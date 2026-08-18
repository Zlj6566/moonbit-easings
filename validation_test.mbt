///|
test "registry exposes the complete easing catalog" {
  let catalog = all_easings()
  assert_true(catalog.length() == 31)
  assert_true(catalog[0] is Linear)
  assert_true(catalog[catalog.length() - 1] is BounceInOut)
}

///|
test "constructors reject invalid sampling and time parameters" {
  try Bezier::new(0.2, 0.0, 0.8, 1.0, sample_count=1) catch {
    MotionError::InvalidSampleCount(1) => assert_true(true)
    _ => fail("unexpected Bezier error")
  } noraise {
    _ => fail("invalid Bezier sample count was accepted")
  }
  try TimeWarp::new(Curve::builtin(Linear), 0.0, 1.0, speed=0.0) catch {
    MotionError::InvalidDuration(0.0) => assert_true(true)
    _ => fail("unexpected time warp error")
  } noraise {
    _ => fail("invalid time warp speed was accepted")
  }
}

///|
test "builders reject empty and duplicate media stops" {
  try TweenSequence::new([]) catch {
    MotionError::EmptyTrack => assert_true(true)
    _ => fail("unexpected sequence error")
  } noraise {
    _ => fail("empty sequence was accepted")
  }
  let first = try! gradient_stop(0.5, rgba(r=1.0, g=0.0, b=0.0))
  let duplicate = try! gradient_stop(0.5, rgba(r=0.0, g=0.0, b=1.0))
  try ColorGradient::new([first, duplicate]) catch {
    MotionError::NonIncreasingKeyframe(_, _) => assert_true(true)
    _ => fail("duplicate gradient stop was accepted")
  } noraise {
    _ => fail("invalid gradient was accepted")
  }
}
