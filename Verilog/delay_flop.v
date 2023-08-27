module delay_flop  
(
 input  clock,
 input  reset,
 input  din,
 output dout
 );

reg data;

always@(posedge clock or posedge reset)
	begin
		if (reset) data <= 1'b0;
		else data <= din;
	end


assign dout = data;

endmodule
