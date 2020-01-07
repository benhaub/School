module Computational_unit(

	input sync_reset, clk, i_sel, y_sel, x_sel,
	input [3:0] nibble_ir, source_sel, i_pins, dm,
	input [8:0] reg_en,
	output reg [3:0] o_reg, data_bus, i,
	output reg r_eq_0,
	output reg [3:0] x0, x1, y0, y1, r, m,
	output reg [7:0] from_CU,
	output reg zero_flag
);

reg alu_out_eq_0;
reg [3:0] x, y, alu_out, i_d;
/* ms and ls for most and least significant */
reg [7:0] alu_ms, alu_ls;

/* 16 to 1 mux */
always @ *

	case(source_sel)
	
		4'H00:	data_bus = x0;
		4'H01:	data_bus = x1;
		4'H02:	data_bus = y0;
		4'H03:	data_bus = y1;
		4'H04:	data_bus = r;
		4'H05:	data_bus = m;
		4'H06:	data_bus = i;
		4'H07:	data_bus = dm;
		4'H08:	data_bus = nibble_ir;
		4'H9:		data_bus = i_pins;
		default:	data_bus = 4'H00; /* For values of 4'H10 or higher */
		
	endcase
	
always

	from_CU = 8'H00;
	
always

	zero_flag = alu_out_eq_0;

/* x0 register */
always @(posedge clk)

	if(reg_en[0])
	
		x0 = data_bus;
		
	else
	
		x0 = x0;
		
/* x1 register */
always @(posedge clk)

	if(reg_en[1])
	
		x1 = data_bus;
		
	else
	
		x1 = x1;
		
/* x_sel mux */
always @ *

	if(x_sel)
	
		x = x1;
		
	else /*(~x_sel)*/
	
		x = x0;
		
/* y0 register */
always @(posedge clk)

	if(reg_en[2])
	
		y0 = data_bus;
		
	else
	
		y0 = y0;
		
/* y1 register */
always @(posedge clk)

	if(reg_en[3])
	
		y1 = data_bus;
		
	else
	
		y1 = y1;
		
/* y_sel mux */
always @ *

	if(y_sel)
	
		y = y1;
		
	else
	
		y = y0;

/* result register */
always @(posedge clk)

	if(reg_en[4])
	
		r = alu_out;
		
	else
	
		r = r;

/* zero_flag register */
always @(posedge clk)

	if(reg_en[4])
	
		r_eq_0 = alu_out_eq_0;
		
	else
	
		r_eq_0 = r_eq_0;
		
/* m register */
always @(posedge clk)

	if(reg_en[5])
	
		m = data_bus;
		
	else
	
		m = m;
		
/* i_sel mux */
always @ *

	if(i_sel)
	
		i_d = m + i;
		
	else /*(~i_sel) */
	
		i_d = data_bus;
		
/* index register */
always @(posedge clk)

	if(reg_en[6])
	
		i = i_d;
		
	else
	
		i = i;
		
/* output register */
always @(posedge clk)

	if(reg_en[8])
	
		o_reg = data_bus;
		
	else
	
		o_reg = o_reg;
		
/* ALU */
always @ *

	if(sync_reset)
	
		alu_out = 4'H0;
	
	/* 2's compliment. y_sel must be 0 for this op */
	else if(reg_en[4] && nibble_ir[3:0] == 4'b0000)
	
		alu_out = (~x + 1'b1);
		
	/* no-op. y_sel must be 1 for this op */
	else if(reg_en[4] && nibble_ir[3:0] == 4'b1000)
	
		alu_out = r;
	
	else if(reg_en[4] && nibble_ir[2:0] == 3'b001)
	
		alu_out = x - y;
		
	else if(reg_en[4] && nibble_ir[2:0] == 3'b010)
	
		alu_out = x + y;
		
	else if(reg_en[4] && nibble_ir[2:0] == 3'b011) begin
	
		alu_ms = x * y;
		alu_out = alu_ms[7:4];
	end
		
	else if(reg_en[4] && nibble_ir[2:0] == 3'b100) begin
	
		alu_ls = x * y; /* TODO: Could put these in separate always @ * */
		alu_out = alu_ls[3:0];
	end
		
	else if(reg_en[4] && nibble_ir[2:0] == 3'b101)

		alu_out = x ^ y;
		
	else if(reg_en[4] && nibble_ir[2:0] == 3'b110)
	
		alu_out = x & y;
		
	else if(reg_en[4] && nibble_ir[3:0] == 4'b0111)
	
		alu_out = ~x;
		
	/* no-op. y must be 1 for this op */	
	else if(reg_en[4] && nibble_ir[3:0] == 4'b1111)
	
		alu_out = r;
		
	else
	
		alu_out = r;
	
/* ALU - zero flag control */
always @ * /* TODO: Should be an active high flip-flop */

	if(sync_reset)
	
		alu_out_eq_0 = 1'b1;
		
	/* no-op */
	else if (nibble_ir[3:0] == 4'h8 || nibble_ir[3:0] == 4'hF)
		alu_out_eq_0 = r_eq_0;
		
	/* We don't compare to r here because the zero-flag is written at the same */
	/* time as the result register */
	else if (alu_out == 4'h0)
	
		alu_out_eq_0 = 1'b1;
		
	else
	
		alu_out_eq_0 = 1'b0;
		
endmodule
