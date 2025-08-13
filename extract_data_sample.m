%% 提取一小段数据用于分析
% 参考程梓睿的实现，提取相同大小的数据用于分析
clear; clc;

% 添加库路径
addpath('student_cases/14+2022210532+chengzirui/lib');

% 设置参数
data_file = 'data/sample_0611_500MHz_middle.bin';
output_file = 'data/small_sample_256k.bin';
pointStart = 1;     % 从文件开始处读取
Nread = 256e3;      % 读取256,000个点，与程梓睿的实现相同

% 读取数据
fprintf('正在读取数据...\n');
data = SignalLoader(data_file, pointStart, Nread);

% 保存小段数据到新文件
fprintf('正在保存小段数据...\n');
fid = fopen(output_file, 'wb');
for i = 1:length(data)
    % 将复数数据写入文件，实部和虚部分别作为int16
    fwrite(fid, [real(data(i)), imag(data(i))], 'int16');
end
fclose(fid);

fprintf('已提取%d个数据点并保存到%s\n', Nread, output_file);

% 显示一些基本统计信息
fprintf('\n数据统计信息:\n');
fprintf('数据点数: %d\n', length(data));
fprintf('实部范围: %.2f 到 %.2f\n', min(real(data)), max(real(data)));
fprintf('虚部范围: %.2f 到 %.2f\n', min(imag(data)), max(imag(data)));
fprintf('幅度范围: %.2f 到 %.2f\n', min(abs(data)), max(abs(data)));

% 绘制数据的实部和虚部（前10000个点）
figure;
subplot(2,1,1);
plot(real(data(1:10000)));  
title('实部 (前10000个点)');
xlabel('样本点');
ylabel('幅度');

subplot(2,1,2);
plot(imag(data(1:10000)));  
title('虚部 (前10000个点)');
xlabel('样本点');
ylabel('幅度');

% 绘制星座图（前50000个点）
figure;
plot(real(data(1:50000)), imag(data(1:50000)), 'o', 'MarkerSize', 1);
title('星座图 (前50000个点)');
xlabel('实部');
ylabel('虚部');
grid on;