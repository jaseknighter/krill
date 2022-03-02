// Engine_Krill
// TODO: figure out why the function looping creates a synth regardless of the parm value (0 or 1)

Engine_Krill : CroneEngine {
	// <Krill>
	// </Krill>
	var risePoll,risePollFunc;
	var fallPoll,fallPollFunc;
	var rc1SamplePoll,rc1SamplePollFunc;
	var rc2SamplePoll,rc2SamplePollFunc;
	var rc_freq=2,rc_mult=0.3,rc_fdbk=2;
	var krillFn;
	var sh1=1, sh2=1;
	var rise=0.1, fall=0.5, looping=1,running=false, env_time=1;
	var env_shape='exp';


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
			hz=220,amp=0.5,rise=1,fall=1, gate=1,
			foc1Val,
			env_time=1, env_shape='exp',
			sh1=1,sh2=1,
			rand_chaos_mode=3, rc_freq=2, rc_mult=0.3,rc_fdbk=2;

			var out, osc, rise_phase, env_phase, rise_rate, fall_rate, 
			env_rate, env_pos, amp_env, env_gen, sig, done, env_changed,
			rc1a, rc1b, rc2a,rc2b, 
			pitch,filter_env;

			rise_phase = Decay.kr(Impulse.kr(0), rise);
			// env_phase = rise_phase > 0;
			env_phase = rise_phase <= 0.001;
			rise_rate = 1 / (rise * ((sh1/2)+1) * env_time);
			fall_rate = 1 / (fall * ((sh2/2)+1) * env_time);
			
			env_rate = Select.kr(env_phase, [rise_rate, fall_rate]);
			env_pos = Sweep.kr(Impulse.kr(0), env_rate);
			
			amp_env = Env([0.001, 1, 0.001], [1, 1], env_shape);
			env_gen = IEnvGen.kr(amp_env, env_pos);

			// sig = osc * env_gen * amp;

			pitch = DegreeToKey.kr(
                scale.as(LocalBuf),
                // MouseX.kr(0,15), // mouse indexes into scale
								LinLin.kr((sh1/2+1),0,1,1,15),
                scale.stepsPerOctave,
                1, // mul = 1
                30 // offset by 72 notes
            );
			// env1 = EnvGen.ar(Env.new([0, 1.0, 0, 0], [0.001, 2.0, 0.04], [0, -4, -4], 2), gate, amp);
			filter_env = EnvGen.ar(Env.adsr(0.001, 0.8, 0, 0.8, 70, -4), gate);
			out = LFSaw.ar(pitch.midicps, 2, -1);

			out = MoogLadder.ar(out, (pitch + filter_env/2).midicps+(LFNoise1.kr(0.2,1100,1500)),LFNoise1.kr(0.4,0.9).abs+0.3,3);
			// out = MoogLadder.ar(out, (env_pos/2).midicps+(LFNoise1.kr(0.2,1100,1500)),LFNoise1.kr(0.4,0.9).abs+0.3,3);
			// out = MoogLadder.ar(out, (pitch * sh2).midicps+(LFNoise1.kr(0.2,1100,1500)),LFNoise1.kr(0.4,0.9).abs+0.3,3);
			out = LeakDC.ar((out * env_gen*amp).tanh/2.7);

			sig = out.tanh;


			done = env_gen <= 0.001;
			env_changed = Changed.kr(env_phase);

			
			
			//random/chaotic generator modes
			// 1: LFNoise0
			rc1a = LFNoise0.ar(10);
			// rc1b = rc1a;
			rc2a = LFNoise0.ar(10);
			// rc2b = rc2a;

			// 2: RosslerL #1
			// #rc1a, rc2a = RosslerL.ar(SampleRate.ir/rc_freq, 0.36, 0.35, 4.5) * rc_mult;
			
			// 3: RosslerL #2
			// #rc1a, rc2a = RosslerL.ar(freq:rc_freq,h:rc_mult);
			// 4: SinOscFB
			// #rc1a, rc2a = SinOscFB.ar([800,700,600,500,400,301], rc_fdbk, rc_mult);
			// ([rc1a,rc2a]).poll;


			//send messages to norns
			SendReply.kr(env_changed * env_phase, '/triggerRiseDonePoll', rc1a);
			// SendReply.kr(done, '/triggerRC1Poll', sh1);
			// SendReply.kr(done, '/triggerRC2Poll', sh2);			
			SendReply.kr(done, '/triggerRC1Poll', rc1a);
			SendReply.kr(done, '/triggerRC2Poll', rc2a);			
			SendReply.kr(done, '/triggerFallDonePoll', rc2a);
			


			Out.ar(0, sig.dup);
		}).add;
		
		context.server.sync;
    
    /////////////////////////////////
		// add polling
    /////////////////////////////////

    // trigger Polls
    risePollFunc = OSCFunc({
      arg msg;
      var val = msg[3].asStringPrec(3).asFloat;


			// if (val > -1 && val < 1) {
				sh1 = val;
				("rise"+sh1).postln;
				risePoll.update(val);
			// };

    }, path: '/triggerRiseDonePoll', srcID: context.server.addr);

    fallPollFunc = OSCFunc({ 
			arg msg;
      var val = msg[3].asStringPrec(3).asFloat;
			sh2 = val;
			// create a new synth on completion of old synth if looping == 1
			context.server.sendMsg("/n_free", msg[1]);				
			if(looping == 1){
				krillFn = Synth.new("krill",[\rise,rise,\fall,fall,\logExp,1,\plugged,0,\env_time,env_time,\env_shape,env_shape,\sh1,sh1,\sh2,sh2,\rc_freq,rc_freq,\rc_mult,rc_mult,\rc_fdbk,rc_fdbk]);

			}{
				running = false;
				("not running, not looping")
			};
			("fall"+sh2).postln;
			//free the active synth

			fallPoll.update(val);
    }, path: '/triggerFallDonePoll', srcID: context.server.addr);

    rc1SamplePollFunc = OSCFunc({
			arg msg;
      var val = msg[3].asStringPrec(3).asFloat;
			rc1SamplePoll.update(val);
    }, path: '/triggerRC1Poll', srcID: context.server.addr);

    rc2SamplePollFunc = OSCFunc({
			arg msg;
      var val = msg[3].asStringPrec(3).asFloat;
			rc2SamplePoll.update(val);
    }, path: '/triggerRC2Poll', srcID: context.server.addr);

		// add polls
    risePoll = this.addPoll(name: "rise_poll", periodic: false);
    fallPoll = this.addPoll(name: "fall_poll", periodic: false);
    rc1SamplePoll = this.addPoll(name: "rc1_sample_poll", periodic: false);
    rc2SamplePoll = this.addPoll(name: "rc2_sample_poll", periodic: false);

    ///////////////////////////////////
		// add norns commands
    ///////////////////////////////////

		this.addCommand("kr_start","",{ arg msg;
			if (running == false){
				krillFn = Synth.new("krill",[\rise,rise,\fall,fall,\logExp,1,\plugged,0,\env_time,env_time,\env_shape,env_shape,\sh1,sh1,\sh2,sh2,\rc_freq,rc_freq,\rc_mult,rc_mult,\rc_fdbk,rc_fdbk]);
				running = true;
			}
		});

		this.addCommand("kr_looping","f",{ arg msg;
			looping = msg[1];
			if (msg[1] == 1.0 && running == false){
				krillFn = Synth.new("krill",[\rise,rise,\fall,fall,\logExp,1,\plugged,0,\env_time,env_time,\env_shape,env_shape,\sh1,sh1,\sh2,sh2,\rc_freq,rc_freq,\rc_mult,rc_mult,\rc_fdbk,rc_fdbk]);
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
			var time;
			// if (msg[1] < 1){
			// 	time = 1;
			// }{
				time = msg[1];
				// ("env time cannot be less than 1, sorry").postln;
			// };
			env_time = time;
		});

		this.addCommand("kr_env_shape","s",{ arg msg;
			env_shape = msg[1].asString;
			env_shape.postln;
		});

		this.addCommand("kr_rc_freq","f",{ arg msg;
			rc_freq = msg[1];
		});

		this.addCommand("kr_rc_mult","f",{ arg msg;
			rc_mult = msg[1];
		});

		this.addCommand("kr_rc_fdbk","f",{ arg msg;
			rc_fdbk = msg[1];
		});

	}

	free {
		risePoll.free;
		risePollFunc.free;
		fallPoll.free;
		fallPollFunc.free;
		rc1SamplePoll.free;
		rc1SamplePollFunc.free;
		rc2SamplePoll.free;
		rc2SamplePollFunc.free;
		krillFn.free;
		sh1.free;
		sh2.free;
		rise.free;
		fall.free;
		looping.free;
		running.free;
		env_time.free;
	}
}
