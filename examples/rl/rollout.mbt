///|
fn scalar(value : Int) -> Json {
  { "shape": [], "dtype": "float32", "data": [value] }
}

///|
/// Deterministic toy environment, not an RL training algorithm.
/// Action at t changes the observed position; reward belongs to that transition.
pub fn rollout() -> Json {
  let steps : Array[Json] = []
  for (episode, actions, horizon) in [("goal", [1, 2], 4), ("time", [-1, 1], 2)] {
    let mut position = 0
    for index, action in actions {
      let next = position + action
      let terminated = next >= 3
      let truncated = index + 1 >= horizon
      let distance = (3 - next).abs()
      steps.push({
        "episode_id": episode,
        "step": index,
        "observation": scalar(position),
        "action": scalar(action),
        "reward": -distance,
        "next_observation": scalar(next),
        "terminated": terminated,
        "truncated": truncated,
      })
      position = next
      if terminated || truncated {
        break
      }
    }
  }
  Json::array(steps)
}
