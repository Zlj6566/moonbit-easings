///|
/// A cached cubic Bézier timing curve.
///
/// The x controls must lie in [0, 1], while y controls may overshoot for
/// spring-like or expressive motion. Construction builds a small lookup table;
/// evaluation only reads the table and performs scalar arithmetic.
pub struct Bezier {
  x1 : Double
  y1 : Double
  x2 : Double
  y2 : Double
  sample_values : Array[Double]
} derive(Debug)

///|
fn bezier_a(p1 : Double, p2 : Double) -> Double {
  1.0 - 3.0 * p2 + 3.0 * p1
}

///|
fn bezier_b(p1 : Double, p2 : Double) -> Double {
  3.0 * p2 - 6.0 * p1
}

///|
fn bezier_c(p1 : Double) -> Double {
  3.0 * p1
}

///|
fn bezier_value(t : Double, p1 : Double, p2 : Double) -> Double {
  ((bezier_a(p1, p2) * t + bezier_b(p1, p2)) * t + bezier_c(p1)) * t
}

///|
fn bezier_slope(t : Double, p1 : Double, p2 : Double) -> Double {
  3.0 * bezier_a(p1, p2) * t * t + 2.0 * bezier_b(p1, p2) * t + bezier_c(p1)
}

///|
fn create_bezier_samples(
  x1 : Double,
  x2 : Double,
  sample_count : Int,
) -> Array[Double] {
  let values : Array[Double] = []
  for i in 0..<sample_count {
    let t = i.to_double() / (sample_count - 1).to_double()
    values.push(bezier_value(t, x1, x2))
  }
  values
}

///|
/// Construct a cubic timing curve with a cached lookup table.
pub fn Bezier::new(
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
  sample_count? : Int = 17,
) -> Bezier raise MotionError {
  if x1 < 0.0 || x1 > 1.0 || x2 < 0.0 || x2 > 1.0 {
    raise MotionError::InvalidBezierX(x1, x2)
  }
  if sample_count < 5 || sample_count > 129 {
    raise MotionError::InvalidSampleCount(sample_count)
  }
  ensure_finite(x1)
  ensure_finite(y1)
  ensure_finite(x2)
  ensure_finite(y2)
  { x1, y1, x2, y2, sample_values: create_bezier_samples(x1, x2, sample_count) }
}

///|
/// Construct a curve while clamping its x controls to the CSS-valid range.
pub fn bezier_clamped(
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
) -> Bezier {
  let safe_x1 = clamp01(x1)
  let safe_x2 = clamp01(x2)
  try! Bezier::new(safe_x1, y1, safe_x2, y2)
}

///|
pub fn Bezier::control_points(
  self : Bezier,
) -> (Double, Double, Double, Double) {
  (self.x1, self.y1, self.x2, self.y2)
}

///|
fn subdivide_bezier(
  x : Double,
  left : Double,
  right : Double,
  x1 : Double,
  x2 : Double,
) -> Double {
  let mut low = left
  let mut high = right
  let mut middle = (low + high) / 2.0
  for _ in 0..<12 {
    middle = (low + high) / 2.0
    let current = bezier_value(middle, x1, x2) - x
    if current > 0.0 {
      high = middle
    } else {
      low = middle
    }
  }
  middle
}

///|
fn refine_bezier(
  x : Double,
  guess : Double,
  lower : Double,
  upper : Double,
  x1 : Double,
  x2 : Double,
) -> Double {
  let mut current = guess
  for _ in 0..<4 {
    let slope = bezier_slope(current, x1, x2)
    if slope.abs() >= 0.0001 {
      let candidate = current - (bezier_value(current, x1, x2) - x) / slope
      current = clamp(candidate, lower, upper)
    }
  }
  current
}

///|
fn solve_bezier_time(
  x : Double,
  x1 : Double,
  x2 : Double,
  samples : Array[Double],
) -> Double {
  let sample_count = samples.length()
  let step = 1.0 / (sample_count - 1).to_double()
  let last = sample_count - 1
  let mut index = 0
  for i in 0..<last {
    if samples[i] <= x {
      index = i
    }
  }
  if index >= last {
    return 1.0
  }
  let next = samples[index + 1]
  let current = samples[index]
  let interval_start = index.to_double() * step
  let denominator = next - current
  let estimate = if denominator.abs() < 0.0000000001 {
    interval_start
  } else {
    interval_start + (x - current) / denominator * step
  }
  let interval_end = interval_start + step
  let slope = bezier_slope(estimate, x1, x2)
  if slope.abs() >= 0.0001 {
    refine_bezier(x, estimate, interval_start, interval_end, x1, x2)
  } else {
    subdivide_bezier(x, interval_start, interval_end, x1, x2)
  }
}

///|
/// Solve the time parameter t for a normalized x coordinate.
pub fn Bezier::solve_time(self : Bezier, x : Double) -> Double {
  let target = clamp01(x)
  if target == 0.0 {
    0.0
  } else if target == 1.0 {
    1.0
  } else {
    solve_bezier_time(target, self.x1, self.x2, self.sample_values)
  }
}

///|
/// Evaluate the y coordinate at normalized time x.
pub fn Bezier::sample(self : Bezier, x : Double) -> Double {
  bezier_value(self.solve_time(x), self.y1, self.y2)
}

///|
/// Return the curve as a first-class easing function.
pub fn Bezier::as_easing(self : Bezier) -> (Double) -> Double {
  fn(x) { self.sample(x) }
}

///|
/// Derivative dy/dx at a normalized time. A zero x slope returns zero.
pub fn Bezier::derivative(self : Bezier, x : Double) -> Double {
  let t = self.solve_time(x)
  let dx = bezier_slope(t, self.x1, self.x2)
  if dx.abs() < 0.0000000001 {
    0.0
  } else {
    bezier_slope(t, self.y1, self.y2) / dx
  }
}

///|
pub fn Bezier::sample_many(
  self : Bezier,
  count : Int,
) -> Array[Double] raise MotionError {
  if count < 2 {
    raise MotionError::InvalidSampleCount(count)
  }
  let values : Array[Double] = []
  for i in 0..<count {
    values.push(self.sample(i.to_double() / (count - 1).to_double()))
  }
  values
}
