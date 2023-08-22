module edge_counter  # (parameter WIDTH = 8) 
(
 input  clock,
 input  reset ,
 output [WIDTH-1:0] dout 
 );


reg [WIDTH-1:0] EdgeCount;


always @(posedge clock or posedge reset)
	begin
		if (reset) EdgeCount <= {WIDTH{1'b0}};		
		else EdgeCount <= EdgeCount +  {{(WIDTH-1){1'b0}}, 1'b1};
	end


assign dout = EdgeCount;

endmodule