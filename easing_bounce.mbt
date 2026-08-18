///|
/// Piecewise quadratic bounce used for UI and game motion.
pub fn bounce_out(t : Double) -> Double {
  let n1 = 7.5625
  let d1 = 2.75
  if t < 1.0 / d1 {
    n1 * t * t
  } else if t < 2.0 / d1 {
    let x = t - 1.5 / d1
    n1 * x * x + 0.75
  } else if t < 2.5 / d1 {
    let x = t - 2.25 / d1
    n1 * x * x + 0.9375
  } else {
    let x = t - 2.625 / d1
    n1 * x * x + 0.984375
  }
}

///|
pub fn bounce_in(t : Double) -> Double {
  1.0 - bounce_out(1.0 - t)
}

///|
pub fn bounce_in_out(t : Double) -> Double {
  if t < 0.5 {
    (1.0 - bounce_out(1.0 - 2.0 * t)) / 2.0
  } else {
    (1.0 + bounce_out(2.0 * t - 1.0)) / 2.0
  }
}
