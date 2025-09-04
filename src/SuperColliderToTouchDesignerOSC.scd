/**********************************************************
ProxySpace
**********************************************************/

(
p = ProxySpace(s, clock: TempoClock(1, queueSize: 1024))
    .quant_(4)
    .fadeTime_(8)
    .push;
)

/**********************************************************
Analysis SynthDef
**********************************************************/

(
SynthDef(\vizTapSend, { |inBus=0, replyID=0, fftSize=1024, atk=0.01, rel=0.1, thresh=0.5, fps=30|
    var sig   = In.ar(inBus, 2);
    var mono  = Mix(sig) * 0.5;
    var amp   = Amplitude.kr(mono, atk, rel).clip(0, 1);
    var chain = FFT(LocalBuf(fftSize), mono);
    var cent  = (SpecCentroid.kr(chain) / (0.5 * SampleRate.ir)).clip(0, 1);
    var onset = Decay.kr(Onsets.kr(chain, thresh, \rcomplex), 0.08);

    SendReply.kr(Impulse.kr(fps), '/viz', [amp, cent, onset], replyID);
    0.0
}).add;
)

/**********************************************************
Router
**********************************************************/

(
//NetAddrは普通の変数に置く（ProxySpaceに巻き込まれない）
var td      = NetAddr("127.0.0.1", 8000);
var addrMap = IdentityDictionary[
    0 -> "/viz/s0",
    1 -> "/viz/p1",
    2 -> "/viz/k0"
];

OSCdef(\vizRecv).free;
OSCdef(\vizRecv, { |msg| // ['/viz', nodeID, replyID, amp, cent, onset]
    var id   = msg[2].asInteger;
    var amp  = msg[3], cent = msg[4], onset = msg[5];
    var path = addrMap[id];
    if(path.notNil) {
        td.sendMsg(path, amp, cent, onset);
    };
}, '/viz');
)

/**********************************************************
Controller
**********************************************************/

( // ProxySpaceのNodeProxy化を避けて、Eventを直接置く
p.envir.removeAt(\viz);
p.envir[\viz] = ();

~viz[\fps]    = 30;
~viz[\fft]    = 1024;
~viz[\thresh] = 0.5;
~viz[\nodes]  = IdentityDictionary.new;

~viz[\attach] = { |proxy, key, replyID|
	~viz[\nodes][key].isNil.if {
        var busIndex  = proxy.bus.index;
        var targetGrp = proxy.group ? s.defaultGroup;
        ~viz[\nodes][key] = Synth.tail(targetGrp, \vizTapSend, [
            \inBus,   busIndex,
            \replyID, replyID,
            \fftSize, ~viz[\fft],
            \atk,     0.01,
            \rel,     0.1,
            \thresh,  ~viz[\thresh],
            \fps,     ~viz[\fps]
        ]);
        ("viz attach " ++ key).postln;
    };
};

~viz[\detach] = { |key|
    ~viz[\nodes][key] !? { |syn|
        syn.free; ~viz[\nodes].removeAt(key);
        ("viz detach " ++ key).postln;
    };
};

~viz[\start] = { |pairs|
    pairs.do { |t| ~viz[\attach].(t[0], t[1], t[2].asInteger) };
    "viz start".postln;
};

~viz[\stop] = {
    ~viz[\nodes].keysValuesDo { |k, syn| syn.free };
    ~viz[\nodes].clear;
    "viz stop".postln;
};

CmdPeriod.add({
    try { OSCdef(\vizRecv).free } { };
    try { ~viz[\stop].() } { };
});
)

// ~viz[\start].([ [~any, \any, any] ]);