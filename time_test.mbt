///|
test "time warp maps and approximately inverts" {
  let warp = try! TimeWarp::new(Curve::builtin(QuadIn), 0.0, 2.0, speed=2.0)
  assert_true(warp.duration() == 1.0)
  assert_true(warp.map(0.0) == 0.0)
  assert_true(warp.map(1.0) == 2.0)
  let mapped = warp.map(0.5)
  assert_true((warp.unmap(mapped) - 0.5).abs() < 0.000001)
  assert_true(remap_times([0.0, 0.5, 1.0], warp).length() == 3)
  assert_true((stagger(4, 0.1, 0.2)[3] - 0.7).abs() < 0.000001)
}

///|
test "motion bounds and signal constraints" {
  let bounds = try! MotionBounds::new(-1.0, 1.0)
  assert_true(bounds.clamp(3.0) == 1.0)
  assert_true(clamp_values([0.0, 2.0, -2.0], bounds)[1] == 1.0)
  assert_true(blend_values([0.0, 10.0], [10.0, 20.0], 0.5)[1] == 15.0)
  assert_true(enforce_monotonic([0.0, 2.0, 1.0], true)[2] == 2.0)
  assert_true(soft_limit(100.0, -1.0, 1.0, 1.0) < 1.0)
}
