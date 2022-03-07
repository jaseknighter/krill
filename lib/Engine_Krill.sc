// Engine_Krill
// TODO: figure out why the function looping creates a synth regardless of the parm value (0 or 1)

Engine_Krill : CroneEngine {
	// <Krill>
	var risePoll,risePollFunc;
	var fallPoll,fallPollFunc;
	var pitchPoll,pitchPollFunc;
	var noteStartPoll;
	var krillFn;
	var sh1=1, sh2=1;
	var rise=1, fall=1, rise_time=1, fall_time=1, looping=1,running=false, env_time=1;
	var rise_start=0, fall_start=0;
	var env_shape='exp';
	var lorenz_sample = 1;
	
	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {

		var scale = Scale.choose.postln;

    // install the Maths quark
		Quarks.install("Maths");
    context.server.sync;

		// add synth defs
		SynthDef("krill",{ 
      arg outBus=0, logExp=0.5,loop=1,plugged=0,trig,
			hz=220,amp=0.5, 
			rise=1,fall=1, rise_time=1, fall_time=1, 
			gate=1,
			env_time=1, env_shape='exp',
			sh1=1,sh2=1,
			logExpBuffer,
			mathsA,mathsAVal,foc1,eor1,sig1,noise, foc1_num,
      mathsB,foc2,eor2,sig2;

			
			var out, osc, rise_phase, env_phase, rise_rate, fall_rate, 
			env_rate, env_pos, amp_env, env_gen, sig, done, env_changed,
			filter_env,
			pitch, freq,

			fall_start=0,rise_start=0;

			logExpBuffer = Buffer.alloc(context.server, 1,1, {|b| b.setnMsg(0, logExp) });
      #mathsA, foc1, eor1 = Maths2.ar(rise, fall, logExpBuffer.bufnum, loop);

			pitch = DegreeToKey.kr(
                scale.as(LocalBuf),
                // MouseX.kr(0,15), // mouse indexes into scale
								// LinLin.kr((sh1+sh2/2+1),-2,2,1,15),
								LinLin.kr((sh1+sh2),0,2,1,15).floor,
                scale.stepsPerOctave,
                1, // mul = 1
                30 // offset by 30 notes (sample code is 72 note offset?!?!?!)
            );
			
			// pitch.midicps.poll;

			filter_env = EnvGen.ar(Env.adsr(0.001, 0.8, 0, 0.8, 70, -4), gate);
			out = LFSaw.ar(pitch.midicps, 2, -1);

			// freq = Pitch.kr(out);
			// freq = Clip.ar(freq, 0.midicps, 127.midicps);

			out = MoogLadder.ar(out, (pitch + filter_env).midicps+(LFNoise1.kr(0.2,1100,1500)),LFNoise1.kr(0.4,0.9).abs+0.3,3);
			out = LeakDC.ar((out * amp).tanh/2.7);

			sig = out.tanh;

			SendReply.kr(Impulse.kr(10), '/triggerPitchPoll', pitch.midicps);
			SendReply.ar(Changed.ar(foc1), '/triggerRiseDonePoll', foc1);
			SendReply.ar(Changed.ar(eor1), '/triggerFallDonePoll', eor1);
			
			Out.ar(0, sig.dup);
		}).add;
		
		context.server.sync;
    
    /////////////////////////////////
		// add polling
    /////////////////////////////////

    // trigger Polls
    pitchPollFunc = OSCFunc({
      arg msg;
			// ("pitchpoll"+msg[3]).postln;
			pitchPoll.update(msg[3]);
    }, path: '/triggerPitchPoll', srcID: context.server.addr);


		risePollFunc = OSCFunc({
      arg msg;
			if (rise_start > 1) {
				sh1 = lorenz_sample;
				rise = rise_time * lorenz_sample;
				// ("rise"+rise_start).postln;

				// ("rise"+rise_start+"/"+fall_start).postln;
				risePoll.update(sh1);
				rise_start=0;
			};
			rise_start = rise_start + 1;
    }, path: '/triggerRiseDonePoll', srcID: context.server.addr);

    fallPollFunc = OSCFunc({ 
			arg msg;
			sh2 = lorenz_sample;
			// if(looping == 1 && fall_start > 1){
			if(fall_start > 1){
				fall = fall_time * lorenz_sample;
				// ("fall"+fall_start).postln;
				fallPoll.update(sh2);
				fall_start=0;
				context.server.sendMsg("/n_free", msg[1]);	
				if (looping == 1){
					noteStartPoll.update();
					krillFn = Synth.new("krill",[\rise,rise,\fall,fall,\logExp,1,\plugged,0,\env_time,env_time,\env_shape,env_shape,\sh1,sh1,\sh2,sh2]);
				}{
					running = false;
				};
			}{
			};
			fall_start = fall_start + 1;
    }, path: '/triggerFallDonePoll', srcID: context.server.addr);

    // add polls
    pitchPoll = this.addPoll(name: "pitch_poll", periodic: false);
    noteStartPoll = this.addPoll(name: "note_start_poll", periodic: false);
    risePoll = this.addPoll(name: "rise_poll", periodic: false);
    fallPoll = this.addPoll(name: "fall_poll", periodic: false);
    
    ///////////////////////////////////
		// add norns commands
    ///////////////////////////////////

		this.addCommand("kr_start","",{ arg msg;
			if (running == false){
				krillFn = Synth.new("krill",[\rise,rise,\fall,fall,\logExp,1,\plugged,0,\env_time,env_time,\env_shape,env_shape,\sh1,sh1,\sh2,sh2]);
				running = true;
			}
		});

		this.addCommand("kr_set_lorenz_sample","f",{ arg msg;
			lorenz_sample = msg[1];
		});

		this.addCommand("kr_looping","f",{ arg msg;
			looping = msg[1];
			("looping" + msg[1]).postln;
			if (msg[1] == 1.0 && running == false){
				krillFn = Synth.new("krill",[\rise,rise,\fall,fall,\logExp,1,\plugged,0,\env_time,env_time,\env_shape,env_shape,\sh1,sh1,\sh2,sh2]);
				running = true;
			};
			
		});
		
		this.addCommand("kr_rise_fall","ff",{ arg msg;
				// rise = msg[1];
				// fall = msg[2];
			if (msg[1] != nil){
				rise_time = msg[1];
				("rise_time"+rise_time).postln;
			};			

			if (msg[2] != nil){
				fall_time = msg[2];
				("fall_time"+fall_time).postln;
			};
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


	}

	free {
		risePoll.free;
		risePollFunc.free;
		fallPoll.free;
		fallPollFunc.free;
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
