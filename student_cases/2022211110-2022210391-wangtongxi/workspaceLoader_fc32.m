% 设置文件路径和要读取的复数点个数
filename = "data/XESA_Data_1200MHz_B50M_20250308_01.fc32";
N = 64e3; 

% 打开文件
fid = fopen(filename, 'rb');

oriFs = 50e6;
rs = 37.5e6;
r = 3/2; % 采样倍数, 可以是分数
fs = oriFs * r;

[P, Q] = rat(r); % 将 r 转换为分数 P/Q

offset = 4000e6;  % 字节偏移量
% 跳过 offset 字节
seekRes=fseek(fid, offset, 'bof');
% 每个复数点由两个 float32 组成：实部 + 虚部
% 因此读取前 2*N 个 float32 即可
raw_data = fread(fid, 2*N, 'float32').';

% 关闭文件
fclose(fid);

% 将实部和虚部组合为复数
complex_data = complex(raw_data(1:2:end), raw_data(2:2:end));

% 使用 resample 进行分数倍重采样
complex_data_inp = resample(complex_data, P, Q);

i_channel = real(complex_data_inp);
q_channel = -imag(complex_data_inp);

% 时间序列产生
ts_complex_data = array2timetable(complex_data_inp',"SampleRate",fs);

quadC = complex_data_inp.^4;
FFTPlot(quadC,oriFs,1)