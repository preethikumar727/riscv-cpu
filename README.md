# RISC-V CPU Project

A 32-bit RISC-V processor (RV32I) written in SystemVerilog, built from scratch.
First as a single-cycle CPU, then as a 5-stage pipelined CPU.

**Status:** Single-cycle RV32I CPU complete. All 28 tests pass on a real program.
Next: 5-stage pipeline.

## CPU blocks

| Block | File | What it does | Status |
|---|---|---|---|
| ALU | `rtl/alu.sv` | Does the math: add, subtract, AND, OR, compare, shift | Done |
| Register file | `rtl/regfile.sv` | 32 registers that hold numbers (x0 is always 0) | Done |
| Immediate generator | `rtl/imm_gen.sv` | Pulls the constant number out of an instruction | Done |
| Control unit | `rtl/control.sv` | Decodes each instruction and tells the other blocks what to do | Done |
| Branch comparator | `rtl/branch_comp.sv` | Decides whether a branch jumps (beq, bne, blt, ...) | Done |
| Load/store unit | `rtl/load_store.sv` | Handles reading and writing bytes, half-words and words | Done |
| Program counter (PC) | `rtl/riscv_core.sv` | Holds the address of the current instruction | Done |
| CPU top | `rtl/riscv_core.sv` | Connects all the blocks together | Done |
| Instruction memory | `tb/cpu_tb.sv` | Stores the program | Done |
| Data memory | `tb/cpu_tb.sv` | Stores data for load and store instructions | Done |
| Hazard unit | `rtl/hazard_unit.sv` | Keeps the pipeline correct (forwarding, stalls, flushes) | Not started |

## How an instruction flows

1. The **PC** gives an address to **instruction memory**.
2. **Instruction memory** returns the instruction.
3. The **control unit** decodes it; the **register file** and **immediate generator** supply the values.
4. The **ALU** does the calculation; the **branch comparator** checks branch conditions.
5. **Data memory** is used only by load and store instructions.
6. The result is written back to the **register file**, and the PC moves on.

## Test results

Every block has its own self-checking testbench, and the full CPU runs a real
RISC-V program (`programs/test_basic.hex`) covering arithmetic, shifts, all load
and store sizes, a loop, branches, and a function call and return.

| Testbench | Tests | Result |
|---|---|---|
| `tb/alu_tb.sv` | 13 | Pass |
| `tb/regfile_tb.sv` | 40 | Pass |
| `tb/imm_gen_tb.sv` | 15 | Pass |
| `tb/control_tb.sv` | 18 | Pass |
| `tb/branch_comp_tb.sv` | 13 | Pass |
| `tb/load_store_tb.sv` | 15 | Pass |
| `tb/cpu_tb.sv` (full CPU) | 28 | Pass |

## How to run

Requires [Icarus Verilog](https://steveicarus.github.io/iverilog/) and GTKWave.

Run the full CPU test:
```
iverilog -g2012 -o sim rtl/*.sv tb/cpu_tb.sv
vvp sim
```

Run a single block's test, for example the ALU:
```
iverilog -g2012 -o sim rtl/alu.sv tb/alu_tb.sv
vvp sim
```

View the waveform:
```
gtkwave cpu.vcd
```

## Folders

- `rtl/` design files
- `tb/` testbenches
- `programs/` test programs
- `docs/` specification