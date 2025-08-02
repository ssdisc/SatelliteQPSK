% 脚本：检验数据文件中的采样点总数
clc;
clear;

% --- 配置 ---
% 数据文件名 (与主脚本 SatelliteQPSKReceiverTest.m 保持一致)
filename = '../../data/sample_0611_500MHz_middle.bin';
% 每个采样点的字节数 (fc32 = float32 I + float32 Q = 4 + 4 = 8 bytes)
bytes_per_sample = 8;
% 原始信号采样率 (Hz)，参考 SatelliteQPSKReceiverTest.m
sample_rate = 150e6;
% --- 结束配置 ---

% 检查文件是否存在
if ~exist(filename, 'file')
    error('错误: 数据文件 "%s" 不存在。请确保文件位于当前目录或MATLAB路径中。', filename);
end

% 获取文件信息
file_info = dir(filename);
file_size_bytes = file_info.bytes;

% 计算采样点数
num_samples = file_size_bytes / bytes_per_sample;

% 计算数据时长
duration_seconds = num_samples / sample_rate;

% 显示结果
fprintf('--- 数据文件采样点检验 ---\n');
fprintf('文件名: %s\n', filename);
fprintf('文件大小: %d 字节\n', file_size_bytes);
fprintf('每个采样点字节数: %d\n', bytes_per_sample);
fprintf('信号采样率: %.2f MHz\n', sample_rate / 1e6);
fprintf('------------------------------------\n');
fprintf('计算出的总采样点数: %d\n', num_samples);
fprintf('计算出的总时长: %.4f 秒\n', duration_seconds);

% 检查文件大小是否是采样点字节数的整数倍
if mod(file_size_bytes, bytes_per_sample) ~= 0
    fprintf('\n警告: 文件总字节数不是每个采样点字节数的整数倍。\n');
    fprintf('文件可能已损坏或格式不正确。\n');
end