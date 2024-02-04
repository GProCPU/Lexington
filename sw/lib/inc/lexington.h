#ifndef __LEXINGTON_H
#define __LEXINGTON_H

#ifdef __cplusplus
extern "C" {
#endif


// Standard libraries
#include <stdint.h>
#include <limits.h>
#include <unistd.h>
#include <stdlib.h>


// I/O and peripherals
#include "csr.h"
#include "trap.h"
#include "time.h"
#include "gpio.h"
#include "uart.h"


// Endianness
#define MSTATUSH_MBE        5
inline uint32_t __attribute__((always_inline)) get_endianness()
    { return 0b1 & (csrr(CSR_MSTATUSH) >> MSTATUSH_MBE); }
inline void __attribute__((always_inline)) set_big_endian() 
    { __asm__ volatile inline ("csrsi mstatush, 0x20"); }
inline void __attribute__((always_inline)) set_little_endian() 
    { __asm__ volatile inline ("csrci mstatush, 0x20"); }

// Memory Fence
inline void __attribute__((always_inline)) fence() 
    { __asm__ volatile inline ("fence"); }
inline void __attribute__((always_inline)) fence_i() 
    { __asm__ volatile inline ("fence.i"); }

// System Instructions
inline void __attribute__((always_inline)) ecall() 
    { __asm__ volatile inline ("ecall"); }
inline void __attribute__((always_inline)) ebreak() 
    { __asm__ volatile inline ("ebreak"); }
inline void __attribute__((always_inline)) wfi() 
    { __asm__ volatile inline ("wfi"); }


#ifdef __cplusplus
}
#endif

#endif //__LEXINGTON_H
