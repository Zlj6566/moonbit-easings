///|
/// Errors raised while constructing or validating motion primitives.
pub(all) suberror MotionError {
  InvalidBezierX(Double, Double)
  InvalidSampleCount(Int)
  InvalidTime(Double)
  InvalidDuration(Double)
  InvalidDelay(Double)
  InvalidRepeatCount(Int)
  EmptyTrack
  NonIncreasingKeyframe(Double, Double)
  InvalidFrameRate(Double)
  InvalidPointCount(Int)
  InvalidTension(Double)
  InvalidSegmentCount(Int)
  InvalidThreshold(Double)
  InvalidMarkerName
  InvalidChannelName
  InvalidRetimeSegment
  InvalidStateName
}

///|
fn ensure_finite(value : Double) -> Unit raise MotionError {
  if value.is_nan() || value.is_inf() {
    raise MotionError::InvalidTime(value)
  }
}

///|
pub fn clamp01(value : Double) -> Double {
  if value <= 0.0 {
    0.0
  } else if value >= 1.0 {
    1.0
  } else {
    value
  }
}

///|
fn clamp(value : Double, lower : Double, upper : Double) -> Double {
  if value <= lower {
    lower
  } else if value >= upper {
    upper
  } else {
    value
  }
}
