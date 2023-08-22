module SPISlave (
    input iSPI_CLK,		
    input iSPI_SS_n,
    input iSPI_IN,
	input [7:0] iSPI_SEND_BYTE,
	 
    output oSPI_OUT,
	output [4:0] oSPI_PERIPH_SLCT,
	output oSPI_WRITE_SIG,
	output oSPI_READ_SIG,
	output oSPI_INC_WRADDR,
	output oSPI_INC_RDADDR,	 
	output [7:0] oSPI_RCV_BYTE,
	output [7:0] oSPI_RCV_CMD
    );

	 
	 
reg [7:0] rLATCH_CMD;
reg [6:0] rLATCH_DATA;
reg r1stBYTE_n;
reg [2:0] rCPT_BIT;
reg rBYTE_READY;	 

assign oSPI_RCV_CMD = rLATCH_CMD;
assign oSPI_WRITE_SIG  = (rBYTE_READY == 1'b1) & (rLATCH_CMD[7] == 1'b1) & (rCPT_BIT == 3'b111);
assign oSPI_INC_WRADDR = (rBYTE_READY == 1'b1) & (rLATCH_CMD[7] == 1'b1) & (rCPT_BIT == 3'b000);
assign oSPI_INC_RDADDR = (rBYTE_READY == 1'b1) & (rCPT_BIT == 3'b111);
assign oSPI_READ_SIG = (rCPT_BIT == 3'b000) & (iSPI_SS_n == 1'b0);
assign oSPI_RCV_BYTE = {rLATCH_DATA[6:0], iSPI_IN};	 
assign oSPI_OUT = (iSPI_SS_n == 1) ? 1'bZ : iSPI_SEND_BYTE[7-rCPT_BIT];
assign oSPI_PERIPH_SLCT = (iSPI_SS_n == 1) ? 4'b0000 : rLATCH_CMD[6:3];

//
//initial
//	begin
//		rLATCH_CMD <= 7'b0;
//		r1stBYTE_n <= 1'b0;
//		rLATCH_DATA <= 7'b0;
//		rBYTE_READY <= 1'b0;
//		rCPT_BIT <= 3'b0;
//	end
	 
always @(negedge iSPI_CLK or posedge iSPI_SS_n)
begin
	if (iSPI_SS_n == 1'b1)
		begin
			rCPT_BIT <= 0;
			r1stBYTE_n <= 0;
		end
   else
		begin
			rCPT_BIT <= rCPT_BIT + 3'b001;
			if (rCPT_BIT == 3'b111)
				r1stBYTE_n <= 1'b1;
		end
end
	 
	 
always @(posedge iSPI_CLK or posedge iSPI_SS_n)
begin
	if (iSPI_SS_n == 1'b1)
		begin
				rLATCH_CMD <= 0;
				rLATCH_DATA <= 0;
				rBYTE_READY <= 0;
		end
	else
		if (r1stBYTE_n == 1'b0)
				rLATCH_CMD[7-rCPT_BIT] <= iSPI_IN;
		else
			if (rCPT_BIT == 3'b111)
					rBYTE_READY <= 1'b1;
			else
				begin
					rLATCH_DATA[6-rCPT_BIT] <= iSPI_IN;
					rBYTE_READY <= 1'b0;
				end
end
	 
endmodule
