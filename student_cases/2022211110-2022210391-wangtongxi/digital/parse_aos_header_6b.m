function parse_aos_header_6b(bitVector)
% 检查输入长度
    if length(bitVector) ~= 48
        error('输入必须为48位bit向量');
    end

    % 按位解析
    version         = bi2de(bitVector(1:2), 'left-msb');
    spacecraftID    = bi2de(bitVector(3:10), 'left-msb');
    vcID            = bi2de(bitVector(11:16), 'left-msb');
    vcFrameCount    = bi2de(bitVector(17:40), 'left-msb');
    replayFlag      = bitVector(41);
    vcUsageFlag     = bitVector(42);
    rsvdSpare       = bi2de(bitVector(43:44), 'left-msb');
    vcCycle         = bi2de(bitVector(45:48), 'left-msb');

    % 打印解析结果
    fprintf('解析结果：\n');
    fprintf('--------------------------------------\n');
    fprintf('Transfer Frame Version Number : %d\n', version);
    fprintf('Spacecraft ID                 : %d\n', spacecraftID);
    fprintf('Virtual Channel ID            : %d\n', vcID);
    fprintf('Virtual Channel Frame Count   : %d\n', vcFrameCount);
    fprintf('Replay Flag                   : %d\n', replayFlag);
    fprintf('VC Frame Count Usage Flag     : %d\n', vcUsageFlag);
    fprintf('RSVD. Spare                   : %d\n', rsvdSpare);
    fprintf('VC Frame Count Cycle          : %d\n', vcCycle);
    fprintf('--------------------------------------\n');
end
