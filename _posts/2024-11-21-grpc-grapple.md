---
layout: post
title: "gRPC Grapple"
date: 2024-11-21 21:56:34 -0600
categories: []
tags: [grpc,arm,linux]
---

## The Backstory

I've been working on a project at my job that involves running a grpc server on [ARMv7 (Cortex-A5) hardware](https://shop.emacinc.com/product/som-a5d35-system-on-module/). The catch is that the project that my project is based on is written in .NET Framework 4.6.1 (out of support, I know, tell me about it), so my only option is to employ the [Mono Runtime](https://www.mono-project.com/docs/advanced/runtime/) over the custom-built Linux OS running on the device. This has the added benefit of not having to worry about building gRPC from source to target ARMv7 which can be a royal PITA. The Mono Runtime version I had built for this device also happened to support .NET Framework version that the project targets (double win).

This takes us to about a week ago, when I initially set up the project. Luckily, the NuGet package system Just Works™ and was able to fetch all the gRPC goodies I needed. I ran a couple tests on my local dev environment, the success of which made me confident (see: foolish) enough to copy the files over to the device and invoke the `mono` command on the unsuspecting .exe file. 

Shockingly, I immediately hit a snag (*gasp*).

{% include image.html url="/assets/img/shocked-surprised.gif" description="My literal reaction" %}

## The Problem

Staring back at me from the terminal was something that went like this:
```shell
Error: Unable to locate shared library libgrpc_csharp_ext.x86.so
```

...what???

This is a .NET Framework project running on Mono. Last I checked, we use .DLLs and .EXEs, not .SOs. When DuckDuckGo fails to shed light on the error, I examined the references list in the project. `Grpc.Core` and `Grpc.Core.Api` were the only two NuGet packages I was using for gRPC purposes. I navigated to the `packages` dir in my solution directory and examined those two packages. Hidden multiple layers deep were other similar shared libraries, but in .DLL form, namely libgrpc_csharp_**x64**.dll. Sure enough, those were the same files that were deployed on the ARM machine.

The [gRPC C# repo](https://github.com/grpc/grpc/tree/v1.46.x/src/csharp) had this to say about the whole thing:

> Internally, gRPC C# uses a native library written in C (gRPC C core) and invokes its functionality via P/Invoke. The fact that a native library is used should be fully transparent to the users and just installing the Grpc.Core NuGet package is the only step needed to use gRPC C# on all supported platforms.

which doesn't apply to me since I'm running ARMv7 architecture and not x86. This would have been **great** to know when I first started this. *Sigh*

## The Solution

Begrugdingly, I built the grpc_csharp_ext project from source, targeting ARMv7. Luckily for me, [someone else](https://github.com/erikest/libgrpc_csharp_ext) already did this for a Raspberry Pi, so I was able to appropriate their CMake script and apply my Cortex-A5 toolchain. I had to rename the resulting shared lib to `libgrpc_csharp_ext.x86.so`, which was what `Grpc.Core` was expecting, and deploy it alongside the .DLLs. 

> **_NOTE:_** Another weird caveat about this is that, on Windows, Grpc.Core will specify which bitness it's building for: x86 or x64. This isn't specified on Linux, but since the ARM chip I was using is 32-bit, Grpc.Core was looking for a .x86.so anyway. Hence the reason I had to rename the lib by adding .x86.