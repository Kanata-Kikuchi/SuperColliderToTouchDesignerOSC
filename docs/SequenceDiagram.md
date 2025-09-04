SuperCollider から TouchDesigner への OSC 通信

このシステムでは、SuperCollider を用いて Live Coding に適した OSC 通信 を実現しています。
音源の生成には NodeProxy を利用し、逐次的に Synth を生成することで柔軟なライブ操作を可能にしています。

また、IDE 側（sclang）の負担を軽減するため、音声解析はサーバー側（scsynth）で実行し、その結果を OSC メッセージとして送信します。
解析データは プッシュ型（イベント駆動） で送られ、SendReply によって sclang 側に届き、さらに ルーター（OSCdef）を介して TouchDesigner など外部ソフトウェアへ転送されます。

Client: sclang( OSCdef, Controller, Analysis, ProxySpace, NodeProxy ), 
Server: scsynth( SynthDefs, NodeTree, Bus ), 
TouchDesigner, DAC

```mermaid
sequenceDiagram
    autonumber
    box Client : sclang
    participant r as OSCdef
    participant c as Controller
    participant a as Analysis
    participant p as ProxySpace
    participant np as NodeProxy
    end
    
    par Sound Source
    p ->> np : Create a NodeProxy
    %%np -->> s : Register it internally as a SynthDef
    end
    
    par Analysis Source
    a ->>+ s : Register a SynthDef for analysis
    end
    
    box Server : scsynth
    participant s as SynthDefs
    participant n as NodeTree
    participant b as Bus
    end
    
    opt OSC is received
    n -->+ r : SendReply : ['/viz', nodeID, replyID, amp, cent, onset]
    create participant t as TouchDesigner
    r ->>- t : NetAddr.sendMsg
    end
    
    par Audio Start
    np ->>+ n : Build & Send synth graph
    s -->> n : Create a SynthNode
    create participant d as DAC
    n -->>- d : Out.ar
    end
    
    alt
    Note over np : \attach 
    c ->>+ n : Create an analysis synth
    s -->> n : Create a SynthNode
    b -->> n : In.ar 
    n -->> n: Amplitude / FFT / Onsets / SpecCentroid
    n -->>- r : SendReply '/viz' with [amp, cent, onset]
    else
    Note over np : \detach
    c ->> n : Free one analysis synth
    c --> c : Remove [\nodes]
    else
    Note over np : \start
    c ->> c : Call [\attach]
    else
    Note over np : \stop
    c ->> n : Free all analysis synths
    c --> c : Clear [\nodes]
    end