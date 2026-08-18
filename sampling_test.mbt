///|
test "sampling config is deterministic" {
  let config = try! SamplingConfig::new(0.0, 1.0, 10.0)
  assert_true(config.frame_count() == 11)
  let tween = try! Tween::new(0.0, 1.0, 1.0)
  let samples = sample_tween(tween, config)
  assert_true(samples.length() == 11)
  assert_true(samples[0].frame() == 0)
  assert_true(samples[10].time() == 1.0)
}

///|
test "function sampling and decimation preserve last sample" {
  let samples = try! sample_function(fn(x) { x * x }, 0.0, 1.0, 21)
  let reduced = decimate_samples(samples, 4)
  assert_true(reduced.length() == 6)
  assert_true(reduced[reduced.length() - 1].time() == 1.0)
}

///|
test "timeline samples named tracks" {
  let position = try! ScalarTrack::new([
    try! keyframe(0.0, 0.0),
    try! keyframe(1.0, 10.0),
  ])
  let opacity = try! ScalarTrack::new([
    try! keyframe(0.0, 1.0),
    try! keyframe(0.5, 0.0),
  ])
  let timeline = Timeline::new()
  timeline.add(track_slot("position", position))
  timeline.add(track_slot("opacity", opacity, offset=0.25))
  assert_true(timeline.track_count() == 2)
  assert_true(timeline.duration() == 1.0)
  let values = timeline.sample(0.5)
  assert_true(values.length() == 2)
  assert_true(values[0].name() == "position")
  assert_true((values[0].value() - 5.0).abs() < 0.000001)
  assert_true((values[1].value() - 0.5).abs() < 0.000001)
}
