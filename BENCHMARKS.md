# Benchmark notes

本页记录仓库内 `cmd/bench` 的一次可复现实测，不把单机墙钟时间当作跨平台性能承诺。

## 工作负载

`cmd/bench` 在 Native Release 构建中执行 200,000 次循环，每次循环同时调用：

- Cubic-Bezier `sample`；
- Tween `value_at`；
- 带逐段 easing 的 `ScalarTrack::sample`；
- 四控制点 `Spline2D::sample`；
- 一次 `adaptive_sample` 二次曲线工作负载。

程序输出固定校验和，便于确认优化或工具链切换没有改变计算路径：

~~~text
moonbit-easings native benchmark
iterations = 200000
bezier_samples = 133716.24332666802
tween_samples = 42789197.86454116
track_samples = 99899.94994995055
spline_samples = 1100000.0000000491
adaptive_points = 257
adaptive_endpoints = 0 -> 1
~~~

## 本地实测

测试日期：2026-08-19  
工具链：MoonBit stable，`moonc v0.10.7+bc794d341 (2026-08-11)`  
目标：Windows Native Release  
工作负载：预热一次后直接执行已构建的 `bench.exe` 七次，`Measure-Command` 只包围进程执行，不包含首次编译。

~~~text
timings_ms = 79.066, 63.783, 67.662, 85.604, 83.710, 84.074, 73.559
min_ms = 63.783
median_ms = 79.066
max_ms = 85.604
~~~

这组数据对应当前开发机的 Windows Native Release 进程执行时间；CPU 调度、电源策略和后台进程都会影响结果。比较不同实现时应保持相同工具链、目标、Release 配置和迭代次数，并优先比较固定校验和与重复测量的中位数。

## 重复测量

~~~powershell
moon fmt --check
moon build --target native --release cmd/bench
$exe = "_build/native/release/build/cmd/bench/bench.exe"
& $exe
1..7 | ForEach-Object {
  $elapsed = Measure-Command { & $exe | Out-Null }
  [math]::Round($elapsed.TotalMilliseconds, 3)
}
~~~
