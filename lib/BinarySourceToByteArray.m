%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% BinarySourceToByteArray
function y = BinarySourceToByteArray(x)

byteArray = zeros(1,length(x)/8-1,'uint8');
for m=0:length(x)/8-1
    byteSource = x(1,1+m*8:1+(m+1)*8-1);
    byteDecode = BinarySourceToByte(byteSource);
    byteArray(m+1) = byteDecode;
end

y = byteArray;

end