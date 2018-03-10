module top(
	//Master Clock
	CLOCK_50, 
	
	//VGA Display Port
	VGA_R, VGA_G, VGA_B, VGA_CLK, VGA_BLANK, VGA_HS, VGA_VS, VGA_SYNC, 
	
	//Switches, Red LED, Buttons, Green LEDS
	SW, LEDR, KEY,//, //LEDG
	//HEX Display
	HEX0, HEX1, HEX2, HEX3, HEX4
	);
	//SRAM_ADDR, SRAM_DQ, SRAM_WE_N, SRAM_OE_N, SRAM_UB_N, SRAM_LB_N, SRAM_CE_N);
	
	//CLOCK DIVIDER
		//This stays in the top level module in case we want different phases of clocks
		input CLOCK_50; //FPGA clock @ 50 Mhz
		wire c25; //Output at 25 Mhz
		
		reg [7:0] ccount; //reg used to keep track of clock cycles
		
		assign c25 = ccount[0];
		
		always@(posedge CLOCK_50) begin
			ccount <= ccount + 1'b1;
		end
	//END CLOCK DIVIDER
	
	//BEGIN VGA
		output [9:0] VGA_R, VGA_G, VGA_B;
		output VGA_CLK, VGA_BLANK, VGA_HS, VGA_VS, VGA_SYNC;
	
		wire vgaReset;
		assign vgaReset = KEY[3];
		
		VGA monitor (vgaReset, c25, VGA_R, VGA_G, VGA_B, VGA_CLK, VGA_BLANK, VGA_HS, VGA_VS, VGA_SYNC, SW[17:0]);
	//END VGA
	
	input [3:0] KEY;
	input [17:0] SW;
	output [17:0] LEDR;	
	
	//begin hex
	output [0:6] HEX0, HEX1, HEX2, HEX3, HEX4;
	HEX_out H1(SW[3:0], HEX0);
	HEX_out H2(SW[7:4], HEX1);
	HEX_out H3(SW[11:8], HEX2);
	HEX_out H4(SW[15:12], HEX3);
	HEX_out H5({2'b00, SW[17:16]}, HEX4);
endmodule 