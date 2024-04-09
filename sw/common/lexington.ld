
OUTPUT_FORMAT("elf32-littleriscv")
OUTPUT_ARCH(riscv)
ENTRY(_start)


__Lexington_rom_size = 8K;
__Lexington_ram_size = 8K;

__Lexington_rom_base = 0x00000000;
__Lexington_ram_base = 0x40000000;

__Lexington_heap_size = DEFINED(__Lexington_heap_size) ? __Lexington_heap_size : 0;


MEMORY
{
    rom (rx) : ORIGIN = __Lexington_rom_base, LENGTH = __Lexington_rom_size
    ram (rw) : ORIGIN = __Lexington_ram_base, LENGTH = __Lexington_ram_size
}


SECTIONS
{

    .text : ALIGN(4)
    {

        KEEP(*(.text.startup)); /* keep start-up code at beginning of ROM */
        *(.text .text.*)

        /* Constructor/desctructor pointer array */
        PROVIDE_HIDDEN(__init_array_start = .);
        KEEP(*(.preinit_arra))
        KEEP(*(SORT_BY_INIT_PRIORITY(.init_array.*) SORT_BY_INIT_PRIORITY(.ctors.*)))
        KEEP(*(.init_array EXCLUDE_FILE (*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o ) .ctors))
        PROVIDE_HIDDEN(__init_array_end = .);
        KEEP (*(SORT_NONE(.init)))
        KEEP (*(SORT_NONE(.fini)))
        PROVIDE_HIDDEN(__fini_array_start = .);
        KEEP (*(SORT_BY_INIT_PRIORITY(.fini_array.*) SORT_BY_INIT_PRIORITY(.dtors.*)))
        KEEP (*(.fini_array EXCLUDE_FILE (*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o ) .dtors))
        PROVIDE_HIDDEN(__fini_array_end = .);

        /* Include build ID */
        PROVIDE(__Lexington_build_id_addr = .);
        KEEP(*(.note.gnu.build-id))

        /* finish section on word boundary */
        . = ALIGN(4);
    } > rom

    .rodata : ALIGN(4)
    {
        *(.rodata)
        /* finish section on word boundary */
        . = ALIGN(4);
    } > rom

    .bss (NOLOAD) : ALIGN(4)
    {
        __bss_start = .;
        *(.bss)
        /* finish section on word boundary */
        . = ALIGN(4);
        __bss_end = .;
    } > ram

    .data : ALIGN(4)
    {
        __data_start = .;
        *(.data)
        /* finish section on word boundary */
        . = ALIGN(4);
        __data_end = .;
    } > ram AT > rom

    .heap : ALIGN(4)
    {
        PROVIDE(__heap_start = .);
        . = __Lexington_heap_size;
        /* finish section on word boundary */
        . = ALIGN(4);
        PROVIDE(__head_end = .);
    } > ram

}


/* Export symbols for startup_Lexington.S */
PROVIDE(__Lexington_imem_begin              = ORIGIN(rom));
PROVIDE(__Lexington_dmem_begin              = ORIGIN(ram));
PROVIDE(__Lexington_stack_begin             = (ORIGIN(ram) + LENGTH(ram)) - 4);
PROVIDE(__Lexington_bss_start               = __bss_start);
PROVIDE(__Lexington_bss_end                 = __bss_end);
PROVIDE(__Lexington_copy_data_src_begin     = LOADADDR(.data));
PROVIDE(__Lexington_copy_data_dest_begin    = __data_start);
PROVIDE(__Lexington_copy_data_dest_end      = __data_end);
PROVIDE(__Lexington_heap_size               = __Lexington_heap_size);
