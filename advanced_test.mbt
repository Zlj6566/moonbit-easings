///|
test "derivatives match analytic polynomial curves" {
  assert_true((EasingId::QuadIn.derivative(0.5) - 1.0).abs() < 0.000001)
  assert_true((EasingId::CubicIn.derivative(0.5) - 0.75).abs() < 0.000001)
  assert_true((EasingId::SineIn.derivative(0.0) - 0.0).abs() < 0.000001)
  let numeric = derivative_of(fn(x) { x * x }, 0.5)
  assert_true((numeric - 1.0).abs() < 0.001)
}

///|
test "curve chain maps staged motion" {
  let chain = try! CurveChain::new([
    Curve::builtin(QuadIn),
    Curve::builtin(QuadOut),
  ])
  assert_true(chain.length() == 2)
  assert_true(chain.sample(0.0) == 0.0)
  assert_true(chain.sample(1.0) == 1.0)
  assert_true(chain.sample(0.5) > 0.0)
  let samples = try! chain.sample_many(9)
  assert_true(samples.length() == 9)
}

///|
test "track transforms preserve values and curves" {
  let track = try! ScalarTrack::new([
    try! keyframe(1.0, 2.0, curve=Curve::builtin(QuadIn)),
    try! keyframe(2.0, 4.0, curve=Curve::builtin(QuadOut)),
  ])
  let shifted = try! track.shift(3.0)
  assert_true(shifted.start_time() == 4.0)
  let scaled = try! track.scale_time(2.0)
  assert_true(scaled.duration() == 2.0)
  let mapped = try! track.map_values(fn(value) { value * 10.0 })
  assert_true(mapped.sample(1.5) > 20.0)
  let trimmed = try! track.trim(1.25, 1.75)
  assert_true(trimmed.start_time() == 1.25)
  assert_true(trimmed.end_time() == 1.75)
}

///|
test "track value range and batch sampling" {
  let track = try! ScalarTrack::new([
    try! keyframe(0.0, -1.0, curve=Curve::builtin(BackOut)),
    try! keyframe(1.0, 3.0),
  ])
  let (minimum, maximum) = track.value_range(41)
  assert_true(minimum <= -1.0)
  assert_true(maximum > 3.0)
  let values = track.sample_values([0.0, 0.5, 1.0])
  assert_true(values.length() == 3)
}

///|
test "frame clock and tempo are reversible" {
  let clock = try! FrameClock::new(24.0, origin=1.0)
  assert_true(clock.seconds_to_frame(1.5) == 12)
  assert_true((clock.frame_to_seconds(12) - 1.5).abs() < 0.000001)
  let tempo = try! Tempo::new(120.0)
  assert_true((tempo.beat_duration() - 0.5).abs() < 0.000001)
  assert_true((tempo.seconds_to_beats(1.0) - 2.0).abs() < 0.000001)
}

///|
test "filters support deterministic signal processing" {
  let values = [0.0, 2.0, 4.0, 2.0]
  let smooth = moving_average(values, 3)
  assert_true(smooth.length() == 4)
  let velocity = differentiate(values, 0.5)
  assert_true((velocity[1] - 4.0).abs() < 0.000001)
  let normalized = normalize_samples(values)
  assert_true(normalized[0] == 0.0)
  assert_true(normalized[2] == 1.0)
  assert_true(monotone_envelope([0.0, 2.0, 1.0])[2] == 2.0)
  assert_true(peak_index(values) is Some(2))
  assert_true(rms([3.0, 4.0]) == 3.5355339059327378)
}
