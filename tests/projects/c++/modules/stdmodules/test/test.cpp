// Copyright 2022 Ângelo Andrade Cirino

#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include <doctest/doctest.h>

import std;

import my_module;

TEST_CASE("Test sum") { CHECK(my_sum(1, 1) == 2); }
