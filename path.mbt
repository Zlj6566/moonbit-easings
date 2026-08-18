///|
/// Axis-aligned bounds for a sampled media path.
pub(all) struct Bounds2D {
  minimum : Point2
  maximum : Point2
} derive(Debug)

///|
pub fn Bounds2D::minimum(self : Bounds2D) -> Point2 {
  self.minimum
}

///|
pub fn Bounds2D::maximum(self : Bounds2D) -> Point2 {
  self.maximum
}

///|
/// A cubic geometric Bézier path. This is separate from Bezier timing curves.
pub struct CubicPath2D {
  start : Point2
  control_start : Point2
  control_end : Point2
  end : Point2
} derive(Debug)

///|
pub fn cubic_path2d(
  start : Point2,
  control_start : Point2,
  control_end : Point2,
  end : Point2,
) -> CubicPath2D {
  { start, control_start, control_end, end }
}

///|
fn point_lerp(first : Point2, second : Point2, t : Double) -> Point2 {
  first.lerp(second, t)
}

///|
pub fn CubicPath2D::sample(self : CubicPath2D, t : Double) -> Point2 {
  let x = clamp01(t)
  let first = point_lerp(self.start, self.control_start, x)
  let second = point_lerp(self.control_start, self.control_end, x)
  let third = point_lerp(self.control_end, self.end, x)
  let left = point_lerp(first, second, x)
  let right = point_lerp(second, third, x)
  point_lerp(left, right, x)
}

///|
pub fn CubicPath2D::tangent(self : CubicPath2D, t : Double) -> Point2 {
  let x = clamp01(t)
  let one_minus = 1.0 - x
  let first = self.control_start.lerp(self.start, one_minus)
  let second = self.control_end.lerp(self.control_start, one_minus)
  let third = self.end.lerp(self.control_end, one_minus)
  let left = second.lerp(first, one_minus)
  let right = third.lerp(second, one_minus)
  { x: 3.0 * (right.x - left.x), y: 3.0 * (right.y - left.y) }
}

///|
pub fn CubicPath2D::length(self : CubicPath2D, segments : Int) -> Double {
  if segments <= 0 {
    0.0
  } else {
    let mut total = 0.0
    let mut previous = self.sample(0.0)
    for i in 1..<=segments {
      let current = self.sample(i.to_double() / segments.to_double())
      total = total + previous.distance(current)
      previous = current
    }
    total
  }
}

///|
pub fn CubicPath2D::sample_by_distance(
  self : CubicPath2D,
  distance : Double,
  segments? : Int = 64,
) -> Point2 {
  let total = self.length(segments)
  if total <= 0.0 {
    return self.sample(0.0)
  }
  let target = clamp(distance, 0.0, total)
  let mut travelled = 0.0
  let mut previous = self.sample(0.0)
  for i in 1..<=segments {
    let current = self.sample(i.to_double() / segments.to_double())
    let span = previous.distance(current)
    if travelled + span >= target {
      let ratio = if span == 0.0 { 0.0 } else { (target - travelled) / span }
      return previous.lerp(current, ratio)
    }
    travelled = travelled + span
    previous = current
  }
  self.sample(1.0)
}

///|
pub fn CubicPath2D::bounds(
  self : CubicPath2D,
  segments? : Int = 32,
) -> Bounds2D {
  let first = self.sample(0.0)
  let mut min_x = first.x
  let mut min_y = first.y
  let mut max_x = first.x
  let mut max_y = first.y
  for i in 1..<=segments {
    let point = self.sample(i.to_double() / segments.to_double())
    if point.x < min_x {
      min_x = point.x
    }
    if point.y < min_y {
      min_y = point.y
    }
    if point.x > max_x {
      max_x = point.x
    }
    if point.y > max_y {
      max_y = point.y
    }
  }
  { minimum: { x: min_x, y: min_y }, maximum: { x: max_x, y: max_y } }
}

///|
pub fn CubicPath2D::polyline(
  self : CubicPath2D,
  segments : Int,
) -> Array[Point2] {
  let result : Array[Point2] = []
  if segments <= 0 {
    result.push(self.sample(0.0))
    return result
  }
  for i in 0..<=segments {
    result.push(self.sample(i.to_double() / segments.to_double()))
  }
  result
}
