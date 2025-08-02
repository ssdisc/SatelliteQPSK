function bitstream = qpsk_demod(symbols)
% QPSK符号判决函数
% 输入：
%   symbols - 复数形式的QPSK符号序列
% 输出：
%   bitstream - 解调后的比特流（0和1组成的向量）

% 确保输入是列向量
symbols = symbols(:);

% 获取符号的实部和虚部
real_part = real(symbols);
imag_part = imag(symbols);

% 初始化比特流
bitstream = zeros(2 * length(symbols), 1);

% 根据实部和虚部的符号进行判决
for i = 1:length(symbols)
    idx = 2*i - 1;  % 当前符号对应的比特位置
    
    if real_part(i) >= 0 && imag_part(i) >= 0
        bitstream(idx:idx+1) = [1; 1];
    elseif real_part(i) < 0 && imag_part(i) >= 0
        bitstream(idx:idx+1) = [0; 1];
    elseif real_part(i) < 0 && imag_part(i) < 0
        bitstream(idx:idx+1) = [0; 0];
    else
        bitstream(idx:idx+1) = [1; 0];
    end
end
end