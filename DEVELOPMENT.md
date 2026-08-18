# Development notes

本项目保留可追踪的工程决策，便于后续验收和答辩说明。

## 关键取舍

- 采用 Double 作为核心数值类型，避免把核心 API 绑定到某个渲染后端。
- Bezier 构造阶段预计算 x 样本表，采样阶段只做标量运算，适合每帧调用。
- ScalarTrack 保持轻量标量语义；Point2/Point3、RGBA、Transform2D 通过独立类型轨道提供媒体数据能力，保持包边界清楚。
- ColorGradient、TweenSequence、CubicPath2D 和 SpringSpec 以独立模块扩展常见媒体工作流，不绑定渲染器或资源格式。
- 时间外推显式区分 Clamp、Repeat、Mirror、Continue，避免把循环语义隐藏在渲染器中。
- 所有公共构造函数对时间、时长、Bezier x 控制点和采样数量做校验。

## 可复现开发记录

仓库当前处于本地开发阶段。每个阶段使用可运行的测试和示例作为验收证据；推送到 GitHub 后继续保留功能、测试、文档和 CI 相关提交，不使用空提交凑数量。
