# MoonBit 数字媒体补间动画与贝塞尔缓动函数库

moonbit-easings 是一个纯 MoonBit、无运行时依赖的运动学内核，面向 UI 交互、游戏镜头、数字艺术和离线媒体采样。它把 easing、Cubic-Bezier 时间轴求逆、Tween、关键帧轨道、命名时间线和导出采样组织成一套可组合 API。

项目的边界很明确：它不负责渲染窗口、不解析 Lottie、不绑定 Canvas，也不把某个 UI 框架当作前提。渲染器、游戏循环、音视频导出器可以直接消费这里产生的标量样本、速度和加速度。

## 为什么不是已有 easing 包的重复实现

在选题前检索了 Mooncakes 的 easing、bezier、animation、tween 和 keyframe 关键词。生态中已经有 hackwaly/easing 基础曲线包，以及 cg-zhou/bezier_easing 和使用它的 cg-zhou/moon_lottie。本项目不复制它们的代码，也不把自己描述成首个 easing 实现；独立贡献集中在：

- 把 30 个常用曲线、可配置 Cubic-Bezier 和关键帧段统一成可组合的 Curve；
- 用缓存采样表 + Newton 迭代 + 区间二分完成稳定的时间轴求逆；
- 提供 ScalarTrack、Tween、Timeline 和确定性采样窗口，覆盖实际媒体工作流；
- 提供 Point2/Point3、RGBA、Transform2D 类型轨道、ColorGradient 和 TweenSequence；
- 提供 Hermite/Catmull-Rom、弹簧响应、路径采样、时间量化和曲线诊断指标；
- 保持核心 API 不依赖平台 I/O，方便后续接入 wasm、native、JS 或具体渲染器。

来源和许可证边界见 SOURCES.md。

## 功能范围

### Easing 与曲线

- Linear、Quad、Cubic、Quart、Quint、Sine、Expo、Circ；
- Back、Elastic、Bounce 等带超调的曲线；
- compose、blend、mirror 组合；
- Bezier::new(x1, y1, x2, y2) 自定义三次贝塞尔；
- 曲线采样、导数、近似长度、误差和单调性报告。

### 时间轴与关键帧

- Tween 支持 delay、repeat、Mirror（往返）和生命周期状态；
- Keyframe 与 ScalarTrack 支持每段独立 easing；
- TrackBuilder 支持编辑器式增删改关键帧；
- Timeline 以名称和 offset 组织多条轨道；
- Clamp、Repeat、Mirror、Continue 四种边界策略。

### 数字媒体插值与采样

- 标量、Point2、Point3、RGBA、Transform2D；
- Point2Track、Point3Track、RgbaTrack、TransformTrack 和可编辑 GradientBuilder；
- ColorGradient、TweenSequence、SpringSpec 和 CubicPath2D；
- 最短路径角度插值、预乘 alpha 插值；
- Hermite 和 Catmull-Rom 曲线；
- 固定帧率采样、函数采样、降采样；
- 速度、加速度、峰值、端点误差和积分估计。

## 安装

要求 MoonBit 0.10.3 或更新版本。当前仓库使用 Mooncakes namespace Lyl66655/moonbit-easings；如果发布账号不同，请在发布前把 moon.mod 和导入路径中的 namespace 同步为自己的 Mooncakes 账号。

~~~sh
moon add Lyl66655/moonbit-easings
~~~

在 moon.pkg 中：

~~~moonbit
import {
  "Lyl66655/moonbit-easings" @easings,
}
~~~

## 快速示例

~~~moonbit
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

关键帧轨道：

~~~moonbit
let track = try! @easings.ScalarTrack::new([
  try! @easings.keyframe(0.0, 0.0),
  try! @easings.keyframe(
    0.5,
    1.0,
    curve=@easings.Curve::builtin(@easings.SineInOut),
  ),
  try! @easings.keyframe(1.0, 0.0),
])
let value = track.sample(0.25)
~~~

运行仓库中的示例：

~~~sh
moon run cmd/demo
~~~

## 工程结构

~~~text
.
├── bezier*.mbt             # Cubic-Bezier 缓存求逆与曲线工具
├── easing_*.mbt            # 曲线族、组合和注册表
├── keyframe_*.mbt          # 关键帧与标量轨道
├── tween.mbt               # 延时、重复和往返补间
├── interpolate*.mbt        # 点、颜色、变换及 Hermite/Catmull-Rom
├── typed_tracks.mbt        # Point/Color/Transform 类型轨道
├── color_gradient.mbt      # 颜色渐变与编辑器构建器
├── sequence.mbt            # 串行 Tween 组合
├── sampling.mbt            # 固定帧率与离线采样
├── timeline.mbt            # 命名多轨道时间线
├── path.mbt / spring.mbt   # 几何路径与弹簧响应
├── diagnostics.mbt         # 曲线报告和运动剖面
├── cmd/demo                # 可运行示例
└── .github/workflows       # MoonBit CI
~~~

## 验证

~~~sh
moon check --target all
moon test --target wasm
moon test --target wasm-gc
moon test --target native
moon run cmd/demo
moon fmt --check
moon check --fmt --deny-warn --target all
moon info
~~~

CI 会在 Linux、macOS、Windows 上执行格式化检查、带 deny-warn 的全后端检查、测试和 moon info 差异检查。当前 MoonBit 0.10.7 的 `moon fmt` 与 `moon info` 命令本身不提供 `--deny-warn` 选项，格式化通过 `moon fmt --check` 验证，警告门禁由 `moon check --fmt --deny-warn` 完成。项目核心不使用平台 FFI，因此 JS 测试也会在安装 Node.js 的 CI runner 上执行。

## 设计与性能说明

Bezier::new 阶段生成小型 x 采样表；Bezier::sample 首先用表定位区间，再用 Newton 迭代，斜率过小时回退到区间二分。采样阶段不创建临时数组，适合在每帧循环中调用。sample_many、Timeline::sample_window 等批处理 API 会按调用者要求分配输出数组，这是结果所有权的一部分。

Timeline 仍只保存标量轨道，避免把某个渲染器或序列化格式硬编码进核心；复杂值由类型轨道单独提供，保持数据模型和渲染后端解耦。ColorGradient、CubicPath2D 和 SpringSpec 分别覆盖颜色、几何路径和物理感运动，但不承担资源解析或绘制职责。

## 许可证

MIT，见 LICENSE。
