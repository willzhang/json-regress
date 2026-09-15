///|
fn change(trace : Json, index : Int, key : String, value : Json) -> Json {
  match trace {
    Array(rows) =>
      match rows[index] {
        Object(fields) => fields[key] = value
        _ => abort("invalid test fixture")
      }
    _ => abort("invalid test fixture")
  }
  trace
}

///|
test "two real toy-environment episodes match independent Python transitions" {
  @trajectory.assert_matches(@fixtures.rl(), @rl.rollout())
}

///|
test "action time shift and reward sign errors are detected" {
  let shifted = change(@rl.rollout(), 0, "action", {
    "shape": [],
    "dtype": "float32",
    "data": [2],
  })
  let report = @trajectory.compare(@fixtures.rl(), shifted)
  assert_eq(report.tensors[0].path, "/0/action")
  let sign_error = change(@rl.rollout(), 0, "reward", 2)
  let reward_difference : @json_regress.Difference = @trajectory.compare(
      @fixtures.rl(),
      sign_error,
    ).metadata[0]
  assert_eq(reward_difference.path, "/0/reward")
}

///|
test "time limit is not silently converted to natural termination" {
  let altered = change(
    change(@rl.rollout(), 3, "truncated", false),
    3,
    "terminated",
    true,
  )
  let report = @trajectory.compare(@fixtures.rl(), altered)
  assert_eq(report.metadata.map(fn(d) { d.path }), [
    "/3/terminated", "/3/truncated",
  ])
}

///|
test "missing end field and bad episode reset reject the exported trace" {
  let missing = @rl.rollout()
  match missing {
    Array(rows) =>
      match rows[3] {
        Object(fields) => fields.remove("truncated")
        _ => fail("expected object")
      }
    _ => fail("expected array")
  }
  let rejected = try {
    @trajectory.validate(missing)
    false
  } catch {
    @trajectory.InvalidTrajectory(_) => true
    e => raise e
  }
  assert_eq(rejected, true)
  let boundary = change(@rl.rollout(), 2, "episode_id", "goal")
  let rejected = try {
    @trajectory.validate(boundary)
    false
  } catch {
    @trajectory.InvalidTrajectory(_) => true
    e => raise e
  }
  assert_eq(rejected, true)
}
