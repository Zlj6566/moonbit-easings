///|
test "spline clamps boundaries and follows a closed loop" {
  let open = try! Spline2D::new([
    point2(x=0.0, y=0.0),
    point2(x=1.0, y=2.0),
    point2(x=3.0, y=0.0),
  ])
  assert_true(open.sample(-1.0).x() == 0.0)
  assert_true(open.sample(2.0).x() == 3.0)
  assert_true(open.polyline(4).length() == 9)
  assert_true(open.length(16) > 0.0)
  let closed = try! Spline2D::new(
    [point2(x=0.0, y=0.0), point2(x=1.0, y=0.0), point2(x=1.0, y=1.0)],
    closed=true,
  )
  assert_true(closed.sample(0.0).x() == closed.sample(1.0).x())
}

///|
test "spline projection and 3d distance sampling are bounded" {
  let path = try! Spline2D::new([
    point2(x=0.0, y=0.0),
    point2(x=2.0, y=1.0),
    point2(x=4.0, y=0.0),
  ])
  let projection = path.project(point2(x=2.0, y=0.8), samples_per_segment=24)
  assert_true(projection.parameter() >= 0.0 && projection.parameter() <= 1.0)
  assert_true(projection.distance() >= 0.0)
  let space = try! Spline3D::new([
    point3(x=0.0, y=0.0, z=0.0),
    point3(x=0.0, y=0.0, z=2.0),
  ])
  assert_true(space.length(16) > 1.9)
  assert_true(space.sample_by_distance(0.0).z() == 0.0)
  assert_true(space.sample_by_distance(100.0).z() == 2.0)
}

///|
test "marker windows exclude start and reverse ordering" {
  let timeline = try! marker_sequence(["a", "b", "c"], 0.0, 1.0)
  assert_true(timeline.length() == 3)
  assert_true(timeline.next_after(0.0) is Some(_))
  assert_true(timeline.previous_before(2.0) is Some(_))
  let forward = timeline.between(0.0, 2.0)
  assert_true(forward.length() == 2)
  assert_true(forward[0].name() == "b")
  let backward = timeline.between(2.0, 0.0)
  assert_true(backward.length() == 2)
  assert_true(backward[0].name() == "b")
  let cursor = marker_cursor(timeline)
  assert_true(cursor.advance(1.5).length() == 1)
  assert_true(cursor.time() == 1.5)
}

///|
test "adaptive sampling preserves endpoints and detects crossings" {
  let config = try! AdaptiveSamplingConfig::new(0.0001, max_depth=12)
  let result = try! adaptive_sample(fn(time) { time * time }, 0.0, 1.0, config)
  assert_true(result.points().length() >= 2)
  assert_true(result.points()[0].value() == 0.0)
  assert_true(result.points()[result.points().length() - 1].value() == 1.0)
  let regular = try! sample_function(fn(time) { time * time }, 0.0, 1.0, 17)
  assert_true(integrate_samples(regular) > 0.3)
  assert_true(threshold_crossings(regular, 0.25).length() >= 1)
  assert_true(simplify_samples(regular, 0.001).length() >= 2)
  assert_true(local_maxima(regular, 0.0).length() == 0)
}

///|
test "retime maps remain ordered and reversible" {
  let map = try! RetimeMap::new([
    try! retime_segment(0.0, 1.0, 0.0, 2.0),
    try! retime_segment(1.0, 2.0, 2.0, 3.0),
  ])
  assert_true(map.length() == 2)
  assert_true((map.map(0.5) - 1.0).abs() < 0.001)
  assert_true((map.unmap(2.5) - 1.5).abs() < 0.001)
  assert_true(map.sample(9).length() == 9)
  let shifted = try! map.shift_output(5.0)
  assert_true(shifted.output_start() == 5.0)
  let scaled = try! map.scale_output(2.0)
  assert_true(scaled.output_end() == 6.0)
  try retime_segment(0.0, 0.0, 0.0, 1.0) catch {
    MotionError::InvalidRetimeSegment => assert_true(true)
    _ => fail("unexpected retime error")
  } noraise {
    _ => fail("zero-width retime segment was accepted")
  }
}

///|
test "bundles sample named channels and blend weights" {
  let track = try! ScalarTrack::new([
    try! keyframe(0.0, 0.0),
    try! keyframe(1.0, 2.0),
  ])
  let first = try! scalar_channel("x", track)
  let second = try! scalar_channel("y", track, weight=3.0, offset=1.0)
  let bundle = try! ScalarTrackBundle::new([first, second])
  let sample = bundle.sample(0.5)
  assert_true(sample.length() == 2)
  assert_true(sample.value_named("x") is Some(_))
  assert_true(sample.weighted_value() > 1.0)
  let muted = try! bundle.set_enabled("y", false)
  assert_true(muted.sample(0.5).active_weight() == 1.0)
  try scalar_channel("", track) catch {
    MotionError::InvalidChannelName => assert_true(true)
    _ => fail("unexpected channel error")
  } noraise {
    _ => fail("empty channel name was accepted")
  }
}

///|
test "state machine transitions and completes at the endpoint" {
  let machine = try! MotionStateMachine::new([
    try! motion_state("idle", 0.0),
    try! motion_state("active", 1.0),
  ])
  assert_true(machine.current() == "idle")
  try! machine.transition_to("active", 2.0, duration=1.0)
  assert_true(machine.is_transitioning())
  assert_true(machine.sample(2.5) > 0.0 && machine.sample(2.5) < 1.0)
  assert_true(machine.sample(3.0) == 1.0)
  assert_true(machine.current() == "active")
  try machine.transition_to("missing", 4.0) catch {
    MotionError::InvalidStateName => assert_true(true)
    _ => fail("unexpected state error")
  } noraise {
    _ => fail("missing state was accepted")
  }
}

///|
test "composed paths and builders retain endpoints" {
  let builder = path_builder2d(point2(x=0.0, y=0.0))
  builder.line_to(point2(x=2.0, y=0.0))
  builder.cubic_to(
    point2(x=2.0, y=1.0),
    point2(x=4.0, y=1.0),
    point2(x=4.0, y=0.0),
  )
  let path = try! builder.build(samples_per_curve=32)
  assert_true(path.length() == 2)
  assert_true(path.start().x() == 0.0)
  assert_true(path.end().x() == 4.0)
  assert_true(path.total_length() > 4.0)
  assert_true(path.polyline(8).length() == 17)
  let projected = path.project(point2(x=2.0, y=0.1))
  assert_true(projected.distance() < 0.2)
}

///|
test "clip sequences, transport, and signal filters cover empty edges" {
  let track = try! ScalarTrack::new([
    try! keyframe(0.0, 0.0),
    try! keyframe(1.0, 1.0),
  ])
  let clip = try! motion_clip("fade", track)
  let sequence = try! ClipSequence::new([try! sequence_item(clip, 0.0)])
  assert_true(sequence.sample(0.5) > 0.4)
  assert_true(sequence.sample_many(5).length() == 5)
  let range = try! transport_range(0.0, 2.0)
  let transport = MotionTransport::new(range)
  try! transport.set_speed(2.0)
  transport.play()
  assert_true(transport.advance(0.25).length() == 0)
  assert_true(transport.position() == 0.5)
  assert_true(transport_frame_count(range, 2.0) == 5)
  assert_true(transport_time_at_frame(range, 2.0, 99) == 2.0)
  let signal = try! MotionSignal::new([0.0, 1.0, 2.0, 3.0], 0.0, 1.0)
  assert_true(signal.sample(-1.0) == 0.0)
  assert_true(signal.sample(99.0) == 3.0)
  assert_true(differentiate_signal(signal).values()[1] == 1.0)
  assert_true(integrate_signal(signal) == 4.5)
  assert_true(resample_signal(signal, 0.5).length() == 7)
}

///|
test "motion math and analysis expose stable scalar metrics" {
  let vector = point2(x=3.0, y=4.0)
  assert_true(point2_length(vector) == 5.0)
  assert_true(point2_normalized(vector).x() == 0.6)
  assert_true(point2_dot(vector, vector) == 25.0)
  let signal = try! MotionSignal::new([0.0, 1.0, 0.0], 0.0, 1.0)
  let samples = signal_to_samples(signal)
  assert_true(classify_monotonicity(samples) is Mixed)
  assert_true(curve_maximum(samples) is Some(_))
  assert_true(total_variation(samples) == 2.0)
  assert_true(median([4.0, 1.0, 3.0]) == 3.0)
}
