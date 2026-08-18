///|
/// Sine acceleration.
pub fn sine_in(t : Double) -> Double {
  ease_sine_in(t)
}

///|
/// Sine deceleration.
pub fn sine_out(t : Double) -> Double {
  ease_sine_out(t)
}

///|
/// Sine acceleration followed by deceleration.
pub fn sine_in_out(t : Double) -> Double {
  ease_sine_in_out(t)
}

///|
pub fn expo_in(t : Double) -> Double {
  if t <= 0.0 {
    0.0
  } else {
    power(2.0, 10.0 * (t - 1.0))
  }
}

///|
pub fn expo_out(t : Double) -> Double {
  if t >= 1.0 {
    1.0
  } else {
    1.0 - power(2.0, -10.0 * t)
  }
}

///|
pub fn expo_in_out(t : Double) -> Double {
  if t <= 0.0 || t >= 1.0 {
    t
  } else if t < 0.5 {
    power(2.0, 20.0 * t - 10.0) / 2.0
  } else {
    (2.0 - power(2.0, -20.0 * t + 10.0)) / 2.0
  }
}

///|
pub fn circ_in(t : Double) -> Double {
  1.0 - (1.0 - square(t)).sqrt()
}

///|
pub fn circ_out(t : Double) -> Double {
  (1.0 - square(t - 1.0)).sqrt()
}

///|
pub fn circ_in_out(t : Double) -> Double {
  if t < 0.5 {
    (1.0 - (1.0 - square(2.0 * t)).sqrt()) / 2.0
  } else {
    ((1.0 - square(2.0 * t - 2.0)).sqrt() + 1.0) / 2.0
  }
}
