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