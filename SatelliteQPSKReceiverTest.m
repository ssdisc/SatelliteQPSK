clc;clear;

%% 定义参数对象
config.inputDataFilename = "sample_06111";%611采集数据，约60G
config.sourceSampleRate = 500e6;% 原始信号采样率
config.resampleMolecule = 3;% 重采样分子
config.resampleDenominator = 10;% 重采样分母
config.fs = 150e6;% 重采样后的采样率
config.fb = 150e6;% 数传速率150Mbps
config.startBits = 200e6;% 文件读取数据的起始点
config.bitsLength = 2e5;% 单次处理点
config.IBytesFilename = "Ibytes.txt";% I路比特输出文件
config.QBytesFilename = "Qbytes.txt";% Q路比特输出文件
config.IQBytesFilename = "IQbytes.txt";% IQ路交织输出文件

%% 调用函数
[I_bytes,Q_bytes] = SatelliteQPSKReceiver(config);