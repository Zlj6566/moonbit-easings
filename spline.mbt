///|
/// A normalized projection on a spline, useful for path-following cameras.
pub(all) struct SplineProjection {
  parameter : Double
  distance : Double
  value : Point2
  error : Double
} derive(Debug)

///|
pub fn SplineProjection::parameter(self : SplineProjection) -> Double {
  self.parameter
}

///|
pub fn SplineProjection::distance(self : SplineProjection) -> Double {
  self.distance
}

///|
pub fn SplineProjection::value(self : SplineProjection) -> Point2 {
  self.value
}

///|
pub fn SplineProjection::error(self : SplineProjection) -> Double {
  self.error
}

///|
/// A Catmull-Rom spline over 2D control points.
///
/// `tension=0` is the standard centripetal-free Catmull-Rom form. The
/// `closed` option connects the last control point back to the first one.
pub struct Spline2D {
  points : Array[Point2]
  tension : Double
  closed : Bool
} derive(Debug)

///|
pub fn Spline2D::new(
  points : Array[Point2],
  tension? : Double = 0.0,
  closed? : Bool = false,
) -> Spline2D raise MotionError {
  if points.length() < 2 {
    raise MotionError::InvalidPointCount(points.length())
  }
  ensure_finite(tension)
  if tension < 0.0 || tension > 1.0 {
    raise MotionError::InvalidTension(tension)
  }
  { points: points.copy(), tension, closed }
}

///|
pub fn Spline2D::control_points(self : Spline2D) -> Array[Point2] {
  self.points.copy()
}

///|
pub fn Spline2D::point_count(self : Spline2D) -> Int {
  self.points.length()
}

///|
pub fn Spline2D::tension(self : Spline2D) -> Double {
  self.tension
}

///|
pub fn Spline2D::closed(self : Spline2D) -> Bool {
  self.closed
}

///|
pub fn Spline2D::segment_count(self : Spline2D) -> Int {
  if self.closed {
    self.points.length()
  } else {
    self.points.length() - 1
  }
}

///|
fn wrap_index(index : Int, length : Int) -> Int {
  let remainder = index % length
  if remainder < 0 {
    remainder + length
  } else {
    remainder
  }
}

///|
fn Spline2D::control_at(self : Spline2D, index : Int) -> Point2 {
  if self.closed {
    self.points[wrap_index(index, self.points.length())]
  } else {
    self.points[index.max(0).min(self.points.length() - 1)]
  }
}

///|
fn catmull_component(
  previous : Double,
  start : Double,
  end : Double,
  next : Double,
  t : Double,
  tension : Double,
) -> Double {
  let tangent_scale = (1.0 - tension) / 2.0
  let tangent_start = (end - previous) * tangent_scale
  let tangent_end = (next - start) * tangent_scale
  let t2 = t * t
  let t3 = t2 * t
  let h00 = 2.0 * t3 - 3.0 * t2 + 1.0
  let h10 = t3 - 2.0 * t2 + t
  let h01 = -2.0 * t3 + 3.0 * t2
  let h11 = t3 - t2
  h00 * start + h10 * tangent_start + h01 * end + h11 * tangent_end
}

///|
pub fn catmull_rom_point2(
  previous : Point2,
  start : Point2,
  end : Point2,
  next : Point2,
  t : Double,
  tension? : Double = 0.0,
) -> Point2 {
  {
    x: catmull_component(previous.x(), start.x(), end.x(), next.x(), t, tension),
    y: catmull_component(previous.y(), start.y(), end.y(), next.y(), t, tension),
  }
}

///|
pub fn Spline2D::sample(self : Spline2D, parameter : Double) -> Point2 {
  let normalized = clamp01(parameter)
  let segment_count = self.segment_count()
  if normalized >= 1.0 {
    return self.control_at(
      if self.closed {
        segment_count
      } else {
        segment_count
      },
    )
  }
  let scaled = normalized * segment_count.to_double()
  let index = scaled.to_int().min(segment_count - 1)
  let segment_progress = scaled - index.to_double()
  catmull_rom_point2(
    self.control_at(index - 1),
    self.control_at(index),
    self.control_at(index + 1),
    self.control_at(index + 2),
    segment_progress,
    tension=self.tension,
  )
}

///|
pub fn Spline2D::tangent(self : Spline2D, parameter : Double) -> Point2 {
  let normalized = clamp01(parameter)
  let epsilon = 0.000001
  let before = self.sample((normalized - epsilon).max(0.0))
  let after = self.sample((normalized + epsilon).min(1.0))
  {
    x: (after.x() - before.x()) / (2.0 * epsilon),
    y: (after.y() - before.y()) / (2.0 * epsilon),
  }
}

///|
pub fn Spline2D::speed(self : Spline2D, parameter : Double) -> Double {
  let tangent = self.tangent(parameter)
  @math.hypot(tangent.x(), tangent.y())
}

///|
pub fn Spline2D::sample_many(
  self : Spline2D,
  count : Int,
) -> Array[Point2] raise MotionError {
  if count < 2 {
    raise MotionError::InvalidSampleCount(count)
  }
  let result : Array[Point2] = []
  for index in 0..<count {
    result.push(self.sample(index.to_double() / (count - 1).to_double()))
  }
  result
}

///|
pub fn Spline2D::length(self : Spline2D, samples_per_segment : Int) -> Double {
  if samples_per_segment <= 0 {
    return 0.0
  }
  let total_samples = self.segment_count() * samples_per_segment
  let mut length = 0.0
  let mut previous = self.sample(0.0)
  for index in 1..<=total_samples {
    let current = self.sample(index.to_double() / total_samples.to_double())
    length = length + previous.distance(current)
    previous = current
  }
  length
}

///|
pub fn Spline2D::sample_by_distance(
  self : Spline2D,
  distance : Double,
  samples_per_segment? : Int = 32,
) -> Point2 {
  let segments = samples_per_segment.max(1)
  let total_samples = self.segment_count() * segments
  let total_length = self.length(segments)
  if total_length <= 0.0 || distance <= 0.0 {
    return self.sample(0.0)
  }
  if distance >= total_length {
    return self.sample(1.0)
  }
  let target = distance
  let mut travelled = 0.0
  let mut previous = self.sample(0.0)
  for index in 1..<=total_samples {
    let parameter = index.to_double() / total_samples.to_double()
    let current = self.sample(parameter)
    let step = previous.distance(current)
    if travelled + step >= target && step > 0.0 {
      let ratio = (target - travelled) / step
      return previous.lerp(current, ratio)
    }
    travelled = travelled + step
    previous = current
  }
  self.sample(1.0)
}

///|
pub fn Spline2D::bounds(
  self : Spline2D,
  samples_per_segment? : Int = 32,
) -> Bounds2D {
  let count = self.segment_count() * samples_per_segment.max(1)
  let first = self.sample(0.0)
  let mut min_x = first.x()
  let mut max_x = first.x()
  let mut min_y = first.y()
  let mut max_y = first.y()
  for index in 1..<=count {
    let point = self.sample(index.to_double() / count.to_double())
    min_x = min_x.min(point.x())
    max_x = max_x.max(point.x())
    min_y = min_y.min(point.y())
    max_y = max_y.max(point.y())
  }
  { minimum: point2(x=min_x, y=min_y), maximum: point2(x=max_x, y=max_y) }
}

///|
pub fn Spline2D::polyline(
  self : Spline2D,
  samples_per_segment : Int,
) -> Array[Point2] {
  let count = self.segment_count() * samples_per_segment.max(1)
  let points : Array[Point2] = []
  for index in 0..<=count {
    points.push(self.sample(index.to_double() / count.to_double()))
  }
  points
}

///|
/// Find the closest sampled point to a target, returning an approximate
/// normalized parameter and the actual point on the spline.
pub fn Spline2D::project(
  self : Spline2D,
  target : Point2,
  samples_per_segment? : Int = 32,
) -> SplineProjection {
  let count = self.segment_count() * samples_per_segment.max(1)
  let mut best_parameter = 0.0
  let mut best_value = self.sample(0.0)
  let mut best_distance = best_value.distance(target)
  for index in 1..<=count {
    let parameter = index.to_double() / count.to_double()
    let value = self.sample(parameter)
    let distance = value.distance(target)
    if distance < best_distance {
      best_parameter = parameter
      best_value = value
      best_distance = distance
    }
  }
  {
    parameter: best_parameter,
    distance: best_distance,
    value: best_value,
    error: best_distance,
  }
}

///|
/// A Catmull-Rom spline over 3D control points for camera and scene motion.
pub struct Spline3D {
  points : Array[Point3]
  tension : Double
  closed : Bool
} derive(Debug)

///|
pub fn Spline3D::new(
  points : Array[Point3],
  tension? : Double = 0.0,
  closed? : Bool = false,
) -> Spline3D raise MotionError {
  if points.length() < 2 {
    raise MotionError::InvalidPointCount(points.length())
  }
  ensure_finite(tension)
  if tension < 0.0 || tension > 1.0 {
    raise MotionError::InvalidTension(tension)
  }
  { points: points.copy(), tension, closed }
}

///|
pub fn Spline3D::control_points(self : Spline3D) -> Array[Point3] {
  self.points.copy()
}

///|
pub fn Spline3D::point_count(self : Spline3D) -> Int {
  self.points.length()
}

///|
pub fn Spline3D::tension(self : Spline3D) -> Double {
  self.tension
}

///|
pub fn Spline3D::closed(self : Spline3D) -> Bool {
  self.closed
}

///|
pub fn Spline3D::segment_count(self : Spline3D) -> Int {
  if self.closed {
    self.points.length()
  } else {
    self.points.length() - 1
  }
}

///|
fn Spline3D::control_at(self : Spline3D, index : Int) -> Point3 {
  if self.closed {
    self.points[wrap_index(index, self.points.length())]
  } else {
    self.points[index.max(0).min(self.points.length() - 1)]
  }
}

///|
pub fn catmull_rom_point3(
  previous : Point3,
  start : Point3,
  end : Point3,
  next : Point3,
  t : Double,
  tension? : Double = 0.0,
) -> Point3 {
  {
    x: catmull_component(previous.x(), start.x(), end.x(), next.x(), t, tension),
    y: catmull_component(previous.y(), start.y(), end.y(), next.y(), t, tension),
    z: catmull_component(previous.z(), start.z(), end.z(), next.z(), t, tension),
  }
}

///|
pub fn Spline3D::sample(self : Spline3D, parameter : Double) -> Point3 {
  let normalized = clamp01(parameter)
  let segment_count = self.segment_count()
  if normalized >= 1.0 {
    return self.control_at(segment_count)
  }
  let scaled = normalized * segment_count.to_double()
  let index = scaled.to_int().min(segment_count - 1)
  let segment_progress = scaled - index.to_double()
  catmull_rom_point3(
    self.control_at(index - 1),
    self.control_at(index),
    self.control_at(index + 1),
    self.control_at(index + 2),
    segment_progress,
    tension=self.tension,
  )
}

///|
pub fn Spline3D::tangent(self : Spline3D, parameter : Double) -> Point3 {
  let normalized = clamp01(parameter)
  let epsilon = 0.000001
  let before = self.sample((normalized - epsilon).max(0.0))
  let after = self.sample((normalized + epsilon).min(1.0))
  {
    x: (after.x() - before.x()) / (2.0 * epsilon),
    y: (after.y() - before.y()) / (2.0 * epsilon),
    z: (after.z() - before.z()) / (2.0 * epsilon),
  }
}

///|
pub fn Spline3D::speed(self : Spline3D, parameter : Double) -> Double {
  let tangent = self.tangent(parameter)
  @math.pow(
    tangent.x() * tangent.x() +
    tangent.y() * tangent.y() +
    tangent.z() * tangent.z(),
    0.5,
  )
}

///|
pub fn Spline3D::sample_many(
  self : Spline3D,
  count : Int,
) -> Array[Point3] raise MotionError {
  if count < 2 {
    raise MotionError::InvalidSampleCount(count)
  }
  let result : Array[Point3] = []
  for index in 0..<count {
    result.push(self.sample(index.to_double() / (count - 1).to_double()))
  }
  result
}

///|
pub fn Spline3D::length(self : Spline3D, samples_per_segment : Int) -> Double {
  if samples_per_segment <= 0 {
    return 0.0
  }
  let total_samples = self.segment_count() * samples_per_segment
  let mut length = 0.0
  let mut previous = self.sample(0.0)
  for index in 1..<=total_samples {
    let current = self.sample(index.to_double() / total_samples.to_double())
    let dx = current.x() - previous.x()
    let dy = current.y() - previous.y()
    let dz = current.z() - previous.z()
    length = length + @math.pow(dx * dx + dy * dy + dz * dz, 0.5)
    previous = current
  }
  length
}

///|
pub fn Spline3D::sample_by_distance(
  self : Spline3D,
  distance : Double,
  samples_per_segment? : Int = 32,
) -> Point3 {
  let segments = samples_per_segment.max(1)
  let total_samples = self.segment_count() * segments
  let total_length = self.length(segments)
  if total_length <= 0.0 || distance <= 0.0 {
    return self.sample(0.0)
  }
  if distance >= total_length {
    return self.sample(1.0)
  }
  let mut travelled = 0.0
  let mut previous = self.sample(0.0)
  for index in 1..<=total_samples {
    let parameter = index.to_double() / total_samples.to_double()
    let current = self.sample(parameter)
    let dx = current.x() - previous.x()
    let dy = current.y() - previous.y()
    let dz = current.z() - previous.z()
    let step = @math.pow(dx * dx + dy * dy + dz * dz, 0.5)
    if travelled + step >= distance && step > 0.0 {
      let ratio = (distance - travelled) / step
      return {
        x: previous.x() + (current.x() - previous.x()) * ratio,
        y: previous.y() + (current.y() - previous.y()) * ratio,
        z: previous.z() + (current.z() - previous.z()) * ratio,
      }
    }
    travelled = travelled + step
    previous = current
  }
  self.sample(1.0)
}

///|
pub fn Spline3D::polyline(
  self : Spline3D,
  samples_per_segment : Int,
) -> Array[Point3] {
  let count = self.segment_count() * samples_per_segment.max(1)
  let points : Array[Point3] = []
  for index in 0..<=count {
    points.push(self.sample(index.to_double() / count.to_double()))
  }
  points
}
