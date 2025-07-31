# 卫星通信QPSK调制解调系统 MATLAB 仿真

## 简介

本项目是一个基于 MATLAB 的卫星通信下行链路 QPSK 信号接收机仿真平台。它完整地实现了从原始IQ采样数据到最终解调出业务数据的全过程，旨在通过仿真验证和展示数字通信接收机中的各项关键技术。

## 功能

项目实现的核心信号处理模块包括：

*   **RRC 滚降滤波器:** 用于脉冲成形和匹配滤波，以消除码间串扰。
*   **Gardner 算法符号同步:** 从接收信号中恢复出精确的符号时钟。
*   **Costas 环载波恢复:** 对信号进行载波频率和相位的同步。
*   **帧同步:** 识别和锁定数据帧的起始位置。
*   **解扰:** 恢复经过加扰处理的原始数据码流。
*   **数据解码:** 将二进制数据流转换为字节，并最终输出为十六进制格式。

## 项目结构

*   `SatelliteQPSKReceiverTest.m`: 主测试与仿真脚本，调用各个模块，串联起整个接收流程。
*   `lib/`: 存放核心信号处理算法模块的目录。
    *   `SignalLoader.m`: 信号加载模块。
    *   `RRCFilterFixedLen.m`: RRC 滤波器。
    *   `GardnerSymbolSync.m`: Gardner 符号同步算法。
    *   `QPSKFrequencyCorrectPLL.m`: Costas 环载波恢复。
    *   `FrameSync.m`: 帧同步模块。
    *   `FullFrameDescramblingModule.m`: 解扰模块。
    *   `...` (其他辅助函数)
*   `data/`: (建议) 用于存放输入信号数据。
*   `Ibytes.txt`, `Qbytes.txt`: 仿真中使用的原始基带 I 路