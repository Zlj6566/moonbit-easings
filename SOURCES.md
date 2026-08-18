# 来源与差异说明

`moonbit-easings` 是独立实现，不复制第三方源代码，也不打包第三方素材。

赛前对 Mooncakes 关键词 `easing`、`bezier`、`animation`、`tween`、`keyframe` 做过检索，确认生态中已经存在以下相关项目：

| 项目 | 许可证 | 本项目的边界 |
| --- | --- | --- |
| [hackwaly/easing](https://mooncakes.io/docs/hackwaly/easing) | BSD-3-Clause | 已有基础 easing 函数；本项目不复用其代码，补充面向媒体时间轴的轨道、采样和诊断 API。 |
| [cg-zhou/bezier_easing](https://mooncakes.io/docs/cg-zhou/bezier_easing) | MIT | 已有 CSS 风格 Cubic-Bezier 解算；本项目独立实现解算器，并把曲线接入可复用的 Tween、KeyframeTrack 和采样器。 |
| [cg-zhou/moon_lottie](https://mooncakes.io/docs/cg-zhou/moon_lottie) | MIT | Lottie 引擎及其渲染边界；本项目不解析 Lottie、不渲染 SVG/Canvas，只提供可被动画引擎调用的运动学内核。 |

数学公式参考了公开的 CSS Timing Functions、Robert Penner 风格 easing 公式和 Cubic-Bezier 曲线定义。实现、测试数据和 API 设计均在本仓库内完成。
