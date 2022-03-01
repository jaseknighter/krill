// Engine_Krill
// TODO: figure out why the function looping creates a synth regardless of the parm value (0 or 1)

Engine_Krill : CroneEngine {
	// <Krill>
	// </Krill>
	var risePoll,risePollFunc;
	var fallPoll,fallPollFunc;
	var krillFn;
	var sh1=1, sh2=1;
	var rise=0.1, fall=0.5, looping=1,running=false, env_time=1;


	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {
    // install the Maths quark
		// <Krill>
		var scale = Scale.choose.postln;

		// add synth defs
		SynthDef("krill",{ 
      arg outBus=0, logExp=0.5,loop=1,plugged=0,trig,
			hz=220,amp=0.5,rise=1,fall=1,
			foc1Val,
			env_time=1,
			sh1=1,sh2=1;

			var osc, rise_phase, env_phase, rise_rate, fall_rate, 
			env_rate, env_pos, amp_env, env_gen, sig, done, env_changed;

			// osc = SinOsc.ar(hz+(220*(sh1/2+1)));

			osc = SinOsc.ar(
        (
            DegreeToKey.kr(
                scale.as(LocalBuf),
                // MouseX.kr(0,15), // mouse indexes into scale
								LinLin.kr((sh1/2+1),0,1,1,15),
                scale.stepsPerOctave,
                1, // mul = 1
                30 // offset by 72 notes
            )
            + LFNoise1.kr([3,3], 0.04) // add some low freq stereo detuning
        ).midicps, // convert midi notes to hertz
        0,
        0.25
    	);
			rise_phase = Decay.kr(Impulse.kr(0), rise);
			env_phase = rise_phase <= 0.001;
			rise_rate = 1 / (rise * (sh1/2+1) * env_time);
			fall_rate = 1 / (fall * (sh1/2+1) * env_time);
			env_rate = Select.kr(env_phase, [rise_rate, fall_rate]);
			env_pos = Sweep.kr(Impulse.kr(0), env_rate);
			
			amp_env = Env([0.01, 1, 0.001], [1, 1], 'exp');
			env_gen = IEnvGen.kr(amp_env, env_pos);
			// var env_gen = EnvGen.kr(amp_env, env_pos, doneAction: 1);	
			sig = osc * env_gen * amp;

			done = env_gen <= 0.001;
			env_changed = Changed.kr(env_phase);

			
			
			SendReply.kr(env_changed * env_phase, '/triggerRiseDonePoll', 1);
			SendReply.kr(done, '/triggerFallDonePoll', 1);
			
			//1:
			SendTrig.kr(env_changed * env_phase,1,LFNoise0.ar(1000));
			SendTrig.kr(done,2,LFNoise0.ar(1000));
			// PauseSelf.kr(done);
			// FreeSelf.kr(done);
			Out.ar(0, sig.dup);
		// }).play;
		// }).add.send(context.server);
		}).add;

		// OSCdef(\free_when_done, { |msg, time|
		OSCdef(\free_when_done, { |msg, time|
			if (msg[2]==1){
				sh1 = msg[3];
				("rise done"+sh1).postln;
				// ("rise done"+msg[3]).postln;
				// context.server.sendMsg("/n_free", msg[1]);				
			};
			if (msg[2]==2){
				sh2 = msg[3];
				("free"+sh1).postln;
				// ("free"+msg[3]).postln;
				context.server.sendMsg("/n_free", msg[1]);				
			};
		}, \tr);

		context.server.sync;
      
		
		context.server.sync;
    
    /////////////////////////////////
		// add polling
    /////////////////////////////////

    // trigger Polls
    risePollFunc = OSCFunc({
      arg msg;
      var val = msg[3].asStringPrec(3).asFloat;
			risePoll.update(val);
    }, path: '/triggerRiseDonePoll', srcID: context.server.addr);


    fallPollFunc = OSCFunc({
      // arg msg,rise=0.1,fall=0.3;
      // var val = msg[3].asStringPrec(3).asFloat;

			// create new synth on completion of old synth
			if(looping == 1){
				// ("looping").postln;
				krillFn = Synth.new("krill",[\rise,rise,\fall,fall,\logExp,1,\plugged,0,\env_time,env_time,\sh1,sh1,\sh2,sh2]);
			}{
				running = false;
				("not running, not looping")
			};

			fallPoll.update(fall);
    }, path: '/triggerFallDonePoll', srcID: context.server.addr);

		// add polls
    risePoll = this.addPoll(name: "rise_poll", periodic: false);
    fallPoll = this.addPoll(name: "fall_poll", periodic: false);

    ///////////////////////////////////
		// add norns commands
    ///////////////////////////////////

		this.addCommand("kr_start","",{ arg msg;
			if (running == false){
				krillFn = Synth.new("krill",[\rise,rise,\fall,fall,\logExp,1,\plugged,0,\env_time,env_time,\sh1,sh1,\sh2,sh2]);
				running = true;
			}
		});

		this.addCommand("kr_looping","f",{ arg msg;
			looping = msg[1];
			if (msg[1] == 1.0 && running == false){
				krillFn = Synth.new("krill",[\rise,rise,\fall,fall,\logExp,1,\plugged,0,\env_time,env_time,\sh1,sh1,\sh2,sh2]);
			}
		});
		
		this.addCommand("kr_rise_fall","ff",{ arg msg;
				// rise = msg[1];
				// fall = msg[2];
			if (msg[1] != nil){
				rise = msg[1];
				("rise"+rise).postln;
			};			

			if (msg[2] != nil){
				fall = msg[2];
				("fall"+fall).postln;
			};
    });
	  
		this.addCommand("kr_looping","f",{ arg msg;
			looping = msg[1];
			if (msg[1] == 1.0 && running == false){
				krillFn = Synth.new("krill",[\rise,rise,\fall,fall,\logExp,1,\plugged,0,\env_time,env_time])
			}
		});

		this.addCommand("kr_env_time","f",{ arg msg;
			env_time = msg[1];
		});
	}

	free {
		// <Krill>
		// krillSynthBass.free;
		// krillSynthLead.free;
		// krillFn.free;
		// krillFX.free;
		// krillBusDelay.free;
		// krillBusReverb.free;
		// risePollFunc.free;
		// </Krill>
	}
}
