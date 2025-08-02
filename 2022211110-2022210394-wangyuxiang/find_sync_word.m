function idx_list = find_sync_word(bit, sync_word_hex)
%FIND_SYNC_WORD 返回同步字在比特流中出现的所有起始索引
%
% 输入：
%   bit            - 逻辑向量或数值向量（0/1），表示一维比特流
%   sync_word_hex  - 同步字的十六进制字符串（如 '1ACFFC1D'）
%
% 输出：
%   idx_list       - 同步字在 bit 中出现的所有起始位置索引（行向量）

    arguments
        bit (:,1) {mustBeNumericOrLogical, mustBeVector}
        sync_word_hex (1,:) char
    end

    bit = bit(:)';  % 转换为行向量
    sync_word_bin = dec2bin(hex2dec(sync_word_hex), 32) - '0';
    sync_len = length(sync_word_bin);
    bits_len = length(bit);

    if bits_len < sync_len
        idx_list = [];
        return;
    end

    % 构造滑动窗口矩阵
    idx = bsxfun(@plus, (1:sync_len)', 0:(bits_len - sync_len));
    window_matrix = bit(idx);

    % 匹配位置（布尔索引）
    matches = all(window_matrix == sync_word_bin', 1);

    % 输出匹配起始位置索引
    idx_list = find(matches);
end
