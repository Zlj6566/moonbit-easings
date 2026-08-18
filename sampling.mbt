///|
/// Deterministic sampling window for rendering or offline export.
pub struct SamplingConfig {
  start : Double
  end : Double
  frame_rate : Double
  include_end : Bool
} derive(Debug)

///|
pub fn SamplingConfig::new(
  start : Double,
  end : Double,
  frame_rate : Double,
  include_end? : Bool = true,
) -> SamplingConfig raise MotionError {
  ensure_finite(start)
  ensure_finite(end)
  if end < start {
    raise MotionError::InvalidTime(end)
  }
  if frame_rate <= 0.0 || frame_rate.is_nan() || frame_rate.is_inf() {
    raise MotionError::InvalidFrameRate(frame_rate)
  }
  { start, end, frame_rate, include_end }
}

///|
pub fn SamplingConfig::start(self : SamplingConfig) -> Double {
  self.start
}

///|
pub fn SamplingConfig::end(self : SamplingConfig) -> Double {
  self.end
}

///|
pub fn SamplingConfig::frame_rate(self : SamplingConfig) -> Double {
  self.frame_rate
}

///|
pub fn SamplingConfig::frame_count(self : SamplingConfig) -> Int {
  let span = self.end - self.start
  let base = @math.floor(span * self.frame_rate).to_int()
  if self.include_end {
    base + 1
  } else {
    base
  }
}

///|
pub(all) struct SamplePoint {
  time : Double
  value : Double
  frame : Int
} derive(Debug)

///|
pub fn SamplePoint::time(self : SamplePoint) -> Double {
  self.time
}

///|
pub fn SamplePoint::value(self : SamplePoint) -> Double {
  self.value
}

///|
pub fn SamplePoint::frame(self : SamplePoint) -> Int {
  self.frame
}

///|
pub fn sample_tween(
  tween : Tween,
  config : SamplingConfig,
) -> Array[SamplePoint] {
  let count = config.frame_count()
  let result : Array[SamplePoint] = []
  if count <= 0 {
    return result
  }
  let step = 1.0 / config.frame_rate
  for frame in 0..<count {
    let time = if config.include_end && frame == count - 1 {
      config.end
    } else {
      config.start + frame.to_double() * step
    }
    result.push({ time, value: tween.value_at(time), frame })
  }
  result
}

///|
pub fn sample_track(
  track : ScalarTrack,
  config : SamplingConfig,
  mode? : Extrapolation = Clamp,
) -> Array[SamplePoint] {
  let count = config.frame_count()
  let result : Array[SamplePoint] = []
  if count <= 0 {
    return result
  }
  let step = 1.0 / config.frame_rate
  for frame in 0..<count {
    let time = if config.include_end && frame == count - 1 {
      config.end
    } else {
      config.start + frame.to_double() * step
    }
    result.push({ time, value: track.sample(time, mode~), frame })
  }
  result
}

///|
/// Sample a function on a uniform grid. This is useful for waveform and curve previews.
pub fn sample_function(
  func : (Double) -> Double,
  start : Double,
  end : Double,
  count : Int,
) -> Array[SamplePoint] raise MotionError {
  if count < 2 {
    raise MotionError::InvalidSampleCount(count)
  }
  let result : Array[SamplePoint] = []
  for frame in 0..<count {
    let ratio = frame.to_double() / (count - 1).to_double()
    let time = start + (end - start) * ratio
    result.push({ time, value: func(time), frame })
  }
  result
}

///|
/// Downsample a sample array by keeping every nth frame and preserving the end.
pub fn decimate_samples(
  samples : Array[SamplePoint],
  stride : Int,
) -> Array[SamplePoint] {
  if stride <= 1 || samples.length() <= 2 {
    return samples.copy()
  }
  let result : Array[SamplePoint] = []
  for i in 0..<samples.length() {
    if i % stride == 0 || i == samples.length() - 1 {
      result.push(samples[i])
    }
  }
  result
}
