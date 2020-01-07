module program_sequencer(

	input clk, sync_reset, jmp, jmp_nz, dont_jmp,
	input [3:0] jmp_addr,
	input [7:0] pm_address,
	output reg [7:0] pm_addr,
	output reg [7:0] pc,
	output reg [7:0] from_PS
);

reg [7:0] pc_out;
	
/* Program Counter */
/* Holds the address of origin of the current instruction in the */
/* instruction register */
always @(posedge clk)

	pc_out = pm_addr;
	
always

	pc = pc_out;
	
always

	from_PS = 8'H00;

always @ *
	
	if(sync_reset == 1'b1)
		
		pm_addr = 8'b0;
			
	else if(jmp == 1'b1)
		
		pm_addr = {jmp_addr, 4'H0};
			
	else if((jmp_nz == 1'b1) && (dont_jmp == 1'b0))
		
		pm_addr = {jmp_addr, 4'H0};
			
	else
		
		pm_addr = pc_out + 8'b1;
		
endmodule
