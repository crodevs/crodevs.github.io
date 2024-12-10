---
title: "CMake Dependency Build Trick"
date: 2024-12-09 15:24:27 -0600
categories: []
tags: [cmake]
---

{% include image.html url="/assets/img/cmake-patrick.jpg" description="" %}

I recently found myself in a CMake predicament...

## Foo and Bar
I have project Foo. Foo depends on project Bar. Bar is CMake packaged as `barConfig.cmake` consumed via `find_package(bar CONFIG REQUIRED)` like so:
```shell
find_package(bar CONFIG REQUIRED)
# ...
target_link_libraries(foo PRIVATE namespace::bar)
```
which works as long as `barConfig.cmake` is in the `CMAKE_PREFIX_PATH`

Now say I actually own both project Foo and Bar and simply want to build Bar as a submodule with `add_subdirectory(/submodule/path/b)`. 

This does not work because:
1. `find_package()` looks for `barConfig.cmake` at *configure time*, not *build time*. Therefore, unless you manually go and build Bar first, the config file does not exist yet
2. When you perform `add_subdirectory()` on Bar, it is treated as first-party by CMake, which wants to export it under Foo, but can't because the `namespace::bar` symbol is set to be imported by Foo (via `barTargets.cmake`). See more info in this [stackoverflow question](https://stackoverflow.com/questions/67227735/cmake-target-not-in-export-set)

## FetchContent
Luckily, there is a solution. CMake provides a popular library called ~~ExternalProject~~FetchContent that can configure a dependency to be built at *build time* but allows project target usage at *configure time*. 

>NOTE: I originally had this issue all upside down and didn't quite realize what ExternalProject did or why it was useful. As it turns out, it is similar to FetchContent, but one difference is that it does not expose dependency targets, forcing you to either hardcode output paths or create some CMakeLists.txt generation trickery if you want the behavior I've described.

FetchContent exposes a function called `FetchContent_Declare()` which has an internal call to `add_subdirectory()`. This can have the undesireable effect of adding ALL dependency targets e.g. tests or documentation. We can avoid this and perform our dependency target search in one fell swoop using the following CMake snippet:

```shell
project(foo)

include(FetchContent)
FetchContent_Declare(bar
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/local/path/to/bar
    OVERRIDE_FIND_PACKAGE # CMake >= 3.29
)
find_package(bar REQUIRED CONFIG)
# ...
add_library(foo ${src})
add_dependencies(foo namespace::bar)
target_link_libraries(foo
    PRIVATE # or PUBLIC
        namespace::bar
)
```

1. First we include FetchContent lib
2. Then we run `FetchContent_Declare()`, specifying the local source dir and adding the magic sauce: `OVERRIDE_FIND_PACKAGE`. In a nutshell, this option tells `FetchContent_Declare()` to override `find_package()` with `FetchContent_MakeAvailable()`, indicating that we intend to build the project from sources and are not simply consuming a pre-built package. For more info on this topic, check out the [CMake documentation](https://cmake.org/cmake/help/latest/module/FetchContent.html#integrating-with-find-package)
3. From here on out, we can safely use the `namespace::bar` target of the dependency, **given that the project has explicitly exported the target as namespace::target**. More on that [here](https://discourse.cmake.org/t/best-practice-s-for-isolating-dependencies-pulled-with-fetchcontent/5773)
