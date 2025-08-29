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


%% 5.1 预备步骤：数据加载与重采样
% 本模块包含两个关键步骤：
% 1. 从二进制文件加载原始IQ数据
% 2. 执行重采样降低采样率（500MHz → 150MHz）
% 
% 操作指导：
% 1.  打开主脚本 SatelliteQPSKReceiverTest.m。
% 2.  熟悉 config 结构体中的各项参数，特别是 startBits 和 bitsLength，
%     它们决定了从数据文件的哪个位置开始处理，以及处理多长的数据段。
% 3.  了解重采样参数：resampleMolecule=3, resampleDenominator=10

%% 5.1.1 信号加载模块原理解析
% 功能：从二进制文件中读取原始IQ样本
% 原理：该模块负责读取存储在磁盘上的复数信号数据，数据格式为int16类型，
% I路和Q路数据交替存储。函数支持指定起始位置和读取长度，方便对大文件进行分段处理。

%% 理论指导
% 在数字通信系统中，接收机首先需要从存储介质（如文件）中加载原始的IQ数据。
% 这些数据通常以二进制格式存储，以节省存储空间并提高读取效率。
% 在本项目中，数据以int16格式存储，I路和Q路数据交替排列。

%% 参数说明
% *   filename: 数据文件的路径和名称
% *   pointStart: 读取数据的起始点（以复数点为单位）
% *   Nread: 要读取的数据点数，-1表示读取文件中所有剩余数据

%% 代码实现详解

%% SignalLoader实现代码
% lib/SignalLoader.m
% 首先配置数据文件参数
clc;clear all;
config.inputDataFilename = "data/small_sample_256k.bin"; % 数据文件路径
config.sourceSampleRate = 500e6; % 原始信号采样率

% 检查数据文件是否存在，不存在则创建模拟数据
if ~exist(config.inputDataFilename, 'file')
    fprintf('警告：测试数据文件 %s 不存在，将创建模拟数据文件\n', config.inputDataFilename);
    
    % 创建模拟数据文件
    simulated_data = complex(randn(1, 10000), randn(1, 10000));  % 生成10000个复数样本
    
    % 保存为二进制文件
    fid = fopen(config.inputDataFilename, 'wb');
    for i = 1:length(simulated_data)
        fwrite(fid, [int16(real(simulated_data(i))), int16(imag(simulated_data(i)))], 'int16');
    end
    fclose(fid);
    
    fprintf('已创建模拟数据文件 %s\n', config.inputDataFilename);
end

% 设置读取参数
filename = config.inputDataFilename;
pointStart = 1;
Nread = -1;

% 打开文件
fid = fopen(filename, 'rb');

% 设置搜索指针
fseek(fid, (pointStart - 1) * 8, 'bof');

% 读取数据
if Nread == -1
    % 读取文件中所有剩余数据
    raw = fread(fid, [2, Inf], 'int16');
else
    % 读取指定数量的数据
    raw = fread(fid, [2, Nread], 'int16');
end

s_raw = complex(raw(1,:), raw(2,:));

%关闭指针
fclose(fid);

%% 结果验证与输出
% 检查信号加载是否成功
if ~isempty(s_raw) && isnumeric(s_raw) && isreal(s_raw) == false
    fprintf('✓ 信号加载成功！\n');
    fprintf('  - 加载数据点数：%d\n', length(s_raw));
    fprintf('  - 数据类型：%s\n', class(s_raw));
    fprintf('  - 实部范围：[%.2f, %.2f]\n', min(real(s_raw)), max(real(s_raw)));
    fprintf('  - 虚部范围：[%.2f, %.2f]\n', min(imag(s_raw)), max(imag(s_raw)));
    fprintf('  - 平均功率：%.2f\n', mean(abs(s_raw).^2));
else
    fprintf('✗ 信号加载失败！\n');
    fprintf('  - 错误：数据为空或格式不正确\n');
end

%% 功率谱密度分析
% 计算并绘制原始信号的功率谱密度
figure('Name', '原始信号功率谱密度', 'Position', [100, 100, 800, 600]);

% 计算功率谱密度
[pxx, f] = pwelch(s_raw, [], [], [], config.sourceSampleRate, 'centered');

% 绘制功率谱密度
subplot(2,1,1);
plot(f/1e6, 10*log10(pxx), 'b', 'LineWidth', 1.5);
grid on;
title('原始信号功率谱密度（线性坐标）');
xlabel('频率 (MHz)');
ylabel('功率谱密度 (dB/Hz)');
xlim([-config.sourceSampleRate/2e6, config.sourceSampleRate/2e6]);

% 绘制频谱瀑布图
subplot(2,1,2);
spectrogram(s_raw, 1024, 512, 1024, config.sourceSampleRate, 'yaxis');
title('原始信号频谱瀑布图');
colorbar;

%% 信号质量分析
% 计算信号统计特性
fprintf('\n=== 信号质量分析 ===\n');
fprintf('信号长度：%d 点\n', length(s_raw));
fprintf('采样率：%.2f MHz\n', config.sourceSampleRate/1e6);
fprintf('信号持续时间：%.3f 秒\n', length(s_raw)/config.sourceSampleRate);

% 计算信号功率
signal_power = mean(abs(s_raw).^2);
fprintf('信号平均功率：%.2f\n', signal_power);

% 计算信号带宽（基于-3dB带宽）
[pxx, f] = pwelch(s_raw, [], [], [], config.sourceSampleRate, 'centered');
pxx_db = 10*log10(pxx);
max_power = max(pxx_db);
threshold_3db = max_power - 3;

% 找到-3dB带宽
indices = find(pxx_db >= threshold_3db);
if ~isempty(indices)
    bandwidth_3db = (f(indices(end)) - f(indices(1))) / 1e6;
    fprintf('-3dB带宽：%.2f MHz\n', bandwidth_3db);
else
    fprintf('无法确定-3dB带宽\n');
end

% 计算信号峰均比
peak_power = max(abs(s_raw).^2);
papr = peak_power / signal_power;
fprintf('峰均比（PAPR）：%.2f dB\n', 10*log10(papr));

% 计算I/Q路平衡性
I_component = real(s_raw);
Q_component = imag(s_raw);
I_power = mean(I_component.^2);
Q_power = mean(Q_component.^2);
IQ_imbalance = abs(I_power - Q_power) / (I_power + Q_power) * 100;
fprintf('I/Q路功率不平衡度：%.2f%%\n', IQ_imbalance);

fprintf('=====================\n\n');

%% 5.1.2 重采样模块实现
% 原始信号采样率为500MHz，为了减少计算复杂度并提高后续处理效率，
% 需要将采样率降低到150MHz（重采样比例为3/10）

%% 重采样理论背景
% 在数字信号处理中，重采样（Resampling）是改变信号采样率的过程。
% 本项目中需要进行降采样，主要原因包括：
% 
% 1. **计算效率考虑**：
%    - 原始500MHz采样率产生的数据量巨大，后续处理计算量大
%    - 降采样到150MHz可以显著减少数据点，提高处理速度
% 
% 2. **系统匹配考虑**：  
%    - 150MHz采样率更适合150Mbps的数传速率处理
%    - 符合奈奎斯特采样定理：采样率 > 2倍信号带宽
% 
% 3. **MATLAB resample函数原理**：
%    - 先进行L倍上采样（插零）
%    - 通过低通滤波器抑制镜像频谱
%    - 再进行M倍下采样
%    - 最终采样率变化比例为 L/M
% 
% 在本实现中：L=3（resampleMolecule），M=10（resampleDenominator）
% 新采样率 = 原采样率 × (3/10) = 500MHz × 0.3 = 150MHz

fprintf('=== 重采样处理 ===\n');

% 重采样参数配置
config.resampleMolecule = 3; % 重采样分子（上采样倍数）
config.resampleDenominator = 10; % 重采样分母（下采样倍数）
config.fs = 150e6; % 重采样后的采样率

fprintf('重采样参数：\n');
fprintf('  - 原始采样率：%.0f MHz\n', config.sourceSampleRate/1e6);
fprintf('  - 重采样比例：%d/%d = %.3f\n', config.resampleMolecule, config.resampleDenominator, config.resampleMolecule/config.resampleDenominator);
fprintf('  - 目标采样率：%.0f MHz\n', config.fs/1e6);

% 执行重采样（参考学生案例实现）
fprintf('正在执行重采样...\n');
tic;
s_qpsk = resample(s_raw, config.resampleMolecule, config.resampleDenominator);
resample_time = toc;

fprintf('✓ 重采样完成！\n');
fprintf('  - 处理时间：%.3f 秒\n', resample_time);
fprintf('  - 原始数据点数：%d\n', length(s_raw));
fprintf('  - 重采样后数据点数：%d\n', length(s_qpsk));
fprintf('  - 数据长度变化比例：%.3f\n', length(s_qpsk)/length(s_raw));
fprintf('  - 理论长度变化比例：%.3f\n', config.resampleMolecule/config.resampleDenominator);

%% 5.1.3 重采样效果验证与分析
% 绘制重采样前后的频谱对比
figure('Name', '重采样前后频谱对比', 'Position', [200, 150, 1000, 700]);

% 计算重采样前后的功率谱密度
[pxx_original, f_original] = pwelch(s_raw, [], [], [], config.sourceSampleRate, 'centered');
[pxx_resampled, f_resampled] = pwelch(s_qpsk, [], [], [], config.fs, 'centered');

% 绘制原始信号频谱
subplot(3,1,1);
plot(f_original/1e6, 10*log10(pxx_original), 'b', 'LineWidth', 1.5);
grid on;
title('重采样前信号频谱（500 MHz采样率）');
xlabel('频率 (MHz)');
ylabel('功率谱密度 (dB/Hz)');
xlim([-config.sourceSampleRate/2e6, config.sourceSampleRate/2e6]);

% 绘制重采样后信号频谱
subplot(3,1,2);
plot(f_resampled/1e6, 10*log10(pxx_resampled), 'r', 'LineWidth', 1.5);
grid on;
title('重采样后信号频谱（150 MHz采样率）');
xlabel('频率 (MHz)');
ylabel('功率谱密度 (dB/Hz)');
xlim([-config.fs/2e6, config.fs/2e6]);

% 绘制时域信号对比（仅显示前1000个点）
subplot(3,1,3);
t_original = (0:min(999, length(s_raw)-1)) / config.sourceSampleRate * 1e6;
t_resampled = (0:min(999, length(s_qpsk)-1)) / config.fs * 1e6;

plot(t_original, real(s_raw(1:length(t_original))), 'b-', 'LineWidth', 1.5, 'DisplayName', '原始信号(I路)');
hold on;
plot(t_resampled, real(s_qpsk(1:length(t_resampled))), 'r--', 'LineWidth', 1.5, 'DisplayName', '重采样后信号(I路)');
grid on;
title('时域信号对比（前1000点）');
xlabel('时间 (μs)');
ylabel('幅度');
legend;
xlim([0, max(max(t_original), max(t_resampled))]);

%% 5.1.4 重采样质量评估
fprintf('\n=== 重采样质量评估 ===\n');

% 计算重采样前后的信号功率
original_power = mean(abs(s_raw).^2);
resampled_power = mean(abs(s_qpsk).^2);
power_ratio = resampled_power / original_power;

fprintf('信号功率对比：\n');
fprintf('  - 原始信号功率：%.6f\n', original_power);
fprintf('  - 重采样后功率：%.6f\n', resampled_power);
fprintf('  - 功率比值：%.6f\n', power_ratio);
fprintf('  - 功率变化：%.2f dB\n', 10*log10(power_ratio));

% 计算有效位数（ENOB）估计
% 通过比较信号与量化噪声的比值来估计
snr_original = 20*log10(std(real(s_raw))/mean(abs(real(s_raw) - round(real(s_raw)))));
snr_resampled = 20*log10(std(real(s_qpsk))/mean(abs(real(s_qpsk) - round(real(s_qpsk)))));

fprintf('信号质量指标：\n');
if ~isnan(snr_original) && isfinite(snr_original)
    fprintf('  - 原始信号SNR估计：%.2f dB\n', snr_original);
end
if ~isnan(snr_resampled) && isfinite(snr_resampled)
    fprintf('  - 重采样后SNR估计：%.2f dB\n', snr_resampled);
end

% 计算频域相关性（重叠频段的相关性）
overlap_freq = min(config.sourceSampleRate/2, config.fs/2);
freq_indices_orig = find(abs(f_original) <= overlap_freq);
freq_indices_resamp = find(abs(f_resampled) <= overlap_freq);

if length(freq_indices_orig) > 10 && length(freq_indices_resamp) > 10
    % 插值到相同的频率网格进行比较
    freq_common = linspace(-overlap_freq, overlap_freq, min(length(freq_indices_orig), length(freq_indices_resamp)));
    pxx_orig_interp = interp1(f_original(freq_indices_orig), pxx_original(freq_indices_orig), freq_common, 'linear', 'extrap');
    pxx_resamp_interp = interp1(f_resampled(freq_indices_resamp), pxx_resampled(freq_indices_resamp), freq_common, 'linear', 'extrap');
    
    freq_correlation = corrcoef(pxx_orig_interp, pxx_resamp_interp);
    fprintf('  - 频域相关系数：%.6f\n', freq_correlation(1,2));
end

fprintf('======================\n\n');

% 关键实现细节
% 1. 文件指针定位：fseek(fid, (pointStart - 1) * 8, 'bof')中乘以8是因为每个复数点包含两个int16值（I和Q），每个int16占2字节，总共4字节。
% 2. 数据读取： fread(fid, [2, Inf], 'int16')将数据按2行N列的方式读取，第一行是I路数据，第二行是Q路数据。
% 3. 复数构造：complex(raw(1,:), raw(2,:))将I路和Q路数据组合成复数信号。

%% 5.2 模块详解: RRC匹配滤波
% 预期效果: 信号通过RRC滤波器后，频谱被有效抑制在符号速率范围内，眼图张开，为后续的定时同步做好了准备。

%% 5.2.1 RRC匹配滤波模块原理解析
% 功能：作为匹配滤波器，最大化信噪比，并消除码间串扰（ISI）
% 原理：使用根升余弦（RRC）滤波器对信号进行脉冲成形，限制信号带宽并消除码间串扰。
% RRC滤波器是发射机和接收机各使用一个根升余弦滤波器的匹配滤波方案，
% 两个级联的RRC滤波器等效于一个升余弦（RC）滤波器。

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

%% 代码实现详解
% 在 lib/RRCFilterFixedLen.m 中，核心是MATLAB的 rcosdesign 函数。
% 
% 
%% RRCFilterFixedLen实现代码
% lib/RRCFilterFixedLen.m
% 完整的脚本形式实现，直接使用5.1模块中已定义的参数

% 使用5.1模块中已定义的参数（不重新定义）
% fs = config.fs;              % 采样率 150MHz（重采样后）- 已在5.1中定义
% config.resampleMolecule = 3;  % 重采样分子 - 已在5.1中定义
% config.resampleDenominator = 10; % 重采样分母 - 已在5.1中定义
% s_qpsk                       % 输入信号（来自5.1重采样后的信号）- 已在5.1中生成

% RRC滤波器特定参数
fb = config.fs / 2;              % 符号率（采样率的一半，对应QPSK）
alpha = 0.33;                    % 滚降系数
mode = 'rrc';                    % 滤波器模式：'rrc'表示根升余弦
x = s_qpsk;                      % 输入信号

% 滤波器设计参数
span = 8; % 滤波器长度（单位符号数），即滤波器覆盖8个符号的长度
sps = floor(config.fs / fb); % 每符号采样数 (Samples Per Symbol)

fprintf('RRC滤波器参数：\n');
fprintf('  - 采样率 fs: %.0f MHz (来自5.1模块)\n', config.fs/1e6);
fprintf('  - 符号率 fb: %.0f MBaud\n', fb/1e6);
fprintf('  - 每符号采样数 sps: %d\n', sps);
fprintf('  - 滚降系数 alpha: %.2f\n', alpha);
fprintf('  - 滤波器长度 span: %d 符号\n', span);
fprintf('  - 滤波器模式: %s\n', mode);

% 生成滤波器系数
% 'sqrt' 模式指定了生成根升余弦(RRC)滤波器
if strcmpi(mode, 'rrc')
    % Root Raised Cosine
    h = rcosdesign(alpha, span, sps, 'sqrt');
    fprintf('生成根升余弦(RRC)滤波器系数\n');
elseif strcmpi(mode, 'rc')
    % Raised Cosine
    h = rcosdesign(alpha, span, sps, 'normal');
    fprintf('生成升余弦(RC)滤波器系数\n');
else
    error("Unsupported mode. Use 'rrc' or 'rc'.");
end

fprintf('  - 滤波器系数长度: %d\n', length(h));
fprintf('  - 理论系数长度: %d (span * sps + 1)\n', span * sps + 1);

% 卷积，'same' 参数使输出长度与输入长度一致
fprintf('正在执行RRC滤波...\n');
tic;
s_rrc_filtered = conv(x, h, 'same');
filter_time = toc;

fprintf('✓ RRC滤波完成！\n');
fprintf('  - 处理时间: %.3f 秒\n', filter_time);
fprintf('  - 输入信号长度: %d\n', length(x));
fprintf('  - 输出信号长度: %d\n', length(s_rrc_filtered));
fprintf('  - 滤波器引入的群延迟: %.1f 个样本\n', (length(h)-1)/2);

%% 关键实现细节
% 1. span参数：滤波器长度，单位为符号数。值为8表示滤波器覆盖8个符号的长度。
% 2. sps参数：每符号采样数(Samples Per Symbol)，通过floor(fs / fb)计算得到。
% 3. mode参数：指定滤波器类型，'rrc'表示根升余弦滤波器，'rc'表示升余弦滤波器。
% 4. rcosdesign函数：MATLAB内置函数，用于生成升余弦或根升余弦滤波器系数。
% 5. conv函数：执行卷积运算，'same'参数确保输出长度与输入长度一致。

%% 复现与观察:
% 1. 上述代码已完成RRC滤波处理，输出信号存储在s_rrc_filtered变量中。
% 2. 观察频谱：绘制滤波后信号的功率谱，验证频谱整形效果。
figure('Name', 'RRC滤波后信号频谱', 'Position', [300, 200, 800, 500]);
pwelch(s_rrc_filtered, [], [], [], config.fs, 'centered'); % 使用5.1模块的采样率
title('RRC滤波后的信号频谱');
xlabel('频率 (Hz)');
ylabel('功率谱密度 (dB/Hz)');
grid on;
% 您应该能看到信号的功率被集中在符号率带宽 [-fb/2, fb/2] 附近，
% 总带宽约为 (1+alpha)*fb = (1+0.33)*75 ≈ 100 MHz。频谱边缘有平滑的滚降。

% 3. 观察星座图：此时绘制星座图，由于未经任何同步，
%    它看起来会是一个非常模糊的、旋转的环形。这是正常的。
figure('Name', 'RRC滤波后星座图', 'Position', [400, 300, 600, 600]);
scatterplot(s_rrc_filtered(1:2000)); % 只显示前2000个点以提高显示速度
title('RRC滤波后的星座图（未同步）');
grid on;
axis equal;


%% 5.2.2 AGC归一化模块实现
% 基于学生实现的AGC（自动增益控制）算法，将RRC滤波后的信号功率归一化
% AGC是接收机中的重要模块，确保信号功率稳定，便于后续的同步和解调处理

fprintf('正在执行AGC归一化...\n');
tic;

% AGC归一化实现（基于学生代码）
target_power = 1;      % 目标功率
agc_step = 0.01;       % AGC步长参数
gain = 1.0;            % 初始化增益
s_qpsk_agc = zeros(size(s_rrc_filtered));  % 预分配输出

% 实时逐点更新AGC（模拟时序处理）
for n = 1:length(s_rrc_filtered)
    % 当前输入样本
    sample = s_rrc_filtered(n);
    
    % 当前功率
    current_power = abs(sample * gain)^2;
    
    % 误差
    error = target_power - current_power;
    
    % 更新增益
    gain = gain + agc_step * error * gain;
   
    % 防止增益爆炸
    if gain < 1e-6
       gain = 1e-6;
    elseif gain > 1e6
       gain = 1e6;
    end 
    
    % 应用增益
    s_qpsk_agc(n) = gain * sample;
end

fprintf('AGC归一化完成，耗时: %.4f 秒\n', toc);

% 计算归一化前后的信号功率
original_power = mean(abs(s_rrc_filtered).^2);
agc_power = mean(abs(s_qpsk_agc).^2);
fprintf('RRC滤波后信号功率: %.4f\n', original_power);
fprintf('AGC归一化后信号功率: %.4f\n', agc_power);

%% 5.2.3 RRC滤波器效果可视化
% 绘制滤波前后的频谱对比和星座图对比，直观观察RRC滤波器的作用效果
% 这些可视化有助于理解RRC滤波器在接收机中的关键作用

% 频谱对比图
figure;
subplot(2,1,1);
pwelch(s_qpsk, [], [], [], config.fs, 'centered');
title('RRC滤波前的信号频谱');
ylabel('功率谱密度 (dB/Hz)');

subplot(2,1,2);
pwelch(s_rrc_filtered, [], [], [], config.fs, 'centered');
title('RRC滤波后的信号频谱');
ylabel('功率谱密度 (dB/Hz)');

sgtitle('RRC滤波器频谱对比');

% 星座图对比 - 三个独立图形
% 原始信号星座图
figure;
scatterplot(s_qpsk(1:1000));
title('原始信号星座图');

% RRC滤波后星座图
figure;
scatterplot(s_rrc_filtered(1:1000));
title('RRC滤波后星座图');

% AGC归一化后星座图
figure;
scatterplot(s_qpsk_agc(1:1000));
title('AGC归一化后星座图');

%% 5.2.4 模块优化总结
% 本模块优化要点：
% 1. 移除了重复的数据加载代码，依赖5.1模块已加载的数据
% 2. 专注于RRC滤波功能的核心实现和验证
% 3. 修正了符号率与比特率的概念混淆问题
% 4. 增强了测试的鲁棒性，使用更合理的带宽验证阈值
% 5. 新增了AGC归一化模块，基于学生实现完成信号功率归一化
% 6. 提供了完整的效果可视化功能，便于理解RRC滤波器和AGC的作用
% 
% 后续模块可以直接使用变量s_qpsk_agc作为输入

%% 测试执行与验证说明
% 1. 本优化后的5.2模块包含RRC滤波和AGC归一化功能，不再重复加载数据
% 2. 频谱观察：通过上述可视化代码可观察到滤波前后信号频谱的明显变化
% 3. 星座图分析：可以看到RRC滤波和AGC归一化对星座图的整形效果
% 4. 功率监控：AGC模块确保信号功率稳定在目标值附近
% 5. 模块间数据传递：后续模块可直接使用s_qpsk_agc变量


%% 5.3 模块详解: Gardner定时同步
% 预期效果: 经过Gardner同步后，采样点被调整到每个符号的最佳位置。
% 此时的星座图，点会从之前的弥散环状开始向四个目标位置收敛，形成四个模糊的"云团"，
% 但由于未经载波同步，整个星座图可能仍在旋转，即仍为环形。

%% 5.3.1 Gardner定时同步模块原理解析
% 功能：找到每个符号波形的"最佳"采样时刻
% 原理：Gardner算法是一种高效的、不依赖于载波相位的定时误差检测算法。
% 它的核心思想是：在每个符号周期内，采集两个样本：一个是在预估的最佳采样点（判决点），
% 另一个是在两个判决点之间的中点。通过计算这两个采样点之间的误差来调整采样时刻。

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

%% 代码实现详解
% 在 lib/GardnerSymbolSync.m 中，核心逻辑在 for 循环内。

%% Gardner定时同步实现代码
% 接收5.2节的输出数据
s_qpsk_input = s_qpsk_agc;  % 使用AGC归一化后的信号作为输入

% Gardner算法参数配置
B_loop = 0.0001; % 归一化环路带宽 (与学生实现保持一致)
zeta = 0.707;    % 阻尼系数 (经典最优值)

fprintf('Gardner定时同步参数设置:\n');
fprintf('  - 环路带宽 B_loop: %.4f\n', B_loop);
fprintf('  - 阻尼系数 zeta: %.3f\n', zeta);
fprintf('  - 输入信号长度: %d\n', length(s_qpsk_input));

%% lib/GardnerSymbolSync.m
%% 参数配置
Wn = 2 * pi * B_loop / sps;  % 环路自然频率

% 环路滤波器(PI)系数
c1 = (4 * zeta * Wn) / (1 + 2 * zeta * Wn + Wn^2);
c2 = (4 * Wn^2)      / (1 + 2 * zeta * Wn + Wn^2);

%% 初始化状态
ncoPhase = 0;                    % NCO相位累加器
wFilterLast = 1 / sps;           % 初始定时步进 (每个输入样本代表 1/sps 个符号)

% 算法状态变量
isStrobeSample = false;          % 状态标志: false->中点采样, true->判决点采样
timeErrLast = 0;                 % 上一次的定时误差
wFilter = wFilterLast;           % 环路滤波器输出

% 数据存储
y_last_I = 0; y_last_Q = 0;      % 上一个判决点采样值
mid_I = 0; mid_Q = 0;             % 中点采样值
y_I_Array = []; y_Q_Array = [];  % 输出数组

% 调试变量 - 让读者观察算法工作过程
debug_mu_values = [];            % 记录分数插值间隔mu
debug_timeErr = [];              % 记录时序误差
debug_wFilter = [];              % 记录环路滤波器输出
debug_sample_count = 0;          % 采样计数器

fprintf('Gardner算法状态初始化完成\n');
fprintf('开始主循环处理...\n');

%% Gardner 同步主循环
for m = 6 : length(s_qpsk_input)-3
    % NCO相位累加 (每个输入样本前进 wFilterLast 的相位)
    % 当 ncoPhase 越过 0.5 时，产生一个中点或判决点采样
    ncoPhase_old = ncoPhase;
    ncoPhase = ncoPhase + wFilterLast;

    % 使用 while 循环处理 - 当相位越过0.5时触发采样
    while ncoPhase >= 0.5
        % --- 第一步: 计算插值时刻 (mu) ---
        % 计算过冲点在当前采样区间的归一化位置
        mu = (0.5 - ncoPhase_old) / wFilterLast;
        base_idx = m - 1;
        
        % 记录分数插值间隔mu供调试观察
        debug_mu_values(end+1) = mu;
        
        % 调试信息：让读者观察插值参数
        if mod(length(y_I_Array), 500) == 0 && length(y_I_Array) < 2000
            if isStrobeSample
                state_str = '判决点';
            else
                state_str = '中点';
            end
            fprintf('  样本 %d: mu=%.4f, base_idx=%d, 当前状态=%s\n', ...
                length(y_I_Array), mu, base_idx, state_str);
        end

        % --- 使用Farrow 立方插值器 (完全展开的内联实现) ---
        % === I路插值处理 ===
        % Farrow 结构三阶(Cubic)插值器
        % 使用 base_idx-1, base_idx, base_idx+1, base_idx+2 四个点估计 x(base_idx+mu)
        index = base_idx;
        x = real(s_qpsk_input);  % 提取I路实部
        u = mu;  % 分数延迟
        
        if index < 2 || index > length(x) - 2
            y_I_sample = 0;  % 边界处理，输出零
        else
            % 获取四个相邻采样点
            x_m1 = x(index - 1);  % x(n-1)
            x_0  = x(index);       % x(n)
            x_p1 = x(index + 1);   % x(n+1)
            x_p2 = x(index + 2);   % x(n+2)
            
            % 计算Farrow 结构系数 (I路专用变量)
            farrow_c0_I = x_0;
            farrow_c1_I = 0.5 * (x_p1 - x_m1);
            farrow_c2_I = x_m1 - 2.5*x_0 + 2*x_p1 - 0.5*x_p2;
            farrow_c3_I = -0.5*x_m1 + 1.5*x_0 - 1.5*x_p1 + 0.5*x_p2;
            
            % Horner方法计算插值结果: y = ((c3*u + c2)*u + c1)*u + c0
            y_I_sample = ((farrow_c3_I * u + farrow_c2_I) * u + farrow_c1_I) * u + farrow_c0_I;
        end
        
        % === Q路插值处理 ===
        % Farrow 结构三阶(Cubic)插值器
        % 使用 base_idx-1, base_idx, base_idx+1, base_idx+2 四个点估计 x(base_idx+mu)
        index = base_idx;
        x = imag(s_qpsk_input);  % 提取Q路虚部
        u = mu;  % 分数延迟
        
        if index < 2 || index > length(x) - 2
            y_Q_sample = 0;  % 边界处理，输出零
        else
            % 获取四个相邻采样点
            x_m1 = x(index - 1);  % x(n-1)
            x_0  = x(index);       % x(n)
            x_p1 = x(index + 1);   % x(n+1)
            x_p2 = x(index + 2);   % x(n+2)
            
            % 计算Farrow 结构系数 (Q路专用变量)
            farrow_c0_Q = x_0;
            farrow_c1_Q = 0.5 * (x_p1 - x_m1);
            farrow_c2_Q = x_m1 - 2.5*x_0 + 2*x_p1 - 0.5*x_p2;
            farrow_c3_Q = -0.5*x_m1 + 1.5*x_0 - 1.5*x_p1 + 0.5*x_p2;
            
            % Horner方法计算插值结果: y = ((c3*u + c2)*u + c1)*u + c0
            y_Q_sample = ((farrow_c3_Q * u + farrow_c2_Q) * u + farrow_c1_Q) * u + farrow_c0_Q;
        end
        
        if isStrobeSample
            % === 当前是判决点 (Strobe Point) ===
            
            % --- 第二步: Gardner 误差计算 ---
            % Gardner时序误差检测器公式:
            % e[k] = real{y_mid[k]} * (real{y_strobe[k]} - real{y_strobe[k-1]}) + 
            %        imag{y_mid[k]} * (imag{y_strobe[k]} - imag{y_strobe[k-1]})
            % 误差 = 中点采样 * (当前判决点 - 上一个判决点)
            timeErr = mid_I * (y_I_sample - y_last_I) + mid_Q * (y_Q_sample - y_last_Q);
            
            % 记录误差供调试观察
            debug_timeErr(end+1) = timeErr;

            % --- 第三步: 环路滤波器 (PI控制器) ---
            % wFilter = wFilterLast + c1*(e[k] - e[k-1]) + c2*e[k]
            wFilter = wFilterLast + c1 * (timeErr - timeErrLast) + c2 * timeErr;
            
            % 记录滤波器输出供调试观察
            debug_wFilter(end+1) = wFilter;

            % 调试信息：显示关键计算过程
            if mod(length(y_I_Array), 1000) == 0 && length(y_I_Array) < 5000
                fprintf('    判决点 %d: 时序误差=%.6f, 滤波器输出=%.6f\n', ...
                    length(y_I_Array), timeErr, wFilter);
            end

            % 存储状态用于下次计算
            timeErrLast = timeErr;
            y_last_I = y_I_sample;
            y_last_Q = y_Q_sample;

            % 将判决点采样存入结果数组
            y_I_Array(end+1) = y_I_sample;
            y_Q_Array(end+1) = y_Q_sample;

        else
            % === 当前是中点 (Midpoint) ===
            % 存储中点采样值，用于下一次的误差计算
            mid_I = y_I_sample;
            mid_Q = y_Q_sample;
        end

        % 更新环路滤波器输出 (每个判决点更新一次)
        if isStrobeSample
            wFilterLast = wFilter;
        end

        % 切换状态: 判决点 -> 中点, 中点 -> 判决点
        isStrobeSample = ~isStrobeSample;
        
        % NCO相位减去已处理的0.5个符号周期，并为下一次可能的触发更新"旧"相位
        % 错误修正: ncoPhase_old也应相应减去0.5，而不是被设为固定值。
        % 这能正确处理在单个输入采样间隔内触发多次符号输出的情况。
        ncoPhase_old = ncoPhase_old - 0.5;
        ncoPhase = ncoPhase - 0.5;
    end
end

%% 输出复数结果
sync_output = y_I_Array + 1j * y_Q_Array;

% 处理完成，显示详细统计信息
fprintf('\n=== Gardner定时同步完成 ===\n');
fprintf('  - 输入信号长度: %d 采样点\n', length(s_qpsk_input));
fprintf('  - 输出符号数量: %d 符号\n', length(sync_output));
fprintf('  - 符号抽取率: %.2f%% (每 %.1f 个采样点提取1个符号)\n', ...
    length(sync_output)/length(s_qpsk_input)*100, sps);
fprintf('  - 最终时序步进: %.6f\n', wFilterLast);
if ~isempty(debug_timeErr)
    fprintf('  - 平均时序误差: %.6f\n', mean(abs(debug_timeErr)));
end

% 验证输出信号的合理性
if length(sync_output) == 0
    warning('Gardner同步输出为空，可能存在参数设置问题');
elseif length(sync_output) > length(s_qpsk_input)
    warning('Gardner同步输出长度异常，超过输入长度');
end

%% 5.3.2 Gardner算法工作过程可视化
% 这些图表让读者直观理解Gardner算法的内部工作机制，下面是每个子图的理论预期：

% 1. 分数插值间隔mu (左上图):
%    - 理论预期：此图显示Gardner算法中的分数插值间隔mu值。
%      mu表示插值点在相邻两个采样点之间的相对位置，范围通常在[0,1)之间。
%    - mu的物理意义：
%      * mu ≈ 0：插值点靠近当前采样点
%      * mu ≈ 0.5：插值点在两个采样点的中间
%      * mu ≈ 1：插值点靠近下一个采样点
%    - 环路带宽Bn对mu的影响：
%      * 宽带环路(Bn较大)：环路响应快，mu值快速收敛但抖动大
%      * 窄带环路(Bn较小)：环路响应慢，mu值收敛慢但稳态抖动小
%      * 本项目Bn=0.0001：窄带设计，mu值应该收敛到稳定值且抖动很小
%    - 锁定过程：mu值从初始的大幅波动逐渐收敛到最佳采样位置对应的稳定值

% 2. Gardner时序误差 (右上图):
%    - 理论预期：这是瞬时的、未经滤波的定时误差。在环路锁定前，误差较大且可能无规则；
%      一旦环路开始“捕获”，误差会剧烈波动，反映了环路正在快速调整。锁定后，
%      误差应围绕“0”均值上下随机波动，其波动的剧烈程度（方差）取决于信噪比和环路带宽。

% 3. 环路滤波器输出 (左下图):
%    - 理论预期：此图显示的是NCO的控制信号，即每个采样时刻的步进值`wFilter`。
%      它从初始值`1/sps`（这里是0.5）开始，根据累积的定时误差进行调整。
%      锁定后，该值会非常接近真实的`1/sps`，并有微小波动以跟踪任何时钟频率漂移。

% 4. 时序误差收敛过程 (右下图):
%    - 理论预期：此图包含两条关键曲线：
%      - 有符号滑动平均 (红线): 这是判断环路是否存在“偏置”的关键。理论上，它应该收敛到零。
%        如果它稳定在一个非零值，说明存在持续的定时偏差。
%      - 绝对值滑动平均 (蓝线): 它反映了系统的“抖动”水平，不会收敛到零。
%        在有噪声的情况下，它会收敛到一个稳定的正值（噪声平台），这个值的大小代表了残余定时抖动的强度。

% 图1: 分数插值间隔mu
figure;
subplot(2,2,1);
if ~isempty(debug_mu_values)
    plot(debug_mu_values(1:min(5000,length(debug_mu_values))), 'b-', 'LineWidth', 1);
    title('分数插值间隔mu');
    xlabel('符号索引');
    ylabel('mu值');
    grid on;
    ylim([0, 1]);
    
    % 添加参考线
    yline(0, 'r--', 'alpha=0.5');
    yline(0.5, 'g--', 'alpha=0.5');
    yline(1, 'r--', 'alpha=0.5');
end

% 图2: 时序误差变化
subplot(2,2,2);
if ~isempty(debug_timeErr)
    plot(debug_timeErr(1:min(10000,length(debug_timeErr))));
    title('Gardner时序误差');
    xlabel('符号索引');
    ylabel('时序误差');
    grid on;
end

% 图3: 环路滤波器输出
subplot(2,2,3);
if ~isempty(debug_wFilter)
    plot(debug_wFilter(1:min(10000,length(debug_wFilter))));
    title('环路滤波器输出');
    xlabel('符号索引');
    ylabel('滤波器输出');
    grid on;
end

% 图4: 时序误差收敛过程
subplot(2,2,4);
if ~isempty(debug_timeErr) && length(debug_timeErr) > 10
    % 计算滑动平均，观察收敛趋势
    % 动态选择滑动平均窗口：随序列长度增长而增大，但有上限，保证平滑且可视化
    window = min(1000, max(50, floor(length(debug_timeErr)/100)));
    moving_abs = movmean(abs(debug_timeErr), window);
    moving_signed_mean = movmean(debug_timeErr, window);

    % 同图绘制有符号均值和绝对值滑动平均，便于对比
    plot(moving_abs, '-b'); hold on;
    plot(moving_signed_mean, '-r'); hold off;
    legend({'|e| (滑动平均)','e (有符号滑动平均)'}, 'Location','best');
    title('时序误差收敛过程 (滑动平均，含有符号均值)');
    xlabel('符号索引');
    ylabel('时序误差 (滑动平均)');
    grid on;

    % 计算并打印稳态统计量（取最后1/10段作为稳态估计）
    N = length(debug_timeErr);
    tailN = max(50, floor(N/10));
    steady_tail = debug_timeErr(max(1,N-tailN+1):N);
    steady_mean = mean(steady_tail);
    steady_std = std(steady_tail);
    fprintf('\n[诊断] 时序误差稳态统计 (最后 %d 个样本):\n', tailN);
    fprintf('  - 有符号均值 (偏置): %.6e\n', steady_mean);
    fprintf('  - 标准差 (抖动水平): %.6e\n', steady_std);
    fprintf('  - 绝对值滑动平均末值: %.6e\n', moving_abs(end));
end
sgtitle('Gardner算法内部工作过程可视化');

%% 5.3.3 Gardner定时同步效果对比
% 绘制Gardner同步前后的星座图对比，让读者看到算法效果

% 星座图1: 输入信号（未同步）
figure;
scatterplot(s_qpsk_input(1:min(10000,length(s_qpsk_input))));
title('输入信号星座图 (未同步) - Gardner同步前 (最多 10k 点)');
grid on;

% 星座图2: Gardner同步后的信号
figure;
scatterplot(sync_output(1:min(10000,length(sync_output))));
title('Gardner同步后星座图 - 完整效果 (最多 10k 点)');
grid on;

% 星座图3: 同步后信号的前100个符号（更清晰）
figure;
scatterplot(sync_output(1:min(10000,length(sync_output))));
title('Gardner同步后星座图 - 前若干符号 (最多 10k 点)');
grid on;

% 显示星座图收敛程度的数值分析
if length(sync_output) >= 100
    % 计算符号间的相位抖动
    phases = angle(sync_output);
    phase_diff = diff(unwrap(phases));
    phase_jitter = std(phase_diff);
    
    % 计算符号幅度的一致性
    amplitudes = abs(sync_output);
    amplitude_var = var(amplitudes) / mean(amplitudes)^2;
    
    fprintf('\n=== 同步质量分析 ===\n');
    fprintf('  - 相位抖动标准差: %.4f 弧度\n', phase_jitter);
    fprintf('  - 幅度变异系数: %.4f\n', amplitude_var);
    
    if phase_jitter < 0.1
        fprintf('  - 同步质量: 优秀\n');
    elseif phase_jitter < 0.3
        fprintf('  - 同步质量: 良好\n');
    else
        fprintf('  - 同步质量: 需要优化\n');
    end
end

%% 5.3.4 实践指导 - 读者可以尝试的实验
% 本节为MATLAB实时教程的核心，读者可以逐步执行并观察结果

fprintf('\n=== 5.3节实践指导 ===\n');
fprintf('1. 观察NCO相位累积图：理解时序跟踪的基本机制\n');
fprintf('2. 分析时序误差变化：观察Gardner算法如何检测定时偏差\n');
fprintf('3. 检查环路滤波器输出：了解PI控制器的平滑作用\n');
fprintf('4. 对比星座图变化：直观感受定时同步的效果\n');
fprintf('\n建议实验：\n');
fprintf('- 尝试修改B_loop参数（如0.001, 0.0001）观察收敛速度变化\n');
fprintf('- 调整zeta阻尼系数（如0.5, 1.0）观察系统响应特性\n');
fprintf('- 在不同信号段重复执行，观察算法的稳定性\n');

%% 5.3.5 模块技术总结
% 本模块的创新点和技术要点：
fprintf('\n=== 5.3节技术总结 ===\n');
fprintf('✓ Gardner算法：非数据辅助的定时同步，无需先验符号信息\n');
fprintf('✓ Farrow插值器：3阶立方插值，实现高精度分数延迟\n');
fprintf('✓ PI环路滤波器：最优的二阶系统设计，平衡响应速度与稳定性\n');
fprintf('✓ 环路带宽优化：Bn=0.0001窄带设计，确保稳态精度\n');
fprintf('✓ mu值监控：通过分数插值间隔观察环路锁定状态\n');
fprintf('\n核心公式回顾：\n');
fprintf('- Gardner误差: e[k] = mid_I*(strobe_I[k]-strobe_I[k-1]) + mid_Q*(strobe_Q[k]-strobe_Q[k-1])\n');
fprintf('- 环路滤波器: w[k] = w[k-1] + c1*(e[k]-e[k-1]) + c2*e[k]\n');
fprintf('- Farrow插值: y = ((c3*μ + c2)*μ + c1)*μ + c0\n');
fprintf('- 分数插值: μ = (0.5 - ncoPhase_old) / wFilterLast\n');

% 后续模块可以直接使用变量sync_output作为输入
fprintf('\n变量传递：sync_output -> 下一模块 (载波同步)\n');

%% 5.4 模块详解: 载波同步 (PLL)
% 预期效果: 经过PLL锁相环后，星座图的旋转被完全"锁住"，
% 四个点簇将清晰、稳定地聚集在理想位置附近。这是接收机同步成功的标志性时刻。

%% 5.4.1 载波同步模块原理解析
% 功能：校正频率与相位偏差，锁定星座图
% 原理：采用混合前馈/反馈PLL结构，结合了前馈频率补偿和反馈相位锁定。
% 前馈部分使用预估的中心频率偏移对信号进行粗略的频率校正，
% 反馈部分使用相位检测器和环路滤波器对剩余相位误差进行精确跟踪。

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

%% 代码实现详解
% 在 lib/QPSKFrequencyCorrectPLL.m 中，实现了混合式PLL的核心逻辑。

%% 载波同步实现代码
% lib/QPSKFrequencyCorrectPLL.m
%% 全局变量
theta = 0;
theta_integral = 0;

y = zeros(1,length(x));
err = zeros(1,length(x));

%% 主循环
for m=1:length(x)
   % 应用初始相位到x
   x(m) = x(m) * exp(-1j*(theta));
    
   % 判断最近星座点
   desired_point = 2*(real(x(m)) > 0)-1 + (2*(imag(x(m)) > 0)-1) * 1j;
   
   % 计算相位差
   angleErr = angle(x(m)*conj(desired_point));
   
   % 二阶环路滤波器
   theta_delta = kp * angleErr + ki * (theta_integral + angleErr);
   theta_integral = theta_integral + angleErr;
   
   % 累积相位误差
   theta = theta + theta_delta + 2 * pi * fc / fs;
   
   % 输出当前频偏纠正信号
   y(m) = x(m);
   err(m) = angleErr;
end

%% 关键实现细节
% 1. 相位校正：x(m) = x(m) * exp(-1j*(theta)) 实现相位校正
% 2. 硬判决：desired_point = 2*(real(x(m)) > 0)-1 + (2*(imag(x(m)) > 0)-1) * 1j 实现最近星座点判决
% 3. 相位误差计算：angleErr = angle(x(m)*conj(desired_point)) 精确计算相位差
% 4. PI控制器：theta_delta = kp * angleErr + ki * (theta_integral + angleErr) 实现环路滤波
% 5. NCO更新：theta = theta + theta_delta + 2 * pi * fc / fs 更新总相位

%% 复现与观察:
% 1. 在调试模式下，执行到载波同步行 (s_qpsk_cfo_sync = QPSKFrequencyCorrectPLL(...))。
% 2. 观察星座图 (决定性的一步): 执行完此行后，在命令窗口绘制星座图。
%    scatterplot(s_qpsk_cfo_sync);
%    title('载波同步后的星座图');
%    grid on;
%    此时，您应该能看到一个清晰、稳定的QPSK星座图。四个点簇分别紧密地聚集在理想位置附近。
%    这标志着接收机的同步过程已圆满成功！

%% 5.5 模块详解: 相位模糊恢复、帧同步与解扰
% 载波同步成功后，我们得到了清晰的星座图，但还面临三个紧密相关的问题：
% 相位模糊、帧边界未知和数据加扰。

%% 5.5.1 相位模糊恢复与帧同步模块原理解析
% 功能：通过穷举四种相位并与已知的`1ACFFC1D`同步字进行相关匹配，
% 在确定正确相位的同时，定位数据帧的起始边界
% 原理：QPSK星座图具有π/2的旋转对称性，PLL环路可能锁定在四个稳定状态中的任意一个，
% 导致恢复的符号存在0, 90, 180, 或270度的固定相位偏差。
% FrameSync模块通过穷举四种可能的相位校正，找到能产生最强相关峰值的相位，
% 同时确定帧的起始位置。

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

%% 代码实现详解
% 在 lib/FrameSync.m 中，实现了相位模糊恢复和帧同步的一体化处理。

%% 帧同步实现代码
% lib/FrameSync.m
%% 定义同步字
sync_bits_length = 32;
syncWord = uint8([0x1A,0xCF,0xFC,0x1D]);

% ByteArrayToBinarySourceArray内联实现
x = syncWord;
mode = "reverse";
%% ByteArrayToBinarySourceArray内联实现
y = [];
for m=1:length(x)
    %% ByteToBinarySource内联实现
    byte_x = x(m);
    byte_mode = mode;
    byte_y = zeros(1,8);
    %% 利用位运算依次取出每一位
    for n=1:8
        byte_y(n) = bitand(byte_x,1);
        byte_x = bitshift(byte_x,-1);
    end
    
    if byte_mode == "reverse"
        byte_y = fliplr(byte_y);
    end
    %% 结束ByteToBinarySource内联实现
    
    y = [y,byte_y];
end
%% 结束ByteArrayToBinarySourceArray内联实现

syncWord_bits = y;
ref_bits_I = syncWord_bits;
ref_bits_Q = syncWord_bits;

%% 定义帧长度
frame_len = 8192;
sync_frame_bits = [];
sync_index_list = [];  % 用于记录同步成功的位置

% 设置FrameSync的输入信号（使用载波同步后的信号）
s_symbol = sync_signal;

%% 主循环：搜索帧同步位置
for m = 1 : length(s_symbol) - frame_len
    s_frame = s_symbol(1, m : m + frame_len - 1);  % 提取一个可能的帧

    % 处理相位模糊（旋转3次，每次90°）
    for n = 1 : 3
        s_frame = s_frame * (1i);  % 逆时针旋转90度
        
        % 提取前同步字部分
        s_sync_frame = s_frame(1 : sync_bits_length);
        % SymbolToIdeaSymbol内联实现
        input_symbols = s_sync_frame;
        %% 初始化理想符号数组
        s_sync_frame_bits = zeros(1,length(input_symbols)) + 1j*zeros(1,length(input_symbols));
        for idx=1:length(input_symbols)
            symbol_I = real(input_symbols(idx));
            symbol_Q = imag(input_symbols(idx));
            
            if symbol_I > 0 && symbol_Q > 0
                s_sync_frame_bits(idx) = 0 + 0j;
            elseif symbol_I < 0 && symbol_Q > 0
                s_sync_frame_bits(idx) = 1 + 0j;
            elseif symbol_I < 0 && symbol_Q < 0
                s_sync_frame_bits(idx) = 1 + 1j;
            elseif symbol_I > 0 &&  symbol_Q < 0
                s_sync_frame_bits(idx) = 0 + 1j;
            end
        end
        
        i_sync_frame_bits = real(s_sync_frame_bits);
        q_sync_frame_bits = imag(s_sync_frame_bits);
        
        % 检查同步字匹配
        if isequal(i_sync_frame_bits, ref_bits_I) && isequal(q_sync_frame_bits, ref_bits_Q)
            disp('序列匹配');
            disp(['编号 ', num2str(m)]);
            
            % SymbolToIdeaSymbol内联实现
            input_frame_symbols = s_frame;
            %% 初始化理想符号数组
            s_frame_bits = zeros(1,length(input_frame_symbols)) + 1j*zeros(1,length(input_frame_symbols));
            for idx2=1:length(input_frame_symbols)
                symbol_I = real(input_frame_symbols(idx2));
                symbol_Q = imag(input_frame_symbols(idx2));
                
                if symbol_I > 0 && symbol_Q > 0
                    s_frame_bits(idx2) = 0 + 0j;
                elseif symbol_I < 0 && symbol_Q > 0
                    s_frame_bits(idx2) = 1 + 0j;
                elseif symbol_I < 0 && symbol_Q < 0
                    s_frame_bits(idx2) = 1 + 1j;
                elseif symbol_I > 0 &&  symbol_Q < 0
                    s_frame_bits(idx2) = 0 + 1j;
                end
            end
            
            sync_frame_bits = [sync_frame_bits; s_frame_bits];
            sync_index_list = [sync_index_list, m];      % 记录匹配位置
            break;
        end
    end
end

%% 绘图：帧同步时刻图
figure;
stem(sync_index_list, ones(size(sync_index_list)), 'filled');
xlabel('符号位置');
ylabel('同步触发');
title('帧同步检测位置');
grid on;

%% 关键实现细节
% 1. 相位穷举：通过 s_frame = s_frame * (1i) 实现90度旋转，穷举4种相位状态
% 2. 同步字匹配：使用isequal函数直接比较解调后的比特流与参考同步字
% 3. 帧提取：一旦找到匹配位置，提取完整帧数据
% 4. 位置记录：sync_index_list记录所有成功同步的位置，用于后续分析

%% 5.5.3 解扰模块原理解析
% 功能：根据CCSDS标准，使用1+X^14+X^15多项式，对已同步的帧数据进行解扰，
% 恢复出经LDPC编码后的原始数据
% 原理：在发射端，数据在LDPC编码后、加入同步字之前，经过了加扰处理。
% 加扰的目的是打破数据中可能存在的长串"0"或"1"，保证信号频谱的均匀性。
% 接收端通过与发射端同步的伪随机序列进行异或运算，恢复原始数据。

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

%% 代码实现详解
% 在 lib/FrameScramblingModule.m 和 lib/ScramblingModule.m 中，实现了完整的解扰功能。

%% 解扰模块实现代码
% lib/FrameScramblingModule.m
% 设置输入数据（使用帧同步后的数据）
s_symbols = sync_frame_bits;

%% 获取x的形状
[rows,columns] = size(s_symbols);
x = zeros(rows,columns-32);

%% 定义保留矩阵
I_array = zeros(rows,columns-32);
Q_array = zeros(rows,columns-32);

%% 对x进行裁剪，过滤同步字
for m=1:rows
   x(m,:)=s_symbols(m,33:end);
end

%% 定义I路和Q路的解扰器相位
InPhase_I = ones(1,15);
InPhase_Q = [ones(1,8),zeros(1,7)];

%% 获取I路和Q路
I_bits = real(x);
Q_bits = imag(x);

for m=1:rows
   I_row_bits = I_bits(m,:);
   Q_row_bits = Q_bits(m,:);
   
   % 尝试解扰，考虑IQ未反向
   % I路解扰（内联ScramblingModule实现）
   data = I_row_bits;
   InPhase = InPhase_I;
   N = length(data);
   I_deScrambling = zeros(1,N);
   for idx_i=1:N
       I_deScrambling(idx_i) = bitxor(InPhase(15),data(idx_i));
       scrambled_feedback = bitxor(InPhase(15),InPhase(14));
       
       % 更新模拟移位寄存器
       for n=0:13
          InPhase(15-n) = InPhase(14-n);
       end
       
       InPhase(1) = scrambled_feedback;
   end
   
   % Q路解扰（内联ScramblingModule实现）
   data = Q_row_bits;
   InPhase = InPhase_Q;
   N = length(data);
   Q_deScrambling = zeros(1,N);
   for idx_q=1:N
       Q_deScrambling(idx_q) = bitxor(InPhase(15),data(idx_q));
       scrambled_feedback = bitxor(InPhase(15),InPhase(14));
       
       % 更新模拟移位寄存器
       for n=0:13
          InPhase(15-n) = InPhase(14-n);
       end
       
       InPhase(1) = scrambled_feedback;
   end
   
   % 检查是否合法
   if I_deScrambling(8159) == 0 && I_deScrambling(8160) == 0 && Q_deScrambling(8159) == 0 && Q_deScrambling(8160) == 0
       disp("序列合法");
       I_array(m,:) = I_deScrambling;
       Q_array(m,:) = Q_deScrambling;
   else
       % 假设未解扰成功
       % IQ两路交换，然后解扰
       % I路用Q路初相解扰（内联ScramblingModule实现）
       data = I_row_bits;
       InPhase = InPhase_Q;
       N = length(data);
       I_deScrambling_swap = zeros(1,N);
       for idx_i2=1:N
           I_deScrambling_swap(idx_i2) = bitxor(InPhase(15),data(idx_i2));
           scrambled_feedback = bitxor(InPhase(15),InPhase(14));
           
           % 更新模拟移位寄存器
           for n=0:13
              InPhase(15-n) = InPhase(14-n);
           end
           
           InPhase(1) = scrambled_feedback;
       end
       
       % Q路用I路初相解扰（内联ScramblingModule实现）
       data = Q_row_bits;
       InPhase = InPhase_I;
       N = length(data);
       Q_deScrambling_swap = zeros(1,N);
       for idx_q2=1:N
           Q_deScrambling_swap(idx_q2) = bitxor(InPhase(15),data(idx_q2));
           scrambled_feedback = bitxor(InPhase(15),InPhase(14));
           
           % 更新模拟移位寄存器
           for n=0:13
              InPhase(15-n) = InPhase(14-n);
           end
           
           InPhase(1) = scrambled_feedback;
       end
       
       % 检查是否合法
       if I_deScrambling_swap(8159) == 0 && I_deScrambling_swap(8160) == 0 && Q_deScrambling_swap(8159) == 0 && Q_deScrambling_swap(8160) == 0
           disp("合法，但翻转");
           I_array(m,:) = Q_deScrambling_swap;
           Q_array(m,:) = I_deScrambling_swap;
       else
           % 维持原样输出
           I_array(m,:) = I_deScrambling;
           Q_array(m,:) = Q_deScrambling;
           
           disp("误码率过高");
       end
   end
end

%% ScramblingModule实现代码
% lib/ScramblingModule.m
%% 定义加扰解扰逻辑
N = length(data);
scrambled_data = zeros(1,N);
for m=1:N
    scrambled_data(m) = bitxor(InPhase(15),data(m));
    scrambled_feedback = bitxor(InPhase(15),InPhase(14));
    
    % 更新模拟移位寄存器
    for n=0:13
       InPhase(15-n) = InPhase(14-n);
    end
    
    InPhase(1) = scrambled_feedback;
end

%% 关键实现细节
% 1. 同步字过滤：x(m,:)=s_symbols(m,33:end) 去除前32位同步字
% 2. 初相设置：I路使用ones(1,15)，Q路使用[ones(1,8),zeros(1,7)]
% 3. 智能验证：通过检查帧尾两位是否为00来验证解扰正确性
% 4. IQ路交换处理：自动检测并纠正可能的IQ路交换问题
% 5. LFSR实现：使用1+X^14+X^15多项式生成PRBS序列

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
%     bitStream = bitStream(:)'';

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
%         currentFrame = bytes(startIdx:endIdx)''; % 提取并转为行向量
        
%         % 调用解析器
%         AOSFrameHeaderDecoder(currentFrame);
%     end
% else
%     disp('No complete frames found in Ibytes.txt to verify.');
% end
% ```

% 3. 运行与分析：
%    *   重新运行主脚本。
%    *   在MATLAB实时编辑器中，您应该能看到类似下面的输出：

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
