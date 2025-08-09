# 卫星QPSK接收机教学案例 - 基于真实卫星数据的开放式多技术路径实现

[![MATLAB](https://img.shields.io/badge/MATLAB-R2021a+-orange.svg)](https://www.mathworks.com/products/matlab.html)
[![License](https://img.shields.io/badge/License-Educational%20Use-blue.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-green.svg)]()

## 🎯 项目简介

本项目是北京邮电大学"通信系统建模与仿真"课程的**创新教学案例**，基于北邮70周年校庆期间接收的**真实SAR卫星下行数据**，设计实现了完整的QPSK数字接收机系统。项目首创**开放式技术路径设计理念**，支持学生根据自身技术背景和兴趣自主选择实现方案，已通过三组学生的成功实践验证。

### ✨ 核心特色

- 🛰️ **真实工程数据**：使用53.7GB真实SAR卫星中频IQ数据，体验工程级信号处理挑战
- 🔧 **开放式设计**：三种技术路径可选，满足不同学习风格和技术背景需求
- 🔗 **完整链路**：从信号预处理到数据恢复的端到端QPSK接收机实现
- 📚 **教学导向**：详细教程和理论分析
- 🏆 **实践验证**：经过三组学生的实际项目验证，教学效果显著

## 🚀 技术路径选择

### 🔵 路径一：纯MATLAB编程实现（程梓睿方案）
- **技术特点**：深入算法原理，24个模块化函数实现
- **适合对象**：希望深度理解算法细节的学生
- **核心创新**：
  - ✅ 3阶Farrow立方插值器优化定时精度
  - ✅ 智能解扰验证与IQ路自动交换
  - ✅ 完整帧处理支持，保留同步字和冗余数据
- **技术亮点**：24个独立功能模块，算法参数可精确控制
- **实现目录**：`student_cases/14+2022210532+chengzirui/`

### 🟡 路径二：MATLAB+Simulink混合架构（汪曈熙方案）
- **技术特点**：系统级可视化建模，工程化程度高
- **适合对象**：注重系统工程思维的学生
- **核心优势**：
  - ✅ Simulink可视化信号流程建模
  - ✅ 集成CCSDS LDPC解码器标准模块
  - ✅ 实时监控和参数调试界面
- **技术亮点**：符合工业界建模习惯，模块替换灵活
- **实现目录**：`student_cases/2022211110-2022210391-wangtongxi/`

### 🟢 路径三：向量化优化实现（汪宇翔方案）
- **技术特点**：高效数据处理，性能优化导向
- **适合对象**：关注算法性能和计算效率的学生
- **核心优势**：
  - ✅ bsxfun构造滑动窗口矩阵，高效同步字检测
  - ✅ 向量化批量帧提取，内存效率优化
  - ✅ 智能相位检测，自动处理I/Q路问题
- **技术亮点**：矩阵批处理优势，适合大数据量处理
- **实现目录**：`student_cases/2022211110-2022210394-wangyuxiang/`

## 📁 项目结构

```
SatelliteQPSK/
├── 📄 README.md                        # 项目说明文档
├── 📄 LICENSE                          # 开源协议
├── 📄 CLAUDE.md                        # 项目配置文件
├── 📂 docs/                            # 📚 完整文档体系
│   ├── 📖 TUTORIAL.md                  # 详细教程
│   ├── 📝 基于真实卫星数据的QPSK接收机教学案例设计与实现（初稿）.md
│   ├── 📋 卫星数传信号帧格式说明.pdf    # CCSDS AOS标准文档
│   └── 📚 [8个参考文献PDF]              # 技术参考资料
├── 📂 references/                      # 🔬 学术参考文献
│   ├── 📄 SDR相关论文集.pdf
│   ├── 📄 DVB-S2技术标准.pdf
│   └── 📄 [其他6个参考文献]
├── 📂 student_cases/                   # 🎓 学生实现案例集
│   ├── 📂 14+2022210532+chengzirui/    # 🔵 程梓睿：纯MATLAB实现
│   │   ├── 🎯 SatelliteQPSKReceiverTest.m        # 主测试脚本
│   │   ├── 📂 lib/                              # 24个核心算法模块
│   │   │   ├── 🔧 SatelliteQPSKReceiver.m       # 主处理函数
│   │   │   ├── ⏱️ GardnerSymbolSync.m           # Gardner定时同步
│   │   │   ├── 📡 QPSKFrequencyCorrectPLL.m     # PLL载波同步
│   │   │   ├── 🎯 FrameSync.m                   # 帧同步算法
│   │   │   ├── 🔓 FrameScramblingModule.m       # 解扰模块
│   │   │   ├── 🔍 AOSFrameHeaderDecoder.m       # AOS帧头解析
│   │   │   └── 🧩 [18+其他核心模块]
│   │   ├── 📂 out/                              # 输出结果目录
│   │   └── 📊 技术报告.pdf                      # 详细技术文档
│   ├── 📂 2022211110-2022210391-wangtongxi/     # 🟡 汪曈熙：混合架构实现
│   │   ├── 📊 qpskrx.slx                        # 主Simulink模型
│   │   ├── 📡 qpsk_carrier_sync.m               # 载波同步MATLAB函数
│   │   ├── ⏱️ gardner.m                          # Gardner符号同步
│   │   ├── 📂 digital/                          # 数字处理模块目录
│   │   │   ├── 🎯 frameLocate.m                 # 帧定位算法
│   │   │   ├── 🔧 frameProcess.m                # 帧处理算法
│   │   │   ├── 🔓 ccsds_ldpc_decoder.m          # LDPC解码器
│   │   │   └── 🧮 generate_prbs32767.m          # PRBS序列生成
│   │   └── 📊 技术报告.pdf                      # 详细技术文档
│   └── 📂 2022211110-2022210394-wangyuxiang/    # 🟢 汪宇翔：向量化优化实现
│       ├── 📥 A_read_data.m                     # 数据读取与预处理
│       ├── 🔬 B_data_analyze.m                  # 信号分析与解调
│       ├── 📊 sar_simulink.slx                  # Simulink前端处理模型
│       ├── 🔍 find_sync_word.m                  # 高效同步字检测
│       ├── 📦 extract_frames.m                  # 向量化帧提取
│       ├── 🔓 descramble_array.m                # 优化解扰算法
│       └── 📊 技术报告.pdf                      # 详细技术文档
└── 📂 data/                            # 🗄️ 数据文件目录（用户自行添加）
    └── 💾 sample_0611_500MHz_middle.bin # 真实SAR卫星数据文件（53.7GB）

## 📥 数据文件下载

### 🛰️ 真实SAR卫星数据集

本项目使用的是北京邮电大学70周年校庆期间接收的真实SAR卫星下行数据，包含12个数据文件：

**🔗 百度网盘下载链接：**
- **链接**：https://pan.baidu.com/s/1EZNwXBJPChvZMmNumear2g?pwd=j6wr
- **提取码**：j6wr

**📋 数据文件列表：**
- `sample_0611_500MHz_中段.zip` 及其他11个数据文件
- 总计约57.7GB真实卫星IQ数据
- 格式：int16复数数据，采样率500MHz

**💡 使用说明：**
1. 下载所需的数据文件到本地
2. 将数据文件放置在项目的 `data/` 目录下
3. 根据选择的技术路径，在相应的主程序中修改数据文件路径
4. 建议先使用较小的数据段进行验证测试
```

## ⚙️ 核心算法模块

### 📡 信号处理链路
1. **信号加载**：从二进制文件读取原始IQ样本
2. **重采样**：500Msps → 150Msps，优化处理效率
3. **RRC匹配滤波**：根升余弦脉冲成形，最大化信噪比
4. **AGC归一化**：自动增益控制，稳定信号电平
5. **Gardner定时同步**：符号时钟恢复，支持Farrow插值器优化
6. **载波同步**：多种算法可选（PLL、Costas环、四次方环）
7. **帧同步**：相位模糊恢复与CCSDS AOS帧边界定位
8. **解扰**：基于$1+X^{14}+X^{15}$多项式的PRBS解扰算法

### 📊 关键技术指标
- **调制方式**：QPSK（四相相移键控）
- **比特率**：150 Mbps，对应符号率75 MBaud/s
- **采样率**：500 MHz
- **滚降系数**：α = 0.33（工程优化值）
- **帧结构**：CCSDS AOS标准，1024字节/帧
- **同步字**：0x1ACFFC1D（32比特，优秀自相关特性）
- **数据文件**：53.7GB真实SAR卫星IQ数据

## 🚀 快速开始

### 🔧 环境要求
- **MATLAB**：R2021a或更高版本（推荐R2023a+）
- **必需工具箱**：
  - Signal Processing Toolbox
  - Communications Toolbox
  - Simulink（仅路径二需要）
- **硬件要求**：
  - 内存：8GB+（推荐16GB+，用于处理大数据文件）
  - 存储：至少100GB可用空间
  - CPU：多核处理器（向量化计算优化）

### 🏃‍♂️ 运行步骤

#### 🔵 路径一：纯MATLAB实现（程梓睿方案）
```matlab
% 1. 设置算法库路径
addpath('student_cases/14+2022210532+chengzirui/lib');

% 2. 配置数据文件（必须为int16格式）
% 编辑 SatelliteQPSKReceiverTest.m 第3行，将文件名改为你的测试数据路径
% 例如：filename = 'data/sample_0611_500MHz_middle.bin';

% 3. 运行主程序
run('student_cases/14+2022210532+chengzirui/SatelliteQPSKReceiverTest.m');

% 4. 查看输出结果
% - out/IQbytes.txt: IQ字节数据
% - out/unscrambled_hex.txt: 解扰后的十六进制数据
% - out/Ibytes.txt, Qbytes.txt: I/Q路分离数据
```

#### 🟡 路径二：MATLAB+Simulink混合（汪曈熙方案）
```matlab
% 1. 数据预处理 - 运行workspaceLoader_int16.m
% 配置参数：
oriFs = 500e6;          % 原始采样率 500MHz
rs = 75e6;              % 符号速率 75MHz
r = 3;                  % 上采样倍数
offset = 4000000;       % 跳过前4M字节

run('student_cases/2022211110-2022210391-wangtongxi/workspaceLoader_int16.m');

% 2. 启动Simulink解调模型
open_system('student_cases/2022211110-2022210391-wangtongxi/qpskrx.slx');
sim('qpskrx');

% 3. 帧同步处理
run('student_cases/2022211110-2022210391-wangtongxi/frameLocate.m');

% 4. 数据解析和AOS帧头提取
run('student_cases/2022211110-2022210391-wangtongxi/frameProcess.m');

% 5. 查看AOS帧头解析结果
% 系统会自动显示解析的卫星ID、帧计数等信息
```

#### 🟢 路径三：向量化优化实现（汪宇翔方案）
```matlab
% 1. 数据读取和预处理 - 运行A_read_data.m
% 配置参数：
filename = 'data/sample_0611_500MHz_middle.bin';  
N = 1e6;                % 读取100万个采样点
fs = 500e6;             % 采样率 500MHz
T = 10;                 % 从第10秒开始读取
Ts = 1/fs;              % 采样时间间隔

run('student_cases/2022211110-2022210394-wangyuxiang/A_read_data.m');

% 2. Simulink信号处理 - 运行sar_simulink.slx
% 完成：频偏校正 → 6倍上采样 → 低通滤波 → 5倍下采样 → 符号同步 → 载波同步
open_system('student_cases/2022211110-2022210394-wangyuxiang/sar_simulink.slx');
sim('sar_simulink');

% 3. 解调分析和帧处理 - 运行B_data_analyze.m
% 执行：QPSK判决 → 相位纠正 → 同步字检测 → 帧提取 → 解扰 → LDPC解码 → AOS帧头解析
run('student_cases/2022211110-2022210394-wangyuxiang/B_data_analyze.m');

% 4. 查看解调结果
% I路和Q路的AOS帧头信息会自动显示在命令窗口
% 包括：版本号、卫星ID(40)、帧计数器等字段信息
```

## 🎓 教学价值

### 🎯 学习目标
- **理论掌握**：深入理解QPSK调制解调、同步算法、信道编码等核心理论
- **系统思维**：掌握数字接收机的系统架构和模块间协调设计
- **工程实践**：获得处理真实工程数据的宝贵经验
- **问题解决**：培养分析和解决同步失锁、参数失配等工程问题的能力

### 📚 适用课程
- **通信系统建模与仿真**（主要课程）
- **通信原理**（QPSK调制解调实践）
- **数字信号处理**（滤波器设计、同步算法）
- **卫星通信**（AOS帧结构、解扰算法）
- **MATLAB程序设计**（高级编程实践）

### 🏆 教学成果
基于三组学生的实际验证结果：

| 学生案例 | 技术路径 | 主要收获 | 创新亮点 |
|---------|---------|---------|---------|
| 程梓睿 | 纯MATLAB实现 | 算法原理深度理解 | Farrow插值器优化 |
| 汪曈熙 | 混合架构实现 | 系统工程思维培养 | 标准模块集成应用 |
| 汪宇翔 | 向量化优化实现 | 性能优化思维训练 | 高效矩阵运算 |

## ✅ 验证结果

### 📊 系统性能指标
成功解析AOS帧头信息，验证接收机功能正确性：
```
--- AOS Frame Header Decoded ---
Version: 1
Spacecraft ID: 40 (0x28)
Virtual Channel ID: 0
Frame Count: 514313
--------------------------------
Frame Count: 514314 (连续递增✅)
Frame Count: 514315 (连续递增✅)
```

### 🎯 关键验证点
- ✅ **星座图收敛**：清晰的四象限QPSK星座点
- ✅ **帧同步成功**：准确定位0x1ACFFC1D同步字
- ✅ **解扰正确**：AOS帧头字段解析正确
- ✅ **帧计数连续**：无丢帧现象，系统工作稳定

## 📖 技术支持

### 📚 详细文档
- **[完整教程](docs/TUTORIAL.md)** - 9章深度解析指南，从理论到实践的完整覆盖
- **[学术论文](docs/基于真实卫星数据的QPSK接收机教学案例设计与实现（初稿）.md)** - 教学案例设计理念与验证分析
- **技术报告** - 每个实现路径的详细技术文档和调试指南

### 🔧 问题排查
- **环境配置**：确保MATLAB版本和工具箱满足要求
- **内存不足**：处理大数据文件时适当调整数据段长度
- **路径问题**：检查数据文件路径和lib目录添加
- **参数调试**：参考各路径的技术报告进行参数优化

### 💡 常见问题解答
1. **Q**: 数据文件太大，如何处理？
   **A**: 可以调整`bitsLength`参数，先处理小段数据进行验证

2. **Q**: 星座图不收敛怎么办？
   **A**: 检查采样率、符号率配置，调整环路带宽参数

3. **Q**: 如何验证解调结果正确性？
   **A**: 使用AOS帧头解析器检查帧计数器连续性

## 🏆 致谢


### 👨‍🎓 学生贡献
- **程梓睿**：纯MATLAB路径，Farrow插值器优化创新
- **汪曈熙**：混合架构路径，系统级建模实践
- **汪宇翔**：向量化优化路径，高效算法实现

## 📄 开源协议

本项目采用教育用途开源协议，欢迎：
- ✅ 教学使用和课程集成
- ✅ 学术研究和技术交流
- ✅ 非商业用途的修改和分发
- ⚠️ 商业用途请联系项目维护者

## 🌟 项目亮点

- 📊 **实践验证**：三组学生成功实现，教学效果显著
- 🛰️ **真实数据**：53.7GB SAR卫星数据，工程级挑战
- 📚 **文档完善**：教程+学术论文+技术报告的完整体系
- 🔧 **技术先进**：Farrow插值器、向量化优化等创新实现

---

**📧 联系方式**  
**北京邮电大学 信息与通信工程学院**  
**通信系统建模与仿真课程团队**
