`timescale 1ns/1ps

module fp32_div_tb;

	reg clk;
	reg start;
	reg [31:0] a, b;
	wire [31:0] result;
	wire done;

initial begin
        clk = 0;
        forever #10 clk = ~clk;  
end    

initial begin
        start = 0;
        a = 0;
        b = 0;
        #20;
        
        a = 32'h40F00000; // 7.5
        b = 32'h40200000; // 2.5
        start = 1;
        #20;
        start = 0;
        wait(done);
	#40;

        a = 32'h41000000; // 8.0
        b = 32'h40000000; // 2.0
        start = 1;
        #20;
        start = 0;
        wait(done);
        #40;
        
        a = 32'h40A00000; // 5.0
        b = 32'h00000000; // 0.0
        start = 1;
        #20;
        start = 0;
        wait(done);
        #40;
        
        a = 32'h7F800000; // +inf
        b = 32'h40000000; // 2.0
        start = 1;
        #20;
        start = 0;
        wait(done);
        #40;
        
        a = 32'h7FC00000; // NaN
        b = 32'h40000000; // 2.0
        start = 1;
        #20;
        start = 0;
        wait(done);
        #40;
        
        a = 32'h00001000; // 很小的非规格化数
        b = 32'h40000000; // 2.0
        start = 1;
        #20;
        start = 0;
        wait(done);
        #40;
        
        $finish();
end
    
initial begin
	$fsdbDumpfile("fp32_div_tb.fsdb");
	$fsdbDumpvars(0);
end
    
fp_div_top dut (
	.clk(clk),
	.start(start),
	.a(a),
	.b(b),
	.result(result),
	.done(done)
);
    

endmodule

module fp_div_top(
	input clk,
	input start,
	input [31:0] a,
	input [31:0] b,
	output [31:0] result,
	output done
);
	wire s_a, s_b;
	wire [7:0] exp_a, exp_b;
	wire [22:0] mant_a, mant_b;
	wire [1:0] state;
	wire adn;
	wire s_o;
	wire [34:0] dividend_m;
	wire [29:0] divisor_m;
	wire [4:0] lzd_o_a, lzd_o_b;
	wire [9:0] exp_mid;
	wire [31:0] Q;
	wire [22:0] mant_o;
	wire [7:0] exp_o;
    
	unpack u_unpack(
		.a(a),
		.b(b),
		.s_a(s_a),
		.s_b(s_b),
		.exp_a(exp_a),
		.exp_b(exp_b),
     		.mant_a(mant_a),
		.mant_b(mant_b)
    	);
	    
	outlier_handling u_outlier(
		.s_a(s_a),
		.s_b(s_b),
		.exp_a(exp_a),
		.exp_b(exp_b),
		.mant_a(mant_a),
		.mant_b(mant_b),
		.state(state),
		.adn(adn)
	);
	    
	XOR u_xor(
		.s_a(s_a),
		.s_b(s_b),
		.s_o(s_o)
	);
    
	prenorm u_prenorm(
		.exp_a(exp_a),
		.exp_b(exp_b),
		.mant_a(mant_a),
		.mant_b(mant_b),
		.dividend_m(dividend_m),
		.divisor_m(divisor_m),
		.lzd_o_a(lzd_o_a),
		.lzd_o_b(lzd_o_b)
	);
    
	adder_1 u_adder1(
		.exp_a(exp_a),
		.exp_b(exp_b),
		.lzd_o_a(lzd_o_a),
		.lzd_o_b(lzd_o_b),
		.exp_mid(exp_mid)
	);
    
	iteration u_iteration(
		.dividend_m(dividend_m),
		.divisor_m(divisor_m),
		.clk(clk),
		.start(start),
		.Q(Q),
		.done(done)
	);
    
	round_to_nearest_even u_round(
		.done(done),
		.Q(Q),
		.exp_q_mid(exp_mid),
		.mant_o(mant_o),
		.exp_o(exp_o)
	);
    
	pack u_pack(
		.s_o(s_o),
		.start(start),
		.adn(adn),
		.done(done),
		.exp_o(exp_o),
		.mant_o(mant_o),
		.state(state),
		.answer(result)
	);

endmodule