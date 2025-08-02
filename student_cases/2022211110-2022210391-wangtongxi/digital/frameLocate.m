symbolsData=symbols.Data;
mask=~cellfun('isempty', symbolsData);
symbolsClean = cell2mat(symbolsData(mask));
bits=qpsk_demod(symbolsClean);

bitsI=bits(1:2:end);
bitsQ=bits(2:2:end);

CSM=[0 0 0 1  1 0 1 0  1 1 0 0  1 1 1 1  1 1 1 1  1 1 0 0  0 0 0 1  1 1 0 1]';
positions=find_subvector(bitsI,CSM);

frames=[];
for i=1:length(positions)-1
    frames=[frames; bitsI(positions(i):8192+positions(i)-1)'];
end