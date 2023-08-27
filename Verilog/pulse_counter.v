module pulse_counter  # (parameter WIDTH = 8) 
(
 input  clock,
 input  din,
 input  reset ,
 output [WIDTH-1:0] dout 
 );


reg [WIDTH-1:0] count;

always @(posedge clock or posedge reset)
		begin
		if (reset) count <= {WIDTH{1'b0}};	
		else if (din)
				count <= count +  {{(WIDTH-1){1'b0}}, 1'b1};
		end

assign dout = count;

endmodule
