// blink the led of the board and print a heartbeat
//
// the led pin comes from `boards/<board>/board.h`, it's selected by the board option,
// e.g. xmake f --board=esp32c3
//
// @note the entry is the esp-idf native `void app_main(void)`, and we print with
// `esp_rom_printf`, it writes to the rom console, which is the usb port on the
// boards booting over the native usb (usb-serial-jtag), e.g. xmake monitor
//
#include "board.h"
#include "driver/gpio.h"
#include "esp_rom_sys.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

void app_main(void)
{
    esp_rom_printf("blink: toggle gpio %d every 500ms\n", LED_GPIO);
    gpio_reset_pin(LED_GPIO);
    gpio_set_direction(LED_GPIO, GPIO_MODE_OUTPUT);
    for (int count = 0; ; count++) {
        gpio_set_level(LED_GPIO, count & 1);
        esp_rom_printf("blink: tick %d\n", count);
        vTaskDelay(pdMS_TO_TICKS(500));
    }
}
