module VGA(Reset, c25, VGA_R, VGA_G, VGA_B, VGA_CLK, VGA_BLANK, VGA_HS, VGA_VS, VGA_SYNC, row_out, col_out, pixel_in);
	parameter cols = 793;
	parameter rows = 525;
	parameter rsl = 2;
	parameter hsl = 95;
	parameter disp = 138;
	parameter d_row = 6'h24; //36 decimal
	parameter d_col = 8'h88; //136 decimal
	input c25;
	
	input Reset;
	output [9:0] VGA_R, VGA_G, VGA_B;
	output VGA_CLK, VGA_BLANK, VGA_HS, VGA_VS, VGA_SYNC;
	assign VGA_CLK = c25;
	
	input [7:0] pixel_in;
	//input [15:0] pixel_in; //color test
	
	output [9:0] row_out, col_out;
	
	reg [9:0] blue = 0, green = 0, red = 0;
	
	assign VGA_R = red;
	assign VGA_G = green;
	assign VGA_B = blue;
	assign VGA_SYNC = 1'b0;
	
	reg [9:0] row, column;
	
	assign VGA_VS = (row < rsl) ? 1'b0 : 1'b1;
	assign VGA_HS = (column < hsl) ? 1'b0 : 1'b1;
	assign VGA_BLANK = VGA_HS & VGA_VS;
	
	assign row_out = (row + 1'b1> d_row) ? (row + 1'b1 -d_row) : 10'h000;
	assign col_out = (column + 1'b1 > d_col) ? (column + 1'b1 - d_col) : 10'h000;
	
	
	always@(posedge c25 or negedge Reset) begin
		if(~Reset) begin
			row <= 0;
			column <= 0;
		end
		else begin
			if(column < cols) begin
				column <= column + 1'b1;
			end else begin
				column <= 0;
				if(row < rows) begin
					row <= row + 1'b1;
				end else begin
					row <= 0;
				end
			end
		end
	end
	always@(negedge c25) begin
		if(row >= d_row && row < 516) begin
			if(column >= d_col && column < 776) begin
			
				red <= 8'h92*pixel_in[7:5];
				green <= 8'h92*pixel_in[4:2];
				blue <= 9'h155*pixel_in[1:0];
				/* Color Test
				red <= {pixel_in[15:10], 4'h0};
				green <= {pixel_in[9:5], 5'b00000};
				blue <= {pixel_in[4:0], 5'b00000};*/
			end
			else begin
				blue <= 10'h000;
				red <= 10'h000;
				green <= 10'h000;
			end
		end else begin
			blue <= 10'h000;
			red <= 10'h000;
			green <= 10'h000;
		end
	end
endmodule 