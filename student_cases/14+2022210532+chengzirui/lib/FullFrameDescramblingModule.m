function [I_array_full, Q_array_full] = FullFrameDescramblingModule(s_symbols)
%% 获取x的形状
[rows, columns] = size(s_symbols);
if columns ~= 8192
    error('Input must be 8192 bits (1024 bytes) wide frames.');
end

%% 分离同步字和数据
sync_bits = s_symbols(:, 1:32);
data_bits_scrambled = s_symbols(:, 33:end);

%% 定义I路和Q路的解扰器相位
InPhase_I = ones(1, 15);
InPhase_Q = [ones(1, 8), zeros(1, 7)];

%% 获取I路和Q路的数据部分
I_bits = real(data_bits_scrambled);
Q_bits = imag(data_bits_scrambled);

%% 定义保留解扰后数据的矩阵
I_data_array = zeros(rows, columns - 32);
Q_data_array = zeros(rows, columns - 32);

%% 循环处理每一帧
for m = 1:rows
   I_row_bits = I_bits(m, :);
   Q_row_bits = Q_bits(m, :);
   
   % 尝试解扰，考虑IQ未反向
   I_deScrambling_data = ScramblingModule(I_row_bits, InPhase_I);
   Q_deScrambling_data = ScramblingModule(Q_row_bits, InPhase_Q);
   
   % 检查是否合法 (末尾两位为00)
   % 8160 = 1020 bytes * 8 bits
   if I_deScrambling_data(8159) == 0 && I_deScrambling_data(8160) == 0 && Q_deScrambling_data(8159) == 0 && Q_deScrambling_data(8160) == 0
       disp("序列合法 (Full Frame)");
       I_data_array(m, :) = I_deScrambling_data;
       Q_data_array(m, :) = Q_deScrambling_data;
   else
       % 假设未解扰成功, IQ两路交换，然后解扰
       I_deScrambling_data = ScramblingModule(I_row_bits, InPhase_Q);
       Q_deScrambling_data = ScramblingModule(Q_row_bits, InPhase_I);
       
       % 再次检查是否合法
       if I_deScrambling_data(8159) == 0 && I_deScrambling_data(8160) == 0 && Q_deScrambling_data(8159) == 0 && Q_deScrambling_data(8160) == 0
           disp("合法，但翻转 (Full Frame)");
           % 注意：这里交换的是解扰后的数据
           I_data_array(m, :) = Q_deScrambling_data;
           Q_data_array(m, :) = I_deScrambling_data;
       else
           % 维持原样输出并警告
           I_data_array(m, :) = I_deScrambling_data; % Outputting the first attempt
           Q_data_array(m, :) = Q_deScrambling_data;
           disp("误码率过高 (Full Frame)");
       end
   end
end

%% 重组完整帧
I_array_full = [real(sync_bits), I_data_array];
Q_array_full = [imag(sync_bits), Q_data_array];

end