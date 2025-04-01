# AHB Interface Verification

## Overview

This repository provides the design and testbench for verifying an **AHB (Advanced High-performance Bus)** interface. The design is implemented in **Verilog**, while the testbench is written using **UVM (Universal Verification Methodology)** in the **D programming language**. This project is a comprehensive approach to simulate and verify the functionality of an AHB slave interface.

The repository includes the following primary files:
- **ahb_design.v**: The Verilog design for an AHB slave module.
- **ahb_test.d**: A UVM testbench in the D programming language for testing the AHB interface.

This project aims to test the AHB slave module's response to various AHB transactions, ensuring correct data transfer, timing, and handling of the AHB protocol.

## Files Overview

### 1. **ahb_design.v** (Verilog AHB Slave Design)

The `ahb_design.v` file defines an **AHB Slave module** with a simple memory interface. The slave responds to requests from a master, handling both read and write transactions according to the AHB protocol.

#### Key Parameters:
- **DW**: Data width of the bus (default is 32 bits).
- **AW**: Address width (default is 32 bits).

#### Module Ports:
- **Inputs**:
  - `HCLK`: Clock signal for the AHB interface.
  - `HRESETn`: Active low reset signal.
  - `HSEL`: Slave select signal indicating the slave is being accessed.
  - `HADDR`: Address bus for specifying the target address for read/write operations.
  - `HWRITE`: Write enable signal.
  - `HSIZE`: Size of the data transfer.
  - `HBURST`: Burst type signal for multi-word transfers.
  - `HTRANS`: Transfer type signal indicating the type of transaction.
  - `HWDATA`: Write data for write operations.
  
- **Outputs**:
  - `HRDATA`: Read data output.
  - `HREADY`: Ready signal indicating whether the slave is ready for the next transaction.
  - `HRESP`: Response signal indicating the result of the operation (success or error).

#### Functionality:
- **Memory Simulation**: The module includes a simple 16-word memory, where read and write operations are carried out based on the provided address (`HADDR`) and data (`HWDATA`).
- **Reset and Ready Logic**: The slave asserts `HREADY` when it is ready to accept the next transaction and responds with `HRESP` to indicate success or failure.
- **Read/Write Operations**: If the transaction is a write (`HWRITE`), the data is written to memory. If the transaction is a read, the corresponding data is fetched from memory and sent on `HRDATA`.

### 2. **ahb_test.d** (UVM Testbench)

The `ahb_test.d` file defines a **UVM-based testbench** written in the D programming language. It consists of several components to simulate the AHB sequence and verify the behavior of the AHB interface against the specified protocol.

#### Key Classes:
- **ahb_seq_item**:
  - Represents an individual sequence item for AHB transactions.
  - Contains fields like address (`addr`), data (`data`), and transaction control signals (`hwrite`, `hsize`, `hburst`, `htrans`).
  - Constraints ensure that addresses are aligned and within a valid range.

- **ahb_sequence**:
  - Defines the sequence of actions for the AHB interface.
  - Creates sequence items (`ahb_seq_item`), starts them, and finishes them, allowing you to generate AHB transactions.

- **ahb_sequencer**:
  - Manages the sequencing of AHB transactions by calling the `ahb_sequence` class.
  - Ensures the transactions are correctly driven according to the AHB protocol.

- **ahb_driver**:
  - Drives the AHB signals to the slave module based on the sequence item.
  - Implements the actual communication with the AHB slave by asserting the appropriate control signals and waiting for the slave to be ready (`HREADY`).
  
- **ahb_monitor**:
  - Monitors the AHB interface during simulation and records the values of signals like `HADDR`, `HWDATA`, `HWRITE`, and `HRESP`.
  - Captures transaction data for verification purposes.

- **ahb_agent**:
  - Combines the sequencer, driver, and monitor into a single agent that is used in the test environment.
  - Provides a cohesive unit for handling AHB transactions in the verification environment.

- **ahb_env**:
  - Sets up the environment that includes the agent and connects it to the rest of the testbench.

- **ahb_test**:
  - The top-level test class that instantiates the environment and runs the simulation.
  - Starts the sequence and drives the simulation to completion.

#### Functionality:
- The `ahb_test.d` file generates AHB transactions, executes them via the `ahb_driver`, and verifies the behavior through the `ahb_monitor`.
- The `ahb_sequence` defines a simple test that interacts with the AHB slave, triggering read/write operations and checking for proper responses.
- The testbench outputs logs using `uvm_info` for debugging and status tracking.

## Compilation and Simulation

To compile and run the simulation for both the design and the UVM testbench, follow these steps:

### 1. **Compiling the Verilog Design**:
   The Verilog design can be compiled using **Icarus Verilog**. Make sure you have Icarus Verilog installed on your machine. To compile the `ahb_design.v` file, run the following command:

   ```bash
   iverilog -g2012 -o ahb_tb ahb_design.v
