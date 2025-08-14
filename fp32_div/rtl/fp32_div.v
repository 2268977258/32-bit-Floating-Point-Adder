//加法器模块
module FA_PG(
	input x,y,cin,
	output f,p,g
);

	assign f = x ^ y ^ cin;
	assign p =  x | y;
	assign g = x & y;

endmodule

//8位先行进位加法器模块
module CLA_8(
	input [7:0] a,b,
	input cin,
	output [7:0] f,
	output cout
);

	wire [8:0] c;
	wire [7:0] p,g;	

	assign c[0] = cin;
	FA_PG fa0(a[0], b[0], c[0], f[0], p[0], g[0]);
	FA_PG fa1(a[1], b[1], c[1], f[1], p[1], g[1]);
	FA_PG fa2(a[2], b[2], c[2], f[2], p[2], g[2]);
	FA_PG fa3(a[3], b[3], c[3], f[3], p[3], g[3]);
	FA_PG fa4(a[4], b[4], c[4], f[4], p[4], g[4]);
	FA_PG fa5(a[5], b[5], c[5], f[5], p[5], g[5]);
	FA_PG fa6(a[6], b[6], c[6], f[6], p[6], g[6]);
	FA_PG fa7(a[7], b[7], c[7], f[7], p[7], g[7]);
	assign c[1] = g[0] | (p[0] & c[0]);
	assign c[2] = g[1] | (p[1] & c[1]);
   	assign c[3] = g[2] | (p[2] & c[2]);
	assign c[4] = g[3] | (p[3] & c[3]);
	assign c[5] = g[4] | (p[4] & c[4]);
	assign c[6] = g[5] | (p[5] & c[5]);
	assign c[7] = g[6] | (p[6] & c[6]);
	assign c[8] = g[7] | (p[7] & c[7]);
	assign cout = c[8];

endmodule

//将输入的32位浮点数a与b各自拆分出符号位，阶码与尾数
module unpack(
	input [31:0]a,b,
	output reg s_a,s_b,
	output reg [7:0]exp_a,exp_b,
	output reg [22:0]mant_a,mant_b
);

	always @(*) begin
	s_a = a[31];
	exp_a = a[30:23];
	mant_a = a[22:0];
	s_b = b[31];
	exp_b = b[30:23];
	mant_b = b[22:0];
	end

endmodule

//检测异常值如无穷大，0和NaN
module outlier_handling(
	input s_a,s_b,
	input [7:0]exp_a,exp_b,
	input [22:0]mant_a,mant_b,
	output	reg[1:0]state,
	output	reg adn
);
	always @(*) begin
	if(exp_a == 8'b11111111 && mant_a == 23'b0 && exp_b == 8'b11111111 && mant_b == 23'b0) begin
		adn = 1;
		state = 2'b00;	//两个无穷大
	end else if(exp_a == 8'b0 && mant_a == 23'b0 && (exp_b != 8'b0 || mant_b != 23'b0) && exp_b != 8'b11111111) begin
		adn = 1;
		state = 2'b01;	//被除数为0，除数为非异常值
	end else if(exp_b == 8'b0 && mant_b == 23'b0) begin
		adn = 1;
		state = 2'b00;	//除数为0
	end else if(exp_a == 8'b11111111 && mant_a != 23'b0 || exp_b == 8'b11111111 && mant_b != 23'b0) begin
		adn = 1;
		state = 2'b11;	//存在NaN		
	end else if(exp_a == 8'b0 && mant_a == 23'b0 && exp_b == 8'b11111111 && mant_b == 23'b0) begin
		adn = 1;
		state = 2'b00;	//输入为0和无穷大		
	end else if(exp_a == 8'b11111111 && mant_a == 23'b0 && (exp_b != 8'b0 || mant_b != 23'b0) && exp_b != 8'b11111111) begin
		adn = 1;
		state = 2'b10;	//被除数为无穷大，除数为正常值		
	end else begin
		adn = 0;
	end
	end

endmodule

//对符号位进行异或计算决定进行加法还是减法
module XOR(
	input s_a,s_b,
	output s_o
);
	assign s_o = s_a ^ s_b;

endmodule

//对尾数进行预处理
module prenorm(
	input [7:0]exp_a,exp_b,
	input [22:0]mant_a,mant_b,
	output [34:0]dividend_m,
	output [29:0]divisor_m,
	output [4:0]lzd_o_a,lzd_o_b
);
	integer i;
	wire non_a = 1'b0;
	wire non_b = 1'b0;
	reg chag_a = 1'b0;
	reg chag_b = 1'b0;
	reg [34:0]dividend;
	reg [29:0]divisor;
	reg [4:0]lzd_a,lzd_b;
	reg [23:0]shift_a,shift_b;
	
	assign non_a = ~(|exp_a);
	assign non_b = ~(|exp_b);
	
	always @(*) begin
	lzd_a = 5'b0;
	lzd_b = 5'b0;
	chag_a = 1'b0;
	chag_b = 1'b0;

	//使阶码自或,以判断是否为非规格化数，若是，则检查前导零并左移
	if(non_a == 1'b1) begin
		shift_a = {1'b0, mant_a};
		for(i = 0 ;i < 24 && chag_a != 1'b1;i = i + 1) begin
		if(shift_a[23-i] == 1'b1) begin
			chag_a = 1'b1;
		end else begin
			chag_a = 1'b0;
			lzd_a = lzd_a + 1;
		end
		end
		shift_a = shift_a << lzd_o_a;
	end else begin
		shift_a = {1'b1, mant_a};
	end

	if(non_b == 1'b1) begin
		shift_b = {1'b0, mant_b};
		for(i = 0 ;i < 24 && chag_b != 1'b1;i = i + 1) begin
		if(shift_b[23-i] == 1'b1) begin
			chag_b = 1'b1;
		end else begin
			chag_b = 1'b0;
			lzd_b = lzd_b + 1;
		end
		end
		shift_b = shift_b << lzd_o_b;
	end else begin
		shift_b = {1'b1, mant_b};
	end

	dividend = {7'b0, shift_a, 4'b0};
	divisor = {shift_b, 6'b0};
	end
	assign dividend_m = dividend;
	assign divisor_m = divisor;
	assign lzd_o_a = lzd_a;
	assign lzd_o_b = lzd_b;

endmodule

//计算指数中间结果
module adder_1(
	input [7:0]exp_a,exp_b,
	input [4:0]lzd_o_a,lzd_o_b,
	output [9:0]exp_mid
);
	wire [7:0]n_lzd_a,n_lzd_b,n_exp_b,o_0,o_1,o_2,o_3;
	wire [3:0]c;
	wire s;

	assign n_lzd_a = ~({3'b0, lzd_o_a}); 	
	assign n_lzd_b = ~({3'b0, lzd_o_b}); 
	assign n_exp_b = ~exp_b;
	assign s = 1'b1 + c[0] + c[1] + c[2] + c[3];
	assign exp_mid = {s, 1'b0, o_3};

	//exp_a减去exp_b和可能存在的前导零数量，最后加127
	CLA_8 cla0(exp_a, n_exp_b, 1'b1, o_0, c[0]);
	CLA_8 cla1(o_0, 8'b01111111, 1'b0, o_1, c[1]);
	CLA_8 cla2(o_1, n_lzd_a, 1'b1, o_2, c[2]);
	CLA_8 cla3(o_2, n_lzd_b, 1'b1, o_3, c[3]);
endmodule

//迭代计算尾数的商
module iteration(
	input [34:0] dividend_m,
	input [29:0] divisor_m,
	input clk,
	input start,       
	output reg [31:0] Q,
	output reg done  
);
	localparam IDLE = 2'b00;
	localparam SAVE = 2'b01;
	localparam CALC = 2'b10;
	localparam DONE = 2'b11;
    
	reg [1:0] state = 2'b00;
	reg [3:0] iter_count; 
	reg [8:0] bound_cmp_sign;
	reg [13:0] rw_estimate;
	reg [11:0] part_rem,part_rem_1;
	reg [31:0] q,Q_reg, Q_minus;
	reg [34:0] a, b, c,sum_1, carry_1,sum_2, carry_2, carry_shift, sum_shift,carry_shift_1,sum_shift_1;
	wire [8:0] bound_cmp_sign_1;
	wire [7:0] out_1, out_2;
	wire [1:0] c0;
    
	QSL qsl(
		.bound_sel(divisor_m[29:23]),
		.sqrt_first_round(1'b0),
		.sqrt_secd_round(1'b0),
		.sqrt_secd_round_sign(1'b0),
		.part_rem(part_rem),
		.bound_cmp_sign(bound_cmp_sign_1)
	);
    
	CLA_8 cla0(
		.a(sum_shift[28:21]),
		.b(carry_shift[28:21]),
		.cin(1'b0),
		.f(out_1),
		.cout(c0[0])
	);
    
	CLA_8 cla1(
		.a({2'b0, sum_shift[34:29]}),
		.b({2'b0, carry_shift[34:29]}),
		.cin(c0[0]),
		.f(out_2),
		.cout(c0[1])
	);

	always @(posedge clk) begin
	case(state)
		IDLE: begin
                if(start) begin
			Q_reg <= 32'b0;
			Q <= 32'b0;
			Q_minus <= 32'b0;
			iter_count <= 3'b0;
			state <= SAVE;
			done <= 1'b0;
                end
		end
            
		SAVE: begin
			sum_shift <= dividend_m << 4;
			carry_shift <= 35'b0; 
			Q_reg <= 32'b0;
			Q_minus <= 32'b0;
			state <= CALC;
		end

		CALC: begin
                // 计算部分余数绝对值
		
                // 更新商
                if(rw_estimate[13] == 1'b0) begin
			Q_reg <= (Q_reg << 4) + q;
			Q_minus <= (Q_reg << 4) + q - 1;
                end else begin
			Q_reg <= (Q_minus << 4) + q + 32'd16;
			Q_minus <= (Q_minus << 4) + q + 32'd15;
                end
                
                sum_shift <= sum_2 << 4;
                carry_shift <= carry_2 << 5;
                
                if(iter_count == 4'b0111) begin
			state <= DONE;
                end else begin
			iter_count <= iter_count + 1;
                end
		end
            
		DONE: begin
                Q <= Q_reg;
                done <= 1'b1;
                state <= IDLE;
		end
	endcase
	end
    
	always @(*) begin
	case(bound_cmp_sign)
		9'b111111111:begin
			a = 35'b0;
			b = 35'b0;
			c = 35'b0;
		end
		9'b011111111:begin
			a = {5'b0, divisor_m};
			b = 35'b0;
			c = 35'b0;
		end
		9'b001111111:begin
			a = 35'b0;
			b = {4'b0, divisor_m, 1'b0};
			c = 35'b0;
		end
		9'b000111111:begin
			a = {5'b0, divisor_m};
			b = {4'b0, divisor_m, 1'b0};
			c = 35'b0;
		end
		9'b000011111:begin
			a = 35'b0;
			b = 35'b0;
			c = {3'b0, divisor_m, 2'b0};
		end
		9'b000001111:begin
			a = {5'b0, divisor_m};
			b = 35'b0;
			c = {3'b0, divisor_m, 2'b0};
		end
		9'b000000111:begin
			a = 35'b0;
			b = {4'b0, divisor_m, 1'b0};
			c = {3'b0, divisor_m, 2'b0};
		end
		9'b000000011:begin
			a = {5'b0, divisor_m};
			b = {4'b0, divisor_m, 1'b0};
			c = {3'b0, divisor_m, 2'b0};
		end
		9'b000000001:begin
			a = 35'b0;
			b = 35'b0;
			c = {2'b0, divisor_m, 3'b0};
		end
		9'b000000000:begin
			a = {5'b0, divisor_m};
			b = 35'b0;
			c = {2'b0, divisor_m, 3'b0};
		end
	endcase	
        
        if(~rw_estimate[13]) begin
            a = ~a + 1;
            b = ~b + 1;
            c = ~c + 1;
        end
        
        sum_1 = a ^ b ^ c ^ sum_shift;
        carry_1 = (a & b) | ((a | b) & c) | ((a | b | c) & sum_shift);
        sum_2 = sum_1 ^ (carry_1 << 1) ^ carry_shift;
        carry_2 = (sum_1 & (carry_1 << 1)) | ((sum_1 | (carry_1 << 1)) & carry_shift);
	end   

	always @(*) begin
    	rw_estimate = {out_2[5:0], out_1};
	part_rem = rw_estimate[13] ? ~rw_estimate[13:2] : rw_estimate[13:2];
	if(bound_cmp_sign_1[0] != 0) 
		bound_cmp_sign = bound_cmp_sign_1;

	case(bound_cmp_sign)
		9'b111111111:q = rw_estimate[13] ? 32'b0: 32'b0;
		9'b011111111:q = rw_estimate[13] ? 32'hFFFFFFFF: 32'd1;
		9'b001111111:q = rw_estimate[13] ? 32'hFFFFFFFE: 32'd2;
		9'b000111111:q = rw_estimate[13] ? 32'hFFFFFFFD: 32'd3;
		9'b000011111:q = rw_estimate[13] ? 32'hFFFFFFFC: 32'd4;
		9'b000001111:q = rw_estimate[13] ? 32'hFFFFFFFB: 32'd5;
		9'b000000111:q = rw_estimate[13] ? 32'hFFFFFFFA: 32'd6;
		9'b000000011:q = rw_estimate[13] ? 32'hFFFFFFF9: 32'd7;
		9'b000000001:q = rw_estimate[13] ? 32'hFFFFFFF8: 32'd8;
		9'b000000000:q = rw_estimate[13] ? 32'hFFFFFFF7: 32'd9;	
		default:q = 32'b0;
	endcase
	// 根据bound_cmp_sign选择q值
	end

endmodule

//对运算结果进行移位与剪切，输出结果尾数与阶码
module round_to_nearest_even(
	input done,
	input [31:0]Q,
	input [9:0]exp_q_mid,
	output reg [22:0]mant_o,
	output reg [7:0]exp_o
);
	reg [31:0]Q_1;

	always @(*) begin
	if(done) begin
	exp_o = exp_q_mid[7:0];
	if(~Q[31]) 
		Q_1 = Q << 1;		
	else begin
		Q_1 = Q;
		exp_o = exp_o + 1;
	end

	if(Q_1[7] == 1'b0) begin
		mant_o = Q_1[30:8];
	end else if(Q_1[7] == 1'b1) begin
		if(Q_1[30:8] == 23'b11111111111111111111111) begin
			exp_o = exp_o + 1;
			mant_o = 23'b00000000000000000000000;
		end else begin
			mant_o = Q_1[30:8];
			mant_o = mant_o + 1;
		end
	end //使用就近舍入偶数原则得出最终的23位尾数
	end
	end	

endmodule

//进行最终包装
module pack(
	input s_o,adn,done,
	input start,
	input [7:0]exp_o,
	input [22:0]mant_o,
	input [1:0]state,
	output reg[31:0]answer
);
	always @(*) begin
	if(start) 
		answer = 0;

	if(done) begin
	if(adn == 1'b0) begin
		answer[31:0] = {s_o, exp_o[7:0], mant_o[22:0]};
	end else if(adn == 1'b1) begin
		if(state == 2'b01) begin	//被除数为0，除数为非异常值
			answer = 32'b0;
		end else if(state == 2'b10) begin	//被除数为无穷大，除数为正常值
			answer = {1'b1, 8'b11111111, 23'b0};
		end else begin	//其他情况
			answer = {1'b1, 8'b11111111, 23'b1};
		end
	end
	end
	end	
	
endmodule