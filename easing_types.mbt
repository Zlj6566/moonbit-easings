///|
/// Families of easing curves used by a motion timeline.
pub(all) enum EasingId {
  Linear
  QuadIn
  QuadOut
  QuadInOut
  CubicIn
  CubicOut
  CubicInOut
  QuartIn
  QuartOut
  QuartInOut
  QuintIn
  QuintOut
  QuintInOut
  SineIn
  SineOut
  SineInOut
  ExpoIn
  ExpoOut
  ExpoInOut
  CircIn
  CircOut
  CircInOut
  BackIn
  BackOut
  BackInOut
  ElasticIn
  ElasticOut
  ElasticInOut
  BounceIn
  BounceOut
  BounceInOut
} derive(Eq, Debug)

///|
/// Extrapolation policy for a keyframe track or a tween.
pub(all) enum Extrapolation {
  Clamp
  Repeat
  Mirror
  Continue
} derive(Eq, Debug)

///|
/// A compact sample of a scalar motion function.
pub(all) struct MotionSample {
  time : Double
  value : Double
  velocity : Double
  acceleration : Double
} derive(Debug)

///|
pub fn MotionSample::value(self : MotionSample) -> Double {
  self.value
}

///|
pub fn MotionSample::velocity(self : MotionSample) -> Double {
  self.velocity
}

///|
pub fn MotionSample::acceleration(self : MotionSample) -> Double {
  self.acceleration
}
