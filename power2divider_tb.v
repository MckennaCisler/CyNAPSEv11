module power2divider_tb
#( 
	parameter DIVIDEND_WIDTH = 96,
    parameter DIVISOR_WIDTH = 32
)
();

    reg  [(DIVIDEND_WIDTH-1):0] dividend;
    reg  [(DIVISOR_WIDTH-1):0] divisor;
    wire [(DIVIDEND_WIDTH-1):0] quotient;
    
    power2divider div(
        .dividend(dividend),
        .divisor(divisor), 
        .quotient(quotient)
    );

    wire [(DIVIDEND_WIDTH-1):0] real_quotient;
    assign real_quotient = dividend / divisor;
    wire [(DIVIDEND_WIDTH-1):0] quotient_per_diff;
    assign quotient_per_diff = 100*(quotient-real_quotient)/real_quotient;

    initial begin
        #1
        $monitor("%d %d %d %d %.1f", dividend, divisor, quotient, real_quotient, quotient_per_diff);
        dividend = 10;
        divisor = 2;
        #1
        dividend = 20;
        divisor = 4;
        #1
        dividend = 30;
        divisor = 4;
        #1
        dividend = 10;
        divisor = 1;
        #1
        dividend = 10;
        divisor = 5;
        #1
        dividend = 50;
        divisor = 7;
        #1
        dividend = 97813;
        divisor = 16;
        #1
        dividend = 97813;
        divisor = 135;

        #1
        dividend = 74101;
        for (divisor = 1; divisor < 500; divisor++) begin
            #1;
        end

        #5 $finish;
    end

endmodule
