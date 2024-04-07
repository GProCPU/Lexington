#include "lexington.h"

// #define MAX_COUNT   1000000
#define BLINK_DELAY     500


int main() {

    time_init(TIME_INIT_10MHz);

    for (uint32_t i=0; i<16; i++) {
        gpio_mode(GPIOA, i, OUTPUT);
    }

    while (1) {
        for (uint32_t i=0; i<15; i++) {
            gpio_write(GPIOA, i, HIGH);
            delay(BLINK_DELAY);
            gpio_write(GPIOA, i, LOW);
        }
        for (uint32_t i=15; i>0; i--) {
            gpio_write(GPIOA, i, HIGH);
            delay(BLINK_DELAY);
            gpio_write(GPIOA, i, LOW);
        }
    }

    return 0;
}
