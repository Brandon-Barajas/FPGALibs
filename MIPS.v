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
