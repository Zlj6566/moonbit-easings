///|
/// Direction of a transport clock.
pub(all) enum PlaybackDirection {
  Forward
  Reverse
} derive(Eq, Debug)

///|
pub(all) enum TransportStatus {
  Stopped
  Playing
  Paused
  Finished
} derive(Eq, Debug)

///|
/// A transport window with explicit in/out points for media scrubbing.
pub struct TransportRange {
  start : Double
  end : Double
} derive(Debug)

///|
pub fn transport_range(
  start : Double,
  end : Double,
) -> TransportRange raise MotionError {
  ensure_finite(start)
  ensure_finite(end)
  if end <= start {
    raise MotionError::InvalidDuration(end - start)
  }
  { start, end }
}

///|
pub fn TransportRange::start(self : TransportRange) -> Double {
  self.start
}

///|
pub fn TransportRange::end(self : TransportRange) -> Double {
  self.end
}

///|
pub fn TransportRange::duration(self : TransportRange) -> Double {
  self.end - self.start
}

///|
pub fn TransportRange::contains(self : TransportRange, time : Double) -> Bool {
  time >= self.start && time <= self.end
}

///|
pub fn TransportRange::clamp(self : TransportRange, time : Double) -> Double {
  time.max(self.start).min(self.end)
}

///|
pub fn TransportRange::normalized(
  self : TransportRange,
  time : Double,
) -> Double {
  clamp01((time - self.start) / self.duration())
}

///|
/// A stateful transport clock for preview, timeline scrubbing, and export.
pub struct MotionTransport {
  mut position : Double
  mut speed : Double
  mut status : TransportStatus
  mut direction : PlaybackDirection
  range : TransportRange
  markers : MarkerTimeline
} derive(Debug)

///|
pub fn MotionTransport::new(
  range : TransportRange,
  markers? : MarkerTimeline = MarkerTimeline::empty(),
) -> MotionTransport {
  {
    position: range.start,
    speed: 1.0,
    status: Stopped,
    direction: Forward,
    range,
    markers,
  }
}

///|
pub fn MotionTransport::position(self : MotionTransport) -> Double {
  self.position
}

///|
pub fn MotionTransport::speed(self : MotionTransport) -> Double {
  self.speed
}

///|
pub fn MotionTransport::status(self : MotionTransport) -> TransportStatus {
  self.status
}

///|
pub fn MotionTransport::direction(self : MotionTransport) -> PlaybackDirection {
  self.direction
}

///|
pub fn MotionTransport::range(self : MotionTransport) -> TransportRange {
  self.range
}

///|
pub fn MotionTransport::markers(self : MotionTransport) -> MarkerTimeline {
  self.markers
}

///|
pub fn MotionTransport::set_speed(
  self : MotionTransport,
  speed : Double,
) -> Unit raise MotionError {
  ensure_finite(speed)
  if speed < 0.0 {
    raise MotionError::InvalidTime(speed)
  }
  self.speed = speed
}

///|
pub fn MotionTransport::set_direction(
  self : MotionTransport,
  direction : PlaybackDirection,
) -> Unit {
  self.direction = direction
}

///|
pub fn MotionTransport::play(self : MotionTransport) -> Unit {
  self.status = Playing
}

///|
pub fn MotionTransport::pause(self : MotionTransport) -> Unit {
  if self.status is Playing {
    self.status = Paused
  }
}

///|
pub fn MotionTransport::stop(self : MotionTransport) -> Unit {
  self.position = match self.direction {
    Forward => self.range.start
    Reverse => self.range.end
  }
  self.status = Stopped
}

///|
pub fn MotionTransport::seek(
  self : MotionTransport,
  position : Double,
) -> Unit raise MotionError {
  ensure_finite(position)
  self.position = self.range.clamp(position)
  self.status = Paused
}

///|
pub fn MotionTransport::rewind(self : MotionTransport) -> Unit {
  self.position = self.range.start
  self.direction = Forward
  self.status = Paused
}

///|
pub fn MotionTransport::fast_forward(self : MotionTransport) -> Unit {
  self.position = self.range.end
  self.direction = Reverse
  self.status = Paused
}

///|
/// Advance the clock and return markers crossed by this step.
pub fn MotionTransport::advance(
  self : MotionTransport,
  delta_seconds : Double,
) -> Array[MarkerHit] raise MotionError {
  ensure_finite(delta_seconds)
  if delta_seconds < 0.0 {
    raise MotionError::InvalidTime(delta_seconds)
  }
  if !(self.status is Playing) || delta_seconds == 0.0 {
    return []
  }
  let signed_delta = match self.direction {
    Forward => delta_seconds * self.speed
    Reverse => -delta_seconds * self.speed
  }
  let next = self.position + signed_delta
  let clamped = self.range.clamp(next)
  let hits = self.markers.between(self.position, clamped)
  self.position = clamped
  if next < self.range.start || next > self.range.end {
    self.status = Finished
  }
  hits
}

///|
pub fn MotionTransport::seek_and_collect(
  self : MotionTransport,
  position : Double,
) -> Array[MarkerHit] raise MotionError {
  ensure_finite(position)
  let target = self.range.clamp(position)
  let result = self.markers.between(self.position, target)
  self.position = target
  result
}

///|
pub fn MotionTransport::normalized_position(self : MotionTransport) -> Double {
  self.range.normalized(self.position)
}

///|
pub fn MotionTransport::remaining(self : MotionTransport) -> Double {
  match self.direction {
    Forward => self.range.end - self.position
    Reverse => self.position - self.range.start
  }
}

///|
pub fn MotionTransport::elapsed(self : MotionTransport) -> Double {
  match self.direction {
    Forward => self.position - self.range.start
    Reverse => self.range.end - self.position
  }
}

///|
pub fn MotionTransport::is_at_boundary(self : MotionTransport) -> Bool {
  self.position == self.range.start || self.position == self.range.end
}

///|
pub fn MotionTransport::clone_at(
  self : MotionTransport,
  position : Double,
) -> MotionTransport {
  let copy = MotionTransport::new(self.range, markers=self.markers)
  copy.position = self.range.clamp(position)
  copy.speed = self.speed
  copy.status = self.status
  copy.direction = self.direction
  copy
}

///|
/// A fixed-rate export iterator that emits frame times and marker events.
pub struct TransportFrame {
  index : Int
  time : Double
  normalized : Double
  marker_hits : Array[MarkerHit]
} derive(Debug)

///|
pub fn TransportFrame::index(self : TransportFrame) -> Int {
  self.index
}

///|
pub fn TransportFrame::time(self : TransportFrame) -> Double {
  self.time
}

///|
pub fn TransportFrame::normalized(self : TransportFrame) -> Double {
  self.normalized
}

///|
pub fn TransportFrame::marker_hits(self : TransportFrame) -> Array[MarkerHit] {
  self.marker_hits.copy()
}

///|
pub fn transport_frames(
  range : TransportRange,
  frame_rate : Double,
  markers? : MarkerTimeline = MarkerTimeline::empty(),
) -> Array[TransportFrame] raise MotionError {
  if frame_rate <= 0.0 || frame_rate.is_nan() || frame_rate.is_inf() {
    raise MotionError::InvalidFrameRate(frame_rate)
  }
  let count = @math.floor(range.duration() * frame_rate).to_int() + 1
  let result : Array[TransportFrame] = []
  let mut previous = range.start
  for index in 0..<count {
    let time = if index == count - 1 {
      range.end
    } else {
      range.start + index.to_double() / frame_rate
    }
    result.push({
      index,
      time,
      normalized: range.normalized(time),
      marker_hits: markers.between(previous, time),
    })
    previous = time
  }
  result
}

///|
pub fn transport_frame_count(
  range : TransportRange,
  frame_rate : Double,
) -> Int {
  if frame_rate <= 0.0 {
    0
  } else {
    @math.floor(range.duration() * frame_rate).to_int() + 1
  }
}

///|
pub fn transport_time_at_frame(
  range : TransportRange,
  frame_rate : Double,
  frame : Int,
) -> Double {
  if frame <= 0 || frame_rate <= 0.0 {
    range.start
  } else {
    (range.start + frame.to_double() / frame_rate).min(range.end)
  }
}

///|
pub fn transport_progress(range : TransportRange, time : Double) -> Double {
  range.normalized(time)
}
