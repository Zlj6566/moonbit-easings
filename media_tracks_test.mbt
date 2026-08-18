///|
test "typed point tracks share easing and extrapolation semantics" {
  let points = try! Point2Track::new([
    try! point2_keyframe(
      0.0,
      value=point2(x=0.0, y=0.0),
      curve=Curve::builtin(QuadIn),
    ),
    try! point2_keyframe(1.0, value=point2(x=10.0, y=20.0)),
  ])
  let middle = points.sample(0.5)
  assert_true((middle.x() - 2.5).abs() < 0.000001)
  assert_true(points.sample(1.5, mode=Repeat).x() == 2.5)
  let many = points.sample_many(5)
  assert_true(many.length() == 5)

  let space = try! Point3Track::new([
    try! point3_keyframe(0.0, value=point3(x=0.0, y=0.0, z=0.0)),
    try! point3_keyframe(1.0, value=point3(x=1.0, y=2.0, z=3.0)),
  ])
  assert_true((space.sample(0.5).z() - 1.5).abs() < 0.000001)
}

///|
test "color and transform tracks interpolate media values" {
  let colors = try! RgbaTrack::new([
    try! rgba_keyframe(0.0, value=rgba(r=0.0, g=0.0, b=0.0)),
    try! rgba_keyframe(1.0, value=rgba(r=1.0, g=1.0, b=1.0)),
  ])
  assert_true((colors.sample(0.25).red() - 0.25).abs() < 0.000001)
  let transforms = try! TransformTrack::new([
    try! transform_keyframe(
      0.0,
      value=transform2d(
        position=point2(x=0.0, y=0.0),
        scale=point2(x=1.0, y=1.0),
        rotation=0.0,
      ),
    ),
    try! transform_keyframe(
      1.0,
      value=transform2d(
        position=point2(x=10.0, y=4.0),
        scale=point2(x=2.0, y=2.0),
        rotation=@math.PI,
      ),
    ),
  ])
  assert_true((transforms.sample(0.5).position().x() - 5.0).abs() < 0.000001)
  assert_true(
    (transforms.sample(2.0, mode=Continue).position().x() - 20.0).abs() <
    0.000001,
  )
}

///|
test "gradient and serial tween composition" {
  let gradient = try! ColorGradient::new([
    try! gradient_stop(0.0, rgba(r=1.0, g=0.0, b=0.0)),
    try! gradient_stop(1.0, rgba(r=0.0, g=0.0, b=1.0)),
  ])
  assert_true((gradient.sample(0.5).red() - 0.5).abs() < 0.000001)
  assert_true(gradient.reversed().sample(0.0).blue() == 1.0)
  let builder = GradientBuilder::new()
  builder.add(try! gradient_stop(0.0, rgba(r=0.0, g=1.0, b=0.0)))
  builder.add(try! gradient_stop(1.0, rgba(r=1.0, g=1.0, b=0.0)))
  assert_true(try! (builder.build().length() == 2))

  let first = try! Tween::new(0.0, 1.0, 1.0)
  let second = try! Tween::new(1.0, 3.0, 2.0)
  let sequence = try! TweenSequence::new([first, second], gap=0.25)
  assert_true((sequence.duration() - 3.25).abs() < 0.000001)
  assert_true(sequence.sample(1.1).state() is Gap)
  assert_true((sequence.value_at(1.1) - 1.0).abs() < 0.000001)
  assert_true(sequence.sample_many(7).length() == 7)
}
