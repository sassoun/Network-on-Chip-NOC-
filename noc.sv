module noc (nocif n, crc_if c);

logic [2:0] CurrentState;
logic [2:0] NextState;
logic [7:0] SourceID;
logic [31:0] READ_DATA, READ_DATA1; // read data from data_rd (from crc)
typedef enum logic [6:0] {state1, state2, state3, state4, state5, state6, state7} STATE1;
typedef enum logic [9:0] {sstate1, sstate2, sstate3, sstate4, sstate5, sstate6, sstate7, sstate8, sstate9, sstate10} STATE2;
typedef enum logic [5:0] {ssstate1, ssstate2, ssstate3, ssstate4, ssstate5, ssstate6} STATE3;
typedef enum logic [1:0] {sssstate1, sssstate2} STATE4;

STATE1 STATE_A;
STATE2 STATE_B;
STATE3 STATE_C;
STATE4 STATE_D;

logic [7:0] Addr1_rd, Addr2_rd, Addr3_rd, Addr4_rd; // to store into addr
logic [7:0] Addr1_wr, Addr2_wr, Addr3_wr, Addr4_wr; // to store into addr
logic [7:0] Data1, Data2, Data3, Data4; // to store into data_wr
logic [7:0] test, test1;
logic wr_en, rd_en, full, empty;

parameter IDLE = 3'b000; // it fills the bus, if data comes in, it ignores it
parameter READ = 3'b001;
parameter READ_RESP = 3'b010;
parameter WRITE = 3'b011;
parameter WRITE_RESP = 3'b100;
parameter RESERVED = 3'b101;
parameter MESSAGE = 3'b110;
parameter END = 3'b111;
logic SASSOUN;

//fifo SAS (.wr_en(wr_en), .rst(n.rst), .full(full), .empty(empty), .clk(n.clk), .rd_en(rd_en), .READ_DATA(READ_DATA), .READ_DATA1(READ_DATA1));

always @ (posedge n.clk or posedge n.rst) 
begin

		if (n.rst == 1'b1) //goes through one time in the beginning
			begin	
				CurrentState = IDLE;
				STATE_A = state1;
				STATE_B = sstate1;
				STATE_C = ssstate1;
				STATE_D = sssstate1;
				SASSOUN =1'b1;
				c.Sel = 0;
				c.RW = 0;
				for(int count=0; count<32; count++)  // clear all data from the memory initially
					begin
						READ_DATA[count] =0;
					end 

	

			end

else if (n.rst != 1'b1)
begin

case(CurrentState) // making sure everything loops in this case until it ends

	IDLE:  // IDLE determines what next state will be (read, readresponse, write...)
	begin
		c.RW =0;
		c.Sel =0;

		if ((n.CmdW == 1'b1) && (n.DataW[7:5] == 3'b001)) // when CmdR=1 and code=001 (checking the framing), READ state is enabled
			begin 
				CurrentState = READ; 
			end

		else if ((n.CmdW == 1'b1) && (n.DataW[7:5] == 3'b010)) // when CmdR=1 and code=001 (checking the framing), READ state is enabled
			begin 
				CurrentState = READ_RESP; 
			end

		else if ((n.CmdW == 1'b1) && (n.DataW[7:5] == 3'b011)) // when CmdR=1 and code=011, WRITE state is enabled
			begin 
				CurrentState = WRITE; 
			end

		else if ((n.CmdW == 1'b1) && (n.DataW[7:5] == 3'b100)) // when CmdR=1 and code=011, WRITE state is enabled
			begin 
				CurrentState = WRITE_RESP; 
			end
	end


	READ:
	begin

		if ((n.CmdW == 1'b0) && (SASSOUN == 1'b1))  // after READ happens (CmdW=1), the first CmdW=0 will be your SourceID
			begin
				SourceID [7:0] ={n.DataW};
				SASSOUN =1'b0;
				c.RW =0;
				c.Sel =0;
			end

		case(STATE_A) 
		
				state1:
					begin
						STATE_A = state2; // skip the SourceID
					end

				state2:   			// 1 byte (8 bits)		// READ state
					begin
						Addr1_rd =n.DataW;
						c.RW =0;
						c.Sel =0;
						STATE_A =state3;
					end

				state3:                         // 2 bytes (16 bits)
					begin
						Addr2_rd =n.DataW;
						c.RW =0;
						c.Sel =0;
						STATE_A =state4; 
					end

				state4:                         // 3 bytes (24 bits)
					begin
						Addr3_rd =n.DataW;
						c.RW =0;
						c.Sel =0;
						STATE_A =state5;
					end

				state5:                         // 4 bytes (32 bits)
					begin
						Addr4_rd =n.DataW;
						c.addr [31:0] ={Addr4_rd, Addr3_rd, Addr2_rd, Addr1_rd}; // all 4 bytes of data will be stored into input of CRC
						c.RW =0;
						c.Sel =1;
						READ_DATA [31:0] =c.data_rd [31:0];
						STATE_A =state6;
						rd_en = 1'b0;
						wr_en = 1'b1;
					end

				state6:
					begin	

						if (n.DataW == 8'b0000_1100) // 0C (we need to increment 2 times)
							begin
								test = n.DataW;
								c.addr =(c.addr + 8'b0000_0100); // increment by 4
								c.Sel =1; // everytime we have a new address, make Sel=1
							end

						if (n.DataW == 8'b0000_1000) // 08 (increment 1 time)
							begin
								test = n.DataW;
								c.addr =(c.addr + 8'b0000_0100); // increment by 4
								c.Sel =1; // everytime we have a new address, make Sel=1	

							end

						if (n.DataW == 8'b0000_0100) // 04 (dont increment)
							begin
								test = n.DataW;
								c.Sel = 0; // everytime we have a new address, make Sel=1
							end	
					
						c.RW =0;
						STATE_A = state7;
					end

				state7:
					begin

						if (test == 8'b0000_1100) // 0C
							begin
								c.addr =(c.addr + 8'b0000_0100); // increment by 4
								c.Sel = 1;

							end
						if (test == 8'b0000_1000 || test == 8'b0000_0100) // 08 or 04
							begin
								c.Sel = 0; // dont increment
							end

						c.RW =0;
						SASSOUN = 1'b1;
						STATE_A = state1;
						CurrentState = IDLE;
					end
		endcase
	end


	WRITE:
	begin

		if ((n.CmdW == 1'b0) && (SASSOUN == 1'b1))  // after READ happens (CmdW=1), the first CmdW=0 will be your SourceID
			begin
				SourceID [7:0] = {n.DataW};
				SASSOUN =1'b0;
				c.RW =0;
				c.Sel =0;
				
			end

		case(STATE_B) 
				sstate1:
					begin
						STATE_B = sstate2; // skip the SourceID
					end

				sstate2:   			// 1 byte (8 bits) for addr
					begin
						Addr1_wr =n.DataW;
						c.RW =0;
						c.Sel =0;
						STATE_B =sstate3;
					end

				sstate3:                         // 2 bytes (16 bits)
					begin
						Addr2_wr =n.DataW;
						c.RW =0;
						c.Sel =0;
						STATE_B =sstate4; 
					end

				sstate4:                         // 3 bytes (24 bits)
					begin
						Addr3_wr =n.DataW;
						c.RW =0;
						c.Sel =0;
						STATE_B =sstate5;
					end

				sstate5:                         // 4 bytes (32 bits)
					begin
						Addr4_wr =n.DataW;
						c.RW =0;
						c.Sel =0;
						STATE_B = sstate6;
					end

				sstate6: 
					begin
						c.RW =0;
						c.Sel =0;
						STATE_B = sstate7; // we will assume DataW = 04 (do not increment)
					end

				sstate7:  			// 1 byte (8 bits) for Data	
					begin
						Data1 =n.DataW;
						c.RW =0;
						c.Sel =0;
						STATE_B = sstate8;
					end

				sstate8:                         // 2 bytes (16 bits)
					begin
						Data2 =n.DataW;
						c.RW =0;
						c.Sel =0;
						STATE_B = sstate9; 
					end

				sstate9:                         // 3 bytes (24 bits)
					begin
						Data3 =n.DataW;
						c.RW =0;
						c.Sel =0;
						STATE_B =sstate10;
					end

				sstate10:                         // 4 bytes (32 bits) for Data
					begin
						Data4 =n.DataW;
						c.data_wr [31:0] ={Data4, Data3, Data2, Data1};// all 4 bytes of data will be stored into input of CRC
						c.addr [31:0] ={Addr4_wr, Addr3_wr, Addr2_wr, Addr1_wr}; // all 4 bytes of data will be stored into input of CRC
						c.RW =1;
						c.Sel =1;
						SASSOUN = 1'b1;
						STATE_B = sstate1;
						CurrentState = IDLE;
					end
		endcase
end



endcase
end
end
/*
always @ (posedge n.clk) 
begin
	if (!empty) //READ_RESP: (send the dataR, ReturnID, framing to TB from Read Response)
	begin
		case(STATE_C)

			ssstate1:
				begin
					n.CmdR = 1;
					n.DataR = n.DataW; // framing (63)
					STATE_C = ssstate2;
				end

			ssstate2:
				begin
					n.CmdR = 0;
					n.DataR = n.DataW; // ReturnID
					STATE_C = ssstate3;
				end
		
			ssstate3:
				begin
					if(n.DataW == 8'b0000_0100) // 04
					begin
						test1 = n.DataW;
						n.CmdR = 0;
						n.DataR = n.DataW; // data (1. byte)
					end
					STATE_C = ssstate4;
				end

			ssstate4:
				begin
					if(n.DataW == 8'b0000_0100) // 04
					begin
						n.CmdR = 0;
						n.DataR = n.DataW; // data (2. byte)
					end
					STATE_C = ssstate5;
				end

			ssstate5:
				begin
					if(n.DataW == 8'b0000_0100) // 04
					begin
						n.CmdR = 0;
						n.DataR = n.DataW; // data (3. byte)
					end
					STATE_C = ssstate6;
				end

			ssstate6:
				begin
					if(n.DataW == 8'b0000_0100) // 04
					begin
						n.CmdR = 0;
						n.DataR = n.DataW; // data (4. byte)
					end
						CurrentState = IDLE;
						STATE_C = ssstate1;
				end
		endcase
	end
end


endmodule

		  
		  
 module fifo (wr_en,rst,full,empty,clk,rd_en,READ_DATA,READ_DATA1);
 parameter width=32;
 parameter depth=20; 
//parameter depth=15;

 input wr_en,rd_en,rst,clk;
 output full,empty;
 input [width-1:0] READ_DATA;
 output reg [width-1:0] READ_DATA1;
 reg  [width-1 :0 ] data_mem [depth-1 : 0 ];
 reg [3 :0 ] wr_ptr,rd_ptr;

 //assign full = (rd_ptr == wr_ptr +1)?1:0;
 assign full = ((wr_ptr ==20)&&(rd_ptr==0))?1:((rd_ptr == wr_ptr +1)?1:0);
 assign empty = (rd_ptr == wr_ptr)?1:0;

 always @ (posedge clk,posedge rst)
 begin
 if (rst)
 begin
 wr_ptr <= 0;
 rd_ptr <= 0;
 end
 else
 begin
 if (rd_en && !empty)
 begin
 READ_DATA1 <= data_mem[rd_ptr];
 rd_ptr <= rd_ptr +1;
 end
 else
 begin
 READ_DATA1 <= READ_DATA1;
 rd_ptr <= rd_ptr;
 end
 if (wr_en && !full)
 begin
 data_mem[wr_ptr] <= READ_DATA;
 wr_ptr <= wr_ptr +1;
 end
 else
 begin
 data_mem[wr_ptr] <= data_mem[wr_ptr];
 wr_ptr <= wr_ptr;
 end
 end
 end
*/	
 endmodule
		  
	  
		  
	
