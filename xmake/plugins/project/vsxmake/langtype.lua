-- Copy from cl.lua
local _g = {}
_g.cxxmaps =
{
    cxx11       = "-std:c++11"
,   gnuxx11     = "-std:c++11"
,   cxx14       = "-std:c++14"
,   gnuxx14     = "-std:c++14"
,   cxx17       = "-std:c++17"
,   gnuxx17     = "-std:c++17"
,   cxx1z       = "-std:c++17"
,   gnuxx1z     = "-std:c++17"
,   cxx20       = {"-std:c++20", "-std:c++latest"}
,   gnuxx20     = {"-std:c++20", "-std:c++latest"}
,   cxx2a       = {"-std:c++20", "-std:c++latest"}
,   gnuxx2a     = {"-std:c++20", "-std:c++latest"}
,   cxx23       = {"-std:c++23", "-std:c++latest"}
,   gnuxx23     = {"-std:c++23", "-std:c++latest"}
,   cxx2b       = {"-std:c++23", "-std:c++latest"}
,   gnuxx2b     = {"-std:c++23", "-std:c++latest"}
,   cxxlatest   = "-std:c++latest"
,   gnuxxlatest = "-std:c++latest"
}

_g.cmaps =
{
    -- stdc
    c99       = "-TP" -- compile as c++ files because older msvc only support c89
,   gnu99     = "-TP"
,   c11       = {"-std:c11", "-TP"}
,   gnu11     = {"-std:c11", "-TP"}
,   c17       = {"-std:c17", "-TP"}
,   gnu17     = {"-std:c17", "-TP"}
,   clatest   = {"-std:c17", "-std:c11"}
,   gnulatest = {"-std:c17", "-std:c11"}
}

_g.csmaps =
{
    csharp = "-TP"
,   
}

function iscsharp(language)
    if language and _g.csmaps[language] then
        return true
    end

    return false
end

function isc(language)
    if language and _g.cmaps[language] then
        return true
    end

    return false
end

function iscpp(language)
    if language and _g.cxxmaps[language] then
        return true
    end

    return false
end