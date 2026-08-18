///|
/// A small, dependency-free command-line preview of the motion pipeline.
fn main {
  let curve = try! @easings.Bezier::new(0.25, 0.1, 0.25, 1.0)
  let tween = try! @easings.Tween::new(
    0.0,
    320.0,
    1.0,
    curve=@easings.Curve::bezier(curve),
  )
  println("moonbit-easings demo")
  println("time      value      velocity")
  for i in 0..<=10 {
    let time = i.to_double() / 10.0
    let sample = tween.sample_motion(time)
    println(
      "\{time.to_string()}    \{sample.value().to_string()}    \{sample.velocity().to_string()}",
    )
  }
  let track = try! @easings.ScalarTrack::new([
    try! @easings.keyframe(0.0, 0.0),
    try! @easings.keyframe(
      0.5,
      1.0,
      curve=@easings.Curve::builtin(@easings.SineInOut),
    ),
    try! @easings.keyframe(1.0, 0.0),
  ])
  let report = @easings.analyze_easing_id(@easings.SineInOut, 101)
  println("track midpoint = \{track.sample(0.5).to_string()}")
  println("sine peak velocity = \{report.peak_velocity().to_string()}")
  let gradient = try! @easings.ColorGradient::new([
    try! @easings.gradient_stop(0.0, @easings.rgba(r=1.0, g=0.0, b=0.0)),
    try! @easings.gradient_stop(1.0, @easings.rgba(r=0.0, g=0.0, b=1.0)),
  ])
  let midpoint_color = gradient.sample(0.5)
  let sequence = try! @easings.TweenSequence::new(
    [
      try! @easings.Tween::new(0.0, 1.0, 0.25),
      try! @easings.Tween::new(1.0, 0.0, 0.5),
    ],
    gap=0.1,
  )
  println("gradient midpoint red = \{midpoint_color.red().to_string()}")
  println("sequence duration = \{sequence.duration().to_string()}")
}
