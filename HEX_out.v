module HEX_out(in, HEX0);
input [3:0] in;
output [6:0] HEX0;
assign HEX0=hex0;
reg [6:0] hex0;
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