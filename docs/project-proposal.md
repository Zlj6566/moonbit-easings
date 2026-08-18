# 2026 MoonBit 8 月黑客松项目申报书：moonbit-easings

项目仓库：https://github.com/Zlj6566/moonbit-easings

## 项目概述

moonbit-easings 是一个纯 MoonBit、零运行时依赖的数字媒体运动学库，面向 UI 交互、游戏镜头、数字艺术和离线媒体导出，提供从曲线计算到可消费运动数据的完整补间管线。

## 选题方向与应用价值

项目属于 MoonBit 生态库与数字媒体基础工具方向。现有 easing 项目通常聚焦单个曲线集合或 Bezier 求值；实际动画应用仍需自行处理关键帧、重复往返、类型插值、帧率采样和运动诊断。本项目为渲染器、游戏循环、编辑器和导出器提供稳定、可组合、跨平台的运动数据接口，不绑定 Canvas、Lottie 或具体 UI 框架。

## 核心功能

- 31 种 Linear、Polynomial、Sine、Expo、Circ、Back、Elastic、Bounce 缓动曲线。
- 带缓存采样表的 Cubic-Bezier 时间轴求逆，采用 Newton 迭代并在低斜率区间回退二分。
- Tween、TweenSequence、Keyframe、ScalarTrack、Timeline，以及 Clamp/Repeat/Mirror/Continue 边界策略。
- Point2/Point3、RGBA、Transform2D 类型轨道、ColorGradient、Hermite/Catmull-Rom、弹簧和路径采样。
- 固定帧率采样、降采样、速度/加速度/峰值/误差/积分诊断，服务实时和离线两类工作流。

## 技术路线与实施范围

核心数值统一使用 Double；构造阶段完成参数、时间和关键帧校验，运行阶段使用无平台依赖的标量计算。项目已完成数学曲线、Bezier、Tween/轨道、类型插值、采样、诊断、示例和跨平台 CI，后续将继续完善文档、性能基准、边界测试和 Mooncakes 发布。

## 测试与交付物

仓库包含 40 个测试，已在 Wasm、Wasm GC、JS、Native 后端通过 `moon test --deny-warn --target all`，并通过 `moon check --fmt --deny-warn --target all`、`moon fmt --check`、`moon info` 和可运行 demo 验证。交付物包括 MIT License、README、来源说明、可运行示例、生成接口文件、GitHub CI 和手动发布 workflow。
## 原创性与生态差异

项目为原创 MoonBit 实现，参考公开 CSS Timing Functions、Robert Penner 风格公式和 Cubic-Bezier 定义；赛前检索了 Mooncakes 的 hackwaly/easing、cg-zhou/bezier_easing 和 moon_lottie，仅借鉴其公开定位，不复制源码、测试素材或私有内容。本项目的独立贡献是面向数字媒体的运动数据管线，而非单纯 easing 集合或 Lottie 渲染引擎。
