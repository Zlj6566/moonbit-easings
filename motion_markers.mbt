///|
/// A named event attached to a motion timeline.
pub struct MotionMarker {
  time : Double
  name : String
  payload : String
} derive(Debug)

///|
pub fn marker(
  time : Double,
  name : String,
  payload? : String = "",
) -> MotionMarker raise MotionError {
  ensure_finite(time)
  if name.is_empty() {
    raise MotionError::InvalidMarkerName
  }
  { time, name, payload }
}

///|
pub fn MotionMarker::time(self : MotionMarker) -> Double {
  self.time
}

///|
pub fn MotionMarker::name(self : MotionMarker) -> String {
  self.name
}

///|
pub fn MotionMarker::payload(self : MotionMarker) -> String {
  self.payload
}

///|
/// Direction of playback when a marker window is traversed.
pub(all) enum MarkerDirection {
  Forward
  Backward
} derive(Eq, Debug)

///|
/// A marker together with the direction in which it was crossed.
pub(all) struct MarkerHit {
  marker : MotionMarker
  direction : MarkerDirection
} derive(Debug)

///|
pub fn MarkerHit::marker(self : MarkerHit) -> MotionMarker {
  self.marker
}

///|
pub fn MarkerHit::direction(self : MarkerHit) -> MarkerDirection {
  self.direction
}

///|
pub fn MarkerHit::time(self : MarkerHit) -> Double {
  self.marker.time
}

///|
pub fn MarkerHit::name(self : MarkerHit) -> String {
  self.marker.name
}

///|
/// A sorted marker index for transport controls, editors, and event dispatch.
pub struct MarkerTimeline {
  markers : Array[MotionMarker]
} derive(Debug)

///|
pub fn MarkerTimeline::new(markers : Array[MotionMarker]) -> MarkerTimeline {
  let sorted = markers.copy()
  sorted.sort_by(fn(left, right) {
    let order = left.time.compare(right.time)
    if order == 0 {
      left.name.compare(right.name)
    } else {
      order
    }
  })
  { markers: sorted }
}

///|
pub fn MarkerTimeline::empty() -> MarkerTimeline {
  { markers: [] }
}

///|
pub fn MarkerTimeline::markers(self : MarkerTimeline) -> Array[MotionMarker] {
  self.markers.copy()
}

///|
pub fn MarkerTimeline::length(self : MarkerTimeline) -> Int {
  self.markers.length()
}

///|
pub fn MarkerTimeline::duration(self : MarkerTimeline) -> Double {
  if self.markers.length() == 0 {
    0.0
  } else {
    self.markers[self.markers.length() - 1].time
  }
}

///|
pub fn MarkerTimeline::add(self : MarkerTimeline, value : MotionMarker) -> Unit {
  self.markers.push(value)
  self.markers.sort_by(fn(left, right) {
    let order = left.time.compare(right.time)
    if order == 0 {
      left.name.compare(right.name)
    } else {
      order
    }
  })
}

///|
pub fn MarkerTimeline::remove_at(
  self : MarkerTimeline,
  index : Int,
) -> MotionMarker? {
  if index < 0 || index >= self.markers.length() {
    None
  } else {
    Some(self.markers.remove(index))
  }
}

///|
pub fn MarkerTimeline::find(
  self : MarkerTimeline,
  name : String,
) -> Array[MotionMarker] {
  self.markers.filter(fn(item) { item.name == name })
}

///|
pub fn MarkerTimeline::next_after(
  self : MarkerTimeline,
  time : Double,
) -> MotionMarker? {
  for item in self.markers {
    if item.time > time {
      return Some(item)
    }
  }
  None
}

///|
pub fn MarkerTimeline::previous_before(
  self : MarkerTimeline,
  time : Double,
) -> MotionMarker? {
  for index in 0..<self.markers.length() {
    let reverse_index = self.markers.length() - 1 - index
    if self.markers[reverse_index].time < time {
      return Some(self.markers[reverse_index])
    }
  }
  None
}

///|
/// Return markers crossed while moving from `start` to `end`.
/// The start boundary is excluded and the end boundary is included.
pub fn MarkerTimeline::between(
  self : MarkerTimeline,
  start : Double,
  end : Double,
) -> Array[MarkerHit] {
  if start == end {
    return []
  }
  if end > start {
    let result : Array[MarkerHit] = []
    for item in self.markers {
      if item.time > start && item.time <= end {
        result.push({ marker: item, direction: Forward })
      }
    }
    result
  } else {
    let forward : Array[MarkerHit] = []
    for item in self.markers {
      if item.time >= end && item.time < start {
        forward.push({ marker: item, direction: Backward })
      }
    }
    let result : Array[MarkerHit] = []
    for index in 0..<forward.length() {
      result.push(forward[forward.length() - 1 - index])
    }
    result
  }
}

///|
pub fn MarkerTimeline::at(
  self : MarkerTimeline,
  time : Double,
  tolerance? : Double = 0.000001,
) -> Array[MotionMarker] {
  let radius = tolerance.max(0.0)
  self.markers.filter(fn(item) { (item.time - time).abs() <= radius })
}

///|
pub fn MarkerTimeline::window(
  self : MarkerTimeline,
  start : Double,
  end : Double,
) -> Array[MarkerHit] {
  self.between(start, end)
}

///|
/// A cursor for deterministic marker dispatch in a transport loop.
pub struct MarkerCursor {
  timeline : MarkerTimeline
  mut time : Double
} derive(Debug)

///|
pub fn marker_cursor(
  timeline : MarkerTimeline,
  start_time? : Double = 0.0,
) -> MarkerCursor {
  { timeline, time: start_time }
}

///|
pub fn MarkerCursor::time(self : MarkerCursor) -> Double {
  self.time
}

///|
pub fn MarkerCursor::timeline(self : MarkerCursor) -> MarkerTimeline {
  self.timeline
}

///|
pub fn MarkerCursor::seek(self : MarkerCursor, time : Double) -> Unit {
  self.time = time
}

///|
pub fn MarkerCursor::advance(
  self : MarkerCursor,
  time : Double,
) -> Array[MarkerHit] {
  let result = self.timeline.between(self.time, time)
  self.time = time
  result
}

///|
pub fn MarkerCursor::reset(self : MarkerCursor, time? : Double = 0.0) -> Unit {
  self.time = time
}

///|
/// Build a timeline from a regular sequence of marker names.
pub fn marker_sequence(
  names : Array[String],
  start : Double,
  interval : Double,
) -> MarkerTimeline raise MotionError {
  ensure_finite(start)
  ensure_finite(interval)
  let values : Array[MotionMarker] = []
  for index in 0..<names.length() {
    values.push(marker(start + index.to_double() * interval, names[index]))
  }
  MarkerTimeline::new(values)
}

///|
/// Return a copy with all marker times shifted by an offset.
pub fn shift_markers(
  timeline : MarkerTimeline,
  offset : Double,
) -> MarkerTimeline raise MotionError {
  ensure_finite(offset)
  let values : Array[MotionMarker] = []
  for item in timeline.markers() {
    values.push(marker(item.time + offset, item.name, payload=item.payload))
  }
  MarkerTimeline::new(values)
}

///|
/// Return a copy with marker times scaled around the origin.
pub fn scale_markers(
  timeline : MarkerTimeline,
  factor : Double,
) -> MarkerTimeline raise MotionError {
  ensure_finite(factor)
  let values : Array[MotionMarker] = []
  for item in timeline.markers() {
    values.push(marker(item.time * factor, item.name, payload=item.payload))
  }
  MarkerTimeline::new(values)
}
