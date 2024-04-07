# Machine Timer (mtime)



## Ports

### Parameters

- **`XLEN=32`** data width

### Inputs

- **`rd_en`** read enable flag from DBus
- **`wr_en`** write enable flag from DBus
- **`addr[1:0]`** read/write address from DBus
- **`wr_data[WIDTH-1:0]`** write data from DBus
- **`wr_strobe[(WIDTH/8)-1:0]`** byte enable for writes from DBus

### Outputs

- **`rd_data[WIDTH-1:0]`** read data to DBus
- **`time_rd_data[63:0]`** read-only `time(h)` CSR
- **`interrupt`** machine timer interrupt flag

## Behavior

The Machine Timer has two 64-bit registers: `mtime` and `mtimecmp`.
The `mtime` register is a counter that increments at the core clock frequency.
The `mtimecmp` register controls the interrupt behavior.
If `mtime` is unsigned greater than or equal to `mtimecmp` then the `interrupt` flag is asserted.
See The [CSR](./CSR.md) documentation for more details.

### Memory Mapped Registers

The trap unit is controlled by several memory mapped registers.
This module only takes two address bits as input.
These two bits correspond to the byte-addressable address bits `addr_32[3:2]`.
These registers are defined in the [CSR](./CSR.md) documentation.

**Table 1.** Mtime Memory Mapped Registers

| Addr | Name | Description |
| --- | --- | --- |
| 0xC000_0000 | `mtime`     | Lower 32 bits of `mtime`
| 0xC000_0004 | `mtimeh`    | Upper 32 bits of `mtime`
| 0xC000_0008 | `mtimecmp`  | Lower 32 bits of `mtimecmp`
| 0xC000_000C | `mtimecmph` | Upper 32 bits of `mtimecmp`
