%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Symbol Sync Module
function y = SymbolSync(x,sps)

% 假设信号已通过RRC匹配滤波处理，且为复数QPSK信号
dampingFactor = 1;  % 控制环路带宽 1
normalizedLoopBandwidth = 0.02;% 0.02

% 创建符号同步器对象（通常适用于QPSK等恒模信号）
symSync = comm.SymbolSynchronizer(...
    'TimingErrorDetector', 'Gardner (non-data-aided)', ...
    'SamplesPerSymbol', sps, ...
    'DampingFactor', dampingFactor, ...
    'NormalizedLoopBandwidth', normalizedLoopBandwidth, ...
    'DetectorGain', 1);%2.7



% 同步处理（内部自动找到起始点）
y = symSync(x.').';

end
