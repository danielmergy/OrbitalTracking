module enable_flop #(parameter WIDTH = 8) (din, clock, ss_n,  dout, en);

input  [WIDTH-1:0] din;
input clock;
input ss_n;
input en;
output [WIDTH-1:0] dout;
reg    [WIDTH-1:0] ff;

always @ (posedge clock or posedge ss_n) 
		begin
		if(ss_n) 
			ff <= 0;
		else if (en) 
			ff <= din;
		end	

assign dout = ff;			
			
endmodule