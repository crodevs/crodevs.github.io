# gRPC tricks

I've been working on a project at my job that involves running a grpc server on ARMv7 (Cortex-A5) hardware. The catch is that the project that my project is based on is written in .NET Framework 4.6.1 (out of support, I know, tell me about it), so my only option is to employ the [Mono Runtime](https://www.mono-project.com/docs/advanced/runtime/) over the custom-built Linux OS running on the device. This has the added benefit of not having to worry about building gRPC from source to target ARMv7 which can be a royal PITA. The Mono Runtime version I had built for this device also happened to support .NET Framework version that the project targets (double win).

This takes us to about a week ago, when I initially set up the project. Luckily, the NuGet package system Just Works™ and was able to fetch all the gRPC goodies I needed. I ran a couple tests on my local dev environment, the success of which made me confident (see: foolish) enough to copy the files over to the device and invoke the `mono` command on the unsuspecting .exe file. 

Shockingly, I immediately hit a snag (*gasp*).

{% include image.html url="/assets/img/shocked-surprised.gif" description="My literal reaction" %}

Staring back at me from the terminal was something that went like this:
```shell
Error: Unable to locate shared library libgrpc_csharp_x86.so
```

...what???

