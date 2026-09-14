///|
test "numeric scalar rules preserve the established JSON tolerance contract" {
  let values = [-8.0, -7.0, -0.125, 0.0, 0.125, 7.0, 8.0]
  for
    (absolute, relative) in [
      (0.0, 0.0),
      (0.125, 0.0),
      (0.0, 0.125),
      (0.125, 0.125),
    ] {
    let rules = @json_regress.Rules::new(tolerances=[
      { path: "", absolute, relative, },
    ])
    for a in values {
      for b in values {
        let expected = @numeric.Tensor::new([], "float64", [a])
        let actual = @numeric.Tensor::new([], "float64", [b])
        assert_eq(
          @numeric.compare(expected, actual, absolute~, relative~).is_match(),
          @json_regress.compare(Json::number(a), Json::number(b), rules~).is_empty(),
        )
      }
    }
  }
}

///|
test "default sample limit does not hide a larger late error" {
  let expected = @numeric.Tensor::new([12], "float64", Array::make(12, 0.0))
  let actual = @numeric.Tensor::new(
    [12],
    "float64",
    Array::makei(12, fn(i) { i.to_double() + 1.0 }),
  )
  match @numeric.compare(expected, actual) {
    Values(summary) => {
      assert_eq(summary.samples.length(), 8)
      assert_eq(summary.mismatched, 12)
      assert_eq(summary.max_absolute_error, 12.0)
      assert_eq(summary.samples[7].index, 7)
    }
    _ => fail("expected value summary")
  }
}

///|
test "JSON export cannot mutate validated storage" {
  let tensor = @numeric.Tensor::new([1], "float64", [3.0])
  match tensor.to_json() {
    Object(fields) => {
      match fields.get("data") {
        Some(Array(data)) => data[0] = Json::number(99.0)
        _ => fail("expected exported data")
      }
      match fields.get("shape") {
        Some(Array(shape)) => shape[0] = Json::number(2.0)
        _ => fail("expected exported shape")
      }
    }
    _ => fail("expected exported object")
  }
  assert_eq(tensor.data(), [3.0])
  assert_eq(tensor.shape(), [1])
}
