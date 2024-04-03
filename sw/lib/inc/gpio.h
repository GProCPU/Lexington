#ifndef __GPIO_H
#define __GPIO_H

#include <stdint.h>


#define HIGH            1
#define LOW             0

#define INPUT           0
#define OUTPUT          1

#define GPIOA_BASE      ((uint32_t) 0xFFFFFFA0U)
#define GPIOB_BASE      ((uint32_t) 0xFFFFFFB0U)
#define GPIOC_BASE      ((uint32_t) 0xFFFFFFC0U)

typedef volatile struct __attribute__((packed,aligned(4))) {
    uint32_t MODE;
    uint32_t IDATA;
    uint32_t ODATA;
    uint32_t INT_CONF;
} gpio_t;

#define GPIOA           ((gpio_t*) GPIOA_BASE)
#define GPIOB           ((gpio_t*) GPIOB_BASE)
#define GPIOC           ((gpio_t*) GPIOC_BASE)


void gpio_mode(gpio_t* bank, uint32_t pin, uint32_t mode);
uint32_t gpio_read(gpio_t* bank, uint32_t pin);
void gpio_write(gpio_t* bank, uint32_t pin, uint32_t state);


#endif //__GPIO_H
