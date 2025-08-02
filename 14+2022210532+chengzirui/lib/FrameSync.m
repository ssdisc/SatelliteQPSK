%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% QPSK帧同步器，加入帧同步时刻图绘制
function sync_frame_bits = FrameSync(s_symbol)
%% 定义同步字
sync_bits_length = 32;
syncWord = uint8([0x1A,0xCF,0xFC,0x1D]);
syncWord_bits = ByteArrayToBinarySourceArray(syncWord,"reverse");
ref_bits_I = syncWord_bits;
ref_bits_Q = syncWord_bits;

%% 定义帧长度
frame_len = 8192;
sync_frame_bits = [];
sync_index_list = [];  % 用于记录同步成功的位置

%% 主循环：搜索帧同步位置
for m = 1 : length(s_symbol) - frame_len
    s_frame = s_symbol(1, m : m + frame_len - 1);  % 提取一个可能的帧

    % 处理相位模糊（旋转3次，每次90°）
    for n = 1 : 3
        s_frame = s_frame * (1i);  % 逆时针旋转90度
        
        % 提取前同步字部分
        s_sync_frame = s_frame(1 : sync_bits_length);
        s_sync_frame_bits = SymbolToIdeaSymbol(s_sync_frame);  % 解调为理想符号
        
        i_sync_frame_bits = real(s_sync_frame_bits);
        q_sync_frame_bits = imag(s_sync_frame_bits);
        
        % 检查同步字匹配
        if isequal(i_sync_frame_bits, ref_bits_I) && isequal(q_sync_frame_bits, ref_bits_Q)
            disp('序列匹配');
            disp(['编号 ', num2str(m)]);
            
            s_frame_bits = SymbolToIdeaSymbol(s_frame);  % 获取整帧
            sync_frame_bits = [sync_frame_bits; s_frame_bits];
            sync_index_list = [sync_index_list, m];      % 记录匹配位置
            break;
        end
    end
end

%% 绘图：帧同步时刻图
figure;
stem(sync_index_list, ones(size(sync_index_list)), 'filled');
xlabel('符号位置');
ylabel('同步触发');
title('帧同步检测位置');
grid on;
