module set_bits_after_first_one #(parameter SHIFT_LEN = 8) 
(
  input [SHIFT_LEN-1:0] onehot,
  output [SHIFT_LEN-1:0] meroupad
);
  
  	wire [SHIFT_LEN-1:0] vec;
	genvar i;
 
  
  	assign vec[SHIFT_LEN-1] = onehot[SHIFT_LEN-1];
  
	generate
      for (i=SHIFT_LEN-2; i>=0; i=i-1) begin : per_output
        assign vec[i] = onehot[i] | vec[i+1];
        end
	endgenerate
  
	assign meroupad = vec;  

endmodule
