///|
/// A named scalar channel with editor-friendly activation and weighting.
pub struct ScalarChannel {
  name : String
  track : ScalarTrack
  enabled : Bool
  weight : Double
  offset : Double
} derive(Debug)

///|
pub fn scalar_channel(
  name : String,
  track : ScalarTrack,
  enabled? : Bool = true,
  weight? : Double = 1.0,
  offset? : Double = 0.0,
) -> ScalarChannel raise MotionError {
  if name.is_empty() {
    raise MotionError::InvalidChannelName
  }
  ensure_finite(weight)
  ensure_finite(offset)
  if weight < 0.0 {
    raise MotionError::InvalidThreshold(weight)
  }
  { name, track, enabled, weight, offset }
}

///|
pub fn ScalarChannel::name(self : ScalarChannel) -> String {
  self.name
}

///|
pub fn ScalarChannel::track(self : ScalarChannel) -> ScalarTrack {
  self.track
}

///|
pub fn ScalarChannel::enabled(self : ScalarChannel) -> Bool {
  self.enabled
}

///|
pub fn ScalarChannel::weight(self : ScalarChannel) -> Double {
  self.weight
}

///|
pub fn ScalarChannel::offset(self : ScalarChannel) -> Double {
  self.offset
}

///|
pub fn ScalarChannel::sample(
  self : ScalarChannel,
  time : Double,
  mode? : Extrapolation = Clamp,
) -> Double {
  self.track.sample(time, mode~) + self.offset
}

///|
pub fn ScalarChannel::with_enabled(
  self : ScalarChannel,
  enabled : Bool,
) -> ScalarChannel {
  { ..self, enabled, }
}

///|
pub fn ScalarChannel::with_weight(
  self : ScalarChannel,
  weight : Double,
) -> ScalarChannel raise MotionError {
  ensure_finite(weight)
  if weight < 0.0 {
    raise MotionError::InvalidThreshold(weight)
  }
  { ..self, weight, }
}

///|
pub fn ScalarChannel::with_offset(
  self : ScalarChannel,
  offset : Double,
) -> ScalarChannel raise MotionError {
  ensure_finite(offset)
  { ..self, offset, }
}

///|
pub fn ScalarChannel::duration(self : ScalarChannel) -> Double {
  self.track.duration()
}

///|
pub fn ScalarChannel::start_time(self : ScalarChannel) -> Double {
  self.track.start_time()
}

///|
pub fn ScalarChannel::end_time(self : ScalarChannel) -> Double {
  self.track.end_time()
}

///|
/// The combined result at one timestamp. `weighted_value` is the normalized
/// blend of enabled channels; individual values remain available for output.
pub(all) struct BundleSample {
  time : Double
  names : Array[String]
  values : Array[Double]
  weighted_value : Double
  active_weight : Double
} derive(Debug)

///|
pub fn BundleSample::time(self : BundleSample) -> Double {
  self.time
}

///|
pub fn BundleSample::names(self : BundleSample) -> Array[String] {
  self.names.copy()
}

///|
pub fn BundleSample::values(self : BundleSample) -> Array[Double] {
  self.values.copy()
}

///|
pub fn BundleSample::length(self : BundleSample) -> Int {
  self.values.length()
}

///|
pub fn BundleSample::value_at(self : BundleSample, index : Int) -> Double? {
  if index < 0 || index >= self.values.length() {
    None
  } else {
    Some(self.values[index])
  }
}

///|
pub fn BundleSample::value_named(self : BundleSample, name : String) -> Double? {
  for index in 0..<self.names.length() {
    if self.names[index] == name {
      return Some(self.values[index])
    }
  }
  None
}

///|
pub fn BundleSample::weighted_value(self : BundleSample) -> Double {
  self.weighted_value
}

///|
pub fn BundleSample::active_weight(self : BundleSample) -> Double {
  self.active_weight
}

///|
/// A group of synchronized scalar tracks for UI properties, camera channels,
/// or a compact control stream exported to a runtime.
pub struct ScalarTrackBundle {
  channels : Array[ScalarChannel]
  start_time : Double
  end_time : Double
} derive(Debug)

///|
fn validate_channel_names(
  channels : Array[ScalarChannel],
) -> Unit raise MotionError {
  for left in 0..<channels.length() {
    for right in (left + 1)..<channels.length() {
      if channels[left].name == channels[right].name {
        raise MotionError::InvalidChannelName
      }
    }
  }
}

///|
pub fn ScalarTrackBundle::new(
  channels : Array[ScalarChannel],
) -> ScalarTrackBundle raise MotionError {
  if channels.length() == 0 {
    raise MotionError::EmptyTrack
  }
  validate_channel_names(channels)
  let mut start = channels[0].start_time()
  let mut finish = channels[0].end_time()
  for channel in channels {
    start = start.min(channel.start_time())
    finish = finish.max(channel.end_time())
  }
  { channels: channels.copy(), start_time: start, end_time: finish }
}

///|
pub fn ScalarTrackBundle::channels(
  self : ScalarTrackBundle,
) -> Array[ScalarChannel] {
  self.channels.copy()
}

///|
pub fn ScalarTrackBundle::length(self : ScalarTrackBundle) -> Int {
  self.channels.length()
}

///|
pub fn ScalarTrackBundle::start_time(self : ScalarTrackBundle) -> Double {
  self.start_time
}

///|
pub fn ScalarTrackBundle::end_time(self : ScalarTrackBundle) -> Double {
  self.end_time
}

///|
pub fn ScalarTrackBundle::duration(self : ScalarTrackBundle) -> Double {
  self.end_time - self.start_time
}

///|
pub fn ScalarTrackBundle::find(
  self : ScalarTrackBundle,
  name : String,
) -> ScalarChannel? {
  for channel in self.channels {
    if channel.name == name {
      return Some(channel)
    }
  }
  None
}

///|
pub fn ScalarTrackBundle::sample(
  self : ScalarTrackBundle,
  time : Double,
  mode? : Extrapolation = Clamp,
) -> BundleSample {
  let names : Array[String] = []
  let values : Array[Double] = []
  let mut weighted_total = 0.0
  let mut active_weight = 0.0
  for channel in self.channels {
    let value = channel.sample(time, mode~)
    names.push(channel.name)
    values.push(value)
    if channel.enabled && channel.weight > 0.0 {
      weighted_total = weighted_total + value * channel.weight
      active_weight = active_weight + channel.weight
    }
  }
  {
    time,
    names,
    values,
    weighted_value: if active_weight == 0.0 {
      0.0
    } else {
      weighted_total / active_weight
    },
    active_weight,
  }
}

///|
pub fn ScalarTrackBundle::sample_many(
  self : ScalarTrackBundle,
  count : Int,
  mode? : Extrapolation = Clamp,
) -> Array[BundleSample] raise MotionError {
  if count < 2 {
    raise MotionError::InvalidSampleCount(count)
  }
  let result : Array[BundleSample] = []
  for index in 0..<count {
    let ratio = index.to_double() / (count - 1).to_double()
    let time = self.start_time + self.duration() * ratio
    result.push(self.sample(time, mode~))
  }
  result
}

///|
pub fn ScalarTrackBundle::set_enabled(
  self : ScalarTrackBundle,
  name : String,
  enabled : Bool,
) -> ScalarTrackBundle raise MotionError {
  let result : Array[ScalarChannel] = []
  let mut found = false
  for channel in self.channels {
    if channel.name == name {
      result.push(channel.with_enabled(enabled))
      found = true
    } else {
      result.push(channel)
    }
  }
  if !found {
    raise MotionError::InvalidChannelName
  }
  ScalarTrackBundle::new(result)
}

///|
pub fn ScalarTrackBundle::set_weight(
  self : ScalarTrackBundle,
  name : String,
  weight : Double,
) -> ScalarTrackBundle raise MotionError {
  let result : Array[ScalarChannel] = []
  let mut found = false
  for channel in self.channels {
    if channel.name == name {
      result.push(channel.with_weight(weight))
      found = true
    } else {
      result.push(channel)
    }
  }
  if !found {
    raise MotionError::InvalidChannelName
  }
  ScalarTrackBundle::new(result)
}

///|
pub fn ScalarTrackBundle::with_channel(
  self : ScalarTrackBundle,
  channel : ScalarChannel,
) -> ScalarTrackBundle raise MotionError {
  let result : Array[ScalarChannel] = []
  for existing in self.channels {
    if existing.name != channel.name {
      result.push(existing)
    }
  }
  result.push(channel)
  ScalarTrackBundle::new(result)
}

///|
pub fn ScalarTrackBundle::without(
  self : ScalarTrackBundle,
  name : String,
) -> ScalarTrackBundle raise MotionError {
  let result : Array[ScalarChannel] = []
  for channel in self.channels {
    if channel.name != name {
      result.push(channel)
    }
  }
  ScalarTrackBundle::new(result)
}

///|
/// Blend two bundles by channel name. Missing channels are carried through
/// from the bundle that contains them.
pub fn blend_bundles(
  first : ScalarTrackBundle,
  second : ScalarTrackBundle,
  amount : Double,
) -> ScalarTrackBundle raise MotionError {
  let weight = clamp01(amount)
  let result : Array[ScalarChannel] = []
  for left in first.channels {
    match second.find(left.name) {
      Some(right) => {
        let frames : Array[Keyframe] = []
        let count = left.track
          .keyframes()
          .length()
          .max(right.track.keyframes().length())
        let left_frames = left.track.keyframes()
        let right_frames = right.track.keyframes()
        for index in 0..<count {
          let l = left_frames[index.min(left_frames.length() - 1)]
          let r = right_frames[index.min(right_frames.length() - 1)]
          frames.push(
            keyframe(
              l.time * (1.0 - weight) + r.time * weight,
              l.value * (1.0 - weight) + r.value * weight,
            ),
          )
        }
        result.push(
          scalar_channel(
            left.name,
            ScalarTrack::new(frames),
            enabled=left.enabled || right.enabled,
            weight=left.weight * (1.0 - weight) + right.weight * weight,
            offset=left.offset * (1.0 - weight) + right.offset * weight,
          ),
        )
      }
      None => result.push(left)
    }
  }
  for right in second.channels {
    if first.find(right.name) is None {
      result.push(right)
    }
  }
  ScalarTrackBundle::new(result)
}

///|
pub struct ScalarTrackBundleBuilder {
  channels : Array[ScalarChannel]
} derive(Debug)

///|
pub fn ScalarTrackBundleBuilder::new() -> ScalarTrackBundleBuilder {
  { channels: [] }
}

///|
pub fn ScalarTrackBundleBuilder::add(
  self : ScalarTrackBundleBuilder,
  channel : ScalarChannel,
) -> ScalarTrackBundleBuilder raise MotionError {
  for existing in self.channels {
    if existing.name == channel.name {
      raise MotionError::InvalidChannelName
    }
  }
  self.channels.push(channel)
  self
}

///|
pub fn ScalarTrackBundleBuilder::remove(
  self : ScalarTrackBundleBuilder,
  name : String,
) -> Bool {
  for index in 0..<self.channels.length() {
    if self.channels[index].name == name {
      let _ = self.channels.remove(index)
      return true
    }
  }
  false
}

///|
pub fn ScalarTrackBundleBuilder::length(self : ScalarTrackBundleBuilder) -> Int {
  self.channels.length()
}

///|
pub fn ScalarTrackBundleBuilder::build(
  self : ScalarTrackBundleBuilder,
) -> ScalarTrackBundle raise MotionError {
  ScalarTrackBundle::new(self.channels)
}
