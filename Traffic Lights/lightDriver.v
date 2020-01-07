module lightDriver (

	input [2:0] light,
	input halfSec,
	output reg [6:0] lightSegment
);

reg flash;

always @(posedge halfSec)

	flash = ~flash;
	
always @ * begin

	case(light)
	
		3'b001:	lightSegment = 7'b1110111; /* green */	
		
		3'b010:	lightSegment = 7'b0111111; /* amber */
		
		3'b100: 	lightSegment = 7'b1111110; /* red */
		
		3'b101:	lightSegment = 7'b0111001; /* Advanced left turn arrow */
		
		3'b110:	lightSegment = 7'b1011111; /* Walk light */
		
		3'b011:	lightSegment = 7'b0100001;	/* don't walk */
		
		3'b111:	if(flash)	lightSegment = 7'b0100001;
					else			lightSegment = 7'b1111111; /* flashing don't walk */
		
		default: lightSegment = 7'b0000000; /* something went wrong */
		
	endcase
	
end
	
endmodule
