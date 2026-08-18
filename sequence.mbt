///|
/// Lifecycle state for a serial composition of scalar tweens.
pub(all) enum SequenceState {
  Before
  Active
  Gap
  After
} derive(Eq, Debug)

///|
/// A sample from a TweenSequence, including the active segment index.
pub(all) struct SequenceSample {
  time : Double
  value : Double
  index : Int
  progress : Double
  state : SequenceState
} derive(Debug)

///|
pub fn SequenceSample::time(self : SequenceSample) -> Double {
  self.time
}

///|
pub fn SequenceSample::value(self : SequenceSample) -> Double {
  self.value
}

///|
pub fn SequenceSample::index(self : SequenceSample) -> Int {
  self.index
}

///|
pub fn SequenceSample::progress(self : SequenceSample) -> Double {
  self.progress
}

///|
pub fn SequenceSample::state(self : SequenceSample) -> SequenceState {
  self.state
}

///|
/// A serial composition of Tweens with optional gaps between segments.
pub struct TweenSequence {
  tweens : Array[Tween]
  gap : Double
} derive(Debug)

///|
pub fn TweenSequence::new(
  tweens : Array[Tween],
  gap? : Double = 0.0,
) -> TweenSequence raise MotionError {
  if tweens.length() == 0 {
    raise MotionError::EmptyTrack
  }
  ensure_finite(gap)
  if gap < 0.0 {
    raise MotionError::InvalidDuration(gap)
  }
  { tweens: tweens.copy(), gap }
}

///|
pub fn TweenSequence::tweens(self : TweenSequence) -> Array[Tween] {
  self.tweens.copy()
}

///|
pub fn TweenSequence::length(self : TweenSequence) -> Int {
  self.tweens.length()
}

///|
pub fn TweenSequence::gap(self : TweenSequence) -> Double {
  self.gap
}

///|
pub fn TweenSequence::duration(self : TweenSequence) -> Double {
  let mut total = 0.0
  for index in 0..<self.tweens.length() {
    total = total + self.tweens[index].total_duration()
    if index + 1 < self.tweens.length() {
      total = total + self.gap
    }
  }
  total
}

///|
fn TweenSequence::segment_start(self : TweenSequence, index : Int) -> Double {
  let mut start = 0.0
  for cursor in 0..<index {
    start = start + self.tweens[cursor].total_duration()
    start = start + self.gap
  }
  start
}

///|
fn TweenSequence::sample_before(
  self : TweenSequence,
  time : Double,
) -> SequenceSample {
  let first = self.tweens[0].sample(0.0)
  { time, value: first.value(), index: 0, progress: 0.0, state: Before }
}

///|
fn TweenSequence::sample_after(
  self : TweenSequence,
  time : Double,
) -> SequenceSample {
  let last_index = self.tweens.length() - 1
  let last = self.tweens[last_index]
  let sample = last.sample(last.total_duration())
  {
    time,
    value: sample.value(),
    index: last_index,
    progress: 1.0,
    state: After,
  }
}

///|
/// Sample the sequence in wall-clock time. A gap holds the previous value.
pub fn TweenSequence::sample(
  self : TweenSequence,
  time : Double,
) -> SequenceSample {
  if time < 0.0 {
    return self.sample_before(time)
  }
  if time >= self.duration() {
    return self.sample_after(time)
  }
  for index in 0..<self.tweens.length() {
    let start = self.segment_start(index)
    let tween = self.tweens[index]
    let end = start + tween.total_duration()
    if time < end {
      let segment_sample = tween.sample(time - start)
      return {
        time,
        value: segment_sample.value(),
        index,
        progress: segment_sample.progress(),
        state: Active,
      }
    }
    if index + 1 < self.tweens.length() && time < end + self.gap {
      let value = tween.sample(tween.total_duration()).value()
      return { time, value, index, progress: 1.0, state: Gap }
    }
  }
  self.sample_after(time)
}

///|
pub fn TweenSequence::value_at(self : TweenSequence, time : Double) -> Double {
  self.sample(time).value()
}

///|
pub fn TweenSequence::sample_many(
  self : TweenSequence,
  count : Int,
) -> Array[SequenceSample] raise MotionError {
  if count < 2 {
    raise MotionError::InvalidSampleCount(count)
  }
  let values : Array[SequenceSample] = []
  let duration = self.duration()
  for index in 0..<count {
    let ratio = index.to_double() / (count - 1).to_double()
    values.push(self.sample(duration * ratio))
  }
  values
}

///|
/// A mutable composition helper used by editors and importers.
pub struct SequenceBuilder {
  tweens : Array[Tween]
  gap : Double
}

///|
pub fn SequenceBuilder::new(gap? : Double = 0.0) -> SequenceBuilder {
  { tweens: [], gap }
}

///|
pub fn SequenceBuilder::add(self : SequenceBuilder, tween : Tween) -> Unit {
  self.tweens.push(tween)
}

///|
pub fn SequenceBuilder::remove_at(
  self : SequenceBuilder,
  index : Int,
) -> Tween? {
  if index < 0 || index >= self.tweens.length() {
    None
  } else {
    Some(self.tweens.remove(index))
  }
}

///|
pub fn SequenceBuilder::build(
  self : SequenceBuilder,
) -> TweenSequence raise MotionError {
  TweenSequence::new(self.tweens, gap=self.gap)
}
