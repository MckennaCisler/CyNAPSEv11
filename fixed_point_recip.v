module fixed_point_recip(a, q);
//Reciprocal by means of Integer Division
//Uses Reduced Precision

parameter WIDTH = 32;
parameter FRAC = 32;

input signed [WIDTH-1:0] a;
output [(WIDTH+FRAC-1):0] q;

wire signed [(FRAC+WIDTH-1):0] div;
//wire signed [FRAC+WIDTH-1:0] a_add_sub;
wire signed [(FRAC+WIDTH-1):0] one;
assign one  = 1'b1 << FRAC; //Reciprocal one - Upshifted

//Perform Integer Division
assign q = one / a;

//Truncate
//always @* begin
//	q[WIDTH-1] <= a[WIDTH-1];
//	q[WIDTH-2:0] <= div[WIDTH-2:0];
//end

endmodule
