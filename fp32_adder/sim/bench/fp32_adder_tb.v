`timescale 1ns / 1ps

module tb_float_adder;

    reg [31:0] a, b;
    wire [31:0] answer;
    reg cin;

    wire s_a, s_b;
    wire [7:0] exp_a, exp_b;
    wire [22:0] mant_a, mant_b;
    wire [7:0] exp_diff;
    wire [7:0] exp_larger;
    wire [1:0] state;
    wire adn,same,XOR,s_o,a_larger;
    wire [47:0] l_shift, s_shift;
    wire [47:0] adder_1_o;
    wire [7:0] ldz_o;
    wire [7:0] exp_o;
    wire [22:0] mant_o;

unpack u_unpack (
    .a(a),
    .b(b),
    .s_a(s_a),
    .s_b(s_b),
    .exp_a(exp_a),
    .exp_b(exp_b),
    .mant_a(mant_a),
    .mant_b(mant_b)
);

outlier_handling u_outlier_handling (
    .s_a(s_a),
    .s_b(s_b),
    .exp_a(exp_a),
    .exp_b(exp_b),
    .mant_a(mant_a),
    .mant_b(mant_b),
    .state(state),
    .adn(adn)
);

compare u_compare (
    .s_a(s_a),
    .s_b(s_b),
    .exp_a(exp_a),
    .exp_b(exp_b),
    .mant_a(mant_a),
    .mant_b(mant_b),
    .same(same),
    .a_larger(a_larger),
    .s_o(s_o)
);

exp_aligner u_exp_aligner(
    .exp_a(exp_a),
    .exp_b(exp_b),
    .same(same),
    .exp_diff(exp_diff),
    .exp_larger(exp_larger)
);

XOR u_xor (
    .s_a(s_a),
    .s_b(s_b),
    .XOR(XOR)
);

shift_1 u_shift_1 (
    .mant_a(mant_a),
    .mant_b(mant_b),
    .exp_diff(exp_diff),
    .a_larger(a_larger),
    .same(same),
    .l_shift(l_shift),
    .s_shift(s_shift)
);

adder_1 u_adder_1 (
    .l_shift(l_shift),
    .s_shift(s_shift),
    .XOR(XOR),
    .adder_1_o(adder_1_o)
);

LDZ u_ldz (
    .adder_1_o(adder_1_o),
    .ldz_o(ldz_o)
);

shift_and_cut u_shift_and_cut (
    .adder_1_o(adder_1_o),
    .ldz_o(ldz_o),
    .exp_larger(exp_larger),
    .exp_o(exp_o),
    .mant_o(mant_o)
);

pack u_pack (
    .s_o(s_o),
    .adn(adn),
    .exp_o(exp_o),
    .mant_o(mant_o),
    .state(state),
    .answer(answer)
);

initial begin
        a = 32'b0; 
        b = 32'b0; 
        cin = 1'b0;

        #30;
        a = 32'h40490FDB; //3.14159
        b = 32'h40490FDB; 
        #30;

        a = 32'hC0490FDB; //-3.14159 
        b = 32'h40490FDB; 
        #30;

        a = 32'b0; //0
        b = 32'b0; //0
        #30;

        a = 32'h7F800000; //正无穷
        b = 32'hFF800000; //负无穷
        #30;

        a = 32'hfF800000; //负无穷
        b = 32'hFF800000; //负无穷
        #30;

        a = 32'h7FC00001; // NaN
        b = 32'h40490FDB; // 3.14159 
        #30;

        $stop;
    end

endmodule