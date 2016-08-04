module project_top
	(
		CLOCK_50,                    	//	On Board 50 MHz
		// Your inputs and outputs here
		KEY,
		HEX0,
		HEX1,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,                       	//	VGA Clock
		VGA_HS,                        	//	VGA H_SYNC
		VGA_VS,                        	//	VGA V_SYNC
		VGA_BLANK_N,                    	//	VGA BLANK
		VGA_SYNC_N,                    	//	VGA SYNC
		VGA_R,                       	//	VGA Red[9:0]
		VGA_G,                         	//	VGA Green[9:0]
		VGA_B                       	//	VGA Blue[9:0]
	);



	// *** DECLARE INPUTS AND OUTPUTS ***

	input CLOCK_50;            	//	50 MHz
	input [3:0] KEY;

	// VGA signals
	// Do not change the following outputs
	output        	VGA_CLK;               	//	VGA Clock
	output        	VGA_HS;                	//	VGA H_SYNC
	output        	VGA_VS;                	//	VGA V_SYNC
	output        	VGA_BLANK_N;            	//	VGA BLANK
	output        	VGA_SYNC_N;            	//	VGA SYNC
	output	[9:0]	VGA_R;               	//	VGA Red[9:0]
	output	[9:0]	VGA_G;                 	//	VGA Green[9:0]
	output	[9:0]	VGA_B;               	//	VGA Blue[9:0]



	// *** DECLARE WIRES AND REGISTERS *** 

	// reset button for VGA
	wire resetn;
	assign resetn = KEY[0];

	// reset button for modules
	wire reset_n;
	assign reset_n = KEY[1];

	// manual clock
	// for testing purposes only
	// wire man_clk;
	// assign man_clk = KEY[2];

	// hit button
	wire hit;
	assign hit = KEY[3];

	// colour, x, y and writeEn wires that are inputs to VGA
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	// states and delays
	reg [2:0] counter = 3'b000;
	reg [2:0] state_f = 3'b000;
	reg [2:0] state_g = 3'b000;
	reg [11:0] delay = 0;
	reg [8:0] delay2 = 0;

	// score
	wire [7:0] score_;
	reg [7:0] score;
	assign score_ = 8'b00000000 + score;

	// garbage position variable and wire used for rng
	// 0-3: garbage position, 3'b111: currently no garbage
	reg [2:0] garb = 3'b111;
	wire [4:0] rng;



	// *** INSTANTIATE MODULES ***

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
		.resetn(resetn),
		.clock(CLOCK_50),
		.colour(colour),
		.x(x),
		.y(y),
		.plot(writeEn),
		/* Signals for the DAC to drive the monitor. */
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B),
		.VGA_HS(VGA_HS),
		.VGA_VS(VGA_VS),
		.VGA_BLANK(VGA_BLANK_N),
		.VGA_SYNC(VGA_SYNC_N),
		.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";

	// rateDivider
	wire [27:0] timer;
	wire enable;
	assign timer = 100000000;
	rateDivider RD(timer, CLOCK_50, enable);

	// hex decoders for score display
	output [6:0] HEX0;
	output [6:0] HEX1;
	hex_decoder h0(score[3:0], HEX0);
	// hex_decoder h1(score[7:4], HEX1);
	// for testing purposes only
	hex_decoder h2({1'b0,counter},HEX1);

	// drawer
	reg item, erase;
	reg [2:0] position;
	wire item_, erase_;
	wire [2:0] position_;
	assign item_ = item;
	assign erase_ = erase;
	assign position_ = position;
	draw d0(CLOCK_50, reset_n, item_, erase_, position_, x, y, colour, writeEn);

	// random number generator
	random r0(CLOCK_50, reset_n, rng);



	// *** COUNTERs AND FSMs ***

	// counter for press movement
	always@(posedge enable) begin
		// move press back and forth
		if (counter == 3'b101) 
			counter <= 3'b000;
		else 
			counter <= counter + 1'b1;	 
	end

	// FSMs the game
	always@(posedge CLOCK_50 or posedge enable) begin

		// enable signal
		if (enable) begin

			// reset the FSM
			state_f <= 3'b000;

			// generate a garbage if there is currently none
			if (garb == 3'b111) 
				garb <= 3'b000 + rng[1:0];

		end    // end of enable signal

		// CLOCK_50 signal
		else begin

			// reset FSM, delays and garbage.
			if (!reset_n) begin
				state_f <= 3'b000;
				delay <= 0;
				delay2 <= 0;
				garb <= 3'b111;
			end

			// reset score
			// reset with the VGA, not with other modules
			else if (!resetn) begin
				score <= 8'b00000000;
				state_g <= 3'b000;
			end

			// if no reset signal is low
			else begin 
				
								
				// hit detection and adding score
				// when button is pressed
				// if garbage is underneath the counter position, aka the press
				// start the FSM
				if (((!hit) && (garb != 3'b111)) && ((garb == counter) || 
				(garb == 3'b001 && counter == 3'b101) || (garb == 3'b010 && counter == 3'b100)))
					state_g <= 3'b000;

				// drawing FSM
				case(state_f)

					// state 0
					// erase previous press    
					3'b000: begin
						erase <= 1'b1;
						if (counter == 3'b000) 
							position <= 3'b101;
						else
							position <= counter - 3'b001;
						item <= 1'b1;
						state_f <= 3'b001;
					end 

					// state 1
					// wait for erase to finish
					3'b001: begin
						if (delay == 2401) begin
							state_f <= 3'b010;
							delay <= 0;
						end
						else
							delay <= delay + 1;
					end    // end of state 1

					// state 2
					// draw current press
					3'b010: begin
						erase <= 1'b0;
						position <= counter;
						item <= 1'b1;
						state_f <= 3'b011;
					end    // end of state 2

					// state 3
					// do nothing
					3'b011: 
						state_f <= 3'b011;

				endcase    // end of drawing FSM				

				
				// FSM for erasing garbage and calculating score
				case(state_g)

					// state 0
					3'b001: begin
						// erase the garbage if there is one
						// and calculate score
						if (garb != 3'b111) begin
							erase <= 1'b1;
							position <= garb;
							item <= 1'b0;
							state_g <= 3'b001;
							score <= score + 1;
						end
						else
							state_g <= 3'b001;
					end

					// state 1
					// wait for garbage to finish erasing
					3'b001: begin
						if (delay2 == 401) begin
							state_g <= 3'b010;
							delay2 <= 0;
						end
						else
							delay2 <= delay2 + 1;
					end

					// state 2    
					// generate new garbage
					3'b010: begin
						garb <= 3'b000 + rng[1:0];
						state_g <= 3'b011;
					end

					// state 3
					// draw the garbage
					3'b011: begin
						erase <= 1'b0;
						position <= garb;
						item <= 1'b0;
						state_g <= 3'b100;
					end
						
					// state 4
					// wait for garbage to finish drawing
					3'b100: begin
						if (delay2 == 401) begin
							state_g <= 3'b101;
							delay2 <= 0;
						end
						else
							delay2 <= delay2 + 1;
					end
					
					// state 5
					// do nothing
					3'b101:
						state_g <= 3'b101;

				endcase    // end of erase garbage FSM

			end    // end of non-reset actions

		end    // end of CLOCK_50

	end    // end of always

endmodule    // end of project_top module

