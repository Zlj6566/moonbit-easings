///|
/// Playback policy for a reusable motion clip.
pub(all) enum ClipLoopMode {
  Once
  Repeat
  PingPong
} derive(Eq, Debug)

///|
/// A named, timestamped scalar motion clip with optional marker events.
pub struct MotionClip {
  name : String
  track : ScalarTrack
  markers : MarkerTimeline
  loop_mode : ClipLoopMode
} derive(Debug)

///|
pub fn motion_clip(
  name : String,
  track : ScalarTrack,
  markers? : MarkerTimeline = MarkerTimeline::empty(),
  loop_mode? : ClipLoopMode = Once,
) -> MotionClip raise MotionError {
  if name.is_empty() {
    raise MotionError::InvalidStateName
  }
  { name, track, markers, loop_mode }
}

///|
pub fn MotionClip::name(self : MotionClip) -> String {
  self.name
}

///|
pub fn MotionClip::track(self : MotionClip) -> ScalarTrack {
  self.track
}

///|
pub fn MotionClip::markers(self : MotionClip) -> MarkerTimeline {
  self.markers
}

///|
pub fn MotionClip::loop_mode(self : MotionClip) -> ClipLoopMode {
  self.loop_mode
}

///|
pub fn MotionClip::start_time(self : MotionClip) -> Double {
  self.track.start_time()
}

///|
pub fn MotionClip::end_time(self : MotionClip) -> Double {
  self.track.end_time()
}

///|
pub fn MotionClip::duration(self : MotionClip) -> Double {
  self.track.duration()
}

///|
fn MotionClip::map_time(self : MotionClip, time : Double) -> Double {
  let start = self.start_time()
  let duration = self.duration()
  if duration <= 0.0 || self.loop_mode is Once {
    return time.max(start).min(self.end_time())
  }
  let offset = time - start
  let cycles = @math.floor(offset / duration).to_int()
  let phase = offset - cycles.to_double() * duration
  if self.loop_mode is Repeat {
    start + phase
  } else if cycles % 2 == 0 {
    start + phase
  } else {
    self.end_time() - phase
  }
}

///|
pub fn MotionClip::sample(self : MotionClip, time : Double) -> Double {
  self.track.sample(self.map_time(time))
}

///|
pub fn MotionClip::sample_motion(
  self : MotionClip,
  time : Double,
) -> MotionSample {
  let mapped = self.map_time(time)
  self.track.sample_motion(mapped)
}

///|
pub fn MotionClip::sample_many(
  self : MotionClip,
  count : Int,
) -> Array[SamplePoint] raise MotionError {
  if count < 2 {
    raise MotionError::InvalidSampleCount(count)
  }
  let result : Array[SamplePoint] = []
  for index in 0..<count {
    let ratio = index.to_double() / (count - 1).to_double()
    let time = self.start_time() + self.duration() * ratio
    result.push({ time, value: self.sample(time), frame: index })
  }
  result
}

///|
pub fn MotionClip::markers_between(
  self : MotionClip,
  start : Double,
  end : Double,
) -> Array[MarkerHit] {
  self.markers.between(self.map_time(start), self.map_time(end))
}

///|
pub fn MotionClip::with_loop_mode(
  self : MotionClip,
  loop_mode : ClipLoopMode,
) -> MotionClip {
  { ..self, loop_mode, }
}

///|
pub fn MotionClip::with_markers(
  self : MotionClip,
  markers : MarkerTimeline,
) -> MotionClip {
  { ..self, markers, }
}

///|
pub fn MotionClip::shift(
  self : MotionClip,
  offset : Double,
) -> MotionClip raise MotionError {
  let frames : Array[Keyframe] = []
  for frame in self.track.keyframes() {
    frames.push(keyframe(frame.time + offset, frame.value, curve=frame.curve))
  }
  motion_clip(
    self.name,
    ScalarTrack::new(frames),
    markers=shift_markers(self.markers, offset),
    loop_mode=self.loop_mode,
  )
}

///|
pub fn MotionClip::scale_time(
  self : MotionClip,
  factor : Double,
) -> MotionClip raise MotionError {
  ensure_finite(factor)
  if factor <= 0.0 {
    raise MotionError::InvalidDuration(factor)
  }
  let frames : Array[Keyframe] = []
  for frame in self.track.keyframes() {
    frames.push(keyframe(frame.time * factor, frame.value, curve=frame.curve))
  }
  motion_clip(
    self.name,
    ScalarTrack::new(frames),
    markers=scale_markers(self.markers, factor),
    loop_mode=self.loop_mode,
  )
}

///|
/// A clip placed at a start offset in a larger composition.
pub struct ClipSequenceItem {
  clip : MotionClip
  start : Double
  weight : Double
} derive(Debug)

///|
pub fn sequence_item(
  clip : MotionClip,
  start : Double,
  weight? : Double = 1.0,
) -> ClipSequenceItem raise MotionError {
  ensure_finite(start)
  ensure_finite(weight)
  if weight < 0.0 {
    raise MotionError::InvalidThreshold(weight)
  }
  { clip, start, weight }
}

///|
pub fn ClipSequenceItem::clip(self : ClipSequenceItem) -> MotionClip {
  self.clip
}

///|
pub fn ClipSequenceItem::start(self : ClipSequenceItem) -> Double {
  self.start
}

///|
pub fn ClipSequenceItem::end(self : ClipSequenceItem) -> Double {
  self.start + self.clip.duration()
}

///|
pub fn ClipSequenceItem::weight(self : ClipSequenceItem) -> Double {
  self.weight
}

///|
/// A sequence compositor that averages overlapping clip contributions.
pub struct ClipSequence {
  items : Array[ClipSequenceItem]
  duration : Double
} derive(Debug)

///|
pub fn ClipSequence::new(
  items : Array[ClipSequenceItem],
) -> ClipSequence raise MotionError {
  if items.length() == 0 {
    raise MotionError::EmptyTrack
  }
  let sorted = items.copy()
  sorted.sort_by(fn(left, right) { left.start.compare(right.start) })
  let mut duration = 0.0
  for item in sorted {
    duration = duration.max(item.end())
  }
  { items: sorted, duration }
}

///|
pub fn ClipSequence::items(self : ClipSequence) -> Array[ClipSequenceItem] {
  self.items.copy()
}

///|
pub fn ClipSequence::length(self : ClipSequence) -> Int {
  self.items.length()
}

///|
pub fn ClipSequence::duration(self : ClipSequence) -> Double {
  self.duration
}

///|
pub fn ClipSequence::sample(self : ClipSequence, time : Double) -> Double {
  let mut total = 0.0
  let mut weight = 0.0
  for item in self.items {
    if time >= item.start && time <= item.end() && item.weight > 0.0 {
      total = total + item.clip.sample(time - item.start) * item.weight
      weight = weight + item.weight
    }
  }
  if weight == 0.0 {
    if time < self.items[0].start {
      self.items[0].clip.sample(0.0)
    } else {
      self.items[self.items.length() - 1].clip.sample(time)
    }
  } else {
    total / weight
  }
}

///|
pub fn ClipSequence::sample_many(
  self : ClipSequence,
  count : Int,
) -> Array[SamplePoint] raise MotionError {
  if count < 2 {
    raise MotionError::InvalidSampleCount(count)
  }
  let result : Array[SamplePoint] = []
  for index in 0..<count {
    let ratio = index.to_double() / (count - 1).to_double()
    let time = self.duration * ratio
    result.push({ time, value: self.sample(time), frame: index })
  }
  result
}

///|
pub fn ClipSequence::markers_between(
  self : ClipSequence,
  start : Double,
  end : Double,
) -> Array[MarkerHit] {
  let result : Array[MarkerHit] = []
  for item in self.items {
    let local_start = start - item.start
    let local_end = end - item.start
    for hit in item.clip.markers_between(local_start, local_end) {
      result.push(hit)
    }
  }
  result.sort_by(fn(left, right) { left.time().compare(right.time()) })
  result
}

///|
pub struct ClipSequenceBuilder {
  items : Array[ClipSequenceItem]
} derive(Debug)

///|
pub fn ClipSequenceBuilder::new() -> ClipSequenceBuilder {
  { items: [] }
}

///|
pub fn ClipSequenceBuilder::add(
  self : ClipSequenceBuilder,
  item : ClipSequenceItem,
) -> ClipSequenceBuilder {
  self.items.push(item)
  self
}

///|
pub fn ClipSequenceBuilder::add_at(
  self : ClipSequenceBuilder,
  clip : MotionClip,
  start : Double,
  weight? : Double = 1.0,
) -> ClipSequenceBuilder raise MotionError {
  self.items.push(sequence_item(clip, start, weight~))
  self
}

///|
pub fn ClipSequenceBuilder::length(self : ClipSequenceBuilder) -> Int {
  self.items.length()
}

///|
pub fn ClipSequenceBuilder::build(
  self : ClipSequenceBuilder,
) -> ClipSequence raise MotionError {
  ClipSequence::new(self.items)
}

///|
/// A small library for resolving named clips at runtime.
pub struct MotionClipLibrary {
  clips : Array[MotionClip]
} derive(Debug)

///|
pub fn MotionClipLibrary::new() -> MotionClipLibrary {
  { clips: [] }
}

///|
pub fn MotionClipLibrary::add(
  self : MotionClipLibrary,
  clip : MotionClip,
) -> Unit {
  for index in 0..<self.clips.length() {
    if self.clips[index].name == clip.name {
      self.clips[index] = clip
      return
    }
  }
  self.clips.push(clip)
}

///|
pub fn MotionClipLibrary::remove(
  self : MotionClipLibrary,
  name : String,
) -> MotionClip? {
  for index in 0..<self.clips.length() {
    if self.clips[index].name == name {
      return Some(self.clips.remove(index))
    }
  }
  None
}

///|
pub fn MotionClipLibrary::find(
  self : MotionClipLibrary,
  name : String,
) -> MotionClip? {
  for clip in self.clips {
    if clip.name == name {
      return Some(clip)
    }
  }
  None
}

///|
pub fn MotionClipLibrary::clips(self : MotionClipLibrary) -> Array[MotionClip] {
  self.clips.copy()
}

///|
pub fn MotionClipLibrary::length(self : MotionClipLibrary) -> Int {
  self.clips.length()
}

///|
pub fn MotionClipLibrary::total_duration(self : MotionClipLibrary) -> Double {
  let mut total = 0.0
  for clip in self.clips {
    total = total + clip.duration()
  }
  total
}
