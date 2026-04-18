# Phase 4 (Week 10-12): ASIC Synthesis and Evaluation

## Target outcome
Gate-level synthesis reports with and without clock gating, and quantified power benefit.

## Tasks
1. Select technology/library flow:
   - commercial flow (Design Compiler + foundry lib), or
   - open-source flow (Yosys + Sky130)
2. Prepare synthesis scripts and constraints:
   - clocks, io delays, basic constraints
3. Run synthesis twice:
   - case A: no clock gating
   - case B: with clock gating
4. Collect reports:
   - power.rpt
   - area.rpt
   - timing.rpt
5. Compare dynamic and leakage power

## Exit criteria
- Both synthesis runs complete
- Reports are archived in `results/`
- Comparison table is ready for thesis chapter and slides
