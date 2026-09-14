///|
test "real CPU linear layer executes and adapter preserves shape and dtype" {
  let output = @json_regress_moonxi.linear_output()
  assert_eq(output.shape(), [2, 2])
  assert_eq(output.dtype(), "float32")
  assert_eq(output.size(), 4)
}
