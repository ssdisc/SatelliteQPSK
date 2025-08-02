function frames = extract_frames(bitstream, index)
% extract_frames - 高效提取8192比特帧，使用向量化操作
% 输入:
%   bitstream : 一维逻辑型或数值型比特流
%   index     : 起始索引数组（帧头位置，1-based）
% 输出:
%   frames    : 每行一帧，共8192位，矩阵大小为 N×8192

    FRAME_LEN = 8192;

    % 丢弃越界帧头索引
    valid_idx = index(index + FRAME_LEN - 1 <= length(bitstream));

    % 构造帧内偏移矩阵（每帧8192列）
    offsets = 0:(FRAME_LEN - 1);              % 1 × 8192
    indices_matrix = valid_idx(:) + offsets;  % N × 8192

    % 向量化提取帧数据
    if isscalar(valid_idx)
        frames = bitstream(indices_matrix)';
    else
        frames = bitstream(indices_matrix);
    end
end
