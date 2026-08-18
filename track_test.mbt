///|
test "keyframe track interpolates with per-segment easing" {
  let first = try! keyframe(0.0, 0.0, curve=Curve::builtin(QuadIn))
  let last = try! keyframe(1.0, 10.0)
  let track = try! ScalarTrack::new([first, last])
  assert_true((track.sample(0.5) - 2.5).abs() < 0.0000001)
  assert_true(track.length() == 2)
  assert_true(track.start_time() == 0.0)
  assert_true(track.end_time() == 1.0)
}

///|
test "track supports repeat mirror and continue" {
  let first = try! keyframe(0.0, 0.0)
  let last = try! keyframe(1.0, 10.0)
  let track = try! ScalarTrack::new([first, last])
  assert_true((track.sample(1.25, mode=Repeat) - 2.5).abs() < 0.000001)
  assert_true((track.sample(1.25, mode=Mirror) - 7.5).abs() < 0.000001)
  assert_true((track.sample(2.0, mode=Continue) - 20.0).abs() < 0.000001)
}

///|
test "track motion exposes finite difference diagnostics" {
  let first = try! keyframe(0.0, 0.0)
  let last = try! keyframe(2.0, 4.0)
  let track = try! ScalarTrack::new([first, last])
  let sample = track.sample_motion(1.0)
  assert_true((sample.value() - 2.0).abs() < 0.00001)
  assert_true((sample.velocity() - 2.0).abs() < 0.001)
}

///|
test "track builder keeps frames ordered" {
  let builder = TrackBuilder::new()
  builder.add(try! keyframe(2.0, 20.0))
  builder.add(try! keyframe(0.0, 0.0))
  builder.add(try! keyframe(1.0, 10.0))
  let track = try! builder.build()
  assert_true((track.sample(0.5) - 5.0).abs() < 0.000001)
  assert_true(builder.remove_at(1) is Some(_))
}

///|
test "track rejects duplicate timestamps" {
  let first = try! keyframe(1.0, 0.0)
  let second = try! keyframe(1.0, 1.0)
  try ScalarTrack::new([first, second]) catch {
    MotionError::NonIncreasingKeyframe(_, _) => assert_true(true)
    _ => fail("unexpected motion error")
  } noraise {
    _ => fail("duplicate timestamp was accepted")
  }
}
