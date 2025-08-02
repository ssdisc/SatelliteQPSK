%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ByteArrayToBinarySourceArray Module
function y = ByteArrayToBinarySourceArray(x,mode)

y = [];
for m=1:length(x)
    bits_array = ByteToBinarySource(x(m),mode);
    y = [y,bits_array];
end

end