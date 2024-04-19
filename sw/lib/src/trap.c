#include "trap.h"

#include "gpio.h"


void __attribute__((interrupt))
__DEFAULT_EX_HANDLER() {
    // Display exception cause on LEDs
    uint32_t mcause = csrr(CSR_MCAUSE);
    GPIO_LED->MODE = 0x0000FFFFu;
    GPIO_LED->ODATA = mcause;
    // Dead loop
    while (1);
}
