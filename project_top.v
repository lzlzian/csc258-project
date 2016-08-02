

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

	input CLOCK_50;            	//	50 MHz
	input [3:0] KEY;

    // RESET BUTTON FOR VGA
    wire resetn;
    assign resetn = KEY[0];

    // RESET BUTTON FOR MODULES
    wire reset_n;
    assign reset_n = KEY[1];

    // KEY TO PLAY THE GAME
    wire hit;
    assign hit = KEY[3];

	// Do not change the following outputs
	output        	VGA_CLK;               	//	VGA Clock
	output        	VGA_HS;                	//	VGA H_SYNC
	output        	VGA_VS;                	//	VGA V_SYNC
	output        	VGA_BLANK_N;            	//	VGA BLANK
	output        	VGA_SYNC_N;            	//	VGA SYNC
	output	[9:0]	VGA_R;               	//	VGA Red[9:0]
	output	[9:0]	VGA_G;                 	//	VGA Green[9:0]
	output	[9:0]	VGA_B;               	//	VGA Blue[9:0]
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
    wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
        	.resetn(resetn),
        	.clock(CLOCK_50),
        	.colour(colour_),
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

    // instantiate rateDivider and counter
	wire [27:0] timer;
	wire enable;
	reg [1:0] counter = 2'b01;
    reg [1:0] prev_counter = 2'b00;
    reg [2:0] state_f = 3'b000;
    reg [1:0] state_g = 2'b11;
    reg [11:0] delay = 0;
    reg [8:0] delay2 = 0;
	assign timer = 10000000;
	rateDivider RD(timer, CLOCK_50, enable);

    // declare score
    wire [7:0] score_;
    reg [7:0] score;
    assign score_ = 8'b00000000 + score;

    // instantiate hex decoders for score display
    output [6:0] HEX0;
    output [6:0] HEX1;
    hex_decoder h0(score[3:0], HEX0);
    hex_decoder h1(score[7:4], HEX1);

    // instantiate the drawer
    reg item, erase;
    reg [1:0] position;
    draw d0(CLOCK_50, reset_n, item, erase, position, x, y, colour, writeEn);

    // declare garbage position variable and the random number generator
    // 0-3: garbage position, 4: currently no garbage
    reg [2:0] garb = 3'b100;
    wire [4:0] rng;
    random r0(CLOCK_50, reset_n, rng);


    // *** DRAW ***
    // use counter to track press position
    always@(posedge CLOCK_50) begin

        // reset
    	if (!reset_n) begin
            counter <= 2'b01;
            prev_counter <= 2'b00;
            state_f <= 2'b000;
            delay <= 0;
            garb <= 3'b100;
        end

	    // reset score
	    // reset with the VGA, not with other modules
		if (!resetn) begin
			score <= 8'b00000000;
			state_g <= 2'b11;
		end

	    // move press back and forth
        else if (enable) begin

	        if (counter == 2'b00)  begin
	            prev_counter <= counter;
	            counter <= counter + 1;
	        end
	        else if (counter == 2'b11) begin
	            prev_counter <= counter;
	            counter <= counter - 1;
	        end
	        else if (counter > prev_counter) begin
	            prev_counter <= counter;
	            counter <= counter + 1;
	        end
	        else if (counter < prev_counter) begin
	            prev_counter <= counter;
	            counter <= counter - 1;
	        end

	        // generate a garbage if there is currently none
	        if (garb == 3'b100) begin
	            garb <= 3'b000 + rng[1:0];
	        end

	        // reset the FSM
	        state_f <= 3'b000;
	    end


	    // draw
	    case(state_f)

	    	// draw the garbage
	    	3'b000: begin
		        erase <= 1'b0;
		        position <= garb[1:0];
		        item <= 1'b0;
		        state_f <= 3'b001;
		    end

		    // wait for garbage to finish drawing
		    3'b001: begin
		    	if (delay == 401) begin
		    		state_f <= 3'b010;
		    		delay <= 0;
				end
		    	else
		    		delay <= delay + 1;
		    end
		    
		    // erase previous press    
		    3'b010: begin
		        erase <= 1'b1;
		        position <= prev_counter;
		        item <= 1'b1;
		        state_f <= 3'b011;
		    end

		    // wait for erase to finish
		    3'b011: begin
		        if (delay == 2401) begin
		    		state_f <= 3'b100;
		    		delay <= 0;
					end
		    	else
		    		delay <= delay + 1;
		    end

		    // draw current press
		    3'b100: begin
		        erase <= 1'b0;
		        position <= counter;
		        item <= 1'b1;
		        state_f <= 3'b111;
		    end

		    // do nothing
		    3'b111: 
		    	state_f <= 3'b111;
		endcase
		
        // hit detection and adding score
        // button pressed
        if (!hit) begin
            // garbage is below the press
            // start the FSM
            if (counter == garb)
            	state_g <= 2'b00;
        end

        case(state_g)
			// erase the garbage
    		2'b00: begin
                erase <= 1'b1;
                position <= garb;
                item <= 1'b0;
                state_g <= 2'b01;
            end

            // wait for garbage to finish erasing
            2'b01: begin
            	if (delay2 == 401) begin
		    		state_g <= 2'b10;
		    		delay2 <= 0;
					end
		    	else
		    		delay2 <= delay2 + 1;
		   	end
                
            // set garb to 3'b100, aka no current garbage
            // add score
            2'b10: begin
                garb <= 3'b100;
                score <= score + 1;
                state_g <= 2'b11;
            end

            // do nothing
            2'b11: 
            	state_g <= 2'b11;

		endcase
	end    // end of always
	
endmodule




