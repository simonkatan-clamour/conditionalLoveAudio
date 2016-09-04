{ Poll.kr(Impulse.kr(10), , \test) }.play(s);

(
{

	var amp, sig, id = 1234;
	amp = Line.kr(0,1,1, doneAction:2 );
	Poll.kr(Impulse.kr(20),amp, \test, id);
	sig = SinOsc.ar(375, 0, amp);

}.play(s);

)

(
o.free;
o = OSCFunc({arg msg; msg.postln;}, '/tr', s.addr);
)

~vizNode.sendMsg("/poll",12,3);