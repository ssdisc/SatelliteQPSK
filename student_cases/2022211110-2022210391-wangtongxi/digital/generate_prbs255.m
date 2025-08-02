function prbs = generate_prbs255(state)
    % 输出长度为 131071
    nBits = 255;
    prbs = zeros(1, nBits);

    for i = 1:nBits
        % 当前输出是 state 的 x0
        prbs(i) = state(end);

        % 计算新的输入位：x1 = x8 + x7 + x5 + x3
        newBit = xor(xor(xor(state(end), state(5)),state(3)),state(1));  % x15 xor x14
        
        state = [newBit,state(1:end-1)];
    end
end
