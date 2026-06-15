# RV32I 5-Stage Pipelined Processor

By: **Tirth Patel**

![ISA](https://img.shields.io/badge/ISA-RISC--V-blue)
![RTL](https://img.shields.io/badge/RTL-SystemVerilog-orange)
![Simulation](https://img.shields.io/badge/Simulation-Verilator-green)
![Waveforms](https://img.shields.io/badge/Waveforms-GTKWave-purple)
![Target](https://img.shields.io/badge/Target-FPGA-red)

A fully functional 5-stage pipelined RISC-V processor (RV32I) implemented in SystemVerilog, supporting all 37 base integer instructions with data forwarding and hazard detection.

![CI](https://github.com/tirthp14/rv32i-pipeline/actions/workflows/ci.yml/badge.svg)

## Features

- Full RV32I ISA (37 instructions)
- 5-stage pipeline: IF → ID → EX → MEM → WB
- Data forwarding (EX→EX and MEM→EX paths)
- Load-use hazard detection and stall insertion
- Control hazard handling with 2-cycle branch flush
- Verified against the RISC-V compliance test suite

## Running locally

**Requirements:** Verilator ≥ 5.0, `riscv32-unknown-elf-gcc`

```bash
# Lint all RTL
make lint

# Run full pipeline testbench
make sim-top

# Run unit tests
make sim-alu
```

---

## Repository Structure (General Idea)
```
rv32i-pipeline/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                       <- lint + simulate on every push/PR
│   └── PULL_REQUEST_TEMPLATE.md
├── rtl/
│   ├── core/
│   │   ├── fetch.sv
│   │   ├── decode.sv
│   │   ├── execute.sv
│   │   ├── memory.sv
│   │   ├── writeback.sv
│   │   ├── pipeline_regs.sv
│   │   ├── alu.sv
│   │   ├── alu_control.sv
│   │   ├── reg_file.sv
│   │   ├── imm_gen.sv
│   │   ├── control_unit.sv
│   │   ├── hazard_unit.sv
│   │   ├── forwarding_unit.sv
│   │   └── top.sv
│   └── pkg/
│       └── rv32i_pkg.sv                 <- shared typedefs, opcodes, enums
├── tb/
│   ├── tb_top.sv                        <- main testbench
│   ├── tb_alu.sv                        <- unit test for ALU
│   ├── tb_reg_file.sv
│   └── programs/
│       ├── alu_ops.hex
│       ├── hazard_test.hex
│       ├── branch_test.hex
│       └── load_store.hex
├── docs/
│   ├── architecture.md                  <- your design decisions
│   ├── hazards.md
│   └── diagrams/
│       └── datapath.png
├── scripts/
│   ├── compile_test.sh                  <- compile C → .hex with riscv-gcc
│   └── run_sim.sh
├── Makefile
├── README.md
└── .verilator_lint                      <- lint config
```
