# 8 月黑客松项目申报书：moonbit-easings

项目目标：为 MoonBit 生态提供面向 UI、游戏镜头、数字艺术和离线媒体的纯 MoonBit 补间动画与时间轴内核。
现有痛点：已有基础 easing 或单独 Bezier 包能够计算曲线，但应用层仍需自行处理关键帧、重复、往返、轨道偏移、固定帧率采样和运动诊断。
核心范围：30 个常用 easing、可配置 Cubic-Bezier 求逆、Tween/Sequence、ScalarTrack、Point/Color/Transform 类型轨道、Timeline、颜色渐变、路径采样、确定性采样和曲线报告。
技术路线：构造阶段缓存 Bezier x 采样表，运行阶段使用 Newton 迭代并在低斜率区间二分；关键帧按严格递增时间组织，统一用 Curve 描述每段运动。
应用方式：渲染器或游戏循环调用 sample/value_at，离线导出器调用 sample_window，编辑器可使用 GradientBuilder 和 TrackBuilder；核心不依赖窗口、Canvas、Lottie 或平台 FFI。
测试规划：覆盖曲线端点、单调性、Bezier 对称/反向、关键帧边界、Repeat/Mirror/Continue、Tween 生命周期、类型轨道、渐变、串行组合、插值和固定帧率采样，并在多后端 CI 中复验。
交付物：可发布的 MoonBit 模块、完整 README、可运行 cmd/demo、MIT License、来源说明、生成接口文件、跨平台 CI 和可复现验证命令。
项目性质：原创 MoonBit 工具包；参考公开的 CSS Timing Functions、Robert Penner 风格公式和 Bezier 定义，不复制 hackwaly/easing、cg-zhou/bezier_easing 或 moon_lottie 的实现。
生态差异：本项目的重心是“运动数据管线”，不是单纯 easing 函数集合，也不是 Lottie/SVG 渲染引擎。
实施阶段：先完成数学曲线与 Bezier 解算，再完成轨道/Tween/Timeline，随后补齐插值、采样、诊断、示例、CI 和 Mooncakes 发布准备。
仓库链接：待推送到参赛者 GitHub 后补充；当前本地仓库尚未配置 remote，也不会在本阶段执行远程推送。
