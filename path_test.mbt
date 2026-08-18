///|
test "cubic path samples endpoints and bounds" {
  let path = cubic_path2d(
    point2(x=0.0, y=0.0),
    point2(x=0.0, y=10.0),
    point2(x=10.0, y=10.0),
    point2(x=10.0, y=0.0),
  )
  assert_true(path.sample(0.0).x() == 0.0)
  assert_true(path.sample(1.0).x() == 10.0)
  assert_true(path.length(64) > 10.0)
  let bounds = path.bounds(segments=32)
  assert_true(bounds.minimum().x() == 0.0)
  assert_true(bounds.maximum().y() > 7.0)
  let line = path.polyline(8)
  assert_true(line.length() == 9)
}

///|
test "cubic path distance sampling is stable" {
  let path = cubic_path2d(
    point2(x=0.0, y=0.0),
    point2(x=2.0, y=0.0),
    point2(x=8.0, y=10.0),
    point2(x=10.0, y=10.0),
  )
  let total = path.length(128)
  let middle = path.sample_by_distance(total / 2.0)
  assert_true(middle.x() > 3.0 && middle.x() < 7.0)
  let tangent = path.tangent(0.5)
  assert_true(tangent.x() != 0.0 || tangent.y() != 0.0)
}
