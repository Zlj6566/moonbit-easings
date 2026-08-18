///|
/// A color stop whose curve controls the transition to the next stop.
pub struct GradientStop {
  position : Double
  color : Rgba
  curve : Curve
} derive(Debug)

///|
pub fn gradient_stop(
  position : Double,
  color : Rgba,
  curve? : Curve = Curve::builtin(Linear),
) -> GradientStop raise MotionError {
  ensure_finite(position)
  if position < 0.0 || position > 1.0 {
    raise MotionError::InvalidTime(position)
  }
  { position, color, curve }
}

///|
pub fn GradientStop::position(self : GradientStop) -> Double {
  self.position
}

///|
pub fn GradientStop::color(self : GradientStop) -> Rgba {
  self.color
}

///|
pub fn GradientStop::curve(self : GradientStop) -> Curve {
  self.curve
}

///|
/// A validated one-dimensional color gradient for UI and media rendering.
pub struct ColorGradient {
  stops : Array[GradientStop]
  premultiplied : Bool
} derive(Debug)

///|
pub fn ColorGradient::new(
  stops : Array[GradientStop],
  premultiplied? : Bool = false,
) -> ColorGradient raise MotionError {
  if stops.length() == 0 {
    raise MotionError::EmptyTrack
  }
  for i in 1..<stops.length() {
    if stops[i].position <= stops[i - 1].position {
      raise MotionError::NonIncreasingKeyframe(
        stops[i - 1].position,
        stops[i].position,
      )
    }
  }
  { stops: stops.copy(), premultiplied }
}

///|
pub fn ColorGradient::stops(self : ColorGradient) -> Array[GradientStop] {
  self.stops.copy()
}

///|
pub fn ColorGradient::length(self : ColorGradient) -> Int {
  self.stops.length()
}

///|
pub fn ColorGradient::premultiplied(self : ColorGradient) -> Bool {
  self.premultiplied
}

///|
pub fn ColorGradient::start(self : ColorGradient) -> Double {
  self.stops[0].position
}

///|
pub fn ColorGradient::end(self : ColorGradient) -> Double {
  self.stops[self.stops.length() - 1].position
}

///|
fn ColorGradient::segment(self : ColorGradient, position : Double) -> Int {
  let last = self.stops.length() - 1
  if position <= self.stops[0].position {
    return 0
  }
  if position >= self.stops[last].position {
    return last - 1
  }
  for index in 0..<last {
    if position <= self.stops[index + 1].position {
      return index
    }
  }
  last - 1
}

///|
/// Sample the gradient. Values outside its declared range are clamped.
pub fn ColorGradient::sample(self : ColorGradient, position : Double) -> Rgba {
  let first = self.stops[0]
  let last = self.stops[self.stops.length() - 1]
  if self.stops.length() == 1 || position <= first.position {
    return first.color
  }
  if position >= last.position {
    return last.color
  }
  let index = self.segment(position)
  let left = self.stops[index]
  let right = self.stops[index + 1]
  let ratio = (position - left.position) / (right.position - left.position)
  interpolate_rgba(
    left.color,
    right.color,
    left.curve.apply(ratio),
    premultiplied=self.premultiplied,
  )
}

///|
pub fn ColorGradient::sample_many(
  self : ColorGradient,
  count : Int,
) -> Array[Rgba] raise MotionError {
  if count < 2 {
    raise MotionError::InvalidSampleCount(count)
  }
  let values : Array[Rgba] = []
  for index in 0..<count {
    let ratio = index.to_double() / (count - 1).to_double()
    values.push(self.sample(ratio))
  }
  values
}

///|
/// Return a gradient with the stop order and transition directions reversed.
pub fn ColorGradient::reversed(self : ColorGradient) -> ColorGradient {
  let reversed : Array[GradientStop] = []
  for index in 0..<self.stops.length() {
    let source = self.stops[self.stops.length() - 1 - index]
    let position = 1.0 - source.position
    let curve = match source.curve {
      Builtin(id) => Curve::builtin(reverse_easing_id(id))
      CubicBezier(bezier) => Curve::bezier(bezier.reversed())
    }
    reversed.push({ position, color: source.color, curve })
  }
  { stops: reversed, premultiplied: self.premultiplied }
}

///|
fn reverse_easing_id(id : EasingId) -> EasingId {
  match id {
    Linear => Linear
    QuadIn => QuadOut
    QuadOut => QuadIn
    QuadInOut => QuadInOut
    CubicIn => CubicOut
    CubicOut => CubicIn
    CubicInOut => CubicInOut
    QuartIn => QuartOut
    QuartOut => QuartIn
    QuartInOut => QuartInOut
    QuintIn => QuintOut
    QuintOut => QuintIn
    QuintInOut => QuintInOut
    SineIn => SineOut
    SineOut => SineIn
    SineInOut => SineInOut
    ExpoIn => ExpoOut
    ExpoOut => ExpoIn
    ExpoInOut => ExpoInOut
    CircIn => CircOut
    CircOut => CircIn
    CircInOut => CircInOut
    BackIn => BackOut
    BackOut => BackIn
    BackInOut => BackInOut
    ElasticIn => ElasticOut
    ElasticOut => ElasticIn
    ElasticInOut => ElasticInOut
    BounceIn => BounceOut
    BounceOut => BounceIn
    BounceInOut => BounceInOut
  }
}

///|
/// A builder for gradients assembled by an editor or an importer.
pub struct GradientBuilder {
  stops : Array[GradientStop]
  premultiplied : Bool
}

///|
pub fn GradientBuilder::new(premultiplied? : Bool = false) -> GradientBuilder {
  { stops: [], premultiplied }
}

///|
pub fn GradientBuilder::add(
  self : GradientBuilder,
  stop : GradientStop,
) -> Unit {
  self.stops.push(stop)
  self.stops.sort_by(fn(left, right) { left.position.compare(right.position) })
}

///|
pub fn GradientBuilder::remove_at(
  self : GradientBuilder,
  index : Int,
) -> GradientStop? {
  if index < 0 || index >= self.stops.length() {
    None
  } else {
    Some(self.stops.remove(index))
  }
}

///|
pub fn GradientBuilder::build(
  self : GradientBuilder,
) -> ColorGradient raise MotionError {
  ColorGradient::new(self.stops, premultiplied=self.premultiplied)
}
