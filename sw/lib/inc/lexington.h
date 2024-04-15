#ifndef __LEXINGTON_H
#define __LEXINGTON_H

// Standard libraries
#include <stdint.h>
#include <stdbool.h>
#include <limits.h>
#include <unistd.h>
#include <stdlib.h>


// I/O and peripherals
#include "csr.h"
#include "trap.h"
#include "mtime.h"
#include "gpio.h"
#include "uart.h"
#include "vga.h"


#ifdef __cplusplus
extern "C" {
#endif


// Endianness
#define MSTATUSH_MBE        5
static inline uint32_t __attribute__((always_inline)) get_endianness()
    { return 0b1 & (csrr(CSR_MSTATUSH) >> MSTATUSH_MBE); }
static inline void __attribute__((always_inline)) set_big_endian() 
    { __asm__ volatile inline ("csrsi mstatush, 0x20"); }
static inline void __attribute__((always_inline)) set_little_endian() 
    { __asm__ volatile inline ("csrci mstatush, 0x20"); }

// Memory Fence
static inline void __attribute__((always_inline)) fence() 
    { __asm__ volatile inline ("fence"); }
static inline void __attribute__((always_inline)) fence_i() 
    { __asm__ volatile inline ("fence.i"); }

// System Instructions
static inline void __attribute__((always_inline)) ecall() 
    { __asm__ volatile inline ("ecall"); }
static inline void __attribute__((always_inline)) ebreak() 
    { __asm__ volatile inline ("ebreak"); }
static inline void __attribute__((always_inline)) wfi() 
    { __asm__ volatile inline ("wfi"); }


#ifdef __cplusplus
}
#endif

#endif //__LEXINGTON_H
