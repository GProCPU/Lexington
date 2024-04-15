#ifndef __CSR_H
#define __CSR_H

#include <stdint.h>


#define CSR_MISA            
#define CSR_MVENDORID       0xF11
#define CSR_MARCHID         0xF12
#define CSR_MIMPID          0xF13
#define CSR_MHARTID         0xF14
#define CSR_MSTATUS         0x300
#define CSR_MSTATUSH        0x310
#define CSR_MTVEC           0x305
#define CSR_MIP             0x344
#define CSR_MIE             0x304
#define CSR_CYCLE           0xC00
#define CSR_CYCLEH          0xC80
#define CSR_MCYCLE          0xB00
#define CSR_MCYCLEH         0xB80
#define CSR_INSTRET         0xC02
#define CSR_INSTRETH        0xC82
#define CSR_MINSTRET        0xB02
#define CSR_MINSTRETH       0xB82
#define CSR_MCOUNTINHIBIT   0x320
#define CSR_MSCRATCH        0x340
#define CSR_MEPC            0x341
#define CSR_MCAUSE          0x342
#define CSR_MTVAL           0x343
#define CSR_MCONFIGPTR      0xF15
#define CSR_TIME            0xC01
#define CSR_TIMEH           0xC80


#ifdef __cplusplus
extern "C" {
#endif

static inline uint32_t __attribute__ ((always_inline)) csrrw(const uint32_t csr, uint32_t data) {
    uint32_t result;
    __asm__ volatile inline (
        "csrrw %[result], %[csr], %[data]"
        : [result] "=r" (result)
        : [csr] "i" (csr), [data] "r" (data)
    );
    return result;
}

static inline uint32_t __attribute__ ((always_inline)) csrrs(const uint32_t csr, uint32_t mask) {
    uint32_t result;
    __asm__ volatile inline (
        "csrrs %[result], %[csr], %[mask]"
        : [result] "=r" (result)
        : [csr] "i" (csr), [mask] "r" (mask)
    );
    return result;
}

static inline uint32_t __attribute__ ((always_inline)) csrrc(const uint32_t csr, uint32_t mask) {
    uint32_t result;
    __asm__ volatile inline (
        "csrrc %[result], %[csr], %[mask]"
        : [result] "=r" (result)
        : [csr] "i" (csr), [mask] "r" (mask)
    );
    return result;
}


static inline void __attribute__ ((always_inline)) csrw(const uint32_t csr, uint32_t data) {
    __asm__ volatile inline (
        "csrw %[csr], %[data]"
        : 
        : [csr] "i" (csr), [data] "r" (data)
    );
}

static inline void __attribute__ ((always_inline)) csrs(const uint32_t csr, uint32_t mask) {
    __asm__ volatile inline (
        "csrs %[csr], %[mask]"
        : 
        : [csr] "i" (csr), [mask] "r" (mask)
    );
}

static inline void __attribute__ ((always_inline)) csrc(const uint32_t csr, uint32_t mask) {
    __asm__ volatile inline (
        "csrc %[csr], %[mask]"
        : 
        : [csr] "i" (csr), [mask] "r" (mask)
    );
}


static inline uint32_t __attribute__ ((always_inline)) csrr(const uint32_t csr) {
    uint32_t result;
    __asm__ volatile inline (
        "csrr   %[result], %[csr]"
        : [result] "=r" (result)
        : [csr] "i" (csr)
    );
    return result;
}


static inline uint32_t __attribute__ ((always_inline)) csr_swap(const uint32_t csr, uint32_t data) {
    __asm__ volatile inline (
        "csrrw  %[result], %[csr], %[data]"
        : [result] "+r" (data)
        : [csr] "n" (csr), [data] "r" (data)
    );
    return data;
}

#ifdef __cplusplus
} // extern "C"
#endif

#endif // __CSR_H
