module power2divider
#( 
    // note: must have DIVISOR_WIDTH <= DIVIDEND_WIDTH
	parameter DIVIDEND_WIDTH = 96,
    parameter DIVISOR_WIDTH = 32
)
(
    input wire [(DIVIDEND_WIDTH-1):0] dividend,
    input wire [(DIVISOR_WIDTH-1):0] divisor,
    output reg [(DIVIDEND_WIDTH-1):0] quotient
);
    integer i;

    reg [(DIVIDEND_WIDTH-1):0] dividend_tmps [(DIVIDEND_WIDTH-1):0];
    reg [(DIVISOR_WIDTH-1):0] divisor_tmps  [(DIVISOR_WIDTH-1):0];

    always @* begin
        dividend_tmps[0] = dividend;
        divisor_tmps[0] = divisor;
        // the largest divisor we can have is 2^DIVISOR_WIDTH - 1
        for (i = 1; i < DIVISOR_WIDTH; i++) begin
            dividend_tmps[i] = dividend_tmps[i-1] >> 1;
            divisor_tmps[i] = divisor_tmps[i-1] >> 1;
            if (divisor_tmps[i-1] != {DIVISOR_WIDTH{1'd0}}) begin
                quotient = dividend_tmps[i-1];
            end
        end
    end

endmodule
