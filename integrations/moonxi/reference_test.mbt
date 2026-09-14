///|
test "real CPU layer matches independent Python reference values" {
  let expected = @numeric.Tensor::from_json(
    @fixtures.linear(),
    pointer="/expected",
  )
  let actual = @json_regress_moonxi.linear_output()
  @numeric.assert_matches(expected, actual)
  let perturbed = actual.data()
  perturbed[1] = perturbed[1] + 0.000001
  let close = @numeric.Tensor::new(actual.shape(), actual.dtype(), perturbed)
  @numeric.assert_matches(expected, close, absolute=0.000002)
  perturbed[1] = perturbed[1] + 0.1
  let bad = @numeric.Tensor::new(actual.shape(), actual.dtype(), perturbed)
  match @numeric.compare(expected, bad, absolute=0.000002) {
    Values(summary) => {
      assert_eq(summary.mismatched, 1)
      assert_eq(summary.samples[0].coordinate, [0, 1])
    }
    _ => fail("expected element difference")
  }
}

///|
test "framework shape and dtype drift cannot pass using the expected layout" {
  let expected = @numeric.Tensor::from_json(
    @fixtures.linear(),
    pointer="/expected",
  )
  let actual = @json_regress_moonxi.linear_output()
  let reshaped = @numeric.Tensor::new([4], actual.dtype(), actual.data())
  assert_eq(@numeric.compare(expected, reshaped).is_match(), false)
  let retyped = @numeric.Tensor::new(actual.shape(), "float64", actual.data())
  assert_eq(@numeric.compare(expected, retyped).is_match(), false)
}
