%% 初始化参数
filename = 'XESA_Data_1200MHz_B50M_20250308_01.fc32';  % 文件名
N = 1e6;                    % 读取前 N 个采样点
fs = 50e6;                    % 原始采样率
Ts = 1/fs;                    % 原始采样时间间隔
T = 10;                     %   起始读取时间
t = (0:N-1)' * Ts;          % Simulink时间轴
Rs = 37.5e6;                % 符号速率
fss = 75e6;                % 上采样频率
R = 1/3;                    % 滚降系数
freqStart = 50e6;
freqEnd = 55e6;

%% 读取.sc16数据
start_sample = round(T * fs);  % 复数点起始位置
% 打开文件
fid = fopen(filename, 'rb');
% 每个复数点 = 实部 + 虚部 = 2 float32 = 8 字节
offset = start_sample * 2 * 4;  % 字节偏移量
% 跳过 offset 字节
seekres = fseek(fid, offset, 'bof');
% 读取 N 个复数点（= N×2 个 int）
raw = fread(fid, [2, N], 'single=>double');  % 返回 2×N 的矩阵
fclose(fid);
% 构造复数数组
data = complex(raw(1, :), raw(2, :)).';
ts = timeseries(data, t);