///|
/// Controls recursive subdivision of a scalar motion signal.
pub struct AdaptiveSamplingConfig {
  tolerance : Double
  max_depth : Int
  max_samples : Int
} derive(Debug)

///|
pub fn AdaptiveSamplingConfig::new(
  tolerance : Double,
  max_depth? : Int = 10,
  max_samples? : Int = 4097,
) -> AdaptiveSamplingConfig raise MotionError {
  ensure_finite(tolerance)
  if tolerance <= 0.0 {
    raise MotionError::InvalidThreshold(tolerance)
  }
  if max_depth < 1 {
    raise MotionError::InvalidSegmentCount(max_depth)
  }
  if max_samples < 2 {
    raise MotionError::InvalidSampleCount(max_samples)
  }
  { tolerance, max_depth, max_samples }
}

///|
pub fn AdaptiveSamplingConfig::tolerance(
  self : AdaptiveSamplingConfig,
) -> Double {
  self.tolerance
}

///|
pub fn AdaptiveSamplingConfig::max_depth(self : AdaptiveSamplingConfig) -> Int {
  self.max_depth
}

///|
pub fn AdaptiveSamplingConfig::max_samples(
  self : AdaptiveSamplingConfig,
) -> Int {
  self.max_samples
}

///|
/// A scalar sample with a subdivision depth for diagnostics and renderers.
pub(all) struct AdaptiveSamplePoint {
  time : Double
  value : Double
  depth : Int
} derive(Debug)

///|
pub fn AdaptiveSamplePoint::time(self : AdaptiveSamplePoint) -> Double {
  self.time
}

///|
pub fn AdaptiveSamplePoint::value(self : AdaptiveSamplePoint) -> Double {
  self.value
}

///|
pub fn AdaptiveSamplePoint::depth(self : AdaptiveSamplePoint) -> Int {
  self.depth
}

///|
/// Result metadata for an adaptive sample pass.
pub(all) struct AdaptiveSampleResult {
  points : Array[AdaptiveSamplePoint]
  accepted_segments : Int
  rejected_segments : Int
  maximum_error : Double
} derive(Debug)

///|
pub fn AdaptiveSampleResult::points(
  self : AdaptiveSampleResult,
) -> Array[AdaptiveSamplePoint] {
  self.points.copy()
}

///|
pub fn AdaptiveSampleResult::accepted_segments(
  self : AdaptiveSampleResult,
) -> Int {
  self.accepted_segments
}

///|
pub fn AdaptiveSampleResult::rejected_segments(
  self : AdaptiveSampleResult,
) -> Int {
  self.rejected_segments
}

///|
pub fn AdaptiveSampleResult::maximum_error(
  self : AdaptiveSampleResult,
) -> Double {
  self.maximum_error
}

///|
fn point_distance_to_chord(
  time : Double,
  value : Double,
  left_time : Double,
  left_value : Double,
  right_time : Double,
  right_value : Double,
) -> Double {
  let span = right_time - left_time
  if span == 0.0 {
    (value - left_value).abs()
  } else {
    let ratio = (time - left_time) / span
    let chord = left_value + (right_value - left_value) * ratio
    (value - chord).abs()
  }
}

///|
fn append_adaptive_segment(
  func : (Double) -> Double,
  left_time : Double,
  left_value : Double,
  right_time : Double,
  right_value : Double,
  depth : Int,
  config : AdaptiveSamplingConfig,
  points : Array[AdaptiveSamplePoint],
  counters : Array[Int],
  maximum_error : Array[Double],
) -> Unit {
  if points.length() >= config.max_samples() - 1 {
    points.push({ time: right_time, value: right_value, depth })
    counters[0] = counters[0] + 1
    return
  }
  let middle_time = (left_time + right_time) / 2.0
  let middle_value = func(middle_time)
  let error = point_distance_to_chord(
    middle_time, middle_value, left_time, left_value, right_time, right_value,
  )
  maximum_error[0] = maximum_error[0].max(error)
  if error <= config.tolerance() || depth >= config.max_depth() {
    points.push({ time: right_time, value: right_value, depth })
    counters[0] = counters[0] + 1
  } else {
    counters[1] = counters[1] + 1
    append_adaptive_segment(
      func,
      left_time,
      left_value,
      middle_time,
      middle_value,
      depth + 1,
      config,
      points,
      counters,
      maximum_error,
    )
    append_adaptive_segment(
      func,
      middle_time,
      middle_value,
      right_time,
      right_value,
      depth + 1,
      config,
      points,
      counters,
      maximum_error,
    )
  }
}

///|
/// Recursively sample a scalar curve where curvature exceeds a tolerance.
pub fn adaptive_sample(
  func : (Double) -> Double,
  start : Double,
  end : Double,
  config : AdaptiveSamplingConfig,
) -> AdaptiveSampleResult raise MotionError {
  ensure_finite(start)
  ensure_finite(end)
  if end <= start {
    raise MotionError::InvalidTime(end)
  }
  let left_value = func(start)
  let right_value = func(end)
  let points : Array[AdaptiveSamplePoint] = [
    { time: start, value: left_value, depth: 0 },
  ]
  let counters = [0, 0]
  let maximum_error = [0.0]
  append_adaptive_segment(
    func, start, left_value, end, right_value, 0, config, points, counters, maximum_error,
  )
  {
    points,
    accepted_segments: counters[0],
    rejected_segments: counters[1],
    maximum_error: maximum_error[0],
  }
}

///|
pub fn adaptive_sample_tween(
  tween : Tween,
  start : Double,
  end : Double,
  config : AdaptiveSamplingConfig,
) -> AdaptiveSampleResult raise MotionError {
  adaptive_sample(fn(time) { tween.value_at(time) }, start, end, config)
}

///|
/// Linear interpolation over a sorted adaptive sample.
pub fn interpolate_samples(
  samples : Array[AdaptiveSamplePoint],
  time : Double,
) -> Double {
  if samples.length() == 0 {
    return 0.0
  }
  if time <= samples[0].time {
    return samples[0].value
  }
  let last = samples.length() - 1
  if time >= samples[last].time {
    return samples[last].value
  }
  for index in 0..<last {
    let left = samples[index]
    let right = samples[index + 1]
    if time <= right.time {
      let ratio = (time - left.time) / (right.time - left.time)
      return left.value + (right.value - left.value) * ratio
    }
  }
  samples[last].value
}

///|
/// Resample an adaptive result at a fixed number of output points.
pub fn resample_adaptive(
  result : AdaptiveSampleResult,
  count : Int,
) -> Array[SamplePoint] raise MotionError {
  if count < 2 {
    raise MotionError::InvalidSampleCount(count)
  }
  let source = result.points()
  let output : Array[SamplePoint] = []
  if source.length() == 0 {
    return output
  }
  let start = source[0].time
  let finish = source[source.length() - 1].time
  for index in 0..<count {
    let ratio = index.to_double() / (count - 1).to_double()
    let time = start + (finish - start) * ratio
    output.push({ time, value: interpolate_samples(source, time), frame: index })
  }
  output
}

///|
/// Approximate the integral of a sampled scalar signal with trapezoids.
pub fn integrate_samples(samples : Array[SamplePoint]) -> Double {
  if samples.length() < 2 {
    return 0.0
  }
  let mut total = 0.0
  for index in 0..<(samples.length() - 1) {
    let left = samples[index]
    let right = samples[index + 1]
    total = total + (right.time - left.time) * (left.value + right.value) / 2.0
  }
  total
}

///|
/// Return the largest absolute error between two aligned sample arrays.
pub fn maximum_sample_error(
  first : Array[SamplePoint],
  second : Array[SamplePoint],
) -> Double {
  let count = first.length().min(second.length())
  let mut maximum = 0.0
  for index in 0..<count {
    maximum = maximum.max((first[index].value - second[index].value).abs())
  }
  maximum
}

///|
/// Find crossings of a scalar threshold, using linear interpolation in each span.
pub fn threshold_crossings(
  samples : Array[SamplePoint],
  threshold : Double,
) -> Array[Double] raise MotionError {
  ensure_finite(threshold)
  let result : Array[Double] = []
  if samples.length() < 2 {
    return result
  }
  for index in 0..<(samples.length() - 1) {
    let left = samples[index]
    let right = samples[index + 1]
    let left_delta = left.value - threshold
    let right_delta = right.value - threshold
    if left_delta == 0.0 {
      result.push(left.time)
    } else if left_delta * right_delta < 0.0 {
      let ratio = left_delta.abs() / (left_delta.abs() + right_delta.abs())
      result.push(left.time + (right.time - left.time) * ratio)
    }
  }
  if samples[samples.length() - 1].value == threshold {
    result.push(samples[samples.length() - 1].time)
  }
  result
}

///|
/// Keep local maxima with a configurable minimum prominence.
pub fn local_maxima(
  samples : Array[SamplePoint],
  prominence : Double,
) -> Array[SamplePoint] raise MotionError {
  ensure_finite(prominence)
  if prominence < 0.0 {
    raise MotionError::InvalidThreshold(prominence)
  }
  let result : Array[SamplePoint] = []
  if samples.length() < 3 {
    return result
  }
  for index in 1..<(samples.length() - 1) {
    let before = samples[index - 1]
    let current = samples[index]
    let after = samples[index + 1]
    if current.value >= before.value + prominence &&
      current.value >= after.value + prominence {
      result.push(current)
    }
  }
  result
}

///|
/// Remove samples that are within a scalar tolerance of their chord.
pub fn simplify_samples(
  samples : Array[SamplePoint],
  tolerance : Double,
) -> Array[SamplePoint] raise MotionError {
  ensure_finite(tolerance)
  if tolerance < 0.0 {
    raise MotionError::InvalidThreshold(tolerance)
  }
  if samples.length() <= 2 {
    return samples.copy()
  }
  let keep = Array::make(samples.length(), false)
  keep[0] = true
  keep[samples.length() - 1] = true
  simplify_range(samples, 0, samples.length() - 1, tolerance, keep)
  let result : Array[SamplePoint] = []
  for index in 0..<samples.length() {
    if keep[index] {
      result.push(samples[index])
    }
  }
  result
}

///|
fn simplify_range(
  samples : Array[SamplePoint],
  first : Int,
  last : Int,
  tolerance : Double,
  keep : Array[Bool],
) -> Unit {
  if last <= first + 1 {
    return
  }
  let left = samples[first]
  let right = samples[last]
  let mut best_index = -1
  let mut best_error = tolerance
  for index in (first + 1)..<last {
    let point = samples[index]
    let error = point_distance_to_chord(
      point.time,
      point.value,
      left.time,
      left.value,
      right.time,
      right.value,
    )
    if error > best_error {
      best_error = error
      best_index = index
    }
  }
  if best_index >= 0 {
    keep[best_index] = true
    simplify_range(samples, first, best_index, tolerance, keep)
    simplify_range(samples, best_index, last, tolerance, keep)
  }
}
