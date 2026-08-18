///|
/// Numerically estimate a first derivative without allocating a sample buffer.
pub fn derivative_of(
  func : (Double) -> Double,
  t : Double,
  step? : Double = 0.000001,
) -> Double {
  let width = if step <= 0.0 { 0.000001 } else { step }
  let left = clamp(t - width, 0.0, 1.0)
  let right = clamp(t + width, 0.0, 1.0)
  if right == left {
    0.0
  } else {
    (func(right) - func(left)) / (right - left)
  }
}

///|
fn derivative_power(t : Double, exponent : Double) -> Double {
  if t <= 0.0 && exponent < 1.0 {
    0.0
  } else {
    exponent * power(t, exponent - 1.0)
  }
}

///|
fn derivative_bounce_out(t : Double) -> Double {
  let n1 = 7.5625
  let d1 = 2.75
  if t < 1.0 / d1 {
    2.0 * n1 * t
  } else if t < 2.0 / d1 {
    2.0 * n1 * (t - 1.5 / d1)
  } else if t < 2.5 / d1 {
    2.0 * n1 * (t - 2.25 / d1)
  } else {
    2.0 * n1 * (t - 2.625 / d1)
  }
}

///|
/// First derivative of a built-in easing curve on normalized time.
pub fn EasingId::derivative(self : EasingId, t : Double) -> Double {
  let x = clamp01(t)
  match self {
    Linear => 1.0
    QuadIn => 2.0 * x
    QuadOut => 2.0 - 2.0 * x
    QuadInOut => if x < 0.5 { 4.0 * x } else { 4.0 - 4.0 * x }
    CubicIn => 3.0 * square(x)
    CubicOut => 3.0 * square(1.0 - x)
    CubicInOut =>
      if x < 0.5 {
        12.0 * square(x)
      } else {
        12.0 * square(1.0 - x)
      }
    QuartIn => derivative_power(x, 4.0)
    QuartOut => derivative_power(1.0 - x, 4.0)
    QuartInOut =>
      if x < 0.5 {
        4.0 * derivative_power(2.0 * x, 4.0)
      } else {
        4.0 * derivative_power(2.0 - 2.0 * x, 4.0)
      }
    QuintIn => derivative_power(x, 5.0)
    QuintOut => derivative_power(1.0 - x, 5.0)
    QuintInOut =>
      if x < 0.5 {
        5.0 * derivative_power(2.0 * x, 5.0)
      } else {
        5.0 * derivative_power(2.0 - 2.0 * x, 5.0)
      }
    SineIn => @math.sin(x * @math.PI / 2.0) * @math.PI / 2.0
    SineOut => @math.cos(x * @math.PI / 2.0) * @math.PI / 2.0
    SineInOut => @math.sin(x * @math.PI) * @math.PI / 2.0
    ExpoIn => 10.0 * @math.ln(2.0) * power(2.0, 10.0 * (x - 1.0))
    ExpoOut => 10.0 * @math.ln(2.0) * power(2.0, -10.0 * x)
    ExpoInOut =>
      if x < 0.5 {
        10.0 * @math.ln(2.0) * power(2.0, 20.0 * x - 10.0)
      } else {
        10.0 * @math.ln(2.0) * power(2.0, -20.0 * x + 10.0)
      }
    CircIn => if x >= 1.0 { 0.0 } else { x / (1.0 - square(x)).sqrt() }
    CircOut =>
      if x <= 0.0 {
        0.0
      } else {
        (1.0 - x) / (1.0 - square(x - 1.0)).sqrt()
      }
    CircInOut => derivative_of(fn(value) { self.apply(value) }, x)
    BackIn => derivative_of(fn(value) { back_in(value) }, x)
    BackOut => derivative_of(fn(value) { back_out(value) }, x)
    BackInOut => derivative_of(fn(value) { back_in_out(value) }, x)
    ElasticIn => derivative_of(fn(value) { elastic_in(value) }, x)
    ElasticOut => derivative_of(fn(value) { elastic_out(value) }, x)
    ElasticInOut => derivative_of(fn(value) { elastic_in_out(value) }, x)
    BounceIn => -derivative_bounce_out(1.0 - x)
    BounceOut => derivative_bounce_out(x)
    BounceInOut =>
      if x < 0.5 {
        derivative_bounce_out(1.0 - 2.0 * x)
      } else {
        derivative_bounce_out(2.0 * x - 1.0)
      }
  }
}

///|
pub fn Curve::derivative(self : Curve, t : Double) -> Double {
  match self {
    Builtin(id) => id.derivative(t)
    CubicBezier(curve) => curve.derivative(t)
  }
}

///|
pub fn Tween::velocity_at(self : Tween, time : Double) -> Double {
  self.sample_motion(time).velocity()
}
