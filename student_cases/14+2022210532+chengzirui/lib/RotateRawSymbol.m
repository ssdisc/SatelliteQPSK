%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% RotateRawSymbolModule
function rotatedSymbol = RotateRawSymbol(s_symbol,n)
% s_symbol: 输入的原始QPSK符号序列 (复数向量)
% n: 旋转次数 (0, 1, 2, 3)，对应逆时针旋转 0°, 90°, 180°, 270°

    % 检查n的有效性
    if n < 0 || n > 3 || mod(n,1) ~= 0
        error('旋转次数n必须是0到3之间的整数。');
    end

    % 根据n的值确定旋转因子
    % 逆时针旋转角度 theta = n * 90°
    % 旋转因子 rotation_factor = exp(1i * deg2rad(n * 90));
    % 或者直接使用以下离散值：
    % n=0 (0°):   rotation_factor = 1
    % n=1 (90°):  rotation_factor = 1i
    % n=2 (180°): rotation_factor = -1
    % n=3 (270°): rotation_factor = -1i

    switch n
        case 0
            rotation_factor = 1;
        case 1
            rotation_factor = 1i;
        case 2
            rotation_factor = -1;
        case 3
            rotation_factor = -1i;
        otherwise
            % 此处实际上在前面的错误检查中已经覆盖
            rotation_factor = 1; % 默认为不旋转
    end

    % 对输入的符号序列进行旋转
    rotatedSymbol = s_symbol .* rotation_factor;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 示例用法：
% 假设我们有一个标准的QPSK符号
% standard_qpsk_symbols = [1+1i, -1+1i, -1-1i, 1-1i] / sqrt(2); % 归一化功率

% disp('原始符号:');
% disp(standard_qpsk_symbols);

% % 旋转0次 (0度)
% rotated_0 = RotateRawSymbol(standard_qpsk_symbols, 0);
% disp('旋转0次 (0度):');
% disp(rotated_0);

% % 旋转1次 (90度)
% rotated_90 = RotateRawSymbol(standard_qpsk_symbols, 1);
% disp('旋转1次 (90度):');
% disp(rotated_90);

% % 旋转2次 (180度)
% rotated_180 = RotateRawSymbol(standard_qpsk_symbols, 2);
% disp('旋转2次 (180度):');
% disp(rotated_180);

% % 旋转3次 (270度)
% rotated_270 = RotateRawSymbol(standard_qpsk_symbols, 3);
% disp('旋转3次 (270度):');
% disp(rotated_270);

% % 绘制星座图进行验证
% figure;
% subplot(2,3,1);
% plot(real(standard_qpsk_symbols), imag(standard_qpsk_symbols), 'o');
% title('原始QPSK星座图');
% xlim([-1.5 1.5]); ylim([-1.5 1.5]); grid on; axis square;

% subplot(2,3,2);
% plot(real(rotated_0), imag(rotated_0), 'rx');
% title('旋转 0°');
% xlim([-1.5 1.5]); ylim([-1.5 1.5]); grid on; axis square;

% subplot(2,3,3);
% plot(real(rotated_90), imag(rotated_90), 'rx');
% title('旋转 90°');
% xlim([-1.5 1.5]); ylim([-1.5 1.5]); grid on; axis square;

% subplot(2,3,4);
% plot(real(rotated_180), imag(rotated_180), 'rx');
% title('旋转 180°');
% xlim([-1.5 1.5]); ylim([-1.5 1.5]); grid on; axis square;

% subplot(2,3,5);
% plot(real(rotated_270), imag(rotated_270), 'rx');
% title('旋转 270°');
% xlim([-1.5 1.5]); ylim([-1.5 1.5]); grid on; axis square;