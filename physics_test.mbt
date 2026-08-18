///|
test "spring response reaches target and reports motion" {
  let spring = try! spring_spec(120.0, 18.0)
  assert_true(spring.natural_frequency() > 0.0)
  assert_true(spring.damping_ratio() > 0.0)
  assert_true((spring.value_at(0.0, 1.0, 0.0) - 0.0).abs() < 0.000001)
  assert_true((spring.value_at(0.0, 1.0, 10.0) - 1.0).abs() < 0.01)
  let sample = spring.sample(0.0, 1.0, 0.25)
  assert_true(sample.velocity().abs() > 0.0)
  assert_true(spring.settle_time() > 0.0)
  assert_true(spring.sample_many(0.0, 1.0, 1.0, 11).length() == 11)
}

///|
test "spring validates physical parameters" {
  try spring_spec(0.0, 1.0) catch {
    MotionError::InvalidDuration(_) => assert_true(true)
    _ => fail("unexpected motion error")
  } noraise {
    _ => fail("invalid spring was accepted")
  }
}

///|
test "hsv round trip and hue interpolation" {
  let red = rgba(r=1.0, g=0.0, b=0.0)
  let hsv_value = red.to_hsv()
  assert_true(hsv_value.saturation() == 1.0)
  assert_true((hsv_value.hue() - 0.0).abs() < 0.000001)
  let round_trip = hsv_value.to_rgba()
  assert_true((round_trip.red() - 1.0).abs() < 0.000001)
  let middle = interpolate_hsv(
    hsv(hue=350.0, saturation=1.0, value=1.0),
    hsv(hue=10.0, saturation=1.0, value=1.0),
    0.5,
  )
  assert_true((middle.hue() - 0.0).abs() < 0.000001)
  assert_true(red.luminance() > 0.2)
}
