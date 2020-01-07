/*
 * One hot encoding FSM of a set of traffic lights for a 4-way intersection
 */
module trafficLights (

	input clk, reset, debug, left_turn_request_d, NS_walk_request_d, WE_walk_request_d, emergency_mode,
	output [6:0] NB_trafficSegments, SB_trafficSegments, EB_trafficSegments, WB_trafficSegments,
	output [6:0] NB_walkSegments, SB_walkSegments, EB_walkSegments, WB_walkSegments,
	output reg left_turn_request, NS_walk_request, WE_walk_request
);

	reg [5:0] timer;
	reg state1w, state1fd, state1d, state1, state2, state3, state4, state4a, state4w, state4fd, state4d;
	reg state5, state6;
	
	reg state1w_d, state1fd_d, state1d_d, state1_d, state2_d, state3_d, state4_d, state4a_d; 
	reg state4w_d, state4fd_d, state4d_d, state5_d, state6_d;
	
	reg entering_state1w, entering_state1fd, entering_state1d, entering_state1, entering_state2;
	reg entering_state3, entering_state4, entering_state4a, entering_state4w, entering_state4fd;
	reg entering_state4d, entering_state5, entering_state6;
	
	reg staying_state1w, staying_state1fd, staying_state1d, staying_state1, staying_state2;
	reg staying_state3, staying_state4, staying_state4a, staying_state4w, staying_state4fd;
	reg staying_state4d, staying_state5, staying_state6;
	
	wire oneSec, halfSec;
	reg [2:0] NBLight, SBLight, EBLight, WBLight;
	
	reg [2:0] NB_walkLight, SB_walkLight, EB_walkLight, WB_walkLight;
	
	/* Timer control */
	always @(negedge reset or posedge clk)
			
		if(reset == 1'b0)
		
			timer = 6'd60;
			
		else if(entering_state1w)
		
			timer = 6'd10;
			
		else if(entering_state1fd)
		
			timer = 6'd20;
			
		else if(entering_state1d)
		
			timer = 6'd30;
			
		else if(entering_state1)
		
			timer = 6'd60;
			
		else if(entering_state2)
		
			timer = 6'd6;
			
		else if(entering_state3)
		
			timer = 6'd2;
			
		else if(entering_state4a)
		
			timer = 6'd20;
			
		else if(entering_state4)
		
			timer = 6'd60;
			
		else if(entering_state4w)
		
			timer = 6'd10;
			
		else if(entering_state4fd)
		
			timer = 6'd20;
			
		else if(entering_state4d)
		
			timer = 6'd30;
				
		else if(entering_state5)
		
			timer = 6'd6;
			
		else if(entering_state6)
		
			timer = 6'd2;
			
		else if(oneSec == 1'b1 && timer != 6'd1)
		
			if(emergency_mode && (state1 | state1d))
				/* Pause the timer */
				timer = timer;
				
			else
		
				timer = timer - 6'd1;
			
		else
		
			timer = timer;
			
	/* Advanced left turn detection. Would normally be some kind of inductive sensors under */
	/* the road that triggers when a car (large mass of metal) passes over the sensor. Here, */
	/* it is simulated as a key button press on the DEII. */
always @(posedge clk or negedge reset)
	
		if(reset == 1'b0)
			
			left_turn_request = 1'b0;
			
		/* KEY buttons are active low */
		else if(left_turn_request_d == 1'b0)
			
			left_turn_request = 1'b1;
		
		/* Don't need light request light on if we're in the advanced left turn state */
		else if(entering_state4a)
			
			left_turn_request = 1'b0;
				
		else
			
				left_turn_request = left_turn_request;
				
	/* North and South walk request detection. Triggered by key button presses on the DEII to */
	/* simulate a button press on the side walk */
	always @(posedge clk or negedge  reset)
	
		if(reset == 1'b0)
		
			NS_walk_request = 1'b0;
			
		else if(NS_walk_request_d == 1'b0)
		
			NS_walk_request = 1'b1;
			
		else if(entering_state4w)
		
			NS_walk_request = 1'b0;
			
		else
		
			NS_walk_request = NS_walk_request;
			
	/* East and West walk request detection */
	always @(posedge clk or negedge  reset)
	
		if(reset == 1'b0)
		
			WE_walk_request = 1'b0;
			
		else if(WE_walk_request_d == 1'b0)
		
			WE_walk_request = 1'b1;
			
		else if(entering_state1w)
		
			WE_walk_request = 1'b0;
			
		else
		
			WE_walk_request = WE_walk_request;
					
	/*
	 * ***************************************************************State1w DFF
	 */
	 always @(posedge clk or negedge reset)
	 
		if(reset == 1'b0)
		
			state1w = 1'b0;
			
		else
		
			state1w = state1w_d;
			
	/* Logic for entering state1w */
	always @ *
	
		if(state6 == 1'b1 && timer == 6'd1 && WE_walk_request == 1'b1)
		
			entering_state1w = 1'b1;
			
		else
		
			entering_state1w = 1'b0;
			
	/* Logic for staying in state1w */
	always @ *
	
		if(state1w == 1'b1 && timer != 6'd1 && reset != 1'b0)
		
			staying_state1w = 1'b1;
			
		else
		
			staying_state1w = 1'b0;
			
	/* State 1w d input */
	always @ *
	
		if(entering_state1w)
		
			state1w_d = 1'b1;
			
		else if(staying_state1w)
		
			state1w_d = 1'b1;
			
		else
		
			state1w_d = 1'b0;
			
	/*
	 * **************************************************************State1fd DFF
	 */
	 always @(posedge clk or negedge reset)
	 
		if(reset == 1'b0)
		
			state1fd = 1'b0;
			
		else
		
			state1fd = state1fd_d;
			
	/* Logic for entering state1fd */
	always @ *
	
		if(state1w == 1'b1 && timer == 6'd1 && reset != 1'b0)
		
			entering_state1fd = 1'b1;
			
		else
		
			entering_state1fd = 1'b0;
			
	/* Logic for staying in state1fd */
	always @ *
	
		if(state1fd == 1'b1 && timer != 6'd1 && reset != 1'b0)
		
			staying_state1fd = 1'b1;
			
		else
		
			staying_state1fd = 1'b0;
			
	/* State 1fd d input */
	always @ *
	
		if(entering_state1fd)
		
			state1fd_d = 1'b1;
			
		else if(staying_state1fd)
		
			state1fd_d = 1'b1;
			
		else
		
			state1fd_d = 1'b0;
			
	/*
	 * ************************************************************State1d DFF
	 */
	 always @(posedge clk or negedge reset)
	 
		if(reset == 1'b0)
		
			state1d = 1'b0;
			
		else
		
			state1d = state1d_d;
			
	/* Logic for entering state1d */
	always @ *
	
		if(state1fd == 1'b1 && timer == 6'd1 && reset != 1'b0)
		
			entering_state1d = 1'b1;
			
		else
		
			entering_state1d = 1'b0;
			
	/* Logic for staying in state1d */
	always @ *
	
		if((state1d == 1'b1 && timer != 6'd1 && reset != 1'b0) || (emergency_mode && state1d && reset != 1'b0))
		
			staying_state1d = 1'b1;
			
		else
		
			staying_state1d = 1'b0;
			
	/* State 1d d input */
	always @ *
	
		if(entering_state1d)
		
			state1d_d = 1'b1;
			
		else if(staying_state1d)
		
			state1d_d = 1'b1;
			
		else
		
			state1d_d = 1'b0;
	
	/*
	 * ************************************************************State1 DFF
	 */
	 always @(posedge clk or negedge reset)
	 
		if(reset == 1'b0)
		
			state1 = 1'b1;
			
		else
		
			state1 = state1_d;
		
	/* Logic for entering state 1 */
	always @ *
	
		if((state6 == 1'b1 && timer == 6'd1 && WE_walk_request != 1'b1) || (reset == 1'b0))
			
			entering_state1 = 1'b1;
		
		else
		
			entering_state1 = 1'b0;
		
	/* Logic for staying in state 1 */
	always @ *
	
		if((state1 == 1'b1 && timer != 6'd1)  || emergency_mode && state1)
		
			staying_state1 = 1'b1;
			
		else
		
			staying_state1 = 1'b0;
			
	/* State 1 d input */
	always @ *
	
		if(entering_state1 == 1'b1)
		
			state1_d = 1'b1;
			
		else if(staying_state1 == 1'b1)
		
			state1_d = 1'b1;
			
		/* Not in state 1 */	
		else
		
			state1_d = 1'b0;
			
	/*
	 * ************************************************************State2 DFF
	 */
	always @(posedge clk or negedge reset)
	
		if(reset == 1'b0)
		
			state2 = 1'b0;
			
		else
		
			state2 = state2_d;
			
	/* Logic for entering state 2 */
	always @ *
		
		if((state1 == 1'b1 || state1d == 1'b1) && timer == 6'd1 && reset != 1'b0)
			
			entering_state2 = 1'b1;
				
		else
			
			entering_state2 = 1'b0;
				
	/* Logic for staying in state 2 */
	always @ *
		
		if(state2 == 1'b1 && timer != 6'd1 && reset != 1'b0)
			
			staying_state2 = 1'b1;
				
		else
			
			staying_state2 = 1'b0;
				
	/* State 2 d input */
	always @ *
			
		if(entering_state2)
			
			state2_d = 1'b1;
				
		else if(staying_state2)
			
			state2_d = 1'b1;
				
		/* Not in state 2 */	
		else
			
			state2_d = 1'b0;	
		 
	/*
	 * ************************************************************State3 DFF
	 */
	always @(posedge clk or negedge reset)
	
	if(reset == 1'b0)
		
		state3 = 1'b0;
			
	else
		
		state3 = state3_d;
			
	/* Logic for entering state 3 */
	always @ *
		
		if(state2 == 1'b1 && timer == 6'd1 && reset != 1'b0)
			
			entering_state3 = 1'b1;
				
		else
			
			entering_state3 = 1'b0;
				
	/* Logic for staying in state 3 */
	always @ *
		
		if(state3 == 1'b1 && timer != 6'd1 && reset != 1'b0)
			
			staying_state3 = 1'b1;
				
		else
			
			staying_state3 = 1'b0;
				
	/* State 3 d input */
	always @ *
			
		if(entering_state3)
			
			state3_d = 1'b1;
				
		else if(staying_state3)
			
			state3_d = 1'b1;
				
		/* Not in state 3 */	
		else
			
			state3_d = 1'b0;
		
	/*
	 * *************************************************************State4a DFF
	 */
	 always @(posedge clk or negedge reset)
	 
		if(reset == 1'b0)
		
			state4a = 1'b0;
			
		else
		
			state4a = state4a_d;
		
	/* Logic for entering state 4a*/	
	always @ *
	
		if(left_turn_request == 1'b1 && reset != 1'b0 && timer == 6'd1 && state3 == 1'b1)
		
			entering_state4a = 1'b1;
			
		else
		
			entering_state4a = 1'b0;
			
	/* Logic for staying in state 4a */		
	always @ *
	
		if(timer != 6'd1 && state4a == 1'b1 && reset != 1'b0)
		
			staying_state4a = 1'b1;
			
		else
		
			staying_state4a = 1'b0;
			
	/* state4a d input */
		always @ *
		
			if(entering_state4a)
			
				state4a_d = 1'b1;
				
			else if(staying_state4a)
			
				state4a_d = 1'b1;
				
			/* not in state 4a */
			else
			
				state4a_d = 1'b0;
		  
	/*
	 * ************************************************************State4 DFF
	 */
	always @(posedge clk or negedge reset)
	
		if(reset == 1'b0)
		
			state4 = 1'b0;
			
		else
		
			state4 = state4_d;
			
	/* Logic for entering state 4 */
	always @ *
		
		if((state3 == 1'b1 || state4a == 1'b1) && timer == 6'd1 && reset != 1'b0 && left_turn_request != 1'b1 && NS_walk_request != 1'b1)
			
			entering_state4 = 1'b1;
				
		else
			
			entering_state4 = 1'b0;
				
	/* Logic for staying in state 4 */
	always @ *
		
		if(state4 == 1'b1 && timer != 6'd1 && reset != 1'b0)
			
			staying_state4 = 1'b1;
				
		else
			
			staying_state4 = 1'b0;
				
	/* State 4 d input */
	always @ *
			
		if(entering_state4)
			
			state4_d = 1'b1;
				
		else if(staying_state4)
			
			state4_d = 1'b1;
				
		/* Not in state 4 */	
		else
			
			state4_d = 1'b0;
			
	/*
	 * ************************************************************State4w DFF
	 */
	always @(posedge clk or negedge reset)
	
		if(reset == 1'b0)
		
			state4w = 1'b0;
			
		else
		
			state4w = state4w_d;
			
	/* Logic for entering state 4w */
	always @ *
		
		if((state3 == 1'b1 || state4a == 1'b1) && timer == 6'd1 && reset != 1'b0 && left_turn_request != 1'b1 && NS_walk_request == 1'b1)
			
			entering_state4w = 1'b1;
				
		else
			
			entering_state4w = 1'b0;
				
	/* Logic for staying in state 4w */
	always @ *
		
		if(state4w == 1'b1 && timer != 6'd1 && reset != 1'b0)
			
			staying_state4w = 1'b1;
				
		else
			
			staying_state4w = 1'b0;
				
	/* State 4w d input */
	always @ *
			
		if(entering_state4w)
			
			state4w_d = 1'b1;
				
		else if(staying_state4w)
			
			state4w_d = 1'b1;
				
		/* Not in state 4 */	
		else
			
			state4w_d = 1'b0;	
			
	/*
	 * ************************************************************State4fd DFF
	 */
	always @(posedge clk or negedge reset)
	
		if(reset == 1'b0)
		
			state4fd = 1'b0;
			
		else
		
			state4fd = state4fd_d;
			
	/* Logic for entering state4 fd */
	always @ *
		
		if(state4w == 1'b1 && timer == 6'd1 && reset != 1'b0)
			
			entering_state4fd = 1'b1;
				
		else
			
			entering_state4fd = 1'b0;
				
	/* Logic for staying in state 4w */
	always @ *
		
		if(state4fd == 1'b1 && timer != 6'd1 && reset != 1'b0)
			
			staying_state4fd = 1'b1;
				
		else
			
			staying_state4fd = 1'b0;
				
	/* State 4w d input */
	always @ *
			
		if(entering_state4fd)
			
			state4fd_d = 1'b1;
				
		else if(staying_state4fd)
			
			state4fd_d = 1'b1;
				
		/* Not in state 4 */	
		else
			
			state4fd_d = 1'b0;
		
	/*
	 * ************************************************************State4d DFF
	 */
	always @(posedge clk or negedge reset)
	
		if(reset == 1'b0)
		
			state4d = 1'b0;
			
		else
		
			state4d = state4d_d;
			
	/* Logic for entering state4d */
	always @ *
		
		if(state4fd == 1'b1 && timer == 6'd1 && reset != 1'b0)
			
			entering_state4d = 1'b1;
				
		else
			
			entering_state4d = 1'b0;
				
	/* Logic for staying in state 4w */
	always @ *
		
		if(state4d == 1'b1 && timer != 6'd1 && reset != 1'b0)
			
			staying_state4d = 1'b1;
				
		else
			
			staying_state4d = 1'b0;
				
	/* State 4w d input */
	always @ *
			
		if(entering_state4d)
			
			state4d_d = 1'b1;
				
		else if(staying_state4d)
			
			state4d_d = 1'b1;
				
		/* Not in state 4 */	
		else
			
			state4d_d = 1'b0;		
			
	/*
	 * ************************************************************State 5 DFF
	 */
	always @(posedge clk or negedge reset)
	
		if(reset == 1'b0)
		
			state5 = 1'b0;
			
		else
		
			state5 = state5_d;
			
	/* Logic for entering state 5 */
	always @ *
		
		if((state4 == 1'b1 || state4d == 1'b1) && timer == 6'd1 && reset != 1'b0)
			
			entering_state5 = 1'b1;
				
		else
			
			entering_state5 = 1'b0;
				
	/* Logic for staying in state 5 */
	always @ *
		
		if(state5 == 1'b1 && timer != 6'd1 && reset != 1'b0)
			
			staying_state5 = 1'b1;
				
		else
			
			staying_state5 = 1'b0;
				
	/* State 5 d input */
	always @ *
			
		if(entering_state5)
			
			state5_d = 1'b1;
				
		else if(staying_state5)
			
			state5_d = 1'b1;
				
		/* Not in state 5 */	
		else
			
			state5_d = 1'b0;		 
		 
	/*
	 * ************************************************************State 6 DFF
	 */
	always @(posedge clk or negedge reset)
	
		if(reset == 1'b0)
		
			state6 = 1'b0;
			
		else
		
			state6 = state6_d;
			
	/* Logic for entering state 6 */
	always @ *
		
		if(state5 == 1'b1 && timer == 6'd1 && reset != 1'b0)
			
			entering_state6 = 1'b1;
				
		else
			
			entering_state6 = 1'b0;
				
	/* Logic for staying in state 6 */
	always @ *
		
		if(state6 == 1'b1 && timer != 6'd1 && reset != 1'b0)
			
			staying_state6 = 1'b1;
				
		else
			
			staying_state6 = 1'b0;
				
	/* State 6 d input */
	always @ *
			
		if(entering_state6)
			
			state6_d = 1'b1;
				
		else if(staying_state6)
			
			state6_d = 1'b1;
				
		/* Not in state 6 */	
		else
			
			state6_d = 1'b0;			  
		  
	/*
	 * ************************************************************Ouput logic
	 */
	always @ *
	
		if(state1) begin
		
			NBLight = 3'b100;
			SBLight = 3'b100;
			EBLight = 3'b001;
			WBLight = 3'b001;
			NB_walkLight = 3'b011;
			SB_walkLight = 3'b011;
			EB_walkLight = 3'b011;
			WB_walkLight = 3'b011;
		end
		
		else if(state1w) begin
		
			NBLight = 3'b100;
			SBLight = 3'b100;
			EBLight = 3'b001;
			WBLight = 3'b001;
			NB_walkLight = 3'b011;
			SB_walkLight = 3'b011;
			EB_walkLight = 3'b110;
			WB_walkLight = 3'b110;
		end
		
		
		else if(state1fd) begin
		
			NBLight = 3'b100;
			SBLight = 3'b100;
			EBLight = 3'b001;
			WBLight = 3'b001;
			NB_walkLight = 3'b011;
			SB_walkLight = 3'b011;
			EB_walkLight = 3'b111;
			WB_walkLight = 3'b111;
		end
		
		
		else if(state1d) begin
		
			NBLight = 3'b100;
			SBLight = 3'b100;
			EBLight = 3'b001;
			WBLight = 3'b001;
			NB_walkLight = 3'b011;
			SB_walkLight = 3'b011;
			EB_walkLight = 3'b011;
			WB_walkLight = 3'b011;
		end
		
		else if(state2) begin
		
			NBLight = 3'b100;
			SBLight = 3'b100;
			EBLight = 3'b010;
			WBLight = 3'b010;
			NB_walkLight = 3'b011;
			SB_walkLight = 3'b011;
			EB_walkLight = 3'b011;
			WB_walkLight = 3'b011;
		end
		
		else if(state3) begin
		
			NBLight = 3'b100;
			SBLight = 3'b100;
			EBLight = 3'b100;
			WBLight = 3'b100;
			NB_walkLight = 3'b011;
			SB_walkLight = 3'b011;
			EB_walkLight = 3'b011;
			WB_walkLight = 3'b011;
		end
		
		else if(state4) begin
		
			NBLight = 3'b001;
			SBLight = 3'b001;
			EBLight = 3'b100;
			WBLight = 3'b100;
			NB_walkLight = 3'b011;
			SB_walkLight = 3'b011;
			EB_walkLight = 3'b011;
			WB_walkLight = 3'b011;
		end
		
		else if(state4a) begin
		
			NBLight = 3'b100;
			SBLight = 3'b101; /* Advanced left turn arrow */
			EBLight = 3'b100;
			WBLight = 3'b100;
			NB_walkLight = 3'b011;
			SB_walkLight = 3'b011;
			EB_walkLight = 3'b011;
			WB_walkLight = 3'b011;
		end
		
		else if(state4w) begin
		
			NBLight = 3'b001;
			SBLight = 3'b001;
			EBLight = 3'b100;
			WBLight = 3'b100;
			NB_walkLight = 3'b110;
			SB_walkLight = 3'b110;
			EB_walkLight = 3'b011;
			WB_walkLight = 3'b011;
		end
		
		else if(state4fd) begin
		
			NBLight = 3'b001;
			SBLight = 3'b001;
			EBLight = 3'b100;
			WBLight = 3'b100;
			NB_walkLight = 3'b111;
			SB_walkLight = 3'b111;
			EB_walkLight = 3'b011;
			WB_walkLight = 3'b011;
		end
		
		else if(state4d) begin
		
			NBLight = 3'b001;
			SBLight = 3'b001;
			EBLight = 3'b100;
			WBLight = 3'b100;
			NB_walkLight = 3'b011;
			SB_walkLight = 3'b011;
			EB_walkLight = 3'b011;
			WB_walkLight = 3'b011;
		end
		
		else if(state5) begin
		
			NBLight = 3'b010;
			SBLight = 3'b010;
			EBLight = 3'b100;
			WBLight = 3'b100;
			NB_walkLight = 3'b011;
			SB_walkLight = 3'b011;
			EB_walkLight = 3'b011;
			WB_walkLight = 3'b011;
		end
		
		else if(state6) begin
	
			NBLight = 3'b100;
			SBLight = 3'b100;
			EBLight = 3'b100;
			WBLight = 3'b100;
			NB_walkLight = 3'b011;
			SB_walkLight = 3'b011;
			EB_walkLight = 3'b011;
			WB_walkLight = 3'b011;
		end
	
	/* Invalid state */ 	
	else begin
	
			NBLight = 3'b000;
			SBLight = 3'b000;
			EBLight = 3'b000;
			WBLight = 3'b000;
			NB_walkLight = 3'b000;
			SB_walkLight = 3'b000;
			EB_walkLight = 3'b000;
			WB_walkLight = 3'b000;
	end
	
/* Sub-circuits */			
timer T(.clk(clk), .reset(reset), .debug(debug), .oneSec(oneSec), .halfSec(halfSec));

lightDriver NBT(.light(NBLight), .lightSegment(NB_trafficSegments), .halfSec(halfSec));
lightDriver SBT(.light(SBLight), .lightSegment(SB_trafficSegments), .halfSec(halfSec));
lightDriver EBT(.light(EBLight), .lightSegment(EB_trafficSegments), .halfSec(halfSec));
lightDriver WBT(.light(WBLight), .lightSegment(WB_trafficSegments), .halfSec(halfSec));

lightDriver NBW(.light(NB_walkLight), .lightSegment(NB_walkSegments), .halfSec(halfSec));
lightDriver SBW(.light(SB_walkLight), .lightSegment(SB_walkSegments), .halfSec(halfSec));
lightDriver EBW(.light(EB_walkLight), .lightSegment(EB_walkSegments), .halfSec(halfSec));
lightDriver WBW(.light(WB_walkLight), .lightSegment(WB_walkSegments), .halfSec(halfSec));		

endmodule
