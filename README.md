# FPGA Differential Filter Accelerator ⚡

This project implements a hardware accelerator for **differential signal filtering** on FPGA, designed using **VHDL** and **Xilinx Vivado**. The module interfaces directly with memory to process data streams using configurable Order-3 and Order-5 filters, optimized for minimal resource usage.

## 🎯 Key Features
* **Finite State Machine (FSM):** Designed a robust 17-state FSM to manage setup, loading, filtering, saturation, and writing phases independently.
* **Memory Management:** Low-level interfacing with synchronous RAM (Reading/Writing bytes) with handshake protocols.
* **Signal Processing:** Implementation of convolution filters with dynamic coefficients:
    * *Order 3 Filter:* Smoothing and noise reduction.
    * *Order 5 Filter:* Complex signal processing with normalization factor $n=60$.
* **Optimization:** Bitwise operations used for division/multiplication approximation to avoid heavy arithmetic logic units (ALUs).

## 🛠 Architecture
The design abandoned a modular approach in favor of an **Integrated FSM** to improve timing performance and debuggability.
![FSM Diagram](./docs/fsm_diagram.png) *(Suggerimento: fai uno screenshot della pagina 11 del tuo PDF)*

## 🚀 Performance
* **Synthesis Tool:** Vivado 2016.1
* **Latency:** Optimized to process continuous streams of data with minimal idle cycles.
* **Robustness:** Tested against edge cases (K=0, K=Max, Saturating values) via exhaustive Testbenches.

## 📄 Documentation
For a deep dive into the state machine logic and experimental results, check the full report:
👉 **[Read the Technical Report](./docs/Report_Progetto.pdf)**
