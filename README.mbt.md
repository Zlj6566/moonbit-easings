# moonbit-easings

MoonBit 数字媒体补间动画与贝塞尔缓动函数库：为 UI 交互、游戏镜头、数字艺术和离线媒体提供可组合、无运行时依赖的运动学基础设施。

## 项目定位

`moonbit-easings` 负责“时间、数值和运动轨迹如何变化”，不负责窗口渲染、资源解析或具体 UI 框架。它可以作为渲染器、游戏循环、音视频导出器和交互式编辑器的底层采样层，输出标量、向量、颜色、变换、路径和事件数据。

项目把 easing、Cubic-Bezier 时间轴求逆、Tween、关键帧轨道、时间线、路径和传输控制放在统一的数据模型中，同时保持核心包不依赖平台 I/O，适合 Wasm、Wasm-GC、JavaScript 和 Native 目标。

## 核心能力

- 31 个内建 easing：Linear、Quad、Cubic、Quart、Quint、Sine、Expo、Circ、Back、Elastic、Bounce。
- `Bezier::new(x1, y1, x2, y2)`：缓存采样表、Newton 迭代和二分回退组成稳定的时间轴求逆器。
- Tween 与 `ScalarTrack`：支持 delay、repeat、Mirror、Continue、逐段曲线、速度和加速度。
- 多媒体类型：Point2、Point3、RGBA、Transform2D、颜色渐变、Hermite 和 Catmull-Rom。
- 轨迹编排：命名标记、MarkerCursor、ScalarTrackBundle、MotionStateMachine、MotionClip 和 ClipSequence。
- 几何与时间：Spline2D/Spline3D、复合 Path2D、距离采样、投影、边界框和 Piecewise RetimeMap。
- 离线分析：固定帧率与自适应采样、信号滤波、峰值、积分、单调性、曲线报告和可复现实验入口。

与只提供基础 easing 函数的包相比，本项目的重点是可直接接入数字媒体工作流的轨道、时间、路径和导出层；它不复制其他生态包的实现，也不绑定 Lottie、Canvas 或某个游戏引擎。

## 快速开始

要求 MoonBit stable 0.10.7 或更新版本。

~~~sh
moon add Zlj6566/moonbit-easings
~~~

在 `moon.pkg` 中导入：

~~~moonbit nocheck
///|
import {
  "Zlj6566/moonbit-easings" @easings,
}
~~~

最小 Tween 示例：

~~~moonbit nocheck
let curve = try! @easings.Bezier::new(0.25, 0.1, 0.25, 1.0)
let tween = try! @easings.Tween::new(
  0.0,
  320.0,
  1.0,
  curve=@easings.Curve::bezier(curve),
)
let sample = tween.sample_motion(0.5)
println(sample.value().to_string())
println(sample.velocity().to_string())
~~~

## CLI

仓库提供两个可运行入口：

~~~sh
# 展示 Tween、关键帧、颜色渐变和序列组合
moon run cmd/demo

# 运行可复现的 Native 工作负载并打印校验和
moon run --target native --release cmd/bench
~~~

`cmd/bench` 不把主机时钟写入库 API；它打印固定迭代次数、采样校验和和自适应采样结果，主机耗时由 `BENCHMARKS.md` 中的测量命令取得。

## 架构

```text
Easing / Bezier
      │
      ├── Tween / Keyframe / ScalarTrack
      │          │
      │          ├── Timeline / Bundle / StateMachine
      │          └── Clip / Sequence / Transport / Markers
      │
      ├── Point / Color / Transform Tracks
      ├── Spline / Path / RetimeMap
      └── Sampling / Signal / Diagnostics
```

主要模块按职责拆分：`easing_*.mbt` 与 `bezier*.mbt` 提供曲线内核；`keyframe_*.mbt`、`tween.mbt` 和 `timeline.mbt` 提供时间数据模型；`typed_tracks.mbt`、`path.mbt`、`spline.mbt` 和 `path_geometry.mbt` 提供数字媒体值与几何；`adaptive_sampling.mbt`、`signal_processing.mbt` 和 `curve_analysis.mbt` 面向离线导出与质量检查；`motion_clip.mbt`、`motion_transport.mbt`、`motion_markers.mbt` 和 `motion_state_machine.mbt` 面向运行时编排。

核心采样函数只在调用者明确请求批量结果时分配输出数组；Bezier 单点采样使用缓存表、Newton 迭代和二分回退，不创建临时采样数组。

## 基准

基准说明、工具链版本、机器环境、完整输出和重复测量方式见 [BENCHMARKS.md](BENCHMARKS.md)。本地执行：

~~~sh
moon build --target native --release cmd/bench
moon run --target native --release cmd/bench
~~~

校验和用于确认不同构建目标实际执行了同一工作负载；墙钟数据不被当作跨机器的绝对性能承诺。

## 测试

提交前执行完整检查：

~~~sh
moon fmt --check
moon info --target all
git diff --exit-code
moon check --fmt --deny-warn --target all
moon build --target all
moon test --deny-warn --target all
~~~

测试覆盖 easing 边界、Bezier 参数求逆、重复和镜像时间、关键帧排序、向量/颜色/变换插值、路径端点、空输入、非法参数、标记方向、轨迹投影、自适应采样、重映射、信号边界和 Native/JS/Wasm 全目标行为。

## CI

`.github/workflows/test.yml` 在 Ubuntu、macOS 和 Windows 上安装官方 MoonBit stable 工具链，执行格式化、`moon info` 生成物差异检查、全目标检查、全目标构建和全目标测试，并开启 `--deny-warn`。

`.github/workflows/publish.yml` 只在手动触发时验证同一检查链，并使用仓库 Secret 中的 `MOONCAKES_TOKEN` 发布包；日常 CI 不执行发布。基准程序不进入普通测试矩阵，可按文档在 Native Release 模式单独运行。

## 许可证

本项目采用 MIT License，见 [LICENSE](LICENSE)。实现来源和第三方生态边界见 [SOURCES.md](SOURCES.md)。
