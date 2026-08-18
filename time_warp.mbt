///|
/// A normalized time remapping used by editors and media exporters.
pub struct TimeWarp {
  curve : Curve
  start : Double
  end : Double
  speed : Double
} derive(Debug)

///|
pub fn TimeWarp::new(
  curve : Curve,
  start : Double,
  end : Double,
  speed? : Double = 1.0,
) -> TimeWarp raise MotionError {
  if end < start {
    raise MotionError::InvalidTime(end)
  }
  if speed <= 0.0 {
    raise MotionError::InvalidDuration(speed)
  }
  { curve, start, end, speed }
}

///|
pub fn TimeWarp::duration(self : TimeWarp) -> Double {
  (self.end - self.start) / self.speed
}

///|
pub fn TimeWarp::map(self : TimeWarp, time : Double) -> Double {
  if self.end == self.start {
    self.start
  } else {
    let ratio = clamp01((time - self.start) / self.duration())
    self.start + self.curve.apply(ratio) * (self.end - self.start)
  }
}

///|
/// Invert a timing curve with a fixed bisection budget.
pub fn TimeWarp::unmap(self : TimeWarp, mapped_time : Double) -> Double {
  if self.end == self.start {
    self.start
  } else {
    let target = clamp01((mapped_time - self.start) / (self.end - self.start))
    let mut low = 0.0
    let mut high = 1.0
    let mut middle = 0.5
    for _ in 0..<32 {
      middle = (low + high) / 2.0
      if self.curve.apply(middle) < target {
        low = middle
      } else {
        high = middle
      }
    }
    self.start + middle * self.duration()
  }
}

///|
pub fn TimeWarp::curve(self : TimeWarp) -> Curve {
  self.curve
}

///|
pub fn stagger(count : Int, delay : Double, interval : Double) -> Array[Double] {
  let result : Array[Double] = []
  if count <= 0 {
    return result
  }
  for index in 0..<count {
    result.push(delay + index.to_double() * interval)
  }
  result
}

///|
pub fn remap_times(times : Array[Double], warp : TimeWarp) -> Array[Double] {
  times.map(fn(time) { warp.map(time) })
}
