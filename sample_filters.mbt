///|
/// Moving-average smoothing for an already sampled scalar signal.
pub fn moving_average(values : Array[Double], window : Int) -> Array[Double] {
  if values.length() == 0 || window <= 1 {
    return values.copy()
  }
  let result : Array[Double] = []
  for index in 0..<values.length() {
    let first = (index - window / 2).max(0)
    let last = (index + window / 2).min(values.length() - 1)
    let mut total = 0.0
    for i in first..<=last {
      total = total + values[i]
    }
    result.push(total / (last - first + 1).to_double())
  }
  result
}

///|
/// First difference of a sampled signal with an explicit time step.
pub fn differentiate(values : Array[Double], step : Double) -> Array[Double] {
  let result : Array[Double] = []
  if values.length() == 0 {
    return result
  }
  if step <= 0.0 {
    return Array::make(values.length(), 0.0)
  }
  result.push(0.0)
  for i in 1..<values.length() {
    result.push((values[i] - values[i - 1]) / step)
  }
  result
}

///|
/// Normalize a signal to [0, 1]. Constant signals map to zero.
pub fn normalize_samples(values : Array[Double]) -> Array[Double] {
  if values.length() == 0 {
    return []
  }
  let mut minimum = values[0]
  let mut maximum = values[0]
  for value in values {
    if value < minimum {
      minimum = value
    }
    if value > maximum {
      maximum = value
    }
  }
  let span = maximum - minimum
  if span == 0.0 {
    Array::make(values.length(), 0.0)
  } else {
    values.map(fn(value) { (value - minimum) / span })
  }
}

///|
/// Clamp a signal to a monotone non-decreasing envelope.
pub fn monotone_envelope(values : Array[Double]) -> Array[Double] {
  if values.length() == 0 {
    return []
  }
  let result : Array[Double] = [values[0]]
  for i in 1..<values.length() {
    result.push(result[i - 1].max(values[i]))
  }
  result
}

///|
pub fn peak_index(values : Array[Double]) -> Int? {
  if values.length() == 0 {
    None
  } else {
    let mut index = 0
    for i in 1..<values.length() {
      if values[i] > values[index] {
        index = i
      }
    }
    Some(index)
  }
}

///|
pub fn rms(values : Array[Double]) -> Double {
  if values.length() == 0 {
    0.0
  } else {
    let mut total = 0.0
    for value in values {
      total = total + value * value
    }
    (total / values.length().to_double()).sqrt()
  }
}
