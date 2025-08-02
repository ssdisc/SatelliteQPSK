function aosFrameHead = AOSFrameHeaderDecoder(inputBinary)
%% 抽取第一帧进行验证
aosFrameBits = inputBinary(1,1:48);

%% 核心解码逻辑
% 获取版本ID号
if join(string(aosFrameBits(1,1:2)),"") == "01"
    aosFrameHead.versionId = 1;
end

% 获取卫星组号
satelliteGroupId = aosFrameBits(1,3:10);
if (BinarySourceToByte(satelliteGroupId) >= 36) && (BinarySourceToByte(satelliteGroupId) <= 39)
    aosFrameHead.satelliteType = "02组";
elseif (BinarySourceToByte(satelliteGroupId) >= 40) && (BinarySourceToByte(satelliteGroupId) <= 43)
    aosFrameHead.satelliteType = "03组";
else
    aosFrameHead.satelliteType = "无效";    
end

% 获取虚拟信道标识
satelliteVirtualChannelId = join(string(aosFrameBits(1,11:16)),"");
if satelliteVirtualChannelId == "000001" && aosFrameHead.satelliteType == "02组"
    aosFrameHead.satelliteVirtualChannelId = "02组 SAR数据";
elseif satelliteVirtualChannelId == "000010" && aosFrameHead.satelliteType == "02组"
    aosFrameHead.satelliteVirtualChannelId = "02组 星上处理数据";
elseif satelliteVirtualChannelId == "111111" && aosFrameHead.satelliteType == "02组"
    aosFrameHead.satelliteVirtualChannelId = "02组 填充帧";
elseif satelliteVirtualChannelId == "000000" && aosFrameHead.satelliteType == "03组"
    aosFrameHead.satelliteVirtualChannelId = "03组 有效数据";
elseif satelliteVirtualChannelId == "111111" && aosFrameHead.satelliteType == "03组"
    aosFrameHead.satelliteVirtualChannelId = "03组 填充帧";
else
    aosFrameHead.satelliteVirtualChannelId = "无效";
end

% 获取VCDU循环计数
satelliteVCDUCounter = BinarySourceToInt(aosFrameBits(1,17:40));
aosFrameHead.satelliteVCDUCounter = satelliteVCDUCounter;

% 标志域数据解码
% 获取实时回放标识
satelliteReplyId = join(string(aosFrameBits(1,41)),"");
if satelliteReplyId == "0"
    aosFrameHead.satelliteReplyId = "实时传输";
else
    aosFrameHead.satelliteReplyId = "回放";
end
    
% 获取下传标识
satelliteDownloadId = join(string(aosFrameBits(1,42)),"");
if satelliteDownloadId == "0"
    aosFrameHead.satelliteDownloadId = "单路下传";
else
    aosFrameHead.satelliteDownloadId = "双路下传";
end
    
% 获取IQ数据标识
satelliteIQDataId = join(string(aosFrameBits(1,43:44)),"");
if satelliteIQDataId == "00"
    aosFrameHead.satelliteIQDataId = "合路";
elseif satelliteIQDataId == "01"
    aosFrameHead.satelliteIQDataId = "I路";
elseif satelliteIQDataId == "10"
    aosFrameHead.satelliteIQDataId = "Q路";
else % "11"
    aosFrameHead.satelliteIQDataId = "无效";
end
    
% 获取传输速率标识
satelliteDigitalSpeed = join(string(aosFrameBits(1,45:48)),"");
if satelliteDigitalSpeed == "0111"
    aosFrameHead.satelliteDigitalSpeed = "1500Mbps";
elseif satelliteDigitalSpeed == "1100"
    aosFrameHead.satelliteDigitalSpeed = "1200Mbps";
elseif satelliteDigitalSpeed == "1001"
    aosFrameHead.satelliteDigitalSpeed = "900Mbps";
elseif satelliteDigitalSpeed == "0110"
    aosFrameHead.satelliteDigitalSpeed = "600Mbps";
elseif satelliteDigitalSpeed == "0101"
    aosFrameHead.satelliteDigitalSpeed = "300Mbps";
elseif satelliteDigitalSpeed == "1010"
    aosFrameHead.satelliteDigitalSpeed = "150Mbps";
elseif satelliteDigitalSpeed == "0011"
    aosFrameHead.satelliteDigitalSpeed = "75Mbps";
else
    aosFrameHead.satelliteDigitalSpeed = "无效";

end