#ifndef __UART_H
#define __UART_H

#include <stdint.h>


#ifdef __cplusplus
extern "C" {
#endif

typedef volatile struct __attribute__((packed,aligned(4))) {
    uint32_t DATA;
    uint32_t CONF;
} UART_t;

#define UART0_BASE      ((uint32_t)0xFFFFFF80U)
#define UART0           ((UART_t*) UART0_BASE)

#define UART_CONF_RX_BUSY       0x00000001
#define UART_CONF_TX_BUSY       0x00000002
#define UART_CONF_RX_EMPTY      0x00000004
#define UART_CONF_RX_FULL       0x00000008
#define UART_CONF_TX_EMPTY      0x00000010
#define UART_CONF_TX_FULL       0x00000020
#define UART_CONF_RX_INT        0x000001C0
#define UART_CONF_RX_INT_DONE   0x00000040
#define UART_CONF_RX_INT_FULL   0x00000080
#define UART_CONF_RX_INT_ERR    0x00000100
#define UART_CONF_TX_INT        0x00000600
#define UART_CONF_TX_INT_DONE   0x00000200
#define UART_CONF_TX_INT_EMPTY  0x00000400
#define UART_CONF_DBG           0x20000000
#define UART_CONF_RST           0x40000000
#define UART_CONF_RX_ERR        0x80000000

void uart_tx(UART_t* UART, uint8_t data);
uint8_t uart_rx(UART_t* UART);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // __UART_H
