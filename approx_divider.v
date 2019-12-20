module approx_divider #(parameter dvnd=32, parameter dvsr=32)(dividend, divisor, quotient);
	input wire [(dvnd-1):0] dividend;
	input wire [(dvsr-1):0] divisor;
	output wire [(dvnd-1):0] quotient;
	
	wire [(2*dvsr-1):0] reciprocal;
	fixed_point_recip #(.WIDTH(32), .FRAC(32)) recip (.a(divisor), .q(reciprocal));
	
	wire [(dvnd+2*dvsr-1):0] div_out;
	DRUMk_n_m_s #(.k(8), .n(64), .m(64)) mult (.a(dividend), .b(reciprocal), .r(div_out));

	assign quotient = div_out[(dvnd+dvsr-1):dvsr];
	
endmodule