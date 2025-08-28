%% 卫星QPSK接收机MATLAB实现深度解析教程
% 本教程按照从整体到部分的方式，逐步解析程梓睿同学实现的QPSK信号接收机。
% 首先介绍整体架构和使用方法，然后深入解析每个子模块的实现原理和代码细节。

%% 1. 项目简介与理论背景
% 本项目旨在使用MATLAB从零开始构建一个功能完备的QPSK（四相相移键控）信号接收机。
% 该接收机能够处理一个真实的、从文件中加载的卫星中频IQ（同相/正交）数据流，通过一系列精密的数字信号处理步骤——包括匹配滤波、定时恢复、载波恢复、帧同步和解扰——最终准确地恢复出原始传输的二进制数据。

%% 1.1 QPSK在卫星通信中的重要性
% QPSK是一种高效的数字调制技术，它在每个符号（Symbol）中编码2个比特（bits）的信息。
% 相比于BPSK（每个符号1比特），QPSK在不增加带宽的情况下将数据传输速率提高了一倍，这使其在频谱资源受限的卫星通信中极具吸引力。

%% 1.2 CCSDS标准与本项目关联
% 本项目处理的信号帧结构遵循 **CCSDS (空间数据系统咨询委员会)** 的AOS (Advanced Orbiting Systems) 建议标准。
% 具体来说：
% *   **帧同步字:** 帧同步模块使用了 **`1ACFFC1D`** (十六进制) 作为同步字。
% *   **AOS帧结构:** 每个数据帧的总长度为 **1024字节**，由以下部分组成：
%    *   **同步字 (ASM):** 4字节 (`0x1ACFFC1D`)
%    *   **AOS帧头:** 6字节
%    *   **数据负载:** 886字节
%    *   **LDPC校验码:** 128字节

%% 2. 技术路径选择与系统架构
% 本项目采用开放式设计理念，支持不同的技术实现路径，学生可根据自身技术背景和兴趣自主选择。
% 这里仅引用了纯Matlab实现。

%% 2.1 纯MATLAB编程实现（程梓睿方案）
% - **特点**：完全基于MATLAB脚本和函数实现，注重算法原理的深度理解
% - **适合对象**：希望深入理解算法细节、具备一定编程基础的学生
% - **核心优势**：
%   - 算法参数可精确控制
%   - 调试过程清晰可见
%   - 便于算法创新和优化

%% 3. 系统架构与处理流程
% 本QPSK接收机的处理流程是模块化的，每个模块负责一个特定的信号处理任务。
% 主脚本 SatelliteQPSKReceiverTest.m 负责配置全局参数，并调用核心处理函数 lib/SatelliteQPSKReceiver.m。
%
% 各模块核心功能简介:
% 1.  **信号加载:** 从二进制文件中读取原始IQ样本。
% 2.  **重采样:** 将原始500Msps的采样率降采样至150Msps，在保证信号质量的同时提高处理效率。
% 3.  **RRC滤波:** 作为匹配滤波器，最大化信噪比，并消除码间串扰（ISI）。
% 4.  **AGC:** 自动调整信号幅度，为后续模块提供稳定的输入电平。
% 5.  **定时同步:** (Gardner) 找到每个符号波形的"最佳"采样时刻。
% 6.  **载波同步:** (PLL) 校正频率与相位偏差，锁定星座图。
% 7.  **相位模糊恢复 & 帧同步:** 通过穷举四种相位并与已知的`1ACFFC1D`同步字进行相关匹配，在确定正确相位的同时，定位数据帧的起始边界。
% 8.  **解扰:** 根据CCSDS标准，使用$1+X^{14}+X^{15}$多项式，对已同步的帧数据进行解扰，恢复出经LDPC编码后的原始数据。
% 9.  **数据输出:** 将恢复的比特流转换为字节，并写入文件。

%% 4. 环境准备与文件说明
% 在开始复现之前，请确保您的环境配置正确，并理解项目中各个关键文件的作用。

%% 4.1 环境设置
% 1.  **MATLAB环境:** 推荐使用 R2021a 或更高版本
% 2.  **项目文件:** 下载或克隆整个项目到您的本地工作目录
% 3.  **数据文件:** 获取项目数据文件，放置在项目的`data/`目录下
% 4.  **MATLAB路径:** 将 `lib` 目录添加到MATLAB的搜索路径中

%% 4.2 关键文件解析
% *   SatelliteQPSKReceiverTest.m: **主测试脚本**。这是您需要运行的入口文件。
% *   lib/SatelliteQPSKReceiver.m: **核心接收机封装器**。
% *   lib/: **核心函数库目录**。存放了所有独立的信号处理模块。
% *   Ibytes.txt / Qbytes.txt: **输出文件**。接收机成功运行后，恢复出的I路和Q路数据将以字节流的形式分别保存在这两个文本文件中。

%% 5. 核心模块详解与复现 (深度分析)
% 本章节是教程的核心。以下将以程梓睿同学的实现为主，逐一深入每个关键模块。

%% 5.1 模块详解: RRC匹配滤波
% **预期效果:** 信号通过RRC滤波器后，频谱被有效抑制在符号速率范围内，眼图张开，为后续的定时同步做好了准备。

%% 理论指导
% 在数字通信系统中，为了限制信号带宽并消除码间串扰（ISI），发送端通常使用一个**脉冲成形滤波器**。
% 最常用的就是**升余弦（Raised Cosine, RC）**或其平方根——**根升余弦（Root Raised Cosine, RRC）**滤波器。
% 
% 奈奎斯特第一准则指出，如果一个滤波器的冲激响应在符号间隔的整数倍时刻上除了中心点外都为零，
% 那么它就不会引入ISI。RC滤波器满足此准则。
% 
% 为了在发射机和接收机之间优化信噪比，通常采用**匹配滤波器**方案：即发射机和接收机各使用一个RRC滤波器。
% 两个级联的RRC滤波器等效于一个RC滤波器，既满足了无ISI准则，又实现了最佳的信噪比性能。

%% 参数选择: 滚降系数 alpha
% alpha 是RRC滤波器最重要的参数，其取值范围为 [0, 1]。
% *   **基本概念澄清:**
%    *   **比特率 (Bit Rate, $f_{bit}$):** 每秒传输的比特数。本项目为 **150 Mbps**。
%    *   **符号率 (Symbol Rate / Baud Rate, $f_{sym}$):** 每秒传输的符号数。由于QPSK每个符号承载2个比特，因此符号率为 $f_{sym} = f_{bit} / 2 = \textbf{75 MBaud/s}$。
% *   **物理意义**: alpha 决定了信号占用的实际带宽。信号带宽 $BW = (1 + \alpha) \cdot f_{sym}$。
% *   **取值影响**:
%    *   alpha = 0: 带宽最窄（等于奈奎斯特带宽 $f_{sym}$），但其冲激响应拖尾很长，对定时误差非常敏感。
%    *   alpha = 1: 带宽最宽（等于 $2 \cdot f_{sym}$），冲激响应衰减最快，对定时误差最不敏感，但频谱利用率最低。
%    *   **在本项目中 (config.rollOff = 0.33)**: 这是一个非常典型且工程上常用的折中值。它在保证较低带外泄露的同时，提供了对定时误差较好的鲁棒性。

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

%% 5.2 模块详解: Gardner定时同步
% **预期效果:** 经过Gardner同步后，采样点被调整到每个符号的最佳位置。此时的星座图，点会从之前的弥散环状开始向四个目标位置收敛，形成四个模糊的"云团"，但由于未经载波同步，整个星座图可能仍在旋转，即仍为环形。

%% 理论指导
% 定时同步的目标是克服由于收发双方时钟频率的细微偏差（符号时钟偏移）导致的采样点漂移问题。
% Gardner算法是一种高效的、不依赖于载波相位的定时误差检测（TED）算法。
% 
% 它的核心思想是：在每个符号周期内，采集两个样本：一个是在预估的最佳采样点（**判决点, Strobe Point**），
% 另一个是在两个判决点之间的中点（**中点, Midpoint**）。
% 
% Gardner定时误差检测器的数学公式为：
% 
% $$
% e[k] = \text{real}\{y_{mid}[k]\} \cdot (\text{real}\{y_{strobe}[k]\} - \text{real}\{y_{strobe}[k-1]\}) + \text{imag}\{y_{mid}[k]\} \cdot (\text{imag}\{y_{strobe}[k]\} - \text{imag}\{y_{strobe}[k-1]\})
% $$
% 
% 其中 $k$ 是符号索引。

%% Farrow插值器优化（程梓睿创新实现）
% 在程梓睿的纯MATLAB实现中，采用了3阶Farrow立方插值器进行精确的分数延迟插值，这是该实现的技术亮点之一。
% 
% **Farrow插值器原理**：
% Farrow插值器能够实现任意分数延迟的高精度插值，采用3阶立方多项式结构。
% 在本实现中，使用四个相邻数据点 $x(n-1)$, $x(n)$, $x(n+1)$, $x(n+2)$ 来插值计算 $x(n+\mu)$。
% 
% **技术优势**：
% 相比传统线性插值，Farrow插值器能够获得更高的定时精度，特别是在高符号率系统中优势明显。

%% 参数选择: 环路带宽 Bn 和阻尼系数 zeta
% 在 lib/GardnerSymbolSync.m 中，环路滤波器的特性由 B_loop (归一化环路带宽) 和 zeta (阻尼系数) 决定。
% *   **环路带宽 Bn**: 决定了环路对定时误差的跟踪速度和响应能力。本项目中 B_loop = 0.0001 是一个相对较窄的带宽，适用于信噪比较好的场景，追求高稳定度。
% *   **阻尼系数 zeta**: 决定了环路响应的瞬态特性。本项目中 zeta = 0.707 是经典的最优取值，在响应速度和稳定性之间提供了最佳的平衡。


%% 5.3 模块详解: 载波同步 (PLL)
% **预期效果:** 经过PLL锁相环后，星座图的旋转被完全"锁住"，四个点簇将清晰、稳定地聚集在理想位置附近。这是接收机同步成功的标志性时刻。

%% 理论指导
% 载波同步的目标是补偿两类相位失真：
% 1.  **载波频率偏移 (CFO):** 由发射机和接收机本地振荡器（晶振）的频率不完全一致引起，导致星座图持续旋转。
% 2.  **载波相位偏移 (CPO):** 由信道延迟等因素引入的一个固定的相位偏移。

%% 混合前馈/反馈PLL
% 本项目采用了一种更优化的**混合式锁相环**，它结合了前馈（Feedforward）和反馈（Feedback）的优点，以实现快速锁定和精确跟踪。
% 
% **工作机制:**
% 1.  **前馈频率补偿:** 在进入环路之前，代码首先使用一个预估的中心频率偏移 `fc` 对信号进行粗略的频率校正。这通过在NCO的累加器中直接加入一个固定相位增量 `2 * pi * fc / fs` 来实现。这一步能够预先移除大部分的固定频偏，大大减轻后续反馈环路的负担，加快锁定速度。
% 2.  **相位误差检测 (Phase Detector):** 对于经过粗略校正的每一个符号 `y[n]`，首先对其进行硬判决，得到离它最近的理想星座点 `d[n]`。相位误差通过以下方式**精确计算**：
%    $$
%    e[n] = \angle\{ y[n] \cdot \text{conj}(d[n]) \}
%    $$
%    其中 `conj` 是复共轭，`angle` 函数直接、精确地计算复数的相位角，比 `imag` 近似法更鲁棒。
% 3.  **环路滤波器 (Loop Filter):** 检测出的瞬时误差 `e[n]` 充满了噪声。一个二阶环路滤波器（PI控制器）对误差进行平滑和积分，以获得对剩余相位误差的稳定估计。
% 4.  **数控振荡器 (NCO):** NCO根据环路滤波器的输出，生成一个精细的校正相位，与前馈补偿量一起，产生最终的复数校正因子 `exp(-j * theta)`。

%% 参数选择: fc, kp 和 ki
% *   **fc (预估频偏):** 一个重要的输入参数，代表对载波中心频率偏移的先验估计值。准确的 `fc` 可以显著提高锁定性能。
% *   **kp (比例增益) 和 ki (积分增益):** 这两个反馈环路的参数通常根据归一化环路带宽 `Bn` 和阻尼系数 `zeta` 计算得出。
%    *   **kp (比例增益):** 决定了环路对当前瞬时相位误差的响应强度。
%    *   **ki (积分增益):** 决定了环路对累积相位误差的响应强度。`ki` 的作用是消除稳态误差，确保能够跟踪残余的频率偏移。
% 
% **本项目中的取值 (config.pll_bandWidth=0.02, config.pll_dampingFactor=0.707)**:
% *   这里的环路带宽 `Bn` 被设置为 `0.02`，它是一个归一化值，通常相对于采样率。这是一个中等带宽的环路，能够在较短时间内锁定，同时保持较好的噪声抑制性能。

%% 5.4 模块详解: 相位模糊恢复、帧同步与解扰
% 载波同步成功后，我们得到了清晰的星座图，但还面临三个紧密相关的问题：相位模糊、帧边界未知和数据加扰。

%% 相位模糊恢复与帧同步
% *   **问题:** QPSK星座图具有 $\pi/2$ 的旋转对称性。PLL环路可能锁定在四个稳定状态中的任意一个，导致恢复的符号存在 0, 90, 180, 或 270 度的固定相位偏差。同时，我们需要在连续的符号流中找到帧的起始位置。
% *   **解决方案 (一体化处理):** 这两个问题可以通过一个步骤解决。lib/FrameSync.m 采用了一种高效的策略：
%    1.  对接收到的符号流，**穷举四种可能的相位校正**（乘以 $e^{j \cdot k \cdot \pi/2}$，其中 k=0,1,2,3）。
%    2.  对每一种校正后的结果，进行硬判决得到比特流。
%    3.  使用一个"滑窗"，将比特流与本地存储的32位 **CCSDS同步字 `1ACFFC1D`** 进行相关性计算（或直接比较）。
%    4.  找到哪个相位校正能够产生最强的相关峰值。这个峰值的位置就是帧的起始点，而对应的相位校正角度就是需要补偿的相位模糊。
% *   **结果:** 此步骤完成后，我们不仅校正了相位模糊，还精确地定位了每个1024字节AOS帧的边界。

%% 解扰 (Descrambling)
% *   **目标:** 恢复被加扰的原始数据。根据《卫星数传信号帧格式说明.pdf》，在发射端，数据在LDPC编码后、加入同步字之前，经过了加扰处理。加扰的目的是打破数据中可能存在的长串"0"或"1"，保证信号频谱的均匀性，这有利于接收端各同步环路的稳定工作。
% *   **工作机制:**
%    1.  **加扰多项式:** 加扰器基于一个本原多项式 $1 + X^{14} + X^{15}$ 来生成伪随机二进制序列 (PRBS)。
%    2.  **不同初相:** I路和Q路的加扰器使用不同的初始状态（初相），以生成两路独立的PRBS。
%        *   I路初相: `111111111111111` (二进制，左为高位)
%        *   Q路初相: `000000011111111` (二进制，左为高位)
%    3.  **解扰实现:** 在接收端，lib/FrameScramblingModule.m 会根据同样的配置（多项式和初相）生成一个完全同步的PRBS。将接收到的加扰数据流与本地生成的PRBS再次进行按位异或（XOR）。根据逻辑运算 `(Data XOR PRBS) XOR PRBS = Data`，即可恢复出LDPC编码后的数据。
% *   **关键:** 解扰成功的关键在于，接收端的PRBS生成器（LFSR）的配置必须与发射端完全一致，并且其起始状态需要通过帧同步来精确对齐。


%% 6. 运行与验证
% 当程序完整运行结束后，您可以通过以下方式验证接收机的性能。

%% 6.1 检查输出文件
% *   **检查输出文件:** 检查是否生成了 Ibytes.txt 和 Qbytes.txt 文件。
% *   **解析AOS帧头:** 对恢复出的多个连续数据帧进行AOS帧头解析。

%% 6.2 分析调试图窗
% 程序运行结束后，会弹出多个图窗。请重点关注：
% *   **"定时同步星座图"** vs **"载波同步星座图"**
% *   **频谱图**: 显示了信号经过RRC滤波器后的频谱形态

%% 7. 整体实现与使用方法
% 程梓睿同学已经封装好了完整的接收机处理流程，我们可以通过调用核心函数来使用：

%% 7.1 环境配置和参数设置
% 添加库路径
addpath('student_cases/14+2022210532+chengzirui/lib');

% 清除工作区
clear; clc;

% 定义参数对象
config.inputDataFilename = "data/small_sample_256k.bin"; % 使用小数据文件进行测试
config.sourceSampleRate = 500e6; % 原始信号采样率
config.resampleMolecule = 3; % 重采样分子
config.resampleDenominator = 10; % 重采样分母
config.fs = 150e6; % 重采样后的采样率
config.fb = 150e6; % 数传速率150Mbps
config.startBits = 0; % 文件读取数据的起始点

% 设置处理所有数据点（使用-1表示读取文件中所有数据）
config.bitsLength = -1; % 自动处理文件中的所有数据

fprintf('将自动处理文件中的所有数据点\n');

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

%% 7.2 核心处理函数实现 (SatelliteQPSKReceiver.m)
% 以下是核心处理函数的完整实现，该函数调用了学生已实现的各个模块：

%% 卫星QPSK接收模块封装器
function [I_bytes,Q_bytes] = SatelliteQPSKReceiver(config)
%% 提取参数
filename = config.inputDataFilename;
fs = config.fs;
fb = config.fb;
resampleMolecule = config.resampleMolecule;
resampleDenominator = config.resampleDenominator;
startBits = config.startBits;
bitsLength = config.bitsLength;  % 设置为-1可读取文件中所有数据
IBytesFilename = config.IBytesFilename;
QBytesFilename = config.QBytesFilename;
IQBytesFilename = config.IQBytesFilename;
rollOff = config.rollOff;

% 新增：检查并提取新配置参数
if isfield(config, 'keepRedundantData')
    keepRedundantData = config.keepRedundantData;
    FullFrameIBytesFilename = config.FullFrameIBytesFilename;
    FullFrameQBytesFilename = config.FullFrameQBytesFilename;
    FullFrameIQBytesFilename = config.FullFrameIQBytesFilename;
else
    keepRedundantData = false;
end

% 新增：检查并提取未解扰十六进制文件名
if isfield(config, 'UnscrambledHexFilename')
    UnscrambledHexFilename = config.UnscrambledHexFilename;
    writeUnscrambledHex = true;
else
    writeUnscrambledHex = false;
end

%% 局部参数
% 锁相环参数定义
df = 1e6;
Bn = 2 * df / fs;  % = 0.02
zeta = 0.707;

kp = 4 * zeta * Bn / (1 + 2*zeta*Bn + Bn^2);   % ≈ 0.056
ki = 4 * Bn^2 / (1 + 2*zeta*Bn + Bn^2);        % ≈ 0.0015

disp("kp:"+string(kp));
disp("ki:"+string(ki));

% 计算得到sps
sps = 2*fs/fb;

%% 从文件读取数据
s_qpsk = SignalLoader(filename,startBits,bitsLength);

%% 执行重采样
s_qpsk = resample(s_qpsk,resampleMolecule,resampleDenominator);

%% 执行RRC滤波
s_qpsk = RRCFilterFixedLen(fb/2,fs,s_qpsk,rollOff,"RRC");

%% 执行AGC
s_qpsk = AGC_Normalize(s_qpsk,1,0.01);

%% 执行定时同步
s_qpsk_sto_sync = GardnerSymbolSync(s_qpsk,sps,0.0001,0.707);

%% 执行载波同步
s_qpsk_cfo_sync = QPSKFrequencyCorrectPLL(s_qpsk_sto_sync,0,fs,ki,kp);

%% 执行帧同步，输出同步后的序列数组
sync_frame = FrameSync(s_qpsk_cfo_sync);

%% 新增：在解扰前保存为十六进制文件
if writeUnscrambledHex && ~isempty(sync_frame)
    disp("正在保存未解扰的十六进制数据...");
    
    % 提取I路和Q路比特
    I_bits_unscrambled = real(sync_frame);
    Q_bits_unscrambled = imag(sync_frame);

    % 将比特转换为字节
    [rows_unscrambled, ~] = size(I_bits_unscrambled);
    I_bytes_unscrambled = [];
    Q_bytes_unscrambled = [];
    for m = 1:rows_unscrambled
        I_bytes_unscrambled = [I_bytes_unscrambled, BinarySourceToByteArray(I_bits_unscrambled(m, :))];
        Q_bytes_unscrambled = [Q_bytes_unscrambled, BinarySourceToByteArray(Q_bits_unscrambled(m, :))];
    end
    
    % 交织字节流
    BytesStream_unscrambled = zeros(1, length(I_bytes_unscrambled) * 2, 'uint8');
    for m = 1:length(I_bytes_unscrambled)
       BytesStream_unscrambled(2*m-1) = I_bytes_unscrambled(m);
       BytesStream_unscrambled(2*m) = Q_bytes_unscrambled(m);
    end
    
    % 写入十六进制文件
    WriteHexToFile(BytesStream_unscrambled, UnscrambledHexFilename);
end

%% 根据配置选择解扰和处理方式
if keepRedundantData
    disp("执行完整帧解扰...");
    % 调用新的完整帧解扰模块
    [I_array_full, Q_array_full] = FullFrameDescramblingModule(sync_frame);
    
    % 提取到IQ字节 (完整帧)
    [rows_full, ~] = size(I_array_full);
    I_bytes_full = [];
    Q_bytes_full = [];
    for m = 1:rows_full
        I_bytes_full = [I_bytes_full, BinarySourceToByteArray(I_array_full(m, :))];
        Q_bytes_full = [Q_bytes_full, BinarySourceToByteArray(Q_array_full(m, :))];
    end
    
    % 交织完整帧到文件
    BytesStream_full = zeros(1, length(I_bytes_full) * 2, 'uint8');
    for m = 1:length(I_bytes_full)
       BytesStream_full(2*m-1) = I_bytes_full(m);
       BytesStream_full(2*m) = Q_bytes_full(m);
    end
    
    % 写入完整帧到新文件
    WriteUint8ToFile(I_bytes_full, FullFrameIBytesFilename);
    WriteUint8ToFile(Q_bytes_full, FullFrameQBytesFilename);
    WriteUint8ToFile(BytesStream_full, FullFrameIQBytesFilename);
    
    % 为了保持函数原有输出的兼容性，我们仍然可以处理原始数据
    disp("同时执行原始数据处理流程...");
    [I_array,Q_array] = FrameScramblingModule(sync_frame);
else
    disp("执行原始解扰流程...");
    %% 执行解扰
    [I_array,Q_array] = FrameScramblingModule(sync_frame);
end

%% 提取到IQ字节 (原始逻辑)
[rows,columns] = size(I_array);
I_bytes = [];
Q_bytes = [];
for m=1:rows
    I_bytes = [I_bytes,BinarySourceToByteArray(I_array(m,:))];
    Q_bytes = [Q_bytes,BinarySourceToByteArray(Q_array(m,:))];
end

%% 交织到文件 (原始逻辑)
BytesStream = zeros(1,length(I_bytes)*2,'uint8');

for m=1:length(I_bytes)
   BytesStream(2*m-1) = I_bytes(m);
   BytesStream(2*m) = Q_bytes(m);
end

%% 数据验证，选取一帧打印出AOS
aosFrameHead = AOSFrameHeaderDecoder(I_array);

%% 写入到文件 (原始逻辑)
WriteUint8ToFile(I_bytes,IBytesFilename);
WriteUint8ToFile(Q_bytes,QBytesFilename);
WriteUint8ToFile(BytesStream,IQBytesFilename);

%% 调试窗口
% 绘制频谱
figure;
[Pxx, f] = pwelch(s_qpsk,[],[],[],fs,'centered');
subplot(1,1,1);
plot(f/1e6, 10*log10(Pxx));
xlabel('频率 (MHz)');
ylabel('功率谱密度 (dB/Hz)');
title('卫星滤波前QPSK调制信号 - 频谱');
grid on;

% 计算瞬时功率（每个采样点的功率）
power_inst = abs(s_qpsk).^2;

% 设置窗口参数
window_size = 100;                % 每个窗口的样本数
num_windows = floor(length(s_qpsk)/window_size);

% 初始化均值功率数组
avg_power = zeros(1, num_windows);
time_axis = zeros(1, num_windows);

% 逐窗口计算功率均值
for i = 1:num_windows
    idx_start = (i-1)*window_size + 1;
    idx_end = i*window_size;
    segment = s_qpsk(idx_start:idx_end);
    avg_power(i) = mean(abs(segment).^2);      % 每段窗口平均功率
end

% 绘图：时间-平均功率图
figure;
plot(avg_power); % x轴单位转换为毫秒
xlabel('采样点');
ylabel('平均功率');
title('窗口平均功率 vs 时间');
grid on;

% 绘制星座图
% 显示定时同步后的星座
scatterplot(s_qpsk_sto_sync);
title('定时同步星座图');

% 显示定时同步后的星座
scatterplot(s_qpsk_cfo_sync);
title('载波同步星座图');

% 打印AOS帧头
disp(aosFrameHead);
end

%% 7.3 运行接收机
% 调用核心处理函数
[I_bytes, Q_bytes] = SatelliteQPSKReceiver(config);

%% 7.4 整体处理流程解析
% SatelliteQPSKReceiver函数封装了完整的处理流程，主要包括以下步骤：
% 1. 从文件读取数据 (SignalLoader)
% 2. 执行重采样 (resample)
% 3. 执行RRC滤波 (RRCFilterFixedLen)
% 4. 执行AGC (AGC_Normalize)
% 5. 执行定时同步 (GardnerSymbolSync)
% 6. 执行载波同步 (QPSKFrequencyCorrectPLL)
% 7. 执行帧同步 (FrameSync)
% 8. 执行解扰 (FrameScramblingModule)
% 9. 数据输出到文件 (WriteUint8ToFile)
%
% 接下来我们将逐一解析每个子模块的实现原理和代码细节。

%% 8. 核心模块详解与原理解析

%% 8.1 信号加载模块 (SignalLoader)
% 功能：从二进制文件中读取原始IQ样本
% 原理：该模块负责读取存储在磁盘上的复数信号数据，数据格式为int16类型，
% I路和Q路数据交替存储。函数支持指定起始位置和读取长度，方便对大文件进行分段处理。

% 代码实现：
% function y = SignalLoader(filename,pointStart,Nread)
% % 打开文件
% fid = fopen(filename, 'rb');
% % 设置搜索指针
% fseek(fid, (pointStart - 1) * 8, 'bof');
% % 读取数据
% if Nread == -1
%     % 读取文件中所有剩余数据
%     raw = fread(fid, [2, Inf], 'int16');
% else
%     % 读取指定数量的数据
%     raw = fread(fid, [2, Nread], 'int16');
% end
% y = complex(raw(1,:), raw(2,:));
% %关闭指针
% fclose(fid);
% end

% 单元测试示例：
% % 创建测试数据
% test_data = complex([1, 2, 3, 4], [5, 6, 7, 8]);
% % 保存为二进制文件
% fid = fopen('test_signal.bin', 'wb');
% for i = 1:length(test_data)
%     fwrite(fid, [real(test_data(i)), imag(test_data(i))], 'int16');
% end
% fclose(fid);
% % 测试SignalLoader函数
% loaded_data = SignalLoader('test_signal.bin', 1, 4);
% % 验证结果
% assert(isequal(test_data, loaded_data), 'SignalLoader测试失败');

%% 8.2 RRC滤波器模块 (RRCFilterFixedLen)
% 功能：作为匹配滤波器，最大化信噪比，并消除码间串扰（ISI）
% 原理：使用根升余弦（RRC）滤波器对信号进行脉冲成形，限制信号带宽并消除码间串扰。
% RRC滤波器是发射机和接收机各使用一个根升余弦滤波器的匹配滤波方案，
% 两个级联的RRC滤波器等效于一个升余弦（RC）滤波器。

% 代码实现：
% function y = RRCFilterFixedLen(fb, fs, x, alpha, mode)
% % 参数
% span = 8; % 滤波器长度（单位符号数）
% sps = floor(fs / fb); % 每符号采样数
% % 生成滤波器
% if strcmpi(mode, 'rrc')
%     % Root Raised Cosine
%     h = rcosdesign(alpha, span, sps, 'sqrt');
% elseif strcmpi(mode, 'rc')
%     % Raised Cosine
%     h = rcosdesign(alpha, span, sps, 'normal');
% else
%     error('Unsupported mode. Use ''rrc'' or ''rc''.');
% end
% % 卷积，保持输入输出长度一致
% y = conv(x, h, 'same');
% end

% 单元测试示例：
% % 创建测试信号
% t = 0:0.01:10;
% test_signal = cos(2*pi*5*t) + 0.5*sin(2*pi*10*t);  % 合成信号
% % 应用RRC滤波器
% filtered_signal = RRCFilterFixedLen(100, 1000, test_signal, 0.33, 'rrc');
% % 验证输出长度与输入长度一致
% assert(length(filtered_signal) == length(test_signal), 'RRC滤波器长度不匹配');

%% 8.3 AGC模块 (AGC_Normalize)
% 功能：自动调整信号幅度，为后续模块提供稳定的输入电平
% 原理：AGC（自动增益控制）模块通过实时检测输入信号的功率，
% 动态调整增益以使输出信号功率保持在目标值附近。
% 该实现采用逐点更新的方式，模拟实时处理过程。

% 代码实现：
% function y = AGC_Normalize(x, target_power, agc_step)
% % 初始化增益
% gain = 1.0;
% % 预分配输出
% y = zeros(size(x));
% % 实时逐点更新AGC（模拟时序处理）
% for n = 1:length(x)
%     % 当前输入样本
%     sample = x(n);
%     % 当前功率
%     current_power = abs(sample * gain)^2;
%     % 误差
%     error = target_power - current_power;
%     % 更新增益
%     gain = gain + agc_step * error * gain;
%     % 防止增益爆炸
%     if gain < 1e-6
%        gain = 1e-6;
%     elseif gain > 1e6
%        gain = 1e6;
%     end 
%     % 应用增益
%     y(n) = gain * sample;
% end
% end

% 单元测试示例：
% % 创建测试信号
% test_signal = complex(randn(1, 1000), randn(1, 1000));  % 复数高斯噪声
% % 应用AGC
% agc_output = AGC_Normalize(test_signal, 1.0, 0.01);
% % 计算输出功率
% output_power = mean(abs(agc_output).^2);
% % 验证输出功率接近目标功率
% assert(abs(output_power - 1.0) < 0.1, 'AGC功率控制失败');

%% 8.4 Gardner定时同步模块 (GardnerSymbolSync)
% 功能：找到每个符号波形的"最佳"采样时刻
% 原理：Gardner算法是一种高效的、不依赖于载波相位的定时误差检测算法。
% 它的核心思想是：在每个符号周期内，采集两个样本：一个是在预估的最佳采样点（判决点），
% 另一个是在两个判决点之间的中点。通过计算这两个采样点之间的误差来调整采样时刻。

% 代码实现要点：
% 1. 使用NCO（数控振荡器）来控制采样时刻
% 2. 使用Farrow插值器进行分数延迟插值
% 3. 通过Gardner误差检测算法计算定时误差
% 4. 使用PI控制器作为环路滤波器调整NCO参数

% 单元测试思路：
% % 创建已知符号序列和采样偏移的测试信号
% % 应用Gardner同步算法
% % 验证输出符号序列与原始符号序列的一致性
% % 验证定时误差收敛到零附近

%% 8.5 载波同步模块 (QPSKFrequencyCorrectPLL)
% 功能：校正频率与相位偏差，锁定星座图
% 原理：采用混合前馈/反馈PLL结构，结合了前馈频率补偿和反馈相位锁定。
% 前馈部分使用预估的中心频率偏移对信号进行粗略的频率校正，
% 反馈部分使用相位检测器和环路滤波器对剩余相位误差进行精确跟踪。

% 代码实现：
% function [y,err] = QPSKFrequencyCorrectPLL(x,fc,fs,ki,kp)
% %% 全局变量
% theta = 0;
% theta_integral = 0;
% y = zeros(1,length(x));
% err = zeros(1,length(x));
% %% 主循环
% for m=1:length(x)
%    % 应用初始相位到x
%    x(m) = x(m) * exp(-1j*(theta));
%    % 判断最近星座点
%    desired_point = 2*(real(x(m)) > 0)-1 + (2*(imag(x(m)) > 0)-1) * 1j;
%    % 计算相位差
%    angleErr = angle(x(m)*conj(desired_point));
%    % 二阶环路滤波器
%    theta_delta = kp * angleErr + ki * (theta_integral + angleErr);
%    theta_integral = theta_integral + angleErr;
%    % 累积相位误差
%    theta = theta + theta_delta + 2 * pi * fc / fs;
%    % 输出当前频偏纠正信号
%    y(m) = x(m);
%    err(m) = angleErr;
% end
% end

% 单元测试示例：
% % 创建带有频率偏移和相位偏移的QPSK信号
% symbols = [-1-1j, -1+1j, 1-1j, 1+1j];  % QPSK星座点
% data = symbols(randi(4, 1, 1000));     % 随机QPSK符号
% % 添加频率偏移和相位偏移
% t = 0:length(data)-1;
% freq_offset = 0.01;  % 归一化频率偏移
% phase_offset = pi/6; % 相位偏移
% offset_signal = data .* exp(1j*(2*pi*freq_offset*t + phase_offset));
% % 应用载波同步
% [sync_signal, ~] = QPSKFrequencyCorrectPLL(offset_signal, 0, 1, 0.001, 0.01);
% % 验证星座图收敛
% % scatterplot(sync_signal)应显示清晰的QPSK星座点

%% 8.6 帧同步模块 (FrameSync)
% 功能：通过穷举四种相位并与已知的`1ACFFC1D`同步字进行相关匹配，
% 在确定正确相位的同时，定位数据帧的起始边界
% 原理：QPSK星座图具有π/2的旋转对称性，PLL环路可能锁定在四个稳定状态中的任意一个，
% 导致恢复的符号存在0, 90, 180, 或270度的固定相位偏差。
% FrameSync模块通过穷举四种可能的相位校正，找到能产生最强相关峰值的相位，
% 同时确定帧的起始位置。

% 代码实现要点：
% 1. 穷举四种可能的相位校正（乘以exp(j*k*pi/2)，其中k=0,1,2,3）
% 2. 对每一种校正后的结果，进行硬判决得到比特流
% 3. 使用滑窗将比特流与本地存储的32位CCSDS同步字`1ACFFC1D`进行相关性计算
% 4. 找到相关峰值最大的相位校正和位置

%% 8.7 解扰模块 (FrameScramblingModule)
% 功能：根据CCSDS标准，使用1+X^14+X^15多项式，对已同步的帧数据进行解扰，
% 恢复出经LDPC编码后的原始数据
% 原理：在发射端，数据在LDPC编码后、加入同步字之前，经过了加扰处理。
% 加扰的目的是打破数据中可能存在的长串"0"或"1"，保证信号频谱的均匀性。
% 接收端通过与发射端同步的伪随机序列进行异或运算，恢复原始数据。

% 代码实现：
% function [I_array,Q_array] = FrameScramblingModule(s_symbols)
% % 定义I路和Q路的解扰器相位
% InPhase_I = ones(1,15);  % I路初相: 111111111111111
% InPhase_Q = [ones(1,8),zeros(1,7)];  % Q路初相: 111111110000000
% % 获取I路和Q路
% I_bits = real(s_symbols);
% Q_bits = imag(s_symbols);
% % 对每行进行解扰处理
% for m=1:rows
%    I_row_bits = I_bits(m,:);
%    Q_row_bits = Q_bits(m,:);
%    % 尝试解扰，考虑IQ未反向
%    I_deScrambling = ScramblingModule(I_row_bits,InPhase_I);
%    Q_deScrambling = ScramblingModule(Q_row_bits,InPhase_Q);
%    % 检查是否合法（末尾两位为00）
%    if I_deScrambling(8159) == 0 && I_deScrambling(8160) == 0 && Q_deScrambling(8159) == 0 && Q_deScrambling(8160) == 0
%        I_array(m,:) = I_deScrambling;
%        Q_array(m,:) = Q_deScrambling;
%    else
%        % IQ两路交换，然后解扰
%        I_deScrambling = ScramblingModule(I_row_bits,InPhase_Q);
%        Q_deScrambling = ScramblingModule(Q_row_bits,InPhase_I);
%        % 检查是否合法
%        if I_deScrambling(8159) == 0 && I_deScrambling(8160) == 0 && Q_deScrambling(8159) == 0 && Q_deScrambling(8160) == 0
%            I_array(m,:) = Q_deScrambling;
%            Q_array(m,:) = I_deScrambling;
%        else
%            % 维持原样输出
%            I_array(m,:) = I_deScrambling;
%            Q_array(m,:) = Q_deScrambling;
%        end
%    end
% end
% end

%% 9. 总结与展望
% 本项目通过一系列精心设计的MATLAB模块，并配以此深度解析教程，成功实现并剖析了一个功能完备的QPSK接收机。
% 通过本分步指南，您不仅能够亲手操作和观察每一个处理环节，更能深入理解核心算法的理论精髓。
%
% 我们按照从整体到部分的方式，首先介绍了完整的接收机处理流程和使用方法，
% 然后深入解析了每个子模块的实现原理和代码细节，最后提供了原理解析和单元测试示例。
%
% 至此，您已经掌握了构建一个基本数字接收机的全套流程和核心技术。以此为基础，您可以进一步探索更高级的主题。
%
% **进一步学习建议:**
% *   **信道编码:** 实现卷积码/Turbo码的编译码器（如Viterbi解码），以对抗信道噪声。
% *   **高级调制:** 将QPSK扩展到16-QAM, 64-QAM等高阶调制方式。
% *   **OFDM系统:** 将单载波系统扩展到多载波系统，以对抗频率选择性衰落。
%
% 希望本教程能成为您在数字通信学习道路上的一块坚实基石。