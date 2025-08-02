%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FrameScramblingModule

function [I_array,Q_array] = FrameScramblingModule(s_symbols)
%% 获取x的形状
[rows,columns] = size(s_symbols);
x = zeros(rows,columns-32);

%% 定义保留矩阵
I_array = zeros(rows,columns-32);
Q_array = zeros(rows,columns-32);

%% 对x进行裁剪，过滤同步字
for m=1:rows
   x(m,:)=s_symbols(m,33:end); 
end

%% 定义I路和Q路的解扰器相位
InPhase_I = ones(1,15);
InPhase_Q = [ones(1,8),zeros(1,7)];

%% 获取I路和Q路
I_bits = real(x);
Q_bits = imag(x);

for m=1:rows
   I_row_bits = I_bits(m,:);
   Q_row_bits = Q_bits(m,:);
   
   % 尝试解扰，考虑IQ未反向
   I_deScrambling = ScramblingModule(I_row_bits,InPhase_I);
   Q_deScrambling = ScramblingModule(Q_row_bits,InPhase_Q);
   
   % 检查是否合法
   if I_deScrambling(8159) == 0 && I_deScrambling(8160) == 0 && Q_deScrambling(8159) == 0 && Q_deScrambling(8160) == 0
       disp("序列合法");
       I_array(m,:) = I_deScrambling;
       Q_array(m,:) = Q_deScrambling;
   else
       % 假设未解扰成功
       % IQ两路交换，然后解扰
       I_deScrambling = ScramblingModule(I_row_bits,InPhase_Q);
       Q_deScrambling = ScramblingModule(Q_row_bits,InPhase_I);
       
       % 检查是否合法
       if I_deScrambling(8159) == 0 && I_deScrambling(8160) == 0 && Q_deScrambling(8159) == 0 && Q_deScrambling(8160) == 0
           disp("合法，但翻转");
           I_array(m,:) = Q_deScrambling;
           Q_array(m,:) = I_deScrambling;
       else
           % 维持原样输出
           I_array(m,:) = I_deScrambling;
           Q_array(m,:) = Q_deScrambling;
           
           disp("误码率过高");
       end
   end
end

end