%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Frequency Correct Module (PLL)
function [y,err] = QPSKFrequencyCorrectPLL(x,fc,fs,ki,kp)
%% 全局变量
theta = 0;
theta_integral = 0;

y = zeros(1,length(x));
err = zeros(1,length(x));

%% 主循环
for m=1:length(x)
   % 应用初始相位到x
   x(m) = x(m) * exp(-1j*(theta));
    
   % 判断最近星座点
   desired_point = 2*(real(x(m)) > 0)-1 + (2*(imag(x(m)) > 0)-1) * 1j;
   
   % 计算相位差
   angleErr = angle(x(m)*conj(desired_point));
   
   % 二阶环路滤波器
   theta_delta = kp * angleErr + ki * (theta_integral + angleErr);
   theta_integral = theta_integral + angleErr;
   
   % 累积相位误差
   theta = theta + theta_delta + 2 * pi * fc / fs;
   
   % 输出当前频偏纠正信号
   y(m) = x(m);
   err(m) = angleErr;
end

end