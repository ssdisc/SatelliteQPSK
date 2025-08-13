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