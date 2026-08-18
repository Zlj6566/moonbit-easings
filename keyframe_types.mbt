///|
/// A curve selector stored on a keyframe transition.
pub(all) enum Curve {
  Builtin(EasingId)
  CubicBezier(Bezier)
} derive(Debug)

///|
pub fn Curve::builtin(id : EasingId) -> Curve {
  Builtin(id)
}

///|
pub fn Curve::bezier(curve : Bezier) -> Curve {
  CubicBezier(curve)
}

///|
pub fn Curve::apply(self : Curve, t : Double) -> Double {
  match self {
    Builtin(id) => id.apply(t)
    CubicBezier(curve) => curve.sample(t)
  }
}

///|
/// A scalar keyframe. Its curve controls the segment beginning at this frame.
pub struct Keyframe {
  time : Double
  value : Double
  curve : Curve
} derive(Debug)

///|
pub fn keyframe(
  time : Double,
  value : Double,
  curve? : Curve = Curve::builtin(Linear),
) -> Keyframe raise MotionError {
  ensure_finite(time)
  ensure_finite(value)
  { time, value, curve }
}

///|
pub fn Keyframe::time(self : Keyframe) -> Double {
  self.time
}

///|
pub fn Keyframe::value(self : Keyframe) -> Double {
  self.value
}

///|
pub fn Keyframe::curve(self : Keyframe) -> Curve {
  self.curve
}

///|
/// A validated, immutable-at-the-API scalar track.
pub struct ScalarTrack {
  frames : Array[Keyframe]
} derive(Debug)

///|
pub fn ScalarTrack::keyframes(self : ScalarTrack) -> Array[Keyframe] {
  self.frames.copy()
}

///|
pub fn ScalarTrack::length(self : ScalarTrack) -> Int {
  self.frames.length()
}

///|
pub fn ScalarTrack::start_time(self : ScalarTrack) -> Double {
  self.frames[0].time
}

///|
pub fn ScalarTrack::end_time(self : ScalarTrack) -> Double {
  self.frames[self.frames.length() - 1].time
}

///|
pub fn ScalarTrack::duration(self : ScalarTrack) -> Double {
  self.end_time() - self.start_time()
}
