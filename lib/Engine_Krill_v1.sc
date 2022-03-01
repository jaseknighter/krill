// Engine_Krill
Engine_Krill_v1 : CroneEngine {
	// <Krill>
	var krillBusDelay;
	var krillBusReverb;
	var krillFn;
	var krillFX;
	var krillSynthBass;
	var krillSynthLead;
  var risePoll,risePollFunc;
  var fallPoll,fallPollFunc;
	// </Krill>


	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {
    // install the Maths quark
		// <Krill>

		// add synth defs
		SynthDef("mxfn",{ 
      arg outBus=0, riseDur1=0.1,fallDur1=0.1,logExp1=0.5,loop1=1,plugged1=0,trig1,
			hz=440,amp=2.
			foc1Val;
			// logExp1Buffer,

			var osc, rise, env_phase, rise_rate, fall_rate, 
			env_rate, env_pos, amp_env, env_gen, sig, done, env_changed;


			// var sig,foc1,eor1,sig1,noise, foc1_num,
			// sig,mathsA,mathsAVal,foc1,eor1,sig1,noise, foc1_num,
      // mathsB,foc2,eor2,sig2;

			// logExp1Buffer = Buffer.alloc(context.server, 1,1, {|b| b.setnMsg(0, logExp1) });
			// #mathsA, foc1, eor1 = Maths2.ar(riseDur1, fallDur1, buffer1.bufnum, loop1);

			osc = SinOsc.ar(hz);

			rise = Decay.kr(Impulse.kr(0), riseDur1);
			env_phase = rise <= 0.001;
			rise_rate = 1 / riseDur1;
			fall_rate = 1 / fallDur1;
			env_rate = Select.kr(env_phase, [rise_rate, fall_rate]);
			env_pos = Sweep.kr(Impulse.kr(0), env_rate);
			amp_env = Env([0.01, 1, 0.001], [1, 1], 'exp');
			env_gen = IEnvGen.kr(amp_env, env_pos);
			sig = osc * env_gen * amp;

			env_changed = Changed.kr(env_phase);
			// (env_changed * env_phase).poll;
			// ([changed,env_phase>0]).poll;
			
			done = env_gen <= 0.001;

	
			SendReply.kr(env_changed * env_phase, '/triggerRisePoll', 1);
			// SendReply.kr(env_changed, '/triggerRisePoll', 1);
			
			// SendReply.kr((foc1Val, '/triggerEor1Val', eor1Val);
			
      // SendReply.kr(Impulse.kr(10), '/triggerRisePoll', foc1);
			// SendReply.kr(Impulse.kr(10), '/triggerFOC1', foc1);
      // SendReply.kr(Impulse.kr(10), '/triggerEOR1', eor1);

			FreeSelf.kr(done);

			Out.ar(outBus, sig.dup);
		}).add;
      
		SynthDef("mxfx",{ 
			arg inDelay, inReverb, reverb=0.05, reverbAttack=0.1,reverbDecay=0.5, out, secondsPerBeat=1/4,delayBeats=4,delayFeedback=0.1,bufnumDelay, t_trig=1;
			var snd,snd2,y,z;

			// delay
			// snd = In.ar(inDelay,2);
			// snd = CombC.ar(
			// 	snd,
			// 	2,
			// 	secondsPerBeat*delayBeats,
			// 	secondsPerBeat*delayBeats*LinLin.kr(delayFeedback,0,1,2,128),// delayFeedback should vary between 2 and 128
			// ); 
			// Out.ar(out,snd);

			// reverb
			snd2 = In.ar(inReverb,2);
			snd2 = DelayN.ar(snd2, 0.03, 0.03);
			snd2 = CombN.ar(snd2, 0.1, {Rand(0.01,0.099)}!32, 4);
			snd2 = SplayAz.ar(2, snd2);
			snd2 = LPF.ar(snd2, 1500);
			5.do{snd2 = AllpassN.ar(snd2, 0.1, {Rand(0.01,0.099)}!2, 3)};
			snd2 = LPF.ar(snd2, 1500);
			snd2 = LeakDC.ar(snd2);

			snd2=snd2*(1-EnvGen.ar(Env.perc(reverbAttack,reverbDecay), t_trig));

			Out.ar(out,snd2);
		}).add;

		// hotroded version of "08091500acidTest309 by_otophilia"


		SynthDef("Krill", {
			arg outBus=0, amp=1.0,
			gate=1, pitch=50,port=0,
			reverbOut, reverbSend=0, delayOut, delaySend=0;
			var env1, env2, out, snd;
			pitch = Lag.kr([pitch,pitch+0.05], port);
			env1 = EnvGen.ar(Env.new([0, 1.0, 0, 0], [0.001, 2.0, 0.04], [0, -4, -4], 2), gate, amp);
			env2 = EnvGen.ar(Env.adsr(0.001, 0.8, 0, 0.8, 70, -4), gate);
			out = LFSaw.ar(pitch.midicps, 2, -1);

			out = MoogLadder.ar(out, (pitch + env2/2).midicps+(LFNoise1.kr(0.2,1100,1500)),LFNoise1.kr(0.4,0.9).abs+0.3,3);
			out = LeakDC.ar((out * env1).tanh/2.7);

			snd = out.tanh;

			Out.ar(delayOut,snd*delaySend);
			Out.ar(reverbOut,snd*reverbSend);
			Out.ar(outBus, snd);
		}).add;


		SynthDef("Krill2", {
			arg outBus=0, amp=1.0,
			gate=1, pitch=50,port=0,
			reverbOut, reverbSend=0, delayOut, delaySend=0;
			var env1, env2, out, snd;
			pitch = Lag.kr([pitch,pitch+0.05], port);
			env1 = EnvGen.ar(Env.perc(0.01,0.7,4,-4), gate, amp);
			env2 = EnvGen.ar(Env.perc(0.001,0.3,600*SinOsc.kr(0.123).range(0.5,4),-3), gate);
			out = LFPulse.ar(pitch.midicps, 0, 0.5);

			out = MoogLadder.ar(out, 100+pitch.midicps + env2,LinExp.kr(SinOsc.kr(0.153),-1,1,0.01,0.6));
			out = LeakDC.ar((out * env1).tanh);

			snd = out.tanh;

			Out.ar(delayOut,snd*delaySend);
			Out.ar(reverbOut,snd*reverbSend);
			Out.ar(outBus, snd);
		}).add;

		// initialize fx, synths, fn, and bus
		context.server.sync;
		krillBusDelay = Bus.audio(context.server,2);
		krillBusReverb = Bus.audio(context.server,2);
		context.server.sync;
		krillFX = Synth.new("mxfx",[\out,0,\inDelay,krillBusDelay,\inReverb,krillBusReverb]);
		context.server.sync;
		krillFn = Synth.before(krillFX,"mxfn",[\riseDur1,0.1,\fallDur1,0.1,\logExp1,1,\loop1,1,\plugged1,0]);
		krillSynthLead = Synth.before(krillFX,"Krill",[\amp,0,\out,0,\delayOut,krillBusDelay,\reverbOut,krillBusReverb]);
		krillSynthBass = Synth.before(krillFX,"Krill2",[\amp,0,\out,0,\delayOut,krillBusDelay,\reverbOut,krillBusReverb]);

		context.server.sync;
    
    /////////////////////////////////
		// add polling
    /////////////////////////////////

    // trigger Polls
    risePollFunc = OSCFunc({
      arg msg;
      var val = msg[3].asStringPrec(3).asFloat;
			risePoll.update(val);
    }, path: '/triggerRisePoll', srcID: context.server.addr);

    // risePollFunc = OSCFunc({
    //   arg msg;
    //   var val = msg[3].asStringPrec(3).asFloat;
		// 	risePoll.update(val)
    // }, path: '/triggerRisePoll', srcID: context.server.addr);

    // risePollFunc = OSCFunc({
    //   arg msg;
    //   var val = msg[3].asStringPrec(3).asFloat;
		// 	risePoll.update(val)
    // }, path: '/triggerRisePoll', srcID: context.server.addr);

		// add polls
    risePoll = this.addPoll(name: "maths_a_foc1", periodic: false);

    ///////////////////////////////////
		// add norns commands
    ///////////////////////////////////

		this.addCommand("Krill_fn1_rise","f",{ arg msg;
			krillFn = Synth.before(krillFX,"mxfn",[\riseDur1,0.1,\fallDur1,0.1,\logExp1,1,\loop1,1,\plugged1,0]);
			
			("Krill_fn1_rise").postln;
			krillFn.set(
				\riseDur1,msg[1],
      );
    });

    this.addCommand("Krill_fn1_fall","f",{ arg msg;
			krillFn.set(
				\fallDur1,msg[1],
      );
    });

    this.addCommand("Krill_fn1_logExp","f",{ arg msg;
			krillFn.set(
				\logExp1,msg[1],
      );
    });

    this.addCommand("Krill_fn1_loop","f",{ arg msg;
			krillFn.set(
				\loop1,msg[1],
      );
    });

    this.addCommand("Krill_fn1_plugged","f",{ arg msg;
			krillFn.set(
				\plugged1,msg[1],
      );
    });
    
		this.addCommand("Krill_bass","fffff",{ arg msg;
			krillSynthBass.set(
				\amp,msg[1],
				\pitch,msg[2],
				\delaySend,msg[3],
				\reverbSend,msg[4],
				\port,msg[5],
				\gate,1,

			);
		});
		this.addCommand("Krill_bass_gate","i",{ arg msg;
			krillSynthBass.set(
				\gate,msg[1],
			);
		});

		this.addCommand("Krill_lead","fffff",{ arg msg;
			krillSynthLead.set(
				\amp,msg[1],
				\pitch,msg[2]+12,
				\delaySend,msg[3],
				\reverbSend,msg[4],
				\port,msg[5],
			);
		});

		this.addCommand("Krill_lead_gate","i",{ arg msg;
			krillSynthLead.set(
				\gate,msg[1],
			);
		});

		this.addCommand("Krill_drum","sfff",{ arg msg;
			Synth.before(krillFX,msg[1].asString,[
				\amp,msg[2],
				\delayOut,krillBusDelay,
				\delaySend,msg[3],
				\reverbOut,krillBusReverb,
				\reverbSend,msg[4],
			]);
		});

		this.addCommand("Krill_reverb","iff",{ arg msg;
			krillFX.set(
				\t_trig,msg[1],
				\reverbAttack,msg[2],
				\reverbDecay,msg[3],
			);
		});

		// engine.Krill_delay(clock.get_beats()/16,8,0.5)
		this.addCommand("Krill_delay","fff",{ arg msg;
			krillFX.set(
				\secondsPerBeat,msg[1],
				\delayBeats,msg[2],
				\delayFeedback,msg[3],
			);
		});
		// </Krill>
	}

	free {
		// <Krill>
		krillSynthBass.free;
		krillSynthLead.free;
		krillFn.free;
		krillFX.free;
		krillBusDelay.free;
		krillBusReverb.free;
		risePollFunc.free;
		// </Krill>
	}
}
