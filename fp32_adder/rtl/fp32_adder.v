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

//48位加法器
module CLA_48 (
	input [47:0] a,b,   
	input cin, 
	output [47:0] f,
	output cout
);
	wire [5:0] carry; 
	wire [47:0] outc;

	CLA_8 cla0 (a[7:0], b[7:0], cin, outc[7:0], carry[0]);
	CLA_8 cla1 (a[15:8], b[15:8], carry[0], outc[15:8], carry[1]);
	CLA_8 cla2 (a[23:16], b[23:16], carry[1], outc[23:16], carry[2]);
	CLA_8 cla3 (a[31:24], b[31:24], carry[2], outc[31:24], carry[3]);
	CLA_8 cla4 (a[39:32], b[39:32], carry[3], outc[39:32], carry[4]);
	CLA_8 cla5 (a[47:40], b[47:40], carry[4], outc[47:40], carry[5]);
	assign cout = carry[5];
	assign f = outc;

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
	if(exp_a == 8'b0 && mant_a == 23'b0 && exp_b == 8'b0 && mant_a == 23'b0) begin
		adn = 1;
		state = 2'b00;	//两个零
	end else if(exp_a == 8'b11111111 && mant_a == 23'b0 && exp_b == 8'b11111111 && mant_b == 23'b0 && s_a == s_b) begin
		adn = 1;
		state = 2'b01;	//两个同号无穷大
	end else if(exp_a == 8'b11111111 && mant_a == 23'b0 && exp_b == 8'b11111111 && mant_b == 23'b0 && s_a != s_b) begin
		adn = 1;
		state = 2'b10;	//两个异号无穷大		
	end else if(exp_a == 8'b11111111 && mant_a != 23'b0 || exp_b == 8'b11111111 && mant_b != 23'b0) begin
		adn = 1;
		state = 2'b11;	//存在NaN		
	end else if(exp_a == 8'b11111111 && mant_a == 23'b0 && exp_b != 8'b11111111 || exp_b == 8'b11111111 && mant_b == 23'b0  && exp_a != 8'b11111111) begin
		adn = 1;
		state = 2'b01;	//只存在一个无穷大
	end else begin
		adn = 0;
	end
	end

endmodule

//比较绝对值大小
module compare(
	input s_a,s_b,
	input [7:0]exp_a,exp_b,
	input [22:0]mant_a,mant_b,
	output reg same,
	output reg a_larger,
	output reg s_o
);
	always @(*) begin
	same = 1'b0;
	if(exp_a > exp_b) begin
		a_larger = 1'b1;
		s_o = s_a;
	end else if(exp_a < exp_b) begin
		a_larger = 1'b0;
		s_o = s_b;		
	end else if(exp_a == exp_b) begin
		if(mant_a > mant_b) begin
			a_larger = 1'b1;
			s_o = s_a;
		end else if(mant_a < mant_b) begin
			a_larger = 1'b0;
			s_o = s_b;
		end else if(mant_a == mant_b) begin
			same = 1'b1;
			a_larger = 1'b0;
			s_o = s_b;
		end	
	end
	end

endmodule

//计算阶码差值
module exp_aligner(
	input [7:0]exp_a,exp_b,
	input same,
	output reg[7:0]exp_diff,exp_larger
);
	reg [7:0]num_a,num_b,para_1,para_2;
	wire [7:0]outc;
	wire cout;

	always @(*) begin
	num_a = exp_a;
	num_b = exp_b;
	//阶码转为补码	
	if(exp_a > exp_b) begin
		exp_larger = exp_a;
		para_1 = num_a;
		para_2 = ~num_b;
		exp_diff = outc;
	end else if(exp_a < exp_b) begin
		exp_larger = exp_b;
		para_1 = num_b;
		para_2 = ~num_a;
		exp_diff = outc;	
	end else if(exp_a == exp_b) begin
		exp_diff = 8'b0;
		exp_larger = exp_a;
	end
	end
	CLA_8 cla(para_1, para_2, 1'b1, outc, cout);

endmodule

//对符号位进行异或计算决定进行加法还是减法
module XOR(
	input s_a,s_b,
	output XOR
);
	assign XOR = s_a ^ s_b;

endmodule

//将尾数对齐
module shift_1(
	input [22:0]mant_a,mant_b,
	input [7:0]exp_diff,
	input a_larger,same,
	output reg[47:0]l_shift,s_shift
);
	reg [47:0]com_a,com_b;
	
	always @(*) begin
	com_a = {mant_a, 25'b0};	
	com_b = {mant_b, 25'b0};
	if(a_larger == 1'b1 && same == 1'b0) begin
		l_shift = com_a >> 1'b1;
		s_shift = com_b >> (exp_diff + 1'b1);
	end else if(a_larger == 1'b0 && same == 1'b0) begin
		l_shift = com_b >> 1'b1;
		s_shift = com_a >> (exp_diff + 1'b1);
	end else if(same == 1'b1) begin
		l_shift = com_a >> 1'b1;
		s_shift = com_b >> 1'b1;
	end
	end

endmodule

//根据异或结果进行48位加法或减法计算
module adder_1(
	input [47:0]l_shift,s_shift,
	input XOR,
	output [47:0]adder_1_o
);
	wire cout;
	wire [47:0]outc;
	reg cin;
	reg [47:0]para_1,para_2;

	always @(*) begin
	if(XOR == 1'b1) begin
		para_1 = l_shift;
		para_2 = ~s_shift;
		cin = 1'b1;
	end else if(XOR == 1'b0) begin
		para_1 = l_shift;
		para_2 = s_shift;
		cin = 1'b0;
	end
	end
	assign adder_1_o = outc;
	CLA_48 cla_48(para_1, para_2, cin, outc, cout);

endmodule

//计算结果第一个1前有几位0
module LDZ(
	input [47:0]adder_1_o,
	output reg[7:0]ldz_o
);
	integer i;
	reg chag = 1'b0;
	reg [7:0]cout = 8'b0;
	
	always @(*) begin
	cout = 8'b0;
	for(i = 0 ;i < 48 && chag != 1'b1;i = i + 1) begin
	if(adder_1_o[47-i] == 1'b1) begin
		chag = 1'b1;
	end else if(adder_1_o[47-i] == 1'b0) begin
		chag = 1'b0;
		cout = cout + 1;
	end
	end
	ldz_o = cout;
	end

endmodule

//对运算结果进行移位与剪切，输出结果尾数与阶码
module shift_and_cut(
	input [47:0]adder_1_o,
	input [7:0]ldz_o,
	input [7:0]exp_larger,
	output reg[7:0]exp_o,
	output reg[22:0]mant_o
);
	reg [47:0] num_sh;	

	always @(*) begin
	if(ldz_o == 8'b0 && adder_1_o != 48'b0) begin 
		num_sh = adder_1_o;
		exp_o = exp_larger + 1;		
	end else if(exp_larger < ldz_o && adder_1_o != 48'b0) begin 
		num_sh = adder_1_o << exp_larger;
		exp_o = (num_sh[47] == 1'b1) ? 8'b1 : 8'b0;		
	end else if(adder_1_o == 48'b0) begin 
		num_sh = adder_1_o;
		exp_o = 8'b0;		
	end else begin
		num_sh = adder_1_o << ldz_o;
		exp_o = exp_larger - ldz_o + 1'b1;
	end //整理尾数与阶码

	if(num_sh[24] == 1'b0) begin
		mant_o = num_sh[47:25];
	end else if(num_sh[24] == 1'b1) begin
		if(num_sh[47:25] == 23'b11111111111111111111111) begin
			exp_o = exp_o + 1;
			mant_o = 23'b10000000000000000000000;
		end else begin
			mant_o = num_sh[47:25];
			mant_o = mant_o + 1;
		end
	end //使用就近舍入偶数原则得出最终的23位尾数
	end

endmodule

//进行最终包装
module pack(
	input s_o,adn,
	input [7:0]exp_o,
	input [22:0]mant_o,
	input [1:0]state,
	output reg[31:0]answer
);
	always @(*) begin
	if(adn == 1'b0) begin
		answer[31:0] = {s_o, exp_o[7:0], mant_o[22:0]};
	end else if(adn == 1'b1) begin
		if(state == 2'b00) begin
			answer = 32'b0;
		end else if(state == 2'b01) begin
			answer = {s_o, 8'b11111111, 23'b0};
		end else if(state == 2'b10) begin
			answer = {s_o, 8'b11111111, 23'b1};
		end else if(state == 2'b11) begin
			answer = {s_o, 8'b11111111, 23'b1};
		end
	end
	end

endmodule