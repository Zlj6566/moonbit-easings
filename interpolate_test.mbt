///|
test "point and color interpolation" {
  let p0 = point2(x=0.0, y=10.0)
  let p1 = point2(x=10.0, y=20.0)
  let p = p0.lerp(p1, 0.5)
  assert_true(p.x() == 5.0)
  assert_true(p.y() == 15.0)
  assert_true(p0.distance(p1) > 14.0)
  let color = interpolate_rgba(
    rgba(r=0.0, g=0.0, b=0.0),
    rgba(r=1.0, g=0.5, b=0.0),
    0.5,
  )
  assert_true((color.red() - 0.5).abs() < 0.000001)
  assert_true((color.green() - 0.25).abs() < 0.000001)
}

///|
test "angle interpolation follows shortest path" {
  let start = 3.0
  let end = -3.0
  let middle = interpolate_angle(start, end, 0.5)
  assert_true(middle.abs() > 3.0)
}

///|
test "hermite and catmull rom pass through endpoints" {
  assert_true(hermite(2.0, 8.0, 0.0, 0.0, 0.0) == 2.0)
  assert_true(hermite(2.0, 8.0, 0.0, 0.0, 1.0) == 8.0)
  let values = [0.0, 10.0, 20.0, 30.0]
  assert_true(catmull_rom_array(values, 1.0) == 10.0)
  assert_true(catmull_rom_array(values, 2.0) == 20.0)
}
