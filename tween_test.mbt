///|
test "tween delay repeat and lifecycle" {
  let tween = try! Tween::new(
    0.0,
    10.0,
    1.0,
    delay=0.5,
    repeat_count=1,
    mode=Mirror,
  )
  assert_true(tween.sample(0.25).state() is Before)
  assert_true((tween.value_at(0.5) - 0.0).abs() < 0.000001)
  assert_true((tween.value_at(1.0) - 5.0).abs() < 0.000001)
  assert_true((tween.value_at(1.5) - 10.0).abs() < 0.000001)
  assert_true(tween.sample(2.5).state() is After)
  assert_true((tween.value_at(2.5) - 0.0).abs() < 0.000001)
}

///|
test "tween uses a custom bezier curve" {
  let curve = try! Bezier::new(0.25, 0.1, 0.25, 1.0)
  let tween = try! Tween::new(0.0, 1.0, 2.0, curve=Curve::bezier(curve))
  assert_true(tween.value_at(0.0) == 0.0)
  assert_true(tween.value_at(2.0) == 1.0)
  assert_true(tween.value_at(1.0) > 0.5)
}

///|
test "tween sample many includes endpoints" {
  let tween = try! Tween::new(3.0, 9.0, 1.0)
  let samples = try! tween.sample_many(11)
  assert_true(samples.length() == 11)
  assert_true(samples[0].value() == 3.0)
  assert_true(samples[10].value() == 9.0)
}
