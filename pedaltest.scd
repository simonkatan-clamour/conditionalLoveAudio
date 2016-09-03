(
SynthDef(\pedalTone, {|freq = 25, phase = 0, pan = 0, tFreq = 0.05, wFreq = 4, wampF = 0.2, fFreq = 1000, amp = 0.1|

	var wamp, swell, wobble, out;

	swell = LFTri.kr(tFreq,phase,0.5,0.5);
	wobble = SinOsc.kr(wFreq,0,freq/40);
	wamp = SinOsc.kr(wampF,0,0.2,0.3);
	out = VarSaw.ar(freq, 0, wamp, swell);
	out = out * 0.8 + RHPF.ar(out, fFreq, 0.02, 0.2);
	out = Pan2.ar(out, pan) * amp;
	out = out * EnvGen.kr(Env.asr(4,1,0.01,'sine'),1, doneAction:2);
	Out.ar(0, out);

}).send(s);
)



x= Synth.new(\pedalTone, [\freq, 500, \tFreq, 1.0, \phase]);

(
x = {|gate = 1 |

	//ideally will be a a gradual build up use just a flat version for now.
	var sig, env;

	sig = Mix.fill( 8,
		{arg count;
			var out, wamp, swell, wobble, freq, pan, flip;

			pan = 0.1 * count * [1,-1].choose;
			freq = 25 + (25 * (count +1));
			swell = LFTri.kr(rrand(0.05,0.1),3,0.25,0.1);
			wobble = SinOsc.kr(rrand(4,14),0,freq/40);
			wamp = SinOsc.kr(0.2 + (0.01 * count),0,0.2,0.3);
			out = VarSaw.ar(freq,0, wamp, swell);
			out = out + RHPF.ar(out, rrand(1000,2000), 0.02, 0.2);
			out = Pan2.ar(out, pan);
		}
	);

	sig = sig * EnvGen.kr(Env.asr(4,1,0.01,'sine'),gate, doneAction:2);



}.play;
)


{SinOsc.ar(1.0,0,0.5,0.5)}.plot(1.0);