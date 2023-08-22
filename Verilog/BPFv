module BPF #(parameter WIDTH = 8) (din, clock, ss_n,  dout, select);

input  [WIDTH-1:0] din;
input clock;
input ss_n;
input select;
output [WIDTH-1:0] dout;

reg    [WIDTH-1:0] ff;

always @ (posedge clock or posedge ss_n) //Accumulator
		begin
		if(ss_n) ff <= 0;
		else 	 ff <= din;
		end	
			
assign dout = select ? ff : din;
			
endmodule
