declare name        "MidiClockClick";
declare version     "1.0";
declare author      "Vincent Rateau";
declare license     "GPL v3";
declare description	"Metronom driven by MidiClock";


import("stdfaust.lib");


process = synth2 * clicklfo(emphasis), synth1 * clicklfo(1) : clickchoice : onoff : vol : pan;


// CLICK GENERATOR
////////////////////////////////////
clicklfo(s) = sequence(s) : an.amp_follower_ud(0.001, 0.01) ; // : hbargraph("", 0, 1) ;

//mute beat click if emphased beate is playing
clickchoice = (_<: _,_) ,_ : select2( ( sidechaincond ) , _ , _ )
	with{
		sidechaincond = _ : an.amp_follower_ud(0.000, 0.1) < 0.1 ;
	};

emphasis = nentry("emphasis", 4, 0, 12, 1);


//SYNTHS
////////////////////////////////////
synth1 = synthchoice <: (_==0) * os.square(440), (_==1) * os.triangle(440), (_==2) *  os.saw1(440), (_==3) *  os.osc(440) :> _;
synth2 = synthchoice <: (_==0) * os.square(880), (_==1) * os.triangle(880), (_==2) *  os.saw1(880), (_==3) *  os.osc(880) :> _;

synthchoice = vslider("[1]synth[style:menu{'square':0 ; 'triangle':1 ; 'saw':2 ; 'sin':3 }]", 0,0,3,1) ;


//MIXER
////////////////////////////////////
onoff = _ * (checkbox("On/Off"): si.smooth(0.999)) ;
vol = _ * (hslider("[3]level", 1, 0, 1, 0.01): si.smooth(0.999));

pan(a) = (a * (1-panui)), (a * panui) ;
panui = hslider("[2]pan", 0.5, 0, 1, 0.01);


// MIDI CLOCK
////////////////////////////////////////////

sequence(s) = vgroup("Midi Clock Signal", clocker : midiclock(s) : beatpulse)
with{
	// clocker is a square signal (1/0), changing state at each received midi clock
	clocker   = checkbox("[1]MIDI clock[midi:clock]");


	// count 24 pulse and reset
	midiclock(s) =  sq2pulse : counter(24*s) // : vbargraph("counter loop 24", 0, 30);
	with{
		// detect front, (create pulse from square wave)
		sq2pulse(x)  = (x-x') != 0.0 ;
	};


	//  pulse once a beat
	beatpulse = _ == 0  <:  _-_' : _ >0 ;
	//clock2beat =  beatpulse :  counter(4)  : _ +1 ; //: hbargraph("counter loop 4", 1, 4);


	// count and multiply by 1 as long as counter < n (last number in loop), otherwise multiply by 0 = reset seq to zero
	counter(n)   =  +   ~ cond(n)
	with{
		// condition inside the loop. play resets sequence to 0
		cond(n) = _ <: _, _ : ( _ < n) * _  :> _ * play ;

		// Start / Stop button controlled with MIDI start/stop messages inside the loop (if stop then reset to 0)
		play      = checkbox("[2]Sequence Start / Stop [midi:start] [midi:stop]");
	};
};
