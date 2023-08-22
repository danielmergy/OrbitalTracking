module simple_latch # (parameter WIDTH = 8) 
(
 input  en,
 input  [WIDTH-1:0] din,
 output [WIDTH-1:0] dout 
 );

reg [WIDTH-1:0] Latched; 

always @(en) if(~en) Latched <= din;

assign dout = Latched;

endmodule