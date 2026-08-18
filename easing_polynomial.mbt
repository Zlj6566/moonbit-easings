///|
/// Linear interpolation with no acceleration.
pub fn linear(t : Double) -> Double {
  t
}

///|
/// Quadratic acceleration.
pub fn quad_in(t : Double) -> Double {
  square(t)
}

///|
/// Quadratic deceleration.
pub fn quad_out(t : Double) -> Double {
  t * (2.0 - t)
}

///|
/// Quadratic acceleration followed by deceleration.
pub fn quad_in_out(t : Double) -> Double {
  ease_in_out_power(t, 2.0)
}

///|
/// Cubic acceleration.
pub fn cubic_in(t : Double) -> Double {
  cube(t)
}

///|
/// Cubic deceleration.
pub fn cubic_out(t : Double) -> Double {
  1.0 - cube(1.0 - t)
}

///|
/// Cubic acceleration followed by deceleration.
pub fn cubic_in_out(t : Double) -> Double {
  ease_in_out_power(t, 3.0)
}

///|
/// Quartic acceleration.
pub fn quart_in(t : Double) -> Double {
  ease_in_power(t, 4.0)
}

///|
/// Quartic deceleration.
pub fn quart_out(t : Double) -> Double {
  ease_out_power(t, 4.0)
}

///|
/// Quartic acceleration followed by deceleration.
pub fn quart_in_out(t : Double) -> Double {
  ease_in_out_power(t, 4.0)
}

///|
/// Quintic acceleration.
pub fn quint_in(t : Double) -> Double {
  ease_in_power(t, 5.0)
}

///|
/// Quintic deceleration.
pub fn quint_out(t : Double) -> Double {
  ease_out_power(t, 5.0)
}

///|
/// Quintic acceleration followed by deceleration.
pub fn quint_in_out(t : Double) -> Double {
  ease_in_out_power(t, 5.0)
}

///|
/// Polynomial easing with a caller-selected exponent.
pub fn polynomial_in(t : Double, exponent~ : Double) -> Double {
  ease_in_power(t, exponent)
}

///|
pub fn polynomial_out(t : Double, exponent~ : Double) -> Double {
  ease_out_power(t, exponent)
}

///|
pub fn polynomial_in_out(t : Double, exponent~ : Double) -> Double {
  ease_in_out_power(t, exponent)
}
