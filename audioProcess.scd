
//load file into buffer

(
~fp = "/Users/kimonsatan/code/JavaScript/projects/clamourTests/blobSoundTester/samples/20472_woodpigeonnr_03.wav";

b = Buffer.read(s, ~fp);

)

c = Buffer.alloc(s, b.numFrames, 1); //recoprd buffer

// now play it
(

x = {
	var sig, dur;
	dur = BufDur.kr(b);
	sig = PlayBuf.ar(1, b,  BufRateScale.kr(b) * -1, startPos: b.numFrames loop: 0);
	sig = RLPF.ar(sig,
		XLine.kr(50, 1500, dur , doneAction: 2),
		0.1);
	RecordBuf.ar(sig * 0.2, c );
	sig = Pan2.ar(sig * 0.2, 0);



}.play;


)

//check the results
{PlayBuf.ar(1,c)}.play

(
c.write("/Users/kimonsatan/Desktop/test.wav", sampleFormat: 'int16');
)



b.free;
c.free;




