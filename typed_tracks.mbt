///|
/// A point keyframe for UI, camera, and sprite motion tracks.
pub struct Point2Keyframe {
  time : Double
  value : Point2
  curve : Curve
} derive(Debug)

///|
pub fn point2_keyframe(
  time : Double,
  value~ : Point2,
  curve? : Curve = Curve::builtin(Linear),
) -> Point2Keyframe raise MotionError {
  ensure_finite(time)
  { time, value, curve }
}

///|
pub fn Point2Keyframe::time(self : Point2Keyframe) -> Double {
  self.time
}

///|
pub fn Point2Keyframe::value(self : Point2Keyframe) -> Point2 {
  self.value
}

///|
pub fn Point2Keyframe::curve(self : Point2Keyframe) -> Curve {
  self.curve
}

///|
/// A validated 2D point track with the same boundary policies as ScalarTrack.
pub struct Point2Track {
  frames : Array[Point2Keyframe]
} derive(Debug)

///|
pub fn Point2Track::new(
  frames : Array[Point2Keyframe],
) -> Point2Track raise MotionError {
  if frames.length() == 0 {
    raise MotionError::EmptyTrack
  }
  for i in 1..<frames.length() {
    if frames[i].time <= frames[i - 1].time {
      raise MotionError::NonIncreasingKeyframe(
        frames[i - 1].time,
        frames[i].time,
      )
    }
  }
  { frames: frames.copy() }
}

///|
pub fn Point2Track::keyframes(self : Point2Track) -> Array[Point2Keyframe] {
  self.frames.copy()
}

///|
pub fn Point2Track::length(self : Point2Track) -> Int {
  self.frames.length()
}

///|
pub fn Point2Track::start_time(self : Point2Track) -> Double {
  self.frames[0].time
}

///|
pub fn Point2Track::end_time(self : Point2Track) -> Double {
  self.frames[self.frames.length() - 1].time
}

///|
pub fn Point2Track::duration(self : Point2Track) -> Double {
  self.end_time() - self.start_time()
}

///|
fn Point2Track::inside(self : Point2Track, time : Double) -> Point2 {
  let last = self.frames.length() - 1
  if time <= self.frames[0].time {
    return self.frames[0].value
  }
  if time >= self.frames[last].time {
    return self.frames[last].value
  }
  for index in 0..<last {
    let left = self.frames[index]
    let right = self.frames[index + 1]
    if time <= right.time {
      let ratio = (time - left.time) / (right.time - left.time)
      return left.value.lerp(right.value, left.curve.apply(ratio))
    }
  }
  self.frames[last].value
}

///|
fn Point2Track::continue_value(self : Point2Track, time : Double) -> Point2 {
  let last = self.frames.length() - 1
  if time < self.start_time() && last > 0 {
    let first = self.frames[0]
    let next = self.frames[1]
    let ratio = (time - first.time) / (next.time - first.time)
    return first.value.lerp(next.value, ratio)
  }
  if time > self.end_time() && last > 0 {
    let before = self.frames[last - 1]
    let end = self.frames[last]
    let ratio = (time - before.time) / (end.time - before.time)
    return before.value.lerp(end.value, ratio)
  }
  self.inside(time)
}

///|
pub fn Point2Track::sample(
  self : Point2Track,
  time : Double,
  mode? : Extrapolation = Clamp,
) -> Point2 {
  let mapped = map_track_time(time, self.start_time(), self.end_time(), mode)
  if mode is Continue {
    self.continue_value(mapped)
  } else {
    self.inside(mapped)
  }
}

///|
pub fn Point2Track::sample_many(
  self : Point2Track,
  count : Int,
  mode? : Extrapolation = Clamp,
) -> Array[Point2] raise MotionError {
  if count < 2 {
    raise MotionError::InvalidSampleCount(count)
  }
  let result : Array[Point2] = []
  for index in 0..<count {
    let ratio = index.to_double() / (count - 1).to_double()
    result.push(self.sample(self.start_time() + ratio * self.duration(), mode~))
  }
  result
}

///|
/// A 3D keyframe for camera and scene transforms.
pub struct Point3Keyframe {
  time : Double
  value : Point3
  curve : Curve
} derive(Debug)

///|
pub fn point3_keyframe(
  time : Double,
  value~ : Point3,
  curve? : Curve = Curve::builtin(Linear),
) -> Point3Keyframe raise MotionError {
  ensure_finite(time)
  { time, value, curve }
}

///|
pub fn Point3Keyframe::time(self : Point3Keyframe) -> Double {
  self.time
}

///|
pub fn Point3Keyframe::value(self : Point3Keyframe) -> Point3 {
  self.value
}

///|
pub fn Point3Keyframe::curve(self : Point3Keyframe) -> Curve {
  self.curve
}

///|
pub struct Point3Track {
  frames : Array[Point3Keyframe]
} derive(Debug)

///|
pub fn Point3Track::new(
  frames : Array[Point3Keyframe],
) -> Point3Track raise MotionError {
  if frames.length() == 0 {
    raise MotionError::EmptyTrack
  }
  for i in 1..<frames.length() {
    if frames[i].time <= frames[i - 1].time {
      raise MotionError::NonIncreasingKeyframe(
        frames[i - 1].time,
        frames[i].time,
      )
    }
  }
  { frames: frames.copy() }
}

///|
pub fn Point3Track::keyframes(self : Point3Track) -> Array[Point3Keyframe] {
  self.frames.copy()
}

///|
pub fn Point3Track::length(self : Point3Track) -> Int {
  self.frames.length()
}

///|
pub fn Point3Track::start_time(self : Point3Track) -> Double {
  self.frames[0].time
}

///|
pub fn Point3Track::end_time(self : Point3Track) -> Double {
  self.frames[self.frames.length() - 1].time
}

///|
pub fn Point3Track::duration(self : Point3Track) -> Double {
  self.end_time() - self.start_time()
}

///|
fn Point3Track::inside(self : Point3Track, time : Double) -> Point3 {
  let last = self.frames.length() - 1
  if time <= self.frames[0].time {
    return self.frames[0].value
  }
  if time >= self.frames[last].time {
    return self.frames[last].value
  }
  for index in 0..<last {
    let left = self.frames[index]
    let right = self.frames[index + 1]
    if time <= right.time {
      let ratio = (time - left.time) / (right.time - left.time)
      return left.value.lerp(right.value, left.curve.apply(ratio))
    }
  }
  self.frames[last].value
}

///|
fn Point3Track::continue_value(self : Point3Track, time : Double) -> Point3 {
  let last = self.frames.length() - 1
  if time < self.start_time() && last > 0 {
    let first = self.frames[0]
    let next = self.frames[1]
    let ratio = (time - first.time) / (next.time - first.time)
    return first.value.lerp(next.value, ratio)
  }
  if time > self.end_time() && last > 0 {
    let before = self.frames[last - 1]
    let end = self.frames[last]
    let ratio = (time - before.time) / (end.time - before.time)
    return before.value.lerp(end.value, ratio)
  }
  self.inside(time)
}

///|
pub fn Point3Track::sample(
  self : Point3Track,
  time : Double,
  mode? : Extrapolation = Clamp,
) -> Point3 {
  let mapped = map_track_time(time, self.start_time(), self.end_time(), mode)
  if mode is Continue {
    self.continue_value(mapped)
  } else {
    self.inside(mapped)
  }
}

///|
pub fn Point3Track::sample_many(
  self : Point3Track,
  count : Int,
  mode? : Extrapolation = Clamp,
) -> Array[Point3] raise MotionError {
  if count < 2 {
    raise MotionError::InvalidSampleCount(count)
  }
  let result : Array[Point3] = []
  for index in 0..<count {
    let ratio = index.to_double() / (count - 1).to_double()
    result.push(self.sample(self.start_time() + ratio * self.duration(), mode~))
  }
  result
}

///|
/// A color keyframe track for gradients, fades, and compositing timelines.
pub struct RgbaKeyframe {
  time : Double
  value : Rgba
  curve : Curve
} derive(Debug)

///|
pub fn rgba_keyframe(
  time : Double,
  value~ : Rgba,
  curve? : Curve = Curve::builtin(Linear),
) -> RgbaKeyframe raise MotionError {
  ensure_finite(time)
  { time, value, curve }
}

///|
pub struct RgbaTrack {
  frames : Array[RgbaKeyframe]
  premultiplied : Bool
} derive(Debug)

///|
pub fn RgbaTrack::new(
  frames : Array[RgbaKeyframe],
  premultiplied? : Bool = false,
) -> RgbaTrack raise MotionError {
  if frames.length() == 0 {
    raise MotionError::EmptyTrack
  }
  for i in 1..<frames.length() {
    if frames[i].time <= frames[i - 1].time {
      raise MotionError::NonIncreasingKeyframe(
        frames[i - 1].time,
        frames[i].time,
      )
    }
  }
  { frames: frames.copy(), premultiplied }
}

///|
pub fn RgbaTrack::keyframes(self : RgbaTrack) -> Array[RgbaKeyframe] {
  self.frames.copy()
}

///|
pub fn RgbaTrack::length(self : RgbaTrack) -> Int {
  self.frames.length()
}

///|
pub fn RgbaTrack::start_time(self : RgbaTrack) -> Double {
  self.frames[0].time
}

///|
pub fn RgbaTrack::end_time(self : RgbaTrack) -> Double {
  self.frames[self.frames.length() - 1].time
}

///|
pub fn RgbaTrack::duration(self : RgbaTrack) -> Double {
  self.end_time() - self.start_time()
}

///|
fn RgbaTrack::inside(self : RgbaTrack, time : Double) -> Rgba {
  let last = self.frames.length() - 1
  if time <= self.frames[0].time {
    return self.frames[0].value
  }
  if time >= self.frames[last].time {
    return self.frames[last].value
  }
  for index in 0..<last {
    let left = self.frames[index]
    let right = self.frames[index + 1]
    if time <= right.time {
      let ratio = (time - left.time) / (right.time - left.time)
      return interpolate_rgba(
        left.value,
        right.value,
        left.curve.apply(ratio),
        premultiplied=self.premultiplied,
      )
    }
  }
  self.frames[last].value
}

///|
fn RgbaTrack::continue_value(self : RgbaTrack, time : Double) -> Rgba {
  let last = self.frames.length() - 1
  if time < self.start_time() && last > 0 {
    let first = self.frames[0]
    let next = self.frames[1]
    let ratio = (time - first.time) / (next.time - first.time)
    return interpolate_rgba(
      first.value,
      next.value,
      ratio,
      premultiplied=self.premultiplied,
    )
  }
  if time > self.end_time() && last > 0 {
    let before = self.frames[last - 1]
    let end = self.frames[last]
    let ratio = (time - before.time) / (end.time - before.time)
    return interpolate_rgba(
      before.value,
      end.value,
      ratio,
      premultiplied=self.premultiplied,
    )
  }
  self.inside(time)
}

///|
pub fn RgbaTrack::sample(
  self : RgbaTrack,
  time : Double,
  mode? : Extrapolation = Clamp,
) -> Rgba {
  let mapped = map_track_time(time, self.start_time(), self.end_time(), mode)
  if mode is Continue {
    self.continue_value(mapped)
  } else {
    self.inside(mapped)
  }
}

///|
pub fn RgbaTrack::sample_many(
  self : RgbaTrack,
  count : Int,
  mode? : Extrapolation = Clamp,
) -> Array[Rgba] raise MotionError {
  if count < 2 {
    raise MotionError::InvalidSampleCount(count)
  }
  let result : Array[Rgba] = []
  for index in 0..<count {
    let ratio = index.to_double() / (count - 1).to_double()
    result.push(self.sample(self.start_time() + ratio * self.duration(), mode~))
  }
  result
}

///|
/// A transform track that interpolates translation, scale, rotation, and skew.
pub struct TransformKeyframe {
  time : Double
  value : Transform2D
  curve : Curve
} derive(Debug)

///|
pub fn transform_keyframe(
  time : Double,
  value~ : Transform2D,
  curve? : Curve = Curve::builtin(Linear),
) -> TransformKeyframe raise MotionError {
  ensure_finite(time)
  { time, value, curve }
}

///|
pub struct TransformTrack {
  frames : Array[TransformKeyframe]
  shortest_rotation : Bool
} derive(Debug)

///|
pub fn TransformTrack::new(
  frames : Array[TransformKeyframe],
  shortest_rotation? : Bool = true,
) -> TransformTrack raise MotionError {
  if frames.length() == 0 {
    raise MotionError::EmptyTrack
  }
  for i in 1..<frames.length() {
    if frames[i].time <= frames[i - 1].time {
      raise MotionError::NonIncreasingKeyframe(
        frames[i - 1].time,
        frames[i].time,
      )
    }
  }
  { frames: frames.copy(), shortest_rotation }
}

///|
pub fn TransformTrack::keyframes(
  self : TransformTrack,
) -> Array[TransformKeyframe] {
  self.frames.copy()
}

///|
pub fn TransformTrack::length(self : TransformTrack) -> Int {
  self.frames.length()
}

///|
pub fn TransformTrack::start_time(self : TransformTrack) -> Double {
  self.frames[0].time
}

///|
pub fn TransformTrack::end_time(self : TransformTrack) -> Double {
  self.frames[self.frames.length() - 1].time
}

///|
pub fn TransformTrack::duration(self : TransformTrack) -> Double {
  self.end_time() - self.start_time()
}

///|
fn TransformTrack::inside(self : TransformTrack, time : Double) -> Transform2D {
  let last = self.frames.length() - 1
  if time <= self.frames[0].time {
    return self.frames[0].value
  }
  if time >= self.frames[last].time {
    return self.frames[last].value
  }
  for index in 0..<last {
    let left = self.frames[index]
    let right = self.frames[index + 1]
    if time <= right.time {
      let ratio = (time - left.time) / (right.time - left.time)
      return interpolate_transform(
        left.value,
        right.value,
        left.curve.apply(ratio),
        shortest_rotation=self.shortest_rotation,
      )
    }
  }
  self.frames[last].value
}

///|
fn TransformTrack::continue_value(
  self : TransformTrack,
  time : Double,
) -> Transform2D {
  let last = self.frames.length() - 1
  if time < self.start_time() && last > 0 {
    let first = self.frames[0]
    let next = self.frames[1]
    let ratio = (time - first.time) / (next.time - first.time)
    return interpolate_transform(
      first.value,
      next.value,
      ratio,
      shortest_rotation=self.shortest_rotation,
    )
  }
  if time > self.end_time() && last > 0 {
    let before = self.frames[last - 1]
    let end = self.frames[last]
    let ratio = (time - before.time) / (end.time - before.time)
    return interpolate_transform(
      before.value,
      end.value,
      ratio,
      shortest_rotation=self.shortest_rotation,
    )
  }
  self.inside(time)
}

///|
pub fn TransformTrack::sample(
  self : TransformTrack,
  time : Double,
  mode? : Extrapolation = Clamp,
) -> Transform2D {
  let mapped = map_track_time(time, self.start_time(), self.end_time(), mode)
  if mode is Continue {
    self.continue_value(mapped)
  } else {
    self.inside(mapped)
  }
}

///|
pub fn TransformTrack::sample_many(
  self : TransformTrack,
  count : Int,
  mode? : Extrapolation = Clamp,
) -> Array[Transform2D] raise MotionError {
  if count < 2 {
    raise MotionError::InvalidSampleCount(count)
  }
  let result : Array[Transform2D] = []
  for index in 0..<count {
    let ratio = index.to_double() / (count - 1).to_double()
    result.push(self.sample(self.start_time() + ratio * self.duration(), mode~))
  }
  result
}

///|
/// Shared time mapping for typed tracks. Continue is handled by scalar or
/// vector-specific sampling; Repeat and Mirror always remain in the track.
fn map_track_time(
  time : Double,
  first : Double,
  last : Double,
  mode : Extrapolation,
) -> Double {
  let span = last - first
  if span <= 0.0 || mode is Clamp {
    return if time < first { first } else if time > last { last } else { time }
  }
  if time >= first && time <= last {
    return time
  }
  match mode {
    Continue => time
    Repeat => {
      let offset = time - first
      let cycles = @math.floor(offset / span)
      first + offset - cycles * span
    }
    Mirror => {
      let offset = time - first
      let cycles = @math.floor(offset / span)
      let part = offset - cycles * span
      if cycles.to_int() % 2 == 0 {
        first + part
      } else {
        last - part
      }
    }
    Clamp => if time < first { first } else { last }
  }
}
