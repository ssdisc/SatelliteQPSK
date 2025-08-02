function y = RRCFilterFixedLen(fb, fs, x, alpha, mode)

% 参数
span = 8; % 滤波器长度（单位符号数）
sps = floor(fs / fb); % 每符号采样数
    
% 生成滤波器
if strcmpi(mode, 'rrc')
    % Root Raised Cosine
    h = rcosdesign(alpha, span, sps, 'sqrt');
elseif strcmpi(mode, 'rc')
    % Raised Cosine
    h = rcosdesign(alpha, span, sps, 'normal');
else
    error('Unsupported mode. Use ''rrc'' or ''rc''.');
end
        
% 卷积，保持输入输出长度一致
y = conv(x, h, 'same');
end
