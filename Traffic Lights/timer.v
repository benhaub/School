/*
 * This is a 1Hz timer made using the on board 27MHz DEII clock. The output
 * oneSec is logic high whenever 1 second has gone by
 */
module timer(

	input clk,
	input reset,
	input debug,
	output reg oneSec,
	output reg halfSec
);

reg [24:0] timeCounter;
 /* One second on 27MHz clock is 27 million */
 `define SECOND 25'd27000000
 `define TENTH_SECOND 25'd2700000
 `define HALF_SECOND 25'd13500000
 
 /*
 * flip-flop to convert the 27MHz clock into a 1Hz clock. For purposes 
 * of testing, the clock can be sped up by a factor of 10 when the debug
 * switch is on
 */
always @(posedge clk)

	if(reset == 1'b0)
		
		timeCounter = 25'd0;
	
	else if(timeCounter == `SECOND)
	
		timeCounter = 25'd0;
		
	/* increase oneSec frequency to 10Hz */
	else if(debug == 1'b1 && timeCounter == `TENTH_SECOND)
		
		timeCounter = 25'd0;
		
	else
	
		timeCounter = timeCounter + 25'd1;
		
/*
 * combinational circuitry to test the output
 */
always @ *

		if(reset == 1'b0)
		
			oneSec = 1'b0;
		
		else if(timeCounter == `SECOND)
	
			oneSec = 1'b1;
			
		else if(timeCounter == `TENTH_SECOND && debug == 1'b1)
		
			oneSec = 1'b1;
			
		else
		
			oneSec = 1'b0;
			
always @ *

	if(reset == 1'b0)
	
		halfSec = 1'b0;
		
	else if(timeCounter == `HALF_SECOND || timeCounter == `SECOND)
	
		halfSec = 1'b1;
		
	else
	
		halfSec = 1'b0;
			
endmodule