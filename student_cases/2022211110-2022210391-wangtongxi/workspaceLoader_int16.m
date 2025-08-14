% 设置文件路径和要读取的复数点个数
filename = "data/small_sample_256k.bin";
N = 256e3;  % 读取前 N 个采样点 (设置为Inf可读取全部)
offset = 0;  % 字节偏移量 (默认为0，即从文件开头读取) 

% 打开文件
fid = fopen(filename, 'rb');
if fid == -1
    error('无法打开文件: %s', filename);
end

% 跳过 offset 字节
if offset > 0
    seekRes = fseek(fid, offset, 'bof');
    if seekRes ~= 0
        fclose(fid);
        error('无法定位到指定的偏移量: %d 字节', offset);
    end
end

oriFs = 500e6;
rs = 75e6;
r = 3;
fs = oriFs*r;

% 根据N值决定读取方式
if isinf(N)
    % 读取所有剩余复数点
    raw_data = fread(fid, Inf, 'int16=>double').';
else
    % 读取前N个复数点
    % 每个复数点由两个 int16 组成：实部 + 虚部
    % 因此读取前 2*N 个 int16 即可
    raw_data = fread(fid, 2*N, 'int16=>double').';
end

% 检查是否成功读取了数据
if isempty(raw_data)
    fclose(fid);
    error('未能从文件中读取数据');
end

% 关闭文件
fclose(fid);

% 将实部和虚部组合为复数
complex_data = complex(raw_data(1:2:end), raw_data(2:2:end));

% 上采样
complex_data_inp = upsample(complex_data,r);
lowpassFilter=fir1(100,0.1,"low");
complex_data_inp = filter(lowpassFilter,1,complex_data_inp);
FFTPlot(complex_data_inp,fs,1);

% 时间序列产生
ts_complex_data = array2timetable(complex_data_inp',"SampleRate",fs);

quadC = complex_data_inp.^4;
FFTPlot(quadC,oriFs,2)