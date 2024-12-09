---
title: "Cmake \"External\" Build Trick"
date: 2024-12-09 15:24:27 -0600
categories: []
tags: [cmake]
---

{% include image.html url="/assets/img/cmake-patrick.jpg" description="" %}

I recently found myself in this CMake predicament...

I have project Foo. Foo depends on project Bar. Bar is CMake packaged as `barConfig.cmake` consumed via `find_package(bar CONFIG REQUIRED)` like so:
```
find_package(bar CONFIG REQUIRED)
# ...
target_link_libraries(foo PRIVATE namespace::bar)
```
which works as long as `barConfig.cmake` is in the `CMAKE_PREFIX_PATH`

Now say I actually own both project Foo and Bar and simply want to build Bar as a submodule with `add_subdirectory(/submodule/path/b)`. 

This does not work because:
1. `find_package()` looks for `barConfig.cmake` at *configure time*, not *build time*. Therefore, unless you manually go and build Bar first, the config file does not exist yet
2. When you perform `add_subdirectory()` on Bar, it is treated as first-party by CMake, which wants to export it under Foo, but can't because the `namespace::bar` symbol is set to be imported by Foo (via `barTargets.cmake`). See more info in this [stackoverflow question](https://stackoverflow.com/questions/67227735/cmake-target-not-in-export-set)

Luckily, there is a solution. CMake provides a library called `ExternalProject` that can configure a dependency to be built at *build time* but allows package symbol usage at *configure time*. Normally, this would be used for its namesake, external dependencies, but here, it allows a local CMake project to be configured as a dependency. Here is an example:

```
project(foo)

include(ExternalProject)
ExternalProject_Add(bar
	SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/local/path/to/bar
    CMAKE_ARGS 
        -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} # you can install bar in any CMAKE_PREFIX_PATH path
)
find_package(bar REQUIRED CONFIG)
# ...
add_library(foo ${src})
add_dependencies(foo bar)
target_link_libraries(foo
    PRIVATE # or PUBLIC
        namespace::bar
)
```
