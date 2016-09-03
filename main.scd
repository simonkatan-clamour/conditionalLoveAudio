NetAddr.langPort;

(

SynthDef.new(\simplePlayerMono, {|bufNum, loop = 0, trig = 1, rate = 1, pos = 0, amp = 1, outbus = 0, pan =0 |

	var sig;

	sig = PlayBuf.ar(1, bufNum, rate: rate, startPos: pos * BufFrames.kr(bufNum), loop: loop);
	sig = Pan2.ar(sig , pan) * amp;
	sig = sig * EnvGen.kr(Env.asr(0.01,1,0.2),trig,doneAction:2);
	Out.ar(outbus, sig);
}).send(s);

SynthDef.new(\simplePlayOnceMono, {|bufNum, loop = 0, trig = 1, rate = 1, pos = 0, amp = 1, pan = 0, outbus = 0|

	var sig;

	sig = PlayBuf.ar(1, bufNum, rate: rate, startPos: pos * BufFrames.kr(bufNum));
	sig = Pan2.ar(sig ,pan) * amp;
	sig = sig * EnvGen.kr(Env.linen(0.01,BufDur.kr(bufNum) - 0.02,0.01),trig,doneAction:2);
	Out.ar(outbus, sig);
}).send(s);

SynthDef(\playWithTone, {|v_amp = 0.5, s_amp = 0.1, bufNum = 0, pan = 0, freq = 200, noiseFreq = 30, trig = 1 |

	var sig, p_sig, t_sig, bDur;

	p_sig = PlayBuf.ar(1, bufNum);
	t_sig = LFPar.ar(freq, mul:0.5) * LFNoise0.ar(noiseFreq);

	sig = Pan2.ar((p_sig * v_amp) + (t_sig * s_amp), pan);

	sig = sig * EnvGen.kr(Env.asr(releaseTime: 0.01),trig, doneAction:2);
	Out.ar(0,sig);


}).send(s);

SynthDef(\granPulseNoise, {|v_amp = 0.5, s_amp = 0.1, trigRate = 10, bufNum = 0, pan = 0, envDur = 5,  endPosR = 0.8, envBufNum = -1, trig = 1|

	var sig, a_sig, b_sig, rate = 1.0, endPos, grainDur;

	grainDur = 1/trigRate;

	a_sig = GrainBuf.ar(
		numChannels: 2,
		trigger: Impulse.ar(trigRate),
		dur: grainDur,
		sndbuf: bufNum,
		rate: rate,
		pos: Line.kr(0,endPosR,envDur),
		envbufnum: envBufNum) * EnvGen.kr(Env.new([1,1,0],[envDur,0.1]));

	b_sig = GrainBuf.ar(
		numChannels: 2,
		trigger: LFNoise0.kr(trigRate),
		dur: grainDur,
		sndbuf: bufNum,
		rate: rate,
		pos: endPosR,
		envbufnum: envBufNum) * EnvGen.kr(Env.new([0,0,1],[envDur,0.1]));

	sig = Pan2.ar(a_sig * v_amp + (b_sig * s_amp), pan);

	sig = sig * EnvGen.kr(Env.asr(releaseTime: 0.01),trig, doneAction:2);

	Out.ar(0,sig);

}).send(s);

SynthDef(\pedalTone, {|freq = 25, phase = 0, pan = 0, tFreq = 0.05, wFreq = 4, wampF = 0.2, fFreq = 1000, amp = 0.1, gate = 1|

	var wamp, swell, wobble, out;

	swell = SinOsc.kr(tFreq,phase,0.5,0.5);
	wobble = SinOsc.kr(wFreq,0,freq/40);
	wamp = SinOsc.kr(wampF,0,0.2,0.3);
	out = VarSaw.ar(freq, 0, wamp, swell);
	out = out * 0.8 + RHPF.ar(out, fFreq, 0.02, 0.2);
	out = Pan2.ar(out, pan) * amp;
	out = out * EnvGen.kr(Env.asr(4,1,0.01,'sine'),gate, doneAction:2);
	Out.ar(0, out);

}).send(s);

SynthDef.new( \shot , {

	arg amp = 1.0, pan = 0, shotDec = 0.5 ,combMul= 0.5, tweetAdd = 95, tweetMul = 0.25, tweetRel = 3.0;

	var sig, bang, tweets, tweetEnv, tMulHz;

	tMulHz = tweetAdd.midicps * tweetMul;

	bang = GrayNoise.ar([0.2,0.2]) * EnvGen.kr(Env.perc(0.001,shotDec));
	bang = AllpassN.ar( bang , 0.03, 0.03, 2 );
	tweetEnv = EnvGen.kr(Env.perc(0.1, tweetRel ).delay(0.1), doneAction: 2);
	tweets= SinOsc.ar( LFNoise2.ar(50, tMulHz, tweetAdd.midicps), mul: 0.1);
	tweets = CombN.ar(tweets, 0.01, 0.01, 1) * combMul + tweets * (1 - combMul);
	sig = bang + (tweets * tweetEnv);
	sig = Pan2.ar(sig, pan) * amp;
	Out.ar(0,sig);

}).send(s);


)


//load all the files into an identity dictionary

(

var path = "/Users/kimonsatan/Music/projectSamples/conditionalLove/samples",
dp = PathName.new(path);

~buf.do{|voice|
	voice.do{|samp| samp.free;}
};

~buf = ();

dp.folders.do{|v|



	var fp = v.allFolders[v.allFolders.size - 1].asSymbol;
	~buf.put(fp, ());

	v.postln;

	v.files.do{|f|
		var name;
		name = f.fullPath;
		name = name.split();
		name = name[name.size() -1];
		name = name.split($.);
		name = name[0];
		~buf.put(fp.asSymbol, ~buf.at(fp).put(name.asSymbol, Buffer.read(s, f.fullPath)));
	}

};

~onSynths.free;
~onSynths = Group.new;



)

~buf[\splats]


//start piece here


/*Msgs from meteor

//hit - addr - 0
//text - string - 1
//voice - string - 2
//vol - float - 3
//pan - float - 4

*/




(

//helper function
~packageMessage = {|msg|
	var dict = ();
	msg.do{|item, count|
		var id = count%2;
		if(count > 0 && id == 0,{
			dict.put(msg[count - 1].asSymbol, item);
		});
	};
	dict;
};




OSCdef(\blob).free;  // unregister OSCdef
OSCdef(\blob, {|msg|

	//var txt = msg[1], voice = msg[2], amp = msg[3].asFloat, pan = msg[4].asFloat;

	var options = Array.new();

	msg.do{|i c|
		if(c > 0){
			if(c%2 == 1 ,
				{ options = options.add(i.asSymbol)},
				{ options = options.add(i)}
			);
		};
	};

	options.postln;

	b = ~buf [\splats] ["232211_spit2"].asSymbol;
	x = Synth.new(\simplePlayOnceMono, [\bufNum, b , \pan, 0, \amp, 1.0 ]);


}, '/blob');


OSCdef(\hit).free;  // unregister OSCdef
OSCdef(\hit, {|msg|

	var txt = msg[1], voice = msg[2], amp = msg[3].asFloat, pan = msg[4].asFloat;
	msg.postln;


	x = Synth.new(\simplePlayOnceMono, [\bufNum, ~buf[voice.asSymbol][txt.asSymbol], \amp, amp, \pan, pan]);


}, '/hit');

OSCdef(\noteOn).free;  // unregister OSCdef
OSCdef(\noteOn, {|msg|

	var  voice = msg[1], synth = msg[2].asSymbol, v_amp = msg[3].asFloat, s_amp = msg[4].asFloat,
	pan = msg[5].asFloat;

	msg.postln;

	if(synth == \playWithTone , {

		x = Synth.new(\playWithTone, [
			\bufNum, ~buf[voice.asSymbol][\on],
			\freq, msg[6].asInt.midicps,
			\noiseFreq, msg[7].asInt,
			\pan, pan,
			\v_amp, v_amp,
			\s_amp, s_amp], ~onSynths
		);

	},{

		x = Synth.new(\granPulseNoise, [
			\bufNum, ~buf[voice.asSymbol][\on],
			\pan, pan,
			\v_amp, v_amp,
			\s_amp, s_amp,
			\trigRate, msg[6].asInt,
			\envDur, msg[7].asFloat,
			\endPosR, msg[8].asFloat,
		], ~onSynths
		);

	});

}, '/noteOn');

OSCdef(\noteOff).free;  // unregister OSCdef
OSCdef(\noteOff, {|msg|

	var  voice = msg[1], amp = msg[2].asFloat, pan = msg[3].asFloat;


	~onSynths.set(\trig, 0); //free all synths in the group

	x = Synth.new(\simplePlayOnceMono, [\bufNum, ~buf[voice.asSymbol][\off], \amp, amp, \pan, pan]);

}, '/noteOff');

OSCdef(\addTone).free;
OSCdef(\addTone, {|msg|



	var dict = ~packageMessage.value(msg);

	dict.postln;


	x = Synth.new(\pedalTone, [
		\phase, dict.at(\phase),
		\freq, rrand(100,500),
		\tFreq, dict.at(\freq),
		\wFreq, rrand(4,14),
		\wampF, 0.2,
		\fFreq, rrand(1000,2000),
		\pan, rrand(-1,1),
		\amp, rrand(0.1,0.5)

	]);

}, '/addTone');

OSCdef(\startPedal).free;
OSCdef(\startPedal, {|msg|

	~pedalSynths.free;
	~pedalSynths = Group.new;
	~pedalTask.stop;
	~pedalTask = Task({

		20.do{|count|

			x = Synth.new(\pedalTone, [
				\freq, 25 + (25 * count),
				\tFreq, rrand(0.05, 0.1),
				\wFreq, rrand(4,14),
				\wampF, 0.2 + (0.01 * count),
				\fFreq, rrand(1000,2000),
				\pan, 0.05 * count * [1,-1].choose,
				\amp, 0.6/(count +1)

			],~pedalSynths);

			rrand(15,30).wait;
		}


	}).start;


},'/startPedal');

OSCdef(\allOff).free;
OSCdef(\allOff, {|msg|

	~onSynths.set(\trig, 0);

	if(~pedalSynths != nil,{

		~pedalTask.stop;
		~pedalSynths.set(\gate, 0);
		~pedalSynths = nil;

	});

},'/allOff');


)







