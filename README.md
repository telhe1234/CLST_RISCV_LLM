# CLST_RISCV_LLM
Tools and benchmarks for CLST-guided LLM-aided RISC-V processor generation and FPGA evaluation

## CLST-Guided Generation Workflow

This repository provides a Colab/Jupyter notebook and supporting Python scripts for running the CLST-guided LLM-aided hardware design workflow. The default configuration uses ChatGPT through the OpenAI API, which requires an OpenAI API key. Other frontier LLMs can be integrated by modifying the model-call section of the notebook or script.

The required inputs include a sequence of RV32I processor design tasks, reference figures used for multimodal grounding, and unit testbenches for each processor submodule and for the top-level module. These inputs guide the generation, repair, and evaluation of Verilog HDL modules that are incrementally integrated into a complete single-cycle RV32I RISC-V processor.

The repository includes:

- Verilog RTL source files for the generated processor modules.
- Module-level and top-level Verilog testbenches.
- CLST prompt files and topic-based design specifications.
- Reference figures and workflow diagrams used by the generation script.
- Python/Colab scripts for generation, repair, and pass@k evaluation.
- JSONL/CSV result logs and summary tables.
- Quartus project files for FPGA synthesis and implementation.

## Reproducibility

The included notebooks and scripts can be used to reproduce the generation loop, collect JSONL result logs, compute pass@k summaries, and compare generated Verilog modules against the provided unit testbenches.

The Quartus project files are provided to support FPGA synthesis and implementation on the Altera MAX 10 FPGA using the Terasic DE10-Lite development board.

## Acknowledgment and Related Work

This repository adapts parts of the evaluation workflow from the ROME hierarchical prompting framework introduced in:

Andre Nakkab, Sai Qian Zhang, Ramesh Karri, and Siddharth Garg, "Rome was Not Built in a Single Step: Hierarchical Prompting for LLM-based Chip Design," arXiv:2407.18276, 2024.

The present repository modifies and extends the ROME-style generation and evaluation workflow for CLST-guided LLM-aided RV32I RISC-V processor design, simulation, pass@k benchmarking, and FPGA implementation.