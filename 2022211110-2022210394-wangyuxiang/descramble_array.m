function data_out = descramble_array(data_in, channel)
% descramble_array - 对输入数据矩阵进行加扰解码（LFSR），使用预生成PRBS优化
% 输入:
%   data_in : N x 8160 的二进制矩阵
%   channel : 字符 'I' 或 'Q'，指定使用 I 路或 Q 路初始状态
% 输出:
%   data_out: N x 8160 的解扰后二进制矩阵

    % 验证输入维度
    [num_frames, frame_len] = size(data_in);
    if frame_len ~= 8160
        error('Each row of input must be a binary vector of length 8160');
    end

    % 初始化 LFSR 初状态
    switch upper(channel)
        case 'I'
            init_lfsr = ones(1, 15);
        case 'Q'
            init_lfsr = [zeros(1, 7), ones(1, 8)];
        otherwise
            error('Invalid channel type. Use ''I'' or ''Q''.');
    end

    % 预生成长度 8192 的 PRBS 序列
    prbs_seq = zeros(1, 8160);
    lfsr = init_lfsr;
    for i = 1:8160
        prbs_bit = xor(lfsr(1), lfsr(2));
        prbs_seq(i) = lfsr(1);
        lfsr = [lfsr(2:15), prbs_bit];
    end

    % 逐帧批量解扰
    data_out = xor(data_in, repmat(prbs_seq, num_frames, 1));
end
