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