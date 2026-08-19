///|
/// Geometric segment types that can be composed into a renderable path.
pub(all) enum PathSegment2D {
  Line(Point2, Point2)
  Cubic(CubicPath2D)
} derive(Debug)

///|
pub fn path_line(start : Point2, end : Point2) -> PathSegment2D {
  Line(start, end)
}

///|
pub fn path_cubic(
  start : Point2,
  control_start : Point2,
  control_end : Point2,
  end : Point2,
) -> PathSegment2D {
  Cubic(cubic_path2d(start, control_start, control_end, end))
}

///|
fn PathSegment2D::start(self : PathSegment2D) -> Point2 {
  match self {
    Line(start, _) => start
    Cubic(path) => path.sample(0.0)
  }
}

///|
fn PathSegment2D::end(self : PathSegment2D) -> Point2 {
  match self {
    Line(_, end) => end
    Cubic(path) => path.sample(1.0)
  }
}

///|
fn PathSegment2D::sample(self : PathSegment2D, ratio : Double) -> Point2 {
  match self {
    Line(start, end) => start.lerp(end, clamp01(ratio))
    Cubic(path) => path.sample(ratio)
  }
}

///|
fn PathSegment2D::tangent(self : PathSegment2D, ratio : Double) -> Point2 {
  match self {
    Line(start, end) => { x: end.x() - start.x(), y: end.y() - start.y() }
    Cubic(path) => path.tangent(ratio)
  }
}

///|
fn PathSegment2D::length(self : PathSegment2D, samples : Int) -> Double {
  match self {
    Line(start, end) => start.distance(end)
    Cubic(path) => path.length(samples)
  }
}

///|
pub fn PathSegment2D::bounds(
  self : PathSegment2D,
  samples? : Int = 32,
) -> Bounds2D {
  let count = samples.max(1)
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
pub fn PathSegment2D::polyline(
  self : PathSegment2D,
  samples : Int,
) -> Array[Point2] {
  let count = samples.max(1)
  let result : Array[Point2] = []
  for index in 0..<=count {
    result.push(self.sample(index.to_double() / count.to_double()))
  }
  result
}

///|
/// A length-indexed composition of line and cubic path segments.
pub struct Path2D {
  segments : Array[PathSegment2D]
  lengths : Array[Double]
  total_length : Double
} derive(Debug)

///|
pub fn Path2D::new(
  segments : Array[PathSegment2D],
  samples_per_curve? : Int = 32,
) -> Path2D raise MotionError {
  if segments.length() == 0 {
    raise MotionError::EmptyTrack
  }
  let lengths : Array[Double] = []
  let mut total = 0.0
  for segment in segments {
    let length = segment.length(samples_per_curve.max(1))
    lengths.push(length)
    total = total + length
  }
  { segments: segments.copy(), lengths, total_length: total }
}

///|
pub fn Path2D::segments(self : Path2D) -> Array[PathSegment2D] {
  self.segments.copy()
}

///|
pub fn Path2D::length(self : Path2D) -> Int {
  self.segments.length()
}

///|
pub fn Path2D::total_length(self : Path2D) -> Double {
  self.total_length
}

///|
pub fn Path2D::start(self : Path2D) -> Point2 {
  self.segments[0].start()
}

///|
pub fn Path2D::end(self : Path2D) -> Point2 {
  self.segments[self.segments.length() - 1].end()
}

///|
fn Path2D::locate_distance(self : Path2D, distance : Double) -> (Int, Double) {
  if self.total_length <= 0.0 {
    return (0, 0.0)
  }
  let target = clamp(distance, 0.0, self.total_length)
  let mut previous = 0.0
  for index in 0..<self.length() {
    let next = previous + self.lengths[index]
    if target <= next || index == self.length() - 1 {
      let ratio = if self.lengths[index] == 0.0 {
        0.0
      } else {
        (target - previous) / self.lengths[index]
      }
      return (index, clamp01(ratio))
    }
    previous = next
  }
  (self.length() - 1, 1.0)
}

///|
pub fn Path2D::sample(self : Path2D, parameter : Double) -> Point2 {
  let (index, ratio) = self.locate_distance(
    clamp01(parameter) * self.total_length,
  )
  self.segments[index].sample(ratio)
}

///|
pub fn Path2D::sample_by_distance(self : Path2D, distance : Double) -> Point2 {
  let (index, ratio) = self.locate_distance(distance)
  self.segments[index].sample(ratio)
}

///|
pub fn Path2D::tangent(self : Path2D, parameter : Double) -> Point2 {
  let (index, ratio) = self.locate_distance(
    clamp01(parameter) * self.total_length,
  )
  self.segments[index].tangent(ratio)
}

///|
pub fn Path2D::bounds(self : Path2D, samples_per_curve? : Int = 32) -> Bounds2D {
  let first = self.segments[0].bounds(samples=samples_per_curve)
  let mut min_x = first.minimum().x()
  let mut max_x = first.maximum().x()
  let mut min_y = first.minimum().y()
  let mut max_y = first.maximum().y()
  for index in 1..<self.length() {
    let bounds = self.segments[index].bounds(samples=samples_per_curve)
    min_x = min_x.min(bounds.minimum().x())
    max_x = max_x.max(bounds.maximum().x())
    min_y = min_y.min(bounds.minimum().y())
    max_y = max_y.max(bounds.maximum().y())
  }
  { minimum: point2(x=min_x, y=min_y), maximum: point2(x=max_x, y=max_y) }
}

///|
pub fn Path2D::polyline(
  self : Path2D,
  samples_per_segment : Int,
) -> Array[Point2] {
  let result : Array[Point2] = []
  for segment_index in 0..<self.length() {
    let points = self.segments[segment_index].polyline(samples_per_segment)
    for point_index in 0..<points.length() {
      if segment_index == 0 || point_index > 0 {
        result.push(points[point_index])
      }
    }
  }
  result
}

///|
/// Approximate the nearest point by scanning each segment's polyline.
pub fn Path2D::project(
  self : Path2D,
  target : Point2,
  samples_per_segment? : Int = 32,
) -> SplineProjection {
  let steps = samples_per_segment.max(1)
  let mut best_parameter = 0.0
  let mut best_value = self.start()
  let mut best_distance = best_value.distance(target)
  let mut offset = 0.0
  for segment_index in 0..<self.length() {
    let segment_length = self.lengths[segment_index]
    for step in 0..<=steps {
      let segment_ratio = step.to_double() / steps.to_double()
      let value = self.segments[segment_index].sample(segment_ratio)
      let distance = value.distance(target)
      let parameter = if self.total_length == 0.0 {
        0.0
      } else {
        (offset + segment_length * segment_ratio) / self.total_length
      }
      if distance < best_distance {
        best_parameter = parameter
        best_value = value
        best_distance = distance
      }
    }
    offset = offset + segment_length
  }
  {
    parameter: best_parameter,
    distance: best_distance,
    value: best_value,
    error: best_distance,
  }
}

///|
pub fn Path2D::append(
  self : Path2D,
  segment : PathSegment2D,
  samples_per_curve? : Int = 32,
) -> Path2D raise MotionError {
  let segments = self.segments.copy()
  segments.push(segment)
  Path2D::new(segments, samples_per_curve~)
}

///|
/// Builder for paths constructed from a start point and successive endpoints.
pub struct PathBuilder2D {
  mut current : Point2
  segments : Array[PathSegment2D]
} derive(Debug)

///|
pub fn path_builder2d(start : Point2) -> PathBuilder2D {
  { current: start, segments: [] }
}

///|
pub fn PathBuilder2D::current(self : PathBuilder2D) -> Point2 {
  self.current
}

///|
pub fn PathBuilder2D::line_to(self : PathBuilder2D, end : Point2) -> Unit {
  self.segments.push(Line(self.current, end))
  self.current = end
}

///|
pub fn PathBuilder2D::cubic_to(
  self : PathBuilder2D,
  control_start : Point2,
  control_end : Point2,
  end : Point2,
) -> Unit {
  self.segments.push(
    Cubic(cubic_path2d(self.current, control_start, control_end, end)),
  )
  self.current = end
}

///|
pub fn PathBuilder2D::close(self : PathBuilder2D) -> Unit {
  if self.segments.length() > 0 {
    self.line_to(self.segments[0].start())
  }
}

///|
pub fn PathBuilder2D::length(self : PathBuilder2D) -> Int {
  self.segments.length()
}

///|
pub fn PathBuilder2D::build(
  self : PathBuilder2D,
  samples_per_curve? : Int = 32,
) -> Path2D raise MotionError {
  Path2D::new(self.segments, samples_per_curve~)
}
