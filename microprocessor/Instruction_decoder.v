module Instruction_decoder(

	input [7:0] next_instr,
	input sync_reset, clk,
	output reg jmp, jmp_nz, i_sel, y_sel, x_sel,
	output reg [3:0] ir_nibble, source_sel,
	output reg [8:0] reg_en,
	output reg [7:0] ir,
	output reg [7:0] from_ID,
	output reg NOPC8, NOPCF, NOPD8, NOPDF
);

/* Instruction register */
always @(posedge clk)

	ir = next_instr;
	
always

	ir_nibble = ir[3:0];
	
always

	from_ID = 8'H00;
	
always @ * begin

	if(ir == 8'HC8)
	
		NOPC8 = 1'b1;
		
	else
	
		NOPC8 = 1'b0;
		
	if(ir == 8'HCF)
	
		NOPCF = 1'b1;
		
	else
	
		NOPCF = 1'b0;
		
	if(ir == 8'HD8)
	
		NOPD8 = 1'b1;
		
	else
	
		NOPD8 = 1'b0;
		
	if(ir == 8'HDF)
	
		NOPDF = 1'b1;
		
	else
	
		NOPDF = 1'b0;
end
	
/* Note that syn_reset does not clear any registers. The instruction decoder */
/* just helps to set this up by making sure that all the registers are */
/* enabled for when the reset is aasserted */	

/* Logic for x0 reg enable */	
always @ *

	if(sync_reset == 1'b1)
	
		reg_en[0] = 1'b1;

	else if((ir[7] == 1'b0) && (ir[6:4] == 3'd0))
	
		reg_en[0] = 1'b1;
		
	else if((ir[7:6] == 2'b10) && (ir[5:3] == 3'd0))
	
		reg_en[0] = 1'b1;
		
	else
	
		reg_en[0] = 1'b0;
		
/* Logic for x1 reg enable */
always @ *

	if(sync_reset == 1'b1)
	
		reg_en[1] = 1'b1;

	else if((ir[7] == 1'b0) && (ir[6:4] == 3'd1))

		reg_en[1] = 1'b1;
		
	else if((ir[7:6] == 2'b10) && (ir[5:3] == 3'd1))
	
		reg_en[1] = 1'b1;
		
	else
	
		reg_en[1] = 1'b0;
		
/* Logic for y0 enable */
always @ *

	if(sync_reset == 1'b1)
	
		reg_en[2] = 1'b1;

	else if((ir[7] == 1'b0) && (ir[6:4] == 3'd2))
	
		reg_en[2] = 1'b1;
		
	else if((ir[7:6] == 2'b10) && (ir[5:3] == 3'd2))
	
		reg_en[2] = 1'b1;
		
	else
	
		reg_en[2] = 1'b0;
		
/* Logic for y1 reg enable */
always @ *

	if(sync_reset == 1'b1)
	
		reg_en[3] = 1'b1;

	else if((ir[7] == 1'b0) && (ir[6:4] == 3'd3))
	
		reg_en[3] = 1'b1;
		
	else if((ir[7:6] == 2'b10) && (ir[5:3] == 3'd3))
	
		reg_en[3] = 1'b1;
		
	else
	
		reg_en[3] = 1'b0;

/* Logic for o_reg enable */		
always @ *

	if(sync_reset == 1'b1)
	
		reg_en[8] = 1'b1;
		
	/* move instruction */
	else if(ir[7:4] == 4'b0100)
		
		reg_en[8] = 1'b1;
	/* Load instruction */
	else if(ir[7:3] == 5'b10100)
	
		reg_en[8] = 1'b1;
		
	else
	
		reg_en[8] = 1'b0;
	
/* Logic for r reg enable. r_reg is only enabled when there is an alu */
/* instruction */
always @ *

	if(sync_reset == 1'b1)
	
		reg_en[4] = 1'b1;
		
	else if(ir[7:5] == 3'b110)
	
		reg_en[4] = 1'b1;
		
	else
	
		reg_en[4] = 1'b0;
		
/* Logic for m reg enable */
always @ *

	if(sync_reset == 1'b1)
	
		reg_en[5] = 1'b1;

	else if((ir[7] == 1'b0) && (ir[6:4] == 3'd5))
	
		reg_en[5] = 1'b1;
		
	else if((ir[7:6] == 2'b10) && (ir[5:3] == 3'd5))
	
		reg_en[5] = 1'b1;
		
	else
	
		reg_en[5] = 1'b0;

/* Logic for i reg enable (the index regster) */
/* i is enabled when the i_reg is the destination, data memory is a */
/* desitnation or when data memory is a source. Otherwise it is disabled */
always @ *

	if(sync_reset == 1'b1)
		
		reg_en[6] = 1'b1;
	
	/* load w/ i or dm at dst */
	else if(ir[7:4] == 4'H6 || ir[7:4] == 4'H7)
	
		reg_en[6] = 1'b1;
		
	else if(ir[7:6] == 2'b10)
	
		/* mov w/ i at dst */
		if(ir[5:3] == 3'H6)
			
			reg_en[6] = 1'b1;
		
		/* mov w/ dm at dst */
		else if(ir[5:3] == 3'H7)
		
			reg_en[6] = 1'b1;
		
		/* mov w/ dm at src */
		else if(ir[2:0] == 3'H7)
		
			reg_en[6] = 1'b1;
			
		else
		
			reg_en[6] = 1'b0;
		
	else
	
		reg_en[6] = 1'b0;
		
/* Logic for dm reg enable. The i register is also enabled when dm is used */		
always @ *

	if(sync_reset == 1'b1)
	
		reg_en[7] = 1'b1;

	else if((ir[7] == 1'b0) && (ir[6:4] == 3'd7))
	
		reg_en[7] = 1'b1;
	
	else if((ir[7:6] == 2'b10) && (ir[5:3] == 3'd7))
	
		reg_en[7] = 1'b1;
		
	else
	
		reg_en[7] = 1'b0;


/*********************Logic for decoding source register**********************/

always @ *

	if(sync_reset)
	
	  source_sel = 4'd10;

	/* If there is a load instruction, select ir_nibble (pm_data) */
	else if(ir[7] == 1'b0)
	
		source_sel = 4'd8;

	/* Special case where src and dst are both 4'd4. Send r to o_reg */
	else if((ir[5:3] == 4'd4) && (ir[2:0] == 4'd4))
	
		source_sel = 4'd4;

	/* Special case when src and dst are the same. use i_pins as src */
	else if(ir[5:3] == ir[2:0])
	
		source_sel = 4'd9;

	else
	
		/* Made a choice to completely avoid the possibility of having beyond */
		/* 9 for a value on the mux. values from 10 to 15 will never happen here. */
		/* 10 is possible on reset */
		source_sel = {1'b0, ir[2:0]};
		
/************************* *Logic for decoding selects**************************/

/* i_sel */
/* Controls the auto increment of the i register on any load or move instruction */
/* where the dm register is in the source or destination field, except the move */
/* instructions where dm is the source and i is the destination */
always @ *

	if(sync_reset == 1'b1)

		i_sel = 1'b0;
	
	/* Do not increment when dm is the source and i is the destination */
	else if(ir == 8'b10110111)
	
		i_sel = 1'b0;
	
	/* increment when dm is the src or dst of a load */
	else if(ir[7:6] == 2'b10)
	
		if(ir[5:3] == 3'b111 || ir[2:0] == 3'b111)
			i_sel = 1'b1;	
		else
			i_sel = 1'b0;
			
	/* dm is the dst of a mov */
	else if(ir[7] == 1'b0)
	
		if(ir[6:4] == 3'b111)
			i_sel = 1'b1;
		else
			i_sel = 1'b0;
			
	else
	
		i_sel = 1'b0;
		
		
always @ *		
/* x_sel */
	if(sync_reset == 1'b1)
	
		x_sel = 1'b0;
		
	/* ALU instruction */	
	else if(ir[7:5] == 3'b110)
	
		if(ir[4] == 1'b0)
			
			x_sel = 1'b0;
			
		else
		
			x_sel = 1'b1;
			
	else
	
		x_sel = x_sel;
		
always @ *
/* y_sel */
	if(sync_reset == 1'b1)
	
		y_sel = 1'b0;
		
	else if(ir[7:5] == 3'b110)
	
		/* y_sel must be 0 for ones and 2's compliment functions */
		if(ir[2:0] == 3'b000 || ir[2:0] == 3'b111)
		
			y_sel = 1'b0;
			
		else if(ir[3] == 1'b1)
		
			y_sel = 1'b1;
			
		else
		
			y_sel = 1'b0;
			
	else

		y_sel = y_sel;
		
/**********************Logic for decoding instruction type**********************/
/* jmp */
always @ *

	if(sync_reset == 1'b1)
	
	  jmp = 1'b0;

	else if(ir[7:4] == 4'b1110)
	
		jmp = 1'b1;
		
	else
	
		jmp = 1'b0;
		
/* jmp_nz (cond. jump)*/
always @ *

	if(sync_reset == 1'b1)
	
	  jmp_nz = 1'b0;

	else if(ir[7:4] == 4'b1111)
	
		jmp_nz = 1'b1;
		
	else
	
		jmp_nz = 1'b0;
	
endmodule