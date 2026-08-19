///|
/// Dot product for planar tangent and normal calculations.
pub fn point2_dot(first : Point2, second : Point2) -> Double {
  first.x() * second.x() + first.y() * second.y()
}

///|
pub fn point2_cross(first : Point2, second : Point2) -> Double {
  first.x() * second.y() - first.y() * second.x()
}

///|
pub fn point2_length(value : Point2) -> Double {
  @math.hypot(value.x(), value.y())
}

///|
pub fn point2_normalized(value : Point2) -> Point2 {
  let length = point2_length(value)
  if length == 0.0 {
    point2(x=0.0, y=0.0)
  } else {
    point2(x=value.x() / length, y=value.y() / length)
  }
}

///|
pub fn point2_normal(value : Point2) -> Point2 {
  point2(x=-value.y(), y=value.x())
}

///|
pub fn point2_reflect(value : Point2, normal : Point2) -> Point2 {
  let unit = point2_normalized(normal)
  let scale = 2.0 * point2_dot(value, unit)
  point2(x=value.x() - scale * unit.x(), y=value.y() - scale * unit.y())
}

///|
pub fn point2_angle(first : Point2, second : Point2) -> Double {
  @math.atan2(point2_cross(first, second), point2_dot(first, second))
}

///|
pub fn point2_from_polar(radius : Double, angle : Double) -> Point2 {
  point2(x=radius * @math.cos(angle), y=radius * @math.sin(angle))
}

///|
pub fn point2_lerp_clamped(
  first : Point2,
  second : Point2,
  ratio : Double,
) -> Point2 {
  first.lerp(second, clamp01(ratio))
}

///|
pub fn point3_dot(first : Point3, second : Point3) -> Double {
  first.x() * second.x() + first.y() * second.y() + first.z() * second.z()
}

///|
pub fn point3_length(value : Point3) -> Double {
  @math.pow(point3_dot(value, value), 0.5)
}

///|
pub fn point3_normalized(value : Point3) -> Point3 {
  let length = point3_length(value)
  if length == 0.0 {
    point3(x=0.0, y=0.0, z=0.0)
  } else {
    point3(x=value.x() / length, y=value.y() / length, z=value.z() / length)
  }
}

///|
pub fn point3_cross(first : Point3, second : Point3) -> Point3 {
  point3(
    x=first.y() * second.z() - first.z() * second.y(),
    y=first.z() * second.x() - first.x() * second.z(),
    z=first.x() * second.y() - first.y() * second.x(),
  )
}

///|
pub fn point3_distance(first : Point3, second : Point3) -> Double {
  point3_length(
    point3(
      x=second.x() - first.x(),
      y=second.y() - first.y(),
      z=second.z() - first.z(),
    ),
  )
}

///|
pub fn point3_lerp_clamped(
  first : Point3,
  second : Point3,
  ratio : Double,
) -> Point3 {
  first.lerp(second, clamp01(ratio))
}

///|
pub fn remap_value(
  value : Double,
  source_min : Double,
  source_max : Double,
  target_min : Double,
  target_max : Double,
) -> Double {
  let span = source_max - source_min
  if span == 0.0 {
    target_min
  } else {
    target_min + (target_max - target_min) * (value - source_min) / span
  }
}

///|
pub fn smooth_damp(
  current : Double,
  target : Double,
  velocity : Double,
  smooth_time : Double,
  delta_time : Double,
) -> (Double, Double) {
  let time = smooth_time.max(0.000001)
  let step = delta_time.max(0.0)
  let omega = 2.0 / time
  let x = omega * step
  let factor = 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
  let difference = current - target
  let temporary = (velocity + omega * difference) * step
  let next_velocity = (velocity - omega * temporary) * factor
  let next = target + (difference + temporary) * factor
  (next, next_velocity)
}

///|
pub fn critically_damped_step(
  current : Double,
  target : Double,
  velocity : Double,
  response : Double,
  delta_time : Double,
) -> (Double, Double) {
  smooth_damp(
    current,
    target,
    velocity,
    1.0 / response.max(0.000001),
    delta_time,
  )
}
