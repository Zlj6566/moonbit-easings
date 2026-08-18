///|
/// Reverse the direction of a cubic timing curve.
pub fn Bezier::reversed(self : Bezier) -> Bezier {
  try! Bezier::new(
    1.0 - self.x2,
    1.0 - self.y2,
    1.0 - self.x1,
    1.0 - self.y1,
    sample_count=self.sample_values.length(),
  )
}

///|
/// A coarse arc-length estimate in parameter space, useful for diagnostics.
pub fn Bezier::approximate_length(self : Bezier, segments : Int) -> Double {
  if segments <= 0 {
    0.0
  } else {
    let mut total = 0.0
    let mut last_x = 0.0
    let mut last_y = 0.0
    for i in 1..<=segments {
      let t = i.to_double() / segments.to_double()
      let x = bezier_value(t, self.x1, self.x2)
      let y = bezier_value(t, self.y1, self.y2)
      total = total + @math.hypot(x - last_x, y - last_y)
      last_x = x
      last_y = y
    }
    total
  }
}

///|
/// Return the maximum absolute difference between this curve and a reference.
pub fn Bezier::max_error(
  self : Bezier,
  reference : (Double) -> Double,
  samples : Int,
) -> Double {
  if samples <= 0 {
    0.0
  } else {
    let mut result = 0.0
    for i in 0..<=samples {
      let x = i.to_double() / samples.to_double()
      let error = (self.sample(x) - reference(x)).abs()
      if error > result {
        result = error
      }
    }
    result
  }
}
