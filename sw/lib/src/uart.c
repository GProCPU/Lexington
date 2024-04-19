#include "uart.h"
#include "stdbool.h"



void uart_tx(UART_t* UART, uint8_t data) {
    while (UART->CONF & UART_CONF_TX_FULL);
    UART->DATA = (uint32_t) data;
}

uint8_t uart_rx(UART_t* UART) {
    while (UART->CONF & UART_CONF_RX_EMPTY);
    return (uint8_t) UART->DATA;
}


void print(const char* str) {
    while (*str) {
        while (UART0->CONF & UART_CONF_TX_FULL);
        UART0->DATA = (uint32_t) *str;
        str++;
    }
}

void print_int32(int32_t num, int32_t base) {
    char str[20];
    char* end = str + 19;
    char* ptr = end;
    bool neg = false;
    
    // Check sign
    if (num < 0) {
        num = 0 - num;
        neg = true;
    }

    // Get digits
    do {
        *ptr = (char) (num % base) + '0';
        num /= base;
        ptr--;
    } while (num);

    // Put sign
    if (neg) {
        *ptr = '-';
    } else {
        ptr++;
    }
    print(ptr);
}

void println(const char* str) {
    while (*str) {
        while (UART0->CONF & UART_CONF_TX_FULL);
        UART0->DATA = (uint32_t) *str;
        str++;
    }
    while (UART0->CONF & UART_CONF_TX_FULL);
    UART0->DATA = (uint32_t) "\r";
    while (UART0->CONF & UART_CONF_TX_FULL);
    UART0->DATA = (uint32_t) "\n";
}
