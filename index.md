---
layout: default
title: {{ site.name }}
---

## Simple description

    target("console")
        set_kind("binary")
        add_files("src/*.c") 

## Build project

    xmake

## Run target

    xmake run console

## Support features

* Tasks
* Macros
* Actions
* Options
* Plugins
* Templates

## Support platforms

* Windows (x86, x64, amd64, x86_amd64)
* Macosx (i386, x86_64)
* Linux (i386, x86_64, cross-toolchains ...)
* Android (armv5te, armv6, armv7-a, armv8-a, arm64-v8a)
* iPhoneOS (armv7, armv7s, arm64, i386, x86_64)
* WatchOS (armv7k, i386)
* Mingw (i386, x86_64)

## Support Languages

* C/C++
* Objc/Objc++
* Swift
* Assembly

## In the plans

* Manage package and dependence
* Download package automaticlly
* Create package repository for porting other third-party source codes, it's goal is that one people port it and many people shared.
* Implement more plugins
* Create more project files for IDE (.e.g vs, xcode ..)
