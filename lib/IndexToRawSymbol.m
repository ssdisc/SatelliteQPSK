%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% IndexToSymbol Module
function y = IndexToRawSymbol(x)

% 定义映射矩阵
tranMatrix = [0+0j,1+0j,1+1j,0+1j];

y = zeros(1,length(x));
for m=1:length(x)
    y(m) = tranMatrix(x(m)+1);
end

end