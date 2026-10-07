SV_FILES = rtl/pkg/rv32i_pkg.sv $(wildcard rtl/core/*.sv)

.PHONY: lint sim-alu sim-top sim-top-build clean

lint:
	verilator --lint-only --Wall -sv -Wno-MULTITOP -Wno-UNUSEDPARAM \
		-Irtl/pkg -Irtl/core \
		$(SV_FILES)

sim-alu:
	verilator --binary -sv --timing --top-module tb_alu \
		rtl/pkg/rv32i_pkg.sv rtl/core/alu.sv tb/tb_alu.sv -o sim_alu
	./obj_dir/sim_alu

sim-top-build:
	verilator --binary -sv --timing --top-module tb_top \
		$(SV_FILES) tb/tb_top.sv -o sim_top

sim-top: sim-top-build
	./obj_dir/sim_top

clean:
	rm -rf obj_dir build *.log *.vcd
