declare name        "MidiClockClick";
declare version     "1.0";
declare author      "Vincent Rateau";
declare license     "GPL v3";
declare reference   "www.sonejo.net";
declare description	"Metronom driven by MidiClock";

import("music.lib");
import("oscillator.lib");
import("effect.lib");


process = synth2 * clicklfo(emphasis), synth1 * clicklfo(1) : clickchoice : onoff : vol : pan;


// CLICK GENERATOR
////////////////////////////////////
clicklfo(s) = sequence(s) : amp_follower_ud(0.001, 0.01) ; // : hbargraph("", 0, 1) ;

//mute beat click if emphased beate is playing
clickchoice = (_<: _,_) ,_ : select2( ( sidechaincond ) , _ , _ ) 
	with{
		sidechaincond = _ : amp_follower_ud(0.000, 0.1) < 0.1 ;
	};

emphasis = nentry("emphasis", 4, 0, 12, 1);


//SYNTHS
////////////////////////////////////
synth1 = synthchoice <: (_==0) * square(440), (_==1) * triangle(440), (_==2) *  saw1(440), (_==3) *  osc(440) :> _;
synth2 = synthchoice <: (_==0) * square(880), (_==1) * triangle(880), (_==2) *  saw1(880), (_==3) *  osc(880) :> _;

synthchoice = vslider("Synth[style:menu{'square':0 ; 'triangle':1 ; 'saw':2 ; 'sin':3 }]", 0,0,3,1) ;


//MIXER
////////////////////////////////////
onoff = _ * (checkbox("On/Off"): smooth(0.999)) ;
vol = _ * (hslider("level", 1, 0, 1, 0.01): smooth(0.999));

pan(a) = (a * (1-panui)), (a * panui) ;
panui = hslider("pan", 0.5, 0, 1, 0.01);



//GLOBAL FUNCTIONS
////////////////////////////////////

//Sample and Hold function
SH(trig,x) = (*(1 - trig) + x * trig) ~_;


	
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