///|
/// Move a track in time while preserving its segment curves.
pub fn ScalarTrack::shift(
  self : ScalarTrack,
  offset : Double,
) -> ScalarTrack raise MotionError {
  let frames : Array[Keyframe] = []
  for frame in self.frames {
    frames.push({
      time: frame.time + offset,
      value: frame.value,
      curve: frame.curve,
    })
  }
  ScalarTrack::new(frames)
}

///|
/// Scale a track's time axis around its first keyframe.
pub fn ScalarTrack::scale_time(
  self : ScalarTrack,
  factor : Double,
) -> ScalarTrack raise MotionError {
  if factor <= 0.0 {
    raise MotionError::InvalidDuration(factor)
  }
  let origin = self.start_time()
  let frames : Array[Keyframe] = []
  for frame in self.frames {
    frames.push({
      time: origin + (frame.time - origin) * factor,
      value: frame.value,
      curve: frame.curve,
    })
  }
  ScalarTrack::new(frames)
}

///|
/// Transform values without changing timing or curves.
pub fn ScalarTrack::map_values(
  self : ScalarTrack,
  mapper : (Double) -> Double,
) -> ScalarTrack raise MotionError {
  let frames : Array[Keyframe] = []
  for frame in self.frames {
    let value = mapper(frame.value)
    ensure_finite(value)
    frames.push({ time: frame.time, value, curve: frame.curve })
  }
  ScalarTrack::new(frames)
}

///|
/// Return a track with a replacement curve on every segment.
pub fn ScalarTrack::with_curve(
  self : ScalarTrack,
  curve : Curve,
) -> ScalarTrack raise MotionError {
  let frames : Array[Keyframe] = []
  for frame in self.frames {
    frames.push({ time: frame.time, value: frame.value, curve })
  }
  ScalarTrack::new(frames)
}

///|
/// Copy a time range, adding interpolated boundary frames when needed.
pub fn ScalarTrack::trim(
  self : ScalarTrack,
  start : Double,
  end : Double,
) -> ScalarTrack raise MotionError {
  if end < start {
    raise MotionError::InvalidTime(end)
  }
  let first_value = self.sample(start)
  let last_value = self.sample(end)
  let frames : Array[Keyframe] = []
  frames.push({ time: start, value: first_value, curve: self.frames[0].curve })
  for frame in self.frames {
    if frame.time > start && frame.time < end {
      frames.push(frame)
    }
  }
  if end > start {
    frames.push({
      time: end,
      value: last_value,
      curve: self.frames[self.frames.length() - 1].curve,
    })
  }
  ScalarTrack::new(frames)
}

///|
pub fn ScalarTrack::value_range(
  self : ScalarTrack,
  samples_per_segment : Int,
) -> (Double, Double) {
  let count = if samples_per_segment < 2 { 2 } else { samples_per_segment }
  let mut minimum = self.frames[0].value
  let mut maximum = minimum
  for segment in 0..<(self.frames.length() - 1) {
    let left = self.frames[segment]
    let right = self.frames[segment + 1]
    for i in 0..<count {
      let ratio = i.to_double() / (count - 1).to_double()
      let value = left.value +
        (right.value - left.value) * left.curve.apply(ratio)
      if value < minimum {
        minimum = value
      }
      if value > maximum {
        maximum = value
      }
    }
  }
  (minimum, maximum)
}

///|
pub fn ScalarTrack::sample_values(
  self : ScalarTrack,
  times : Array[Double],
  mode? : Extrapolation = Clamp,
) -> Array[Double] {
  let result : Array[Double] = []
  for time in times {
    result.push(self.sample(time, mode~))
  }
  result
}
