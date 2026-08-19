///|
/// A lightweight signal buffer for post-processing sampled motion data.
pub struct MotionSignal {
  values : Array[Double]
  start : Double
  step : Double
} derive(Debug)

///|
pub fn MotionSignal::new(
  values : Array[Double],
  start : Double,
  step : Double,
) -> MotionSignal raise MotionError {
  ensure_finite(start)
  ensure_finite(step)
  if step <= 0.0 {
    raise MotionError::InvalidDuration(step)
  }
  { values: values.copy(), start, step }
}

///|
pub fn MotionSignal::values(self : MotionSignal) -> Array[Double] {
  self.values.copy()
}

///|
pub fn MotionSignal::length(self : MotionSignal) -> Int {
  self.values.length()
}

///|
pub fn MotionSignal::start(self : MotionSignal) -> Double {
  self.start
}

///|
pub fn MotionSignal::step(self : MotionSignal) -> Double {
  self.step
}

///|
pub fn MotionSignal::end(self : MotionSignal) -> Double {
  if self.values.length() == 0 {
    self.start
  } else {
    self.start + (self.values.length() - 1).to_double() * self.step
  }
}

///|
pub fn MotionSignal::duration(self : MotionSignal) -> Double {
  self.end() - self.start
}

///|
pub fn MotionSignal::at(self : MotionSignal, index : Int) -> Double? {
  if index < 0 || index >= self.values.length() {
    None
  } else {
    Some(self.values[index])
  }
}

///|
pub fn MotionSignal::sample(self : MotionSignal, time : Double) -> Double {
  if self.values.length() == 0 {
    return 0.0
  }
  let position = (time - self.start) / self.step
  if position <= 0.0 {
    return self.values[0]
  }
  let last = self.values.length() - 1
  if position >= last.to_double() {
    return self.values[last]
  }
  let left_index = position.to_int()
  let ratio = position - left_index.to_double()
  self.values[left_index] +
  (self.values[left_index + 1] - self.values[left_index]) * ratio
}

///|
pub fn MotionSignal::sample_many(
  self : MotionSignal,
  count : Int,
) -> Array[SamplePoint] raise MotionError {
  if count < 2 {
    raise MotionError::InvalidSampleCount(count)
  }
  let result : Array[SamplePoint] = []
  for index in 0..<count {
    let ratio = index.to_double() / (count - 1).to_double()
    let time = self.start + self.duration() * ratio
    result.push({ time, value: self.sample(time), frame: index })
  }
  result
}

///|
pub fn MotionSignal::map(
  self : MotionSignal,
  func : (Double) -> Double,
) -> MotionSignal {
  { ..self, values: self.values.map(func) }
}

///|
pub fn MotionSignal::zip_map(
  self : MotionSignal,
  other : MotionSignal,
  func : (Double, Double) -> Double,
) -> MotionSignal {
  let count = self.length().min(other.length())
  let values : Array[Double] = []
  for index in 0..<count {
    values.push(func(self.values[index], other.values[index]))
  }
  { values, start: self.start, step: self.step }
}

///|
pub fn MotionSignal::scale(
  self : MotionSignal,
  factor : Double,
) -> MotionSignal {
  self.map(fn(value) { value * factor })
}

///|
pub fn MotionSignal::offset(
  self : MotionSignal,
  amount : Double,
) -> MotionSignal {
  self.map(fn(value) { value + amount })
}

///|
pub fn MotionSignal::clamp(
  self : MotionSignal,
  minimum : Double,
  maximum : Double,
) -> MotionSignal {
  self.map(fn(value) { value.max(minimum).min(maximum) })
}

///|
pub fn MotionSignal::reverse(self : MotionSignal) -> MotionSignal {
  let values : Array[Double] = []
  for index in 0..<self.values.length() {
    values.push(self.values[self.values.length() - 1 - index])
  }
  { values, start: self.start, step: self.step }
}

///|
/// Create a centered moving average; edge windows are shortened rather than
/// padded, avoiding artificial impulses at clip boundaries.
pub fn smooth_signal(signal : MotionSignal, radius : Int) -> MotionSignal {
  if radius <= 0 || signal.length() == 0 {
    return signal
  }
  let values : Array[Double] = []
  for index in 0..<signal.length() {
    let first = (index - radius).max(0)
    let last = (index + radius).min(signal.length() - 1)
    let mut total = 0.0
    for inner in first..<=last {
      total = total + signal.values[inner]
    }
    values.push(total / (last - first + 1).to_double())
  }
  { values, start: signal.start, step: signal.step }
}

///|
/// Apply a first-order exponential low-pass filter.
pub fn low_pass_signal(signal : MotionSignal, alpha : Double) -> MotionSignal {
  if signal.length() == 0 {
    return signal
  }
  let coefficient = clamp01(alpha)
  let values : Array[Double] = [signal.values[0]]
  for index in 1..<signal.length() {
    let previous = values[index - 1]
    let current = signal.values[index]
    values.push(previous + (current - previous) * coefficient)
  }
  { values, start: signal.start, step: signal.step }
}

///|
/// Differentiate a signal using central differences in the interior.
pub fn differentiate_signal(signal : MotionSignal) -> MotionSignal {
  let values : Array[Double] = []
  if signal.length() == 0 {
    return signal
  }
  if signal.length() == 1 {
    values.push(0.0)
    return { values, start: signal.start, step: signal.step }
  }
  values.push((signal.values[1] - signal.values[0]) / signal.step)
  for index in 1..<(signal.length() - 1) {
    values.push(
      (signal.values[index + 1] - signal.values[index - 1]) /
      (2.0 * signal.step),
    )
  }
  let last = signal.length() - 1
  values.push((signal.values[last] - signal.values[last - 1]) / signal.step)
  { values, start: signal.start, step: signal.step }
}

///|
pub fn integrate_signal(signal : MotionSignal) -> Double {
  if signal.length() < 2 {
    return 0.0
  }
  let mut total = 0.0
  for index in 0..<(signal.length() - 1) {
    total = total +
      (signal.values[index] + signal.values[index + 1]) * signal.step / 2.0
  }
  total
}

///|
pub fn cumulative_integral(signal : MotionSignal) -> MotionSignal {
  let values : Array[Double] = [0.0]
  for index in 0..<(signal.length() - 1) {
    let area = (signal.values[index] + signal.values[index + 1]) *
      signal.step /
      2.0
    values.push(values[index] + area)
  }
  { values, start: signal.start, step: signal.step }
}

///|
/// Convolve a signal with a finite kernel, using edge replication.
pub fn convolve_signal(
  signal : MotionSignal,
  kernel : Array[Double],
) -> MotionSignal {
  if signal.length() == 0 || kernel.length() == 0 {
    return signal
  }
  let values : Array[Double] = []
  let radius = kernel.length() / 2
  for index in 0..<signal.length() {
    let mut total = 0.0
    for kernel_index in 0..<kernel.length() {
      let source_index = (index + kernel_index - radius)
        .max(0)
        .min(signal.length() - 1)
      total = total + signal.values[source_index] * kernel[kernel_index]
    }
    values.push(total)
  }
  { values, start: signal.start, step: signal.step }
}

///|
pub fn normalize_signal(signal : MotionSignal) -> MotionSignal {
  if signal.length() == 0 {
    return signal
  }
  let mut minimum = signal.values[0]
  let mut maximum = signal.values[0]
  for value in signal.values {
    minimum = minimum.min(value)
    maximum = maximum.max(value)
  }
  let span = maximum - minimum
  if span == 0.0 {
    signal.map(fn(_) { 0.0 })
  } else {
    signal.map(fn(value) { (value - minimum) / span })
  }
}

///|
pub fn signal_minimum(signal : MotionSignal) -> Double? {
  if signal.length() == 0 {
    return None
  }
  let mut result = signal.values[0]
  for value in signal.values {
    result = result.min(value)
  }
  Some(result)
}

///|
pub fn signal_maximum(signal : MotionSignal) -> Double? {
  if signal.length() == 0 {
    return None
  }
  let mut result = signal.values[0]
  for value in signal.values {
    result = result.max(value)
  }
  Some(result)
}

///|
pub fn signal_energy(signal : MotionSignal) -> Double {
  let mut total = 0.0
  for value in signal.values {
    total = total + value * value
  }
  total * signal.step
}

///|
pub fn signal_rms(signal : MotionSignal) -> Double {
  if signal.length() == 0 {
    0.0
  } else {
    (signal_energy(signal) / signal.duration().max(signal.step)).sqrt()
  }
}

///|
/// Resample at a new step while preserving the signal's time span.
pub fn resample_signal(
  signal : MotionSignal,
  step : Double,
) -> MotionSignal raise MotionError {
  ensure_finite(step)
  if step <= 0.0 {
    raise MotionError::InvalidDuration(step)
  }
  if signal.length() == 0 {
    return { values: [], start: signal.start, step }
  }
  let count = @math.floor(signal.duration() / step).to_int() + 1
  let values : Array[Double] = []
  for index in 0..<count {
    values.push(signal.sample(signal.start + index.to_double() * step))
  }
  MotionSignal::new(values, signal.start, step)
}

///|
pub fn signal_to_samples(signal : MotionSignal) -> Array[SamplePoint] {
  let result : Array[SamplePoint] = []
  for index in 0..<signal.length() {
    result.push({
      time: signal.start + index.to_double() * signal.step,
      value: signal.values[index],
      frame: index,
    })
  }
  result
}
