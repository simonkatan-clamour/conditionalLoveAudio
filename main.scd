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
	Poll.kr(Impulse.kr(10), swell * lamp, \pedal , scidx);
	wobble = SinOsc.kr(wFreq,0, min(5,freq/40));
	wamp = SinOsc.kr(wampF,0,0.2,0.3);
	out = VarSaw.ar(freq + wobble, 0, wamp, swell);
	out = out * 0.8 + RHPF.ar(out, fFreq, 0.02, 0.2);
	out = Pan2.ar(out, pan) * xamp;
	out = out * EnvGen.kr(Env.asr(0.1,1,0.01,'sine'),gate, doneAction:2);
	Out.ar(0, out);

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

~toneSynths.free;
~toneSynths = Group.new;


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
	~mistyPlayer = Synth.new(\simplePlayOnceStereo, [\bufNum, b , \pan, 0, \amp, 0.25 ]);


}, '/startMisty');



OSCdef(\splat).free;  // unregister OSCdef
OSCdef(\splat, {|msg|

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
	"splat".postln;
	b =~buf [\splats].at( '338116_splat1');
	x = Synth.new(\simplePlayOnceMono, [\bufNum, b , \pan, 0, \amp, 1.0 ]);


}, '/splat');



~vizNode = NetAddr("127.0.0.1", 12345); // send data back to vizualizer

~pollNode.free;
~pollNode = OSCFunc(
{
	arg msg;
	~vizNode.sendMsg("/poll", msg[2], msg[3].abs);
},
'/tr', s.addr);

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



OSCdef(\allOff).free;
OSCdef(\allOff, {|msg|

	~toneSynths.set(\gate, 0);
	~mistyPlayer.free;

},'/allOff');


)





