module vga_template(clk, Reset, 
	dispClk, dispX, dispY, //an outgoing clock requesting the next pixel when the circuit is in the 'display' region
	VGA_R, VGA_G, VGA_B, VGA_CLK, VGA_BLANK, VGA_HS, VGA_VS, VGA_SYNC, //actual VGA pins
	red, green, blue, en //pixel controls
	);
	//Fill in timing specifications here, the following specifications are for a 640x480@60hz display
	//Horizontal Parameters are given in pixel width
	//Vertical Parameters are given in line count
	parameter 	horizontalSync = 96, 
					horizontalFrontPorch = 16, 
					horizontalBackPorch = 48,
					horizontalDisplay = 640, //c, visible area, draw area, etc.
					verticalSync = 2, 
					verticalFrontPorch = 10, 
					verticalBackPorch = 33,
					verticalDisplay = 480; //c, visible area, draw area, etc.
	//line_width = horizontalSync+ horizontalFrontPorch + horizontalBackPorch + horizontalDisplay 
	//line_width = 800
	parameter col_count = 800;
	//line_count = verticalSync + verticalFrontPorch + verticalBackPorch + verticalDisplay
	//line_count = 525
	parameter row_count = 525;
	//bitwidth(line_width) = roof(log2(line_width)) = 10
	//bitwidth(line_count) = 10
	reg [9:0] row; //line_width has bitwidth 10, [n-1, 0]
	output [9:0] dispY = row; //pass this value outside the module 
	reg [9:0] col; //line_count has bitwidth 10, [n-1, 0]
	output [9:0] dispX = col; //pass this value outside the module
	
	wire display = (row < verticalDisplay) && (col < horizontalDisplay); //1 - in Display region ; 0 - not in display region 
			
	//reg [9:0] red, green, blue; 
	
	//define inputs/outputs
	input clk;
	input Reset;
	output dispClk = display & clk;
	//Our dac has a 10 bit width, adjust to appropriate value for your dac
	input [9:0] red, green, blue;
	//en switches between back/foreground, background is currently just black, could be adjusted below
	input en;
	reg [9:0] background = 10'h000;
	
	output [9:0] VGA_R, VGA_G, VGA_B;
	output VGA_CLK, VGA_BLANK, VGA_HS, VGA_VS, VGA_SYNC;
	
	//end defines
	
	//assign regs to their appropriate wires
	//to adjust background colors: change background to dedicated variables, and attach as inputs or assign a static value of appropriate bitwidth
	assign VGA_R = display ? (en ? red : background) : 10'h000;// red;
	assign VGA_G = display ? (en ? green : background) : 10'h000;//green;
	assign VGA_B = display ? (en ? blue : background) : 10'h000;//blue;
	assign VGA_CLK = clk;
	assign VGA_BLANK = VGA_HS & VGA_VS;
	assign VGA_HS = (col >= horizontalDisplay + horizontalFrontPorch + horizontalSync) || (col < horizontalDisplay + horizontalFrontPorch); //horizontal sync signal
	assign VGA_VS = (row >= verticalDisplay + verticalFrontPorch + verticalSync) || (row < verticalDisplay + verticalFrontPorch);//vertical sync signal
	assign VGA_SYNC = 1'b0;// VGA_HS & VGA_VS;?
	//end assignments
	

	
	always@(posedge clk or negedge Reset) begin
		if(~Reset) begin
			row <= verticalDisplay;
			col <= horizontalDisplay;
		end else begin
			if(col < col_count)
				col <= col + 1'b1;
			else begin
				col <= 0;
				if(row < row_count) 
					row <= row + 1'b1;
				else 
					row <= 0;
			end
		end
	end
endmodule 