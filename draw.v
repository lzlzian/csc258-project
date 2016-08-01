module draw(clk, reset_n, item, erase, position, x_cord, y_cord, colourOut, plot);

	// CLOCK_50 and reset_n
	input clk,reset_n;

	// item: 1 - press, 0 - garbage
	input item;

	// erase: 1 - erase, 0 - draw new
	input erase;

	// position: 0 to 3
	input [1:0] position;

	// x and y coordinates final outputs
	output [7:0] x_cord;
	output [6:0] y_cord;

	// output colour: 3'b111 - white, 3'b000 - black
	output [2:0] colourOut;

	// writeEn signal to be sent to VGA
	output plot;

	// x and y positions
	// reg type because used in always block
	reg [7:0] x_pos;
	reg [6:0] y_pos;

	// x and y counters, both initially 0
	// reg type because used in always block
	reg [5:0] x_count = 0;
	reg [5:0] y_count = 0;

	// signal if the item has been drawn
	// 1 - completed, 0 - incomplete
	reg complete = 0;

	// x output is the sum of x's starting postion and x's current counter
	// likewise for y
	assign x_cord = x_pos + x_counter;
	assign y_cord = y_pos + y_counter;

	// output colour white if erase == 0 and reset_n == 0, otherwise black
	assign colourOut = ((erase == 0) && (reset_n == 0))? 3'b111 : 3'b000;

	// enable VGA to write if the item is still incomplete
	assign plot = (complete == 0)? 1 : 0;

	// always block to select starting x, y position
	// based on press or garbage, and position 0 - 3
	always @(*) begin
		case ({item, position}) 
			{1, 0}:
				begin
					x_pos = 0;
					y_pos = 0;
				end
			{1, 1}:
				begin
					x_pos = 40;
					y_pos = 0;
				end
			{1, 2}:
				begin
					x_pos = 80;
					y_pos = 0;
				end
			{1, 3}:
				begin
					x_pos = 120;
					y_pos = 0;
				end
			{0, 0}:
				begin
					x_pos = 10;
					y_pos = 100;
				end
			{0, 1}:
				begin
					x_pos = 50;
					y_pos = 100;
				end
			{0, 2}:
				begin
					x_pos = 90;
					y_pos = 100;
				end
			{0, 3}:
				begin
					x_pos = 130;
					y_pos = 100;
				end
			default:
				begin
					x_pos = 0;
					y_pos = 0;
				end
		endcase
	end    // end of always

	// always block to draw
	always @(posedge clk) begin
		case (item)
			// draw press
			1: 
				begin
					// synchronous low reset
					if (reset_n == 0) begin
						x_count <= 0;
						y_count <= 0;
					end
					// draw if the item is still incomplete
					else if (complete == 0) begin
						// draw horizontal lines
						else if ((x_count < 39) && (y_count < 60)) begin
							x_count <= x_count + 1;
						end
						// end of the line, go to the beginning of next line
						else if ((x_count == 39) && (y_count) < 59) begin
							x_count <= 0;
							y_count <= y_count + 1;
						end
						// end of this press
						else if ((x_count == 39) && (y_count) == 59) begin
							x_count <= 0;
							y_count <= 0;
							complete <= 1;
						end
					end
				end    // end of current case
			// draw garbage
			0:
				begin
					// synchronous low reset
					if (reset_n == 0) begin
						x_count <= 0;
						y_count <= 0;
					end
					// draw if the item is still incomplete
					else if (complete == 0) begin
						// draw horizontal lines
						else if ((x_count < 19) && (y_count < 20)) begin
							x_count <= x_count + 1;
						end
						// end of the line, go to the beginning of next line
						else if ((x_count == 19) && (y_count) < 19) begin
							x_count <= 0;
							y_count <= y_count + 1;
						end
						// end of this garbage
						else if ((x_count == 19) && (y_count) == 19) begin
							x_count <= 0;
							y_count <= 0;
							complete <= 1;
						end
					end
				end    // end of current case
		endcase
	end    // end of always

endmodule

