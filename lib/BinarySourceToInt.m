function y = BinarySourceToInt(binarySource)

sum = 0;
for m=1:length(binarySource)
    sum = sum * 2 + binarySource(m);
end

y = sum;