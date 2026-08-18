///|
/// A named scalar track placed on a shared media timeline.
pub struct TrackSlot {
  name : String
  track : ScalarTrack
  offset : Double
  enabled : Bool
} derive(Debug)

///|
pub fn track_slot(
  name : String,
  track : ScalarTrack,
  offset? : Double = 0.0,
  enabled? : Bool = true,
) -> TrackSlot {
  { name, track, offset, enabled }
}

///|
pub fn TrackSlot::name(self : TrackSlot) -> String {
  self.name
}

///|
pub fn TrackSlot::track(self : TrackSlot) -> ScalarTrack {
  self.track
}

///|
pub fn TrackSlot::offset(self : TrackSlot) -> Double {
  self.offset
}

///|
pub fn TrackSlot::enabled(self : TrackSlot) -> Bool {
  self.enabled
}

///|
pub(all) struct TimelineValue {
  name : String
  value : Double
} derive(Debug)

///|
pub fn TimelineValue::name(self : TimelineValue) -> String {
  self.name
}

///|
pub fn TimelineValue::value(self : TimelineValue) -> Double {
  self.value
}

///|
/// A deterministic collection of named scalar tracks.
pub struct Timeline {
  slots : Array[TrackSlot]
} derive(Debug)

///|
pub fn Timeline::new() -> Timeline {
  { slots: [] }
}

///|
pub fn Timeline::add(self : Timeline, slot : TrackSlot) -> Unit {
  self.slots.push(slot)
}

///|
pub fn Timeline::remove(self : Timeline, name : String) -> Bool {
  match self.slots.search_by(fn(slot) { slot.name == name }) {
    None => false
    Some(index) => {
      ignore(self.slots.remove(index))
      true
    }
  }
}

///|
pub fn Timeline::set_enabled(
  self : Timeline,
  name : String,
  enabled : Bool,
) -> Bool {
  match self.slots.search_by(fn(slot) { slot.name == name }) {
    None => false
    Some(index) => {
      let old = self.slots[index]
      self.slots[index] = { ..old, enabled, }
      true
    }
  }
}

///|
pub fn Timeline::track_count(self : Timeline) -> Int {
  self.slots.length()
}

///|
pub fn Timeline::tracks(self : Timeline) -> Array[TrackSlot] {
  self.slots.copy()
}

///|
pub fn Timeline::duration(self : Timeline) -> Double {
  let mut result = 0.0
  for slot in self.slots {
    let end = slot.offset + slot.track.duration()
    if slot.enabled && end > result {
      result = end
    }
  }
  result
}

///|
/// Sample every enabled track at a timeline coordinate.
pub fn Timeline::sample(
  self : Timeline,
  time : Double,
  mode? : Extrapolation = Clamp,
) -> Array[TimelineValue] {
  let result : Array[TimelineValue] = []
  for slot in self.slots {
    if slot.enabled {
      result.push({
        name: slot.name,
        value: slot.track.sample(time - slot.offset, mode~),
      })
    }
  }
  result
}

///|
/// Sample a timeline on a deterministic export grid.
pub fn Timeline::sample_window(
  self : Timeline,
  config : SamplingConfig,
  mode? : Extrapolation = Clamp,
) -> Array[Array[TimelineValue]] {
  let count = config.frame_count()
  let result : Array[Array[TimelineValue]] = []
  let step = 1.0 / config.frame_rate
  for frame in 0..<count {
    let time = if config.include_end && frame == count - 1 {
      config.end
    } else {
      config.start + frame.to_double() * step
    }
    result.push(self.sample(time, mode~))
  }
  result
}
