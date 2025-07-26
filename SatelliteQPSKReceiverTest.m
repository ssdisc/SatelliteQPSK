% 添加库路径
addpath('lib');

clc;clear;

%% 定义参数对象
config.inputDataFilename = "XESA_Data_1200MHz_B50M_20250308_01.fc32";% 课题要求所用数据
config.sourceSampleRate = 50e6;% 原始信号采样率
config.resampleMolecule = 3;% 重采样分子
config.resampleDenominator = 2;% 重采样分母
config.fs = 75e6;% 重采样后的采样率
config.fb = 75e6;% 数传速率75Mbps
config.rollOff = 1/3;% 滚降系数
config.startBits = 200e6;% 文件读取数据的起始点
config.bitsLength = 64e3;% 单次处理点
config.IBytesFilename = "Ibytes.txt";% I路比特输出文件
config.QBytesFilename = "Qbytes.txt";% Q路比特输出文件
config.IQBytesFilename = "IQbytes.txt";% IQ路交织输出文件

%% 调用函数
[I_bytes,Q_bytes] = SatelliteQPSKReceiver(config);