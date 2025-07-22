%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Scrambling/DeScrambling Module
function scrambled_data = ScramblingModule(data,InPhase)
%% 定义加扰解扰逻辑
N = length(data);
scrambled_data = zeros(1,N);
for m=1:N
    scrambled_data(m) = bitxor(InPhase(15),data(m));
    scrambled_feedback = bitxor(InPhase(15),InPhase(14));
    
    % 更新模拟移位寄存器
    for n=0:13
       InPhase(15-n) = InPhase(14-n);
    end
    
    InPhase(1) = scrambled_feedback;
end

end