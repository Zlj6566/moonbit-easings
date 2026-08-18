///|
/// Bounds used to keep generated motion within a safe output range.
pub struct MotionBounds {
  minimum : Double
  maximum : Double
} derive(Debug)

///|
pub fn MotionBounds::new(
  minimum : Double,
  maximum : Double,
) -> MotionBounds raise MotionError {
  if maximum < minimum {
    raise MotionError::InvalidTime(maximum)
  }
  { minimum, maximum }
}

///|
pub fn MotionBounds::minimum(self : MotionBounds) -> Double {
  self.minimum
}

///|
pub fn MotionBounds::maximum(self : MotionBounds) -> Double {
  self.maximum
}

///|
pub fn MotionBounds::clamp(self : MotionBounds, value : Double) -> Double {
  if value < self.minimum {
    self.minimum
  } else if value > self.maximum {
    self.maximum
  } else {
    value
  }
}

///|
pub fn clamp_values(
  values : Array[Double],
  bounds : MotionBounds,
) -> Array[Double] {
  values.map(fn(value) { bounds.clamp(value) })
}

///|
pub fn blend_values(
  first : Array[Double],
  second : Array[Double],
  amount : Double,
) -> Array[Double] {
  let count = first.length().min(second.length())
  let weight = clamp01(amount)
  let result : Array[Double] = []
  for i in 0..<count {
    result.push(first[i] * (1.0 - weight) + second[i] * weight)
  }
  result
}

///|
/// Apply a soft saturation instead of a hard clamp near both bounds.
pub fn soft_limit(
  value : Double,
  minimum : Double,
  maximum : Double,
  softness : Double,
) -> Double {
  if maximum <= minimum {
    minimum
  } else {
    let center = (minimum + maximum) / 2.0
    let half = (maximum - minimum) / 2.0
    let normalized = (value - center) / half
    let strength = if softness <= 0.0 { 1.0 } else { softness }
    center + half * (normalized / (1.0 + @math.pow(normalized.abs(), strength)))
  }
}

///|
pub fn enforce_monotonic(
  values : Array[Double],
  increasing : Bool,
) -> Array[Double] {
  if values.length() == 0 {
    return []
  }
  let result : Array[Double] = [values[0]]
  for i in 1..<values.length() {
    let previous = result[i - 1]
    let current = values[i]
    result.push(
      if increasing {
        previous.max(current)
      } else {
        previous.min(current)
      },
    )
  }
  result
}
