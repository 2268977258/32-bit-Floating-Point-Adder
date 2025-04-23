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

详细说明：根据unpack的结果判断输入是否为异常值如NaN、无穷大、零输出为一位的adn和两位的state。若检测到异常，将输出adn置1，直接输出32位FP32结果：若两数均为零，输出state为00，返回零；若两数均为无穷大且符号相同，输出state为01，返回该无穷大，符号不同，输出state为10，返回NaN任一输入为NaN，输出state为11，返回NaN。
