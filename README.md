# RISC-V CPU Project

A 32-bit RISC-V processor (RV32I) written in SystemVerilog, built from scratch.
First as a single-cycle CPU, then as a 5-stage pipelined CPU.

## CPU blocks

| Block | File | What it does | Status |
|---|---|---|---|
| Program counter (PC) | `rtl/riscv_core.sv` | Holds the address of the current instruction | Not started |
| Instruction memory | `tb/cpu_tb.sv` | Stores the program | Not started |
| Control unit | `rtl/control.sv` | Decodes each instruction and tells the other blocks what to do | Not started |
| Register file | `rtl/regfile.sv` | 32 registers that hold numbers (x0 is always 0) | Not started |
| Immediate generator | `rtl/imm_gen.sv` | Pulls the constant number out of an instruction | Not started |
| ALU | `rtl/alu.sv` | Does the math: add, subtract, AND, OR, compare, shift | Not started |
| Load/store unit | `rtl/load_store.sv` | Handles reading and writing bytes, half-words and words | Not started |
| Data memory | `tb/cpu_tb.sv` | Stores data for load and store instructions | Not started |
| Hazard unit | `rtl/hazard_unit.sv` | Keeps the pipeline correct (forwarding, stalls, flushes) | Not started |
| CPU top | `rtl/riscv_core.sv` | Connects all the blocks together | Not started |

## How an instruction flows

1. The **PC** gives an address to **instruction memory**.
2. **Instruction memory** returns the instruction.
3. The **control unit** decodes it; the **register file** and **immediate generator** supply the values.
4. The **ALU** does the calculation.
5. **Data memory** is used only by load and store instructions.
6. The result is written back to the **register file**, and the PC moves on.

## Folders

- `rtl/` design files
- `tb/` testbenches
- `programs/` test programs
- `docs/` specification 