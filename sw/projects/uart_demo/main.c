#include "lexington.h"


int main() {

    for (uint32_t i=0; i<16; i++) {
        gpio_mode(GPIO_LED, i, OUTPUT);
        gpio_write(GPIO_LED, i, LOW);
    }
    gpio_write(GPIO_LED, 15, HIGH);
    bool led15 = true;

    bool inserted_newline = false;

    char str[] = "GPro 1 Lexington - UART demo:\r\n";
    char* ptr = str;
    while (*ptr) {
        uart_tx(UART0, *ptr);
        ptr++;
    }

    while (1) {

        uint8_t data = uart_rx(UART0);

        if ('\r' == data) {
            inserted_newline = true;
            uart_tx(UART0, data);
            uart_tx(UART0, '\n');
        }
        else {
            if ('\n' != data || !inserted_newline) {
                uart_tx(UART0, data);
            }
            inserted_newline = false;
        }

        if (led15) {
            gpio_write(GPIO_LED, 14, HIGH);
            gpio_write(GPIO_LED, 15, LOW);
        } else {
            gpio_write(GPIO_LED, 14, LOW);
            gpio_write(GPIO_LED, 15, HIGH);
        }

    }

    return 0;
}
