///|
fn showcase(
  label : String,
  fixture : Json,
  actual : @numeric.Tensor,
  absolute : Double,
) -> Unit raise {
  let expected = @numeric.Tensor::from_json(fixture, pointer="/expected")
  @numeric.assert_matches(expected, actual, absolute~)
  println(
    "\{label} PASS: \{@numeric.compare(expected, actual, absolute~).format()}",
  )
  let corrupted = actual.data()
  corrupted[1] = corrupted[1] + 0.1
  let mutant = @numeric.Tensor::new(actual.shape(), actual.dtype(), corrupted)
  let outcome = @numeric.compare(expected, mutant, absolute~)
  assert_eq(outcome.is_match(), false)
  println("\{label} deliberate mutation detected:\n\{outcome.format()}")
}

///|
fn run() -> Unit raise {
  showcase(
    "MoonXi CPU Linear",
    @fixtures.linear(),
    @integration.linear_output(),
    0.0,
  )
  showcase(
    "Tiny world model (untrained, deterministic)",
    @fixtures.world_model(),
    @integration.world_model_output(),
    0.000001,
  )
}

///|
fn main {
  try! run()
}
