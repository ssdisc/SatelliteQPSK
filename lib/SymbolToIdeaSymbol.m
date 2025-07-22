%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SymbolToIdeaSymbol Module (Gray)
function ideaSymbol = SymbolToIdeaSymbol(s_symbol)
%% 初始化理想符号数组
ideaSymbol = zeros(1,length(s_symbol)) + 1j*zeros(1,length(s_symbol));
for m=1:length(s_symbol)
    symbol_I = real(s_symbol(m));
    symbol_Q = imag(s_symbol(m));
    
    if symbol_I > 0 && symbol_Q > 0
        ideaSymbol(m) = 0 + 0j;
    elseif symbol_I < 0 && symbol_Q > 0
        ideaSymbol(m) = 1 + 0j;
    elseif symbol_I < 0 && symbol_Q < 0
        ideaSymbol(m) = 1 + 1j;
    elseif symbol_I > 0 &&  symbol_Q < 0
        ideaSymbol(m) = 0 + 1j;
    end
end