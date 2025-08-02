function y = AGC_Normalize(x, target_power, agc_step)
% 初始化增益
gain = 1.0;
    
% 预分配输出
y = zeros(size(x));
    
% 实时逐点更新AGC（模拟时序处理）
for n = 1:length(x)
    % 当前输入样本
    sample = x(n);
        
    % 当前功率
    current_power = abs(sample * gain)^2;
        
    % 误差
    error = target_power - current_power;
        
    % 更新增益
    gain = gain + agc_step * error * gain;
       
    % 防止增益爆炸
    if gain < 1e-6
       gain = 1e-6;
    elseif gain > 1e6
       gain = 1e6;
    end 
    % 应用增益
    y(n) = gain * sample;
end
end
