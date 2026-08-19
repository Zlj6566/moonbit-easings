///|
/// A named scalar state used to model interaction modes and animation poses.
pub struct MotionStateNode {
  name : String
  value : Double
} derive(Debug)

///|
pub fn motion_state(
  name : String,
  value : Double,
) -> MotionStateNode raise MotionError {
  if name.is_empty() {
    raise MotionError::InvalidStateName
  }
  ensure_finite(value)
  { name, value }
}

///|
pub fn MotionStateNode::name(self : MotionStateNode) -> String {
  self.name
}

///|
pub fn MotionStateNode::value(self : MotionStateNode) -> Double {
  self.value
}

///|
/// A directed transition between two named motion states.
pub struct MotionStateTransition {
  from : String
  to : String
  duration : Double
  curve : Curve
} derive(Debug)

///|
pub fn motion_transition(
  from : String,
  to : String,
  duration : Double,
  curve? : Curve = Curve::builtin(Linear),
) -> MotionStateTransition raise MotionError {
  if from.is_empty() || to.is_empty() {
    raise MotionError::InvalidStateName
  }
  ensure_finite(duration)
  if duration <= 0.0 {
    raise MotionError::InvalidDuration(duration)
  }
  { from, to, duration, curve }
}

///|
pub fn MotionStateTransition::from(self : MotionStateTransition) -> String {
  self.from
}

///|
pub fn MotionStateTransition::to(self : MotionStateTransition) -> String {
  self.to
}

///|
pub fn MotionStateTransition::duration(self : MotionStateTransition) -> Double {
  self.duration
}

///|
pub fn MotionStateTransition::curve(self : MotionStateTransition) -> Curve {
  self.curve
}

///|
/// A transition engine with explicit transport time. State changes are
/// deterministic and do not allocate per sample.
pub struct MotionStateMachine {
  states : Array[MotionStateNode]
  transitions : Array[MotionStateTransition]
  mut current : String
  mut transition_from : String
  mut transition_to : String
  mut transition_start : Double
  mut transition_duration : Double
  mut transition_curve : Curve
  mut has_transition : Bool
} derive(Debug)

///|
fn state_index(states : Array[MotionStateNode], name : String) -> Int? {
  for index in 0..<states.length() {
    if states[index].name == name {
      return Some(index)
    }
  }
  None
}

///|
fn validate_states(states : Array[MotionStateNode]) -> Unit raise MotionError {
  if states.length() == 0 {
    raise MotionError::EmptyTrack
  }
  for left in 0..<states.length() {
    for right in (left + 1)..<states.length() {
      if states[left].name == states[right].name {
        raise MotionError::InvalidStateName
      }
    }
  }
}

///|
fn validate_transitions(
  states : Array[MotionStateNode],
  transitions : Array[MotionStateTransition],
) -> Unit raise MotionError {
  for transition in transitions {
    if state_index(states, transition.from) is None ||
      state_index(states, transition.to) is None {
      raise MotionError::InvalidStateName
    }
  }
}

///|
pub fn MotionStateMachine::new(
  states : Array[MotionStateNode],
  transitions? : Array[MotionStateTransition] = [],
  initial? : String = "",
) -> MotionStateMachine raise MotionError {
  validate_states(states)
  validate_transitions(states, transitions)
  let first = if initial.is_empty() { states[0].name } else { initial }
  if state_index(states, first) is None {
    raise MotionError::InvalidStateName
  }
  {
    states: states.copy(),
    transitions: transitions.copy(),
    current: first,
    transition_from: first,
    transition_to: first,
    transition_start: 0.0,
    transition_duration: 0.0,
    transition_curve: Curve::builtin(Linear),
    has_transition: false,
  }
}

///|
pub fn MotionStateMachine::states(
  self : MotionStateMachine,
) -> Array[MotionStateNode] {
  self.states.copy()
}

///|
pub fn MotionStateMachine::transitions(
  self : MotionStateMachine,
) -> Array[MotionStateTransition] {
  self.transitions.copy()
}

///|
pub fn MotionStateMachine::current(self : MotionStateMachine) -> String {
  self.current
}

///|
pub fn MotionStateMachine::is_transitioning(self : MotionStateMachine) -> Bool {
  self.has_transition
}

///|
fn MotionStateMachine::value_of(
  self : MotionStateMachine,
  name : String,
) -> Double {
  match state_index(self.states, name) {
    Some(index) => self.states[index].value
    None => 0.0
  }
}

///|
fn MotionStateMachine::find_transition(
  self : MotionStateMachine,
  from : String,
  to : String,
) -> MotionStateTransition? {
  for transition in self.transitions {
    if transition.from == from && transition.to == to {
      return Some(transition)
    }
  }
  None
}

///|
/// Start a transition at an arbitrary transport timestamp.
pub fn MotionStateMachine::transition_to(
  self : MotionStateMachine,
  target : String,
  now : Double,
  duration? : Double = 0.0,
  curve? : Curve = Curve::builtin(Linear),
) -> Unit raise MotionError {
  ensure_finite(now)
  if state_index(self.states, target) is None {
    raise MotionError::InvalidStateName
  }
  let selected = if duration > 0.0 {
    motion_transition(self.current, target, duration, curve~)
  } else {
    match self.find_transition(self.current, target) {
      Some(value) => value
      None => motion_transition(self.current, target, 0.000001, curve~)
    }
  }
  self.transition_from = self.current
  self.transition_to = target
  self.transition_start = now
  self.transition_duration = selected.duration
  self.transition_curve = selected.curve
  self.has_transition = true
}

///|
pub fn MotionStateMachine::sample(
  self : MotionStateMachine,
  now : Double,
) -> Double {
  if !self.has_transition {
    return self.value_of(self.current)
  }
  let ratio = (now - self.transition_start) / self.transition_duration
  if ratio >= 1.0 {
    self.current = self.transition_to
    self.has_transition = false
    return self.value_of(self.current)
  }
  if ratio <= 0.0 {
    return self.value_of(self.transition_from)
  }
  let progress = self.transition_curve.apply(ratio)
  let first = self.value_of(self.transition_from)
  let second = self.value_of(self.transition_to)
  first + (second - first) * progress
}

///|
pub fn MotionStateMachine::sample_motion(
  self : MotionStateMachine,
  now : Double,
) -> MotionSample {
  let delta = 0.0001
  let value = self.sample(now)
  let before = self.sample(now - delta)
  let after = self.sample(now + delta)
  {
    time: now,
    value,
    velocity: (after - before) / (2.0 * delta),
    acceleration: (after - 2.0 * value + before) / (delta * delta),
  }
}

///|
pub fn MotionStateMachine::complete(self : MotionStateMachine) -> Unit {
  if self.has_transition {
    self.current = self.transition_to
    self.has_transition = false
  }
}

///|
pub fn MotionStateMachine::reset(
  self : MotionStateMachine,
  state? : String = "",
) -> Unit raise MotionError {
  let target = if state.is_empty() { self.states[0].name } else { state }
  if state_index(self.states, target) is None {
    raise MotionError::InvalidStateName
  }
  self.current = target
  self.transition_from = target
  self.transition_to = target
  self.transition_start = 0.0
  self.transition_duration = 0.0
  self.has_transition = false
}

///|
pub fn MotionStateMachine::add_state(
  self : MotionStateMachine,
  state : MotionStateNode,
) -> Unit raise MotionError {
  if state_index(self.states, state.name) is Some(_) {
    raise MotionError::InvalidStateName
  }
  self.states.push(state)
}

///|
pub fn MotionStateMachine::add_transition(
  self : MotionStateMachine,
  transition : MotionStateTransition,
) -> Unit raise MotionError {
  validate_transitions(self.states, [transition])
  self.transitions.push(transition)
}

///|
pub fn MotionStateMachine::has_state(
  self : MotionStateMachine,
  name : String,
) -> Bool {
  state_index(self.states, name) is Some(_)
}

///|
pub fn MotionStateMachine::state_value(
  self : MotionStateMachine,
  name : String,
) -> Double? {
  match state_index(self.states, name) {
    Some(index) => Some(self.states[index].value)
    None => None
  }
}
