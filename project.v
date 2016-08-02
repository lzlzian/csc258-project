

module project
	(
    	CLOCK_50,                    	//	On Board 50 MHz
    	// Your inputs and outputs here
            	KEY,
            	SW,
    	// The ports below are for the VGA output.  Do not change.
    	VGA_CLK,                       	//	VGA Clock
    	VGA_HS,                        	//	VGA H_SYNC
    	VGA_VS,                        	//	VGA V_SYNC
    	VGA_BLANK_N,                    	//	VGA BLANK
    	VGA_SYNC_N,                    	//	VGA SYNC
    	VGA_R,                       	//	VGA Red[9:0]
    	VGA_G,                         	//	VGA Green[9:0]
    	VGA_B,                       	//	VGA Blue[9:0]
		HEX0,
		HEX1
	);

	input CLOCK_50;            	//	50 MHz
	input [9:0] SW;
	input [3:0] KEY;

    // reset button for VGA
    wire resetn;
    assign resetn = KEY[0];

    // reset button for modules
    wire reset_n;
    assign reset_n = KEY[1];

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
	wire [2:0] colour = 3'b100;
	wire [7:0] x;
	wire [6:0] y;
    wire writeEn;
    
	wire [3:0] garbage;
	assign garbage = SW[9:6];

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

	wire [27:0] timer;
	wire enable;
	reg [1:0] counter = 2'b00;
	assign timer = 100000000;
	rateDivider RD(timer, CLOCK_50, enable);

	always@(posedge enable) begin
    	if (!reset_n) begin
        	counter <= 2'b00;
    	end
    	else if (counter == 2'b11) begin
        	counter <= counter - 1'b1;
    	end
    	else if (counter == 2'b00) begin
        	counter <= counter +1'b1;
    	end
	end    // end of always

    reg [2:0] c0;
    reg [2:0] c1;
    reg [2:0] c2;
    reg [2:0] c3;
    wire [2:0] c00;
    wire [2:0] c11;
    wire [2:0] c22;
    wire [2:0] c33;
    assign c00 = c0;
    assign c11 = c1;
    assign c22 = c2;
    assign c33 = c3;

    reg [1:0] pos0;
    wire [1:0] pos_0;
    assign pos_0 = pos0;

    reg bw;
    wire b_w;
    assign b_w = bw;

    wire [7:0] score_;
    reg [7:0] score;
    assign score_ = 8'b00000000 + score;

    output [6:0] HEX0;
    output [6:0] HEX1;
  
    hex_decoder h0(score[3:0], HEX0);
    hex_decoder h1(score[7:4], HEX1);

    always@(posedge CLOCK_50) begin

        // reset
        if(!reset_n) begin
            colour <= 3'b100;
        	xcounter <= 8'b00000000;
        	ycounter <= 7'b0000000;
    	end

        // first press position
    	if(ycounter < 7'b0111100 && xcounter < 8'b00100111) begin // y < 60, x < 39
        	colour <= 3'b100;
        	xcounter <= xcounter + 1'b1;
        end
        if(ycounter < 7'b0111011 && xcounter == 8'b00100111) begin //y < 59, x = 39
        	colour <= 3'b100;
        	xcounter <= 8'b00000000;
        	ycounter <= ycounter + 1'b1;     	
    	end

    	// second press position
    	if(ycounter == 7'b0111011 && xcounter == 8'b00100111) begin // y = 59, x = 39
        	colour <= 3'b000;
        	xcounter <= 8'b00101000; //x=40
        	ycounter <= 7'b0000000;
        end
    	if(ycounter < 7'b0111100 && xcounter < 8'b01001111 && xcounter > 8'b00100111) begin // y < 60, 39 < x < 79
        	colour <= 3'b000;
        	xcounter <= xcounter + 1'b1;  	
        end
    	if(ycounter < 7'b0111011 && xcounter == 8'b01001111) begin //y < 59, x = 79
         	colour <= 3'b000;
        	xcounter <= 8'b00101000;
        	ycounter <= ycounter + 1'b1;
        end

    	// third press position
    	if(ycounter == 7'b0111011 && xcounter == 8'b01001111) begin // y = 59, x = 79
        	colour <= 3'b001;
        	xcounter <= 8'b01010000; //x=80
        	ycounter <= 7'b0000000;
    	end
    	if(ycounter < 7'b0111100 && xcounter < 8'b01110111 && xcounter > 8'b01001111) begin // y < 60, 79 < x < 119
        	colour <= 3'b001;
        	xcounter <= xcounter + 1'b1;       	
    	end
    	if(ycounter < 7'b0111011 && xcounter == 8'b01110111) begin //x=119
          	colour <= 3'b001;
        	xcounter <= 8'b01010000;
        	ycounter <= ycounter + 1'b1;
    	end

    	// fourth press position
    	if(ycounter == 7'b0111011 && xcounter == 8'b01110111) begin // y = 59, x = 119
        	colour <= 3'b010;
        	xcounter <= 8'b01111000; //x=120
        	ycounter <= 7'b0000000;
     	end
    	if(ycounter < 7'b0111100 && xcounter < 8'b10011111 && x > 8'b01110111) begin // y < 60, 119 < x < 159
         	colour <= 3'b010;
        	xcounter <= xcounter + 1'b1;            	
      	end
    	if(ycounter < 7'b0111011 && xcounter == 8'b10011111) begin //x=159
          	colour <= 3'b010;
        	xcounter <= 8'b01111000;
        	ycounter <= ycounter + 1'b1;
    	end
  	
	end    // end of always



  //press p0(CLOCK_50,reset_n,3'b100,3'b000,3'b000,3'b000,ycounter,xcounter,colour);
  //drawGarbage d0(CLOCK_50, reset_n, pos_0, b_w, ycounter, xcounter, colour);

	always@(posedge enable) begin

        // draw press
        // first position
    	if (counter == 2'b00) begin
        	c0 <= 3'b100;
        	c1 <= 3'b000;
        	c2 <= 3'b000;
        	c3 <= 3'b000; 	
    	end

        // second position
    	else if (counter == 2'b01) begin
        	c0 <= 3'b000;
        	c1 <= 3'b100;
        	c2 <= 3'b000;
        	c3 <= 3'b000;
    	end

    	// third position
    	else if (counter == 2'b10) begin
        	c0 <= 3'b000;
        	c1 <= 3'b000;
        	c2 <= 3'b100;
        	c3 <= 3'b000;
    	end

    	// fourth position
    	else if (counter == 2'b11) begin
        	c0 <= 3'b000;
        	c1 <= 3'b000;
        	c2 <= 3'b100;
        	c3 <= 3'b000;
    	end

    	// draw garbage
        // first garbage
    	if (garbage[3]) begin
        	pos0 <= 2'b11;
	        bw <= 1'b1;
    	end
        // erase first garbage
    	if (!garbage[3]) begin
        	pos0 <= 2'b11;
        	bw <= 1'b0;
    	end

        // second garbage
    	if (garbage[2]) begin
        	pos0 <= 2'b10;
	        bw <= 1'b1;
    	end
        // erase second garbage
    	if (!garbage[2]) begin
        	pos0 <= 2'b10;
	        bw <= 1'b0;
    	end

        // third garbage
    	if (garbage[1]) begin
        	pos0 <= 2'b01;
	        bw <= 1'b1;
    	end
        // erase third garbage
    	if (garbage[1]) begin
        	pos0 <= 2'b01;
	        bw <= 1'b0;
    	end

        // fourth garbage
    	if (garbage[0]) begin
        	pos0 <= 2'b00;
	        bw <= 1'b1;
    	end
        // erase fourth garbage
    	if (garbage[0]) begin
        	pos0 <= 2'b00;
	        bw <= 1'b0;
    	end

	end    // end of always
	
    // adding score
	always@(*) begin
		if (!reset_n) begin
			score <= 8'b00000000;
		end
		if (KEY[3] && counter == 2'b00 && garbage[3]) begin
			score <= score + 1'b1;
		end
		if (KEY[2] && counter == 2'b01 && garbage[2]) begin
			score <= score + 1'b1;
		end
		if (KEY[1] && counter == 2'b10 && garbage[1]) begin
			score <= score + 1'b1;
		end
		if (KEY[0] && counter == 2'b11 && garbage[0]) begin
			score <= score + 1'b1;
		end
					
	end
	
endmodule




