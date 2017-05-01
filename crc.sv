module crc(crc_if m); // building 32-bit synthesizable system verilog CRC block

logic [31:0] CRC_DATA1;
logic [31:0] poly; // CRC polynomial register
logic [31:0] CRC_CTRL; // CRC control register 
logic [31:0] CRC_DATA; // CRC data register

logic [31:0] CRC_ENG; // The data after transposing CRC data register 


always @ (posedge m.clk or posedge m.rst)
begin 
	if (m.rst) //reset all CRC memory map
	begin
		CRC_DATA1 = 32'hFFFFFFFF;	
		poly = 32'h00001021;					
		CRC_CTRL = 32'h00000000;
		CRC_DATA = 32'hFFFFFFFF;
	end

	if (m.RW == 1'b1 && m.Sel == 1'b1) //RW=1 (write), we always want Sel=1 since we want 32-bit
	begin
		case(m.addr)
		32'h40032000:		
		begin

		
		if (CRC_CTRL[25])begin //WAS

		if (CRC_CTRL[24]) begin	//TCRC

		case (CRC_CTRL[31:30]) //TOT (32 bits)

			2'b00: //flipping nothing
			begin
			CRC_DATA[31:0] = m.data_wr; 
			end

			2'b01: //flipping bits only
			begin
			CRC_DATA[31:0] = {m.data_wr[24], m.data_wr[25], m.data_wr[26], m.data_wr[27], m.data_wr[28], m.data_wr[29], m.data_wr[30], m.data_wr[31], m.data_wr[16], m.data_wr[17], m.data_wr[18], m.data_wr[19], m.data_wr[20], m.data_wr[21], m.data_wr[22], m.data_wr[23], m.data_wr[8], m.data_wr[9], m.data_wr[10], m.data_wr[11], m.data_wr[12], m.data_wr[13], m.data_wr[14], m.data_wr[15], m.data_wr[0], m.data_wr[1], m.data_wr[2], m.data_wr[3], m.data_wr[4], m.data_wr[5], m.data_wr[6], m.data_wr[7]};
			end

			2'b10: //flipping both bits and bytes
			begin
			CRC_DATA[31:0] = {m.data_wr[0], m.data_wr[1], m.data_wr[2], m.data_wr[3], m.data_wr[4], m.data_wr[5], m.data_wr[6], m.data_wr[7], m.data_wr[8], m.data_wr[9], m.data_wr[10], m.data_wr[11], m.data_wr[12], m.data_wr[13], m.data_wr[14], m.data_wr[15], m.data_wr[16], m.data_wr[17], m.data_wr[18], m.data_wr[19], m.data_wr[20], m.data_wr[21], m.data_wr[22], m.data_wr[23], m.data_wr[24], m.data_wr[25], m.data_wr[26], m.data_wr[27], m.data_wr[28], m.data_wr[29], m.data_wr[30], m.data_wr[31]};
			end

			2'b11: //flipping bytes only
			begin 
			CRC_DATA[31:0] = {m.data_wr[7], m.data_wr[6], m.data_wr[5], m.data_wr[4], m.data_wr[3], m.data_wr[2], m.data_wr[1], m.data_wr[0], m.data_wr[15], m.data_wr[14], m.data_wr[13], m.data_wr[12], m.data_wr[11], m.data_wr[10], m.data_wr[9], m.data_wr[8], m.data_wr[23], m.data_wr[22], m.data_wr[21], m.data_wr [20], m.data_wr [19], m.data_wr [18], m.data_wr [17], m.data_wr [16], m.data_wr[31], m.data_wr[30], m.data_wr[29], m.data_wr [28], m.data_wr [27], m.data_wr [26], m.data_wr [25], m.data_wr [24]};
			end
		endcase
		end

		else
		begin
			case (CRC_CTRL[31:30]) // TOT (16 bits)

			2'b00: //flipping nothing
			begin
			CRC_DATA[31:0] = {16'h0000,m.data_wr[15:0]};
			end

			2'b01: //flipping bits only
			begin
			CRC_DATA[31:0] = {16'h0000, m.data_wr[8], m.data_wr[9], m.data_wr[10], m.data_wr[11], m.data_wr[12], m.data_wr[13], m.data_wr[14], m.data_wr[15], m.data_wr[0], m.data_wr[1], m.data_wr[2], m.data_wr[3], m.data_wr[4], m.data_wr[5], m.data_wr[6], m.data_wr[7]};
			end

			2'b10: //flipping both bits and bytes
			begin
			CRC_DATA[31:0] = {16'h0000, m.data_wr[16], m.data_wr[17], m.data_wr[18], m.data_wr[19], m.data_wr[20], m.data_wr[21], m.data_wr[22], m.data_wr[23], m.data_wr[24], m.data_wr[25], m.data_wr[26], m.data_wr[27], m.data_wr[28], m.data_wr[29], m.data_wr[30], m.data_wr[31]};
			end

			2'b11: //flipping bytes only
			begin 
			CRC_DATA[31:0] = {16'h0000, m.data_wr[23], m.data_wr[22], m.data_wr[21], m.data_wr [20], m.data_wr [19], m.data_wr [18], m.data_wr [17], m.data_wr [16], m.data_wr[31], m.data_wr[30], m.data_wr[29], m.data_wr [28], m.data_wr [27], m.data_wr [26], m.data_wr [25], m.data_wr [24]};
			end
			endcase
		end

		end
			else
			begin

			
		case (CRC_CTRL[31:30]) // TOT (4 different cases) for 32 bits for CRC_ENG

			2'b00: //flipping nothing
			begin
			CRC_ENG[31:0] = m.data_wr;
			end

			2'b01: //flipping bits only
			begin
			CRC_ENG[31:0] = {m.data_wr[24], m.data_wr[25], m.data_wr[26], m.data_wr[27], m.data_wr[28], m.data_wr[29], m.data_wr[30], m.data_wr[31], m.data_wr[16], m.data_wr[17], m.data_wr[18], m.data_wr[19], m.data_wr[20], m.data_wr[21], m.data_wr[22], m.data_wr[23], m.data_wr[8], m.data_wr[9], m.data_wr[10], m.data_wr[11], m.data_wr[12], m.data_wr[13], m.data_wr[14], m.data_wr[15], m.data_wr[0], m.data_wr[1], m.data_wr[2], m.data_wr[3], m.data_wr[4], m.data_wr[5], m.data_wr[6], m.data_wr[7]};
			end

			2'b10: //flipping both bits and bytes
			begin
			CRC_ENG[31:0] = {m.data_wr[0], m.data_wr[1], m.data_wr[2], m.data_wr[3], m.data_wr[4], m.data_wr[5], m.data_wr[6], m.data_wr[7], m.data_wr[8], m.data_wr[9], m.data_wr[10], m.data_wr[11], m.data_wr[12], m.data_wr[13], m.data_wr[14], m.data_wr[15], m.data_wr[16], m.data_wr[17], m.data_wr[18], m.data_wr[19], m.data_wr[20], m.data_wr[21], m.data_wr[22], m.data_wr[23], m.data_wr[24], m.data_wr[25], m.data_wr[26], m.data_wr[27], m.data_wr[28], m.data_wr[29], m.data_wr[30], m.data_wr[31]};
			end

			2'b11: //flipping bytes only
			begin 
			CRC_ENG[31:0] = {m.data_wr[7], m.data_wr[6], m.data_wr[5], m.data_wr[4], m.data_wr[3], m.data_wr[2], m.data_wr[1], m.data_wr[0], m.data_wr[15], m.data_wr[14], m.data_wr[13], m.data_wr[12], m.data_wr[11], m.data_wr[10], m.data_wr[9], m.data_wr[8], m.data_wr[23], m.data_wr[22], m.data_wr[21], m.data_wr [20], m.data_wr [19], m.data_wr [18], m.data_wr [17], m.data_wr [16], m.data_wr[31], m.data_wr[30], m.data_wr[29], m.data_wr [28], m.data_wr [27], m.data_wr [26], m.data_wr [25], m.data_wr [24]};
			end
		endcase
			end
			

  	
//assign CRC_DATA1 = CRC_DATA;





		if (CRC_CTRL[25] == 0) // if WAS=0 (this loop is for WAS cases)
		begin
			if (CRC_CTRL[24]) //32 bits
			begin
			for( int count = 31; count >= 0; count--) // loop 32 times
			begin
				if (CRC_DATA[31] == 0)
				begin
					CRC_DATA = {CRC_DATA[30:0], CRC_ENG[31]};
					CRC_ENG = CRC_ENG << 1;
				end
			

				else
				begin
					CRC_DATA = {CRC_DATA[30:0], CRC_ENG[31]};
					CRC_DATA = CRC_DATA ^ poly;
					CRC_ENG = CRC_ENG << 1;
				end
			end
			end

			else // if TCRC=0, then it is 16-bits
			begin
				for( int count = 31; count >= 0; count--) // loop 32 times
			begin
				if (CRC_DATA[15] == 0)
				begin
					CRC_DATA = {16'h0000, CRC_DATA[14:0], CRC_ENG[31]};
					CRC_ENG = CRC_ENG << 1;
				end
			

				else
				begin
					CRC_DATA = {16'h0000, CRC_DATA[14:0], CRC_ENG[31]};
					CRC_DATA = CRC_DATA ^ poly;
					CRC_ENG = CRC_ENG << 1;
				end
			end




			end

		end

	

if (CRC_CTRL[24] == 1'b1) // if TCRC = 1, then  32 bits will be used
begin
  	if (CRC_CTRL[26] == 1'b1) // if FXOR =1, then complement CRC DATA (use xor)
		begin
   		CRC_DATA1 = (CRC_DATA ^ 32'hFFFF_FFFF);
		end
	else 
		begin
		CRC_DATA1 = CRC_DATA;
		end
end

else if(CRC_CTRL[24] == 1'b0)  // if TCRC = 0, then  16 bits will be used
begin

if (CRC_CTRL[26] == 1'b1) // if FXOR =1, then complement CRC DATA (use xor)
begin
   	if ((CRC_CTRL[29:28] == 2'b00)) begin //CRC_DATA = CRC_DATA; //{16'h0,CRC_DATA [15:0]};
			CRC_DATA1 = (CRC_DATA ^ 32'h0000_FFFF);	
		end

	else if ((CRC_CTRL[29:28] == 2'b01)) begin //CRC_DATA = CRC_DATA; //{16'h0,CRC_DATA [15:0]};
			CRC_DATA1 = (CRC_DATA ^ 32'h0000_FFFF);	
		end

	else if ((CRC_CTRL[29:28] == 2'b10)) begin //CRC_DATA = CRC_DATA; //{16'h0,CRC_DATA [15:0]};
			CRC_DATA1 = (CRC_DATA ^ 32'h0000_FFFF);	
		end

	else if ((CRC_CTRL[29:28] == 2'b11)) begin //CRC_DATA = CRC_DATA; //{16'h0,CRC_DATA [15:0]};
			CRC_DATA1 = (CRC_DATA ^ 32'h0000_FFFF);	
		end
end


else 
		begin
		CRC_DATA1 = CRC_DATA;
		end

end
	end	



	32'h40032004:
	begin
		if (CRC_CTRL [24]) begin // 32-bit CRC
		poly= m.data_wr;
		end
		else // TCRC = 0 (16-bits)
		begin
		poly= {16'h0000, m.data_wr [15:0]}; // 16-bit (the first MSB of 16 bits = 0)
		end
	end

	32'h40032008:
	begin
		CRC_CTRL = m.data_wr;
	end
	endcase		
	end
end

always @(posedge m.clk)
begin
	if ((m.RW == 1'b0) && (m.Sel == 1'b1)) //RW=0 (read), we always want Sel=1 since we want 32-bit      
	begin
		case(m.addr)
			32'h40032000:
			begin
	
	case (CRC_CTRL[29:28]) //TOTR

			2'b00: //flipping nothing
			begin
			m.data_rd [31:0] = CRC_DATA1;
			end

			2'b01: //flipping bits only
			begin
			m.data_rd [31:0] = {CRC_DATA1[24], CRC_DATA1[25], CRC_DATA1[26], CRC_DATA1[27], CRC_DATA1[28], CRC_DATA1[29], CRC_DATA1[30], CRC_DATA1[31], CRC_DATA1[16], CRC_DATA1[17], CRC_DATA1[18], CRC_DATA1[19], CRC_DATA1[20], CRC_DATA1[21], CRC_DATA1[22], CRC_DATA1[23], CRC_DATA1[8], CRC_DATA1[9], CRC_DATA1[10], CRC_DATA1[11], CRC_DATA1[12], CRC_DATA1[13], CRC_DATA1[14], CRC_DATA1[15], CRC_DATA1[0], CRC_DATA1[1], CRC_DATA1[2], CRC_DATA1[3], CRC_DATA1[4], CRC_DATA1[5], CRC_DATA1[6], CRC_DATA1[7]};
			end

			2'b10: //flipping both bits and bytes
			begin
			m.data_rd [31:0] = {CRC_DATA1[0], CRC_DATA1[1], CRC_DATA1[2], CRC_DATA1[3], CRC_DATA1[4], CRC_DATA1[5], CRC_DATA1[6], CRC_DATA1[7], CRC_DATA1[8], CRC_DATA1[9], CRC_DATA1[10], CRC_DATA1[11], CRC_DATA1[12], CRC_DATA1[13], CRC_DATA1[14], CRC_DATA1[15], CRC_DATA1[16], CRC_DATA1[17], CRC_DATA1[18], CRC_DATA1[19], CRC_DATA1[20], CRC_DATA1[21], CRC_DATA1[22], CRC_DATA1[23], CRC_DATA1[24], CRC_DATA1[25], CRC_DATA1[26], CRC_DATA1[27], CRC_DATA1[28], CRC_DATA1[29], CRC_DATA1[30], CRC_DATA1[31]};
			end

			2'b11: //flipping bytes only
			begin 
			m.data_rd [31:0] = {CRC_DATA1[7], CRC_DATA1[6], CRC_DATA1[5], CRC_DATA1[4], CRC_DATA1[3], CRC_DATA1[2], CRC_DATA1[1], CRC_DATA1[0], CRC_DATA1[15], CRC_DATA1[14], CRC_DATA1[13], CRC_DATA1[12], CRC_DATA1[11], CRC_DATA1[10], CRC_DATA1[9], CRC_DATA1[8], CRC_DATA1[23], CRC_DATA1[22], CRC_DATA1[21], CRC_DATA1 [20], CRC_DATA1 [19], CRC_DATA1 [18], CRC_DATA1 [17], CRC_DATA1 [16], CRC_DATA1[31], CRC_DATA1[30], CRC_DATA1[29], CRC_DATA1 [28], CRC_DATA1 [27], CRC_DATA1 [26], CRC_DATA1 [25], CRC_DATA1 [24]};
			end
	endcase

		end

			32'h40032004:
			begin
			m.data_rd = poly;
			end

			32'h40032008:
			begin
			m.data_rd = CRC_CTRL;
			end
	endcase
	end
end



endmodule


