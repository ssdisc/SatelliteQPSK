%% 卫星QPSK接收机MATLAB实现深度解析教程
% 本教程完全按照原始TUTORIAL.md的结构设计，逐步解析程梓睿同学实现的QPSK信号接收机。
% 首先介绍项目背景和理论基础，然后详细解析每个核心模块的实现原理和代码细节。

%% 1. 项目简介与理论背景

%% 1.1 项目概述
% 本项目旨在使用MATLAB从零开始构建一个功能完备的QPSK（四相相移键控）信号接收机。
% 该接收机能够处理一个真实的、从文件中加载的卫星中频IQ（同相/正交）数据流，
% 通过一系列精密的数字信号处理步骤——包括匹配滤波、定时恢复、载波恢复、帧同步和解扰——
% 最终准确地恢复出原始传输的二进制数据。
%
% 真实世界应用背景：本教程所用到的技术和信号处理流程，与真实的遥感卫星
% （如SAR合成孔径雷达卫星）下行数据链路解调项目高度相似。
% 掌握这些技能意味着您将有能力处理实际的星地通信数据。
%
% 这不仅仅是一个代码复现练习，更是一次深入探索数字通信物理层核心技术的旅程。
% 通过本教程，您将能够：
% *   理解理论：将通信原理中的抽象概念（如RRC滤波器、Gardner算法、锁相环）与实际的MATLAB代码对应起来。
% *   掌握实践：亲手操作、调试并观察信号在接收机中每一步的变化，建立直观而深刻的认识。
% *   获得能力：具备分析、设计和实现基本数字接收机模块的能力，为更复杂的通信系统设计打下坚实基础。

%% 1.2 QPSK在卫星通信中的重要性
% QPSK是一种高效的数字调制技术，它在每个符号（Symbol）中编码2个比特（bits）的信息。
% 相比于BPSK（每个符号1比特），QPSK在不增加带宽的情况下将数据传输速率提高了一倍，
% 这使其在频谱资源受限的卫星通信中极具吸引力。
% 
% 同时，QPSK信号具有恒定的包络（在理想滤波后），这对卫星转发器上的功率放大器（HPA）非常友好，
% 可以使其工作在效率最高的饱和区附近，而不会引入过多的非线性失真。
% 这种功率效率和频谱效率之间的良好平衡，使QPSK成为众多卫星通信标准（如DVB-S, CCSDS）中的首选调制方式之一。

%% 1.3 CCSDS标准与本项目关联
% 本项目处理的信号帧结构遵循 **CCSDS (空间数据系统咨询委员会)** 的AOS (Advanced Orbiting Systems) 建议标准。
% 具体来说：
% *   帧同步字: 帧同步模块使用了 1ACFFC1D (十六进制) 作为同步字。
%     这个特定的32比特序列经过精心设计，具有非常优秀的自相关特性——即只有在完全对齐时，
%     其相关峰值才最高，而在其他任何偏移位置，其相关值都非常低。
%     这使得接收机能够在充满噪声的信号流中以极高的概率准确地找到数据帧的起始边界。
% *   AOS帧结构: 根据《卫星数传信号帧格式说明.pdf》，每个数据帧的总长度为 1024字节，由以下部分组成：
%    *   同步字 (ASM): 4字节 (0x1ACFFC1D)
%    *   AOS帧头: 6字节
%    *   数据负载: 886字节
%    *   LDPC校验码: 128字节
%
% 理解此帧结构是正确解析数据的关键。

%% 2. 技术路径选择与系统架构

%% 2.1 技术路径概述
% 本项目采用开放式设计理念，支持不同的技术实现路径，学生可根据自身技术背景和兴趣自主选择。
% 为了更好地展开对原理的分析以及考虑到无线电爱好者朋友对自由度的需求，
% 这里仅引用了纯Matlab实现，教学实践中也有同学使用matlab+simulink实现，未在本项目中详细描述：
%
% 路径一：纯MATLAB编程实现（程梓睿方案）
% - 特点：完全基于MATLAB脚本和函数实现，注重算法原理的深度理解
% - 适合对象：希望深入理解算法细节、具备一定编程基础的学生
% - 核心优势：
%   - 算法参数可精确控制
%   - 调试过程清晰可见
%   - 便于算法创新和优化
% - 主要实现文件：student_cases/14+2022210532+chengzirui/

%% 2.2 技术路径特点
% 纯MATLAB路径（程梓睿方案）
% | 维度 | 特点 |
% |------|------|
% | 学习深度 | 深入算法细节 |
% | 实现难度 | 中等-高 |
% | 调试便利性 | 逐步调试 |
% | 扩展性 | 算法定制容易 |
% | 工程化程度 | 基础 |

%% 3. 系统架构与处理流程
% 本QPSK接收机的处理流程是模块化的，每个模块负责一个特定的信号处理任务。
% 主脚本 SatelliteQPSKReceiverTest.m 负责配置全局参数，
% 并调用核心处理函数 lib/SatelliteQPSKReceiver.m。
% 其内部处理流程将在后续章节中进行深度解析。
%
% 各模块核心功能简介:
% 1.  信号加载: 从二进制文件中读取原始IQ样本。
% 2.  重采样: 将原始500Msps的采样率降采样至150Msps，在保证信号质量的同时提高处理效率。
% 3.  RRC滤波: 作为匹配滤波器，最大化信噪比，并消除码间串扰（ISI）。
% 4.  AGC: 自动调整信号幅度，为后续模块提供稳定的输入电平。
% 5.  定时同步: (Gardner) 找到每个符号波形的"最佳"采样时刻。
% 6.  载波同步: (PLL) 校正频率与相位偏差，锁定星座图。
% 7.  相位模糊恢复 & 帧同步: 由于QPSK的相位对称性，PLL锁定后可能存在0, 90, 180, 270度的相位模糊。
%     此模块通过穷举四种相位并与已知的1ACFFC1D同步字进行相关匹配，
%     在确定正确相位的同时，定位数据帧的起始边界。
% 8.  解扰: 根据CCSDS标准，使用1+X^14+X^15多项式，对已同步的帧数据进行解扰，
%     恢复出经LDPC编码后的原始数据。
% 9.  数据输出: 将恢复的比特流转换为字节，并写入文件。
%     此时的数据包含AOS帧头、数据负载和LDPC校验位。

%% 4. 环境准备与文件说明

%% 4.1 环境设置
% 1.  MATLAB环境: 推荐使用 R2021a 或更高版本，以确保所有函数
%     （特别是信号处理工具箱中的函数）都可用。
% 2.  项目文件: 下载或克隆整个项目到您的本地工作目录
%     （例如 D:\matlab\SatelliteQPSK）。
% 3.  数据文件: 获取项目数据文件（如sample_0611_500MHz_middle.bin），
%     并将其放置在项目的data/目录下。这是一个16位复数（int16）格式的文件，
%     原始采样率为500MHz，其中I和Q分量交错存储。也可直接使用提供的1MB测试数据。
% 4.  MATLAB路径: 打开MATLAB，并将当前目录切换到您解压的项目根目录。
%     同时，将 lib 目录添加到MATLAB的搜索路径中，或在主脚本中通过 addpath('lib') 添加。

%% 4.2 关键文件解析
% *   SatelliteQPSKReceiverTest.m: 主测试脚本。这是您需要运行的入口文件。
%     它定义了所有的配置参数（如文件名、采样率、符号率等），调用核心接收机函数，
%     并负责绘制最终的调试图窗。
% *   lib/SatelliteQPSKReceiver.m: 核心接收机封装器。
%     该函数按照第2节描述的流程，依次调用各个信号处理模块，实现了完整的接收链路。
% *   lib/: 核心函数库目录。存放了所有独立的信号处理模块，例如：
%     *   lib/SignalLoader.m: 数据加载模块。
%     *   lib/RRCFilterFixedLen.m: RRC滤波器。
%     *   lib/GardnerSymbolSync.m: Gardner定时同步算法。
%     *   lib/QPSKFrequencyCorrectPLL.m: 载波同步锁相环。
%     *   lib/FrameSync.m: 帧同步模块。
%     *   等等。
% *   Ibytes.txt / Qbytes.txt: 输出文件。接收机成功运行后，恢复出的I路和Q路数据
%     将以字节流的形式分别保存在这两个文本文件中。

%% 4.3 快速复现步骤
% 本节提供一个快速上手指南，帮助您快速运行程梓睿同学实现的QPSK接收机。

% 环境配置
% 添加库路径
addpath('student_cases/14+2022210532+chengzirui/lib');

% 清除工作区
clear; clc;

% 参数配置
config.inputDataFilename = "data/small_sample_256k.bin"; % 使用小数据文件进行测试
config.sourceSampleRate = 500e6; % 原始信号采样率
config.resampleMolecule = 3; % 重采样分子
config.resampleDenominator = 10; % 重采样分母
config.fs = 150e6; % 重采样后的采样率
config.fb = 150e6; % 数传速率150Mbps
config.startBits = 0; % 文件读取数据的起始点
config.bitsLength = -1; % 自动处理文件中的所有数据
config.rollOff = 0.33; % 滚降系数

% 输出文件配置
output_dir = 'student_cases/14+2022210532+chengzirui/out';
config.IBytesFilename = fullfile(output_dir, 'Ibytes.txt'); % I路比特输出文件
config.QBytesFilename = fullfile(output_dir, 'Qbytes.txt'); % Q路比特输出文件
config.IQBytesFilename = fullfile(output_dir, 'IQbytes.txt'); % IQ路交织输出文件
config.keepRedundantData = true; % 新增：是否保留完整帧（同步字+冗余）
config.FullFrameIBytesFilename = fullfile(output_dir, 'Ibytes_full.txt'); % 新增：完整帧I路输出
config.FullFrameQBytesFilename = fullfile(output_dir, 'Qbytes_full.txt'); % 新增：完整帧Q路输出
config.FullFrameIQBytesFilename = fullfile(output_dir, 'IQbytes_full.txt'); % 新增：完整帧IQ交织输出
config.UnscrambledHexFilename = fullfile(output_dir, 'unscrambled_hex.txt'); % 新增：未解扰的十六进制数据输出

fprintf('将自动处理文件中的所有数据点\n');

% 运行接收机
% 调用核心处理函数
[I_bytes, Q_bytes] = SatelliteQPSKReceiver(config);

% 验证结果
% 检查输出结果
disp('处理完成，检查输出文件:');
disp(config.IBytesFilename);
disp(config.QBytesFilename);

%% 5. 核心模块详解与复现 (深度分析)
% 本章节是教程的核心。以下将以程梓睿同学的实现为主，逐一深入每个关键模块，
% 剖析其背后的理论、参数选择、代码实现，并指导您如何通过调试观察其效果。
% 其他两位同学的实现可以参考该教程自行理解。

%% 5.1 预备步骤：加载数据
% 1.  打开主脚本 SatelliteQPSKReceiverTest.m。
% 2.  熟悉 config 结构体中的各项参数，特别是 startBits 和 bitsLength，
%     它们决定了从数据文件的哪个位置开始处理，以及处理多长的数据段。

%% 5.2 模块详解: RRC匹配滤波
% 预期效果: 信号通过RRC滤波器后，频谱被有效抑制在符号速率范围内，眼图张开，为后续的定时同步做好了准备。

%% 理论指导
% 在数字通信系统中，为了限制信号带宽并消除码间串扰（ISI），
% 发送端通常使用一个脉冲成形滤波器。
% 最常用的就是升余弦（Raised Cosine, RC）或其平方根——根升余弦（Root Raised Cosine, RRC）滤波器。
% 
% 奈奎斯特第一准则指出，如果一个滤波器的冲激响应在符号间隔的整数倍时刻上除了中心点外都为零，
% 那么它就不会引入ISI。RC滤波器满足此准则。
% 
% 为了在发射机和接收机之间优化信噪比，通常采用匹配滤波器方案：
% 即发射机和接收机各使用一个RRC滤波器。
% 两个级联的RRC滤波器等效于一个RC滤波器，既满足了无ISI准则，又实现了最佳的信噪比性能。

%% 参数选择: 滚降系数 alpha
% alpha 是RRC滤波器最重要的参数，其取值范围为 [0, 1]。
% 
% 基本概念澄清:
% *   比特率 (Bit Rate, f_bit): 每秒传输的比特数。本项目为 150 Mbps。
% *   符号率 (Symbol Rate / Baud Rate, f_sym): 每秒传输的符号数。
%     由于QPSK每个符号承载2个比特，因此符号率为 f_sym = f_bit / 2 = 75 MBaud/s。
%     在代码和后续讨论中，fb 常常指代符号率。
% 
% 物理意义: alpha 决定了信号占用的实际带宽。信号带宽 BW = (1 + alpha) * f_sym。
% 
% 取值影响:
% *   alpha = 0: 带宽最窄（等于奈奎斯特带宽 f_sym），但其冲激响应拖尾很长，对定时误差非常敏感。
% *   alpha = 1: 带宽最宽（等于 2 * f_sym），冲激响应衰减最快，对定时误差最不敏感，但频谱利用率最低。
% *   在本项目中 (config.rollOff = 0.33): 这是一个非常典型且工程上常用的折中值。
%     它在保证较低带外泄露的同时，提供了对定时误差较好的鲁棒性。

%% 代码实现与复现
% 在 lib/RRCFilterFixedLen.m 中，核心是MATLAB的 rcosdesign 函数。
% 
% ```matlab
% % lib/RRCFilterFixedLen.m
% function y = RRCFilterFixedLen(fb, fs, x, alpha, mode)
%     % 参数
%     span = 8; % 滤波器长度（单位符号数），即滤波器覆盖8个符号的长度
%     sps = floor(fs / fb); % 每符号采样数 (Samples Per Symbol)
%     
%     % 生成滤波器系数
%     % 'sqrt' 模式指定了生成根升余弦(RRC)滤波器
%     h = rcosdesign(alpha, span, sps, 'sqrt');
%     
%     % 卷积，'same' 参数使输出长度与输入长度一致
%     y = conv(x, h, 'same');
% end
% ```

%% 复现与观察:
% 1. 在调试模式下，执行到RRC滤波行。
% 2. 观察频谱：执行完此行后，在命令窗口绘制滤波后信号的功率谱。
%    figure;
%    pwelch(s_qpsk, [], [], [], config.fs, 'centered'); % 注意使用重采样后的fs
%    title('RRC滤波后的信号频谱');
%    您应该能看到信号的功率被集中在奈奎斯特带宽 [-f_sym/2, f_sym/2] (即 [-37.5, 37.5] MHz) 附近，
%    总带宽约为 (1+alpha)*f_sym。频谱边缘有平滑的滚降。
% 3. 观察星座图：此时绘制星座图 scatterplot(s_qpsk)，由于未经任何同步，
%    它看起来会是一个非常模糊的、旋转的环形。这是正常的。

%% 5.3 模块详解: Gardner定时同步
% 预期效果: 经过Gardner同步后，采样点被调整到每个符号的最佳位置。
% 此时的星座图，点会从之前的弥散环状开始向四个目标位置收敛，形成四个模糊的"云团"，
% 但由于未经载波同步，整个星座图可能仍在旋转，即仍为环形。

%% 理论指导
% 定时同步的目标是克服由于收发双方时钟频率的细微偏差（符号时钟偏移）导致的采样点漂移问题。
% Gardner算法是一种高效的、不依赖于载波相位的定时误差检测（TED）算法。
% 
% 它的核心思想是：在每个符号周期内，采集两个样本：
% 一个是在预估的最佳采样点（判决点, Strobe Point），
% 另一个是在两个判决点之间的中点（中点, Midpoint）。
% 
% Gardner定时误差检测器的数学公式为：
% 
% e[k] = real{y_mid[k]} * (real{y_strobe[k]} - real{y_strobe[k-1]}) + 
%        imag{y_mid[k]} * (imag{y_strobe[k]} - imag{y_strobe[k-1]})
% 
% 其中 k 是符号索引。
% 
% 直观解释:
% *   如果采样点准确，那么判决点应该落在符号波形的峰值，
%     此时 y_strobe[k] 和 y_strobe[k-1] 的幅度应该相似但符号可能相反。
%     而中点采样 y_mid[k] 应该落在过零点附近，其值接近于0。
%     因此，整体误差 e[k] 接近于0。
% *   如果采样点超前，y_mid[k] 会偏离过零点，导致 e[k] 产生一个正值或负值，指示了超前的方向。
% *   如果采样点滞后，e[k] 会产生一个符号相反的值。

%% Farrow插值器优化（程梓睿创新实现）
% 在程梓睿的纯MATLAB实现中，采用了3阶Farrow立方插值器进行精确的分数延迟插值，
% 这是该实现的技术亮点之一。
% 
% Farrow插值器原理：
% Farrow插值器能够实现任意分数延迟的高精度插值，采用3阶立方多项式结构。
% 在本实现中，使用四个相邻数据点 x(n-1), x(n), x(n+1), x(n+2) 来插值计算 x(n+mu)。
% 
% 插值公式采用Horner形式计算，提高数值稳定性：
% y(n+mu) = ((c3 * mu + c2) * mu + c1) * mu + c0
% 
% 其中mu为分数延迟（0≤mu<1），多项式系数基于输入数据点动态计算：
% - c0 = x(n) 
% - c1 = 1/2[x(n+1) - x(n-1)]
% - c2 = x(n-1) - 2.5x(n) + 2x(n+1) - 0.5x(n+2)
% - c3 = -0.5x(n-1) + 1.5x(n) - 1.5x(n+1) + 0.5x(n+2)
% 
% 技术优势：
% 相比传统线性插值，Farrow插值器能够获得更高的定时精度，
% 特别是在高符号率系统中优势明显。
% 这种优化对于处理真实卫星数据中的定时抖动和频率偏移具有重要意义。

%% 参数选择: 环路带宽 Bn 和阻尼系数 zeta
% 在 lib/GardnerSymbolSync.m 中，环路滤波器的特性由 B_loop (归一化环路带宽) 和 zeta (阻尼系数) 决定。
% 
% 环路带宽 Bn (或 B_loop):
% *   物理意义: 决定了环路对定时误差的跟踪速度和响应能力。
%     它通常被归一化到符号速率 f_sym。带宽越宽，环路锁定速度越快，能跟踪的频率偏差范围也越大。
% *   取值影响: 宽带环路虽然响应快，但对噪声更敏感，会导致锁定后的"抖动"（Jitter）更大。
%     窄带环路对噪声抑制更好，锁定更稳定，但锁定速度慢，跟踪范围小。
%     本项目中 B_loop = 0.0001 是一个相对较窄的带宽（即 0.0001 * f_sym），
%     适用于信噪比较好的场景，追求高稳定度。
% 
% 阻尼系数 zeta:
% *   物理意义: 决定了环路响应的瞬态特性，即如何达到稳定状态。
% *   取值影响:
%     *   zeta < 1: 欠阻尼，环路响应快，但会有超调和振荡。
%     *   zeta = 1: 临界阻尼，最快的无超调响应。
%     *   zeta > 1: 过阻尼，响应缓慢，无超调。
%     *   本项目中 zeta = 0.707: 这是一个经典的、理论上最优的取值，
%         它在响应速度和稳定性之间提供了最佳的平衡，使得环路有大约4%的超调，但能快速稳定下来。

%% 代码实现与复现
% 在 lib/GardnerSymbolSync.m 中，核心逻辑在 for 循环内。
% 
% ```matlab
% % lib/GardnerSymbolSync.m (部分关键代码)
% 
% % ... PI控制器系数计算 ...
% c1 = (4 * zeta * Wn) / (1 + 2 * zeta * Wn + Wn^2);
% c2 = (4 * Wn^2)      / (1 + 2 * zeta * Wn + Wn^2);
% 
% % ... 主循环 ...
% for m = 6 : length(s_qpsk)-3
%     % ... NCO和插值器逻辑，用于产生判决点和中点采样 ...
%     
%     if isStrobeSample
%         % === 当前是判决点 (Strobe Point) ===
%         
%         % --- Gardner 误差计算 ---
%         timeErr = mid_I * (y_I_sample - y_last_I) + mid_Q * (y_Q_sample - y_last_Q);
% 
%         % --- 环路滤波器 (PI控制器) ---
%         % wFilter是NCO的控制字，timeErr是输入，timeErrLast是状态
%         wFilter = wFilterLast + c1 * (timeErr - timeErrLast) + c2 * timeErr;
% 
%         % 存储状态用于下次计算
%         timeErrLast = timeErr;
%         y_last_I = y_I_sample;
%         y_last_Q = y_Q_sample;
%         
%         % ...
%     else
%         % === 当前是中点 (Midpoint) ===
%         mid_I = y_I_sample;
%         mid_Q = y_Q_sample;
%     end
%     % ...
% end
% ```

%% 复现与观察:
% 1. 在调试模式下，执行到定时同步行 (s_qpsk_sto_sync = GardnerSymbolSync(...))。
% 2. 观察星座图：执行完此行后，在命令窗口绘制星座图。
%    scatterplot(s_qpsk_sto_sync);
%    title('定时同步后的星座图');
%    对比RRC滤波后的星座图，您会发现一个显著的变化：之前完全弥散的环状点云，
%    现在开始向四个角落聚集，形成了四个模糊的"云团"。这证明定时恢复已经起作用，
%    采样点已经基本对准。但由于载波频偏未校正，整个星座图可能仍在整体旋转。

%% 真实世界问题排查案例：当AGC干扰定时环路
% 在实际工程中，前级模块的异常会直接影响后续模块。一个经典的案例是 AGC（自动增益控制）与Gardner环路的相互影响。
% *   问题现象: Gardner环路锁定不稳，定时误差输出呈现规律性的锯齿波，导致星座图在"收敛"和"发散"之间跳动。
% *   问题根源: 如果AGC的环路参数（如调整步长、平均窗口）设置得过于激进，AGC本身可能会产生低频振荡。
%     这个振荡会调制信号的包络，而Gardener算法恰恰对信号能量（包络）敏感。结果，Gardner环路错误地
%     试图去"锁定"这个由AGC引入的虚假包络，而不是真实的符号定时，导致同步失败。
% *   解决方案: 适当放宽AGC的参数，比如增大其平均窗口、减小调整步长，使其响应更平滑，消除振荡。
%     这再次证明了在通信链路中，每个模块都不是孤立的。

%% 5.4 模块详解: 载波同步 (PLL)
% 预期效果: 经过PLL锁相环后，星座图的旋转被完全"锁住"，
% 四个点簇将清晰、稳定地聚集在理想位置附近。这是接收机同步成功的标志性时刻。

%% 理论指导
% 载波同步的目标是补偿两类相位失真：
% 1.  载波频率偏移 (CFO): 由发射机和接收机本地振荡器（晶振）的频率不完全一致引起，
%     导致星座图持续旋转。
% 2.  载波相位偏移 (CPO): 由信道延迟等因素引入的一个固定的相位偏移。

%% 混合前馈/反馈PLL
% 本项目采用了一种更优化的混合式锁相环，它结合了前馈（Feedforward）和反馈（Feedback）的优点，
% 以实现快速锁定和精确跟踪。
% 
% 工作机制:
% 1.  前馈频率补偿: 在进入环路之前，代码首先使用一个预估的中心频率偏移 fc 对信号进行粗略的频率校正。
%     这通过在NCO的累加器中直接加入一个固定相位增量 2 * pi * fc / fs 来实现。
%     这一步能够预先移除大部分的固定频偏，大大减轻后续反馈环路的负担，加快锁定速度。
% 2.  相位误差检测 (Phase Detector): 对于经过粗略校正的每一个符号 y[n]，
%     首先对其进行硬判决，得到离它最近的理想星座点 d[n]。
%     相位误差通过以下方式精确计算：
%     e[n] = angle{ y[n] * conj(d[n]) }
%     其中 conj 是复共轭，angle 函数直接、精确地计算复数的相位角，比 imag 近似法更鲁棒。
% 3.  环路滤波器 (Loop Filter): 检测出的瞬时误差 e[n] 充满了噪声。
%     一个二阶环路滤波器（PI控制器）对误差进行平滑和积分，以获得对剩余相位误差的稳定估计。
% 4.  数控振荡器 (NCO): NCO根据环路滤波器的输出，生成一个精细的校正相位，
%     与前馈补偿量一起，产生最终的复数校正因子 exp(-j * theta)。

%% 参数选择: fc, kp 和 ki
% *   fc (预估频偏): 一个重要的输入参数，代表对载波中心频率偏移的先验估计值。
%     准确的 fc 可以显著提高锁定性能。
% *   kp (比例增益) 和 ki (积分增益): 这两个反馈环路的参数通常根据归一化环路带宽 Bn 
%     和阻尼系数 zeta 计算得出。
%     *   kp (比例增益): 决定了环路对当前瞬时相位误差的响应强度。
%     *   ki (积分增益): 决定了环路对累积相位误差的响应强度。
%         ki 的作用是消除稳态误差，确保能够跟踪残余的频率偏移。
% 
% 本项目中的取值 (config.pll_bandWidth=0.02, config.pll_dampingFactor=0.707):
% *   这里的环路带宽 Bn 被设置为 0.02，它是一个归一化值，通常相对于采样率。
%     这是一个中等带宽的环路，能够在较短时间内锁定，同时保持较好的噪声抑制性能。

%% 代码实现与复现
% 在 lib/QPSKFrequencyCorrectPLL.m 中，实现了混合式PLL的核心逻辑。
% 
% ```matlab
% % lib/QPSKFrequencyCorrectPLL.m (代码与文档同步后的版本)
% 
% function [y,err] = QPSKFrequencyCorrectPLL(x,fc,fs,ki,kp)
%     theta = 0;
%     theta_integral = 0;
% 
%     for m=1:length(x)
%        % 1. 应用上一次计算出的相位进行校正
%        x(m) = x(m) * exp(-1j*(theta));
%         
%        % 2. 判决辅助的相位误差检测
%        % 找到最近的理想QPSK星座点 (硬判决, 未归一化)
%        % 注意: 此处未进行 /sqrt(2) 归一化，与理论略有出入，但实现有效
%        desired_point = 2*(real(x(m)) > 0)-1 + (2*(imag(x(m)) > 0)-1) * 1j;
%        
%        % 精确计算相位差
%        angleErr = angle(x(m)*conj(desired_point));
%        
%        % 3. 二阶环路滤波器 (PI控制器)
%        theta_delta = kp * angleErr + ki * (theta_integral + angleErr);
%        theta_integral = theta_integral + angleErr; % 累积误差
%        
%        % 4. NCO: 更新总相位 (反馈 + 前馈)
%        % 除了反馈控制量theta_delta，还加入了前馈的固定频率补偿
%        theta = theta + theta_delta + 2 * pi * fc / fs;
%        
%        % 输出当前已校正的信号
%        y(m) = x(m);
%     end
% end
% ```

%% 复现与观察:
% 1. 在调试模式下，执行到载波同步行 (s_qpsk_cfo_sync = QPSKFrequencyCorrectPLL(...))。
% 2. 观察星座图 (决定性的一步): 执行完此行后，在命令窗口绘制星座图。
%    scatterplot(s_qpsk_cfo_sync);
%    title('载波同步后的星座图');
%    grid on;
%    此时，您应该能看到一个清晰、稳定的QPSK星座图。四个点簇分别紧密地聚集在理想位置附近。
%    这标志着接收机的同步过程已圆满成功！

%% 复现与观察:
% 1. 执行帧同步行 和解扰行。
% 2. 观察工作区的变量 sync_frame，它的维度 [rows, columns] 表示找到了 rows 个完整的数据帧。
% 3. 观察最终的 I_array 和 Q_array，它们包含了最终恢复的、解扰后的比特信息。

%% 5.5 模块详解: 相位模糊恢复、帧同步与解扰
% 载波同步成功后，我们得到了清晰的星座图，但还面临三个紧密相关的问题：
% 相位模糊、帧边界未知和数据加扰。

%% 相位模糊恢复与帧同步
% 问题: QPSK星座图具有 pi/2 的旋转对称性。PLL环路可能锁定在四个稳定状态中的任意一个，
% 导致恢复的符号存在 0, 90, 180, 或 270 度的固定相位偏差。
% 同时，我们需要在连续的符号流中找到帧的起始位置。
% 
% 解决方案 (一体化处理): 这两个问题可以通过一个步骤解决。
% lib/FrameSync.m 采用了一种高效的策略：
% 1.  对接收到的符号流，穷举四种可能的相位校正
%     （乘以 exp(j * k * pi/2)，其中 k=0,1,2,3）。
% 2.  对每一种校正后的结果，进行硬判决得到比特流。
% 3.  使用一个"滑窗"，将比特流与本地存储的32位 CCSDS同步字 1ACFFC1D 进行相关性计算
%     （或直接比较）。
% 4.  找到哪个相位校正能够产生最强的相关峰值。
%     这个峰值的位置就是帧的起始点，而对应的相位校正角度就是需要补偿的相位模糊。
% 
% 结果: 此步骤完成后，我们不仅校正了相位模糊，还精确地定位了每个1024字节AOS帧的边界。

%% 解扰 (Descrambling)
% 目标: 恢复被加扰的原始数据。根据《卫星数传信号帧格式说明.pdf》，
% 在发射端，数据在LDPC编码后、加入同步字之前，经过了加扰处理。
% 加扰的目的是打破数据中可能存在的长串"0"或"1"，保证信号频谱的均匀性，
% 这有利于接收端各同步环路的稳定工作。
% 
% 工作机制:
% 1.  加扰多项式: 加扰器基于一个本原多项式 1 + X^14 + X^15 来生成伪随机二进制序列 (PRBS)。
% 2.  不同初相: I路和Q路的加扰器使用不同的初始状态（初相），以生成两路独立的PRBS。
%     *   I路初相: 111111111111111 (二进制，左为高位)
%     *   Q路初相: 000000011111111 (二进制，左为高位)
% 3.  解扰实现: 在接收端，lib/FrameScramblingModule.m 会根据同样的配置（多项式和初相）
%     生成一个完全同步的PRBS。将接收到的加扰数据流与本地生成的PRBS再次进行按位异或（XOR）。
%     根据逻辑运算 (Data XOR PRBS) XOR PRBS = Data，即可恢复出LDPC编码后的数据。
% 
% 关键: 解扰成功的关键在于，接收端的PRBS生成器（LFSR）的配置必须与发射端完全一致，
% 并且其起始状态需要通过帧同步来精确对齐。

%% 6. 运行与验证
% 当程序完整运行结束后，您可以通过以下方式验证接收机的性能。

%% 6.1 检查输出文件
% *   检查输出文件: 在您的项目根目录下，检查是否生成了 Ibytes.txt 和 Qbytes.txt 文件。
% *   解析AOS帧头: 这是最有力的验证方法。对恢复出的多个连续数据帧进行AOS帧头解析。
%     *   检查固定字段: 验证版本号、卫星ID等是否与预期一致。
%     *   检查帧计数器: 确认连续帧的frame_count字段是否严格递增。
%         这是链路稳定、无丢帧的黄金标准。

%% 6.2 分析调试图窗
% 程序运行结束后，会弹出多个图窗。请重点关注：
% *   "定时同步星座图" vs "载波同步星座图": 这是最有价值的对比。
%     它直观地展示了PLL如何将一个旋转的、模糊的星座图"锁定"为一个清晰、稳定的星座图。
% *   频谱图: 显示了信号经过RRC滤波器后的频谱形态，验证了脉冲成形的效果。

%% 6.3 (进阶) 编写AOS帧头解析器进行验证
% 最能证明接收机正确性的方法，是直接解析恢复出的AOS帧头，并验证其内部字段的有效性。

% 1. 创建解析函数：在您的 lib 文件夹下，创建一个新文件 AOSFrameHeaderDecoder.m（实际已存在于该目录下）。

%% AOS帧头结构定义
% 根据三份报告及代码实现，AOS帧头共6字节（48比特），其结构定义如下，可作为下面代码的参考：

% | 比特位置 (从1开始) | 字段名称                | 比特长度 | 描述                                       |
% | :------------------- | :---------------------- | :------- | :----------------------------------------- |
% | 1-2                  | Version                 | 2        | 传输帧版本号 (固定为`01`b)                 |
% | 3-10                 | Spacecraft ID           | 8        | 航天器标识符 (例如: 40)                    |
% | 11-16                | Virtual Channel ID      | 6        | 虚拟信道标识符                             |
% | 17-40                | Frame Count             | 24       | 虚拟信道帧计数器，用于标识帧的序列号       |
% | 41                   | Replay Flag             | 1        | 回放标识 (1表示回放数据, 0表示实时数据)    |
% | 42                   | VC Frame Count Usage Flag | 1        | 虚拟信道帧计数用法标识 (0表示单路下传)     |
% | 43-44                | Spare                   | 2        | 备用位                                     |
% | 45-48                | Frame Count Cycle       | 4        | 帧计数周期 (例如: I/Q路标识, 传输速率标识) |

% ```matlab
% % lib/AOSFrameHeaderDecoder.m

% function headerInfo = AOSFrameHeaderDecoder(frameBytes)
%     % 该函数解析一个AOS帧的前6个字节（帧头）
%     % 输入: frameBytes - 一个至少包含6个字节的行向量 (uint8)
%     % 输出: headerInfo - 一个包含解析字段的结构体

%     if length(frameBytes) < 6
%         error('输入字节流长度不足6字节，无法解析AOS帧头。');
%     end

%     % 将字节转换为比特流 (MSB first)
%     bitStream = de2bi(frameBytes(1:6), 8, 'left-msb')';
%     bitStream = bitStream(:)';

%     % 根据上面的表格解析字段
%     headerInfo.Version = bi2de(bitStream(1:2), 'left-msb');
%     headerInfo.SpacecraftID = bi2de(bitStream(3:10), 'left-msb');
%     headerInfo.VirtualChannelID = bi2de(bitStream(11:16), 'left-msb');
%     headerInfo.FrameCount = bi2de(bitStream(17:40), 'left-msb');
%     headerInfo.ReplayFlag = bitStream(41);
%     headerInfo.VCFrameCountUsageFlag = bitStream(42);
%     headerInfo.Spare = bi2de(bitStream(43:44), 'left-msb');
%     headerInfo.FrameCountCycle = bi2de(bitStream(45:48), 'left-msb');
    
%     % 打印结果
%     fprintf('--- AOS Frame Header Decoded ---\n');
%     fprintf('Version: %d\n', headerInfo.Version);
%     fprintf('Spacecraft ID: %d (0x%s)\n', headerInfo.SpacecraftID, dec2hex(headerInfo.SpacecraftID));
%     fprintf('Virtual Channel ID: %d\n', headerInfo.VirtualChannelID);
%     fprintf('Frame Count: %d\n', headerInfo.FrameCount);
%     fprintf('--------------------------------\n');
% end
% ```

% 2. 在主脚本中调用：修改您的主测试脚本 SatelliteQPSKReceiverTest.m，在最后添加调用代码。

% ```matlab
% % ... 在脚本的最后 ...

% % 读取恢复的I路字节数据
% fid = fopen('Ibytes.txt', 'r');
% bytes = fread(fid, 'uint8');
% fclose(fid);

% % 假设每帧1024字节，解析前3帧
% frameLength = 1024;
% numFramesToParse = min(3, floor(length(bytes) / frameLength));

% if numFramesToParse > 0
%     disp('--- Verifying recovered I-channel frames ---');
%     for i = 1:numFramesToParse
%         startIdx = (i-1) * frameLength + 1;
%         endIdx = startIdx + frameLength - 1;
%         currentFrame = bytes(startIdx:endIdx)'; % 提取并转为行向量
        
%         % 调用解析器
%         AOSFrameHeaderDecoder(currentFrame);
%     end
% else
%     disp('No complete frames found in Ibytes.txt to verify.');
% end
% ```

% 3. 运行与分析：
%    *   重新运行主脚本。
%    *   在MATLAB命令窗口，您应该能看到类似下面的输出：

% ```
% --- AOS Frame Header Decoded ---
%                 versionId: 1
%                 satelliteType: "03组"
%     satelliteVirtualChannelId: "03组 有效数据"
%         satelliteVCDUCounter: 532605
%             satelliteReplyId: "回放"
%         satelliteDownloadId: "单路下传"
%             satelliteIQDataId: "I路"
%         satelliteDigitalSpeed: "150Mbps"
% --------------------------------
% ```

%% 7. 技术路径详细实现指南

%% 7.1 路径一：纯MATLAB编程实现（程梓睿方案）

%% 7.1.1 实现特色
% - 完整模块化：24个独立功能模块，每个模块负责特定功能
% - Farrow插值器：在Gardner符号同步中实现高精度定时恢复
% - 智能解扰验证：自动检测和纠正IQ路交换问题

%% 7.1.2 关键代码结构
% 14+2022210532+chengzirui/
% ├── SatelliteQPSKReceiverTest.m          # 主测试脚本
% ├── lib/                                 # 核心算法库
% │   ├── SatelliteQPSKReceiver.m         # 主处理函数
% │   ├── GardnerSymbolSync.m             # Gardner定时同步
% │   ├── QPSKFrequencyCorrectPLL.m       # PLL载波同步
% │   ├── FrameSync.m                     # 帧同步算法
% │   ├── FrameScramblingModule.m         # 解扰模块
% │   └── [其他20+算法模块]
% └── out/                                # 输出结果文件

%% 7.1.3 运行步骤
% 1. 环境配置：
%    addpath('student_cases/14+2022210532+chengzirui/lib');  % 添加算法库路径
% 
% 2. 数据文件配置：
%    编辑 SatelliteQPSKReceiverTest.m 文件，修改文件名为你的测试数据路径：
%    % 必须为int16格式的数据文件
%    filename = 'data/sample_0611_500MHz_middle.bin';
% 
% 3. 运行主程序：
%    run('student_cases/14+2022210532+chengzirui/SatelliteQPSKReceiverTest.m');
% 
% 4. 查看输出结果：
%    程序运行完成后，在 out/ 目录下会生成：
%    - IQbytes.txt: IQ字节数据
%    - unscrambled_hex.txt: 解扰后的十六进制数据  
%    - Ibytes.txt, Qbytes.txt: I/Q路分离数据

%% 8. 总结与展望
% 本项目通过一系列精心设计的MATLAB模块，并配以此深度解析教程，
% 成功实现并剖析了一个功能完备的QPSK接收机。
% 通过本分步指南，您不仅能够亲手操作和观察每一个处理环节，
% 更能深入理解：
% 
% *   核心算法的理论精髓：从RRC的奈奎斯特准则到Gardner和PLL的闭环控制思想。
% *   关键参数的物理意义：理解 alpha, Bn, zeta, kp, ki 如何影响系统性能，
%     以及如何在速度、精度和稳定性之间进行权衡。
% *   理论与实践的联系：看到抽象的数学公式如何转化为具体的代码实现，
%     并产生可观测的信号变化。
% 
% 至此，您已经掌握了构建一个基本数字接收机的全套流程和核心技术。
% 以此为基础，您可以进一步探索更高级的主题，例如：
% 
% *   信道编码：实现卷积码/Turbo码的编译码器（如Viterbi解码），以对抗信道噪声。
% *   高级调制：将QPSK扩展到16-QAM, 64-QAM等高阶调制方式。
% *   OFDM系统：将单载波系统扩展到多载波系统，以对抗频率选择性衰落。
% 
% 希望本教程能成为您在数字通信学习道路上的一块坚实基石。

%% 9. 参考文献 (References)
% 本教程的构建和理论分析参考了以下关键资料：

% 1.  项目核心规范:
%     *   卫星数传信号帧格式说明.pdf: 本项目文件夹内包含的文档，详细定义了AOS帧结构、同步字、加扰多项式等关键参数。

% 2.  国际标准:
%     *   CCSDS (Consultative Committee for Space Data Systems): 空间数据系统咨询委员会发布的一系列关于AOS (Advanced Orbiting Systems) 的建议标准（蓝皮书），是本通信协议的根本依据。

% 3.  项目实践报告 (Project Implementation Reports):
%     *   14+2022210532+程梓睿+卫星下行接收报告.pdf
%     *   (这些报告提供了宝贵的实践见解、代码实现和问题排查案例，极大地丰富了本教程的深度和实用性。)