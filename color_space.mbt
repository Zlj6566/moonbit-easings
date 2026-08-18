///|
/// Hue, saturation, value and alpha representation.
pub(all) struct Hsv {
  hue : Double
  saturation : Double
  value : Double
  alpha : Double
} derive(Debug)

///|
pub fn Hsv::hue(self : Hsv) -> Double {
  self.hue
}

///|
pub fn Hsv::saturation(self : Hsv) -> Double {
  self.saturation
}

///|
pub fn Hsv::value(self : Hsv) -> Double {
  self.value
}

///|
pub fn Hsv::alpha(self : Hsv) -> Double {
  self.alpha
}

///|
fn wrap_hue(hue : Double) -> Double {
  let wrapped = hue % 360.0
  if wrapped < 0.0 {
    wrapped + 360.0
  } else {
    wrapped
  }
}

///|
pub fn hsv(
  hue~ : Double,
  saturation~ : Double,
  value~ : Double,
  alpha? : Double = 1.0,
) -> Hsv {
  {
    hue: wrap_hue(hue),
    saturation: clamp01(saturation),
    value: clamp01(value),
    alpha: clamp01(alpha),
  }
}

///|
pub fn Rgba::to_hsv(self : Rgba) -> Hsv {
  let maximum = self.r.max(self.g).max(self.b)
  let minimum = self.r.min(self.g).min(self.b)
  let chroma = maximum - minimum
  let hue = if chroma == 0.0 {
    0.0
  } else if maximum == self.r {
    60.0 * ((self.g - self.b) / chroma % 6.0)
  } else if maximum == self.g {
    60.0 * ((self.b - self.r) / chroma + 2.0)
  } else {
    60.0 * ((self.r - self.g) / chroma + 4.0)
  }
  let saturation = if maximum == 0.0 { 0.0 } else { chroma / maximum }
  hsv(hue~, saturation~, value=maximum, alpha=self.a)
}

///|
pub fn Hsv::to_rgba(self : Hsv) -> Rgba {
  let chroma = self.value * self.saturation
  let section = self.hue / 60.0
  let x = chroma * (1.0 - (section % 2.0 - 1.0).abs())
  let (red, green, blue) = if section < 1.0 {
    (chroma, x, 0.0)
  } else if section < 2.0 {
    (x, chroma, 0.0)
  } else if section < 3.0 {
    (0.0, chroma, x)
  } else if section < 4.0 {
    (0.0, x, chroma)
  } else if section < 5.0 {
    (x, 0.0, chroma)
  } else {
    (chroma, 0.0, x)
  }
  let match_value = self.value - chroma
  rgba(
    r=red + match_value,
    g=green + match_value,
    b=blue + match_value,
    a=self.alpha,
  )
}

///|
fn hue_delta(start : Double, end : Double) -> Double {
  let mut delta = (end - start) % 360.0
  if delta > 180.0 {
    delta = delta - 360.0
  } else if delta < -180.0 {
    delta = delta + 360.0
  }
  delta
}

///|
pub fn interpolate_hsv(start : Hsv, end : Hsv, t : Double) -> Hsv {
  hsv(
    hue=start.hue + hue_delta(start.hue, end.hue) * t,
    saturation=interpolate_scalar(start.saturation, end.saturation, t),
    value=interpolate_scalar(start.value, end.value, t),
    alpha=interpolate_scalar(start.alpha, end.alpha, t),
  )
}

///|
pub fn interpolate_rgba_hsv(start : Rgba, end : Rgba, t : Double) -> Rgba {
  interpolate_hsv(start.to_hsv(), end.to_hsv(), t).to_rgba()
}

///|
pub fn Rgba::luminance(self : Rgba) -> Double {
  0.2126 * self.r + 0.7152 * self.g + 0.0722 * self.b
}
