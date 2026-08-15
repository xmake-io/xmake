// the board configuration of esp32s3, it's selected by the `board` option
//
// @note it's the addressable rgb led (ws2812) on the devkit, a plain gpio toggle
// does not light it up, set it to a real led pin of your board
//
#pragma once

#define LED_GPIO 48
