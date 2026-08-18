///|
/// Evaluate a built-in easing curve.
pub fn EasingId::apply(self : EasingId, t : Double) -> Double {
  let x = clamp01(t)
  match self {
    Linear => linear(x)
    QuadIn => quad_in(x)
    QuadOut => quad_out(x)
    QuadInOut => quad_in_out(x)
    CubicIn => cubic_in(x)
    CubicOut => cubic_out(x)
    CubicInOut => cubic_in_out(x)
    QuartIn => quart_in(x)
    QuartOut => quart_out(x)
    QuartInOut => quart_in_out(x)
    QuintIn => quint_in(x)
    QuintOut => quint_out(x)
    QuintInOut => quint_in_out(x)
    SineIn => sine_in(x)
    SineOut => sine_out(x)
    SineInOut => sine_in_out(x)
    ExpoIn => expo_in(x)
    ExpoOut => expo_out(x)
    ExpoInOut => expo_in_out(x)
    CircIn => circ_in(x)
    CircOut => circ_out(x)
    CircInOut => circ_in_out(x)
    BackIn => back_in(x)
    BackOut => back_out(x)
    BackInOut => back_in_out(x)
    ElasticIn => elastic_in(x)
    ElasticOut => elastic_out(x)
    ElasticInOut => elastic_in_out(x)
    BounceIn => bounce_in(x)
    BounceOut => bounce_out(x)
    BounceInOut => bounce_in_out(x)
  }
}

///|
/// Return a first-class easing function for use in a sampler or a custom blend.
pub fn easing(id : EasingId) -> (Double) -> Double {
  fn(t) { id.apply(t) }
}

///|
/// Compose two curves. `outer(inner(t))` is evaluated without intermediate arrays.
pub fn compose(
  outer : (Double) -> Double,
  inner : (Double) -> Double,
) -> (Double) -> Double {
  fn(t) { outer(inner(t)) }
}

///|
/// Blend two curves with an amount in the closed interval [0, 1].
pub fn blend(
  first : (Double) -> Double,
  second : (Double) -> Double,
  amount~ : Double,
) -> (Double) -> Double {
  let weight = clamp01(amount)
  fn(t) { first(t) * (1.0 - weight) + second(t) * weight }
}

///|
/// Reflect a curve around the center point, useful for reversible UI motion.
pub fn mirror(ease : (Double) -> Double) -> (Double) -> Double {
  fn(t) { 1.0 - ease(1.0 - t) }
}

///|
/// Enumerate the built-ins in a stable order for editors and documentation.
pub fn all_easings() -> Array[EasingId] {
  [
    Linear,
    QuadIn,
    QuadOut,
    QuadInOut,
    CubicIn,
    CubicOut,
    CubicInOut,
    QuartIn,
    QuartOut,
    QuartInOut,
    QuintIn,
    QuintOut,
    QuintInOut,
    SineIn,
    SineOut,
    SineInOut,
    ExpoIn,
    ExpoOut,
    ExpoInOut,
    CircIn,
    CircOut,
    CircInOut,
    BackIn,
    BackOut,
    BackInOut,
    ElasticIn,
    ElasticOut,
    ElasticInOut,
    BounceIn,
    BounceOut,
    BounceInOut,
  ]
}
