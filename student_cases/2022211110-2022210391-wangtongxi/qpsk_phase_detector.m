function decoded_symbols = qpsk_phase_detector(angles)
% QPSK相位判决器

% 初始化输出
decoded_symbols = zeros(size(angles));

% QPSK相位判决
for i = 1:length(angles)
    % 将角度调整到[0, 2pi)范围
    adjusted_angle = mod(angles(i), 2*pi);
    
    % 判决到最近的QPSK相位点
    if adjusted_angle >= 0 && adjusted_angle < pi/2
        decoded_symbols(i) = 0b11;
    elseif adjusted_angle >= pi/2 && adjusted_angle < 3*pi/2
        decoded_symbols(i) = 0b01;
    elseif adjusted_angle >= 3*pi/2 && adjusted_angle < pi
        decoded_symbols(i) = 0b00;
    else
        decoded_symbols(i) = 0b10;
    end
end

% 转换为行向量以匹配输入格式
if isrow(angles)
    decoded_symbols = decoded_symbols.';
end
end