///|
/// Back easing with configurable overshoot.
pub fn back_in(t : Double, overshoot? : Double = 1.70158) -> Double {
  if t <= 0.0 || t >= 1.0 {
    t
  } else {
    t * t * ((overshoot + 1.0) * t - overshoot)
  }
}

///|
pub fn back_out(t : Double, overshoot? : Double = 1.70158) -> Double {
  if t <= 0.0 || t >= 1.0 {
    t
  } else {
    let x = t - 1.0
    x * x * ((overshoot + 1.0) * x + overshoot) + 1.0
  }
}

///|
pub fn back_in_out(t : Double, overshoot? : Double = 1.70158) -> Double {
  if t <= 0.0 || t >= 1.0 {
    t
  } else {
    let scaled = t * 2.0
    let amount = overshoot * 1.525
    if scaled < 1.0 {
      scaled * scaled * ((amount + 1.0) * scaled - amount) / 2.0
    } else {
      let x = scaled - 2.0
      (x * x * ((amount + 1.0) * x + amount) + 2.0) / 2.0
    }
  }
}

///|
fn elastic_phase(amplitude : Double, period : Double) -> Double {
  let safe_amplitude = if amplitude < 1.0 { 1.0 } else { amplitude }
  let safe_period = if period <= 0.0 { 0.3 } else { period }
  let ratio = 1.0 / safe_amplitude
  @math.asin(ratio) * safe_period / (2.0 * @math.PI)
}

///|
/// Elastic acceleration. Amplitude and period are normalized motion controls.
pub fn elastic_in(
  t : Double,
  amplitude? : Double = 1.0,
  period? : Double = 0.3,
) -> Double {
  if t <= 0.0 || t >= 1.0 {
    t
  } else {
    let safe_amplitude = if amplitude < 1.0 { 1.0 } else { amplitude }
    let phase = elastic_phase(amplitude, period)
    let x = t - 1.0
    -safe_amplitude *
    power(2.0, 10.0 * x) *
    @math.sin((x - phase) * (2.0 * @math.PI) / period)
  }
}

///|
pub fn elastic_out(
  t : Double,
  amplitude? : Double = 1.0,
  period? : Double = 0.3,
) -> Double {
  if t <= 0.0 || t >= 1.0 {
    t
  } else {
    let safe_amplitude = if amplitude < 1.0 { 1.0 } else { amplitude }
    let phase = elastic_phase(amplitude, period)
    safe_amplitude *
    power(2.0, -10.0 * t) *
    @math.sin((t - phase) * (2.0 * @math.PI) / period) +
    1.0
  }
}

///|
pub fn elastic_in_out(
  t : Double,
  amplitude? : Double = 1.0,
  period? : Double = 0.3,
) -> Double {
  if t <= 0.0 || t >= 1.0 {
    t
  } else if t < 0.5 {
    elastic_in(t * 2.0, amplitude~, period~) / 2.0
  } else {
    elastic_out(t * 2.0 - 1.0, amplitude~, period~) / 2.0 + 0.5
  }
}
