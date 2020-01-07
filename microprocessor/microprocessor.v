/* Main module to run the microprocessor */
module microprocessor (

	input clk, reset,
	input [3:0] i_pins,
	output [3:0] o_reg, x0, x1, y0, y1, r, m, i,
	output [7:0] from_ID, ir, from_CU, pm_data, pm_address, pc, from_PS,
	output [8:0] reg_enables,
	output NOPC8, NOPCF, NOPD8, NOPDF, zero_flag
);

wire n_clk, jump, conditional_jump, i_mux_select, y_reg_select, x_reg_select;
wire sync_reset;
wire [3:0] LS_nibble_ir, source_select, data_mem_addr, data_bus, dm;
	
	/* Inverter */
	not(n_clk, clk);
	
	/* Sync_reset flip-flop */
	dff DFF(.d(reset), .q(sync_reset), .clk(clk));
	
	program_memory prog_mem(				.clock(n_clk), 
													.address(pm_address), 
													.q(pm_data));
	
	Instruction_decoder instr_decoder(	.clk(clk),
													.next_instr(pm_data),
													.sync_reset(sync_reset),
													.jmp(jump), .jmp_nz(conditional_jump),
													.ir_nibble(LS_nibble_ir),
													.i_sel(i_mux_select),
													.y_sel(y_reg_select),
													.x_sel(x_reg_select),
													.source_sel(source_select),
													.reg_en(reg_enables),
													.from_ID(from_ID),
													.NOPC8(NOPC8),
													.NOPCF(NOPCF),
													.NOPD8(NOPD8),
													.NOPDF(NOPDF),
													.ir(ir));
	
	program_sequencer prog_sequencer(	.clk(clk),
													.sync_reset(sync_reset),
													.jmp(jump),
													.jmp_nz(conditional_jump),
													.jmp_addr(LS_nibble_ir),
													.dont_jmp(zero_flag),
													.pc(pc),
													.from_PS(from_PS),
													.pm_addr(pm_address));
	
	Computational_unit comp_unit(			.sync_reset(sync_reset),
													.clk(clk),
													.i_pins(i_pins),
													.nibble_ir(LS_nibble_ir),
													.i_sel(i_mux_select),
													.y_sel(y_reg_select),
													.x_sel(x_reg_select),
													.source_sel(source_select),
													.reg_en(reg_enables),
													.o_reg(o_reg),
													.dm(dm),
													.data_bus(data_bus),
													.i(data_mem_addr),
													.x0(x0),
													.x1(x1),
													.y0(y0),
													.y1(y1),
													.r(r),
													.m(m),
													.from_CU(from_CU),
													.r_eq_0(zero_flag));
	
	data_memory data_mem(					.clock(n_clk),
													.address(data_mem_addr),
													.data(data_bus),
													.wren(reg_enables[7]),
													.q(dm));
													
assign i = data_mem_addr;

endmodule
