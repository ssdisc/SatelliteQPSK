% 添加库路径
addpath('student_cases/14+2022210532+chengzirui/lib');

clc;clear;


%% 定义参数对象
config.inputDataFilename = "data/sample_0611_500MHz_middle.bin";%611采集数据，约60G
config.sourceSampleRate = 500e6;% 原始信号采样率
config.resampleMolecule = 3;% 重采样分子
config.resampleDenominator = 10;% 重采样分母
config.fs = 150e6;% 重采样后的采样率
config.fb = 150e6;% 数传速率150Mbps
config.startBits = 500e6;% 文件读取数据的起始点
config.bitsLength = 256e3;% 单次处理点
config.rollOff = 0.33;% 滚降系数


output_dir = 'student_cases/14+2022210532+chengzirui/out';

config.IBytesFilename = fullfile(output_dir, 'Ibytes.txt');% I路比特输出文件
config.QBytesFilename = fullfile(output_dir, 'Qbytes.txt');% Q路比特输出文件
config.IQBytesFilename = fullfile(output_dir, 'IQbytes.txt');% IQ路交织输出文件
config.keepRedundantData = true; % 新增：是否保留完整帧（同步字+冗余）
config.FullFrameIBytesFilename = fullfile(output_dir, 'Ibytes_full.txt'); % 新增：完整帧I路输出
config.FullFrameQBytesFilename = fullfile(output_dir, 'Qbytes_full.txt'); % 新增：完整帧Q路输出
config.FullFrameIQBytesFilename = fullfile(output_dir, 'IQbytes_full.txt'); % 新增：完整帧IQ交织输出
config.UnscrambledHexFilename = fullfile(output_dir, 'unscrambled_hex.txt'); % 新增：未解扰的十六进制数据输出

%% 调用函数

[I_bytes,Q_bytes] = SatelliteQPSKReceiver(config);