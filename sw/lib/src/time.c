#include "time.h"

volatile uint32_t __ticks_per_milli;
volatile uint32_t __millis = 0;


void __MTI_HANDLER() {
    __save_context();
    set_mtimecmp(get_mtimecmp() + __ticks_per_milli);
    __millis++;
    __restore_context();
    mret_interrupt();
}

void time_init(uint32_t ticks_per_milli) {
    disable_interrupt(TRAP_CODE_MTI);
    __ticks_per_milli = ticks_per_milli;
    __millis = 0;
    set_mtime(0);
    set_mtimecmp(__ticks_per_milli);
    enable_interrupt(TRAP_CODE_MTI);
    enable_global_interrupts();
}

void delay(uint32_t val) {
    typedef union {
        uint64_t u64;
        uint32_t u32[2];
    } counter_t;

    // Get starting time
    disable_interrupt(TRAP_CODE_MTI);
        uint64_t start_tick = get_mtime();
        uint64_t start_cmp = get_mtimecmp();
        uint32_t start_milli = __millis;
    enable_interrupt(TRAP_CODE_MTI);

    uint64_t delta_ticks = start_cmp - start_tick;

    // Wait until end millis
    uint32_t end_milli = start_milli + val;
    while (__millis < end_milli); // wait

    // Wait until end tick
    counter_t end_tick;
    end_tick.u64 = get_mtimecmp() - delta_ticks;
    while (end_tick.u32[1] < csrr(CSR_TIMEH));
    while (end_tick.u32[0] <= csrr(CSR_TIME));
}

// void delay_micro(uint32_t val) {
//     union {
//         uint64_t u64;
//         uint32_t u32[2];
//     } counter;
//     counter.u32[0] = val;
//     counter.u32[1] = 0;

//     counter.u64 += get_mtime();
//     while (counter.u32[1] < csrr(CSR_TIMEH));
//     while (counter.u32[0] <= csrr(CSR_TIME));
// }
