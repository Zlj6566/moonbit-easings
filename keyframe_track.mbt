///|
/// Build a scalar track from strictly increasing keyframes.
pub fn ScalarTrack::new(
  frames : Array[Keyframe],
) -> ScalarTrack raise MotionError {
  if frames.length() == 0 {
    raise MotionError::EmptyTrack
  }
  for i in 0..<frames.length() {
    ensure_finite(frames[i].time)
    ensure_finite(frames[i].value)
    if i > 0 && frames[i].time <= frames[i - 1].time {
      raise MotionError::NonIncreasingKeyframe(
        frames[i - 1].time,
        frames[i].time,
      )
    }
  }
  { frames: frames.copy() }
}

///|
fn ScalarTrack::track_time(
  self : ScalarTrack,
  time : Double,
  mode : Extrapolation,
) -> Double {
  let first = self.start_time()
  let last = self.end_time()
  let span = last - first
  if span <= 0.0 || mode is Clamp {
    if time < first {
      first
    } else if time > last {
      last
    } else {
      time
    }
  } else if time < first {
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
      Clamp => first
    }
  } else if time > last {
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
      Clamp => last
    }
  } else {
    time
  }
}

///|
fn ScalarTrack::sample_track_inside(
  self : ScalarTrack,
  time : Double,
) -> Double {
  let last_index = self.frames.length() - 1
  if time <= self.frames[0].time {
    return self.frames[0].value
  }
  if time >= self.frames[last_index].time {
    return self.frames[last_index].value
  }
  let mut segment = 0
  for i in 0..<last_index {
    if self.frames[i + 1].time >= time {
      segment = i
      break
    }
  }
  let left = self.frames[segment]
  let right = self.frames[segment + 1]
  let ratio = (time - left.time) / (right.time - left.time)
  let progress = left.curve.apply(ratio)
  left.value + (right.value - left.value) * progress
}

///|
fn ScalarTrack::extrapolate_track(self : ScalarTrack, time : Double) -> Double {
  let first = self.frames[0]
  let last_index = self.frames.length() - 1
  let last = self.frames[last_index]
  if time < first.time {
    if last_index == 0 {
      first.value
    } else {
      let next = self.frames[1]
      let slope = (next.value - first.value) / (next.time - first.time)
      first.value + (time - first.time) * slope
    }
  } else if time > last.time {
    if last_index == 0 {
      last.value
    } else {
      let before = self.frames[last_index - 1]
      let slope = (last.value - before.value) / (last.time - before.time)
      last.value + (time - last.time) * slope
    }
  } else {
    self.sample_track_inside(time)
  }
}

///|
/// Sample at an arbitrary time using the selected boundary policy.
pub fn ScalarTrack::sample(
  self : ScalarTrack,
  time : Double,
  mode? : Extrapolation = Clamp,
) -> Double {
  let mapped = self.track_time(time, mode)
  if mode is Continue {
    self.extrapolate_track(mapped)
  } else {
    self.sample_track_inside(mapped)
  }
}

///|
/// Estimate velocity with a central difference that respects track duration.
pub fn ScalarTrack::velocity(
  self : ScalarTrack,
  time : Double,
  mode? : Extrapolation = Clamp,
) -> Double {
  let delta = if self.duration() <= 0.0 {
    0.0001
  } else {
    (self.duration() / 10000.0).max(0.000001)
  }
  (self.sample(time + delta, mode~) - self.sample(time - delta, mode~)) /
  (2.0 * delta)
}

///|
pub fn ScalarTrack::sample_motion(
  self : ScalarTrack,
  time : Double,
  mode? : Extrapolation = Clamp,
) -> MotionSample {
  let delta = if self.duration() <= 0.0 {
    0.0001
  } else {
    (self.duration() / 10000.0).max(0.000001)
  }
  let value = self.sample(time, mode~)
  let before = self.sample(time - delta, mode~)
  let after = self.sample(time + delta, mode~)
  {
    time,
    value,
    velocity: (after - before) / (2.0 * delta),
    acceleration: (after - 2.0 * value + before) / (delta * delta),
  }
}

///|
/// A mutable builder useful for editors that add frames interactively.
pub struct TrackBuilder {
  frames : Array[Keyframe]
}

///|
pub fn TrackBuilder::new() -> TrackBuilder {
  { frames: [] }
}

///|
pub fn TrackBuilder::add(self : TrackBuilder, frame : Keyframe) -> Unit {
  self.frames.push(frame)
  self.frames.sort_by(fn(a, b) { a.time.compare(b.time) })
}

///|
pub fn TrackBuilder::remove_at(self : TrackBuilder, index : Int) -> Keyframe? {
  if index < 0 || index >= self.frames.length() {
    None
  } else {
    Some(self.frames.remove(index))
  }
}

///|
pub fn TrackBuilder::replace(
  self : TrackBuilder,
  index : Int,
  frame : Keyframe,
) -> Bool {
  if index < 0 || index >= self.frames.length() {
    false
  } else {
    self.frames[index] = frame
    self.frames.sort_by(fn(a, b) { a.time.compare(b.time) })
    true
  }
}

///|
pub fn TrackBuilder::build(
  self : TrackBuilder,
) -> ScalarTrack raise MotionError {
  ScalarTrack::new(self.frames)
}
