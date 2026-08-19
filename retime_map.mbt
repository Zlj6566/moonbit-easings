///|
/// A monotone time remapping segment. Input and output intervals are kept
/// explicit so media editors can preserve source timestamps while changing
/// presentation speed.
pub struct RetimeSegment {
  input_start : Double
  input_end : Double
  output_start : Double
  output_end : Double
  curve : Curve
} derive(Debug)

///|
pub fn retime_segment(
  input_start : Double,
  input_end : Double,
  output_start : Double,
  output_end : Double,
  curve? : Curve = Curve::builtin(Linear),
) -> RetimeSegment raise MotionError {
  ensure_finite(input_start)
  ensure_finite(input_end)
  ensure_finite(output_start)
  ensure_finite(output_end)
  if input_end <= input_start || output_end <= output_start {
    raise MotionError::InvalidRetimeSegment
  }
  { input_start, input_end, output_start, output_end, curve }
}

///|
pub fn RetimeSegment::input_start(self : RetimeSegment) -> Double {
  self.input_start
}

///|
pub fn RetimeSegment::input_end(self : RetimeSegment) -> Double {
  self.input_end
}

///|
pub fn RetimeSegment::output_start(self : RetimeSegment) -> Double {
  self.output_start
}

///|
pub fn RetimeSegment::output_end(self : RetimeSegment) -> Double {
  self.output_end
}

///|
pub fn RetimeSegment::curve(self : RetimeSegment) -> Curve {
  self.curve
}

///|
pub fn RetimeSegment::input_duration(self : RetimeSegment) -> Double {
  self.input_end - self.input_start
}

///|
pub fn RetimeSegment::output_duration(self : RetimeSegment) -> Double {
  self.output_end - self.output_start
}

///|
pub fn RetimeSegment::speed(self : RetimeSegment) -> Double {
  self.input_duration() / self.output_duration()
}

///|
pub fn RetimeSegment::contains_input(
  self : RetimeSegment,
  time : Double,
) -> Bool {
  time >= self.input_start && time <= self.input_end
}

///|
pub fn RetimeSegment::contains_output(
  self : RetimeSegment,
  time : Double,
) -> Bool {
  time >= self.output_start && time <= self.output_end
}

///|
pub fn RetimeSegment::map(self : RetimeSegment, input : Double) -> Double {
  let ratio = clamp01((input - self.input_start) / self.input_duration())
  self.output_start + self.output_duration() * self.curve.apply(ratio)
}

///|
pub fn RetimeSegment::unmap(self : RetimeSegment, output : Double) -> Double {
  let target = clamp01((output - self.output_start) / self.output_duration())
  let mut low = 0.0
  let mut high = 1.0
  for _ in 0..<12 {
    let middle = (low + high) / 2.0
    if self.curve.apply(middle) < target {
      low = middle
    } else {
      high = middle
    }
  }
  self.input_start + self.input_duration() * ((low + high) / 2.0)
}

///|
pub fn RetimeSegment::derivative(
  self : RetimeSegment,
  input : Double,
) -> Double {
  let ratio = clamp01((input - self.input_start) / self.input_duration())
  self.output_duration() / self.input_duration() * self.curve.derivative(ratio)
}

///|
pub struct RetimeMap {
  segments : Array[RetimeSegment]
  input_start : Double
  input_end : Double
  output_start : Double
  output_end : Double
} derive(Debug)

///|
pub fn RetimeMap::new(
  segments : Array[RetimeSegment],
) -> RetimeMap raise MotionError {
  if segments.length() == 0 {
    raise MotionError::EmptyTrack
  }
  for index in 1..<segments.length() {
    let previous = segments[index - 1]
    let current = segments[index]
    if current.input_start < previous.input_end ||
      current.output_start < previous.output_end {
      raise MotionError::InvalidRetimeSegment
    }
  }
  {
    segments: segments.copy(),
    input_start: segments[0].input_start,
    input_end: segments[segments.length() - 1].input_end,
    output_start: segments[0].output_start,
    output_end: segments[segments.length() - 1].output_end,
  }
}

///|
pub fn RetimeMap::segments(self : RetimeMap) -> Array[RetimeSegment] {
  self.segments.copy()
}

///|
pub fn RetimeMap::length(self : RetimeMap) -> Int {
  self.segments.length()
}

///|
pub fn RetimeMap::input_start(self : RetimeMap) -> Double {
  self.input_start
}

///|
pub fn RetimeMap::input_end(self : RetimeMap) -> Double {
  self.input_end
}

///|
pub fn RetimeMap::output_start(self : RetimeMap) -> Double {
  self.output_start
}

///|
pub fn RetimeMap::output_end(self : RetimeMap) -> Double {
  self.output_end
}

///|
fn RetimeMap::find_input(self : RetimeMap, time : Double) -> RetimeSegment {
  if time <= self.input_start {
    return self.segments[0]
  }
  for segment in self.segments {
    if time <= segment.input_end {
      return segment
    }
  }
  self.segments[self.segments.length() - 1]
}

///|
fn RetimeMap::find_output(self : RetimeMap, time : Double) -> RetimeSegment {
  if time <= self.output_start {
    return self.segments[0]
  }
  for segment in self.segments {
    if time <= segment.output_end {
      return segment
    }
  }
  self.segments[self.segments.length() - 1]
}

///|
/// Map a source timestamp to presentation time. Gaps clamp to the adjacent
/// segment, which is deterministic for scrubbing and export.
pub fn RetimeMap::map(self : RetimeMap, input : Double) -> Double {
  let segment = self.find_input(input)
  if input < segment.input_start {
    segment.output_start
  } else if input > segment.input_end && segment.input_end == self.input_end {
    segment.output_end
  } else {
    segment.map(input)
  }
}

///|
pub fn RetimeMap::unmap(self : RetimeMap, output : Double) -> Double {
  let segment = self.find_output(output)
  if output < segment.output_start {
    segment.input_start
  } else if output > segment.output_end && segment.output_end == self.output_end {
    segment.input_end
  } else {
    segment.unmap(output)
  }
}

///|
pub fn RetimeMap::derivative(self : RetimeMap, input : Double) -> Double {
  self.find_input(input).derivative(input)
}

///|
pub fn RetimeMap::sample(
  self : RetimeMap,
  count : Int,
) -> Array[SamplePoint] raise MotionError {
  if count < 2 {
    raise MotionError::InvalidSampleCount(count)
  }
  let result : Array[SamplePoint] = []
  for index in 0..<count {
    let ratio = index.to_double() / (count - 1).to_double()
    let input = self.input_start + self.input_duration() * ratio
    result.push({ time: input, value: self.map(input), frame: index })
  }
  result
}

///|
pub fn RetimeMap::input_duration(self : RetimeMap) -> Double {
  self.input_end - self.input_start
}

///|
pub fn RetimeMap::output_duration(self : RetimeMap) -> Double {
  self.output_end - self.output_start
}

///|
/// Build a map by appending non-overlapping source and presentation ranges.
pub struct RetimeMapBuilder {
  segments : Array[RetimeSegment]
} derive(Debug)

///|
pub fn RetimeMapBuilder::new() -> RetimeMapBuilder {
  { segments: [] }
}

///|
pub fn RetimeMapBuilder::add(
  self : RetimeMapBuilder,
  segment : RetimeSegment,
) -> RetimeMapBuilder raise MotionError {
  self.segments.push(segment)
  self.segments.sort_by(fn(left, right) {
    left.input_start.compare(right.input_start)
  })
  let _ = RetimeMap::new(self.segments)
  self
}

///|
pub fn RetimeMapBuilder::length(self : RetimeMapBuilder) -> Int {
  self.segments.length()
}

///|
pub fn RetimeMapBuilder::build(
  self : RetimeMapBuilder,
) -> RetimeMap raise MotionError {
  RetimeMap::new(self.segments)
}

///|
pub fn retime_linear(
  input_start : Double,
  input_end : Double,
  output_start : Double,
  output_end : Double,
) -> RetimeMap raise MotionError {
  RetimeMap::new([
    retime_segment(input_start, input_end, output_start, output_end),
  ])
}

///|
pub fn RetimeMap::reverse(self : RetimeMap) -> RetimeMap raise MotionError {
  let reversed : Array[RetimeSegment] = []
  for index in 0..<self.segments.length() {
    let segment = self.segments[self.segments.length() - 1 - index]
    reversed.push(
      retime_segment(
        self.input_end - segment.input_end + self.input_start,
        self.input_end - segment.input_start + self.input_start,
        self.output_end - segment.output_end + self.output_start,
        self.output_end - segment.output_start + self.output_start,
        curve=segment.curve,
      ),
    )
  }
  RetimeMap::new(reversed)
}

///|
pub fn RetimeMap::scale_output(
  self : RetimeMap,
  factor : Double,
) -> RetimeMap raise MotionError {
  ensure_finite(factor)
  if factor <= 0.0 {
    raise MotionError::InvalidRetimeSegment
  }
  let scaled : Array[RetimeSegment] = []
  for segment in self.segments {
    scaled.push(
      retime_segment(
        segment.input_start,
        segment.input_end,
        self.output_start + (segment.output_start - self.output_start) * factor,
        self.output_start + (segment.output_end - self.output_start) * factor,
        curve=segment.curve,
      ),
    )
  }
  RetimeMap::new(scaled)
}

///|
pub fn RetimeMap::shift_output(
  self : RetimeMap,
  offset : Double,
) -> RetimeMap raise MotionError {
  ensure_finite(offset)
  let shifted : Array[RetimeSegment] = []
  for segment in self.segments {
    shifted.push(
      retime_segment(
        segment.input_start,
        segment.input_end,
        segment.output_start + offset,
        segment.output_end + offset,
        curve=segment.curve,
      ),
    )
  }
  RetimeMap::new(shifted)
}

///|
pub fn compose_retime(
  first : RetimeMap,
  second : RetimeMap,
  samples_per_segment? : Int = 32,
) -> RetimeMap raise MotionError {
  if first.output_start != second.input_start ||
    first.output_end != second.input_end {
    raise MotionError::InvalidRetimeSegment
  }
  let samples = samples_per_segment.max(2)
  let result : Array[RetimeSegment] = []
  for index in 0..<first.length() {
    let source = first.segments[index]
    let start = source.input_start
    let end = source.input_end
    let first_output = second.map(source.map(start))
    let last_output = second.map(source.map(end))
    result.push(retime_segment(start, end, first_output, last_output))
    let _ = samples
  }
  RetimeMap::new(result)
}
