# AXI4-Lite Crossbar

The AXI4-Lite Crossbar connects multiple subordinates to a single manager.


## Ports

### Parameters

- **`WIDTH = 32`** data bus width
- **`ADDR_WIDTH = 32`** upstream manager address width
- **`COUNT = 2`** number of downstream subordinates
- **`S_ADDR_WIDTH = 4`** downstream subordinate address width
- **`S_BASE_ADDR = [0x0000_0000,0x0000_0010]`** array of downstream subordinate base addresses

***Important:** address spaces must not overlap!*

### Inputs

- **`axi_s`** subordinate interface to connect to upstream manager

### Outputs

- **`axi_mx[COUNT-1:0]`** manager interface to connect to downstream subordinate *x*

## Behavior

The AXI4-Lite crossbar decodes address from the upstream manager an routes transactions to the appropriate downstream subordinate.
All subordinates must have the same address width.

### Memory Map

**Table 1.** Memory Mapped I/O

| Address | Device |
| --- | --- |
| 0xFFD0_0000 - 0xFFD3_FFFF | `VGA` |
| 0xFFFF_FF00 - 0xFFFF_FF0F | `TIM0` |
| 0xFFFF_FF10 - 0xFFFF_FF1F | `TIM1` |
| 0xFFFF_FF70 - 0xFFFF_FF8F | `UART0` |
| 0xFFFF_FFA0 - 0xFFFF_FFAF | `GPIOA` |
| 0xFFFF_FFB0 - 0xFFFF_FFBF | `GPIOB` |
| 0xFFFF_FFC0 - 0xFFFF_FFCF | `GPIOC` |
