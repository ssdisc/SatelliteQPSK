%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SymbolToIndex Module
function y = SymbolToIndex(x)

y = zeros(1,length(x));

for m=1:length(x)
   symbol_I = real(x(m));
   symbol_Q = imag(x(m));
   
   if symbol_I > 0 && symbol_Q > 0
       y(m) = 0;
   elseif symbol_I < 0 && symbol_Q > 0
       y(m) = 1;
   elseif symbol_I < 0 && symbol_Q < 0
       y(m) = 2;
   elseif symbol_I > 0 && symbol_Q < 0
       y(m) = 3;
   end
end

end