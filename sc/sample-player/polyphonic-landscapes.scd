(
///~~~ SERVER CLEANUP ~~~///
s.freeAll;
~cleanup = {
	Pdef.removeAll;
	ServerBoot.removeAll;
	ServerQuit.removeAll;
	ServerTree.removeAll;
	CmdPeriod.removeAll;
};

ServerQuit.add(~cleanup);
~cleanup.();

///~~~ Load path to samples here ~~~///
~path = PathName(thisProcess.nowExecutingPath).parentPath;

///~~~ BUSSES ~~~///
s.newBusAllocators;
~reverb_bus = Bus.audio(s, 2);
~delay_bus = Bus.audio(s, 2);

///~~~ MIDI ~~~///
// MIDIIn.connectAll();
// MIDIIn.disconnectAll();

/*MIDIIn.noteOn({
// function for your midi notes
// like playing a synth
}).permanent_(true);*/ /// <= this makes it cmd + . agnostic
/*ServerOptions.outDevices;
Server.default.options.outDevice_("AudioBox USB 96");
Server.default.options.inDevice_("AudioBox USB 96");*/

// Server.default.options.outDevice_("BlackHole 16ch");
// Server.default.options.inDevice_("BlackHole 16ch");

Buffer.freeAll;
s.waitForBoot({
	///~~~ LOAD SAMPLES IN BUFFERS ~~~///
	///~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~///
	var subfolders;
	b = ();
	~path.postln;
	subfolders = PathName(~path ++ "audio/").entries;
	subfolders.do({
		arg dir;
		var buf_array;
		buf_array = dir.entries.collect({
			arg file;
			Buffer.readChannel(s, file.fullPath, channels: [0, 1]);
		});
		b[dir.folderName.asSymbol] = buf_array;
	});

	// replace this with folder name
	~gltch = b[\gltch];

	///~~~ LOAD SYNTH DEFS ~~~///
	///~~~~~~~~~~~~~~~~~~~~~~~///

	SynthDef.new(\simpler, {
		arg t_trig=1,buf=0,amp=0.5, lpf=17000, fold_amt=0.15,clip_amt=0.15, out=0,
		rel=0,atk=0, sus=1,loops=1,rate=1,pitch=1,bars=4,beat=1,do_stretch=1,grain=5;
		var sig, env, pos_env, micro_pos_env, pos, clip, fold, frames, start, end, start_pos, end_pos, duration,
		sustain, pos_rate, micro_pos, micro_dur,tot_duration, sample_duration, stretch=1, llist, index = 0, phase, r_amp, r_time;

		sample_duration = BufDur.kr(buf);
		duration = BufFrames.ir(buf);

		sustain = (sample_duration * sus / BufSampleRate.ir(buf));

		// we do not need envelope!

		env = EnvGen.ar(
			Env.new([0,1,1,0],[atk, sample_duration * sus, rel],\lin),
			gate: t_trig,
			doneAction: 0,
		);
		// BufRd.ar(1, b, Phasor.ar(0, BufRateScale.kr(b) * rate, 0, BufFrames.kr(b)))
		pos = Phasor.ar(t_trig, BufRateScale.ir(buf) * rate, 0, duration, 0);

		sig = BufRd.ar(numChannels: 2,
			bufnum: buf,
			phase: pos,
			loop: 1,
			interpolation: 4);
		sig = RLPF.ar(sig, lpf.clip(25, 19500), 0.5);
		fold_amt = 1-fold_amt;
		fold_amt = fold_amt.clip(0.001, 1);
		clip_amt = 1-clip_amt;
		clip_amt = clip_amt.clip(0.001, 1);
		fold = Fold.ar(sig, 0-fold_amt, fold_amt) * 1/fold_amt;
		clip = Clip.ar(sig, 0-clip_amt, clip_amt) * 1/clip_amt;
		sig = Mix.ar([sig, fold, clip]);
		// sig = Compander.ar(sig, sig, 0.1, 1, 1/8, 0.002, 0.01);
		sig = sig * amp;
		Out.ar(out, sig);
	}).add;


	///~~~ LOAD FX SYNTH DEFS ~~~///
	///~~~~~~~~~~~~~~~~~~~~~~~~~~///
	SynthDef.new(\reverb,
		{
			arg in=0, mix=0.4, out=0, mod_speed=0.05;
			var sig, wet, verb_mod, mod_carrier;
			sig = In.ar(in, 2); // reads from the audio bus
			mod_carrier = SinOsc.kr(mod_speed).range(0.005, 1);
			verb_mod = SinOsc.kr(mod_carrier).range(0.2, 0.999);
			sig = FreeVerb2.ar(
				sig[0], sig[1],
				mix: mix.clip(0.0, 1.0), room: verb_mod, damp: 0.85
			);
			Out.ar(out, sig)
	}).add;

	SynthDef.new(\delay, {
		arg in=0, mix=1.0, out=0, delay_time=0.5, fb=10, mod_speed=0.5;
		var dry, wet, sig, dry_mix, dly_mod;
		dry = In.ar(in, 2);
		dly_mod = LFDNoise0.ar(mod_speed).range(0.002, delay_time);
		wet = AllpassN.ar(dry, 10.0, dly_mod, fb);
		sig = XFade2.ar(dry, wet, mix.clip(-1.0, 1.0));
		Out.ar(out, sig);
	}).add;


	SynthDef.new(\compressor,
		{
			arg in=0, out=0;
			var compressed;
			in = In.ar(in,2);
			compressed = Compander.ar(in, in, 0.1, 1, 1/8, 0.002, 0.01);
			Out.ar(out, compressed);
	}).add;

	///~~~ VERY IMPORTANT ~~~///
	s.sync;

	~makeNodes ={
		~synths = Group.new;
		~fxs = Group.after(~synths);
		~comp = Synth.new(\compressor, [\in, 0], target: ~fxs);
		~verb = Synth.new(\reverb, [\in, ~reverb_bus], target: ~fxs);
		~delay = Synth.new(\delay, [\in, ~delay_bus, \out, ~reverb_bus], target: ~fxs);

		Pdef.removeAll;
	};
	ServerTree.add(~makeNodes);
	ServerTree.run;

	(
		~rand_wave = {
			arg min=100, max=19500, time=50;
			var num_seg = rrand(6, 35);
			Env(
				[min]++
				(({rrand(min, max)}!(num_seg-1))).scramble
				++[min],
				{exprand(1, time)}!num_seg,
				\sine
				// {rrand(-20, 20)}!num_seg
			).asPseg
		}
	)

});

)



SerialPort.closeAll;
SerialPort.devices;
(
~port = SerialPort.new("/dev/tty.usbmodem12101", baudrate: 9600);
)

~port.close;


(
~char_array = [];
~get_value = Routine.new({
	var ascii;
	{
		ascii = ~port.read.asAscii;
		if(ascii.isDecDigit, {~char_array = ~char_array.add(ascii)});
		if(ascii == $a, {
			~val = ~char_array.collect(_.digit).convertDigits;
			~char_array = [];
		});
	}.loop
}).play;
)

~val;

~sampler.free;
s.freeAll;
(

~sampler = Synth.new(\simpler,
	[
		\group, ~synths,
		\buf, ~gltch[2],
		\rate, 1,
		\amp, -25.dbamp,
		\out, 0,

	]
);
)
~sampler.set(\amp, -40.dbamp);

(
~control = Routine.new({
	{
		~sampler.set(\lpf, ~val.linexp(0, 1023, 50, 2000));

		0.01.wait;
	}.loop;
}).play
)

~control.stop;







