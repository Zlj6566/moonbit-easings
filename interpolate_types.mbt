///|
/// Two-dimensional point for UI and 2D media transforms.
pub(all) struct Point2 {
  x : Double
  y : Double
} derive(Debug)

///|
pub fn point2(x~ : Double, y~ : Double) -> Point2 {
  { x, y }
}

///|
pub fn Point2::x(self : Point2) -> Double {
  self.x
}

///|
pub fn Point2::y(self : Point2) -> Double {
  self.y
}

///|
pub fn Point2::lerp(self : Point2, other : Point2, t : Double) -> Point2 {
  { x: self.x + (other.x - self.x) * t, y: self.y + (other.y - self.y) * t }
}

///|
pub fn Point2::distance(self : Point2, other : Point2) -> Double {
  @math.hypot(other.x - self.x, other.y - self.y)
}

///|
/// Three-dimensional point for camera, scene, and 3D keyframe data.
pub(all) struct Point3 {
  x : Double
  y : Double
  z : Double
} derive(Debug)

///|
pub fn point3(x~ : Double, y~ : Double, z~ : Double) -> Point3 {
  { x, y, z }
}

///|
pub fn Point3::x(self : Point3) -> Double {
  self.x
}

///|
pub fn Point3::y(self : Point3) -> Double {
  self.y
}

///|
pub fn Point3::z(self : Point3) -> Double {
  self.z
}

///|
pub fn Point3::lerp(self : Point3, other : Point3, t : Double) -> Point3 {
  {
    x: self.x + (other.x - self.x) * t,
    y: self.y + (other.y - self.y) * t,
    z: self.z + (other.z - self.z) * t,
  }
}

///|
/// RGBA color stored in the normalized [0, 1] range.
pub(all) struct Rgba {
  r : Double
  g : Double
  b : Double
  a : Double
} derive(Debug)

///|
pub fn rgba(r~ : Double, g~ : Double, b~ : Double, a? : Double = 1.0) -> Rgba {
  { r: clamp01(r), g: clamp01(g), b: clamp01(b), a: clamp01(a) }
}

///|
pub fn Rgba::red(self : Rgba) -> Double {
  self.r
}

///|
pub fn Rgba::green(self : Rgba) -> Double {
  self.g
}

///|
pub fn Rgba::blue(self : Rgba) -> Double {
  self.b
}

///|
pub fn Rgba::alpha(self : Rgba) -> Double {
  self.a
}

///|
/// 2D affine transform represented as translation, scale, rotation and skew.
pub(all) struct Transform2D {
  position : Point2
  scale : Point2
  rotation : Double
  skew : Double
} derive(Debug)

///|
pub fn transform2d(
  position~ : Point2,
  scale~ : Point2,
  rotation~ : Double,
  skew? : Double = 0.0,
) -> Transform2D {
  { position, scale, rotation, skew }
}

///|
pub fn Transform2D::position(self : Transform2D) -> Point2 {
  self.position
}

///|
pub fn Transform2D::scale(self : Transform2D) -> Point2 {
  self.scale
}

///|
pub fn Transform2D::rotation(self : Transform2D) -> Double {
  self.rotation
}

///|
pub fn Transform2D::skew(self : Transform2D) -> Double {
  self.skew
}
