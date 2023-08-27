module binary_to_one_hot #(parameter SIZE_N = 3) 
(
    input [SIZE_N-1:0] bin,
    output [2**SIZE_N-1:0] onehot
);

    generate
        genvar i;
        for(i=0; i<2**SIZE_N; i=  i+1) begin: gen_onehot
            assign onehot[i] = (bin == i);
        end
    endgenerate

endmodule
