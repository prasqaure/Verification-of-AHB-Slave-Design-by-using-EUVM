# AHB Interface Verification

## Overview

This repository contains a testbench and design for verifying an **AHB (Advanced High-performance Bus)** interface. The testbench is written in **UVM (Universal Verification Methodology)** using the D programming language, and the design is implemented in **Verilog**. The goal is to simulate and verify the functionality of an AHB slave interface.

The repository consists of two main files:

1. **ahb_design.v** - Verilog design for an AHB slave module.
2. **ahb_test.d** - UVM testbench written in D, implementing the AHB interface sequences, agents, and test environment.

## Files

### 1. **ahb_design.v**

This is the **Verilog** implementation of an AHB slave module. The module supports 32-bit data width and address width, and implements the basic AHB slave functionality including handling transfers, write/read operations, and responding with ready and response signals.

#### Key Parameters:
- **DW**: Data width (default 32 bits)
- **AW**: Address width (default 32 bits)

#### Functionality:
- **Inputs**:
  - **HCLK**: Clock
  - **HRESETn**: Active low reset
  - **HSEL**: Slave select
  - **HADDR**: Address
