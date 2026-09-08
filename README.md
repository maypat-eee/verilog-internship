# Binary Divider Architectures in Verilog

An RTL-level study and implementation of five binary division architectures for an 8-bit datapath, covering algorithmic design, structural Verilog implementation, simulation, and Vivado implementation analysis.

## Project Overview

Binary division is a relatively complex arithmetic operation in digital hardware because quotient generation depends on intermediate remainder calculations.

This project implements and analyzes five different divider architectures:

- **Restoring Division**
- **Non-Restoring Division**
- **SRT (Sweeney, Robertson, and Tocher) Division**
- **Newton-Raphson Division**
- **Goldschmidt Division**

The architectures are studied from both algorithmic and hardware perspectives, with emphasis on the trade-offs between speed, hardware resources, and implementation complexity.

---

## Architectures

### 1. Restoring Division

A sequential digit-recurrence architecture based on:

- Shift
- Subtract
- Check
- Restore when the subtraction produces a negative remainder

The RTL implementation uses structural components such as adders, registers, multiplexers, counters, and shifting logic.

**Source:** `src/restoring/restoring_divider.v`

---

### 2. Non-Restoring Division

A digit-recurrence architecture that avoids the explicit restoration operation by making the next add/subtract decision based on the sign of the partial remainder.

The implementation uses two's-complement arithmetic, an ALU, registers, shifting logic, control/counting logic, and a final correction stage.

**Source:** `src/non_restoring/non_restoring_divider.v`

---

### 3. SRT Division

Sweeney-Robertson-Tocher division uses redundant quotient digits and quotient-selection logic to reduce the amount of arithmetic required during division.

The implementation includes:

- Divisor normalization
- Quotient-selection logic
- Redundant quotient representation
- Arithmetic/ALU logic
- Quotient recombination
- Correction logic

**Source:** `src/srt/srt_divider.v`

---

### 4. Newton-Raphson Division

A multiplicative division architecture based on reciprocal approximation and iterative refinement.

The implementation includes:

- Divisor normalization
- LUT-based initial reciprocal approximation
- Fixed-point arithmetic
- Parallel multiplier architecture
- Two's-complement arithmetic
- Dynamic rounding
- Denormalization logic

**Source:** `src/newton_raphson/newton_raphson_divider.v`

---

### 5. Goldschmidt Division

Goldschmidt division uses simultaneous scaling of the numerator and denominator with a common convergence factor.

The implementation reuses foundational hardware blocks from the Newton-Raphson architecture and includes:

- Normalization
- LUT-based reciprocal seed
- Multiplication
- Convergence-factor generation
- Dynamic rounding
- Denormalization

**Source:** `src/goldschmidt/goldschmidt_divider.v`

---

## Architecture Comparison

| Architecture | Family | Main Approach | Hardware Characteristics |
|---|---|---|---|
| Restoring | Digit-recurrence | Shift, subtract, restore | Simple and compact |
| Non-Restoring | Digit-recurrence | Sign-dependent add/subtract | Avoids explicit restoration |
| SRT | Digit-recurrence | Redundant quotient digits | More complex, reduced arithmetic |
| Newton-Raphson | Multiplicative | Reciprocal approximation | Fast convergence, higher hardware cost |
| Goldschmidt | Multiplicative | Simultaneous numerator/denominator scaling | Fast convergence, multiplier-intensive |

For the 8-bit datapath studied in this project, the digit-recurrence architectures provide a practical balance of hardware cost and performance, while the multiplicative architectures demonstrate higher-speed convergence at the cost of substantially greater hardware complexity.

---

## Vivado Implementation Analysis

The repository includes Vivado synthesis and implementation reports for all five architectures.

The reports contain:

- Timing analysis
- Resource utilization
- On-chip power estimation
- Synthesis results
- Post-implementation results

### Resource Utilization

The reported Slice LUT utilization shows the relative hardware complexity of the architectures:

| Architecture | Synthesis Slice LUTs | Implementation Slice LUTs |
|---|---:|---:|
| SRT | 204 | 204 |
| Non-Restoring | 142 | 142 |
| Restoring | 139 | 138 |
| Newton-Raphson | 291 | 290 |
| Goldschmidt | 323 | 321 |

Goldschmidt additionally uses a reported **F7 Multiplier** resource in the implementation report.

These results illustrate the increased hardware requirements of the multiplicative approaches compared with the simpler digit-recurrence designs.

---

## Power Analysis

The Vivado reports contain the following **total on-chip power estimates**:

| Architecture | Synthesis Estimate | Implementation Estimate |
|---|---:|---:|
| Restoring | 6.201 W | 6.106 W |
| Non-Restoring | 9.598 W | 9.451 W |
| SRT | 15.504 W | 11.361 W |
| Newton-Raphson | 13.941 W | 13.312 W |
| Goldschmidt | 13.643 W | 13.263 W |

### Important Note on Power Results

The power figures in the Vivado report are **tool-based vectorless estimates**, not measurements from physical hardware.

Vivado's report indicates that the power analysis is based on the synthesized/implemented design and available activity assumptions. Therefore, these values should be interpreted as **estimates for comparative implementation analysis**, rather than experimentally measured power consumption.

The relatively high estimated power values are an important part of the architectural comparison and demonstrate the effect of switching activity and hardware complexity in the implemented designs.

---

## Key Engineering Trade-offs

### Digit-Recurrence Architectures

**Restoring, Non-Restoring, and SRT** operate through iterative quotient generation.

Their main advantages are:

- Relatively simple datapaths
- Lower hardware complexity
- Suitable for small datapaths
- Predictable iterative operation

Restoring and Non-Restoring division require one quotient bit per iteration, while SRT introduces additional quotient-selection and redundant-digit logic to improve the arithmetic process.

### Multiplicative Architectures

**Newton-Raphson and Goldschmidt** use reciprocal approximation and multiplication-based refinement.

Their main advantages are:

- Rapid convergence
- High-performance architecture
- Parallel arithmetic opportunities

Their disadvantages include:

- Larger multiplier structures
- LUT requirements
- Wider arithmetic datapaths
- Additional rounding and scaling logic
- Greater hardware complexity

For an 8-bit datapath, the project analysis indicates that these additional resources can outweigh the benefit of reducing the number of iterative operations.

---

## Repository Structure

```text
verilog-internship/
│
├── README.md
│
├── src/
│   ├── restoring/
│   │   └── restoring_divider.v
│   │
│   ├── non_restoring/
│   │   └── non_restoring_divider.v
│   │
│   ├── srt/
│   │   └── srt_divider.v
│   │
│   ├── newton_raphson/
│   │   └── newton_raphson_divider.v
│   │
│   └── goldschmidt/
│       └── goldschmidt_divider.v
│
└── docs/
    ├── architecture_and_theory.pdf
    └── vivado_implementation_results.pdf
