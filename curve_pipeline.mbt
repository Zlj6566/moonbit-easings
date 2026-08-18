///|
/// A piecewise curve used to choreograph a multi-stage motion.
pub struct CurveChain {
  curves : Array[Curve]
  weights : Array[Double]
  total_weight : Double
} derive(Debug)

///|
pub fn CurveChain::new(
  curves : Array[Curve],
  weights? : Array[Double],
) -> CurveChain raise MotionError {
  if curves.length() == 0 {
    raise MotionError::EmptyTrack
  }
  let selected = match weights {
    Some(values) => {
      if values.length() != curves.length() {
        raise MotionError::InvalidSampleCount(values.length())
      }
      values.copy()
    }
    None => Array::make(curves.length(), 1.0)
  }
  let mut total = 0.0
  for value in selected {
    if value <= 0.0 || value.is_nan() || value.is_inf() {
      raise MotionError::InvalidTime(value)
    }
    total = total + value
  }
  { curves: curves.copy(), weights: selected, total_weight: total }
}

///|
pub fn CurveChain::length(self : CurveChain) -> Int {
  self.curves.length()
}

///|
fn CurveChain::locate(self : CurveChain, t : Double) -> (Int, Double) {
  let distance = clamp01(t) * self.total_weight
  let mut cursor = 0.0
  for i in 0..<self.weights.length() {
    let next = cursor + self.weights[i]
    if distance <= next || i == self.weights.length() - 1 {
      let ratio = if self.weights[i] == 0.0 {
        0.0
      } else {
        (distance - cursor) / self.weights[i]
      }
      return (i, clamp01(ratio))
    }
    cursor = next
  }
  (self.curves.length() - 1, 1.0)
}

///|
pub fn CurveChain::sample(self : CurveChain, t : Double) -> Double {
  let (index, segment_t) = self.locate(t)
  let segment_count = self.curves.length().to_double()
  (index.to_double() + self.curves[index].apply(segment_t)) / segment_count
}

///|
pub fn CurveChain::derivative(self : CurveChain, t : Double) -> Double {
  let (index, segment_t) = self.locate(t)
  let segment_count = self.curves.length().to_double()
  self.curves[index].derivative(segment_t) / segment_count
}

///|
pub fn CurveChain::sample_many(
  self : CurveChain,
  count : Int,
) -> Array[Double] raise MotionError {
  if count < 2 {
    raise MotionError::InvalidSampleCount(count)
  }
  let result : Array[Double] = []
  for i in 0..<count {
    result.push(self.sample(i.to_double() / (count - 1).to_double()))
  }
  result
}
