// Engine_Krill
// TODO: figure out why the function looping creates a synth regardless of the parm value (0 or 1)

Engine_Krill : CroneEngine {
	// <Krill>
	classvar maxNumVoices = 1;
	var voiceGroup;
  var voiceList;
	var krillVoice;
	var id=0;
	var risePoll,risePollFunc;
	var fallPoll,fallPollFunc;
	var nextNotePoll,nextNotePollFunc;
	// var pitchPoll,pitchPollFunc;
	// var noteStartPoll;
	var sh1=1, sh2=1;
	var rise=1, fall=1, rise_time=1, fall_time=1, env_time=1;
	var env_shape='exp';
	var lorenz_sample = 1;
	var minRiseFall = 0.1;
	var mode;
	var krillSynth;
	
	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {

		var scale = Scale.choose.postln;
    voiceGroup = Group.new(context.xg);
    voiceList = List.new();

    // install the Maths quark
		// Quarks.install("Maths");
    // context.server.sync;

		// add synth defs
		SynthDef("KrillSynth",{ 
      arg outBus=0, logExp=0.5,loop=1,plugged=0,trig,
			hz=220,amp=0.5, 
			rise=1,fall=1, rise_time=1, fall_time=1, 
			gate=1,
			env_time=1, env_shape='exp',
			sh1=1,sh2=1,
			mode=1,
			logExpBuffer,
			ext_freq;

			
			var out, osc, rise_phase, env_phase, rise_rate, fall_rate, 
			env_rate, env_pos, amp_env, env_gen, sig, done, env_changed,
			filter_env,
			pitch, freq,
			mathsA=0,foc1=0,eor1=0,
      rise_done=0,
			fall_done=0;


			rise_phase = Decay.kr(Impulse.kr(0), rise);
			// env_phase = rise_phase > 0;
			env_phase = rise_phase <= 0.001;
			rise_rate = 1 / (rise * ((sh1/2)+1) * env_time);
			fall_rate = 1 / (fall * ((sh2/2)+1) * env_time);
			
			env_rate = Select.kr(env_phase, [rise_rate, fall_rate]);
			env_pos = Sweep.kr(Impulse.kr(0), env_rate);
			
			amp_env = Env([0.001, 1, 0.001], [1, 1], env_shape);
			env_gen = IEnvGen.kr(amp_env, env_pos); 

			logExpBuffer = Buffer.alloc(context.server, 1,1, {|b| b.setnMsg(0, logExp) });

			pitch = ext_freq;
			
			filter_env = EnvGen.ar(Env.adsr(0.001, 0.8, 0, 0.8, 70, -4), gate);
			out = LFSaw.ar(pitch.midicps, 2, -1);
			out = MoogLadder.ar(out, (pitch + filter_env).midicps+(LFNoise1.kr(0.2,1100,1500)),LFNoise1.kr(0.4,0.9).abs+0.3,3);
			out = LeakDC.ar((out * amp).tanh/2.7);
			sig = out.tanh;	

			fall_done = env_gen <= 0.001;
			env_changed = Changed.kr(env_phase);

			SendReply.kr(Impulse.kr(10), '/triggerPitchPoll', pitch.midicps);
			SendReply.kr(env_changed * env_phase, '/triggerRiseDonePoll', foc1);
			SendReply.kr(fall_done, '/triggerFallDonePoll', eor1);
			
			Out.ar(0, sig.dup);
		}).add;
		
		context.server.sync;


    /////////////////////////////////
		// add polling
    /////////////////////////////////

    // trigger Polls
    // pitchPollFunc = OSCFunc({
    //   arg msg;
		// 	// ("pitchpoll"+msg[3]).postln;
		// 	pitchPoll.update(msg[3]);
    // }, path: '/triggerPitchPoll', srcID: context.server.addr);

    nextNotePollFunc = OSCFunc({
      arg msg;
			nextNotePoll.update(msg[3]);
    }, path: '/triggerNextNotePoll', srcID: context.server.addr);

		risePollFunc = OSCFunc({
      arg msg;
			sh1 = lorenz_sample;
			if (sh1 < minRiseFall){
				sh1 = minRiseFall
			};
			// ("rise time/sh1: "+rise_time+"/"+sh1).postln;
			rise = rise_time * sh1;
			risePoll.update(rise);
    }, path: '/triggerRiseDonePoll', srcID: context.server.addr);

    fallPollFunc = OSCFunc({ 
			arg msg;
			sh2 = lorenz_sample;
			if (sh2 < minRiseFall){
				sh2 = minRiseFall
			};
			fall = fall_time * sh2;
			// ("fall"+sh1+"/"+sh2).postln;
			fallPoll.update(fall);
			nextNotePoll.update(sh1+sh2);

			// context.server.sendMsg("/n_free", msg[1]);	
			
    }, path: '/triggerFallDonePoll', srcID: context.server.addr);

    // add polls
    // pitchPoll = this.addPoll(name: "pitch_poll", periodic: false);
    nextNotePoll = this.addPoll(name: "next_note_poll", periodic: false);
    risePoll = this.addPoll(name: "rise_poll", periodic: false);
    fallPoll = this.addPoll(name: "fall_poll", periodic: false);
    
    ///////////////////////////////////
		// add norns commands
    ///////////////////////////////////

		//////////////////////////////////////////
		// create a synth voice
		this.addCommand("play_note","f",{ arg msg;
			var ext_freq=msg[1];
			var voicesToRemove, newVoice;
      var env;
      var envSig, envBuf;
      var newEnv, envLength;

      context.server.makeBundle(nil, {
					
				newVoice = (id: id, theSynth: Synth("KrillSynth",
				[
					\rise,rise,
					\fall,fall,
					\logExp,1,
					\plugged,0,
					\env_time,env_time,
					\env_shape,env_shape,
					\ext_freq,ext_freq,					
				],
					target: voiceGroup).onFree({ 
						voiceList.remove(newVoice); 
					})
				);

				voiceList.addFirst(newVoice);

				// set krillVoice to the most recent voice instantiated
				krillVoice = voiceList.detect({ arg item, i; item.id == id; });
				id = id+1;

				// effectsSynth.set(\envBuf, envBuf);
				
			});

      // Free the existing voice if it exists
      if((voiceList.size > 0 && krillVoice.theSynth.isNil == false), {
        voiceList.do{ arg v,i; 
          v.theSynth.set(\t_trig, 1);
          if (i >= maxNumVoices){
            // v.theSynth.set(\gate, 0);
            v.theSynth.free;
          }
        };
      });

		});

		this.addCommand("set_lorenz_sample","f",{ arg msg;
			lorenz_sample = msg[1];
		});

		
		////////////////////
		//NOTE: rise + fall shouldn't be < 0.1
		////////////////////
		this.addCommand("rise_fall","ff",{ arg msg;
				// rise = msg[1];
				// fall = msg[2];
			if (msg[1] > 0){
				rise_time = msg[1];
			};			

			if (msg[2] > 0){
				fall_time = msg[2];
			};
    });
	  
		this.addCommand("env_time","f",{ arg msg;
			env_time = msg[1];
		});
		
		this.addCommand("switch_mode","f",{ arg msg;
			("switch mode: " + msg[1]).postln;
			("voiceList.size: " + voiceList.size).postln;
			// if((voiceList.size > 0 && krillVoice.theSynth.isNil == false), {
			if((voiceList.size > 0), {
        voiceList.do{ arg v,i; 
					v.theSynth.free;
        };
			});
			mode = msg[1];
		});

		this.addCommand("env_shape","s",{ arg msg;
			env_shape = msg[1].asString;
			env_shape.postln;
		});
	}

	free {
		voiceGroup.free;
		voiceList.free;
		krillVoice.free;
		risePoll.free;
		risePollFunc.free;
		fallPoll.free;
		fallPollFunc.free;
		sh1.free;
		sh2.free;
		rise.free;
		fall.free;
		env_time.free;
	}
}
