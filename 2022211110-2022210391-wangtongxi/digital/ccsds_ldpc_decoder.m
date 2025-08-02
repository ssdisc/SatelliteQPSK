function decoded_bits = ccsds_ldpc_decoder(input_bits, max_iter)
% CCSDS LDPC(8160,7136) 解码器
% 输入:
%   input_bits: N x 8160 矩阵，每行是一个接收帧（硬比特，0或1）
%   max_iter: 最大迭代次数 (可选，默认8)
% 输出:
%   decoded_bits: N x 7136 矩阵，每行是解码后的信息比特


% 参数处理
if nargin < 2
    max_iter = 8;
end

% 获取输入帧数
N = size(input_bits, 1);

% 检查输入尺寸
if size(input_bits, 2) ~= 8160
    error('输入矩阵列数必须为8160');
end

% 参数初始化
C = 30;
decSampleIn = [];
decValidIn = []; decStartIn = []; decEndIn =[];
decFrameGap = max_iter*5000; % Maximum frame gap considering all block lengths and code rates

% 生成信号向量
for n = 1:N
    llr_frame = C * (1 - 2 * double(input_bits(n, :)));
    decSampleIn = fi([decSampleIn llr_frame zeros(1,decFrameGap)],1,4,0);
    decStartIn = logical([decStartIn 1 zeros(1,8159) zeros(1,decFrameGap)]);
    decEndIn = logical([decEndIn zeros(1,8159) 1 zeros(1,decFrameGap)]);
    decValidIn = logical([decValidIn ones(1,8160) zeros(1,decFrameGap)]);
end

% Simulink参数设置
dataIn = decSampleIn.';
validIn = decValidIn;
startIn = decStartIn;
endIn = decEndIn;
simTime = length(decValidIn) + decFrameGap;

in = Simulink.SimulationInput('ccsdsLDPCModel');
in = in.setVariable('dataIn', dataIn);
in = in.setVariable('validIn', validIn);
in = in.setVariable('startIn', startIn);
in = in.setVariable('endIn', endIn);
in = in.setVariable('simTime', simTime);
in = in.setVariable('max_iter', max_iter);

% Simulink 仿真
open_system("ccsdsLDPCModel.slx");
out = sim(in);

% 结果处理
startIdx = find(squeeze(out.startOut));
endIdx = find(squeeze(out.endOut));
validOut = (squeeze(out.validOut));
decData = squeeze(out.decOut);
decoded_bits = zeros(N,7136);

for ii = 1:N
    idx = startIdx(ii):endIdx(ii);
    decHDL = decData(idx);
    validHDL = validOut(idx);
    
    HDLOutput = logical(decHDL(validHDL));
    decoded_bits(ii,:) = HDLOutput;
end

close_system("ccsdsLDPCModel.slx",0);
end