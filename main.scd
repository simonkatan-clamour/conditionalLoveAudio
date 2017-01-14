x = {PinkNoise.ar([0.2,0.2])}.play;
x.free;

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

SynthDef.new(\splatPlayer, {|bufNum, loop = 0, trig = 1, rate = 1, pos = 0, amp = 1, pan = 0, outbus = 0|

	//only difference is a couple of mapping functions
	var sig, mpos, mrate;

	mpos = LinLin.kr(pos, 0, 1, 0, 0.3);
	mrate = LinExp.kr(pos, 0, 1, 0.4, 1.4);

	sig = PlayBuf.ar(1, bufNum, rate: mrate, startPos: mpos * BufFrames.kr(bufNum));
	sig = Pan2.ar(sig ,pan) * amp;
	sig = sig * EnvGen.kr(Env.linen(0.01,BufDur.kr(bufNum) - 0.02,0.01),trig,doneAction:2);
	Out.ar(outbus, sig);
}).send(s);


SynthDef.new(\simplePlayOnceStereo, {|bufNum, loop = 0, trig = 1, rate = 1, pos = 0, amp = 1, pan = 0, outbus = 0|

	var sig;

	sig = PlayBuf.ar(2, bufNum, rate: rate, startPos: pos * BufFrames.kr(bufNum));
	sig = Pan2.ar(sig ,pan) * amp;
	sig = sig * EnvGen.kr(Env.linen(0.01,BufDur.kr(bufNum) - 0.02,0.01),trig,doneAction:2);
	Out.ar(outbus, sig);
}).send(s);

SynthDef(\pedalTone, {|scidx = 1, freq = 25, phase = 3, pan = 0, tFreq = 0.05, wFreq = 4, wampF = 0.2, fFreq = 1000, amp = 0.0, gate = 1|

	var wamp, swell, wobble, out, lamp, xamp;

	swell = LFTri.kr(tFreq,phase,0.5,0.5);
	lamp = Lag3.kr(amp , 10);
	xamp = (-35 + (lamp * 25)).dbamp;
	SendReply.kr(Impulse.kr(5),'/pedal',  [swell * lamp], scidx);

	wobble = SinOsc.kr(wFreq,0, min(5,freq/40));
	wamp = SinOsc.kr(wampF,0,0.2,0.3);
	out = VarSaw.ar(freq + wobble, 0, wamp, swell);
	out = out * 0.8 + RHPF.ar(out, fFreq, 0.02, 0.2);
	out = Pan2.ar(out, pan) * xamp;
	out = out * EnvGen.kr(Env.asr(0.1,1,0.01,'sine'),gate, doneAction:2);
	Out.ar(0, out);

}).send(s);

SynthDef(\transSweep, {|scidx = 1, pan = 0, gate = 1|

	var sig;
	sig = WhiteNoise.ar(EnvGen.kr(Env.new([0,1],[4.0],2)));
	sig = Pan2.ar(sig, pan);
	sig = sig * EnvGen.kr(Env.asr(0.01,1,0.01),gate, doneAction:2);
	Out.ar(0, sig);

}).send(s);
)

//load all the files into an identity dictionary

(

var path = "/Users/kimonsatan/Music/projectSamples/conditionalLove/samples",
dp = PathName.new(path);

~buf.do{|v|
	v.do{|samp| samp.free;}
};

~buf = ();

dp.folders.do{|v|



	var fp = v.allFolders[v.allFolders.size - 1].asSymbol;
	fp.postln;
	~buf.put(fp.asSymbol, ());

	v.files.do{|f|
		var name;
		name = f.fullPath;
		name = name.split();
		name = name[name.size() -1];
		name = name.split($.);
		name = name[0];
		name.postln;
		f.postln;
		b = Buffer.read(s, f.fullPath);
		~buf.at(fp).put(name.asSymbol, b);
	}

};


)

~buf [\splats]






////////////////////////////OSC////////////////////////////////
(

~toneRefs = ();
~transRefs = ();

~toneSynths.free;
~toneSynths = Group.new;

~transSweeps.free;
~transSweeps = Group.new;


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



OSCdef(\startMisty).free;  // unregister OSCdef
OSCdef(\startMisty, {|msg|


	b = ~buf [\misty] .at('misty');
	~mistyPlayer = Synth.new(\simplePlayOnceStereo, [\bufNum, b , \pan, 0, \amp, 0.2 ]);


}, '/startMisty');



OSCdef(\splat).free;  // unregister OSCdef
OSCdef(\splat, {|msg|

	var dict = ~packageMessage.value(msg);

	b =~buf [\splats].at( '338116_splat1');
	x = Synth.new(\splatPlayer,
			[\bufNum, b ,
			\pan, dict.at(\pan),
			\amp , 1.0,
			\pos, dict.at(\pos) ,
			\rate, dict.at(\rate)
	]);




}, '/splat');



~vizNode = NetAddr("127.0.0.1", 12345); // send data back to vizualizer

~replyNode.free;
~replyNode = OSCFunc({ |msg|

	~vizNode.sendMsg("/poll", msg[2], msg[3].abs);

}, '/pedal');



OSCdef(\addTone).free;
OSCdef(\addTone, {|msg|


	var id, dict = ~packageMessage.value(msg);

	dict.postln;

	id = ("synth_" + dict.at(\scidx)).asSymbol;

	x = Synth.head(~toneSynths, \pedalTone, [
		\scidx, dict.at(\scidx),
		\freq, rrand(20.0, 72.0).midicps,
		\tFreq, dict.at(\freq),
		\wFreq, rrand(15,20),
		\wampF, 0.2,
		\fFreq, rrand(1000,2000),
		\pan, dict.at(\pan),
		\amp, 0.1

	]);


	~toneRefs.put(id, x);


}, '/addTone');

OSCdef(\updateTone).free;
OSCdef(\updateTone, {|msg|



	var amp, id, dict = ~packageMessage.value(msg);
	id = ("synth_" + dict.at(\scidx)).asSymbol;



	~toneRefs.at(id).set(\amp, dict.at(\amp).asFloat);

}, '/updateTone');

OSCdef(\endTone).free;
OSCdef(\endTone, {|msg|

	var id, dict = ~packageMessage.value(msg);
	id = ("synth_" + dict.at(\scidx)).asSymbol;

	~toneRefs.at(id).set(\gate, 0);
	~transRefs.at(id).set(\gate, 0);

	//also end trans tone here

}, '/endTone');

OSCdef(\transTone).free;
OSCdef(\transTone, {|msg|


	var id, dict = ~packageMessage.value(msg);

	dict.postln;

	id = ("synth_" + dict.at(\scidx)).asSymbol;

	x = Synth.head(~transSweeps, \transSweep, [
		\scidx, dict.at(\scidx),
		\pan, dict.at(\pan)
	]);


	~transRefs.put(id, x);


}, '/transTone');



OSCdef(\allOff).free;
OSCdef(\allOff, {|msg|

	~toneSynths.set(\gate, 0);
	~transSweeps.set(\gate, 0);
	~mistyPlayer.free;

},'/allOff');

)

(

fork{
	10.do{
		b =~buf [\splats].at( '338116_splat1');
		x = Synth.new(\splatPlayer,
			[\bufNum, b , \pan, 0, \amp , 1.0, \pos, rrand(0.0 ,1.0), \rate, rrand(0.0 ,1.0) ]);
		2.0.wait;
	}
}
)

exprand(0.01,1.2)

(
		b =~buf [\splats].at( '338116_splat1');
		x = Synth.new(\splatPlayer, [\bufNum, b , \pan, 0, \amp, 1.0, \pos, 0.3, \rate,  1   ]);

)








