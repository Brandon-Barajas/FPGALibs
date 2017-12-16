module SDCard(cs, sclk, mosi, miso, clk800khz, cmd, cmdready, busy);
	input miso, clk800khz, cmdready;
	input [47:0] cmd;
	output cs, sclk, mosi, busy;
	
	reg busyreg = 1'b1;
	reg clk = 1'b0;
	reg clke = 1'b1;
	reg sclke = 1'b1;
	assign sclk = clk & sclke;
	reg [3:0] clkcount;
	reg [1:0] clkstate = 2'b00;
	assign mosi = cmd[iterator];
	//generate sclk
	always@(posedge clk800khz) begin
		case (clkstate)
			2'b00: begin
				clk <= 1'b0;
				clkstate <= 2'b01;
			end
			2'b01: begin
				clkstate <= 2'b10;
				sclke <= clke;
				clkcount <= 4'h7;
			end
			2'b10: begin
				clk <= 1'b0;
				clkstate <= (&clkcount) ? 2'b01 : 2'b11;
			end
			2'b11: begin
				clk <= 1'b1;
				clkcount <= clkcount + 1'b1;
				clkstate <= 2'b10;
			end
		endcase
	end
	
	reg [5:0] wtime = 6'h00;
	reg [2:0] state = 3'h0;
	reg [8:0] count = 9'h000;
	wire test = &clkcount;
	wire test2 = cmdready & test;
	reg [5:0] iterator = 0;
	always@(posedge clk) begin
		case(state)
			//init 
			0: begin
				clke <= 1'b1; //enable clock
				wtime <= 6'h13; // inverse of 44 = 0x2C
				state <= 2; //jump to state 2
			end
			//sleep
			1: begin
				clke <= 1'b0; //disable clock
				wtime <= 6'h13; //inverse of 44 = 0x2C
				state <= 2; //jump to state 2
			end
			//wait
			2: begin
				wtime <= wtime + 1; //increment timer
				state <= (&wtime) ? 3 : 2; //stay in state as long as timer is not run out
			end
			3: begin
				state <= test ? 4 : 3;
				clke <= test ? 1'b0 : clke;
			end
			//waitcmd
			4: begin
				clke <= 1'b0;
				state <= test2 ? 5:4;
				busyreg <= 1'b0;
			end
			5: begin
				clke <= 1'b1;
				iterator <= 47;
				state <= 6;
				busyreg <= 1'b1;
			end
			6: begin
				iterator <= iterator - 1;
				state <= (iterator > 0) ? 6 : 1;
				clke <= (iterator > 0) ? 1 : 0;
			end
		endcase
	end
	
endmodule