SV_FILES = rtl/pkg/rv32i_pkg.sv $(wildcard rtl/core/*.sv)

.PHONY: lint sim-alu sim-top clean

lint:
	verilator --lint-only --Wall -sv -Wno-MULTITOP \
		-I rtl/pkg -I rtl/core \
		$(SV_FILES)

sim-alu:
	verilator --binary -sv --top-module tb_alu \
		rtl/pkg/rv32i_pkg.sv rtl/core/alu.sv tb/tb_alu.sv -o sim_alu
	./obj_dir/sim_alu

sim-top:
	verilator --binary -sv --top-module tb_top \
		$(SV_FILES) tb/tb_top.sv -o sim_top
	./obj_dir/sim_top

clean:
	rm -rf obj_dir *.log