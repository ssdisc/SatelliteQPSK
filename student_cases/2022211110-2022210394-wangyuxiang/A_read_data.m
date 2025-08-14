%% 初始化参数
filename = 'data/small_sample_256k.bin';  % 文件名
N = 256e3;                    % 读取前 N 个采样点
fs = 500e6;                   % 原始采样率
Ts = 1/fs;                    % 原始采样时间间隔
T = 0;                     %   起始读取时间（小数据文件从头开始）
t = (0:N-1)' * Ts;          % Simulink时间轴
Rs = 75e6;                 % 符号速率
fss = 150e6;               % 上采样频率
R = 1/3;                    % 滚降系数
freqStart = 50e6;
freqEnd = 55e6;

%% 读取.sc16数据
% 小数据文件不需要偏移量
start_sample = 0;  % 复数点起始位置
% 打开文件
fid = fopen(filename, 'rb');
% 每个复数点 = 实部 + 虚部 = 2 int16 = 4 字节（注意：小数据文件是int16格式）
% offset = start_sample * 2 * 4;  % 字节偏移量
% % 跳过 offset 字节
% seekres = fseek(fid, offset, 'bof');
% 读取 N 个复数点（= N×2 个 int16）
raw = fread(fid, [2, N], 'int16=>double');  % 返回 2×N 的矩阵
fclose(fid);
% 构造复数数组
data = complex(raw(1, :), raw(2, :)).';
ts = timeseries(data, t);