///|
fn square(value : Double) -> Double {
  value * value
}

///|
fn cube(value : Double) -> Double {
  value * value * value
}

///|
fn power(value : Double, exponent : Double) -> Double {
  @math.pow(value, exponent)
}

///|
fn ease_in_power(t : Double, exponent : Double) -> Double {
  power(t, exponent)
}

///|
fn ease_out_power(t : Double, exponent : Double) -> Double {
  1.0 - power(1.0 - t, exponent)
}

///|
fn ease_in_out_power(t : Double, exponent : Double) -> Double {
  let doubled = t * 2.0
  if doubled < 1.0 {
    power(doubled, exponent) / 2.0
  } else {
    (2.0 - power(2.0 - doubled, exponent)) / 2.0
  }
}

///|
fn ease_sine_in(t : Double) -> Double {
  if t <= 0.0 {
    0.0
  } else if t >= 1.0 {
    1.0
  } else {
    1.0 - @math.cos(t * @math.PI / 2.0)
  }
}

///|
fn ease_sine_out(t : Double) -> Double {
  if t <= 0.0 {
    0.0
  } else if t >= 1.0 {
    1.0
  } else {
    @math.sin(t * @math.PI / 2.0)
  }
}

///|
fn ease_sine_in_out(t : Double) -> Double {
  if t <= 0.0 {
    0.0
  } else if t >= 1.0 {
    1.0
  } else {
    (1.0 - @math.cos(t * @math.PI)) / 2.0
  }
}
