// Engine_Krill

Engine_Krill : CroneEngine {
	// <Krill>
	var krillVoice;
	var envPosPoll,envPosPollFunc;
	var envLevelPoll,envLevelPollFunc;
	var risePoll,risePollFunc;
	var fallPoll,fallPollFunc;
	var nextNotePoll,nextNotePollFunc;
	var frequency_slew=0;
	var sh1=1, sh2=1;
	var rise=0.05, fall=0.5, rise_time=0.05, fall_time=0.5, env_scalar=1;
	var env_shape=0,env_level=1;
	var lorenz_sample = 1;
	var minRiseFall = 0.005;
	var sequencing_mode, trigger_mode, trigger_type, engine_mode;

	//rings vars
	var exciter_decay_min=0.1,exciter_decay_max=0.5, internal_exciter=0,
			rings_pos=0.05, rings_easter_egg=0, rings_poly=1,
			rings_structure_min=0.2,rings_structure_max=0.2,
			rings_brightness_min=0.01,rings_brightness_max=0.01, rings_damping_min=0.5,rings_damping_max=0.5;
	
	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {

		SynthDef(\KrillSynth,{ 
      arg outBus=0, logExp=0.5,loop=1,plugged=0,
			out,
			hz=220,amp=0.5, 
			rise=0.05,fall=0.5, rise_time=0.05, fall_time=1, 
			gate=1,trig=1,
			env_scalar=1, env_shape=0, env_level=1,
			sh1=1,sh2=1,
			sequencing_mode=1, trigger_mode=1, trigger_type=1, engine_mode=1,
			logExpBuffer,
			frequency, frequency_slew=0,
			// rings args
			exciter_decay_min=0.1,exciter_decay_max=0.5, internal_exciter=0,
			// retrigger_fall=0,
			rise_phase=0, 
			rings_pos=0.05,rings_easter_egg=0, rings_poly=1,
			rings_structure_min=0.2,rings_structure_max=0.2,
			rings_brightness_min=0.01,rings_brightness_max=0.01, rings_damping_min=0.5,rings_damping_max=0.5;

			var osc, env_phase, rise_rate, fall_rate, 
			env_rate, env_pos, rise_fall_env, rise_fall_env_gen, amp_env_gen, sig, done, env_changed,
			filter_env,
			pitch, freq,
			mathsA=0,foc1=0,eor1=0,
      rise_done=0,
			fall_done=0;
			var exciter;
			var modeNum=1,cosFreq=0.75;

			rise_phase = Sweep.kr(trig, 1);

			// retrigger_fall = rise_phase > (rise+fall) * env_scalar;

			env_phase = rise_phase >= (rise * env_scalar);
			rise_rate =  1/(rise * env_scalar);
			fall_rate =  1/(fall * env_scalar);
			env_rate = Select.kr(env_phase, [rise_rate, fall_rate]);
			env_pos = Sweep.kr(trig, env_rate);


			rise_fall_env = Env([0.001, env_level, 0.001], [rise * env_scalar, fall * env_scalar], env_shape);
			rise_fall_env_gen = IEnvGen.kr(rise_fall_env, env_pos); 
			env_changed = Changed.kr(env_phase);
			fall_done = (rise_fall_env_gen <= 0.001) * (env_phase > 0);
			
			pitch = frequency;

			exciter = (trigger_mode) + SoundIn.ar([0,1],mul:trigger_mode);

			sig = MiRings.ar(
				in: exciter, trig: trig, 
				// in: exciter, trig: trig, 
				//  pit: Latch.kr(WhiteNoise.kr(), trig).range(30, 60).round, 
					// pit: pitch, 
					pit: Lag.kr(pitch,frequency_slew), 
					struct: SinOsc.kr(rings_structure_min, rings_structure_max*pi).unipolar * rings_structure_max, 
					bright: SinOsc.kr(rings_brightness_min, rings_brightness_max*pi).unipolar * rings_brightness_max,
					damp: SinOsc.kr(rings_damping_min, rings_damping_max*pi).unipolar * rings_damping_max,
					// struct: TRand.kr(rings_structure_min, rings_structure_max),
					// bright: TRand.kr(rings_brightness_min, rings_brightness_max),
					// damp: TRand.kr(rings_damping_min,rings_damping_max, trig), 
					pos: rings_pos, 
					// model: engine_mode, poly: rings_poly, intern_exciter: 1, easteregg: rings_easter_egg, bypass: 0, mul: 1.0, add: 0);
					model: engine_mode, poly: rings_poly, intern_exciter: internal_exciter, easteregg: rings_easter_egg, bypass: 0, mul: 1.0, add: 0);


			// sig = LFSaw.ar(Lag.kr(pitch.midicps,frequency_slew), 2, -1);
			// sig = LFSaw.ar(pitch.midicps, 2, -1);
			// sig = 	VAKorg35.ar(sig, freq: pitch.midicps, res:rise, overdrive: rise.unipolar, type:0);

			amp_env_gen = EnvGen.ar(rise_fall_env, gate);
			sig = LeakDC.ar((sig * amp_env_gen * amp).tanh/2.7);

			SendReply.kr(Impulse.kr(50), '/triggerEnvPosPoll', env_pos);
			SendReply.kr(Impulse.kr(50), '/triggerEnvLevelPoll', rise_fall_env_gen);

			SendReply.kr(env_changed * env_phase, '/triggerRiseDonePoll', env_phase);
			SendReply.kr(fall_done, '/triggerFallDonePoll', fall_done);
			// SendReply.kr(fall_done, '/triggerFallDonePoll', retrigger_fall);
			Out.ar(out, sig.dup);
		}).add;
		

		context.server.sync;
		
		krillVoice = Synth.new(\KrillSynth,[
			\out, context.out_b.index,
			\trig,0, 
			\gate,0, 
		],
		context.xg);
		
		context.server.sync;

    /////////////////////////////////
		// polling
    /////////////////////////////////


    envPosPollFunc = OSCFunc({
      arg msg;
			envPosPoll.update(msg[3]);
    }, path: '/triggerEnvPosPoll', srcID: context.server.addr);
    
		envLevelPollFunc = OSCFunc({
      arg msg;
			envLevelPoll.update(msg[3]);
    }, path: '/triggerEnvLevelPoll', srcID: context.server.addr);

    nextNotePollFunc = OSCFunc({
      arg msg;
			nextNotePoll.update(msg[3]);
    }, path: '/triggerNextNotePoll', srcID: context.server.addr);

		risePollFunc = OSCFunc({
      arg msg;
			if (sequencing_mode == 1){
				sh1 = lorenz_sample;
				rise = (rise_time * sh1);
			// 	if (rise * env_scalar < 0.5){
			// 		rise = 0.5/env_scalar;
			// 		fall = 0.5/env_scalar;
			// 	("set min rise "+rise).postln;
			// 	};
			};

			risePoll.update(rise);
    }, path: '/triggerRiseDonePoll', srcID: context.server.addr);

    fallPollFunc = OSCFunc({ 
			arg msg;
			if (sequencing_mode == 1){
				sh2 = lorenz_sample;
				fall = (fall_time * sh2).abs;
				// if (fall * env_scalar < 0.5){
				// 	rise = 0.5/env_scalar;
				// 	fall = 0.5/env_scalar;
				// ("set min fall "+fall).postln;
				// };
			};
			// ("fall done" + rise + "/" + fall).postln;
			// krillVoice.set(\trig,0);
			// krillVoice.set(\gate,0);
			// krillVoice.set(\retrigger_fall,0);
			krillVoice.set(\rise_phase,0);
			

			fallPoll.update(fall);
			nextNotePoll.update(sh1+sh2);
    }, path: '/triggerFallDonePoll', srcID: context.server.addr);

    // add polls
    // pitchPoll = this.addPoll(name: "pitch_poll", periodic: false);
    envPosPoll = this.addPoll(name: "env_pos_poll", periodic: false);
    envLevelPoll = this.addPoll(name: "env_level_poll", periodic: false);
    nextNotePoll = this.addPoll(name: "next_note_poll", periodic: false);
    risePoll = this.addPoll(name: "rise_poll", periodic: false);
    fallPoll = this.addPoll(name: "fall_poll", periodic: false);
    
    ///////////////////////////////////
		// norns commands
    ///////////////////////////////////

		//////////////////////////////////////////
		// create a synth voice
		this.addCommand("note_on","ff",{ arg msg;
			var frequency=msg[1];
			// krillVoice.set(\retrigger_fall,0);
			// krillVoice.set(\rise_phase,0);
			krillVoice.set(\trig,0);
			krillVoice.set(\gate,0);
			krillVoice.set(\frequency_slew,frequency_slew);
			krillVoice.set(\trigger_mode,trigger_mode);
			krillVoice.set(\internal_exciter,internal_exciter);
			krillVoice.set(\frequency,frequency);
			krillVoice.set(\env_scalar,env_scalar);
			krillVoice.set(\rise,rise);
			krillVoice.set(\fall,fall);
			krillVoice.set(\trig,1);
			krillVoice.set(\gate,1);
		});

		this.addCommand("note_off","f",{ arg msg;
			krillVoice.set(\trig,0);
			krillVoice.set(\gate,0);
		});

		this.addCommand("frequency_slew","f",{ arg msg;
			// krillVoice.set(\frequency_slew,msg[1]);
			frequency_slew = msg[1];
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
				// krillVoice.set(\rise,rise)
			};			

			if (msg[2] > 0){
				fall_time = msg[2];
				// krillVoice.set(\fall,fall)
			};


			if (sequencing_mode != 1){
				rise = rise_time;
				
			};
			if (sequencing_mode != 1){
				fall = fall_time.abs;
				
			};
			// krillVoice.set(\trig,0);
			// krillVoice.set(\gate,0);
    });
	  
		this.addCommand("env_scalar","f",{ arg msg;
			env_scalar = msg[1];
			// krillVoice.set(\env_scalar,env_scalar);
			// krillVoice.set(\trig,0);
			// krillVoice.set(\gate,0);

		});
		
		this.addCommand("switch_sequencing_mode","f",{ arg msg;
			sequencing_mode = msg[1];
			krillVoice.set(\sequencing_mode,sequencing_mode);
			// krillVoice.set(\trig,0);
			// krillVoice.set(\gate,0);

		});

		this.addCommand("env_level","f",{ arg msg;
			env_level = msg[1];
			krillVoice.set(\env_level,env_level);
		});

		this.addCommand("env_shape","f",{ arg msg;
			env_shape = msg[1];
			krillVoice.set(\env_shape,env_shape);
		});


		/////////////////////////////////
		//rings / karplus strong commands
		/////////////////////////////////
		this.addCommand("engine_mode","f",{ arg msg;
			engine_mode = msg[1];
			// (["set eng mode", engine_mode]).postln;
			krillVoice.set(\trig, 0);
			krillVoice.set(\gate, 0);
			krillVoice.set(\engine_mode,engine_mode);
		});

		this.addCommand("trigger_type","f",{ arg msg;
			trigger_type = msg[1];
			krillVoice.set(\trigger_type,trigger_type)
		});

		this.addCommand("trigger_mode","f",{ arg msg;
			trigger_mode = msg[1];
			trigger_mode.postln;
			// krillVoice.set(\trigger_mode,trigger_mode)
		});

		this.addCommand("exciter_decay_min","f",{ arg msg;
			exciter_decay_min = msg[1];
			krillVoice.set(\exciter_decay_min,exciter_decay_min)
		});

		this.addCommand("exciter_decay_max","f",{ arg msg;
			exciter_decay_max = msg[1];
			krillVoice.set(\exciter_decay_max,exciter_decay_max)
		});

		this.addCommand("rings_pos","f",{ arg msg;
			rings_pos = msg[1];
			krillVoice.set(\rings_pos,rings_pos)
		});

		this.addCommand("rings_structure_min","f",{ arg msg;
			rings_structure_min = msg[1];
			krillVoice.set(\rings_structure_min,rings_structure_min);
		});

		this.addCommand("rings_structure_max","f",{ arg msg;
			rings_structure_max = msg[1];
			krillVoice.set(\rings_structure_max,rings_structure_max);
		});

		this.addCommand("rings_brightness_min","f",{ arg msg;
			rings_brightness_min = msg[1];
			krillVoice.set(\rings_brightness_min,rings_brightness_min)
		});

		this.addCommand("rings_brightness_max","f",{ arg msg;
			rings_brightness_max = msg[1];
			krillVoice.set(\rings_brightness_max,rings_brightness_max)
		});

		this.addCommand("rings_damping_min","f",{ arg msg;
			rings_damping_min = msg[1];
			krillVoice.set(\rings_damping_min,rings_damping_min)
		});

		this.addCommand("rings_damping_max","f",{ arg msg;
			rings_damping_max = msg[1];
			krillVoice.set(\rings_damping_max,rings_damping_max)
		});

		this.addCommand("rings_easter_egg","f",{ arg msg;
			rings_easter_egg = msg[1];
			krillVoice.set(\rings_easter_egg,rings_easter_egg)
		});

		this.addCommand("rings_poly","f",{ arg msg;
			rings_poly = msg[1];
			krillVoice.set(\rings_poly,rings_poly)
		});

		this.addCommand("internal_exciter","f",{ arg msg;
			internal_exciter = msg[1];
			// krillVoice.set(\internal_exciter,internal_exciter)
		});

	}


	free {
		// voiceGroup.free;
		// voiceList.free;
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
