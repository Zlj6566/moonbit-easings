///|
/// Lifecycle state of a tween sample.
pub(all) enum TweenState {
  Before
  Active
  After
} derive(Eq, Debug)

///|
/// A value sample with enough metadata for a renderer or UI state machine.
pub(all) struct TweenSample {
  time : Double
  value : Double
  progress : Double
  cycle : Int
  state : TweenState
} derive(Debug)

///|
pub fn TweenSample::value(self : TweenSample) -> Double {
  self.value
}

///|
pub fn TweenSample::progress(self : TweenSample) -> Double {
  self.progress
}

///|
pub fn TweenSample::cycle(self : TweenSample) -> Int {
  self.cycle
}

///|
pub fn TweenSample::state(self : TweenSample) -> TweenState {
  self.state
}

///|
/// A scalar tween with delay, repeats, and optional ping-pong direction.
pub struct Tween {
  from : Double
  to : Double
  duration : Double
  delay : Double
  repeat_count : Int
  mode : Extrapolation
  curve : Curve
} derive(Debug)

///|
pub fn Tween::new(
  from : Double,
  to : Double,
  duration : Double,
  delay? : Double = 0.0,
  repeat_count? : Int = 0,
  mode? : Extrapolation = Clamp,
  curve? : Curve = Curve::builtin(Linear),
) -> Tween raise MotionError {
  ensure_finite(from)
  ensure_finite(to)
  if duration <= 0.0 {
    raise MotionError::InvalidDuration(duration)
  }
  if delay < 0.0 {
    raise MotionError::InvalidDelay(delay)
  }
  if repeat_count < 0 {
    raise MotionError::InvalidRepeatCount(repeat_count)
  }
  { from, to, duration, delay, repeat_count, mode, curve }
}

///|
pub fn Tween::from(self : Tween) -> Double {
  self.from
}

///|
pub fn Tween::to(self : Tween) -> Double {
  self.to
}

///|
pub fn Tween::duration(self : Tween) -> Double {
  self.duration
}

///|
pub fn Tween::delay(self : Tween) -> Double {
  self.delay
}

///|
pub fn Tween::repeat_count(self : Tween) -> Int {
  self.repeat_count
}

///|
pub fn Tween::total_duration(self : Tween) -> Double {
  self.delay + self.duration * (self.repeat_count + 1).to_double()
}

///|
fn Tween::value_at_progress(
  self : Tween,
  progress : Double,
  reverse : Bool,
) -> Double {
  let directed = if reverse { 1.0 - progress } else { progress }
  let eased = self.curve.apply(directed)
  self.from + (self.to - self.from) * eased
}

///|
fn Tween::sample_active(self : Tween, time : Double) -> TweenSample {
  let elapsed = time - self.delay
  let raw_cycle = @math.floor(elapsed / self.duration)
  let mut cycle = raw_cycle.to_int()
  if cycle < 0 {
    cycle = 0
  }
  if cycle > self.repeat_count {
    cycle = self.repeat_count
  }
  let cycle_start = cycle.to_double() * self.duration
  let progress = clamp01((elapsed - cycle_start) / self.duration)
  let reverse = self.mode is Mirror && cycle % 2 == 1
  {
    time,
    value: self.value_at_progress(progress, reverse),
    progress,
    cycle,
    state: Active,
  }
}

///|
/// Sample a tween at wall-clock time. Time and duration use the same units.
pub fn Tween::sample(self : Tween, time : Double) -> TweenSample {
  if time < self.delay {
    { time, value: self.from, progress: 0.0, cycle: 0, state: Before }
  } else if time >= self.total_duration() {
    let reverse = self.mode is Mirror && self.repeat_count % 2 == 1
    {
      time,
      value: self.value_at_progress(1.0, reverse),
      progress: 1.0,
      cycle: self.repeat_count,
      state: After,
    }
  } else {
    self.sample_active(time)
  }
}

///|
pub fn Tween::value_at(self : Tween, time : Double) -> Double {
  self.sample(time).value
}

///|
pub fn Tween::sample_motion(self : Tween, time : Double) -> MotionSample {
  let delta = (self.duration / 10000.0).max(0.000001)
  let value = self.value_at(time)
  let before = self.value_at(time - delta)
  let after = self.value_at(time + delta)
  {
    time,
    value,
    velocity: (after - before) / (2.0 * delta),
    acceleration: (after - 2.0 * value + before) / (delta * delta),
  }
}

///|
pub fn Tween::sample_many(
  self : Tween,
  count : Int,
) -> Array[TweenSample] raise MotionError {
  if count < 2 {
    raise MotionError::InvalidSampleCount(count)
  }
  let result : Array[TweenSample] = []
  let total = self.total_duration()
  for i in 0..<count {
    result.push(self.sample(total * i.to_double() / (count - 1).to_double()))
  }
  result
}
