///|
/// Summary metrics for comparing or previewing a motion curve.
pub(all) struct CurveReport {
  samples : Int
  minimum : Double
  maximum : Double
  endpoint_error : Double
  monotonic : Bool
  peak_velocity : Double
  peak_acceleration : Double
} derive(Debug)

///|
pub fn CurveReport::samples(self : CurveReport) -> Int {
  self.samples
}

///|
pub fn CurveReport::minimum(self : CurveReport) -> Double {
  self.minimum
}

///|
pub fn CurveReport::maximum(self : CurveReport) -> Double {
  self.maximum
}

///|
pub fn CurveReport::endpoint_error(self : CurveReport) -> Double {
  self.endpoint_error
}

///|
pub fn CurveReport::is_monotonic(self : CurveReport) -> Bool {
  self.monotonic
}

///|
pub fn CurveReport::peak_velocity(self : CurveReport) -> Double {
  self.peak_velocity
}

///|
pub fn CurveReport::peak_acceleration(self : CurveReport) -> Double {
  self.peak_acceleration
}

///|
fn build_report(func : (Double) -> Double, samples : Int) -> CurveReport {
  let count = if samples < 2 { 2 } else { samples }
  let first = func(0.0)
  let mut minimum = first
  let mut maximum = first
  let mut previous = first
  let mut monotonic = true
  let mut peak_velocity = 0.0
  let mut peak_acceleration = 0.0
  let step = 1.0 / (count - 1).to_double()
  for i in 1..<count {
    let x = i.to_double() * step
    let value = func(x)
    if value < minimum {
      minimum = value
    }
    if value > maximum {
      maximum = value
    }
    if value + 0.000000001 < previous {
      monotonic = false
    }
    let velocity = (value - previous) / step
    let acceleration = if i == 1 {
      0.0
    } else {
      (value - 2.0 * previous + func((i - 2).to_double() * step)) /
      (step * step)
    }
    if velocity.abs() > peak_velocity {
      peak_velocity = velocity.abs()
    }
    if acceleration.abs() > peak_acceleration {
      peak_acceleration = acceleration.abs()
    }
    previous = value
  }
  {
    samples: count,
    minimum,
    maximum,
    endpoint_error: (first - 0.0).abs() + (previous - 1.0).abs(),
    monotonic,
    peak_velocity,
    peak_acceleration,
  }
}

///|
/// Inspect an arbitrary easing function using a fixed normalized grid.
pub fn analyze_easing(func : (Double) -> Double, samples : Int) -> CurveReport {
  build_report(func, samples)
}

///|
pub fn analyze_easing_id(id : EasingId, samples : Int) -> CurveReport {
  build_report(easing(id), samples)
}

///|
pub fn analyze_bezier(curve : Bezier, samples : Int) -> CurveReport {
  build_report(curve.as_easing(), samples)
}

///|
/// Produce value, velocity, and acceleration samples for a normalized curve.
pub fn motion_profile(
  func : (Double) -> Double,
  samples : Int,
) -> Array[MotionSample] raise MotionError {
  if samples < 2 {
    raise MotionError::InvalidSampleCount(samples)
  }
  let result : Array[MotionSample] = []
  let step = 1.0 / (samples - 1).to_double()
  for i in 0..<samples {
    let time = i.to_double() * step
    let before_time = (time - step).max(0.0)
    let after_time = (time + step).min(1.0)
    let before = func(before_time)
    let value = func(time)
    let after = func(after_time)
    let width = after_time - before_time
    let velocity = if width == 0.0 { 0.0 } else { (after - before) / width }
    let left_width = time - before_time
    let right_width = after_time - time
    let acceleration = if left_width == 0.0 || right_width == 0.0 {
      0.0
    } else {
      ((after - value) / right_width - (value - before) / left_width) /
      ((left_width + right_width) / 2.0)
    }
    result.push({ time, value, velocity, acceleration })
  }
  result
}

///|
/// Integrate a normalized curve with the trapezoid rule.
pub fn integrate_curve(func : (Double) -> Double, samples : Int) -> Double {
  if samples < 2 {
    0.0
  } else {
    let step = 1.0 / (samples - 1).to_double()
    let mut total = 0.0
    let mut previous = func(0.0)
    for i in 1..<samples {
      let current = func(i.to_double() * step)
      total = total + (previous + current) * step / 2.0
      previous = current
    }
    total
  }
}
