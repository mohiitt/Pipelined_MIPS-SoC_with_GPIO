# GPIO Memory-Mapped Module

## Overview
The `gpio.v` module implements a memory-mapped GPIO interface for a SoC design. It provides two 32-bit registers accessible via memory-mapped I/O.

## Interface

### CPU Interface (Memory-Mapped)
- `clk` - System clock
- `rst` - Active-high reset
- `addr[31:0]` - Memory address for GPIO register access
- `wdata[31:0]` - Write data from CPU
- `rdata[31:0]` - Read data to CPU
- `memRead` - Memory read enable signal
- `memWrite` - Memory write enable signal

### GPIO External Interface
- `gpio_in_pins[31:0]` - External input pins (connected to GPIO_IN register)
- `gpio_out_pins[31:0]` - External output pins (driven by GPIO_OUT register)

## Memory Map

| Address    | Register  | Access | Description |
|------------|-----------|--------|-------------|
| 0x00000000 | GPIO_IN   | R      | Read-only input register |
| 0x00000004 | GPIO_OUT  | R/W    | Read/write output register |

## Functionality

### GPIO_IN Register (0x00000000)
- **Read-only** from CPU perspective
- Continuously synchronized with `gpio_in_pins`
- Updates on every clock cycle
- CPU writes to this address are ignored

### GPIO_OUT Register (0x00000004)
- **Read/write** from CPU perspective
- CPU writes update both internal register and `gpio_out_pins`
- CPU reads return the current register value
- Resets to 0x00000000

## Usage Example

```verilog
// Instantiate GPIO module
gpio gpio_inst (
    .clk(system_clk),
    .rst(system_rst),
    .addr(cpu_addr),
    .wdata(cpu_wdata),
    .rdata(cpu_rdata),
    .memRead(cpu_memRead),
    .memWrite(cpu_memWrite),
    .gpio_in_pins(external_inputs),
    .gpio_out_pins(external_outputs)
);
```

## Testing
Use `testbench/tb_gpio.v` to verify functionality:
- Tests GPIO_IN register reads
- Tests GPIO_OUT register writes and reads
- Verifies read-only behavior of GPIO_IN
- Tests pin synchronization

## Integration Notes
- Designed to follow the same memory interface pattern as `dmem.v`
- Compatible with memory-mapped I/O systems
- Address decoding assumes exact address matches
- Ready for integration with pipelined CPU when available