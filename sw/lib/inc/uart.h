#ifndef __UART_H
#define __UART_H

#include <stdint.h>
#include <stdbool.h>


#ifdef __cplusplus
extern "C" {
#endif

typedef volatile struct __attribute__((packed,aligned(4))) {
    uint32_t DATA;
    uint32_t CONF;
} UART_t;

#define UART0_BASE      ((uint32_t)0xFFFFFF80u)
#define UART0           ((UART_t*) UART0_BASE)

#define UART_CONF_RX_BUSY       0x00000001u
#define UART_CONF_TX_BUSY       0x00000002u
#define UART_CONF_RX_FULL       0x00000004u
#define UART_CONF_RX_EMPTY      0x00000008u
#define UART_CONF_TX_FULL       0x00000010u
#define UART_CONF_TX_EMPTY      0x00000020u
#define UART_CONF_INT           0x000007C0u
#define UART_CONF_RX_INT        0x000001C0u
#define UART_CONF_RX_INT_DONE   0x00000040u
#define UART_CONF_RX_INT_FULL   0x00000080u
#define UART_CONF_RX_INT_ERR    0x00000100u
#define UART_CONF_TX_INT        0x00000600u
#define UART_CONF_TX_INT_DONE   0x00000200u
#define UART_CONF_TX_INT_EMPTY  0x00000400u
#define UART_CONF_RST           0x40000000u
#define UART_CONF_RX_ERR        0x80000000u


// Interrupt enable/disable
static inline void uart_enable_interrupts(UART_t* UART, uint32_t mask) {
    UART->CONF |= mask & UART_CONF_INT;
}
static inline void uart_disable_interrupts(UART_t* UART, uint32_t mask) {
    UART->CONF &= ~(mask & UART_CONF_INT);
}
static inline void uart_disable_interrupts_all(UART_t* UART) {
    UART->CONF &= ~UART_CONF_INT;
}

// Status flags
static inline bool uart_get_rx_busy(UART_t* UART)     { return UART->CONF & UART_CONF_RX_BUSY; }
static inline bool uart_get_tx_busy(UART_t* UART)     { return UART->CONF & UART_CONF_TX_BUSY; }
static inline bool uart_get_rx_full(UART_t* UART)     { return UART->CONF & UART_CONF_RX_FULL; }
static inline bool uart_get_rx_empty(UART_t* UART)    { return UART->CONF & UART_CONF_RX_EMPTY;}
static inline bool uart_get_tx_full(UART_t* UART)     { return UART->CONF & UART_CONF_TX_FULL; }
static inline bool uart_get_tx_empty(UART_t* UART)    { return UART->CONF & UART_CONF_TX_EMPTY; }

// Serial communication
uint8_t uart_rx(UART_t* UART);
void uart_tx(UART_t* UART, uint8_t data);

void print(const char* str);
void print_int32(int32_t num, int32_t base);
void println(const char* str);


#ifdef __cplusplus
} // extern "C"
#endif

#endif // __UART_H
