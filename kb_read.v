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