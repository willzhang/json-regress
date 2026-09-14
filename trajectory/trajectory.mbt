///|
pub suberror InvalidTrajectory {
  InvalidTrajectory(String)
} derive(Debug)

///|
pub suberror Mismatch {
  Mismatch(String)
} derive(Debug)

///|
pub(all) struct TensorDifference {
  path : String
  outcome : @numeric.Outcome
} derive(Debug, Eq)

///|
pub(all) struct Report {
  metadata : Array[@json_regress.Difference]
  tensors : Array[TensorDifference]
} derive(Debug, Eq)

///|
priv struct Step {
  episode : String
  index : Int
  observation : @numeric.Tensor
  action : @numeric.Tensor
  next_observation : @numeric.Tensor
  terminated : Bool
  truncated : Bool
  metadata : Json
}

///|
fn field(
  fields : Map[String, Json],
  key : String,
) -> Json raise InvalidTrajectory {
  match fields.get(key) {
    Some(value) => value
    None => raise InvalidTrajectory("missing required field: \{key}")
  }
}

///|
fn flag(
  fields : Map[String, Json],
  key : String,
) -> Bool raise InvalidTrajectory {
  match field(fields, key) {
    True => true
    False => false
    _ => raise InvalidTrajectory("\{key} must be boolean")
  }
}

///|
fn parse(document : Json) -> Array[Step] raise {
  let values = match document {
    Array(values) => values
    _ => raise InvalidTrajectory("trajectory must be an array of steps")
  }
  let rows : Array[Step] = []
  let episodes : Map[String, Bool] = Map([])
  for value in values {
    let fields = match value {
      Object(fields) => fields
      _ => raise InvalidTrajectory("step must be an object")
    }
    for key in fields.keys() {
      if ![
          "episode_id", "step", "observation", "action", "reward", "next_observation",
          "terminated", "truncated",
        ].contains(key) {
        raise InvalidTrajectory("unknown trajectory field: \{key}")
      }
    }
    let episode = match field(fields, "episode_id") {
      String(s) if s != "" => s
      _ => raise InvalidTrajectory("episode_id must be a non-empty string")
    }
    let raw_index = field(fields, "step")
    let _ = @numeric.Tensor::from_json({
      "shape": [],
      "dtype": "float64",
      "data": [raw_index],
    })
    let index = match raw_index {
      Number(n, ..) if !n.is_nan() &&
        !n.is_inf() &&
        n >= 0.0 &&
        n <= 2147483647.0 &&
        n.floor() == n => n.to_int()
      _ => raise InvalidTrajectory("step must be a non-negative Int")
    }
    let reward = field(fields, "reward")
    // Reuse numeric input validation, including preserved underflow detection.
    let _ = @numeric.Tensor::from_json({
      "shape": [],
      "dtype": "float64",
      "data": [reward],
    })
    let terminated = flag(fields, "terminated")
    let truncated = flag(fields, "truncated")
    let row : Step = {
      episode,
      index,
      terminated,
      truncated,
      observation: @numeric.Tensor::from_json(field(fields, "observation")),
      action: @numeric.Tensor::from_json(field(fields, "action")),
      next_observation: @numeric.Tensor::from_json(
        field(fields, "next_observation"),
      ),
      metadata: {
        "episode_id": episode,
        "step": index,
        "reward": reward,
        "terminated": terminated,
        "truncated": truncated,
      },
    }
    if rows.length() > 0 && rows[rows.length() - 1].episode == episode {
      let previous = rows[rows.length() - 1]
      if previous.terminated || previous.truncated {
        raise InvalidTrajectory(
          "step follows an episode end without reset: \{episode}",
        )
      }
      if previous.index == 2147483647 || index != previous.index + 1 {
        raise InvalidTrajectory("non-contiguous step index: \{episode}")
      }
      if !@numeric.compare(previous.next_observation, row.observation).is_match() {
        raise InvalidTrajectory(
          "observation does not match prior next_observation: \{episode}/\{index}",
        )
      }
    } else {
      if index != 0 || episodes.contains(episode) {
        raise InvalidTrajectory(
          "new episode must start at zero with a fresh id: \{episode}",
        )
      }
      if rows.length() > 0 {
        let previous = rows[rows.length() - 1]
        if !previous.terminated && !previous.truncated {
          raise InvalidTrajectory("episode changed without an end flag")
        }
      }
      episodes[episode] = true
    }
    rows.push(row)
  }
  rows
}

///|
pub fn validate(document : Json) -> Unit raise {
  let _ = parse(document)
}

///|
/// Own normalized trajectory schema, not a universal framework interchange format.
/// Metadata is exact except reward tolerance; all tensor fields use numeric rules.
pub fn compare(
  expected : Json,
  actual : Json,
  absolute? : Double = 0.0,
  relative? : Double = 0.0,
  max_samples? : Int = 8,
) -> Report raise {
  // Validate options even for empty traces or a metadata-only mismatch.
  let empty = @numeric.Tensor::new([0], "float64", [])
  let _ = @numeric.compare(empty, empty, absolute~, relative~, max_samples~)
  let a = parse(expected)
  let b = parse(actual)
  let rules = @json_regress.Rules::new(
    tolerances=a.mapi(fn(i, _) { { path: "/\{i}/reward", absolute, relative, } }),
  )
  let metadata = @json_regress.compare(
    Json::array(a.map(fn(row) { row.metadata })),
    Json::array(b.map(fn(row) { row.metadata })),
    rules~,
  )
  let tensors = []
  let overlap = if a.length() < b.length() { a.length() } else { b.length() }
  for i in 0..<overlap {
    for
      (name, left, right) in [
        ("observation", a[i].observation, b[i].observation),
        ("action", a[i].action, b[i].action),
        ("next_observation", a[i].next_observation, b[i].next_observation),
      ] {
      let outcome = @numeric.compare(
        left,
        right,
        absolute~,
        relative~,
        max_samples~,
      )
      if !outcome.is_match() {
        tensors.push({ path: "/\{i}/\{name}", outcome, })
      }
    }
  }
  { metadata, tensors, }
}

///|
pub fn Report::is_match(self : Report) -> Bool {
  self.metadata.is_empty() && self.tensors.is_empty()
}

///|
pub fn Report::format(self : Report) -> String {
  let parts = []
  if !self.metadata.is_empty() {
    parts.push(@json_regress.format_differences(self.metadata))
  }
  for item in self.tensors {
    parts.push("\{item.path}: \{item.outcome.format()}")
  }
  parts.join("\n")
}

///|
pub fn assert_matches(
  expected : Json,
  actual : Json,
  absolute? : Double = 0.0,
  relative? : Double = 0.0,
) -> Unit raise {
  let report = compare(expected, actual, absolute~, relative~)
  if !report.is_match() {
    raise Mismatch(report.format())
  }
}
