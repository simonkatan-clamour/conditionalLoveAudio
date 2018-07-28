
//AUDIO SETUP
//With sound output set to soundflower in preferences
//Soundflower output set to none


//start the server with the correct options
(

s.quit;
//ServerOptions.inDevices.postln;
o = ServerOptions.new;
o.outDevice = "Scarlett 2i4 USB";
//o.outDevice = "Built-in Output";
o.inDevice = "Soundflower (2ch)";
s.options = o;
s.boot;

s.doWhenBooted({

	"loading synthDefs".postln;

	SynthDef(\StoreSpeech, {|buf = 0, trigger =1|
		var env;
		env = EnvGen.kr(Env.asr(0.01,1,0.01), trigger, doneAction: 2);
		RecordBuf.ar(In.ar(2,1) * trigger, buf, trigger: trigger, doneAction: 2, loop:0 );
	}).send(s);

	Speech.init(8); //One voice for each accent

	SynthDef.new(\simplePlayOnceMono, {|bufNum, trig = 1, rate = 1, pos = 0, amp = 1, pan = 0, outbus = 0|

		var sig;
		sig = PlayBuf.ar(1, bufNum, rate: rate, startPos: pos * BufFrames.kr(bufNum));
		sig = Pan2.ar(sig ,pan) * Lag.kr(amp,0.05);
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


	~voiceGroup = Group.new;

});

~serverNode = NetAddr("127.0.0.1", 12345); // send data back to node server

)

////////////////////////////////////////////////////////////////////

(

var samplePath = "/Users/kimonsatan/Music/projectSamples/conditionalLove/samples/";

//set the accents
~voices = [11,18,19,30,35,38,40,33];
~voices.do({|voice, count|
	Speech.setSpeechVoice(count, voice);
});


~winSample = Buffer.read(s, samplePath ++ "votes/industrial.wav");

//function to add phrase to

~addphrase = { |phrase|

	var recorder;

	phrase.postln;

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

)

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


//Stop the queue routine
~recordQueue.stop;

(

OSCdef(\recordPhrases).free;  // unregister OSCdef
OSCdef(\recordPhrases, {|msg|

	msg.postln;

	//TODO check if phrase is already there....
	~voices.do({|item, count|
		~phraseQueue.addFirst([msg[1], 0, msg[2].asString, count]);
		~phraseQueue.addFirst([msg[1], 1, msg[3].asString, count]);
	});


}, '/recordPhrases');

OSCdef(\recordWinPhrase).free;  // unregister OSCdef
OSCdef(\recordWinPhrase, {|msg|

	msg.postln;

	//TODO check if phrase is already there....

	~phraseQueue.addFirst([msg[1], 0, msg[2].asString, 7]); //voice 7 is currently used as win voice
	~phraseQueue.addFirst([msg[1], 1, msg[3].asString, 7]);


}, '/recordWinPhrase');

OSCdef(\speakPhrase).free;  // unregister OSCdef
OSCdef(\speakPhrase, {|msg|

	//TODO add this to a group for voice
	var key = msg[1].asString ++ "_" ++ msg[2].asString ++ "_" ++ msg[3].asString;
	x = Synth.head(~voiceGroup, \simplePlayOnceMono, [\bufNum, ~phraseStore[key.asSymbol], \amp, 0.15, \pan, msg[4].asFloat, \rate, msg[5].asFloat]);

},'/speakPhrase');

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

	var key = msg[1].asString ++ "_win_" ++ msg[2].asString ++ "_7";


	("concluded " + key).postln;
	~voiceGroup.set(\amp,0.0); //mute any current synths - perhaps better as a bus ?
	x = Synth(\simplePlayOnceStereo, [\bufNum, ~winSample, \amp, 0.15, \pan, 0, \rate, 1]);

	{
		(~winSample.numFrames * 0.75/44100).wait;
		~serverNode.sendMsg("/winSampleDone"); //call back message
		y = Synth(\simplePlayOnceMono, [\bufNum, ~phraseStore[key.asSymbol], \amp, 0.35, \pan, 0, \rate, 1]);
		(~phraseStore[key.asSymbol].numFrames/44100).wait;
		~serverNode.sendMsg("/resumeVote"); //call back message
	}.fork;


},'/voteComplete')

)




/////////////////////////////////////DEBUGGING///////////////////////////////////////



/*~serverNode.sendMsg("/phraseComplete", "test", 0); //call back message

(

~phraseQueue.addFirst("a test 0");
~phraseQueue.addFirst("a test 1");
~phraseQueue.addFirst("a test 2");
~phraseQueue.addFirst("a test 3");
~phraseQueue.addFirst("a test 4");
~phraseQueue.addFirst("a test 5");
~phraseQueue.addFirst("a test 6");
~phraseQueue.addFirst("a test 7");
~phraseQueue.addFirst("a test 8");
~phraseQueue.addFirst("a test 9");
~phraseQueue.addFirst("a test 10");
~phraseQueue.addFirst("a test 11");
~phraseQueue.addFirst("a test 12");
~phraseQueue.addFirst("a test 13");
~phraseQueue.addFirst("a test 14");
~phraseQueue.addFirst("a test 15");
~phraseQueue.addFirst("a test 16");
~phraseQueue.addFirst("a test 17");
~phraseQueue.addFirst("a test 18");
~phraseQueue.addFirst("a test 19");

)*/



//Play throught the phraseStore

(
t = Task({

		~phraseStore.keys.do({|key|
			key.postln;
			p = {
				var sig;
				sig = PlayBuf.ar(1, ~phraseStore.at(key.asSymbol), doneAction: 2, startPos: 0, rate: 1.0);
				sig = Pan2.ar(sig * rrand(0.1,0.2), rrand(-1.0,1.0))
			}.play;

			2.0.wait;
		});

}).play;
)

t.stop;

(
x = Synth(\simplePlayOnceMono, [\bufNum, ~phraseStore.at("5afc6805fa154528944d3f42 _ 0 _ 7".asSymbol), \amp, 0.25, \pan, 0,\rate, 1]);
)

(
~phraseStore.keys.do{|item,count,key|

	item.postln;
}
)


