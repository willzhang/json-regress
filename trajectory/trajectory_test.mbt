///|
fn scalar(n : Double) -> Json {
  { "shape": [], "dtype": "float32", "data": [n] }
}

///|
fn row(
  episode? : String = "a",
  step? : Int = 0,
  observation? : Double = 0.0,
  action? : Double = 1.0,
  next? : Double = 1.0,
  reward? : Double = -2.0,
  terminated? : Bool = false,
  truncated? : Bool = false,
) -> Json {
  {
    "episode_id": episode,
    "step": step,
    "observation": scalar(observation),
    "action": scalar(action),
    "reward": reward,
    "next_observation": scalar(next),
    "terminated": terminated,
    "truncated": truncated,
  }
}

///|
fn rejected(value : Json) -> Bool raise {
  try {
    @trajectory.validate(value)
    false
  } catch {
    @trajectory.InvalidTrajectory(_) => true
    e => raise e
  }
}

///|
test "aligned rollout and independent episode end flags are valid" {
  let trace : Json = [
    row(),
    row(step=1, observation=1.0, next=3.0, terminated=true),
    row(episode="b", terminated=true, truncated=true),
  ]
  @trajectory.assert_matches(trace, trace)
  @trajectory.validate([])
  @trajectory.validate([row()]) // A prefix may end before the episode does.
}

///|
test "invalid timing continuity and reset boundaries fail before comparison" {
  for
    trace in [
      Json::array([row(step=1)]),
      [row(), row(step=2, observation=1.0)],
      [row(), row(step=1, observation=2.0)],
      [row(terminated=true), row(step=1, observation=1.0)],
      [row(), row(episode="b")],
      [row(truncated=true), row(episode="b", truncated=true), row()],
    ] {
    assert_eq(rejected(trace), true)
  }
}

///|
test "action shifts reward sign and separate flags produce field-level failures" {
  let expected : Json = [row(terminated=true)]
  let action = @trajectory.compare(expected, [row(action=2.0, terminated=true)])
  assert_eq(action.is_match(), false)
  assert_eq(action.tensors[0].path, "/0/action")
  let reward = @trajectory.compare(expected, [row(reward=2.0, terminated=true)])
  assert_eq(reward.metadata[0].path, "/0/reward")
  let flags = @trajectory.compare(expected, [row(truncated=true)])
  assert_eq(flags.metadata.map(fn(d) { d.path }), [
    "/0/terminated", "/0/truncated",
  ])
  assert_eq(@trajectory.compare(expected, []).is_match(), false)
}

///|
test "missing or merged end flags and wrong scalar types are rejected" {
  for value in [Json::null(), { "done": true }, { "episode_id": "a" }] {
    assert_eq(rejected(Json::array([value])), true)
  }
  assert_eq(rejected([row(episode="")]), true)
}
