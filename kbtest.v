module kbtest(PS2_CLK, PS2_DAT, CLOCK_50, LEDG);
	input PS2_CLK;
	input PS2_DAT;
	input CLOCK_50;
	output [8:0] LEDG;
	
	reg [25:0] counter = 0;
	always@(posedge CLOCK_50) begin
		counter <= counter + 1;
	end
	
	wire slowclk = counter[25];
	assign LEDG[0] = slowclk;
	
	reg [7:0] kbdata;
	wire [7:0] kbin;
	wire kbpos;
	reg prevpos = 1'b0;
	reg pulse = 1'b0;
	KB_read kb(PS2_CLK, PS2_DAT, kbin, 1'b1, kbpos);
	
	assign LEDG[1] = prevpos;
	assign LEDG[2] = kbpos;
	
	always@(posedge slowclk) begin
		if(pulse == 1'b1) pulse = 1'b0;
		else if(kbpos != prevpos) begin
			pulse = 1'b1;
			prevpos = kbpos;
		end
	end
	
endmodule