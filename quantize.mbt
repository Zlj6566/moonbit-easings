///|
/// Frame clock for deterministic media time conversion.
pub struct FrameClock {
  frame_rate : Double
  origin : Double
} derive(Debug)

///|
pub fn FrameClock::new(
  frame_rate : Double,
  origin? : Double = 0.0,
) -> FrameClock raise MotionError {
  if frame_rate <= 0.0 || frame_rate.is_nan() || frame_rate.is_inf() {
    raise MotionError::InvalidFrameRate(frame_rate)
  }
  ensure_finite(origin)
  { frame_rate, origin }
}

///|
pub fn FrameClock::frame_rate(self : FrameClock) -> Double {
  self.frame_rate
}

///|
pub fn FrameClock::seconds_to_frame(self : FrameClock, seconds : Double) -> Int {
  @math.round((seconds - self.origin) * self.frame_rate).to_int()
}

///|
pub fn FrameClock::frame_to_seconds(self : FrameClock, frame : Int) -> Double {
  self.origin + frame.to_double() / self.frame_rate
}

///|
pub fn FrameClock::quantize(self : FrameClock, seconds : Double) -> Double {
  self.frame_to_seconds(self.seconds_to_frame(seconds))
}

///|
pub fn FrameClock::frame_times(
  self : FrameClock,
  first_frame : Int,
  last_frame : Int,
) -> Array[Double] {
  let result : Array[Double] = []
  if last_frame < first_frame {
    return result
  }
  for frame in first_frame..<=last_frame {
    result.push(self.frame_to_seconds(frame))
  }
  result
}

///|
/// Beat-based timing helper for music and rhythm-driven interactions.
pub struct Tempo {
  beats_per_minute : Double
  beat_offset : Double
} derive(Debug)

///|
pub fn Tempo::new(
  bpm : Double,
  beat_offset? : Double = 0.0,
) -> Tempo raise MotionError {
  if bpm <= 0.0 || bpm.is_nan() || bpm.is_inf() {
    raise MotionError::InvalidTime(bpm)
  }
  ensure_finite(beat_offset)
  { beats_per_minute: bpm, beat_offset }
}

///|
pub fn Tempo::beat_duration(self : Tempo) -> Double {
  60.0 / self.beats_per_minute
}

///|
pub fn Tempo::beats_to_seconds(self : Tempo, beats : Double) -> Double {
  self.beat_offset + beats * self.beat_duration()
}

///|
pub fn Tempo::seconds_to_beats(self : Tempo, seconds : Double) -> Double {
  (seconds - self.beat_offset) / self.beat_duration()
}

///|
pub fn quantize_to_grid(time : Double, step : Double) -> Double {
  if step <= 0.0 {
    time
  } else {
    @math.round(time / step) * step
  }
}
