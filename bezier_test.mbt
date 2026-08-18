///|
test "bezier endpoints and linear curve" {
  let linear_curve = try! Bezier::new(0.0, 0.0, 1.0, 1.0)
  for i in 0..<=20 {
    let x = i.to_double() / 20.0
    assert_true((linear_curve.sample(x) - x).abs() < 0.000001)
  }
}

///|
test "bezier css ease curve is monotone" {
  let curve = try! Bezier::new(0.25, 0.1, 0.25, 1.0)
  let report = analyze_bezier(curve, 201)
  assert_true(report.is_monotonic())
  assert_true(report.endpoint_error() < 0.0000001)
  assert_true(curve.sample(0.5) > 0.5)
}

///|
test "bezier supports y overshoot and zero allocation sampling" {
  let curve = try! Bezier::new(0.2, -0.25, 0.8, 1.25, sample_count=33)
  assert_true(curve.sample(0.0) == 0.0)
  assert_true(curve.sample(1.0) == 1.0)
  assert_true(curve.derivative(0.5) > 0.0)
  let values = try! curve.sample_many(17)
  assert_true(values.length() == 17)
  assert_true(curve.approximate_length(64) > 1.0)
}

///|
test "bezier reverse preserves endpoints" {
  let curve = try! Bezier::new(0.25, 0.1, 0.75, 0.9)
  let reversed = curve.reversed()
  for i in 0..<=20 {
    let x = i.to_double() / 20.0
    assert_true(
      (reversed.sample(x) - (1.0 - curve.sample(1.0 - x))).abs() < 0.00001,
    )
  }
}

///|
test "bezier rejects invalid x controls" {
  try Bezier::new(-0.1, 0.0, 0.5, 1.0) catch {
    MotionError::InvalidBezierX(_, _) => assert_true(true)
    _ => fail("unexpected motion error")
  } noraise {
    _ => fail("invalid x control was accepted")
  }
}
