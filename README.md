# 32-bit-Floating-Point-Adder
这个 Verilog 小项目基于linux系统的VCS仿真实现了一个符合IEEE 754 单精度浮点数标准（32 位）的浮点数加法器（FP32）的完整设计。该设计的目标是通过硬件描述语言（Verilog）实现一个能够处理两输入浮点数的加法运算模块。它包含了从输入数据的解析、异常值处理、对齐操作、加减法计算到结果归一化和输出包装的完整流程。以下是对代码功能和模块的详细介绍：

![image](photo/图片1.png)

图1 FP32加法器架构图

各模块功能详情：

·unpack
        
    功能：将输入的FP32数分解为符号位（s）、指数（exp）和尾数（mantissa），并处理非规格化数。
    
    详细说明：分离符号位（1 bit，s_a与s_b）、指数（8 bit，exp_a与exp_b）和尾数（23 bit，mant_a与mant_b）。

·outlier handling

        功能：处理异常值

        详细说明：根据unpack的结果判断输入是否为异常值如NaN、无穷大、零输出为一位的adn和两位的state。
        若检测到异常，将输出adn置1，直接输出32位FP32结果：若两数均为零，输出state为00，返回零；
        若两数均为无穷大且符号相同，输出state为01，返回该无穷大，符号不同，输出state为10，返回NaN任一输入为NaN，输出state为11，返回NaN。

·compare

        功能：比较两输入数的大小，确定对齐策略。

        详细说明：根据unpack的结果指数（8 bit）和尾数（24 bit）比较输入绝对值的大小。先比较阶码的大小，若相等，再进一步比较尾数大小。
        若尾数还是相等的，将输出值same置1。输出结果a_larger（1 bit）s_o（1 bit，绝对值较大的输入的符号位）same（1bit，判断是否相等）。

·exp_aligner

        功能：负责指数对齐，并计算差值exp_diff = |exp_a - exp_b|。
        
        详细说明：输出较大的指数exp_larger （8 bit）作为中间结果的指数，
        根据两指数大小计算exp_a - exp_b 或 exp_b - exp_a 得到exp_diff 输出（8bit）。

·shifter_1

        功能：将尾数右移对齐。

        详细说明：将mant_a， mant_b，低位补0（25bit） 扩充到48bit，若输入的same值为0，
        则根据输入a_larger选择较小的数，将其右移exp_diff 位，得到s_shift（48bit），较大的数右移一位空出符号位，输出结果l_shift（48bit）。
        若输入的same值为一，则直接输出结果l_shift（48bit），s_shift（48bit）。

·XOR

        功能：执行异或操作

        详细说明：对输入两个符号位s_a和s_b执行异或操作，判断符号位是否不同。
        如果不同，则实际操作为尾数的减法，输出值XOR为1’b1；如果相同，则为加法，输出值XOR为1’b0。

·adder_1

        功能：执行48位加法操作
        
        详细说明：输入l_shift，s_shift，若输入的XOR为1则执行加法，
        若输入的XOR为0，则将s_shift取反并加一，执行减法操作，输出48bit加法结果adder_1_o

·LZD（Leading Zero Detector）

        功能：对adder_1_o进行前导零检测。

        详细说明：输入为adder_1_o（48bit），输出为adder_1_o结果最高位的1前0的个数lzd_o（8bit）

·shift_and_cut

        功能：对结果进行移位与剪切，输出尾数与阶码。

        详细说明：正常情况下使adder_1_o左移lzd_o，输入到num_sh（48bit）中，并使exp_o（8bit）等于exp_larger减去（lzd_o-1）。
        特殊情况需考虑：lzd为0，代表有进位，adder_1_o直接等于num_sh，指数位exp_o = exp_larger + 1；
        exp_larger<lzd，输出可能是非规格化数，adder_1_o左移exp_larger作为num_sh，
        若num_sh最高位为1，exp_o为1，num_sh最高位为0，exp_o为0；若输入的adder_1_o为零，则直接使exp_o等于零。
        最后使用就近舍入到偶数的规则（IEEE 754默认的舍入模式）,将num_sh舍入到23位尾数。
        若要舍去的数组元素中的最高位为1，则舍入尾数使其加1，如舍入操作使尾数溢出，则使指数加1。
        模块输出舍入后结果输出为mant_o（23 bit），exp_o（8bit）。
