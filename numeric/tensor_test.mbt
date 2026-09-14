///|
fn invalid(
  shape : Array[Int],
  data : Array[Double],
  dtype? : String = "float32",
) -> Bool {
  try {
    let _ = @numeric.Tensor::new(shape, dtype, data)
    false
  } catch {
    @numeric.InvalidInput(_) => true
  }
}

///|
test "scalar and row-major shape have exact element counts" {
  assert_eq(@numeric.Tensor::new([], "float64", [2.0]).size(), 1)
  let tensor = @numeric.Tensor::new([2, 2], "float32", [1.0, 2.0, 3.0, 4.0])
  assert_eq(tensor.shape(), [2, 2])
  assert_eq(tensor.dtype(), "float32")
  assert_eq(tensor.data(), [1.0, 2.0, 3.0, 4.0])
  assert_eq(invalid([], []), true)
  assert_eq(invalid([2, 2], [1.0, 2.0]), true)
}

///|
test "zero axes are empty even if other dimensions would overflow" {
  assert_eq(@numeric.Tensor::new([2147483647, 2, 0], "float32", []).size(), 0)
  assert_eq(invalid([0], [1.0]), true)
  assert_eq(invalid([-1, 0], []), true)
  assert_eq(invalid([2147483647, 2], []), true)
}

///|
test "nonfinite and unsafe magnitude values are invalid even on both sides" {
  for
    value in [
      0.0 / 0.0,
      1.0 / 0.0,
      -1.0 / 0.0,
      9007199254740992.0,
      -9007199254740992.0,
    ] {
    assert_eq(invalid([1], [value]), true)
  }
  assert_eq(invalid([1], [0.0], dtype=""), true)
}

///|
test "callers cannot mutate validated tensor arrays" {
  let shape = [1]
  let data = [3.0]
  let tensor = @numeric.Tensor::new(shape, "float32", data)
  shape[0] = 2
  data[0] = 0.0 / 0.0
  let exposed = tensor.data()
  exposed[0] = 99.0
  let exposed_shape = tensor.shape()
  exposed_shape[0] = 9
  assert_eq(tensor.shape(), [1])
  assert_eq(tensor.data(), [3.0])
}
