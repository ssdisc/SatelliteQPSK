function [synced_signal, f_offset_est, phase_est] = qpsk_carrier_sync(rx_signal, fs, fc, show_plots)
% QPSK载波同步函数
% 输入:
%   rx_signal  : 接收信号（复数基带或中频）
%   fs         : 采样率 (Hz)
%   fc         : 信号中心频率 (Hz)，若为基带输入则设为0
%   show_plots : 是否显示调试图 (true/false)
% 输出:
%   synced_signal : 同步后的基带信号
%   f_offset_est  : 估计的频偏 (Hz)
%   phase_est     : 跟踪的相位轨迹 (rad)

% 参数设置
if nargin < 4
    show_plots = false;
end

%% 1. 下变频至基带（若fc非零）
if fc > 0
    N = length(rx_signal);
    t = (0:N-1)/fs;
    rx_baseband = rx_signal .* exp(-1j*2*pi*fc*t); % 数字下变频
else
    rx_baseband = rx_signal;
end

%% 2. 频偏估计（粗+细）
% 2.1 基于4次方谱线的粗频偏估计
N_fft = 1024; % FFT点数
spectrum = abs(fftshift(fft(rx_baseband(1:N_fft).^4, N_fft)));
freq_axis = (-N_fft/2:N_fft/2-1) * fs / N_fft;
[~, idx] = max(spectrum);
f_offset_coarse = freq_axis(idx) / 4; % QPSK需除以4

% 2.2 基于相位差的细频偏估计
phase_diff = angle(rx_baseband(2:end) .* conj(rx_baseband(1:end-1)));
f_offset_fine = mean(phase_diff) * fs / (2*pi);
f_offset_est = f_offset_coarse + f_offset_fine;

% 频偏补偿
t_comp = (0:length(rx_baseband)-1)/fs;
rx_compensated = rx_baseband .* exp(-1j*2*pi*f_offset_est*t_comp);

%% 3. Costas环相位跟踪
% 环路滤波器参数 (比例积分)
alpha = 0.02; % 带宽参数
beta = 0.002;

phase_est = zeros(size(rx_compensated));
error = zeros(size(rx_compensated));

for n = 2:length(rx_compensated)
    % QPSK相位误差检测
    error(n) = sign(real(rx_compensated(n))) * imag(rx_compensated(n)) ...
              - sign(imag(rx_compensated(n))) * real(rx_compensated(n));
    
    % 环路滤波更新相位
    phase_est(n) = phase_est(n-1) + alpha * error(n) + beta * sum(error(1:n));
    
    % 相位旋转补偿
    rx_compensated(n) = rx_compensated(n) * exp(-1j*phase_est(n));
end
synced_signal = rx_compensated;

%% 4. 调试绘图
if show_plots
    figure(1);
    subplot(2,1,1); 
    plot(freq_axis, 10*log10(spectrum)); 
    title('4次方谱线频偏估计'); xlabel('频率 (Hz)');
    
    subplot(2,1,2);
    plot(phase_est); 
    title('Costas环相位跟踪'); xlabel('样本');

    scatterplot(rx_baseband(1:1000)); 
    title('同步前星座图');
    
    scatterplot(synced_signal(end-1000:end));
    title('同步后星座图');

end
end