// Engine_Krill
// TODO: figure out why the function looping creates a synth regardless of the parm value (0 or 1)

Engine_Krill : CroneEngine {
	// <Krill>
	classvar maxNumVoices = 4;
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
	var first_harm, hoa1=0.1,hoa2=0.2,hoa3=0.3,hoa4=0.4,hoa5=0.5,hoa6=0.1,hoa7=0.1,hoa8=0.1,hoa9=0.1,hoa10=0.1,hoa11=0.1,hoa12=0.1,hoa13=0.1,hoa14=0.1,hoa15=0.1,hoa16=0.5;
	
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
		SynthDef(\KrillSynth,{ 
      arg outBus=0, logExp=0.5,loop=1,plugged=0,trig,
			hz=220,amp=0.5, 
			rise=0.05,fall=0.5, rise_time=0.05, fall_time=1, 
			gate=1,
			env_scalar=1, env_shape=8,
			sh1=1,sh2=1,
			mode=1,
			logExpBuffer,
			ext_freq,
			first_harm=1,
			h_osc_amps=0;
			// h_osc_amps=Array.rand(16, 0.1,1.0).normalizeSum;
			// hoa1=0.1,hoa2=0.1,hoa3=0.1,hoa4=0.1,hoa5=0.1,hoa6=0.1,hoa7=0.1,hoa8=0.1,hoa9=0.1,hoa10=0.1,hoa11=0.1,hoa12=0.1,hoa13=0.1,hoa14=0.1,hoa15=0.1,hoa16=0.5;
						

			var out, osc, rise_phase, env_phase, rise_rate, fall_rate, 
			env_rate, env_pos, amp_env, env_gen, sig, done, env_changed,
			filter_env,
			pitch, freq,
			mathsA=0,foc1=0,eor1=0,
      rise_done=0,
			fall_done=0;
			// hosc_array = Array.fill(16,h_osc_amps);


			// (hosc_array[0]).poll;
			// rise_phase = Decay.kr(Impulse.kr(0), rise);
			// env_phase = rise_phase <= 0.0001;
			// env_phase = rise_phase > 0;
			// rise_rate = 1 / (rise * env_scalar);
			// fall_rate = 1 / (fall * env_scalar);


			// rise_rate =  (rise * ((sh1/2)+1) * env_scalar);
			rise_phase = Decay.kr(Impulse.kr(0), rise * env_scalar);
			env_phase = rise_phase <= 0.001;

			rise_rate =  1/(rise * env_scalar);
			// rise_rate =  1/(rise * env_scalar*2);
			fall_rate =  1/(fall * env_scalar);
			// fall_rate =  1/(fall * env_scalar*2);
			
			// rise = rise_time * sh1;
			
			env_rate = Select.kr(env_phase, [rise_rate, fall_rate]);
			env_pos = Sweep.kr(Impulse.kr(0), env_rate);
			
			// amp_env = Env([0.001, 1, 0.001], [rise_rate, fall_rate], env_shape);
			// amp_env = Env([0.001, 1, 0.001], [1, 1], env_shape);
			amp_env = Env([0.001, 1, 0.001], [rise * env_scalar, fall * env_scalar], env_shape);
			// amp_env = Env([0.001, 1, 0.001], [rise_rate, fall_rate], env_shape);
			env_gen = IEnvGen.kr(amp_env, env_pos); 

			pitch = ext_freq;
			
			filter_env = EnvGen.ar(Env.adsr(0.001, 0.8, 0, 0.8, 70, -4), gate);
			// filter_env = EnvGen.ar(Env.adsr(0.001, rise_rate, 0, fall_rate, 70, -4), gate);
			// out = LFSaw.ar(pitch.midicps, 2, -1);

			// harmOscMod = 0.1; //SinOsc.kr(0.1);
			out = HarmonicOsc.ar(
					freq: pitch.midicps,
					// freq: mod.linexp(-1.0,1.0,10,1000),
					// firstharmonic: 3,
					firstharmonic: first_harm,
					amplitudes: h_osc_amps
					// amplitudes: Array.rand(16, 0.1,1.0)
					// amplitudes: hosc_array
					// amplitudes: h_osc_amps.normalizeSum
					// amplitudes: [hoa1,hoa2,hoa3,hoa4,hoa5,hoa6,hoa7,hoa8,hoa9,hoa10,hoa11,hoa12,hoa13,hoa14,hoa15,hoa16]
			);



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
				// if (sh1 < minRiseFall){
				// 	sh1 = minRiseFall
				// };
			}{
				sh1 = 1;
			};

			rise = (rise_time * sh1);
			// rise = (rise_time - sh1).abs;
			// ("rise_time + sh1" + rise_time + "/" + sh1).postln;
			risePoll.update(rise);
    }, path: '/triggerRiseDonePoll', srcID: context.server.addr);

    fallPollFunc = OSCFunc({ 
			arg msg;
			if (mode == 1){
				sh2 = lorenz_sample;
				// if (sh2 < minRiseFall){
				// 	sh2 = minRiseFall
				// };
			}{
				sh2 = 1;
			};

			fall = (fall_time * sh2).abs;
			// fall = (fall_time - sh2).abs;
			// ("fall_time + sh2" + fall_time + "/" + sh2).postln;
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
		this.addCommand("play_note","ff",{ arg msg;
			var ext_freq=msg[1];
			var voicesToRemove, newVoice;
      var env;
      var envSig, envBuf;
      var newEnv, envLength;
			// if (msg[2] >= 1){
			// if (voiceList.size < 10){
			
				context.server.makeBundle(nil, {
					("new voice: " + voiceList.size).postln;

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
						\first_harm,first_harm,
						\h_osc_amps,Array.rand(16, 0.1,1.0).normalizeSum
						// \h_osc_amps,[hoa1,hoa2,hoa3,hoa4,hoa5,hoa6,hoa7,hoa8,hoa9,hoa10,hoa11,hoa12,hoa13,hoa14,hoa15,hoa16].normalizeSum
					],
						target: voiceGroup).onFree({ 
							// ("free").postln;
							voiceList.remove(newVoice); 
						})
					);

					// voiceList.addFirst(newVoice);
					voiceList.addFirst(newVoice);

					// set krillVoice to the most recent voice instantiated
					krillVoice = voiceList.detect({ arg item, i; item.id == id; });
					id = id+1;
				});
			// }{
			// 	("update voice: " + hoa1).postln;
			// 	krillVoice.theSynth.set(
			// 		[
			// 			\gate,1,
			// 			\rise,rise,
			// 			\fall,fall,
			// 			\logExp,1,
			// 			\plugged,0,
			// 			\env_scalar,env_scalar,
			// 			\env_shape,env_shape,
			// 			\ext_freq,ext_freq,			
			// 			\first_harm,first_harm,
			// 			\h_osc_amps,[hoa1,hoa2,hoa3,hoa4,hoa5,hoa6,hoa7,hoa8,hoa9,hoa10,hoa11,hoa12,hoa13,hoa14,hoa15,hoa16].normalizeSum
		
			// 		]
			// 	);
			// };
			// Free the existing voice if it exists
			if((voiceList.size > 0 ), {
				voiceList.do{ arg v,i; 
					v.theSynth.set(\t_trig, 1);
					if (i >= maxNumVoices){
					("free").postln;
						v.theSynth.set(\gate, 0);
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
	  
		this.addCommand("env_scalar","f",{ arg msg;
			env_scalar = msg[1];
		});
		
		this.addCommand("switch_mode","f",{ arg msg;
			("switch mode: " + msg[1]).postln;
			("voiceList.size: " + voiceList.size).postln;
			// if((voiceList.size > 0 && krillVoice.theSynth.isNil == false), {
			// if((voiceList.size > 0), {
      //   voiceList.do{ arg v,i; 
			// 		v.theSynth.free;
      //   };
			// });
			mode = msg[1];
		});

		this.addCommand("env_shape","f",{ arg msg;
			env_shape = msg[1];
			env_shape.postln;
		});

		this.addCommand("set_first_harm", "f", { arg msg;
			first_harm = msg[1];
			krillVoice.theSynth.set(\first_harm,first_harm)
		});
		
		this.addCommand("set_harm_osc_amps", "ffffffffffffffff", { arg msg;
			
			hoa1 = msg[1];
			hoa2= msg[2];
			hoa3= msg[3];
			hoa4= msg[4];
			hoa5= msg[5];
			hoa6= msg[6];
			hoa7= msg[7];
			hoa8= msg[8];
			hoa9= msg[9];
			hoa10=msg[10];
			hoa11=msg[11];
			hoa12=msg[12];
			hoa13=msg[13];
			hoa14=msg[14];
			hoa15=msg[15];
			hoa16=msg[16];
			// krillVoice.theSynth.set(\hoa1,hoa1);
			// krillVoice.theSynth.set(\hoa2,hoa2);
			// krillVoice.theSynth.set(\hoa3,hoa3);
			// krillVoice.theSynth.set(\hoa4,hoa4);
			// krillVoice.theSynth.set(\hoa5,hoa5);
			// krillVoice.theSynth.set(\hoa6,hoa6);
			// krillVoice.theSynth.set(\hoa7,hoa7);
			// krillVoice.theSynth.set(\hoa8,hoa8);
			// krillVoice.theSynth.set(\hoa9,hoa9);
			// krillVoice.theSynth.set(\hoa10,hoa10);
			// krillVoice.theSynth.set(\hoa11,hoa11);
			// krillVoice.theSynth.set(\hoa12,hoa12);
			// krillVoice.theSynth.set(\hoa13,hoa13);
			// krillVoice.theSynth.set(\hoa14,hoa14);
			// krillVoice.theSynth.set(\hoa15,hoa15);
			// krillVoice.theSynth.set(\hoa16,hoa16);
			// /h_osc_amps,[0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5]
			// krillVoice.theSynth.set(\h_osc_amps, [msg[1],msg[2],msg[3],msg[4],msg[5],msg[6],msg[7],msg[8],msg[9],msg[10],msg[11],msg[12],msg[13],msg[14],msg[15],msg[16]].normalizeSum);
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
