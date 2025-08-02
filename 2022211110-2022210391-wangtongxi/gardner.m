function [sym_out, indexes] = gardner(rx, sps)
% Gardner符号同步算法
% 输入:
% rx - 接收复信号 (column vector)
% sps - 每符号采样点数 (建议 >= 2)
% 输出:
% sym_out - 已同步抽取后的符号
% timing_error - 每次更新的符号定时误差记录

% 初始化
mu = 0; % 初始相位（在 0 到 sps-1 之间）
tau = 0.01; % 步长（调整范围 0.01 ~ 0.1）
n = 1 + sps; % 当前样本指针
i = 1; % 输出符号索引
timing_error = [];
indexes = [];
sym_out = [];

while n + sps < length(rx)-1
% 抽取当前符号和前一半符号
idx1 = floor(n + mu);
idx2 = floor(n + mu - sps/2);
idx0 = floor(n + mu - sps);

r1 = rx(idx1 + 1);
r0 = rx(idx0 + 1);
r_half = rx(idx2 + 1);

% 计算Gardner误差
err = real((r1 - r0) * conj(r_half));
timing_error(i) = err;

% 更新 mu 相位
mu = mu + sps + tau * err;

% 如果 mu 超过一符号，推进n
while mu >= sps
    mu = mu - sps;
    n = n + 1;
end

% 保存同步点的符号
sym_out(i) = r_half;
indexes = [indexes,r_half];
i = i + 1;
end

sym_out = sym_out.';

end