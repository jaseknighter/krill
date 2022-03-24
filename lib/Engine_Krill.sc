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
	var rise=0.05, fall=0.5, rise_time=0.05, fall_time=1, env_scalar=1;
	var env_shape=8;
	var lorenz_sample = 1;
	var minRiseFall = 0.005;
	var mode;
	var krillSynth;
	var exciter_decay_min=0.1,exciter_decay_max=0.5, 
			resonator_pos=0.0, resonator_resolution=24, resonator_structure=0.01,
			resonator_brightness_min=0.01,resonator_brightness_max=0.5, resonator_damping_min=0.2,resonator_damping_max=0.8;
	
	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {

		var scale = Scale.choose.postln;
    voiceGroup = Group.new(context.xg);
    voiceList = List.new();

		SynthDef(\KrillSynth,{ 
      arg outBus=0, logExp=0.5,loop=1,plugged=0,
			hz=220,amp=0.5, 
			rise=0.05,fall=0.5, rise_time=0.05, fall_time=1, 
			gate=1,
			env_scalar=1, env_shape=8,
			sh1=1,sh2=1,
			mode=1,
			logExpBuffer,
			ext_freq,
			exciter_decay_min=0.1,exciter_decay_max=0.5, 
			resonator_pos=0.0, resonator_resolution=24, resonator_structure=0.01,
			resonator_brightness_min=0.01,resonator_brightness_max=0.5, resonator_damping_min=0.2,resonator_damping_max=0.8;

			var out, osc, rise_phase, env_phase, rise_rate, fall_rate, 
			env_rate, env_pos, amp_env, env_gen, sig, done, env_changed,
			filter_env,
			pitch, freq,
			mathsA=0,foc1=0,eor1=0,
      rise_done=0,
			fall_done=0;
			var trig = Impulse.kr(1);		
			var exciter = AnalogSnareDrum.ar(
				trig, decay: TRand.kr(exciter_decay_min,exciter_decay_max,trig)
			);

			// rise_rate =  (rise * ((sh1/2)+1) * env_scalar);
			rise_phase = Decay.kr(Impulse.kr(0), rise * env_scalar);
			env_phase = rise_phase <= 0.001;

			rise_rate =  1/(rise * env_scalar);
			fall_rate =  1/(fall * env_scalar);
			env_rate = Select.kr(env_phase, [rise_rate, fall_rate]);
			env_pos = Sweep.kr(Impulse.kr(0), env_rate);
			
			amp_env = Env([0.001, 1, 0.001], [rise * env_scalar, fall * env_scalar], env_shape);
			env_gen = IEnvGen.kr(amp_env, env_pos); 

			pitch = ext_freq;
			
			filter_env = EnvGen.ar(Env.adsr(0.001, 0.8, 0, 0.8, 70, -4), gate);
			// filter_env = EnvGen.ar(Env.adsr(0.001, rise_rate, 0, fall_rate, 70, -4), gate);
			// out = LFSaw.ar(pitch.midicps, 2, -1);



  	  out = Resonator.ar(
        input: exciter,
        freq: pitch.midicps,
        // freq: TExpRand.kr(25.0,250.0,trig),
        position: resonator_pos,
        resolution: resonator_resolution,
        structure: SinOsc.kr(resonator_structure).unipolar,
        brightness: SinOsc.kr(resonator_brightness_min, resonator_brightness_max*pi).unipolar * resonator_brightness_max,
        damping: TRand.kr(resonator_damping_min,resonator_damping_max, trig)
  	  );

			// out = HarmonicOsc.ar(
			// 		freq: pitch.midicps,
			// 		firstharmonic: first_harm,
			// 		amplitudes: Array.fill(16,[hoa1,hoa2,hoa3,hoa4,hoa5,hoa6,hoa7,hoa8,hoa9,hoa10,hoa11,hoa12,hoa13,hoa14,hoa15,hoa16].normalizeSum)
			// 		// amplitudes: Array.fill(16,Array.rand(16, 0.1,1.0).normalizeSum)
			// );




			// out = MoogLadder.ar(out, (env_gen ).midicps+(LFNoise1.kr(0.2,1100,1500)),LFN///oise1.kr(0.4,0.9).abs+0.3,3);
			// out = MoogLadder.ar(out, (pitch + filter_env).midicps+(LFNoise1.kr(0.2,1100,1500)),env_gen.abs,4);
			/*
			out = MoogLadder.ar(
				out, 																													//in
				(pitch + filter_env).midicps+(LFNoise1.kr(0.2,1100,1500)),		//cutoff freq
				LFNoise1.kr(0.4,0.9).abs+0.3,																	//res
				3
			);
			*/


			// out = LeakDC.ar((out * amp).tanh/2.7);
			out = LeakDC.ar((out * env_gen * amp).tanh/2.7);
			sig = out.tanh;	
			env_changed = Changed.kr(env_phase);
			fall_done = env_gen <= 0.001;

			// SendReply.kr(Impulse.kr(10), '/triggerPitchPoll', pitch.midicps);
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
			if (mode == 1){
				sh1 = lorenz_sample;
			}{
				sh1 = 1;
			};

			rise = (rise_time * sh1);
			risePoll.update(rise);
    }, path: '/triggerRiseDonePoll', srcID: context.server.addr);

    fallPollFunc = OSCFunc({ 
			arg msg;
			if (mode == 1){
				sh2 = lorenz_sample;
			}{
				sh2 = 1;
			};

			fall = (fall_time * sh2).abs;
			fallPoll.update(fall);
			nextNotePoll.update(sh1+sh2);
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
		this.addCommand("play_note","ff",{ arg msg;
			var ext_freq=msg[1];
			var voicesToRemove, newVoice;
      var env;
      var envSig, envBuf;
      var newEnv, envLength;
			newVoice = (id: id, theSynth: Synth("KrillSynth",
			[
				\rise,rise,
				\fall,fall,
				\logExp,1,
				\plugged,0,
				\env_scalar,env_scalar,
				\env_shape,env_shape,
				\ext_freq,ext_freq,			
				\rise_time,rise_time,		
				\fall_time,fall_time,
				\exciter_decay_min,exciter_decay_min,
				\exciter_decay_max,exciter_decay_max,
				\resonator_pos,resonator_pos,
				\resonator_resolution,resonator_resolution,
				\resonator_structure,resonator_structure,
				\resonator_brightness_min,resonator_brightness_min,
				\resonator_brightness_max,resonator_brightness_max,
				\resonator_damping_min,resonator_damping_min,
				\resonator_damping_max,resonator_damping_max,
			],
				target: voiceGroup).onFree({ 
					voiceList.remove(newVoice); 
				})
			);

			voiceList.addFirst(newVoice);

			// set krillVoice to the most recent voice instantiated
			krillVoice = voiceList.detect({ arg item, i; item.id == id; });
			id = id+1;

			// Free the existing voice if it exists
			if((voiceList.size > 0 ), {
				voiceList.do{ arg v,i; 
					// v.theSynth.set(\t_trig, 1);
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
			if (msg[1] > 0){
				rise_time = msg[1];
			};			

			if (msg[2] > 0){
				fall_time = msg[2];
			};
    });
	  
		this.addCommand("env_scalar","f",{ arg msg;
			env_scalar = msg[1];
		});
		
		this.addCommand("switch_mode","f",{ arg msg;
			mode = msg[1];
		});

		this.addCommand("env_shape","f",{ arg msg;
			env_shape = msg[1];
			env_shape.postln;
		});



		this.addCommand("exciter_decay_min","f",{ arg msg;
			exciter_decay_min = msg[1];
			krillVoice.theSynth.set(\exciter_decay_min,exciter_decay_min)
		});

		this.addCommand("exciter_decay_max","f",{ arg msg;
			exciter_decay_max = msg[1];
			krillVoice.theSynth.set(\exciter_decay_max,exciter_decay_max)
		});

		this.addCommand("resonator_pos","f",{ arg msg;
			resonator_pos = msg[1];
			krillVoice.theSynth.set(\resonator_pos,resonator_pos)
		});

		this.addCommand("resonator_resolution","f",{ arg msg;
			resonator_resolution = msg[1];
			krillVoice.theSynth.set(\resonator_resolution,resonator_resolution)
		});

		this.addCommand("resonator_structure","f",{ arg msg;
			resonator_structure = msg[1];
			krillVoice.theSynth.set(\resonator_structure,resonator_structure)
		});

		this.addCommand("resonator_brightness_min","f",{ arg msg;
			resonator_brightness_min = msg[1];
			krillVoice.theSynth.set(\resonator_brightness_min,resonator_brightness_min)
		});

		this.addCommand("resonator_brightness_max","f",{ arg msg;
			resonator_brightness_max = msg[1];
			krillVoice.theSynth.set(\resonator_brightness_max,resonator_brightness_max)
		});

		this.addCommand("resonator_damping_min","f",{ arg msg;
			resonator_damping_min = msg[1];
			krillVoice.theSynth.set(\resonator_damping_min,resonator_damping_min)
		});

		this.addCommand("resonator_damping_max","f",{ arg msg;
			resonator_damping_max = msg[1];
			krillVoice.theSynth.set(\resonator_damping_max,resonator_damping_max)
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
		env_scalar.free;
	}
}
