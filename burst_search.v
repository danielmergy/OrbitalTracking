module burst_search #(parameter WIDTH = 8, SHIFT_LEN = 8) (din, clock, ss_n,  threshold, n, burst_detected);

parameter SIZE_N = $clog2(SHIFT_LEN);
parameter MAX_COUNT_SIZE = WIDTH + SIZE_N;



input [SIZE_N-1:0] n; //# of flops activated (not bypassed)
input [WIDTH-1:0] din;
input [WIDTH-1:0] threshold;
input clock;
input ss_n;
output burst_detected;

wire [MAX_COUNT_SIZE-1:0] threshold_extended;
wire [MAX_COUNT_SIZE-1:0] incremented;
reg [MAX_COUNT_SIZE-1:0] accumulated;


wire [SHIFT_LEN-1:0] onehot;
wire [SHIFT_LEN-1:0] meroupad;
wire [SHIFT_LEN-1:0] meroupad_lsb_zero;
wire [WIDTH-1:0] vec [SHIFT_LEN-1:0];


genvar i;

binary_to_one_hot   	  #(.SIZE_N(SIZE_N)) B2OH (.bin(n), .onehot(onehot) );

set_bits_after_first_one  #(.SHIFT_LEN(SHIFT_LEN))  SETTER ( .onehot(onehot), .meroupad(meroupad) );

assign meroupad_lsb_zero = {meroupad[SHIFT_LEN-1:1],1'b0};

BPF #(.WIDTH(WIDTH)) FIRST (.din(din), .clock(clock), .ss_n(ss_n),  .dout(vec[SHIFT_LEN-1]), .select(meroupad_lsb_zero[SHIFT_LEN-1]));

generate
        for (i=SHIFT_LEN-2; i>=0; i=i-1) begin : per_output
		BPF #(.WIDTH(WIDTH)) inst (.din(vec[i+1]), .clock(clock), .ss_n(ss_n),  .dout(vec[i]), .select(meroupad_lsb_zero[i]));
        end
endgenerate

always @ (posedge clock or posedge ss_n) //Accumulator
		begin
		if(ss_n) accumulated <= 0;
		else 	 accumulated <= incremented;
		end	
			
assign incremented = accumulated + {{(SIZE_N-1){1'b0}}, din} - {{(SIZE_N-1){1'b0}}, vec[0]};	
		

assign threshold_extended = {{(SIZE_N-1){1'b0}},threshold};

assign burst_detected = (incremented < threshold_extended);
			
endmodule