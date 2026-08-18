///|
/// Scalar interpolation primitive.
pub fn interpolate_scalar(start : Double, end : Double, t : Double) -> Double {
  start + (end - start) * t
}

///|
pub fn interpolate_point2(start : Point2, end : Point2, t : Double) -> Point2 {
  start.lerp(end, t)
}

///|
pub fn interpolate_point3(start : Point3, end : Point3, t : Double) -> Point3 {
  start.lerp(end, t)
}

///|
/// Interpolate straight in RGBA space, optionally preserving premultiplied alpha.
pub fn interpolate_rgba(
  start : Rgba,
  end : Rgba,
  t : Double,
  premultiplied? : Bool = false,
) -> Rgba {
  let alpha = interpolate_scalar(start.a, end.a, t)
  if premultiplied && alpha > 0.0 {
    let r = interpolate_scalar(start.r * start.a, end.r * end.a, t) / alpha
    let g = interpolate_scalar(start.g * start.a, end.g * end.a, t) / alpha
    let b = interpolate_scalar(start.b * start.a, end.b * end.a, t) / alpha
    rgba(r~, g~, b~, a=alpha)
  } else {
    rgba(
      r=interpolate_scalar(start.r, end.r, t),
      g=interpolate_scalar(start.g, end.g, t),
      b=interpolate_scalar(start.b, end.b, t),
      a=alpha,
    )
  }
}

///|
/// Interpolate an angle in radians along the shortest path.
pub fn interpolate_angle(start : Double, end : Double, t : Double) -> Double {
  let turn = 2.0 * @math.PI
  let mut delta = (end - start) % turn
  if delta > @math.PI {
    delta = delta - turn
  } else if delta < -@math.PI {
    delta = delta + turn
  }
  start + delta * t
}

///|
pub fn interpolate_transform(
  start : Transform2D,
  end : Transform2D,
  t : Double,
  shortest_rotation? : Bool = true,
) -> Transform2D {
  let rotation = if shortest_rotation {
    interpolate_angle(start.rotation, end.rotation, t)
  } else {
    interpolate_scalar(start.rotation, end.rotation, t)
  }
  {
    position: start.position.lerp(end.position, t),
    scale: start.scale.lerp(end.scale, t),
    rotation,
    skew: interpolate_scalar(start.skew, end.skew, t),
  }
}

///|
/// Cubic Hermite interpolation. Tangents use the same units as values.
pub fn hermite(
  start : Double,
  end : Double,
  tangent_start : Double,
  tangent_end : Double,
  t : Double,
) -> Double {
  let t2 = t * t
  let t3 = t2 * t
  let h00 = 2.0 * t3 - 3.0 * t2 + 1.0
  let h10 = t3 - 2.0 * t2 + t
  let h01 = -2.0 * t3 + 3.0 * t2
  let h11 = t3 - t2
  h00 * start + h10 * tangent_start + h01 * end + h11 * tangent_end
}

///|
/// Catmull-Rom interpolation across four scalar samples.
pub fn catmull_rom(
  previous : Double,
  start : Double,
  end : Double,
  next : Double,
  t : Double,
  tension? : Double = 0.0,
) -> Double {
  let tangent_scale = (1.0 - tension) / 2.0
  let tangent_start = (end - previous) * tangent_scale
  let tangent_end = (next - start) * tangent_scale
  hermite(start, end, tangent_start, tangent_end, t)
}

///|
/// Cubic interpolation over a value array using clamped endpoint samples.
pub fn catmull_rom_array(values : Array[Double], position : Double) -> Double {
  if values.length() == 0 {
    0.0
  } else if values.length() == 1 {
    values[0]
  } else {
    let max_index = values.length() - 1
    let x = clamp(position, 0.0, max_index.to_double())
    let index = x.to_int()
    let t = x - index.to_double()
    let previous = values[(index - 1).max(0)]
    let start = values[index]
    let end = values[(index + 1).min(max_index)]
    let next = values[(index + 2).min(max_index)]
    catmull_rom(previous, start, end, next, t)
  }
}
