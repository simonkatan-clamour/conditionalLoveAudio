
//AUDIO SETUP
//With sound output set to soundflower in preferences
//Soundflower output set to none


//start the server with the correct options
(

s.quit;
//ServerOptions.inDevices.postln;
o = ServerOptions.new;
o.outDevice = "Scarlett 2i4 USB";
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
		sig = Pan2.ar(sig ,pan) * amp;
		sig = sig * EnvGen.kr(Env.linen(0.01,BufDur.kr(bufNum) - 0.02,0.01),trig,doneAction:2);
		Out.ar(outbus, sig);
	}).send(s);

});

~serverNode = NetAddr("127.0.0.1", 12345); // send data back to node server

)

////////////////////////////////////////////////////////////////////

(

//set the accents
~voices = [11,18,19,30,35,38,40,33];
~voices.do({|voice, count|
	Speech.setSpeechVoice(count, voice);
});


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



//function to add phrase to

~addphrase = { |phrase, voiceIdx = 0|

	var recorder;

	Speech.doneAction_({ |voice|
		recorder.set(\trigger, 0);
		~isRecording = false;
		~serverNode.sendMsg("/phraseComplete", phrase, voiceIdx); //call back message
		("done recording " + phrase).postln;
	});


	Buffer.alloc(s, 44100 * 4, 1,
	{ |buffer|
		~phraseStore.at(phrase.asSymbol).free; //free the old buffer if it exists
		~phraseStore.put(phrase.asSymbol, buffer); //TODO implement multiVoice
		recorder = Synth.new(\StoreSpeech, [\buf, buffer]);
		phrase.speak(voiceIdx);
	});

};

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
				~addphrase.value(phrase, rrand(0,~voices.size())); //TODO remove random voice
			},{
				//"all voices occupied".postln
			});


		});
		0.05.wait;
	}

}).play;
)


//Stop the queue routine
~recordQueue.stop;

(

OSCdef(\recordPhrase).free;  // unregister OSCdef
OSCdef(\recordPhrase, {|msg|

	msg[1].postln;

	//TODO check if phrase is already there....

	~phraseQueue.addFirst(msg[1].asString); //TODO multivoice here


}, '/recordPhrase');

OSCdef(\speakPhrase).free;  // unregister OSCdef
OSCdef(\speakPhrase, {|msg|
	msg.postln;
	x = Synth(\simplePlayOnceMono, [\bufNum, ~phraseStore[msg[1].asSymbol], \amp, 0.2, \pan, rrand(-0.75, 0.75)]);

},'/speakPhrase')

)

/////////////////////////////////////DEBUGGING///////////////////////////////////////

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

)



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