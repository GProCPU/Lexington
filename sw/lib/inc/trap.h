#ifndef __TRAP_H
#define __TRAP_H

#include <stdint.h>

#include "csr.h"


// Standard Interrupt Causes
#define TRAP_CODE_NMI                   0
#define TRAP_CODE_SSI                   1
#define TRAP_CODE_MSI                   3
#define TRAP_CODE_STI                   5
#define TRAP_CODE_MTI                   7
#define TRAP_CODE_SEI                   9
#define TRAP_CODE_MEI                   11

// Platform Interrupt Causes
#define TRAP_CODE_UART0RX               16
#define TRAP_CODE_UART0TX               17
#define TRAP_CODE_TIM0                  18
#define TRAP_CODE_TIM1                  19
#define TRAP_CODE_GPIOA0                20
#define TRAP_CODE_GPIOA1                21
#define TRAP_CODE_GPIOB0                22
#define TRAP_CODE_GPIOB1                23
#define TRAP_CODE_GPIOC0                24
#define TRAP_CODE_GPIOC1                25

// Exception Trap Codes
#define TRAP_CODE_INST_MISALIGNED       0
#define TRAP_CODE_INST_ACCESS_FAULT     1
#define TRAP_CODE_ILLEGAL_INST          2
#define TRAP_CODE_BREAKPOINT            3
#define TRAP_CODE_LOAD_MISALIGNED       4
#define TRAP_CODE_LOAD_ACCESS_FAULT     5
#define TRAP_CODE_STORE_MISALIGNED      6
#define TRAP_CODE_STORE_ACCESS_FAULT    7
#define TRAP_CODE_ECALL_UMODE           8
#define TRAP_CODE_ECALL_SMODE           9
#define TRAP_CODE_ECALL_MMODE           10
#define TRAP_CODE_INST_PAGE_FAULT       11
#define TRAP_CODE_LOAD_PAGE_FAULT       12
#define TRAP_CODE_STORE_PAGE_FAULT      13

// mtvec Modes
#define MTVEC_MODE_DIRECT               0
#define MTVEC_MODE_VECTORED             1
#define MTVEC_MODE_MASK                 (0b11)
#define MTVEC_BASE_MASK                 ((uint32_t)0xFFFFFFFC)


// Global interrupt enable
static void enable_global_interrupts();
static void disable_global_interrupts();
static uint32_t get_global_interrupt_enable();

// Trap-Vector
static uint32_t get_mtvec_mode();
static uint32_t get_mtvec_base();
static void set_mtvec_direct();
static void set_mtvec_vectored();
static void set_mtvec_base_direct(uint32_t base);
static void set_mtvec_base_vectored(uint32_t base);

// Interrupt Enable
static void enable_interrupt(uint32_t source);
static void disable_interrupt(uint32_t source);

// Interrupt Pending
static uint32_t get_interrupt_pending(uint32_t source);
static void set_interrupt_pending(uint32_t source);
static void clear_interrupt_pending(uint32_t source);

// Trap Cause
static uint32_t is_mcause_interrupt();




// INLINE FUNCTIONS

// Global interrupt enable
inline void __attribute__((always_inline)) enable_global_interrupts() {
    __asm__ volatile inline ("csrs mstatus, 0x4");
};

inline void __attribute__((always_inline)) disable_global_interrupts() {
    __asm__ volatile inline ("csrc mstatus, 0x4");
};

inline uint32_t __attribute__((always_inline)) get_global_interrupt_enable() {
    return 0b1 & (csrr(CSR_MSTATUS) >> 3);
};



// Trap-Vector
inline uint32_t __attribute__((always_inline)) get_mtvec_mode() {
    return MTVEC_MODE_MASK & (csrr(CSR_MSTATUS) >> 3);
};

inline uint32_t __attribute__((always_inline)) get_mtvec_base() {
    return MTVEC_BASE_MASK & csrr(CSR_MTVEC);
};

inline void __attribute__((always_inline)) set_mtvec_direct() {
    __asm__ volatile inline("csrc mtvec, 0x3");
};

inline void __attribute__((always_inline)) set_mtvec_vectored() {
    __asm__ volatile inline(
        "csrc mtvec, 0x2\n"
        "csrs mtvec, 0x1"
    );
};

inline void __attribute__((always_inline)) set_mtvec_base_direct(uint32_t base) {
    uint32_t data = MTVEC_BASE_MASK & base;
    csrw(CSR_MTVEC, data);
};

inline void __attribute__((always_inline)) set_mtvec_base_vectored(uint32_t base) {
    uint32_t data = (base & MTVEC_BASE_MASK) | 0b01;
    csrw(CSR_MTVEC, data);
};



// Interrupt Enable
inline void __attribute__((always_inline)) enable_interrupt(uint32_t source) {
    uint32_t mask = 0b1 << source;
    csrs(CSR_MIE, mask);
};

inline void __attribute__((always_inline)) disable_interrupt(uint32_t source) {
    uint32_t mask = 0b1 << source;
    csrc(CSR_MIE, mask);
};



// Interrupt Pending
inline uint32_t __attribute__((always_inline)) get_interrupt_pending(uint32_t source) {
    return 0b1 & (csrr(CSR_MIP) >> source);
};

inline void __attribute__((always_inline)) set_interrupt_pending(uint32_t source) {
    uint32_t mask = 0b1 << source;
    csrs(CSR_MIP, mask);
};

inline void __attribute__((always_inline)) clear_interrupt_pending(uint32_t source) {
    uint32_t mask = 0b1 << source;
    csrc(CSR_MIP, mask);
};



// Trap Cause
inline uint32_t __attribute__((always_inline)) is_mcause_interrupt() {
    return csrr(CSR_MCAUSE) >> 31;
};


#endif // __TRAP_H
