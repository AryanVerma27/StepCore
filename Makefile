# StepCore - build & run with Synopsys VCS
#   make            compile + run (defaults A=15, B=1)
#   make run A=100 B=37
#   make gui        open waveforms in DVE / Verdi
#   make clean

RTL  = rtl/pc.sv rtl/imem.sv rtl/dmem.sv rtl/regfile.sv rtl/alu.sv rtl/arm_core.sv
TB   = tb/tb_arm_core.sv
A   ?= 15
B   ?= 1

all: run

simv: $(RTL) $(TB)
	vcs -sverilog -full64 -debug_access+all -timescale=1ns/1ps $(TB) $(RTL) -o simv

run: simv
	./simv +A=$(A) +B=$(B)

gui: simv
	./simv -gui +A=$(A) +B=$(B)

clean:
	rm -rf simv simv.daidir csrc AN.DB DVEfiles ucli.key *.vpd *.vcd *.fsdb vc_hdrs.h *.log

.PHONY: all run gui clean
