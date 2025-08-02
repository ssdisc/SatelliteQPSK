% 设置文件路径和要读取的复数点个数
filename = "../../data/sample_0611_500MHz_middle.bin";
N = 50000; 

% 打开文件
fid = fopen(filename, 'rb');

% 每个复数点由两个 float32 组成：实部 + 虚部
% 因此读取前 2*N 个 float32 即可
raw_data = fread(fid, 2*N, 'float32').';

% 关闭文件
fclose(fid);

% 将实部和虚部组合为复数
complex_data = complex(raw_data(1:2:end), raw_data(2:2:end));
fs = 50e6;
rs = 37.5e6;

% 变频信号生成
%carrier = exp(1j*2*pi*100e6*(0:1:N-1)/fs);

% 变频
%basebandDataRaw = complex_data.*real(carrier);
%i_channel = real(basebandDataRaw);
%q_channel = -imag(basebandDataRaw);

i_channel = real(complex_data);
q_channel = -imag(complex_data);

% 升采样
r = 3;
complex_data = upsample(complex_data, r);
i_channel = upsample(i_channel, r);
q_channel = upsample(q_channel, r);
% 
% 滤波
complex_data = filter(lowpass(), complex_data);
i_channel = filter(lowpass(), i_channel);
q_channel = filter(lowpass(), q_channel);

% 降采样
%complex_data = downsample(complex_data,4);
%[rounded_phase,rounded_complex_data] = round_phase(complex_data);


% 载波同步
% 载波同步滤波器
ts = 1/fs;                    % 原始采样时间间隔
d = 0.707;  % 阻尼系数
Kp = 1;      % phase detector S-curve is linear
Bn = 0.02*rs;   % noise bandwidth in Hz
Ko = 1;      % gain of NCO (here just a direct conversion)
% calculate the loop filter coefficients
K1 = (4*d*Bn*ts)/(Ko*Kp*(d+1/(4*d)));
K2 = (4*(Bn*ts)^2)/(Ko*Kp*(d+1/4*d)^2);

% ISI抑制
%rrcFilter = rcosdesign(0.5, 6, 8);
%i_channel = filter(rrcFilter,1,i_channel);

% 时钟提取
%clk = abs(i_channel.*q_channel).^2;
%FFTPlot(clk,fs,5)
%[symbols,err] = gardner(complex_data,8);

% 判决
%symbols = qpsk_phase_detector(phase);

% 初始化比特序列
% bitsI = zeros(1, length(symbols)); 
% bitsQ = zeros(1, length(symbols));
% for i = 1:length(symbols)
%     switch symbols(i)
%         case 0
%             bitsI(i) = 0;
%             bitsQ(i) = 0;
%         case 1
%             bitsI(i) = 0;
%             bitsQ(i) = 1;
%         case 2
%             bitsI(i) = 1;
%             bitsQ(i) = 0;
%         case 3
%             bitsI(i) = 1;
%             bitsQ(i) = 1;
%         otherwise
%             error('Invalid QPSK symbol');
%     end
% end
% % 按4位分组并转换为十六进制
% nibbles = reshape(bitsI, 4, [])'; % 每行一组4位
% hex = dec2hex(bin2dec(num2str(nibbles)))';
% 
% % 显示结果
% disp(['Hexadecimal: ', hex(:)']);
% 
% % 绘图
% figure(1);
% clf;
% plot(real(complex_data));
% hold on;
% plot(imag(complex_data));
% legend('Real Part', 'Imaginary Part');
% xlabel('Sample Index');
% ylabel('Amplitude');
% title(sprintf('前 %d 个复数点波形图', N));
% grid on;
% 
% figure(2);
% clf;
% plot(i_channel);
% hold on;
% plot(q_channel);
% legend('I', 'Q');
% xlabel('Sample Index');
% ylabel('Amplitude');
% title(sprintf('前 %d 个点两路波形图', N));
% grid on;
% 
% FFTPlot(i_channel, r*fs,4);
% FFTPlot(q_channel, r*fs,5);

