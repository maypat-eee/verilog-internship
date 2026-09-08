# Binary Divider Architectures in Verilog

This repo holds the work from my internship project, where I implemented and compared five different binary division architectures in Verilog for an 8-bit datapath. The goal was to go beyond just "make division work in hardware" and actually understand *why* you'd pick one approach over another — in terms of speed, area, and complexity.

Division is one of those operations that looks trivial in software (`a / b`) but turns into a real design problem in hardware, mostly because you can't just compute the quotient in one shot — each bit usually depends on the remainder from the step before it. That dependency is what makes this a genuinely interesting RTL problem, and it's why there isn't one "correct" divider — just different trade-offs.

I built and tested:

- Restoring Division
- Non-Restoring Division
- SRT (Sweeney-Robertson-Tocher) Division
- Newton-Raphson Division
- Goldschmidt Division

The first three are the classic "digit-recurrence" style — shift, subtract, check, repeat. The last two take a completely different approach based on multiplying by successive approximations of the reciprocal. I wanted to implement both families so I could actually compare them instead of just reading about the differences.

## How the architectures work

### Restoring Division
`src/restoring/restoring_divider.v`

This is the most straightforward of the bunch, and honestly a good place to start if you've never built a divider before. Each cycle it shifts, subtracts the divisor, and checks the sign of the result. If the subtraction went negative, it "restores" the previous remainder by adding the divisor back before moving on. It's built from fairly standard blocks — adders, a shift register, a mux, and a counter to track iterations. Simple to reason about, but you pay for that simplicity with an extra correction step whenever the subtraction fails.

### Non-Restoring Division
`src/non_restoring/non_restoring_divider.v`

This is basically the same idea as restoring division, but smarter about avoiding wasted cycles. Instead of restoring the remainder immediately after a negative subtraction, it just remembers the sign and decides whether to add or subtract on the *next* iteration. Everything runs in two's complement, so there's no separate restore step — just a correction pass at the very end to clean up the final remainder. It's a small change on paper but it noticeably simplifies the control logic.

### SRT Division
`src/srt/srt_divider.v`

This one's more involved. SRT division uses redundant quotient digits (instead of committing to a single bit each cycle) and a quotient-selection function to figure out which digit to pick. That flexibility is what lets it reduce arithmetic work per cycle, but it comes at the cost of extra logic:

- Divisor normalization
- Quotient-selection logic
- Redundant digit representation
- The ALU/arithmetic core
- A recombination and correction stage at the end

This was the most fiddly of the three digit-recurrence designs to get working correctly — the redundant representation makes debugging less intuitive than a plain restoring/non-restoring design.

### Newton-Raphson Division
`src/newton_raphson/newton_raphson_divider.v`

Here's where the approach changes entirely. Instead of grinding through bit-by-bit subtraction, this method approximates 1/divisor and refines that approximation with a couple of multiplication steps until it's accurate enough to multiply by the numerator. The implementation needed:

- Normalization of the divisor
- A LUT to get an initial reciprocal guess
- Fixed-point arithmetic throughout
- A parallel multiplier
- Two's complement handling
- Rounding and denormalization at the end

Convergence is fast (quadratic, in theory), but you're trading iteration count for a much heavier datapath — multipliers aren't cheap.

### Goldschmidt Division
`src/goldschmidt/goldschmidt_divider.v`

Goldschmidt is a close cousin of Newton-Raphson — same general idea of reciprocal approximation, but instead of refining the reciprocal directly, it scales the numerator and denominator together using a shared convergence factor until the denominator approaches 1. It reuses a lot of the hardware blocks from the Newton-Raphson implementation (normalization, LUT seed, multiplier), plus its own convergence-factor generation logic. One nice property is that its multiplications can run in parallel more easily than Newton-Raphson's, which matters if you're optimizing for latency rather than area.

## Comparing the five

| Architecture   | Family           | Core idea                              | What stands out                          |
|----------------|------------------|-----------------------------------------|-------------------------------------------|
| Restoring      | Digit-recurrence | Shift, subtract, restore                | Simplest to build and debug               |
| Non-Restoring  | Digit-recurrence | Sign-based add/subtract decision        | Skips the explicit restore step           |
| SRT            | Digit-recurrence | Redundant quotient digits               | Less arithmetic, more control complexity  |
| Newton-Raphson | Multiplicative   | Iterative reciprocal refinement         | Converges fast, needs a real multiplier   |
| Goldschmidt    | Multiplicative   | Parallel numerator/denominator scaling  | Similar cost to N-R, more parallel-friendly |

For an 8-bit datapath specifically, my takeaway was that the digit-recurrence designs are the more sensible choice — the multiplicative methods are built to shine on wider datapaths where cutting the iteration count really pays off, but at 8 bits that advantage doesn't outweigh the extra multiplier hardware.

## Vivado results

All five designs were synthesized and implemented in Vivado, and the full reports (timing, utilization, power) are in `docs/`. A couple of numbers worth calling out here:

**Slice LUT usage** (synthesis vs. implementation):

| Architecture   | Synthesis | Implementation |
|----------------|-----------|-----------------|
| Restoring      | 139       | 138             |
| Non-Restoring  | 142       | 142             |
| SRT            | 204       | 204             |
| Newton-Raphson | 291       | 290             |
| Goldschmidt    | 323       | 321             |

That's roughly a 2x jump in LUT count going from the digit-recurrence designs to the multiplicative ones — which lines up with expectations, given how much extra logic the reciprocal approach needs. Goldschmidt also pulled in a dedicated F7 multiplier resource during implementation, which the other four didn't.

**Estimated on-chip power**:

| Architecture   | Synthesis | Implementation |
|----------------|-----------|-----------------|
| Restoring      | 6.201 W   | 6.106 W         |
| Non-Restoring  | 9.598 W   | 9.451 W         |
| SRT            | 15.504 W  | 11.361 W        |
| Newton-Raphson | 13.941 W  | 13.312 W        |
| Goldschmidt    | 13.643 W  | 13.263 W        |

Worth flagging: these are Vivado's vectorless power estimates, not something measured off real silicon, so treat them as a way to compare the designs relative to each other rather than absolute numbers. Still, the gap between Restoring and everything else is large enough to be a meaningful part of the comparison, not just noise.

## What I took away from this

The digit-recurrence family (Restoring, Non-Restoring, SRT) is where you go if you want something compact and predictable — good default choice for smaller datapaths. Non-Restoring in particular felt like the best "bang for your buck": barely more complex than Restoring, but a bit more efficient.

The multiplicative family (Newton-Raphson, Goldschmidt) earns its complexity by converging fast, but that speed is bought with real hardware cost — bigger multipliers, LUT tables, wider fixed-point paths, and extra rounding logic. For this 8-bit case, that trade didn't pay off; I'd expect the balance to tip the other way as the datapath gets wider and the number of digit-recurrence iterations starts to actually hurt.

## Repo layout

```
verilog-internship/
│
├── README.md
│
├── src/
│   ├── restoring/restoring_divider.v
│   ├── non_restoring/non_restoring_divider.v
│   ├── srt/srt_divider.v
│   ├── newton_raphson/newton_raphson_divider.v
│   └── goldschmidt/goldschmidt_divider.v
│
└── docs/
    ├── architecture_and_theory.pdf
    └── vivado_implementation_results.pdf
```
