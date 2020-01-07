/* Card lock reader for hotel guests. The function of maid cards exactly */
/* parallels that of guest cards. The only difference is the number on */
/* the card and therefore the next combination */
module electronic_card_lock(

	input clk, /* for debugging with signal tap */
	input wire key_0, key_1,
	/* 16 digit entry code that is programmed onto each card */
	input wire [15:0] entry_code_on_card,
	/* 4 different card types for guests and maids. */
	input wire [1:0] card_type,
	/*
	 * 00 = guest card
	 * 01 = maid card
	 * 10 = guest reset card
	 * 11 = maid reset card
	 */
	output reg card_read,
	output reg trip_lock_for_guest,
	output reg trip_lock_for_maid
);

reg [15:0] current_guest_combination, current_maid_combination;
reg [15:0] next_guest_combination, next_maid_combination;
reg [17:0] card_number;
wire guest_feedback, guest_tap, maid_feedback, maid_tap;

/* card read enable. Can not read cards while card read is logic low */
always @ *

	if(~key_0)
	
		card_read = 1'b0;
		
	else if(~key_1)
	
		card_read = 1'b1;
		
	else
	
		card_read = card_read;
			
/* LSFR for guest cards. Generates the codes that need to be read from */
/* the card in order to unlock the door */
assign guest_tap = next_guest_combination[4];

/* Feedback network. */
assign guest_feedback = (next_guest_combination[15] ^ guest_tap ^ next_guest_combination[2] ^ next_guest_combination[1]);

/* Shift Network */
always @(posedge card_read)

	/* clear the lsfr if the guest reset card is inserted */
	if(card_type == 2'b10 && next_guest_combination != 16'H0000)
	
		next_guest_combination = 16'H0000;
		
	/* if the lsfr is in reset mode at the time a guest card is inserted, the lsfr is loaded */
	/* with the combination on the card on the positive edge of card_read and the lock trip */
	/* is turned on. See the first else if of guest lock control */	
	else if(card_type == 2'b00 && next_guest_combination == 16'H0000)
	
		next_guest_combination = entry_code_on_card;
		
	/* If a card is inserted that matches the next combination, then a new */
	/* guest has entered the room, and a new "next guest code" must be generated */
	else if(entry_code_on_card == next_guest_combination)
	
		next_guest_combination = {next_guest_combination[14:0], guest_feedback};
		
	/* The lock is in reset mode, and has taken the new guest combination. It's jabbed in a second time */
	/* to generate the next combination in the sequence */
	else if(card_type == 2'b00 && next_guest_combination == entry_code_on_card)
	
		next_guest_combination = {next_guest_combination[14:0], guest_feedback};
	
	else
	
		next_guest_combination = next_guest_combination;
		
/* guest lock control */
always @ *

	/* if the lsfr is in reset mode at the time a guest card is inserted, the lsfr is loaded */
	/* with the combination on the card on the positive edge of card_read and the lock trip */
	/* is turned on. See the first else if of the shift network. */
	if(card_type == 2'b00 && card_read && next_guest_combination == entry_code_on_card)
	
		trip_lock_for_guest = 1'b1;
		
	/* A guest is returning to the room */	
	else if(card_type == 2'b00 && entry_code_on_card == current_guest_combination && card_read)
	
		trip_lock_for_guest = 1'b1;
		
	/* Dumb hack to get my version to agree with the lab pre-amble. */
	/* Apparently there is not supposed to be a separate lock for the maids */		
	else if(trip_lock_for_maid == 1'b1)
	
		trip_lock_for_guest = 1'b1;
		
	else
	
		trip_lock_for_guest = 1'b0;
		
/* guest lock re-program */
always @(posedge card_read)

	if(card_type == 2'b00 && entry_code_on_card == next_guest_combination)
	
		current_guest_combination = entry_code_on_card;
		
	else
	
		current_guest_combination = current_guest_combination;
		
/* LSFR for maid cards. Generates the codes that need to be read from */
/* the card in order to unlock the door */
assign maid_tap = next_maid_combination[4];

/* Feedback network. */
assign maid_feedback = (next_maid_combination[15] ^ maid_tap ^ next_maid_combination[2] ^ next_maid_combination[1]);

/* Shift Network */
always @(posedge card_read)

	/* clear the lsfr if the maid reset card is inserted */
	if(card_type == 2'b11 && next_maid_combination != 16'H0000)
	
		next_maid_combination = 16'H0000;
		
	/* if the lsfr is in reset mode at the time a maid card is inserted, the lsfr is loaded */
	/* with the combination on the card on the positive edge of card_read and the lock trip */
	/* is turned on */	
	else if(card_type == 2'b01 && next_maid_combination == 16'H0000)
	
		next_maid_combination = entry_code_on_card;
		
	/* If a card is inserted that matches the next combination, then a new */
	/* maid has entered the room, and a new "next maid code" must be generated */
	else if(entry_code_on_card == next_maid_combination)
	
		next_maid_combination = {next_maid_combination[14:0], maid_feedback};
		
	/* The lock is in reset mode, and has taken the new maid combination. It's jabbed in a second time */
	/* to generate the next combination in the sequence */
	else if(card_type == 2'b01 && next_maid_combination == entry_code_on_card)
	
		next_maid_combination = {next_maid_combination[14:0], maid_feedback};
	
	else
	
		next_maid_combination = next_maid_combination;
		
/* maid lock control */
always @ *

	/* if the lsfr is in reset mode at the time maid card is inserted, the lsfr is loaded */
	/* with the combination on the card on the positive edge of card_read and the lock trip */
	/* is turned on */
	if(card_type == 2'b01 && card_read && next_maid_combination == entry_code_on_card)
	
		trip_lock_for_maid = 1'b1;
		
	/* A maid is returning to the room */	
	else if(card_type == 2'b01 && entry_code_on_card == current_maid_combination && card_read)
	
		trip_lock_for_maid = 1'b1;
		
	else
	
		trip_lock_for_maid = 1'b0;
		
/* maid lock re-program */
always @(posedge card_read)

	if(card_type == 2'b01 && entry_code_on_card == next_maid_combination)
	
		current_maid_combination = entry_code_on_card;
		
	else
	
		current_maid_combination = current_maid_combination;
		
/* card_reader */
always @(posedge card_read)

		if(next_guest_combination == 16'H0000 || next_maid_combination == 16'H0000)
		
			card_number = 18'H00000;
			
		else
		
			card_number = {card_type, entry_code_on_card};
		
endmodule
