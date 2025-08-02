%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% BinarySourceToByte
function y = BinarySourceToByte(x)
sum = 0;

for m=1:length(x)
    sum = sum * 2;
    sum = sum + x(m);
end

y=sum;
end