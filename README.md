# ESE545_ComputerArchitecture_Final

This repository contains the VHDL source and related documents for my submission for the final project of ESE545 - Computer Architecture at Stony Brook in 2022.
The project requirements were to generate a cycle-accurate HDL model of the Cell SPU given a subset of instructions detailed in the ISA.

The Cell SPU is a dual-instruction fetch in-order SIMD processing unit implemented with seven execution pipelines that are organized into two groups: the even pipelines and the odd pipelines.  As per the Cell SPU specification, each pipeline group can have at most one instruction per stage in the pipeline, so two instructions can not be routed to two pipelines in the same pipeline group in the same clock cycle.

This model includes units for instruction routing, branch prediction, data hazard detection, structural hazard detection, and data forwarding.

For more details on any of the logic mentioned above, I've included a copy of the final report I submitted with this project that describes how all of these mechanisms function, how they're represented in the hardware description, and the decisions I made while implementing them.
