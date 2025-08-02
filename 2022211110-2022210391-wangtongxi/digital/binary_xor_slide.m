function [best_position, max_count, xor_result] = binary_xor_slide(long_vec, short_vec, target_pattern)
    % 计算两个二进制向量的滑动异或，并找到特定模式出现最多的位置
    %
    % 输入参数:
    %   long_vec - 较长的二进制向量 (1×n)
    %   short_vec - 较短的二进制向量 (1×m), m <= n
    %   target_pattern - 要统计的目标模式，例如 [0 1] 或 [1 0 1]
    %
    % 输出参数:
    %   best_position - 使目标模式出现最多的起始位置
    %   max_count - 目标模式出现的最大次数
    %   xor_result - 最佳位置时的异或结果
    
    len_long = length(long_vec);
    len_short = length(short_vec);
    pattern_len = length(target_pattern);
    
    if len_short > len_long
        error('短向量长度不能大于长向量');
    end
    if pattern_len > len_short
        error('目标模式长度不能大于短向量长度');
    end
    
    max_count = -1;
    best_position = 1;
    best_xor = [];
    
    % 滑动窗口遍历所有可能的位置
    for pos = 1:(len_long - len_short + 1)
        % 获取长向量的当前窗口
        current_window = long_vec(pos:pos+len_short-1);
        
        % 计算异或
        xor_result = xor(current_window, short_vec);
        
        % 统计目标模式出现的次数
        count = 0;
        for i = 1:pattern_len:(len_short - pattern_len + 1)
            if isequal(xor_result(i:i+pattern_len-1), target_pattern)
                count = count + 1;
            end
        end
        
        % 更新最佳位置
        if count > max_count
            max_count = count;
            best_position = pos;
            best_xor = xor_result;
        end
    end
    
    xor_result = best_xor;
end