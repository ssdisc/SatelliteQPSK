%% 初始化参数
filename = 'data/small_sample_256k.bin';  % 文件名
N = 256e3;                      % 读取前 N 个采样点 (设置为Inf可读取全部)
fs = 500e6;                     % 原始采样率
Ts = 1/fs;                      % 原始采样时间间隔
T = 0;                          % 起始读取时间
Rs = 75e6;                      % 符号速率
fss = 600e6;                    % 上采样频率
R = 1/3;                        % 滚降系数
freqStart = 50e6;
freqEnd = 55e6;

%% 读取.sc16数据
% 打开文件
fid = fopen(filename, 'rb');
% 根据N值决定读取方式
if isinf(N)
    % 读取所有复数点
    raw = fread(fid, [2, Inf], 'int16=>double');
else
    % 读取前N个复数点
    start_sample = round(T * fs);  % 复数点起始位置
    % 每个复数点 = 实部 + 虚部 = 2 int16 = 4 字节
    offset = start_sample * 2 * 2;  % 字节偏移量
    % 跳过 offset 字节
    fseek(fid, offset, 'bof');
    % 读取 N 个复数点（= N×2 个 int）
    raw = fread(fid, [2, N], 'int16=>double');
end
fclose(fid);
% 获取实际读取的采样点数
N = size(raw, 2);
% 构造时间轴
t = (0:N-1)' * Ts;
% 构造复数数组
data = complex(raw(1, :), raw(2, :)).';
ts = timeseries(data, t);