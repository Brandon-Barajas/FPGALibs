module test(KEY, CLOCK_50, VGA_R, VGA_G, VGA_B, VGA_CLK, 
				VGA_BLANK, VGA_HS, VGA_VS, VGA_SYNC, SW, LEDR, HEX7, HEX6,
				HEX5, HEX4, SRAM_ADDR, SRAM_DQ, SRAM_WE_N, SRAM_OE_N,
				SRAM_UB_N, SRAM_LB_N, SRAM_CE_N, PS2_CLK, PS2_DAT, LEDG);
input [17:0] SW;
input [3:0] KEY;
input CLOCK_50;


	output [9:0] VGA_R, VGA_G, VGA_B;
	output VGA_CLK, VGA_BLANK, VGA_HS, VGA_VS, VGA_SYNC;
	output [17:0] LEDR;
	output [0:6] HEX7, HEX6, HEX5, HEX4;
	
	output [7:0] LEDG;


reg[15:0] inst;
reg[15:0] MEMTEST [255:0]; 
reg[15:0] MEMTEST2 [127:0]; 
reg[15:0] MEMTEST3 [63:0]; 
reg[15:0] MEMTEST4 [63:0]; 
reg[15:0] MEMTEST5 [63:0]; 
reg[15:0] MEMTEST6 [63:0]; 
reg[15:0] MEMTEST7 [63:0]; 
reg[15:0] MEMTEST8 [31:0]; 
reg[15:0] MEMTEST9 [31:0]; 
reg[31:0] k;
//reg[31:0] addr;

	//Keyboard initializatoin
	input PS2_CLK, PS2_DAT;
	wire kbpos;
	reg prev_kbpos = 1'b0;
	reg key_ready = 1'b0;
	wire [7:0] kbin;
	wire kready;
	assign kready=key_ready;
	
	KB_read IN(PS2_CLK, PS2_DAT, kbin, 1'b1, kbpos);
	
	//assign LEDG[2] = kbpos;
	////assign LEDG[3] = kready;
	//assign LEDG[4] = prev_kbpos;
	//assign LEDG[5] = superslow;
	
	reg [26:0] bigcounter;
	
	always@(posedge CLOCK_50) begin
		bigcounter <= bigcounter + 1'b1;
	end
	
	wire superslow;
	assign superslow = bigcounter[25];
	
	always@(posedge CLOCK_50) begin
		if(key_ready) key_ready <= 1'b0;
		else if(prev_kbpos != kbpos) begin
			key_ready <= 1'b1;
			prev_kbpos <= kbpos;
		end
	end

	reg c25;
	reg [2:0] ccount;
	
	always@(posedge CLOCK_50) begin
		c25 <= ~c25;
		ccount <= ccount + 1'b1;
	end
	
	wire vgaReset;
	assign vgaReset = KEY[3];
	wire [9:0] vga_row, vga_col;
	wire [7:0] vga_pixel;
	reg [7:0] vga_pix;
	assign vga_pixel = char_in[15:8] * rompix; //(vga_col % 2) ? sram_in[15:8] : sram_in[7:0];
	
	VGA monitor (vgaReset, c25, VGA_R, VGA_G, VGA_B, VGA_CLK, VGA_BLANK, VGA_HS, VGA_VS, VGA_SYNC, vga_row, vga_col, vga_pixel);
	
	//ROM INIT (CHARACTER - FORMAT ASCII)
	wire [2:0] charcol;
	assign charcol = vga_col[2:0];
	wire [3:0] charrow;
	assign charrow = vga_row[3:0];
	wire rompix;
	pc_vga_8x16 charrom(vga_col[2:0] - 1'b1,vga_row[3:0],~ascii,rompix);
	
	/*
	//CHAR BIOS INIT 
	reg [7:0] nextchar = 8'h00;
	reg [7:0] charout;
	reg cwritesig = 1'b0;
	reg ewrite = 1'b0; //external write signal
	reg cblanksig = 1'b0;
	reg ready = 1'b1;
	wire reset;
	
	always@(posedge CLOCK_50) begin
		case(nextchar)
			8'h00: cwritesig <= 1'b0;
			8'h0A: charpos <= 8'h50 * (charpos/8'h50 + 1'b1);
			8'h0C: begin
				if(ewrite == 1'b0) cblanksig <= 1'b1;
				charpos <= 11'h000;
			end
			default: begin 
				if(ewrite == 1'b0) begin 
					charout <= nextchar;
					nextchar <= 0;
				end
		endcase
	end */
	
	
	//SRAM INIT
	//video handler INIT
	reg sram_we;
	reg [15:0] sram_out, sram_in, char_in;
	reg [17:0] sram_address;
	wire [17:0] char_pos;
	
	parameter offset = 18'h3F69F;
	//we're using a 512KB memory, addresses have 16 bits each, so we only need the last 2400 addressess 
	assign char_pos = ((vga_col/8) + (7'h50 * ((vga_row)/16))) + offset; 
	//7'h50 = 80 (chars per row) | >>3 because 8 bit char width | >> 4 for 16 bit char height
	wire [7:0] ascii = char_in[7:0];
	
	wire [7:0] acount;
	assign acount = sram_address - offset;
	
	reg [11:0] charpos = 11'h000;
	reg cblank = 1'b0;

	always@(posedge CLOCK_50) begin
	//	if(addr<255)begin
		/*if(~SW[0])begin
			inst<=MEMTEST[addr];
		end
		else if(SW[0])begin
			inst<=MEMTEST2	[addr];
		end*/
		case(SW[3:0])
		0: begin
			inst<=MEMTEST[addr];
		end
		1: begin
			inst<=MEMTEST2[addr];
		end
		2: begin
			inst<=MEMTEST3[addr];
		end
		3: begin
			inst<=MEMTEST4[addr];
		end
		4: begin
			inst<=MEMTEST5[addr];
		end
		5: begin
			inst<=MEMTEST6[addr];
		end
		6: begin
			inst<=MEMTEST7[addr];
		end
		7: begin
			inst<=MEMTEST8[addr];
		end
		8: begin
			inst<=MEMTEST9[addr];
		end
		default:begin inst<=16'h0; end
		endcase
		//end
		
		if(vga_col[2:0] == 3'b000) begin
			sram_we <= 1'b0;
			sram_address <= char_pos;
			char_in <= SRAM_DQ;
		end else begin
			if(~KEY[0]) begin
				sram_we <= 1'b1;
				charpos <= (charpos + 1'b1) % 12'h960;
				sram_address <= offset + charpos;
				sram_out <= 16'h0000;
				//PCtest<=0;
			end else begin
				if(~KEY[1]) begin
					sram_we <= 1'b1;
					sram_address <= sram_address + 1'b1;
					sram_out <= {8'hFF, acount};
					exec<=1;
				end else begin
				//if (addr<156) begin
				//end
				//else begin inst<=16'h0; end
				sram_we = 1;
				sram_address = (wr) ? (addr) : (offset + A02[15:8]);
				//sram_address = (offset + A02[15:8]);
				sram_out = (wr) ? (16'hff00^dataout[15:0])  : {8'hFF, A02[7:0]};
				//sram_out = {8'hFF, A02[7:0]};
				end
			end
		end
	end
	
	output [17:0] SRAM_ADDR;
	inout [15:0] SRAM_DQ;
	output SRAM_CE_N, SRAM_OE_N, SRAM_WE_N, SRAM_UB_N, SRAM_LB_N;
	
	assign SRAM_WE_N = ~sram_we;
	assign SRAM_CE_N = 1'b0;
	assign SRAM_OE_N = 1'b0;
	assign SRAM_UB_N = 1'b0;
	assign SRAM_LB_N = 1'b0;
	assign SRAM_ADDR = sram_address;
	assign SRAM_DQ [15:0] = sram_we ? sram_out : 16'hzzzz;
	//END SRAM


wire [15:0] i;
wire clk;
wire key;
wire [31:0] dataout;
wire [17:0] addr;
reg [17:0] PCtest;
wire [17:0] pcTest;

assign pcTest=PCtest;
reg [17:0] start;

wire [17:0] s;

wire rcache;
reg readycache;
reg n;

reg pause;

reg[17:0] count;
reg prog;

initial begin
pause=0;
// inst=0;
start=0;
for(k=0;k<255;k=k+1)begin	
	MEMTEST[k]=16'h0000;	
	
end
for(k=0;k<128;k=k+1)begin	
	MEMTEST2[k]=16'h0000;	
	
end

for(k=0;k<64;k=k+1)begin	
	MEMTEST3[k]=16'h0000;	
end
for(k=0;k<64;k=k+1)begin	
	MEMTEST4[k]=16'h0000;	
end
for(k=0;k<64;k=k+1)begin	
	MEMTEST5[k]=16'h0000;	
end
for(k=0;k<64;k=k+1)begin	
	MEMTEST6[k]=16'h0000;	
end
for(k=0;k<64;k=k+1)begin	
	MEMTEST7[k]=16'h0000;	
end
for(k=0;k<32;k=k+1)begin	
	MEMTEST8[k]=16'h0000;	
end
for(k=0;k<32;k=k+1)begin	
	MEMTEST9[k]=16'h0000;	
end

	//initialize
	
	//if(~SW[0])begin
	MEMTEST[0]=16'h2408;
	MEMTEST[1]=16'h0008;
	MEMTEST[2]=16'h2417;
	MEMTEST[3]=16'h0008;
	MEMTEST[4]=16'hAFA8;
	MEMTEST[5]=16'h0398;
	MEMTEST[6]=16'hAFA8;
	MEMTEST[7]=16'h03E8;
	MEMTEST[8]=16'hAFA8;
	MEMTEST[9]=16'h0438;
	MEMTEST[10]=16'hAFA8;
	MEMTEST[11]=16'h0488;
	MEMTEST[12]=16'h0000;
	MEMTEST[13]=16'h0000;
	MEMTEST[14]=16'h0000;
	MEMTEST[15]=16'h0000;
	MEMTEST[14]=16'h0000;
	MEMTEST[15]=16'h0000;
	
	//rt values
	MEMTEST[16]=16'h240F;
	MEMTEST[17]=16'h0001; //t7=0x01
	MEMTEST[18]=16'h240E;
	MEMTEST[19]=16'h0050; //t6=0x50
	MEMTEST[20]=16'h240D;
	MEMTEST[21]=16'h0051; //t5=0x51
	MEMTEST[22]=16'h240C;
	MEMTEST[23]=16'h004F; //t4=0x4f
	MEMTEST[24]=16'h240B;
	MEMTEST[25]=16'h0003; //t3=0x03
	MEMTEST[26]=16'h240A;
	MEMTEST[27]=16'h0002; //t2=0x02

	//start
	MEMTEST[28]=16'h03A0;
	MEMTEST[29]=16'hF021; //fp=sp
	//evol
	MEMTEST[30]=16'h8FDA;
	MEMTEST[31]=16'h0000; //t0=0x0008
	//n1
	MEMTEST[32]=16'h0000;
	MEMTEST[33]=16'h0000; //no op
	MEMTEST[34]=16'h27C9;
	MEMTEST[35]=16'h0001; //t1=fp+0x01
	MEMTEST[36]=16'h8FB1;
	MEMTEST[37]=16'h0001; //s1=(sp)0x01
	MEMTEST[38]=16'h1011;
	MEMTEST[39]=16'h0001; //BNE sp(1) 0x0008 n2
	MEMTEST[40]=16'h2610;
	MEMTEST[41]=16'h0001; //s0=s0+1
	
	//n2
	MEMTEST[42]=16'h0000;
	MEMTEST[43]=16'h0000; //no op
	MEMTEST[44]=16'h27C9;
	MEMTEST[45]=16'h0051; //t1=fp+0x51
	MEMTEST[46]=16'h8FB1;
	MEMTEST[47]=16'h0051; //s1=(sp)0x51
	MEMTEST[48]=16'h1011;
	MEMTEST[49]=16'h0001; //BNE SP(81) n3
	MEMTEST[50]=16'h2610;
	MEMTEST[51]=16'h0001;
	
	//n3
	MEMTEST[52]=16'h0000;
	MEMTEST[53]=16'h0000;
	MEMTEST[54]=16'h27C9;
	MEMTEST[55]=16'h0050;
	MEMTEST[56]=16'h8FB1;
	MEMTEST[57]=16'h0050;
	MEMTEST[58]=16'h1011;
	MEMTEST[59]=16'h0001; //BNE SP(80) n4
	MEMTEST[60]=16'h2610;
	MEMTEST[61]=16'h0001;
	
	//n4
	MEMTEST[62]=16'h0000;
	MEMTEST[63]=16'h0000;
	MEMTEST[64]=16'h27C9;
	MEMTEST[65]=16'h004F;
	MEMTEST[66]=16'h8FB1;
	MEMTEST[67]=16'h004F;
	MEMTEST[68]=16'h1011;
	MEMTEST[69]=16'h0001;
	MEMTEST[70]=16'h2610;
	MEMTEST[71]=16'h0001;
	
	//n5
	MEMTEST[72]=16'h0000;
	MEMTEST[73]=16'h0000;
	MEMTEST[74]=16'h03CF;
	MEMTEST[75]=16'h4823;
	MEMTEST[76]=16'h8D31;
	MEMTEST[77]=16'h0000;
	MEMTEST[78]=16'h1011;
	MEMTEST[79]=16'h0001;
	MEMTEST[80]=16'h2610;
	MEMTEST[81]=16'h0001;
	
	//n6
	MEMTEST[82]=16'h0000;
	MEMTEST[83]=16'h0000;
	MEMTEST[84]=16'h03CE;
	MEMTEST[85]=16'h4823;
	MEMTEST[86]=16'h8D31;
	MEMTEST[87]=16'h0000;
	MEMTEST[88]=16'h1011;
	MEMTEST[89]=16'h0001;
	MEMTEST[90]=16'h2610;
	MEMTEST[91]=16'h0001;
	
	
	//n7
	MEMTEST[92]=16'h0000;
	MEMTEST[93]=16'h0000;
	MEMTEST[94]=16'h03CD;
	MEMTEST[95]=16'h4823;
	MEMTEST[96]=16'h8D31;
	MEMTEST[97]=16'h0000;
	MEMTEST[98]=16'h1011;
	MEMTEST[99]=16'h0001;
	MEMTEST[100]=16'h2610;
	MEMTEST[101]=16'h0001;
	//n8
	
	MEMTEST[102]=16'h0000;
	MEMTEST[103]=16'h0000;
	MEMTEST[104]=16'h03CC;
	MEMTEST[105]=16'h4823;
	MEMTEST[106]=16'h8D31;
	MEMTEST[107]=16'h0000;
	MEMTEST[108]=16'h1011;
	MEMTEST[109]=16'h0001;
	MEMTEST[110]=16'h2610;
	MEMTEST[111]=16'h0001;
	
	/*MEMTEST[96]=16'h1000;
	MEMTEST[97]=16'h0001;
	MEMTEST[98]=16'hAFB7;
	MEMTEST[99]=16'h0298;
	MEMTEST[100]=16'h0800;
	MEMTEST[101]=16'h0003;*/
	
	
	//update
	MEMTEST[112]=16'h120A;
	MEMTEST[113]=16'h0009; //branch stable
	
	MEMTEST[114]=16'h0000;
	MEMTEST[115]=16'h0000;
	

	MEMTEST[116]=16'h020A;
	MEMTEST[117]=16'h482A; //SLT 
	MEMTEST[118]=16'h1520;
	MEMTEST[119]=16'h000B; //branch death
	MEMTEST[120]=16'h0000;
	MEMTEST[121]=16'h0000;
	

	MEMTEST[122]=16'h120B;
	MEMTEST[123]=16'h0006	; //branch live
	MEMTEST[124]=16'h0000;
	MEMTEST[125]=16'h0000;
	
	
	MEMTEST[126]=16'h0170;
	MEMTEST[127]=16'h482A; //SLT
	MEMTEST[128]=16'h1520;
	MEMTEST[129]=16'h0002; //branch death again
	MEMTEST[130]=16'h0000;
	MEMTEST[131]=16'h0000;

	//stable

	MEMTEST[132]=16'hAF9A;
	MEMTEST[133]=16'h0000;
	MEMTEST[134]=16'h0800;
	MEMTEST[135]=16'h004A; //J next
	
	//live
	MEMTEST[136]=16'h2410;
	MEMTEST[137]=16'h0000;
	MEMTEST[138]=16'hAF97;
	MEMTEST[139]=16'h0000;
	MEMTEST[140]=16'h0800;
	MEMTEST[141]=16'h004A; //j next

	//dead
	MEMTEST[142]=16'h2410;
	MEMTEST[143]=16'h0000;
	MEMTEST[144]=16'hAF80;
	MEMTEST[145]=16'h0000;
	MEMTEST[146]=16'h0800;
	MEMTEST[147]=16'h004A; //j next
	

	//next
	
	/*MEMTEST[154]=16'hAFB7;
	MEMTEST[155]=16'h0052; //branch stable
	MEMTEST[156]=16'hAFB7;
	MEMTEST[157]=16'h0053; //branch stable
	MEMTEST[158]=16'hAFB7;
	MEMTEST[159]=16'h0054; //branch stable
	
	MEMTEST[160]=16'h1000;
	MEMTEST[161]=16'h0001;
	MEMTEST[162]=16'hAFB7;
	MEMTEST[163]=16'h0298;
	MEMTEST[164]=16'h0000;
	MEMTEST[165]=16'h0000;
	MEMTEST[166]=16'h0800;
	MEMTEST[167]=16'h0030;*/
	
	MEMTEST[148]=16'h2419;
	MEMTEST[149]=16'h0960;
	MEMTEST[150]=16'h1799;
	MEMTEST[151]=16'h000E; //bne gp t9 nextCell
	
	MEMTEST[152]=16'h0000;
	MEMTEST[153]=16'h0000;
	
	MEMTEST[154]=16'h241C;
	MEMTEST[155]=16'h0000; //set gp to 0
	
	MEMTEST[156]=16'h27B8;
	MEMTEST[157]=16'h0000; //set t8 to SP
	
	MEMTEST[158]=16'h0000;
	MEMTEST[159]=16'h0000; //update disp
	
	MEMTEST[160]=16'h8F91;
	MEMTEST[161]=16'h0000; //load MEM[gp] to s1
	
	MEMTEST[162]=16'hAF11;
	MEMTEST[163]=16'h0000; //store to MEM[t8]

	MEMTEST[164]=16'h279C;
	MEMTEST[165]=16'h0001; //increment gp

	MEMTEST[166]=16'h2718;
	MEMTEST[167]=16'h0001; //increment t8
	
	MEMTEST[168]=16'h1319;
	MEMTEST[169]=16'h0003; //beq past update disp
	
	MEMTEST[170]=16'h0000;
	MEMTEST[171]=16'h0000;
	
	MEMTEST[172]=16'h0800; 
	MEMTEST[173]=16'h004F;//j update disp

	MEMTEST[174]=16'h0000;
	MEMTEST[175]=16'h0000;
	
	MEMTEST[176]=16'h0000;
	MEMTEST[177]=16'h0000;
	
	MEMTEST[178]=16'h0800;
	MEMTEST[179]=16'h0060; //j restart
	
	MEMTEST[180]=16'h0000;
	MEMTEST[181]=16'h0000;

	MEMTEST[182]=16'h279C;	//nextCell
	MEMTEST[183]=16'h0001;
	
	MEMTEST[184]=16'h2410;
	MEMTEST[185]=16'h0000;
	
	MEMTEST[186]=16'h27DE;
	MEMTEST[187]=16'h0001;
	
	MEMTEST[188]=16'h0800;
	MEMTEST[189]=16'h000F; //j evol	
	
	MEMTEST[190]=16'h0000;
	MEMTEST[191]=16'h0000;

	MEMTEST[192]=16'h241C;
	MEMTEST[193]=16'h0000; //restart
	
	MEMTEST[194]=16'h2410;
	MEMTEST[195]=16'h0000;
	
	MEMTEST[196]=16'h0800;
	MEMTEST[197]=16'h000F;	
	//END
	
//	end
//	else if(SW[0])begin
	
	
	
	
	//MEMTEST[]=16'h
	//MEMTEST[]=16'h
	//MEMTEST[28]=16'h0800;
	//MEMTEST[29]=16'h0000;*/
	
	//test Calculator
	/*MEMTEST2[0]=16'h2002;
	MEMTEST2[1]=16'h0004;

	MEMTEST2[2]=16'h3C04;
	MEMTEST2[3]=16'h0043;
	
	MEMTEST2[4]=16'h3C04;
	MEMTEST2[5]=16'h0161;
	
	MEMTEST2[6]=16'h3C04;
	MEMTEST2[7]=16'h026C;

	MEMTEST2[8]=16'h3C04;
	MEMTEST2[9]=16'h0363;

	MEMTEST2[10]=16'h22A0;
	MEMTEST2[11]=16'h0041;

	MEMTEST2[12]=16'h22C0;
	MEMTEST2[13]=16'h0053;
	
	MEMTEST2[14]=16'h3C04;
	MEMTEST2[15]=16'h0661;
	
	MEMTEST2[16]=16'h3C04;
	MEMTEST2[17]=16'h0774;
	
	MEMTEST2[18]=16'h3C04;
	MEMTEST2[19]=16'h0865;
	
	MEMTEST2[20]=16'h3C04;
	MEMTEST2[21]=16'h8000;
	
	
	
	
	//first variable
	MEMTEST2[22]=16'h2402;
	MEMTEST2[23]=16'h0005;
	
	MEMTEST2[24]=16'h0000;
	MEMTEST2[25]=16'h0000;
	
	MEMTEST2[26]=16'h0000;
	MEMTEST2[27]=16'h000C;
	
	MEMTEST2[28]=16'h0000;
	MEMTEST2[29]=16'h0000;
	
	MEMTEST2[30]=16'h0060;
	MEMTEST2[31]=16'h8821;
	
	MEMTEST2[32]=16'h0000;
	MEMTEST2[33]=16'h0000;
	
	/*MEMTEST2[34]=16'hAFB1;
	MEMTEST2[35]=16'h0160;
	
	MEMTEST2[36]=16'h0000;
	MEMTEST2[37]=16'h0000;
	MEMTEST2[38]=16'h0800;
	MEMTEST2[39]=16'h0015;
	
	
	//operation
	MEMTEST2[34]=16'h2002;
	MEMTEST2[35]=16'h0008;
	MEMTEST2[36]=16'h0000;
	MEMTEST2[37]=16'h000C;
	MEMTEST2[38]=16'h0000;
	MEMTEST2[39]=16'h0000;
	MEMTEST2[40]=16'h0060;
	MEMTEST2[41]=16'h9021;
	
	MEMTEST2[42]=16'h0000;
	MEMTEST2[43]=16'h0000;
	
	/*MEMTEST2[44]=16'hAFB2;
	MEMTEST2[45]=16'h0160;
	
	MEMTEST2[46]=16'h0000;
	MEMTEST2[47]=16'h0000;
	MEMTEST2[48]=16'h0800;
	MEMTEST2[49]=16'h0015;
	

	//second variable
	MEMTEST2[44]=16'h2002;
	MEMTEST2[45]=16'h0005;
	MEMTEST2[46]=16'h0000;
	MEMTEST2[47]=16'h000C;
	MEMTEST2[48]=16'h0040;
	MEMTEST2[49]=16'h9820;
	
	
	//branch if a
	MEMTEST2[50]=16'h22B2;
	MEMTEST2[51]=16'h0003;
	MEMTEST2[52]=16'h0000;
	MEMTEST2[53]=16'h0000;
	//branch is s
	MEMTEST2[54]=16'h22D2;
	MEMTEST2[55]=16'h0003;
	MEMTEST2[56]=16'h0000;
	MEMTEST2[57]=16'h0000;
	//calculate a
	MEMTEST2[58]=16'h0232;
	MEMTEST2[59]=16'hA020;
	MEMTEST2[60]=16'h0800;
	MEMTEST2[61]=16'h0021;
	//calculate s
	MEMTEST2[62]=16'h0233;
	MEMTEST2[63]=16'hA022;
	MEMTEST2[64]=16'h0800;
	MEMTEST2[65]=16'h0021;
	//results
	MEMTEST2[66]=16'h0000;
	MEMTEST2[67]=16'h0000;
	MEMTEST2[68]=16'hAFB4;
	MEMTEST2[69]=16'h0160;
	MEMTEST2[70]=16'h0800;
	MEMTEST2[71]=16'h0021;
	
	/*MEMTEST2[72]=16'h0000;
	MEMTEST2[73]=16'h000C;
	
	MEMTEST2[74]=16'h0800;
	MEMTEST2[75]=16'h0022;
	
	MEMTEST2[76]=16'h0000;
	MEMTEST2[77]=16'h0000;*/
	//var1
	MEMTEST2[0]=16'h0000;
	MEMTEST2[1]=16'h0000;
	
	MEMTEST2[2]=16'h0000;
	MEMTEST2[3]=16'h000C;
	
	MEMTEST2[4]=16'h0000;
	MEMTEST2[5]=16'h0000;
	
	MEMTEST2[6]=16'h0003;
	MEMTEST2[7]=16'h8021;
	
	MEMTEST2[8]=16'h0800;
	MEMTEST2[9]=16'h0000;
	
	
	
	
	//var2
	MEMTEST3[0]=16'h0000;
	MEMTEST3[1]=16'h0000;
	
	MEMTEST3[2]=16'h0000;
	MEMTEST3[3]=16'h000C;
	
	MEMTEST3[4]=16'h0000;
	MEMTEST3[5]=16'h0000;
	
	MEMTEST3[6]=16'h0003;
	MEMTEST3[7]=16'h8821;
	
	MEMTEST3[8]=16'h0800;
	MEMTEST3[9]=16'h0000;
	
	//add
	MEMTEST4[0]=16'h0000;
	MEMTEST4[1]=16'h0000;
	
	MEMTEST4[2]=16'h0211;  //addu s2 s1 s0
	MEMTEST4[3]=16'h9021;
		
	MEMTEST4[4]=16'h2413;
	MEMTEST4[5]=16'h002B;
	
	MEMTEST4[6]=16'h2609;
	MEMTEST4[7]=16'h0030;
	
	MEMTEST4[8]=16'h262A;
	MEMTEST4[9]=16'h0030;
	
	MEMTEST4[10]=16'hAFA0;
	MEMTEST4[11]=16'h0050;
	
	MEMTEST4[12]=16'hAFA9;
	MEMTEST4[13]=16'h0100;
	
	MEMTEST4[14]=16'hAFB3;
	MEMTEST4[15]=16'h0150;
	
	MEMTEST4[16]=16'hAFAA; //SW s2 (sp) 0x01A0
	MEMTEST4[17]=16'h01A0;
	
	MEMTEST4[18]=16'hAFA0;
	MEMTEST4[19]=16'h0050;
	
	MEMTEST4[20]=16'h2652;
	MEMTEST4[21]=16'h0030;
	
	MEMTEST4[22]=16'hAFA0;
	MEMTEST4[23]=16'h0050;
	
	MEMTEST4[24]=16'hAFB2;
	MEMTEST4[25]=16'h01F0;
	
	MEMTEST4[26]=16'hAFA0;
	MEMTEST4[27]=16'h0050;
	
	MEMTEST4[28]=16'h0800; //loop to PC 0
	MEMTEST4[29]=16'h0000;
	
	//end	
	
	//sub
	MEMTEST5[0]=16'h0000;
	MEMTEST5[1]=16'h0000;
	
	MEMTEST5[2]=16'h0211;
	MEMTEST5[3]=16'h9023;
		
	MEMTEST5[4]=16'h2413;
	MEMTEST5[5]=16'h002D;
	
	MEMTEST5[6]=16'h2609;
	MEMTEST5[7]=16'h0030;
	
	MEMTEST5[8]=16'h262A;
	MEMTEST5[9]=16'h0030;
	
	MEMTEST5[10]=16'hAFA0;
	MEMTEST5[11]=16'h0050;
	
	MEMTEST5[12]=16'hAFA9;
	MEMTEST5[13]=16'h0100;
	
	MEMTEST5[14]=16'hAFB3;
	MEMTEST5[15]=16'h0150;
	
	MEMTEST5[16]=16'hAFAA;
	MEMTEST5[17]=16'h01A0;
	
	MEMTEST5[18]=16'hAFA0;
	MEMTEST5[19]=16'h0050;
	
	MEMTEST5[20]=16'h2652;
	MEMTEST5[21]=16'h0030;
	
	MEMTEST5[22]=16'hAFA0;
	MEMTEST5[23]=16'h0050;
	
	MEMTEST5[24]=16'hAFB2;
	MEMTEST5[25]=16'h01F0;
	
	MEMTEST5[26]=16'hAFA0;
	MEMTEST5[27]=16'h0050;
	
	MEMTEST5[28]=16'h0800;
	MEMTEST5[29]=16'h0000;
	
	//mul
	MEMTEST6[0]=16'h0000;
	MEMTEST6[1]=16'h0000;
	
	MEMTEST6[2]=16'h0211;
	MEMTEST6[3]=16'h0019;
	
	MEMTEST6[4]=16'h0000;
	MEMTEST6[5]=16'h9812;
	
	MEMTEST6[6]=16'h2413;
	MEMTEST6[7]=16'h002A;
	
	MEMTEST6[8]=16'h2609;
	MEMTEST6[9]=16'h0030;
	
	MEMTEST6[10]=16'h262A;
	MEMTEST6[11]=16'h0030;
	
	MEMTEST6[12]=16'hAFA0;
	MEMTEST6[13]=16'h0050;
	
	MEMTEST6[14]=16'hAFA9;
	MEMTEST6[15]=16'h0100;
	
	MEMTEST6[16]=16'hAFB3;
	MEMTEST6[17]=16'h0150;
	
	MEMTEST6[18]=16'hAFAA;
	MEMTEST6[19]=16'h01A0;
	
	MEMTEST6[20]=16'hAFA0;
	MEMTEST6[21]=16'h0050;
	
	MEMTEST6[22]=16'h2652;
	MEMTEST6[23]=16'h0030;
	
	MEMTEST6[24]=16'hAFA0;
	MEMTEST6[25]=16'h0050;

	MEMTEST6[26]=16'hAFB2;
	MEMTEST6[27]=16'h01F0;
	
	MEMTEST6[28]=16'hAFA0;
	MEMTEST6[29]=16'h0050;
	
	MEMTEST6[30]=16'h0800;
	MEMTEST6[31]=16'h0014;
	
	//ascii table
	MEMTEST7[0]=16'h27BC;	//addiu gp sp 0x0100
	MEMTEST7[1]=16'h0100;
	
	MEMTEST7[2]=16'h0000;
	MEMTEST7[3]=16'h0000;
	
	MEMTEST7[4]=16'h2410;
	MEMTEST7[5]=16'h0015;
	
	MEMTEST7[6]=16'hAFA0;
	MEMTEST7[7]=16'h0050;
	
	MEMTEST7[8]=16'hAF88;
	MEMTEST7[9]=16'h0000;
	
	MEMTEST7[10]=16'hAFA0;
	MEMTEST7[11]=16'h0050;
	
	MEMTEST7[12]=16'h2508;
	MEMTEST7[13]=16'h0001;
	
	MEMTEST7[14]=16'h279C;
	MEMTEST7[15]=16'h0001;
	
	MEMTEST7[16]=16'h2529;
	MEMTEST7[17]=16'h0001;
	
	MEMTEST7[18]=16'h1609;
	MEMTEST7[19]=16'h0002;
	
	MEMTEST7[20]=16'h0000;
	MEMTEST7[21]=16'h0000;
	
	MEMTEST7[22]=16'h0800;
	MEMTEST7[23]=16'h0002;
	
	MEMTEST7[24]=16'h0000;
	MEMTEST7[25]=16'h0000;
	
	MEMTEST7[26]=16'h0390;
	MEMTEST7[27]=16'hE023;
	
	MEMTEST7[28]=16'h279C;
	MEMTEST7[29]=16'h0050;
	
	MEMTEST7[30]=16'h0800;
	MEMTEST7[31]=16'h0002;
	
	//color in 
	MEMTEST8[0]=16'h0000;
	MEMTEST8[1]=16'h0000;
	
	MEMTEST8[2]=16'h0310;
	MEMTEST8[3]=16'hC021;
	
	MEMTEST8[4]=16'h0018;
	MEMTEST8[5]=16'hC040;
	
	MEMTEST8[6]=16'h0000;
	MEMTEST8[7]=16'h0000;
	
	MEMTEST8[8]=16'h0800;
	MEMTEST8[9]=16'h0003;
	
	//color out
	
	MEMTEST9[0]=16'h0000;
	MEMTEST9[1]=16'h0000;
	
	MEMTEST9[2]=16'hAFB8;
	MEMTEST9[3]=16'h0000;
	
	MEMTEST9[4]=16'hAFB8;
	MEMTEST9[5]=16'h0000;
	
	MEMTEST9[6]=16'hAFB8;
	MEMTEST9[7]=16'h0000;

	MEMTEST9[8]=16'h0000;
	MEMTEST9[9]=16'h0000;
	
	MEMTEST9[10]=16'h0800;
	MEMTEST9[11]=16'h0000;
	
	count=0;



end

reg clk2=0;

assign i=inst;
assign clk=clk2;
assign key=KEY[3];


wire [31:0] v0, a0, a1;
wire IRQ;
wire IACK;
wire wr;

MIPSCPU DE1(
.inst			(i),
.clk			(mipsClk),
.din			(datain),
.dout			(dataout),
.a				(addr),
.wr			(wr),
.iack			(IACK),
.v0			(v0),
.a0			(a0),
.KEY			(KEY[2]),
.irq			(IRQ),
.ledg			(ledg),
.LEDR			(ledr),
.mipsIn		(mipsIn),
.rck			(rck)
);	
///debugging
wire ledg;
wire ledg1;
assign LEDG[3:0]=ledg;
wire mipsClk;
//assign LEDG[1]=ledg1;
//end debug	


wire[16:0] EPC;
wire[31:0] SR, CR;
wire[31:0] V0;
wire[15:0] A01, A02;
wire[15:0] A11, A12;
wire[31:0] mipsIn;

wire[17:0] ledr;
assign LEDR=ledr;
wire rck;

	
cpo COPO(
.CLK			(clk2),
.EPC			(EPC),
.SR			(SR),
.CR			(CR),
.IACK			(IACK),
.IRQ			(IRQ),
.v0			(v0),
.a0			(a0),
.V0			(V0),
.A01			(A01),
.A02			(A02),
.a1			(a1),
.A11			(A11),
.A12			(A12),
.kclk			(kready),
.ledg			(ledg1),
.kB			(kbin),
.RPC			(RPC),
.mipsIn		(mipsIn),
.rck			(RCK),
.mipsClk		(mipsClk),
.SW			(SW[17])
);

wire [6:0] HEX7;
wire [6:0] HEX6;
wire [6:0] HEX5;
wire [6:0] HEX4;

reg exec=0;




always@(posedge CLOCK_50)begin


	clk2<=~clk2;
end
/*reg mipsClk;
always@(posedge clk)begin
mipsClk<=~mipsClk;
end*/

endmodule

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



module HEX_out(in, HEX0);
input [3:0] in;
output [6:0] HEX0;
assign HEX0=hex0;
reg [6:0] 	hex0;
always @*
	case (in)
		4'b0000 : begin      	//Hexadecimal 0
			hex0 = 7'b0000001;
			end
		4'b0001 : begin   		//Hexadecimal 1
			hex0 = 7'b1001111;
			end
		4'b0010 : begin 		// Hexadecimal 2
			hex0 = 7'b0010010;
			end
		4'b0011 : begin		// Hexadecimal 3
			hex0 = 7'b0000110;
			end
		4'b0100 :begin		// Hexadecimal 4
			hex0 = 7'b1001100;
			end
		4'b0101 :begin		// Hexadecimal 5
			hex0 = 7'b0100100; 
			end	
		4'b0110 :begin		// Hexadecimal 6
			hex0 = 7'b0100000;
			end
		4'b0111 :begin		// Hexadecimal 7
			hex0 = 7'b0001111;
			end
		4'b1000 : begin    		 //Hexadecimal 8
			hex0 = 7'b0000000;
			end
		4'b1001 :  begin  		//Hexadecimal 9
			hex0 = 7'b0000100;
			end
		4'b1010 :  begin		// Hexadecimal A
			hex0 = 7'b0001000; 
			end
		4'b1011 : begin		// Hexadecimal B
			hex0 = 7'b1100000;
			end
		4'b1100 :begin		// Hexadecimal C
			hex0 = 7'b0110001;
			end
		4'b1101 :begin		// Hexadecimal D
			hex0 = 7'b1000010;
			end
		4'b1110 :begin		// Hexadecimal E
			hex0 = 7'b0110000;
			end
		4'b1111 :begin		// Hexadecimal F
			hex0 = 7'b0111000;
			end
	endcase
	 
endmodule




module cpo(CLK, EPC, SR, CR, IACK, IRQ, v0, a0, V0, A01, A02, a1, A11, A12, kclk, ledg, kB, RPC, mipsIn, rck, mipsClk, SW);
input IRQ;
input CLK;
input [7:0] kB;
input [31:0] v0, a0, SR, CR, a1;
input [16:0] EPC;
input kclk;
output IACK;
output [31:0] V0;
output [15:0] A01, A02, A11, A12;
output [16:0] RPC;
output [31:0] mipsIn;
reg [31:0] mIn;
input SW;

assign mipsIn=mIn;

reg [31:0] scode;
reg [31:0] string;
reg [15:0] addr;
reg [7:0] char=0;


assign V0=scode;
assign A01=string[15:0];
reg gets=0;
reg sel=1;
//assign A02[7:0]=(sel) ? string[23:16] : char;
assign A02[7:0]=char;

assign A11=addr;
reg[7:0] charPos;
//assign A02[15:8]=(sel) ? string[31:24] : charPos;
assign A02[15:8]=charPos;

//wire irq;
output mipsClk;
reg mclk;

assign mipsClk=mclk;

output ledg;
reg LEDG=1'b0;

assign ledg=LEDG;
reg bS=0;

reg iack=1'b0;
assign IACK=iack;
reg [16:0] epc;
reg [31:0] sr, cr;
reg intf=0;
input rck;
reg ackf=0;
reg irq=0;

always @(posedge CLK) begin

	if(SW&&~irq)begin
	mclk=~mclk;
	end
	else if(~SW||irq)begin
	mclk=mclk;
	end
	
//	if(irq) begin
		//scode=v0;
		//string=a0;
		epc=EPC;
		sr=SR;
		cr=CR;
		//sel=0;
		//iack=1;
	//end
		/*if(scode==32'h0000000C)begin
			string[31:24]=string[31:24]+1'b1;
		end*/
		//if(IRQ==1)begin
			/*if(scode==4) begin
				string=a0;
				sel=1;
				/*if(rck!=0)begin
					//iack=1'b1;
					rck<=~rck;
				end
				else begin
					//iack=1'b0;
					rck<=~rck;
				end
			end
			else if(scode==1)begin
				string[31:16]=a0[15:0];
				sel=1;
				/*if(rck!=0)begin
					//iack=1'b1;
					rck<=~rck;
				end
				else begin
					//iack=1'b0;
					rck<=~rck;
				end
			end
			
			else if (scode==5) begin
				sel=0;
			end*/
		//mIn=kB;
	
		if(kclk)begin		
			mIn=kB-16'h30;
			//sel=0;	
			iack=1'b1;	
			//if(irq)begin
				irq=1'b0;
			//end
		end
	
		else if(~kclk)begin

			if(~IRQ)begin
				iack=1'b0;
				intf=1'b0;
				irq=1'b0;
			end
			if(IRQ)begin
				if(iack==0)begin
				irq=1'b1;
				end
				/*else if (iack==1)begin
				irq=0;
				end*/
				
			end
			
			
			//LEDG=1'b0;
			//sel=1;
		end
	

		
	
	
end

/*always @(posedge kclk) begin
		iack=1'b1;
		LEDG=1'b1;
		//iack=1'b0;
		iack=1'b0;
	end
	*/
always @(posedge kclk)begin

	/*if(scode==4)begin
		charPos=a0[31:24];
	end
	else begin*/
	
		if(kB!=8)begin
			if(bS==0)begin
				char=kB;
				charPos=charPos+1'b1;
			end
			else begin
				char=kB;
				//charPos=charPos+1'b1;
				bS=1'b0;;
			end
			
		end
		else begin
			if(bS==0)begin
				char=0;
				bS=1'b1;
			end
			else begin
				char=0;
				charPos=charPos-1'b1;
			end
		end
	//end
		
	
	
	
		//string=a0;
end


endmodule

module MIPSCPU(inst,clk,KEY, din,dout,a, wr, irq, iack, a0, v0, a1, ledg, LEDR, mipsIn, rck);

//FUNCT
	parameter add=6'h20;
	parameter sub=6'h22;
	parameter div=6'h1a;
	parameter mul=6'h18;	
	parameter addu=6'h21;
	parameter jr=6'h8;
	parameter slt=6'h2a;
	parameter sltu=6'h2b;
	parameter sll=6'h00;
	parameter srl=6'h02;
	parameter subu=6'h23;
	parameter multu=6'h19;
	parameter divu=6'h1b;
	parameter syscall=6'h0c;
	parameter NOR=6'h27;
	parameter OR=6'h25;
	parameter XOR=6'h38;
	parameter MFHI=6'b010000;
	parameter MFLO=6'b010010;


	//OPCODE
	parameter addi=6'h8;
	parameter lw=6'h23;
	parameter sw=6'h2b;
	parameter addiu=6'h9;
	parameter bnq=6'h4; 
	parameter lui=6'hf;
	parameter beq=6'h5;
	parameter lbu=6'h24;
	parameter lhu=6'h25;
	parameter ll=6'h30;
	parameter ori=6'hd;
	parameter slti=6'ha;
	parameter sltiu=6'hb;
	parameter sb=6'h28;
	parameter sc=6'h38;
	parameter sh=6'h29;
	parameter xori=6'he;
	parameter andi=6'hc;

	parameter float=6'h11;
	
	//j-opcode
	parameter j=6'h2;
	parameter jal=6'h3;
	
	//misc
	parameter s=8'd32;

	input [15:0]inst;
	input clk;
	input KEY;
	//output nxt_inst;
	input [31:0] din;
	output [31:0]dout;
	output [17:0]a;
	output wr;
	output [17:0] LEDR;
	
	output[3:0] ledg;
	reg[3:0] LEDG=4'b0;
	assign ledg=LEDG;

	output irq;
	output [31:0] v0, a0, a1;
	
	reg write;
	reg nxt;
	
	reg IACK;
	
	assign wr=write;
	assign nxt_inst=nxt;
	

	reg [31:0] inst_full=0;
	
	//decoded instructions
	reg [5:0] opcode,funct;
	reg [4:0] RS,RT,RD,shamt;
	reg [4:0] fmt,FT,FS,FD; //floating point
	reg [15:0] immd;
	reg signed[15:0] simmd;
	reg [25:0] jaddr;
	reg [31:0] dataout;
	reg [31:0] rt, rs, rd;
	reg [31:0] ft, fs, fd;
	
	reg  sums;
	reg [15:0] diff;
	reg [30:23] sume;
	reg [23:0] summ;
							
	reg [7:0] expl, exps;
	reg [23:0] manl, mans;
	
	reg signed [31:0] srt, srs, srd;
	
	reg intack=1'b0;
	
	//registers
	reg [31:0] R [31:0];
	reg [16:0] PC, EPC, CR;
	reg [31:0] HI, LO;
	
	assign LEDR[16:0]  = PC;
	
	reg [31:0] FR [31:0];

	reg [4:0] state;
	
	
	//for reading and writing memory
	reg [17:0] addr;
	wire[31:0] dout;
	wire[17:0] a;
	assign a=addr;
	assign dout=dataout;
	assign PCa=PC;
	
	reg IRQ=0;
	assign irq=IRQ;
	
	assign v0=R[2];
	assign a0=R[4];
	assign a1=R[5];
	
	reg clk2;
	
		//initialize registers to 0
	reg[5:0] k;
	initial begin
		for(k=0;k<30;k=k+1)begin
			R[k]=0;	
		end
		R[0]=32'h00000000;
		
		R[2]=32'h00000000;
		R[8]=32'h00000000;
		R[23]=32'h00000008;
		R[28]=32'h00000000;
		R[29]=32'h0003F69F;
		R[30]=32'h00000001;
		R[31]=32'h00000001;
		
		state=0;
		addr=0;
		PC=0;
		IRQ=0;
	end	
	
	input iack;
	wire IR;
	output rck;
	reg RCK;
	assign rck=RCK;
	
	input[31:0] mipsIn;

	
	//reg ir = IR;
	
	/*always@(posedge clk)begin
		clk2=~clk2;
	end*/	
	reg RET=1'b0;

	
		always@(posedge clk)begin
				
				R[0]=32'h00000000;
			/*if(IRQ) begin
				
				if(iack) begin
					R[3]	=mipsIn;
					LEDG=~LEDG;
					inst_full=inst_full; 	
					PC=PC;
					IRQ=0;
				end
			end
		else if (~IRQ) begin
			//LEDG<=0;*/
			/*if(KEY)begin
				PC=0;
			end
			else begin*/
			//if(PC<158) begin
			R[3]=mipsIn;
			if(~KEY)begin
			PC=0;
			R[3]=mipsIn;
			IRQ=0;
			end
			case(state)
			0:begin
				IRQ=0;
				
				addr={PC,1'b0};
				state=9;
				write=0;
				
			end
			9:begin
				state=6;
			end
			6:begin
				inst_full[31:16]=inst;
				state=1;
			end
			1:begin
				addr={PC,1'b1};
				state=7;
			//nxt<=0;
			end
			7:begin
				state=8;
			end
			8:begin
				inst_full[15:0]=inst;
				state=2;
			end
			2:begin
			
			//decode
				opcode <= inst_full[31:26];
				RS <= inst_full[25:21];
				RT <= inst_full[20:16];
				RD <= inst_full[15:11];
				shamt <= inst_full[10:6];
				funct <= inst_full[5:0];
				immd <= inst_full[15:0];
				simmd = inst_full[15:0];
				jaddr <= inst_full[25:0];

				rt=R[RT];
				rd=R[RD];
				rs=R[RS];
				
				ft=R[FT];
				fd=R[FD];
				fs=R[FS];
			
			//signed values 
				//simmd=immd;
				srs=rs;
				srt=rt;
				srd=rd;
				

					case(opcode)
			//start here
					0:begin
						case(funct)
							add:begin
							srs=rs;
							srt=rt;
							rd=srs+srt;
							state = 5;
							end
							subu:begin
							R[RD]=R[RS]-R[RT];
							state = 5;
							end
							sub:begin
							srs=rs;
							srt=rt;
							rd=srs-srt;
							state = 5;
							end
							divu:begin
							HI=R[RS]%R[RT];
							LO=R[RS]/R[RT];
							state = 5;
							end
							div:begin
							srs=rs;
							srt=rt;
							rt=srs%srt;
							rd=srs/srt;
							state = 5;
							end
							multu:begin
							LO=R[RS]*R[RT];
							state = 5;
							end
							mul:begin
							srs=rs;
							srt=rt;
							LO=srs*srt;
							state = 5;
							end
							addu:begin
							R[RD]=R[RS]+R[RT];
							state = 5;
							//R[RD]=rd;
							end
							jr:begin
							PC=rs;
							state = 5;
							end
							NOR:begin
							R[RD]=~(R[RS]|R[RT]);
							state = 5;
							end
							OR:begin
							R[RD]=R[RS]|R[RT];
							state = 5;
							end
							slt:begin
							srs=rs;
							srt=rt;
							rd=(srs<srt)?1:0;
							state = 5;
							end
							sltu:begin
							R[RD]=(R[RS]<R[RT])?1:0;
							state = 5;
							end
							sll:begin
							R[RD]=R[RT]<<shamt;
							/*if(inst_full[25:6]begin
								inst_full=0;
								PC=PC+1;
								state=0;
							end*/
							
							state = 5;
							end
							srl:begin
							R[RD]=R[RT]>>shamt;
							state = 5;
							end
							XOR:begin
							R[RD]=R[RT]^R[RS];
							state = 5;
							end
							syscall:begin
							//R[4]=mipsIn;
							IRQ=1;
							//RCK=0;
							//IACK=0;
							state = 12;
							end
							MFHI:begin
							R[RD]=HI;
							end
							MFLO:begin
							R[RD]=LO;
							end	
							
							
							
							default:begin end
					endcase
						//out1=R[rd];
						//PC=PC+4;
					end
					j:begin
						PC=jaddr;
						inst_full=0;
						state=0;
					end
					jal:begin
						R[31]=PC+8;
						PC=jaddr;	
						state=0;
					end
					beq:begin
						if(rs==rt)begin
							PC=PC+1'b1+simmd;
							inst_full=32'h0;
							state=11;
						end
						else begin
							inst_full=32'h0;
							state=5;
						end
					end
					bnq:begin
						if(rs!=rt)begin
							PC=PC+1'b1+simmd;
							inst_full=32'h0;
							state=11;
						end
						else begin
							inst_full=32'h0;
							state=5;
						end
					end
					addi:begin
					srs=rs;
					simmd=immd;
					srt=srs+simmd;
					R[RT]=srt;
					state=5;
					end
					addiu:begin
					R[RT]=R[RS]+immd;
					//R[RT]=rt;
					state=5;
					end
					andi:begin
					rt=rs&immd;
					R[RT]=rt;
					state = 5;
					end
					lbu:begin
					addr=R[RS]+simmd;
					//R[RT]=din[7:0];
					state = 5;
					end
					lhu:begin	
					addr=R[RS]+simmd;
					//R[RT]=din[15:0];
					state = 5;
					end
					ll:begin
					addr=R[RS]+immd;
					//R[RT]=din;
					state = 5;
					end
					lui:begin
					rt={immd,16'b0};
					R[RT]=rt;
					state = 5;
					end
					lw:begin
					//case(delay)
						//0:begin
							write=0;
							//addr<=R[RS]+simmd;
						//	delay<=1;
					//	end
					//	1:begin
							//R[RT]<=din;
						//	delay<=0;
						//end	
					//endcase
						state=3;
					end
					
					ori:begin
					rt=rs|immd;
					R[RT]=rt;
					state = 5;
					end
					slti:begin
					srt=rt;
					srs=rs;
					simmd=immd;
					srt=(srs<simmd)?1:0;
					R[RT]=srt;
					state = 5;
					end
					sltiu:begin
					rt=(rs<immd)?1:0;
					R[RS]=rs;
					state = 5;
					end
					sb:begin
					rs=rt[7:0];
					R[RS]=rs;
					state = 5;
					end
					sc:begin
					rs=rt;
					//rt=(atomic)?1:0;
					R[RS]=rs;
					state = 5;
					end
					sw:begin
					write=1;
					//addr<=R[RS]+simmd;
					//wr=1;
					state=3;
					//wr=0;
					end
					xori:begin
					rt=rs^immd;
					R[RS]=rs;
					state = 5;
					end
					//floating point ops
					float:begin
						case(fmt) 
						//double
						6'h11:begin
							case(funct)
							6'h0:begin
							//{F[fd],F[fd+1]}={F[fs],F[fs+1]}+{F[fs],F[fs+1]};
							end
							6'h1:begin
							//{F[fd],F[fd+1]}={F[fs],F[fs+1]}-{F[fs],F[fs+1]};
							end
							6'h2:begin
							//{F[fd],F[fd+1]}={F[fs],F[fs+1]}*{F[fs],F[fs+1]};
							end
							6'h3:begin
							//{F[fd],F[fd+1]}={F[fs],F[fs+1]}/{F[fs],F[fs+1]};
							end
							default begin end
							endcase
						
						end
						//single
						6'h10:begin
							case(funct)
							6'h0:begin
								//F[fd]=F[fs]+F[ft];

								
								
								if(FR[FS][30:23]>FR[FT][30:23])begin
									expl=FR[FS][30:23];
									exps=FR[FT][30:23];
									manl[23]=1;
									manl[22:0]=FR[FS][22:0];
									mans[23]=0;
									mans[22:0]=FR[FT][22:0];
								end
								else begin
									expl=FR[FT][30:23];
									exps=FR[FS][30:23];
									mans[23]=1;
									mans[22:0]=FR[FS][22:0];
									manl[23]=0;
									manl[22:0]=FR[FT][22:0];
								end
								
								
								diff=expl-exps;
								mans=mans<<diff;
								//summ=manl+mans;
								if(summ[23]==1)begin
									sume=manl+1;
								end
								else begin
									sume=manl;
								end
								summ=manl+mans;
								
								FR[FD][30:22]=sume;
								FR[FD][22:0]=summ[22:0];
								
								
							
							end
							6'h1:begin
								//F[fd]=F[fs]-F[ft];
								
								
								
								if(FR[FS][30:23]>FR[FT][30:23])begin
									expl=FR[FS][30:23];
									exps=FR[FT][30:23];
									manl[23]=1;
									manl[22:0]=FR[FS][22:0];
									mans[23]=0;
									mans[22:0]=FR[FT][22:0];
								end
								else begin
									expl=FR[FT][30:23];
									exps=FR[FS][30:23];
									mans[23]=1;
									mans[22:0]=FR[FS][22:0];
									manl[23]=0;
									manl[22:0]=FR[FT][22:0];
								end
								
								
								diff=expl-exps;
								mans=mans<<diff;
								//summ=manl+mans;
								if(summ[23]==1)begin
									sume=manl+1;
								end
								else begin
									sume=manl;
								end
								summ=manl-mans;
								
								FR[FD][30:22]=sume;
								FR[FD][22:0]=summ[22:0];
								
								
							end
							6'h2:begin


								if(FR[FS][30:23]>FR[FT][30:23])begin
									expl=FR[FS][30:23];
									exps=FR[FT][30:23];
									manl[23]=1;
									manl[22:0]=FR[FS][22:0];
									mans[23]=0;
									mans[22:0]=FR[FT][22:0];
								end
								else begin
									expl=FR[FT][30:23];
									exps=FR[FS][30:23];
									mans[23]=1;
									mans[22:0]=FR[FS][22:0];
									manl[23]=0;
									manl[22:0]=FR[FT][22:0];
								end
								
								summ=manl*mans;
								sume=expl+exps;
								sume=sume-127;
								
								if(summ[23]==1)begin
									sume=manl+1;
								end
								else begin
									sume=manl;
								end
								
								FR[FD][30:22]=sume;
								FR[FD][22:0]=summ[22:0];
								
							end
							6'h3:begin
								//F[fd]=F[fs]/F[ft];
								


								if(FR[FS][30:23]>FR[FT][30:23])begin
									expl=FR[FS][30:23];
									exps=FR[FT][30:23];
									manl[23]=1;
									manl[22:0]=FR[FS][22:0];
									mans[23]=0;
									mans[22:0]=FR[FT][22:0];
								end
								else begin
									expl=FR[FT][30:23];
									exps=FR[FS][30:23];
									mans[23]=1;
									mans[22:0]=FR[FS][22:0];
									manl[23]=0;
									manl[22:0]=FR[FT][22:0];
								end
								
								summ=manl/mans;
								expl=expl+127;
								sume=expl-exps;
								
								if(summ[23]==1)begin
									sume=manl+1;
								end
								else begin
									sume=manl;
								end
								
								FR[FD][30:22]=sume;
								FR[FD][22:0]=summ[22:0];
							end
							
							default begin end
							endcase
						
						end
						default:begin end
						endcase
					end
						//PC=PC+4;
						//cl=cl+1;
					
					default:begin end
					endcase
		
			end
			//end here
			3:begin
				addr=R[RS]+simmd;
				state=4;
			end
			4:begin
				state<=10;
			end
			10:begin
				case(opcode)
				sw:begin
					dataout=R[RT];
					state=5;
				end
				lw:begin
					R[RT]=din;
					state=5;
				end
				default:begin
					state=5;
				end
				endcase
			end
			5:begin
			R[RD]=rd;
			//write=0;
			inst_full=0;
			PC=PC+1'b1;
			state=0;
				
			//nxt<=1;
			end
			11:begin		//branch delay
			inst_full=0;
				//PC=jaddr[15:0];
				state=0;
			end
			12:begin		//int ret delay
				IRQ=0;
				R[3]=mipsIn;
				inst_full=0;
				state=5;
			end
			
			endcase
		
			
	//	end
	
		/*if(~IACK)begin
			IRQ=0;
		end*/
			
	end

	//assign dout=immd;
	
endmodule

/*
 * This file implements a Character ROM for translating ASCII
 * character codes into 8x16 pixel image.
 *
 * The input to the module is:
 *  1) 8 bit ASCII code,
 *  2) column select, 0..7, which indicates which of the 8 pixels of the character
 *     image will be returned
 *  3) row select, 0..15, which indicates which of the 16 rows of pixels of the character
 *     image will be returned
 */

module pc_vga_8x16 (
	input	[2:0]	col,
	input	[3:0]	row,
	input	[7:0]	ascii,
	output	pixel
);

reg [16383:0] charrom = {
256'h00000000000000000000000000000000000000007e818199bd8181a5817e0000, 256'h000000007effffe7c3ffffdbff7e00000000000010387cfefefefe6c00000000, 
256'h000000000010387cfe7c381000000000000000003c1818e7e7e73c3c18000000, 256'h000000003c18187effff7e3c18000000000000000000183c3c18000000000000, 
256'hffffffffffffe7c3c3e7ffffffffffff00000000003c664242663c0000000000, 256'hffffffffffc399bdbd99c3ffffffffff0000000078cccccccc78321a0e1e0000, 
256'h0000000018187e183c666666663c000000000000e0f070303030303f333f0000, 256'h000000c0e6e767636363637f637f0000000000001818db3ce73cdb1818000000, 
256'h0000000080c0e0f0f8fef8f0e0c080000000000002060e1e3efe3e1e0e060200, 256'h0000000000183c7e1818187e3c18000000000000666600666666666666660000, 
256'h000000001b1b1b1b1b7bdbdbdb7f00000000007cc60c386cc6c66c3860c67c00, 256'h00000000fefefefe0000000000000000000000007e183c7e1818187e3c180000, 
256'h00000000181818181818187e3c18000000000000183c7e181818181818180000, 256'h000000000000180cfe0c1800000000000000000000003060fe60300000000000, 
256'h000000000000fec0c0c00000000000000000000000002466ff66240000000000, 256'h0000000000fefe7c7c3838100000000000000000001038387c7cfefe00000000, 

256'h00000000000000000000000000000000000000001818001818183c3c3c180000, 256'h00000000000000000000002466666600000000006c6cfe6c6c6cfe6c6c000000, 
256'h000018187cc68606067cc0c2c67c18180000000086c66030180cc6c200000000, 256'h0000000076ccccccdc76386c6c38000000000000000000000000006030303000, 
256'h000000000c18303030303030180c00000000000030180c0c0c0c0c0c18300000, 256'h000000000000663cff3c66000000000000000000000018187e18180000000000, 
256'h0000003018181800000000000000000000000000000000007e00000000000000, 256'h000000001818000000000000000000000000000080c06030180c060200000000, 
256'h000000007cc6c6e6f6decec6c67c0000000000007e1818181818187838180000, 256'h00000000fec6c06030180c06c67c0000000000007cc60606063c0606c67c0000, 
256'h000000001e0c0c0cfecc6c3c1c0c0000000000007cc6060606fcc0c0c0fe0000, 256'h000000007cc6c6c6c6fcc0c0603800000000000030303030180c0606c6fe0000, 
256'h000000007cc6c6c6c67cc6c6c67c000000000000780c0606067ec6c6c67c0000, 256'h0000000000181800000018180000000000000000301818000000181800000000, 
256'h00000000060c18306030180c06000000000000000000007e00007e0000000000, 256'h000000006030180c060c183060000000000000001818001818180cc6c67c0000, 

256'h000000007cc0dcdededec6c6c67c000000000000c6c6c6c6fec6c66c38100000, 256'h00000000fc666666667c666666fc0000000000003c66c2c0c0c0c0c2663c0000, 
256'h00000000f86c6666666666666cf8000000000000fe6662606878686266fe0000, 256'h00000000f06060606878686266fe0000000000003a66c6c6dec0c0c2663c0000, 
256'h00000000c6c6c6c6c6fec6c6c6c60000000000003c18181818181818183c0000, 256'h0000000078cccccc0c0c0c0c0c1e000000000000e666666c78786c6666e60000, 
256'h00000000fe6662606060606060f0000000000000c3c3c3c3c3dbffffe7c30000, 256'h00000000c6c6c6c6cedefef6e6c60000000000007cc6c6c6c6c6c6c6c67c0000, 
256'h00000000f0606060607c666666fc000000000e0c7cded6c6c6c6c6c6c67c0000, 256'h00000000e66666666c7c666666fc0000000000007cc6c6060c3860c6c67c0000, 
256'h000000003c18181818181899dbff0000000000007cc6c6c6c6c6c6c6c6c60000, 256'h00000000183c66c3c3c3c3c3c3c30000000000006666ffdbdbc3c3c3c3c30000, 
256'h00000000c3c3663c18183c66c3c30000000000003c181818183c66c3c3c30000, 256'h00000000ffc3c16030180c86c3ff0000000000003c30303030303030303c0000, 
256'h0000000002060e1c3870e0c080000000000000003c0c0c0c0c0c0c0c0c3c0000, 256'h000000000000000000000000c66c38100000ff00000000000000000000000000, 	
	 
256'h000000000000000000000000001830300000000076cccccc7c0c780000000000, 256'h000000007c666666666c786060e00000000000007cc6c0c0c0c67c0000000000, 
256'h0000000076cccccccc6c3c0c0c1c0000000000007cc6c0c0fec67c0000000000, 256'h00000000f060606060f060646c3800000078cc0c7ccccccccccc760000000000, 
256'h00000000e666666666766c6060e00000000000003c1818181818380018180000, 256'h003c66660606060606060e000606000000000000e6666c78786c666060e00000, 
256'h000000003c181818181818181838000000000000dbdbdbdbdbffe60000000000, 256'h00000000666666666666dc0000000000000000007cc6c6c6c6c67c0000000000, 
256'h00f060607c6666666666dc0000000000001e0c0c7ccccccccccc760000000000, 256'h00000000f06060606676dc0000000000000000007cc60c3860c67c0000000000, 
256'h000000001c3630303030fc30301000000000000076cccccccccccc0000000000, 256'h00000000183c66c3c3c3c300000000000000000066ffdbdbc3c3c30000000000, 
256'h00000000c3663c183c66c3000000000000f80c067ec6c6c6c6c6c60000000000, 256'h00000000fec6603018ccfe0000000000000000000e18181818701818180e0000, 
256'h000000001818181818001818181800000000000070181818180e181818700000, 256'h000000000000000000000000dc7600000000000000fec6c6c66c381000000000};

// Instances
//pc_vga_8x16_00_7F U1 (clk, ascii[6:0], row, col, pixel_row_00_7f);
//pc_vga_8x16_80_FF U2 (clk, ascii[6:0], row, col, pixel_row_80_ff);
assign pixel = charrom[{ascii[7:0], row, ~col}];

endmodule

module KB_read(PS2_CLK, PS2_DAT, dataout, asciiconvert, pos); 
	input PS2_CLK;
	input PS2_DAT;
	input asciiconvert;
	output [7:0] dataout;
	output pos;
	assign pos = posr;
	reg posr;
	reg [10:0] buffer;
	reg [7:0] outbuffer;
	assign dataout = outbuffer;
	reg [3:0] count = 0;
	reg out = 0;
	always@(negedge PS2_CLK) begin
		buffer[count] = PS2_DAT;
		if(count == 10) begin
			count = 0;
			outbuffer = ps2toascii(buffer[8:1]);
			if(out) begin
				posr = ~pos;
				out = 0;
			end
			if(outbuffer == 0) out = 1;
		end else count = count + 1;
	end
	function [7:0] ps2toascii;
		input [7:0] ps2;
		case(ps2)
			8'h1C: ps2toascii = 8'h41;
			8'h32: ps2toascii = 8'h42;
			8'h21: ps2toascii = 8'h43;
			8'h23: ps2toascii = 8'h44;
			8'h24: ps2toascii = 8'h45;
			8'h2B: ps2toascii = 8'h46;
			8'h34: ps2toascii = 8'h47;
			8'h33: ps2toascii = 8'h48;
			8'h43: ps2toascii = 8'h49;
			8'h3B: ps2toascii = 8'h4A;
			8'h42: ps2toascii = 8'h4B;
			8'h4B: ps2toascii = 8'h4C;
			8'h3A: ps2toascii = 8'h4D;
			8'h31: ps2toascii = 8'h4E;
			8'h44: ps2toascii = 8'h4F;
			8'h4D: ps2toascii = 8'h50;
			8'h15: ps2toascii = 8'h51;
			8'h2D: ps2toascii = 8'h52;
			8'h1B: ps2toascii = 8'h53;
			8'h2C: ps2toascii = 8'h54;
			8'h3C: ps2toascii = 8'h55;
			8'h2A: ps2toascii = 8'h56;
			8'h1D: ps2toascii = 8'h57;
			8'h22: ps2toascii = 8'h58;
			8'h35: ps2toascii = 8'h59;
			8'h1A: ps2toascii = 8'h5A;
			8'h45: ps2toascii = 8'h30;
			8'h16: ps2toascii = 8'h31;
			8'h1E: ps2toascii = 8'h32;
			8'h26: ps2toascii = 8'h33;
			8'h25: ps2toascii = 8'h34;
			8'h2E: ps2toascii = 8'h35;
			8'h36: ps2toascii = 8'h36;
			8'h3D: ps2toascii = 8'h37;
			8'h3E: ps2toascii = 8'h38;
			8'h46: ps2toascii = 8'h39;
			8'h5A: ps2toascii = 8'h0A;
			8'h29: ps2toascii = 8'h20;
			8'h66: ps2toascii = 8'h08;
		endcase
	endfunction
endmodule

module LCD_out(line1, line2, LCD_DATA, LCD_RW, LCD_EN, LCD_RS, LCD_ON, LCD_BLON, clk_400hz);
	input [127:0] line1;
	input [127:0] line2;
	reg [3:0] charpos;
	reg [1:0] line = 0;
	reg ln2 = 0;
	input clk_400hz;
	inout [7:0] LCD_DATA;
	output LCD_RW, LCD_EN, LCD_RS, LCD_ON, LCD_BLON;
	
	assign LCD_BLON = 0; // no blon on our lcd
	assign LCD_ON = 1; //turn on the lcd
	
	reg [7:0] dataout;
	
	assign LCD_DATA = LCD_RW ? 8'bzzzzzzzz : dataout;
	
	reg [2:0] cmd;
	
	assign {LCD_EN, LCD_RS, LCD_RW} = cmd;
	
	reg busyflag;
	reg [6:0] state = 2; 
	reg [6:0] statehold;
	// 0-1 flush
	// 2-4 reset
	// 5 Function Set
	// 6 Display Off
	// 7 Display Clear
	// 8 Entry Mode (auto)
	// 32 + (0-15) line 1
	// 32 + (16-31) line 2
	always@(posedge clk_400hz) begin 
		case(state) 
			0: begin
				cmd <= 3'b000;
				state <= 1;
			end
			1: begin
				cmd <= 3'b100;
				state <= statehold;
			end
			2: begin
				cmd <= 3'b100;
				dataout <= 8'h38;
				statehold <= 3;
				state <= 0;
			end
			3: begin
				cmd <= 3'b100;
				dataout <= 8'h38;
				statehold <= 4;
				state <= 0;
			end
			4: begin
				cmd <= 3'b100;
				dataout <= 8'h38;
				statehold <= 5;
				state <= 0;
			end
			5: begin
				cmd <= 3'b100;
				dataout <= 8'h38;
				statehold <= 6;
				state <= 0;
			end
			6: begin
				cmd <= 3'b100;
				dataout <= 8'h08;
				statehold <= 7;
				state <= 0;
			end
			7: begin
				cmd <= 3'b100;
				dataout = 8'h01;
				statehold <= 8;
				state <= 0;
			end
			8: begin
				cmd <= 3'b100;
				dataout <= 8'h0C;
				statehold <= 9;
				state <= 0;
			end
			9: begin
				cmd <= 3'b100;
				dataout <= 8'h06;
				statehold <= 32;
				state <= 0;
			end
			10: begin
				cmd <= 3'b100;
				dataout <= 8'h80;
				state <= 0;
			end
			11: begin
				cmd <= 3'b100;
				state <= 11;
			end
			12: begin
				cmd <= 3'b100;
				dataout <= 8'h68;
				statehold <= 32;
				state <= 0;
			end
			32: begin
				cmd <= 3'b110;
				if(line > 0) begin 
					dataout <= 8'h30;
					charpos <= charpos + 1;
					if(charpos == 7) begin
						charpos <= 0;
						line <= line + 1;
					end
					
				end else begin
					case(charpos)
						0: dataout <= ln2 ? line2[127:120] : line1[127:120];
						1: dataout <= ln2 ? line2[119:112] : line1[119:112];
						2: dataout <= ln2 ? line2[111:104] : line1[111:104];
						3: dataout <= ln2 ? line2[103:96] : line1[103:96];
						4: dataout <= ln2 ? line2[95:88] : line1[95:88];
						5: dataout <= ln2 ? line2[87:80] : line1[87:80];
						6: dataout <= ln2 ? line2[79:72] : line1[79:72];
						7: dataout <= ln2 ? line2[71:64] : line1[71:64];
						8: dataout <= ln2 ? line2[63:56] : line1[63:56];
						9: dataout <= ln2 ? line2[55:48] : line1[55:48];
						10: dataout <= ln2 ? line2[47:40] : line1[47:40];
						11: dataout <= ln2 ? line2[39:32] : line1[39:32];
						12: dataout <= ln2 ? line2[31:24] : line1[31:24];
						13: dataout <= ln2 ? line2[23:16] : line1[23:16];
						14: dataout <= ln2 ? line2[15:8] : line1[15:8];
						15: begin 
							dataout <= ln2 ? line2[7:0] : line1[7:0];
							line <= 1;
							ln2 <= ~ln2;
						end
					endcase
					charpos <= charpos + 1;
				end;
				statehold <= 32;
				state <= 0;
			end
		endcase
	end
endmodule	
