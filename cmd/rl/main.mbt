///|
fn run() -> Unit raise {
  let expected = @fixtures.rl()
  let actual = @environment.rollout()
  @trajectory.assert_matches(expected, actual)
  println(
    "RL trajectory PASS: 4 transitions, 2 episodes; separate natural/time-limit end flags",
  )
  match actual {
    Array(rows) =>
      match rows[0] {
        Object(fields) =>
          fields["action"] = { "shape": [], "dtype": "float32", "data": [2] }
        _ => abort("expected object")
      }
    _ => abort("expected trace")
  }
  let report = @trajectory.compare(expected, actual)
  assert_eq(report.is_match(), false)
  println("Deliberate action shift detected:\n\{report.format()}")
}

///|
fn main {
  try! run()
}
