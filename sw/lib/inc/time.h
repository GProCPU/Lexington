#ifndef __TIME_H
#define __TIME_H

#include <stdint.h>

#include "csr.h"
#include "trap.h"


#define MTIME_BASE              ((uint32_t) 0xC0000000)

typedef volatile struct __attribute__((packed,aligned(4))) {
    uint32_t mtime;
    uint32_t mtimeh;
    uint32_t mtimecmp;
    uint32_t mtimecmph;
} mtime_t;

#define MACHINE_TIMER           ((mtime_t*) MTIME_BASE)

#define TIME_INIT_10MHz     (1000000 / 100)
#define TIME_INIT_15MHz     (1000000 / 66.6666)
#define TIME_INIT_20MHz     (1000000 / 50)
#define TIME_INIT_25MHz     (1000000 / 40)
#define TIME_INIT_30MHz     (1000000 / 33.3333)
#define TIME_INIT_35MHz     (1000000 / 28.5714)
#define TIME_INIT_40MHz     (1000000 / 25)
#define TIME_INIT_45MHz     (1000000 / 22.2222)
#define TIME_INIT_50MHz     (1000000 / 20)
#define TIME_INIT_60MHZ     (1000000 / 16.6666)
#define TIME_INIT_70MHz     (1000000 / 14.2857)
#define TIME_INIT_80MHz     (1000000 / 12.5)
#define TIME_INIT_90MHz     (1000000 / 11.1111)
#define TIME_INIT_100MHz    (1000000 / 10)


void __MTI_HANDLER(); // interrupt handler

void time_init(uint32_t ticks_per_milli);

static void set_mtime(uint64_t val);
static void set_mtimecmp(uint64_t val);
static uint64_t get_mtime();
static uint64_t get_mtimecmp();

static uint32_t milliseconds();
static uint32_t microseconds();

void delay(uint32_t val);
// void delay_micro(uint32_t val);

extern volatile uint32_t __millis;




static inline void __attribute__((always_inline)) set_mtime(uint64_t val) {
    union {
        uint64_t u64;
        uint32_t u32[2];
    } counter;
    counter.u64 = val;

    MACHINE_TIMER->mtime  = 0;
    MACHINE_TIMER->mtimeh = counter.u32[1];
    MACHINE_TIMER->mtime  = counter.u32[0];
}

static inline void __attribute__((always_inline)) set_mtimecmp(uint64_t val) {
    union {
        uint64_t u64;
        uint32_t u32[2];
    } counter;
    counter.u64 = val;

    MACHINE_TIMER->mtimecmph = counter.u32[1];
    MACHINE_TIMER->mtimecmp  = counter.u32[0];
}

static inline uint64_t __attribute__((always_inline)) get_mtime() {
    union {
        uint64_t u64;
        uint32_t u32[2];
    } counter;

    uint32_t tmp;
    do {
        counter.u32[1] = csrr(CSR_TIMEH);
        counter.u32[0] = csrr(CSR_TIME);
        tmp           = csrr(CSR_TIMEH);
    } while (counter.u32[1] != tmp);
    return counter.u64;
}

static inline uint64_t __attribute__((always_inline)) get_mtimecmp() {
    union {
        uint64_t u64;
        uint32_t u32[2];
    } counter;

    counter.u32[1] = MACHINE_TIMER->mtimecmph;
    counter.u32[0] = MACHINE_TIMER->mtimecmp;
    return counter.u64;
}


static inline __attribute((always_inline)) uint32_t milliseconds() {
    return __millis;
}

static inline uint32_t __attribute__((always_inline)) microseconds() {
    return csrr(CSR_TIME);
}


#endif // __TIME_H
