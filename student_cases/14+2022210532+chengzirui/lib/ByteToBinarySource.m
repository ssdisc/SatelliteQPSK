%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ByteToBinarySource Module
function y = ByteToBinarySource(x,mode)
y = zeros(1,length(x));
%% 利用位运算依次取出每一位
for m=1:8
    y(m) = bitand(x,1);
    x = bitshift(x,-1);
end

if mode == "reverse"
    y = fliplr(y);
end

end