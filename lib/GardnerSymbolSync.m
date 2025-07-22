function y_IQ_Array = GardnerSymbolSync(s_qpsk,sps,B_loop,zeta)
%% 参数配置
Wn = 2 * pi * B_loop / sps;  % 环路自然频率

% 环路滤波器(PI)系数
c1 = (4 * zeta * Wn) / (1 + 2 * zeta * Wn + Wn^2);
c2 = (4 * Wn^2)      / (1 + 2 * zeta * Wn + Wn^2);

%% 初始化状态
ncoPhase = 0;                    % NCO相位累加器
wFilterLast = 1 / sps;           % 初始定时步进 (每个输入样本代表 1/sps 个符号)

% 算法状态变量
isStrobeSample = false;          % 状态标志: false->中点采样, true->判决点采样
timeErrLast = 0;                 % 上一次的定时误差
wFilter = wFilterLast;           % 环路滤波器输出

% 数据存储
y_last_I = 0; y_last_Q = 0;      % 上一个判决点采样值
mid_I = 0; mid_Q = 0;             % 中点采样值
y_I_Array = []; y_Q_Array = [];  % 输出数组

%% Gardner 同步主循环
for m = 6 : length(s_qpsk)-3
    % NCO相位累加 (每个输入样本前进 wFilterLast 的相位)
    % 当 ncoPhase 越过 0.5 时，产生一个中点或判决点采样
    ncoPhase_old = ncoPhase;
    ncoPhase = ncoPhase + wFilterLast;

    % 使用 while 循环处理
    while ncoPhase >= 0.5
        % --- 关键修复 1: 正确计算插值时刻 (mu) ---
        % 计算过冲点在当前采样区间的归一化位置
        mu = (0.5 - ncoPhase_old) / wFilterLast;
        base_idx = m - 1;

        % --- 使用Farrow 立方插值器 ---
        y_I_sample = FarrowCubicInterpolator(base_idx, real(s_qpsk), mu);
        y_Q_sample = FarrowCubicInterpolator(base_idx, imag(s_qpsk), mu);
        
        %disp(y_I_sample);

        if isStrobeSample
            % === 当前是判决点 (Strobe Point) ===

            % --- Gardner 误差计算 ---
            % 误差 = 中点采样 * (当前判决点 - 上一个判决点)
            timeErr = mid_I * (y_I_sample - y_last_I) + mid_Q * (y_Q_sample - y_last_Q);

            % 环路滤波器
            wFilter = wFilterLast + c1 * (timeErr - timeErrLast) + c2 * timeErr;

            % 存储状态用于下次计算
            timeErrLast = timeErr;
            y_last_I = y_I_sample;
            y_last_Q = y_Q_sample;

            % 将判决点采样存入结果数组
            y_I_Array(end+1) = y_I_sample;
            y_Q_Array(end+1) = y_Q_sample;

        else
            % === 当前是中点 (Midpoint) ===
            % 存储中点采样值，用于下一次的误差计算
            mid_I = y_I_sample;
            mid_Q = y_Q_sample;
        end

        % 更新环路滤波器输出 (每个判决点更新一次)
        if isStrobeSample
            wFilterLast = wFilter;
        end

        % 切换状态: 判决点 -> 中点, 中点 -> 判决点
        isStrobeSample = ~isStrobeSample;
        
        % NCO相位减去已处理的0.5个符号周期，并为下一次可能的触发更新“旧”相位
        ncoPhase_old = 0.5; 
        ncoPhase = ncoPhase - 0.5;
    end
end

%% 输出复数结果
y_IQ_Array = y_I_Array + 1j * y_Q_Array;

end

function y = FarrowCubicInterpolator(index, x, u)
    % Farrow 结构三阶(Cubic)插值器
    % 使用 index-1, index, index+1, index+2 四个点估计 x(index+u)
    if index < 2 || index > length(x) - 2
        y = 0; return;
    end
    x_m1 = x(index - 1);
    x_0  = x(index);
    x_p1 = x(index + 1);
    x_p2 = x(index + 2);
    
    % Farrow 结构系数
    c0 = x_0;
    c1 = 0.5 * (x_p1 - x_m1);
    c2 = x_m1 - 2.5*x_0 + 2*x_p1 - 0.5*x_p2;
    c3 = -0.5*x_m1 + 1.5*x_0 - 1.5*x_p1 + 0.5*x_p2;
    
    y = ((c3 * u + c2) * u + c1) * u + c0;
end