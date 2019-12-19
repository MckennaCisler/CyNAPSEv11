`timescale 1ns/10ps
module tb_recip;
reg [31:0] a;
wire [63:0] q;
fixed_point_recip recip(.a(a), .q(q));


initial
begin
	#1
	a = 32'd1;
	$monitor("Time:%d | Input:%d Reciprocal:%b", $time, a, q);
	#10
	a = 32'd3;
	#10
	a = 32'd4;
	#10
	a = 32'd5;
	#10
	a = 32'd6;
	#10
	a = 32'd7;
	#10
	a = 32'd8;
	#10
	a = 32'd9;
	#10
	a = 32'd10;
	#10
	a = 32'd25;
	#10
	a = 32'd100;
end
endmodule

