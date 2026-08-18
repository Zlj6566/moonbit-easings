///|
test "all built in curves keep exact endpoints" {
  for id in all_easings() {
    assert_true(id.apply(0.0) == 0.0)
    assert_true(id.apply(1.0) == 1.0)
  }
}

///|
test "polynomial families have expected midpoint values" {
  assert_true((quad_in(0.5) - 0.25).abs() < 0.0000001)
  assert_true((quad_out(0.5) - 0.75).abs() < 0.0000001)
  assert_true((cubic_in(0.5) - 0.125).abs() < 0.0000001)
  assert_true((cubic_out(0.5) - 0.875).abs() < 0.0000001)
  assert_true((quart_in(0.5) - 0.0625).abs() < 0.0000001)
  assert_true((quint_in(0.5) - 0.03125).abs() < 0.0000001)
}

///|
test "composed curves stay allocation free at evaluation" {
  let curve = compose(easing(QuadOut), easing(QuadIn))
  assert_true((curve(0.5) - 0.4375).abs() < 0.0000001)
  let mixed = blend(easing(Linear), easing(QuadIn), amount=0.5)
  assert_true((mixed(0.5) - 0.375).abs() < 0.0000001)
  let reflected = mirror(easing(QuadIn))
  assert_true((reflected(0.25) - 0.4375).abs() < 0.0000001)
}

///|
test "overshoot families are configurable" {
  let gentle = back_in(0.5, overshoot=0.5)
  let strong = back_in(0.5, overshoot=3.0)
  assert_true(strong < gentle)
  let fast = elastic_out(0.4, period=0.15)
  let slow = elastic_out(0.4, period=0.7)
  assert_true((fast - slow).abs() > 0.000001)
}

///|
test "curve report detects overshoot" {
  let report = analyze_easing_id(BackOut, 101)
  assert_true(report.samples() == 101)
  assert_true(report.maximum() > 1.0)
  assert_true(report.endpoint_error() < 0.0000001)
  assert_true(report.peak_velocity() > 0.0)
}
