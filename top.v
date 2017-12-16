module top(
	//Master Clock
	CLOCK_50, 
	
	//VGA Display Port
	VGA_R, VGA_G, VGA_B, VGA_CLK, VGA_BLANK, VGA_HS, VGA_VS, VGA_SYNC, 
	
	//Switches, Red LED, Buttons, Green LEDS
	SW, LEDR, KEY, //LEDG

	//HEX 7seg displays
	HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0,
	//LCD SCREEN
	LCD_DATA, LCD_RW, LCD_EN, LCD_RS, LCD_ON, LCD_BLON,
	//SRAM
	SRAM_ADDR, SRAM_DQ, SRAM_WE_N, SRAM_OE_N, SRAM_UB_N, SRAM_LB_N, SRAM_CE_N,
	//SD Card
	SD_DAT, SD_DAT3, SD_CMD, SD_CLK);
	
	//CLOCK DIVIDER
		//This stays in the top level module in case we want different phases of clocks
		input CLOCK_50; //FPGA clock @ 50 Mhz
		wire c25; //Output at 25 Mhz
		wire clk800khz; //Output at 781,250 Hz (Close enough)
		reg clk400hz = 1'b0;
		
		reg [7:0] ccount; //reg used to keep track of clock cycles
		reg [7:0] lcdcount; //another reg, much slower counter for the lcd screen
		
		assign c25 = ccount[0];
		assign clk800khz = ccount[6];
		
		always@(posedge CLOCK_50) begin
			ccount <= ccount + 1'b1;
			if(&ccount) lcdcount <= lcdcount + 1'b1;
			if(lcdcount == 8'hF4) begin
				clk400hz <= ~clk400hz;
				lcdcount <= 8'h00;
			end
		end
	//END CLOCK DIVIDER
	
	//BEGIN VGA
		output [9:0] VGA_R, VGA_G, VGA_B;
		output VGA_CLK, VGA_BLANK, VGA_HS, VGA_VS, VGA_SYNC;
	
		wire vgaReset;
		assign vgaReset = KEY[3];
		wire [9:0] vga_row, vga_col;
		wire [7:0] vga_pixel = char_in[15:8] * rompix; 
		//wire [15:0] vga_pixel = char_in;
		
		VGA monitor (vgaReset, c25, VGA_R, VGA_G, VGA_B, VGA_CLK, VGA_BLANK, VGA_HS, VGA_VS, VGA_SYNC, vga_row, vga_col, vga_pixel);
	//END VGA
	
	//BEGIN HEX
	output [0:6] HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;
	reg [3:0] h0, h1, h2, h3, h4, h5, h6, h7;
	HEX_out he0(h0, HEX0);
	HEX_out he1(h1, HEX1);
	HEX_out he2(h2, HEX2);
	HEX_out he3(h3, HEX3);
	HEX_out he4(h4, HEX4);
	HEX_out he5(h5, HEX5);
	HEX_out he6(h6, HEX6);
	HEX_out he7(h7, HEX7);
	//END HEX
	
	//BEGIN LCD
	inout [7:0] LCD_DATA;
	output LCD_RW, LCD_EN, LCD_RS, LCD_ON, LCD_BLON;
	reg [7:0] lcddisp [31:0];
	reg [4:0] lcdcursor = 5'h00;
	LCD_out lcd (
		{lcddisp [0],lcddisp [1],lcddisp [2],lcddisp [3],lcddisp [4],lcddisp [5],lcddisp [6],lcddisp [7],
		lcddisp [8],lcddisp [9],lcddisp [10],lcddisp [11],lcddisp [12],lcddisp [13],lcddisp [14],lcddisp [15]},
		{lcddisp [16],lcddisp [17],lcddisp [18],lcddisp [19],lcddisp [20],lcddisp [21],lcddisp [22],lcddisp [23],
		lcddisp [24],lcddisp [25],lcddisp [26],lcddisp [27],lcddisp [28],lcddisp [29],lcddisp [30],lcddisp [31]},
		LCD_DATA, LCD_RW, LCD_EN, LCD_RS, LCD_ON, LCD_BLON, clk400hz);
	
	//END LCD
	
	//ROM INIT (CHARACTER - FORMAT ASCII)
		wire [2:0] charcol = vga_col[2:0];
		wire [3:0] charrow = vga_row[3:0];
		wire rompix;
		pc_vga_8x16 charrom(vga_col[2:0] - 1'b1,vga_row[3:0],~ascii,rompix);
	//END ROM INIT
	
	
	
	//MEMORY CONTROLLER - VGA mixed in for syncing purposes
		output [17:0] SRAM_ADDR;
		inout [15:0] SRAM_DQ;
		output SRAM_CE_N, SRAM_OE_N, SRAM_WE_N, SRAM_UB_N, SRAM_LB_N;
		
		reg sram_we;
		reg [15:0] sram_out, sram_in, char_in;
		wire [7:0] ascii = char_in[7:0]; // CHAR is made with 8 color bits and 8 ascii bits
		reg [17:0] sram_address;
		
		assign SRAM_WE_N = ~sram_we; //write enable, using positive register and negative pin
		assign SRAM_CE_N = 1'b0; //always have chip enabled
		assign SRAM_OE_N = 1'b0; //always have output enabled
		assign SRAM_UB_N = 1'b0; //always have upper bit enabled
		assign SRAM_LB_N = 1'b0; //always have lower bit enabled
		assign SRAM_ADDR = sram_address; //assign the register to the output pins
		assign SRAM_DQ [15:0] = sram_we ? sram_out : 16'hzzzz; //tristate buffer, output when write enabled, recieve otherwise
		
		//BEGIN VGA SECTION
			//we're using a 512KB memory, addresses have 16 bits each, so we only need the last 2400 addressess 
			parameter offset = 18'h3F69F;
			//Automatic cursor for the monitor, this is the memory address of the current character to be loaded to the monitor
			//7'h50 = 80 (chars per row) | >>3 because 8 bit char width | >> 4 for 16 bit char height
			wire [17:0] char_pos = ((vga_col/8) + (7'h50 * ((vga_row)/16))) + offset; 
			
			//wire [7:0] acount;//debug variable
			//assign acount = sram_address - offset;
			
			reg [11:0] cursor = 11'h000; //character cursor
			reg cblank = 1'b0; //assert high to blank monitor
		//END VGA SECTION

		//Master memroy loop used to syncronize signals between different memory ticks
		reg dispswitch = 1'b0;
		
		always@(posedge CLOCK_50) begin
			if(vga_col[2:0] == 3'b000) begin
					sram_we <= 1'b0;
					sram_address <= char_pos;
					char_in <= SRAM_DQ;
			end else if (vga_col[2:0] == 3'b001) begin
				sram_we <= 1'b0;
				sram_address <= lcdcursor + offset;
				lcddisp[lcdcursor] <= {3'b000, lcdcursor};//SRAM_DQ[7:0];
				lcdcursor <= lcdcursor + 1'b1;
			end else begin
				if(cblank) begin
					sram_we <= 1'b1;
					cursor <= (cursor + 1'b1) % 12'h960;
					sram_address <= offset + cursor;
					sram_out <= 16'h0000;
				end else begin
					if(~KEY[1]) begin
						sram_we <= 1'b1;
						sram_address <= sram_address + 1'b1;
						sram_out <= sram_address[15:0];
					end else begin
					sram_we <= SW[17];
					sram_address <= (offset + SW[16:8]);
					sram_out <= {8'hFF, SW[7:0]};
					end
				end
			end
		end
	//END MEMORY CONTROLLER
	
	input [3:0] KEY;
	input [17:0] SW;
	output [17:0] LEDR;
		
	
	//INIT SD CARD
		input SD_DAT; //DatOut SPI
		output SD_CLK, //SCLK
				SD_CMD, //DataIn SPI
				SD_DAT3; //Chip Select
		reg [47:0] cmd = 0;
		reg cmdready = 1'b0;
		wire sdbusy;
		
		SDCard sdc(SD_DAT3, SD_CLK, SD_CMD, SD_DAT, clk800khz, cmd, cmdready, sdbusy);
	//END SD CARD
	
endmodule 