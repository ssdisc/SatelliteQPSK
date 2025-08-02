function aosInfo = parseAOSFrames(bitStream)
% parseAOSFrames - 解析 AOS 帧头信息
% 输入:
%   bitStream: N x 7136 矩阵，每行是一个完整帧（7136 bits = 892 bytes）
% 输出:
%   aosInfo: 结构体数组，包含每帧的AOS帧头信息

    [numFrames, numBits] = size(bitStream);

    aosInfo(numFrames) = struct( ...
        'Version', [], ...
        'SpacecraftID', [], ...
        'VirtualChannelID', [], ...
        'FrameCount', [], ...
        'ReplayFlag', [], ...
        'DownlinkFlag', [], ...
        'IQFlag', [], ...
        'SymbolRate', [], ...
        'Spare', [] ...
    );

    for i = 1:numFrames
        % 提取AOS帧头比特（位于第33~80位）
        aosHeaderBits = bitStream(i, 1:48);

        % 解析字段
        VERSION_NUMBER = aosHeaderBits(1:2);
        SPACECRAFT_ID = aosHeaderBits(3:10);
        VIRTUAL_CHANNEL_ID = aosHeaderBits(11:16);
        FRAME_COUNT = aosHeaderBits(17:40);
        REPLAY_FLAG = aosHeaderBits(41);
        DOWNLINK_FLAG = aosHeaderBits(42);
        IQ_FLAG = aosHeaderBits(43:44);
        SYMBOL_RATE = aosHeaderBits(45:48);

        % 转换为十进制数
        % version = bin2dec(char(versionBits + '0'));
        % scid = bin2dec(char(scidBits + '0'));
        % vcid = bin2dec(char(vcidBits + '0'));
        % vcFrameCount = bin2dec(char(vcFrameCountBits + '0'));
        % controlFlags = bin2dec(char(controlFlagsBits + '0'));
        % spare = bin2dec(char(spareBits + '0'));
        version = bin2dec(char(VERSION_NUMBER + '0'));
        scid = bin2dec(char(SPACECRAFT_ID + '0'));
        vcid = bin2dec(char(VIRTUAL_CHANNEL_ID + '0'));
        vcFrameCount = bin2dec(char(FRAME_COUNT + '0'));
        replyFlag = bin2dec(char(REPLAY_FLAG + '0'));
        vcFrameCountUsageFlag = bin2dec(char(DOWNLINK_FLAG + '0'));
        spare = bin2dec(char(IQ_FLAG + '0'));
        vcFrameCountCycle = bin2dec(char(SYMBOL_RATE + '0'));

        % 填充到结构体
        % aosInfo(i).Version = version;
        % aosInfo(i).SCID = scid;
        % aosInfo(i).VCID = vcid;
        % aosInfo(i).VCFrameCount = vcFrameCount;
        % aosInfo(i).ControlFlags = controlFlags;
        % aosInfo(i).Spare = spare;
        aosInfo(i).Version = version;
        aosInfo(i).SpacecraftID = scid;
        aosInfo(i).VirtualChannelID = vcid;
        aosInfo(i).FrameCount = vcFrameCount;
        aosInfo(i).ReplayFlag = replyFlag;
        aosInfo(i).DownlinkFlag = vcFrameCountUsageFlag;
        aosInfo(i).IQFlag = spare;
        aosInfo(i).SymbolRate = vcFrameCountCycle;
    end
end
