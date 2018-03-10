module VGA(Reset, c25, VGA_R, VGA_G, VGA_B, VGA_CLK, VGA_BLANK, VGA_HS, VGA_VS, VGA_SYNC, pixel_in);
	input c25;
	input Reset;
	
	output [9:0] VGA_R, VGA_G, VGA_B;
	output VGA_CLK, VGA_BLANK, VGA_HS, VGA_VS, VGA_SYNC;
	
	input [17:0] pixel_in;
	wire [9:0] testVal;
	assign testVal = pixel_in;
	
	wire dispClk;
	wire [18:0] dispIndex;
	wire [9:0] dispX, dispY;
	
	wire pix = (dispX < dispY+5) && (dispY < dispX + 5);//(dispIndex == {1'b0, pixel_in});
	
	wire [9:0] red = 8'h92 * pixel_in[7:5];
	wire [9:0] green = 8'h92 * pixel_in[4:2];
	wire [9:0] blue = 9'h155 * pixel_in[1:0];
	vga_template U1(c25, Reset, 
	dispClk, dispX, dispY,
	VGA_R, VGA_G, VGA_B, VGA_CLK, VGA_BLANK, VGA_HS, VGA_VS, VGA_SYNC, //actual VGA pins
	red, green, blue, pix
	);	
endmodule 