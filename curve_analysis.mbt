///|
/// A sample enriched with first and second derivative estimates.
pub(all) struct CurveAnalysisPoint {
  time : Double
  value : Double
  velocity : Double
  acceleration : Double
  normalized_value : Double
} derive(Debug)

///|
pub fn CurveAnalysisPoint::time(self : CurveAnalysisPoint) -> Double {
  self.time
}

///|
pub fn CurveAnalysisPoint::value(self : CurveAnalysisPoint) -> Double {
  self.value
}

///|
pub fn CurveAnalysisPoint::velocity(self : CurveAnalysisPoint) -> Double {
  self.velocity
}

///|
pub fn CurveAnalysisPoint::acceleration(self : CurveAnalysisPoint) -> Double {
  self.acceleration
}

///|
pub fn CurveAnalysisPoint::normalized_value(
  self : CurveAnalysisPoint,
) -> Double {
  self.normalized_value
}

///|
pub(all) enum CurveMonotonicity {
  Increasing
  Decreasing
  Constant
  Mixed
} derive(Eq, Debug)

///|
pub fn analyze_samples(
  samples : Array[SamplePoint],
) -> Array[CurveAnalysisPoint] {
  let result : Array[CurveAnalysisPoint] = []
  if samples.length() == 0 {
    return result
  }
  let mut minimum = samples[0].value
  let mut maximum = samples[0].value
  for sample in samples {
    minimum = minimum.min(sample.value)
    maximum = maximum.max(sample.value)
  }
  let span = maximum - minimum
  for index in 0..<samples.length() {
    let current = samples[index]
    let before = samples[index.max(1) - 1]
    let after = samples[(index + 1).min(samples.length() - 1)]
    let delta_time = after.time - before.time
    let velocity = if delta_time == 0.0 {
      0.0
    } else {
      (after.value - before.value) / delta_time
    }
    let left_delta = current.time - before.time
    let right_delta = after.time - current.time
    let left_velocity = if left_delta == 0.0 {
      velocity
    } else {
      (current.value - before.value) / left_delta
    }
    let right_velocity = if right_delta == 0.0 {
      velocity
    } else {
      (after.value - current.value) / right_delta
    }
    let acceleration = if delta_time == 0.0 {
      0.0
    } else {
      (right_velocity - left_velocity) / (delta_time / 2.0)
    }
    result.push({
      time: current.time,
      value: current.value,
      velocity,
      acceleration,
      normalized_value: if span == 0.0 {
        0.0
      } else {
        (current.value - minimum) / span
      },
    })
  }
  result
}

///|
pub fn classify_monotonicity(
  samples : Array[SamplePoint],
  tolerance? : Double = 0.000001,
) -> CurveMonotonicity {
  if samples.length() < 2 {
    return Constant
  }
  let epsilon = tolerance.max(0.0)
  let mut increasing = false
  let mut decreasing = false
  for index in 1..<samples.length() {
    let difference = samples[index].value - samples[index - 1].value
    if difference > epsilon {
      increasing = true
    } else if difference < -epsilon {
      decreasing = true
    }
  }
  if increasing && decreasing {
    Mixed
  } else if increasing {
    Increasing
  } else if decreasing {
    Decreasing
  } else {
    Constant
  }
}

///|
pub fn curve_minimum(samples : Array[SamplePoint]) -> SamplePoint? {
  if samples.length() == 0 {
    return None
  }
  let mut result = samples[0]
  for sample in samples {
    if sample.value < result.value {
      result = sample
    }
  }
  Some(result)
}

///|
pub fn curve_maximum(samples : Array[SamplePoint]) -> SamplePoint? {
  if samples.length() == 0 {
    return None
  }
  let mut result = samples[0]
  for sample in samples {
    if sample.value > result.value {
      result = sample
    }
  }
  Some(result)
}

///|
/// Estimate the signed area under a curve using the trapezoidal rule.
pub fn integrate_analyzed_curve(samples : Array[SamplePoint]) -> Double {
  integrate_samples(samples)
}

///|
/// Estimate total variation, which is useful for quantizing a motion signal.
pub fn total_variation(samples : Array[SamplePoint]) -> Double {
  if samples.length() < 2 {
    return 0.0
  }
  let mut total = 0.0
  for index in 1..<samples.length() {
    total = total + (samples[index].value - samples[index - 1].value).abs()
  }
  total
}

///|
/// Find the first time at which a sorted curve reaches a target value.
pub fn first_crossing(samples : Array[SamplePoint], target : Double) -> Double? {
  if samples.length() == 0 {
    return None
  }
  for index in 0..<samples.length() {
    if samples[index].value == target {
      return Some(samples[index].time)
    }
    if index + 1 < samples.length() {
      let left = samples[index]
      let right = samples[index + 1]
      let left_delta = left.value - target
      let right_delta = right.value - target
      if left_delta * right_delta < 0.0 {
        let ratio = left_delta.abs() / (left_delta.abs() + right_delta.abs())
        return Some(left.time + (right.time - left.time) * ratio)
      }
    }
  }
  None
}

///|
/// Generate a lookup table with an explicit endpoint policy.
pub fn curve_lookup(
  func : (Double) -> Double,
  start : Double,
  end : Double,
  count : Int,
) -> Array[SamplePoint] raise MotionError {
  sample_function(func, start, end, count)
}

///|
/// Evaluate a table with linear interpolation and clamped boundaries.
pub fn lookup_value(samples : Array[SamplePoint], time : Double) -> Double {
  interpolate_samples(
    samples.map(fn(sample) {
      { time: sample.time, value: sample.value, depth: 0 }
    }),
    time,
  )
}

///|
/// Compose a source curve with an output range.
pub fn map_curve_range(
  samples : Array[SamplePoint],
  output_min : Double,
  output_max : Double,
) -> Array[SamplePoint] {
  let minimum = curve_minimum(samples)
  let maximum = curve_maximum(samples)
  match (minimum, maximum) {
    (Some(low), Some(high)) => {
      let span = high.value - low.value
      samples.map(fn(sample) {
        let ratio = if span == 0.0 {
          0.0
        } else {
          (sample.value - low.value) / span
        }
        {
          time: sample.time,
          value: output_min + (output_max - output_min) * ratio,
          frame: sample.frame,
        }
      })
    }
    _ => []
  }
}

///|
/// Reverse the time direction while preserving the original sample order in
/// the returned array, making it convenient for playback direction toggles.
pub fn reverse_samples(samples : Array[SamplePoint]) -> Array[SamplePoint] {
  if samples.length() == 0 {
    return []
  }
  let first = samples[0].time
  let last = samples[samples.length() - 1].time
  let result : Array[SamplePoint] = []
  for index in 0..<samples.length() {
    let source = samples[samples.length() - 1 - index]
    result.push({
      time: first + last - source.time,
      value: source.value,
      frame: index,
    })
  }
  result
}

///|
pub fn rescale_time(
  samples : Array[SamplePoint],
  start : Double,
  end : Double,
) -> Array[SamplePoint] {
  if samples.length() == 0 {
    return []
  }
  let source_start = samples[0].time
  let source_end = samples[samples.length() - 1].time
  let source_span = source_end - source_start
  samples.map(fn(sample) {
    let ratio = if source_span == 0.0 {
      0.0
    } else {
      (sample.time - source_start) / source_span
    }
    {
      time: start + (end - start) * ratio,
      value: sample.value,
      frame: sample.frame,
    }
  })
}

///|
/// Compute a percentile value from a copied and sorted scalar array.
pub fn percentile(values : Array[Double], ratio : Double) -> Double {
  if values.length() == 0 {
    return 0.0
  }
  let sorted = values.copy()
  sorted.sort_by(fn(left, right) { left.compare(right) })
  let index = (clamp01(ratio) * (sorted.length() - 1).to_double()).to_int()
  sorted[index]
}

///|
pub fn median(values : Array[Double]) -> Double {
  percentile(values, 0.5)
}

///|
pub fn mean(values : Array[Double]) -> Double {
  if values.length() == 0 {
    return 0.0
  }
  let mut total = 0.0
  for value in values {
    total = total + value
  }
  total / values.length().to_double()
}

///|
pub fn variance(values : Array[Double]) -> Double {
  if values.length() == 0 {
    return 0.0
  }
  let average = mean(values)
  let mut total = 0.0
  for value in values {
    let difference = value - average
    total = total + difference * difference
  }
  total / values.length().to_double()
}

///|
pub fn standard_deviation(values : Array[Double]) -> Double {
  variance(values).sqrt()
}
