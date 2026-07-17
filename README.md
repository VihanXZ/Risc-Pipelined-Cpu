# Pipelined RISC-V CPU (RV32I subset) — Verilog

A 5-stage pipelined processor implementing a subset of RV32I, built and verified in
simulation using Icarus Verilog. Includes data hazard handling via forwarding.

## Overview

This project implements a classic 5-stage pipelined CPU (Fetch, Decode, Execute,
Memory, Writeback) from scratch in Verilog, modeled after the standard RISC-V
RV32I instruction set. The design started as a single-cycle CPU to establish
functional correctness, then was converted to a pipelined implementation with
forwarding to resolve read-after-write data hazards.

## Supported instructions

| Type   | Instructions                  |
|--------|--------------------------------|
| R-type | add, sub, and, or, slt         |
| I-type | addi, andi, ori                |
| Load   | lw                              |
| Store  | sw                              |
| Branch | beq, bne                        |

## Architecture

```
   IF        ID        EX        MEM       WB
 ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐
 │Fetch│─►│Decode│─►│Exec │─►│ Mem │─►│Write│
 └─────┘  └─────┘  └─────┘  └─────┘  └─────┘
   PC     regfile    ALU    data_mem  regfile
  instr_  control_  forward-  (lw/sw)  (write
  mem     unit,     ing unit           port)
          imm_gen
```

Pipeline registers (`if_id`, `id_ex`, `ex_mem`, `mem_wb`) sit between each stage,
allowing 5 instructions to be in flight simultaneously.

### Modules

| File | Purpose |
|------|---------|
| `register_file.v` | 32 x 32-bit registers, 2 read ports + 1 write port, x0 hardwired to 0 |
| `alu.v` | Combinational ALU: add, sub, and, or, slt |
| `control_unit.v` | Decodes opcode/funct3/funct7 into datapath control signals |
| `imm_gen.v` | Extracts and sign-extends immediates for I/S/B instruction formats |
| `instr_mem.v` | Read-only instruction memory, loaded from a hex file |
| `data_mem.v` | Read/write data memory for lw/sw |
| `forwarding_unit.v` | Detects data hazards and selects forwarded operands |
| `cpu_pipelined_v2.v` | Top-level module wiring all of the above into the full pipeline |

## Hazard handling

**Data hazards (RAW):** resolved via forwarding. Before executing an instruction,
the forwarding unit checks whether either source register was just written by an
instruction still in the `EX/MEM` or `MEM/WB` pipeline register, and if so,
bypasses the register file entirely and feeds the fresher value directly into the
ALU.

Example that exercises this:
```
addi x2, x0, 10
addi x3, x0, 5
add  x1, x2, x3      ; needs x3's value 1 instruction after it's computed
sw   x1, 0(x0)         ; needs x1's value the instruction immediately after
```
Without forwarding, `add` reads stale (zero) values for x2/x3 and produces
`x1 = 0`. With forwarding, `x1` correctly resolves to `15`.

**Control hazards (branches):** resolved by evaluating the branch condition in
the EX stage and flushing the two speculatively-fetched instructions (`if_id`
and `id_ex`) if the branch is taken.

**Known limitation:** load-use hazards (a `lw` immediately followed by an
instruction that depends on the loaded value) are not yet handled. Forwarding
alone cannot resolve this case, since the loaded value isn't available until
one cycle after where forwarding would need it — it requires a one-cycle
pipeline stall, which is a planned next step.

## How to run

Requires [Icarus Verilog](http://iverilog.icarus.com/) and (optionally)
[GTKWave](http://gtkwave.sourceforge.net/) for waveform viewing.

```bash
iverilog -o sim.out register_file.v alu.v control_unit.v imm_gen.v \
    instr_mem.v data_mem.v forwarding_unit.v cpu_pipelined_v2.v \
    cpu_pipelined_v2_tb.v
vvp sim.out
gtkwave cpu_pipelined_v2.vcd
```

Each module also has its own standalone testbench (e.g. `alu_tb.v`,
`register_file_tb.v`) for isolated unit testing.

## Test results

All modules pass their individual testbenches. The full pipelined CPU correctly
executes a 6-instruction test program exercising arithmetic, memory, and branch
instructions:

```
PASS: x2 = 10
PASS: x3 = 5
PASS: x1 = 15 (10 + 5, forwarded correctly)
PASS: mem[0] = 15 (sw correctly stored the forwarded x1 value)
PASS: x4 = 15 (loaded back correctly)
```

## Next steps

- Load-use hazard detection and single-cycle stall
- Expand instruction subset (jal, jalr, more branch types)
- Synthesize and check timing/resource utilization on real FPGA toolchain
