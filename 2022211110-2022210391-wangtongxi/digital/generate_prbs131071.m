function prbs = generate_prbs131071()
    % 初始化状态（'1100 0111 0001 11000'）
    % 转换为向量：[1100 0111 0001 11000]
    state = [1 1 0 0  0 1 1 1  0 0 0 1  1 1 0 0  0];

    % 输出长度为 131071
    nBits = 131071;
    prbs = zeros(1, nBits);

    for i = 1:nBits
        % 当前输出是 state x0
        prbs(i) = state(end);

        % 计算新的输入位：x17 = x0 ⊕ x14
        newBit = xor(state(3), state(end));  % x0 xor x14
        
        state = [newBit,state(1:end-1)];
    end
end
