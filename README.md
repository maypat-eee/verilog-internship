# Binary Divider Architectures in Verilog

An RTL-level study and implementation of five binary division architectures for an 8-bit datapath.

## Project Overview

This project explores and implements five approaches to binary division:

- Restoring Division
- Non-Restoring Division
- SRT (Sweeney, Robertson, and Tocher) Division
- Newton-Raphson Division
- Goldschmidt Division

The work compares digit-recurrence and multiplicative approaches from a hardware-architecture perspective, including datapath organization, shifting, arithmetic units, correction logic, lookup tables, multiplier structures, rounding, and control logic.

## Architectures

### 1. Restoring Division

A sequential shift-subtract architecture that processes one quotient bit per cycle. The implementation uses registers, add/subtract logic, multiplexing, a counter, and shifting logic.

**Top module:** `divider`

Source: `src/restoring/restoring_divider.v`

### 2. Non-Restoring Division

A digit-recurrence architecture that avoids the explicit restore operation by selecting addition or subtraction based on the partial remainder sign. The implementation includes an ALU, sign-dependent control, registers, shifting, and final correction logic.

**Top module:** `NON`

Source: `src/non_restoring/non_restoring_divider.v`

### 3. SRT Division

A radix-2 SRT architecture using the redundant quotient digit set {-1, 0, +1}. The implementation includes divisor normalization, quotient-select logic (QSL), a three-way arithmetic path, quotient recombination, and correction logic.

**Top module:** `srt`

Source: `src/srt/srt_divider.v`

### 4. Newton-Raphson Division

A multiplicative division architecture that approximates the reciprocal of the normalized divisor and refines it using multiplication. The implementation includes fixed-point processing, a LUT seed, multiplier logic, reciprocal refinement, rounding, and denormalization.

**Top module:** `divider`

Source: `src/newton_raphson/newton_raphson_divider.v`

### 5. Goldschmidt Division

A multiplicative architecture that scales the numerator and denominator using a common convergence factor. The implementation reuses the same style of foundational hardware blocks as the Newton-Raphson design, including normalization, LUT, multiplication, rounding, and denormalization.

**Top module:** `gdivider`

Source: `src/goldschmidt/goldschmidt_divider.v`

## Comparison

| Architecture | Approach | Main characteristic |
|---|---|---|
| Restoring | Digit recurrence | Simple, area-efficient, sequential |
| Non-Restoring | Digit recurrence | Avoids explicit restoration |
| SRT | Digit recurrence | Redundant quotient digits and quotient selection |
| Newton-Raphson | Multiplicative | Fast reciprocal convergence with higher hardware cost |
| Goldschmidt | Multiplicative | Simultaneous numerator/denominator scaling |

For the 8-bit datapath studied in the accompanying report, the digit-recurrence methods provide a practical area/power/speed trade-off, while Newton-Raphson and Goldschmidt demonstrate high-speed multiplicative architectures at the cost of substantially more hardware.

## Repository Structure

```text
verilog-internship/
├── README.md
├── src/
│   ├── restoring/
│   │   └── restoring_divider.v
│   ├── non_restoring/
│   │   └── non_restoring_divider.v
│   ├── srt/
│   │   └── srt_divider.v
│   ├── newton_raphson/
│   │   └── newton_raphson_divider.v
│   └── goldschmidt/
│       └── goldschmidt_divider.v
├── docs/
│   └── internship_report.pdf
└── simulation/
```

## Documentation

The detailed internship report covers the mathematical foundation, hardware architecture, cycle-by-cycle operation, simulation results, and comparative analysis of the five divider architectures.

## Notes

- The Verilog source files in this repository are the original implementations organized by architecture.
- The project is focused on an 8-bit datapath.
- Simulation/testbench files can be added to the `simulation/` directory if they are available and cleared for public sharing.
- Before making the repository public, confirm that the internship work and report are permitted to be shared publicly and that no confidential/proprietary information is included.
