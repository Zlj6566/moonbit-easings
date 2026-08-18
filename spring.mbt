///|
/// Physical parameters for a damped spring response.
pub struct SpringSpec {
  stiffness : Double
  damping : Double
  mass : Double
  initial_velocity : Double
} derive(Debug)

///|
pub fn spring_spec(
  stiffness : Double,
  damping : Double,
  mass? : Double = 1.0,
  initial_velocity? : Double = 0.0,
) -> SpringSpec raise MotionError {
  if stiffness <= 0.0 {
    raise MotionError::InvalidDuration(stiffness)
  }
  if damping < 0.0 {
    raise MotionError::InvalidDelay(damping)
  }
  if mass <= 0.0 {
    raise MotionError::InvalidDuration(mass)
  }
  ensure_finite(initial_velocity)
  { stiffness, damping, mass, initial_velocity }
}

///|
pub fn SpringSpec::natural_frequency(self : SpringSpec) -> Double {
  (self.stiffness / self.mass).sqrt()
}

///|
pub fn SpringSpec::damping_ratio(self : SpringSpec) -> Double {
  self.damping / (2.0 * (self.stiffness * self.mass).sqrt())
}

///|
pub fn SpringSpec::settle_time(
  self : SpringSpec,
  tolerance? : Double = 0.001,
) -> Double {
  let safe_tolerance = clamp(tolerance, 0.0000001, 0.5)
  let decay = self.damping / (2.0 * self.mass)
  if decay <= 0.0 {
    10.0 / self.natural_frequency()
  } else {
    -@math.ln(safe_tolerance) / decay
  }
}

///|
/// Spring position for a unit step from start to end.
pub fn SpringSpec::value_at(
  self : SpringSpec,
  start : Double,
  end : Double,
  time : Double,
) -> Double {
  if time <= 0.0 {
    start
  } else {
    let omega = self.natural_frequency()
    let ratio = self.damping_ratio()
    let displacement = start - end
    if ratio < 1.0 {
      let damped = omega * (1.0 - ratio * ratio).sqrt()
      let decay = @math.exp(-ratio * omega * time)
      let coefficient = (self.initial_velocity + ratio * omega * displacement) /
        damped
      end +
      decay *
      (
        displacement * @math.cos(damped * time) +
        coefficient * @math.sin(damped * time)
      )
    } else if ratio == 1.0 {
      let decay = @math.exp(-omega * time)
      end +
      decay *
      (displacement + (self.initial_velocity + omega * displacement) * time)
    } else {
      let root = (ratio * ratio - 1.0).sqrt()
      let first = -omega * (ratio - root)
      let second = -omega * (ratio + root)
      let coefficient_second = (self.initial_velocity - first * displacement) /
        (second - first)
      let coefficient_first = displacement - coefficient_second
      end +
      coefficient_first * @math.exp(first * time) +
      coefficient_second * @math.exp(second * time)
    }
  }
}

///|
pub fn SpringSpec::velocity_at(
  self : SpringSpec,
  start : Double,
  end : Double,
  time : Double,
) -> Double {
  derivative_of(
    fn(value) { self.value_at(start, end, value) },
    time,
    step=0.00001,
  )
}

///|
pub fn SpringSpec::sample(
  self : SpringSpec,
  start : Double,
  end : Double,
  time : Double,
) -> MotionSample {
  let value = self.value_at(start, end, time)
  let velocity = self.velocity_at(start, end, time)
  let acceleration = derivative_of(
    fn(value_at_time) { self.velocity_at(start, end, value_at_time) },
    time,
    step=0.00001,
  )
  { time, value, velocity, acceleration }
}

///|
pub fn SpringSpec::sample_many(
  self : SpringSpec,
  start : Double,
  end : Double,
  duration : Double,
  count : Int,
) -> Array[MotionSample] raise MotionError {
  if duration <= 0.0 {
    raise MotionError::InvalidDuration(duration)
  }
  if count < 2 {
    raise MotionError::InvalidSampleCount(count)
  }
  let result : Array[MotionSample] = []
  for i in 0..<count {
    let time = duration * i.to_double() / (count - 1).to_double()
    result.push(self.sample(start, end, time))
  }
  result
}

///|
pub fn SpringSpec::is_settled(
  self : SpringSpec,
  start : Double,
  end : Double,
  time : Double,
  tolerance? : Double = 0.001,
) -> Bool {
  let value = self.value_at(start, end, time)
  (value - end).abs() <= tolerance &&
  self.velocity_at(start, end, time).abs() <= tolerance
}
