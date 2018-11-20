x = {PinkNoise.ar([0.2,0.2])}.play;
x.free;

NetAddr.langPort;

(

s.quit;
//ServerOptions.inDevices.postln;
o = ServerOptions.new;
o.outDevice = "Scarlett 2i4 USB";
//o.outDevice= "Built-in Output";
o.inDevice = "Soundflower (2ch)";
s.options = o;
s.boot;


s.doWhenBooted({

	Speech.init(8); //One voice for each accent

	SynthDef(\fader, {|inbus=0, outbus=0, amp=1.0|
		var sig;
		sig = In.ar(inbus,2) * Lag.kr(amp);
		Out.ar(outbus, sig);
	}).send(s);


	SynthDef(\StoreSpeech, {|buf = 0, trigger =1|
		var env;
		env = EnvGen.kr(Env.asr(0.01,1,0.01), trigger, doneAction: 2);
		RecordBuf.ar(In.ar(2,1) * trigger, buf, trigger: trigger, doneAction: 2, loop:0 );
	}).send(s);


	SynthDef.new(\simplePlayerMono, {|bufNum, loop = 0, trig = 1, rate =  1, pos = 0, amp = 1, outbus = 0, pan =0 |

		var sig;

		sig = PlayBuf.ar(1, bufNum, rate: rate, startPos: pos * BufFrames.kr(bufNum), loop: loop);
		sig = Pan2.ar(sig , pan) * amp;
		sig = sig * EnvGen.kr(Env.asr(0.01,1,0.2),trig,doneAction:2);
		Out.ar(outbus, sig);
	}).send(s);

	SynthDef.new(\simplePlayOnceMono, {|bufNum, trig = 1, rate = 1, pos = 0, amp = 1, pan = 0, outbus = 0|

		var sig;

		sig = PlayBuf.ar(1, bufNum, rate: rate, startPos: pos * BufFrames.kr(bufNum));
		sig = Pan2.ar(sig ,pan) * amp;
		sig = sig * EnvGen.kr(Env.linen(0.01,BufDur.kr(bufNum) - 0.02,0.01),trig,doneAction:2);
		Out.ar(outbus, sig);
	}).send(s);

SynthDef.new(\splatPlayer, {|bufNum, loop = 0, trig = 1, rate = 1, pos = 0, amp = 1, freq = 0, pan = 0, outbus = 0|

		var sig, mpos, mrate, mfreq;

		mpos = LinLin.kr(pos, 0, 1, 0, 0.3);
		mrate = LinExp.kr(rate, 0, 1, 0.9, 1.5);
		mfreq = LinLin.kr(rate, 0, 1, -500, 500);

		sig = PlayBuf.ar(1, bufNum, rate: mrate, startPos: mpos * BufFrames.kr(bufNum));
	sig = FreqShift.ar(sig,mfreq);
		sig = Pan2.ar(sig ,pan) * amp;
		sig = sig * EnvGen.kr(Env.linen(0.01,BufDur.kr(bufNum) - 0.02,0.01),trig,doneAction:2);
		Out.ar(outbus, sig);
	}).send(s);


	SynthDef.new(\simplePlayOnceStereo, {|bufNum, rate = 1, gate=1, pos = 0, dur=5000, amp = 1, pan = 0, outbus = 0, in = 0.001, out = 0.01|

		var sig, pf;

		dur = min(dur, BufDur.kr(bufNum) - pos);
		pf = (pos/BufDur.kr(bufNum))  * BufFrames.kr(bufNum);
		sig = PlayBuf.ar(2, bufNum, rate: rate, startPos: pf);
		sig = Pan2.ar(sig ,pan) * amp;
		sig = sig * EnvGen.kr(Env.linen(in, dur - (in + out),out),1,doneAction:2);
		sig = sig * EnvGen.kr(Env.asr(in,1,out,'sine'),gate, doneAction:2);
		Out.ar(outbus, sig);
	}).send(s);

	SynthDef.new(\simplePlayStereo, {|bufNum, loop = 1, trig = 1, rate = 1, gate=1, pos = 0, dur = 5000, amp = 1, pan = 0, in = 0.001, out = 0.01, outbus = 0|
		var sig, pf;
		dur = min(dur, BufDur.kr(bufNum) - pos);
		pf = (pos/BufDur.kr(bufNum))  * BufFrames.kr(bufNum);
		sig = PlayBuf.ar(2, bufNum, rate: rate, startPos: pf, loop: 1, trigger: Impulse.ar(1/dur));
		sig = Pan2.ar(sig ,pan) * amp;
		sig = sig * EnvGen.kr(Env.asr(in,1,out,'sine'),gate, doneAction:2);
		Out.ar(outbus, sig);
	}).send(s);

	SynthDef(\pedalTone, {|scidx = 1, freq = 25, phase = 3, pan = 0, tFreq = 0.05, wFreq = 4, wampF = 0.2, fFreq = 1000, amp = 0.0, gate = 1, outbus=0|

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
		Out.ar(outbus, out);

	}).send(s);

	SynthDef(\transSweep, {|scidx = 1, pan = 0, gate = 1, amp = 0, outbus=0|

		var sig;
		sig =WhiteNoise.ar(EnvGen.kr(Env.new([0,1],[4.0],2))) * amp;
		sig = HPF.ar(sig, ExpRand(1,2000));
		sig = Pan2.ar(sig, pan);
		sig = sig * EnvGen.kr(Env.asr(0.01,1,0.01),gate, doneAction:2);
		Out.ar(outbus, sig);

	}).send(s);


	SynthDef(\crawlerTone, {
		|scidx = 0, gate =1, bufNum = 0, pan = 0, amp = 0.5, prange = 0.5, pstart = 0.1,   energy = 0, rot = 0, baseRate = 0.01, outbus=0 |

		//energy comes from transEnv of displayClass

		var trate, dur, rate, trig, pos, tpan, sig;

		trate = 45 * energy;
		trig = LFPulse.ar(trate, width: 0.1, add: -0.5);

		dur = 0.05 + pow(energy, 0.5);
		pos = BufDur.kr(bufNum) *  (rot * 0.75) + TRand.kr(0.0, 0.1, trig);

		rate = baseRate;

		tpan = TRand.kr(-0.1,0.1,trig) + max(-0.9,min(0.9,pan));


		sig = TGrains.ar(
			2,      //output
			trig , //trigger
			bufNum,
			rate,
			pos,
			dur,
			tpan,
			0 ,
			2);

		sig = sig * EnvGen.kr(Env.asr(0.01,1.0,0.1), gate ,doneAction: 2) * amp * energy * 10;
		Out.ar(outbus, sig);

	}).send(s);



});


)




/////////////////////

//to load files manually

~loadSamplesFunc.value("/Users/kimonsatan/Music/projectSamples/conditionalLove/samples");

/////////////////////

////////////////////////////OSC////////////////////////////////
(

~samplePath = "/Users/kimonsatan/Music/projectSamples/conditionalLove/samples/";

~serverNode = NetAddr("127.0.0.1", 12345); // send data back to node server

~toneRefs = ();
~transRefs = ();
~crawlerRefs = ();

~master.free;
~masterSynth.free;
~master = Bus.audio(s,2);
~masterSynth = Synth.new(\fader, [\inbus, ~master]);

~toneSynths.free;
~toneSynths = Group.new;

~transSweeps.free;
~transSweeps = Group.new;

~crawlerSynths.free;
~crawlerSynths = Group.new;

~polyPlayers.free;
~polyPlayers = Group.new;

~polyPlayers1.free;
~polyPlayers1 = Group.new;

~polyPlayers2.free;
~polyPlayers2 = Group.new;

~queuePlayers.free;
~queuePlayers = Group.new;


~voiceGroup.free;
~voiceGroup = Group.new;

//set the accents
~voices = [11,18,19,30,35,38,40,33];
~voices.do({|voice, count|
	Speech.setSpeechVoice(count, voice);
});

~winSample = Buffer.read(s, ~samplePath ++ "votes/correct.wav");

~isQueueTaskRunning = false;
~queueTask = nil;
~queueBuf = nil;
~queueAmp = 0.5;



////////////////////////////// helper functions ///////////////////////////////

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

~loadSamplesFunc = {|path|


	var dp = PathName.new(path);

	"load samples".postln;

	~buf.do{|v|
		v.do{|samp| samp.free;}
	};

	~buf = ();

	dp.folders.do{|v|
		var fp = v.allFolders[v.allFolders.size - 1].asSymbol;
		~buf.put(fp.asSymbol, ());

		v.files.do{|f|
			var name;
			name = f.fullPath;
			name = name.split();
			name = name[name.size() -1];
			name = name.split($.);
			name = name[0];
			b = Buffer.read(s, f.fullPath);
			~buf.at(fp).put(name.asSymbol, b);
		}

};

};

//function to add phrase

~addphrase = { |phrase|

	var recorder;

/*	phrase.postln;*/

	Speech.doneAction_({ |voice|
		recorder.set(\trigger, 0);
		~isRecording = false;
		~serverNode.sendMsg("/phraseComplete", phrase[0], phrase[1], phrase[3]); //call back message
		("done recording " + phrase).postln;
	});



	Buffer.alloc(s, 44100 * 4, 1,
	{ |buffer|
		var key = (phrase[0].asString ++ "_" ++ phrase[1].asString ++ "_" ++ phrase[3].asString).asSymbol;
		~phraseStore.at(key).free; //free the old buffer if it exists
		~phraseStore.put(key,buffer);
		recorder = Synth.new(\StoreSpeech, [\buf, buffer]);
		phrase[2].asString.speak(phrase[3]);
	});

};


~clearPhrases =  {

	if(~phraseStore != nil, {
		~phraseStore.keys.do(
			{|key|
				~phraseStore.at(key).free;
			}
		)
	});

	~phraseStore = ();
	~phraseQueue = List[];
	~isRecording = false;

};

~clearPhrases.value();

//////////////////////////////////nodes//////////////////////////////////////////


OSCdef(\setMasterLevel).free;  // unregister OSCdef
OSCdef(\setMasterLevel, {|msg|

	var dict = ~packageMessage.value(msg), para=[];

	dict.at(\amp).postln;
	if(dict.at(\amp) != nil, {~masterSynth.set(\amp, dict.at(\amp))});

}, '/setMasterLevel');


OSCdef(\loadSamples).free;  // unregister OSCdef
OSCdef(\loadSamples, {|msg|

	~loadSamplesFunc.value(~samplePath);

}, '/loadSamples');


OSCdef(\playStereo).free;  // unregister OSCdef
OSCdef(\playStereo, {|msg|


	var dict = ~packageMessage.value(msg),  loop = 0, synth = \simplePlayOnceStereo, para;


	if(dict.at(\solo).asString == "true", {

		if(dict.at(\channel) == 0, {~polyPlayers.set(\gate, 0);});
		if(dict.at(\channel) == 1, {~polyPlayers1.set(\gate, 0);});
		if(dict.at(\channel) == 2, {~polyPlayers2.set(\gate, 0);})

	});
	if(dict.at(\loop).asString == "true", {
		synth = \simplePlayStereo
	});

	b = ~buf [dict.at(\dir).asSymbol] .at(dict.at(\file).asSymbol);
	para =  [
		\bufNum, b
	];

	if(dict.at(\amp) != nil, {para = para.add(\amp); para = para.add(dict.at(\amp))});
	if(dict.at(\in) != nil, {para = para.add(\in); para = para.add(dict.at(\in))});
	if(dict.at(\out) != nil, {para = para.add(\out); para = para.add(dict.at(\out))});
	if(dict.at(\pos) != nil, {para = para.add(\pos); para = para.add(dict.at(\pos))});
	if(dict.at(\dur) != nil, {para = para.add(\dur); para = para.add(dict.at(\dur))});

	para.add(\outbus);
	para.add(~master);
	//para.postln;

	if(dict.at(\channel) == nil, {Synth.head(~polyPlayers, synth, para)});
	if(dict.at(\channel) == 0, {Synth.head(~polyPlayers, synth, para)});
	if(dict.at(\channel) == 1, {Synth.head(~polyPlayers1, synth, para)});
	if(dict.at(\channel) == 2, {Synth.head(~polyPlayers2, synth, para)});

}, '/playStereo');


OSCdef(\playqueue).free;
OSCdef(\playqueue, {|msg|

	var dict = ~packageMessage.value(msg);

	~queueBuf = ~buf.at(dict.at(\dir).asSymbol).at(dict.at(\file).asSymbol);
	~queueAmp = dict.at(\amp);

	if(~isQueueTaskRunning == false,
	{
			~queueTask = Task({

				loop
				{
					var dur = ~queueBuf.numFrames/44100;
					Synth.head(~queuePlayers,\simplePlayOnceStereo,
						[
							\bufNum, ~queueBuf,
							\dur, dur,
							\amp, ~queueAmp,
							\outbus, ~master

					]);
					dur.wait;
				}

			}).play();

			~isQueueTaskRunning = true;

	});

}, '/playqueue');


OSCdef(\endqueue).free;
OSCdef(\endqueue, {|msg|

	if(~isQueueTaskRunning == true,
	{
			~queueTask.stop();
			~isQueueTaskRunning = false;
	});

}, '/endqueue');

OSCdef(\cutqueue).free;
OSCdef(\cutqueue, {|msg|

	if(~isQueueTaskRunning == true,
	{
			~queueTask.stop();
			~isQueueTaskRunning = false;
	});

	~queuePlayers.set(\gate, 0);

}, '/cutqueue');

OSCdef(\splat).free;  // unregister OSCdef
OSCdef(\splat, {|msg|

	var dict = ~packageMessage.value(msg);

	//dict.postln;

	b =~buf [\splats].at( '338116_splat3');
	x = Synth.new(\splatPlayer,
			[\bufNum, b ,
			\pan, dict.at(\pan),
			\amp , dict.at(\pan),
			\pos, dict.at(\pos) ,
			\rate, dict.at(\rate),
			\freq, dict.at(\freq),
			\outbus, ~master
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

	//dict.postln;

	id = ("synth_" + dict.at(\scidx)).asSymbol;

	x = Synth.head(~toneSynths, \pedalTone, [
		\scidx, dict.at(\scidx),
		\freq, rrand(20.0, 72.0).midicps,
		\tFreq, dict.at(\freq),
		\wFreq, rrand(15,20),
		\wampF, 0.2,
		\fFreq, rrand(1000,2000),
		\pan, dict.at(\pan),
		\amp, 0.0,
		\outbus, ~master

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

	//dict.postln;

	id = ("synth_" + dict.at(\scidx)).asSymbol;

	x = Synth.head(~transSweeps, \transSweep, [
		\scidx, dict.at(\scidx),
		\pan, dict.at(\pan),
		\amp, dict.at(\amp),
		\outbus, ~master
	]);


	~transRefs.put(id, x);  //TODO why two methods ?


}, '/transTone');


OSCdef(\startCrawler).free;
OSCdef(\startCrawler, {|msg|


	var id, buf, sampArray, dict = ~packageMessage.value(msg);

	//dict.postln;

	id = ("synth_" + dict.at(\scidx)).asSymbol;

	sampArray = [\crane, \catBird, \dino, \magpie];

	buf=~buf[\crawlers].at(sampArray[(dict.at(\blobSeed) * sampArray.size()).floor]);


	x = Synth.head(~crawlerSynths, \crawlerTone, [
		\bufNum, buf,
		\scidx, dict.at(\scidx),
		\pan, dict.at(\pan),
		\amp, 0.0,
		\outbus, ~master
	]);


	~crawlerRefs.put(id, x);



}, '/startCrawler');


OSCdef(\updateCrawler).free;
OSCdef(\updateCrawler, {|msg|


	var id, amp, rot, dict = ~packageMessage.value(msg);
	id = ("synth_" + dict.at(\scidx)).asSymbol;

	rot = (abs(dict.at(\rot))%(2 *pi))/(2*pi);
	//rot.postln;
	amp = (-10 + (pow(dict.at(\death),2.0) * -60)).dbamp; //fade out
	amp = amp * dict.at(\mul);

	~crawlerRefs.at(id).set(\energy, dict.at(\energy), \amp, amp, \rot, rot, \pan, dict.at(\pan), \baseRate, dict.at(\colSeed) );


}, '/updateCrawler');



OSCdef(\endCrawler).free;
OSCdef(\endCrawler, {|msg|


	var id, dict = ~packageMessage.value(msg);
	id = ("synth_" + dict.at(\scidx)).asSymbol;

	//"end crawler".postln;
	~crawlerRefs.at(id).set(\gate, 0);


}, '/endCrawler');


OSCdef(\allOff).free;
OSCdef(\allOff, {|msg|

	~toneSynths.set(\gate, 0);
	~transSweeps.set(\gate, 0);
	~crawlerSynths.set(\gate, 0);
	~polyPlayers.set(\gate, 0);
	~polyPlayers1.set(\gate, 0);
	~polyPlayers2.set(\gate, 0);
	~voiceGroup.set(\gate, 0);
	~queuePlayers.set(\gate, 0);

	if(~isQueueTaskRunning == true,
	{
			~queueTask.stop();
			~isQueueTaskRunning = false;
	});

	~clearPhrases.value();

	"allOff".post;

},'/allOff');

OSCdef(\polyOff).free;
OSCdef(\polyOff, {|msg|

	var dict = ~packageMessage.value(msg);

	dict.at(\channel).postln;

	if(dict.at(\channel) == 0, {~polyPlayers.set(\gate, 0)});
	if(dict.at(\channel) == 1, {~polyPlayers1.set(\gate, 0)});
	if(dict.at(\channel) == 2, {~polyPlayers2.set(\gate, 0)});
	if(dict.at(\channel) == \all, {
		"all polys off".postln;
		~polyPlayers.set(\gate, 0);
		~polyPlayers1.set(\gate, 0);
		~polyPlayers2.set(\gate, 0)
	});

	msg.postln;

},'/polyOff');

OSCdef(\recordPhrases).free;  // unregister OSCdef
OSCdef(\recordPhrases, {|msg|

	msg.postln;

	//TODO check if phrase is already there....

	~voices.do({|item, count|
		~phraseQueue.addFirst([msg[1], 0, msg[2].asString, count]);
		~phraseQueue.addFirst([msg[1], 1, msg[3].asString, count]);
	});


}, '/recordPhrases');

OSCdef(\recordCallPhrase).free;  // unregister OSCdef
OSCdef(\recordCallPhrase, {|msg|

	msg.postln;

	//TODO check if phrase is already there....

	~phraseQueue.addFirst([msg[1], 0, msg[2].asString, 7]); //voice 7 is currently used as win voice


}, '/recordCallPhrase');



OSCdef(\speakPhrase).free;  // unregister OSCdef
OSCdef(\speakPhrase, {|msg|


	var dict = ~packageMessage.value(msg);

	var key = dict.at(\id) ++ "_" ++ dict.at(\choice) ++ "_" ++ dict.at(\voice);
	x = Synth.head(~voiceGroup, \simplePlayOnceMono,
		[
			\bufNum, ~phraseStore[key.asSymbol],
			\amp, dict.at(\amp).asFloat,
			\pan, dict.at(\pan).asFloat,
			\rate, dict.at(\rate).asFloat,
			\outbus, ~master
	]);

},'/speakPhrase');

//TODO speak win phrase function

OSCdef(\resetPhrases).free;  // unregister OSCdef
OSCdef(\resetPhrases, {|msg|

	"resetall".postln;
	~clearPhrases.value();
	~voiceGroup.free;
	~voiceGroup = Group.new;

},'/resetPhrases');

OSCdef(\voteComplete).free;  // unregister OSCdef
OSCdef(\voteComplete, {|msg|

	//mute the voice group - play the win music

	var dict = ~packageMessage.value(msg);

	var key = dict.at(\id).asString;

	("concluded " + key).postln;
	~voiceGroup.set(\amp,0.0); //mute any current synths

	x = Synth(\simplePlayOnceMono, [\bufNum, ~winSample, \amp, dict.at(\amp), \pan, 0, \rate, 1, \outbus, ~master]);

	{
		3.0.wait;

		/*
		//NOT playing win samples
		~serverNode.sendMsg("/winSampleDone"); //call back message
		y = Synth(\simplePlayOnceMono, [\bufNum, ~phraseStore[key.asSymbol], \amp, 0.35, \pan, 0, \rate, 1]);
		(~phraseStore[key.asSymbol].numFrames * 0.65/44100).wait;
		*/

		~serverNode.sendMsg("/resumeVote"); //call back message

	}.fork;


},'/voteComplete');

OSCdef(\playBing).free;
OSCdef(\playBing, {|msg|

		var dict = ~packageMessage.value(msg);
		x = Synth(\simplePlayOnceMono, [\bufNum, ~winSample, \amp, dict.at(\amp), \pan, 0, \rate, 1, \outbus, ~master]);

},'/playBing')

)


//////////////////////////////////// Process the record queue //////////////////////////

(

~recordQueue = Routine(
{
	loop
	{
		if(~phraseQueue.size() > 0,
		{

			if(~isRecording == false,
			{
				var phrase = ~phraseQueue.pop();
				~isRecording = true;
				~addphrase.value(phrase);
			},{
				//"already recording".postln
			});


		});
		0.05.wait;
	}

}).play;

)




