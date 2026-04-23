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

## Memory scope decision for this project
1. Chosen method: blackbox ROM/RAM in synthesis runs for logic-domain comparison.
2. Functional simulation still uses inferred memory wrappers for firmware execution.
3. This keeps power comparison focused on CPU + interconnect + gated peripherals.

## Execution commands (Yosys)
1. `./scripts/run_synth_compare.sh`
2. Outputs:
   - `results/syn/with_memory/stat.txt`
   - `results/syn/blackbox_memory/stat.txt`
   - `results/syn/with_memory/yosys.log`
   - `results/syn/blackbox_memory/yosys.log`

## Exit criteria
- Both synthesis runs complete
- Reports are archived in `results/`
- Comparison table is ready for thesis chapter and slides
