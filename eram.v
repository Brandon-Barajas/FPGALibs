module eram(GPIO_1, LEDR, SW, address, dataout, datain, we, c25);
	input c25;
	input we;
	
	input [14:0] Address;
	input [7:0] dataout;
	output reg [7:0] dataout;	
	inout [35:0] GPIO_1;
	
	
	
	assign {GPIO_1[19], GPIO_1[17], GPIO_1[15], GPIO_1[13:11], GPIO_1[9:1]} = Address;
	
	always@(posedge c25) dataout <= {GPIO_1[28], GPIO_1[26], GPIO_1[24], GPIO_1[22:20], GPIO_1[18], GPIO_1[16]};
	
	assign {GPIO_1[28], GPIO_1[26], GPIO_1[24], GPIO_1[22:20], GPIO_1[18], GPIO_1[16]} = we ? Outbuff : 8'hzz;
	
	assign GPIO_1[10] = 1'b0; // OutputEnable_N
	assign GPIO_1[14] = 1'b0; // ChipEnable_N
	assign GPIO_1[0] = ~we; //WriteEnable_N
	
	
	
	assign {h3, h2, h1, h0} = Address;
	assign {h7, h6} = Outbuff;
endmodule 