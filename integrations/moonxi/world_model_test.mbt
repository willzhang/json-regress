///|
test "real deterministic dynamics inference matches independent scalar math" {
  let expected = @numeric.Tensor::from_json(
    @fixtures.world_model(),
    pointer="/expected",
  )
  let actual = @json_regress_moonxi.world_model_output()
  @numeric.assert_matches(expected, actual, absolute=0.000001)
  let corrupt = actual.data()
  corrupt[1] = corrupt[1] + 0.01
  let result = @numeric.compare(
    expected,
    @numeric.Tensor::new(actual.shape(), actual.dtype(), corrupt),
    absolute=0.000001,
  )
  assert_eq(result.is_match(), false)
  match result {
    Values(s) => assert_eq(s.samples[0].coordinate, [0, 1])
    _ => fail("expected latent-coordinate mismatch")
  }
}

///|
test "world model latent axis swap and nonfinite output fail closed" {
  let expected = @numeric.Tensor::from_json(
    @fixtures.world_model(),
    pointer="/expected",
  )
  let actual = @json_regress_moonxi.world_model_output()
  assert_eq(
    @numeric.compare(
      expected,
      @numeric.Tensor::new([2, 1], "float32", actual.data()),
    ).is_match(),
    false,
  )
  let rejected = try {
    let _ = @numeric.Tensor::new([1, 2], "float32", [0.0 / 0.0, 1.0])
    false
  } catch {
    @numeric.InvalidInput(_) => true
  }
  assert_eq(rejected, true)
}

///|
test "three-step real dynamics exposes nine checkpoints against independent reference" {
  let expected = @fixtures.world_model_checkpoints()
  let actual = @json_regress_moonxi.world_model_checkpoints("test")
  let result = @checking.evaluate(expected, actual, {
    "schema_version": 1,
    "mode": "checkpoints",
    "absolute": 0.000001,
    "variable_metadata": ["backend", "generator"],
  })
  assert_eq(result.exit_code(), 0, msg=result.format())
  match result.to_json() {
    Object(f) =>
      match f["statistics"] {
        Object(stats) =>
          assert_eq(stats["compared_checkpoints"], Json::number(9.0))
        _ => fail("missing statistics")
      }
    _ => fail("missing report")
  }
}
