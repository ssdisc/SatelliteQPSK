function [complex_data] = fc32Reader(filename,N)
% 打开文件
fid = fopen(filename, 'rb');

% 每个复数点由两个 float32 组成：实部 + 虚部
% 因此读取前 2*N 个 float32 即可
raw_data = fread(fid, 2*N, 'float32').';

% 关闭文件
fclose(fid);

% 将实部和虚部组合为复数
complex_data = complex(raw_data(1:2:end), raw_data(2:2:end));
end

