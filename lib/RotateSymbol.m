%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% RotateSymbol Module
function y = RotateSymbol(x,index)

%% 旋转符号（循环旋转)
y = zeros(1,length(x));
for m=1:length(x)
    y(m) = mod((x(m)+index),4);
end