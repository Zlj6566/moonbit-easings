///|
/// Deterministic native benchmark workload. Wall-clock timing is supplied by
/// the host shell so the package itself remains portable and dependency-free.
fn main {
  let curve = try! @easings.Bezier::new(0.25, 0.1, 0.25, 1.0)
  let tween = try! @easings.Tween::new(
    0.0,
    320.0,
    1.0,
    curve=@easings.Curve::bezier(curve),
  )
  let track = try! @easings.ScalarTrack::new([
    try! @easings.keyframe(0.0, 0.0),
    try! @easings.keyframe(
      0.5,
      1.0,
      curve=@easings.Curve::builtin(@easings.SineInOut),
    ),
    try! @easings.keyframe(1.0, 0.0),
  ])
  let spline = try! @easings.Spline2D::new([
    @easings.point2(x=0.0, y=0.0),
    @easings.point2(x=2.0, y=4.0),
    @easings.point2(x=5.0, y=0.0),
    @easings.point2(x=8.0, y=3.0),
  ])
  let config = try! @easings.AdaptiveSamplingConfig::new(0.00001, max_depth=12)
  let adaptive = try! @easings.adaptive_sample(
    fn(time) { time * time },
    0.0,
    1.0,
    config,
  )
  let mut bezier_checksum = 0.0
  let mut tween_checksum = 0.0
  let mut track_checksum = 0.0
  let mut spline_checksum = 0.0
  let iterations = 200000
  for index in 0..<iterations {
    let time = (index % 1000).to_double() / 999.0
    bezier_checksum = bezier_checksum + curve.sample(time)
    tween_checksum = tween_checksum + tween.value_at(time)
    track_checksum = track_checksum + track.sample(time)
    let point = spline.sample(time)
    spline_checksum = spline_checksum + point.x() + point.y()
  }
  let sampled = adaptive.points()
  println("moonbit-easings native benchmark")
  println("iterations = \{iterations.to_string()}")
  println("bezier_samples = \{bezier_checksum.to_string()}")
  println("tween_samples = \{tween_checksum.to_string()}")
  println("track_samples = \{track_checksum.to_string()}")
  println("spline_samples = \{spline_checksum.to_string()}")
  println("adaptive_points = \{sampled.length().to_string()}")
  println(
    "adaptive_endpoints = \{sampled[0].value().to_string()} -> \{sampled[sampled.length() - 1].value().to_string()}",
  )
}
