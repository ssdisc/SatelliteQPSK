function prbs = generate_prbs32767(state)
    % 输出长度为 131071
    nBits = 32767;
    prbs = zeros(1, nBits);

    for i = 1:nBits
        % 当前输出是 state 的第一位（x15）
        prbs(i) = state(1);

        % 计算新的输入位：x15 = x15 ⊕ x14
        newBit = xor(state(1), state(2));  % x15 xor x14
        
        % 移位寄存器左移，新位放在最右边
        state = [state(2:end),newBit];
    end
end
