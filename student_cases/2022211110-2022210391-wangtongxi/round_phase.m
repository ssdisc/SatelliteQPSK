function [rounded_phase,rounded_z] = round_phase(z)
% 将复数归一化并使其相位四舍五入到最近的0, 0.5pi, pi, 1.5pi
% 支持向量输入
% 输入：
%   z - 输入的复数（可以是标量、向量或矩阵）
% 输出：
%   rounded_z - 归一化且相位舍入后的复数（与输入同尺寸）

    % 计算复数的模和相位
    phase = angle(z);
    
    % 将相位转换到[0, 2pi)范围
    phase(phase < 0) = phase(phase < 0) + 2*pi;
    
    % 定义参考相位点
    ref_phases = [0.25*pi, 0.75*pi, 1.25*pi, 1.75*pi];
    
    % 初始化舍入后的相位数组
    rounded_phase = zeros(size(phase));
    
    % 对每个元素进行处理
    for i = 1:numel(phase)
        % 计算当前相位到各参考点的距离
        distances = abs(phase(i) - ref_phases);
        
        % 找到最小距离的索引
        [~, idx] = min(distances);
        
        % 获取舍入后的相位（如果匹配到2pi，实际返回0）
        rounded_phase(i) = mod(ref_phases(idx), 2*pi);
    end
    
    % 构造归一化且相位舍入后的复数
    rounded_z = exp(1i * rounded_phase);
    
    % 如果需要保持原模长，可以取消下面这行的注释
    % rounded_z = magnitude .* rounded_z;
    
    % 保持输入的形状
    rounded_z = reshape(rounded_z, size(z));
end