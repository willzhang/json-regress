///|
fn tensor(data : Array[Double]) -> @numeric.Tensor raise {
  @numeric.Tensor::new([data.length()], "float64", data)
}

///|
test "absolute boundary and symmetric relative boundary match core rules" {
  for (a, b) in [(0.0, 0.125), (-1.0, -1.125)] {
    assert_eq(
      @numeric.compare(tensor([a]), tensor([b]), absolute=0.125).is_match(),
      true,
    )
  }
  assert_eq(
    @numeric.compare(tensor([0.0]), tensor([0.126]), absolute=0.125).is_match(),
    false,
  )
  for (a, b) in [(7.0, 8.0), (8.0, 7.0), (-7.0, -8.0)] {
    assert_eq(
      @numeric.compare(tensor([a]), tensor([b]), relative=0.125).is_match(),
      true,
    )
  }
  // Both thresholds individually fail: they must not be added together.
  assert_eq(
    @numeric.compare(tensor([8.0]), tensor([10.0]), absolute=1.0, relative=0.1).is_match(),
    false,
  )
  assert_eq(
    @numeric.compare(tensor([0.0, -0.0]), tensor([-0.0, 0.0])).is_match(),
    true,
  )
}

///|
test "shape and dtype are strict even with same flattened values" {
  let a = @numeric.Tensor::new([1, 2], "float32", [1.0, 2.0])
  let b = @numeric.Tensor::new([2, 1], "float32", [1.0, 2.0])
  assert_eq(@numeric.compare(a, b), @numeric.ShapeMismatch([1, 2], [2, 1]))
  let c = @numeric.Tensor::new([1, 2], "float64", [1.0, 2.0])
  assert_eq(
    @numeric.compare(a, c),
    @numeric.DtypeMismatch("float32", "float64"),
  )
  assert_eq(@numeric.compare(a, tensor([1.0])).is_match(), false)
}

///|
test "summary counts all failures while samples preserve row-major coordinates" {
  let a = @numeric.Tensor::new([2, 2, 2], "float64", [
    0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0,
  ])
  let b = @numeric.Tensor::new([2, 2, 2], "float64", [
    0.0, 1.0, 2.0, 3.5, 4.0, 7.0, 9.0, 11.0,
  ])
  match @numeric.compare(a, b, max_samples=2) {
    Values(s) => {
      assert_eq(s.total, 8)
      assert_eq(s.mismatched, 4)
      assert_eq(s.max_absolute_error, 4.0)
      assert_eq(s.samples.length(), 2)
      assert_eq(s.samples[0].coordinate, [0, 1, 1])
      assert_eq(s.samples[1].coordinate, [1, 0, 1])
      assert_eq(s.samples[1].expected, 5.0)
      assert_eq(s.samples[1].actual, 7.0)
    }
    _ => fail("expected numeric report")
  }
  assert_eq(@numeric.compare(a, b, max_samples=0).is_match(), false)
  assert_eq(
    @numeric.compare(a, b, max_samples=0).format(),
    "values: total=8; mismatched=4; max_absolute_error=4\n... 4 additional mismatches omitted",
  )
}

///|
test "empty tensors and scalars retain valid summary and coordinates" {
  let empty = @numeric.Tensor::new([2, 0], "float32", [])
  assert_eq(
    @numeric.compare(empty, empty),
    @numeric.Values({
      total: 0,
      mismatched: 0,
      max_absolute_error: 0.0,
      samples: [],
    }),
  )
  let a = @numeric.Tensor::new([], "float32", [1.0])
  let b = @numeric.Tensor::new([], "float32", [2.0])
  match @numeric.compare(a, b) {
    Values(s) => assert_eq(s.samples[0].coordinate, [])
    _ => fail("expected numeric report")
  }
}

///|
test "invalid rules fail before a structural mismatch or empty comparison" {
  let a = tensor([])
  for tolerance in [-1.0, 0.0 / 0.0, 1.0 / 0.0] {
    let rejected = try {
      let _ = @numeric.compare(a, tensor([1.0]), absolute=tolerance)
      false
    } catch {
      @numeric.InvalidRule(_) => true
      e => raise e
    }
    assert_eq(rejected, true)
  }
  let rejected = try {
    let _ = @numeric.compare(a, a, max_samples=-1)
    false
  } catch {
    @numeric.InvalidRule(_) => true
  }
  assert_eq(rejected, true)
}

///|
test "assertion fails even if no samples are requested" {
  @numeric.assert_matches(tensor([1.0]), tensor([1.001]), absolute=0.01)
  let rejected = try {
    @numeric.assert_matches(tensor([1.0]), tensor([2.0]), max_samples=0)
    false
  } catch {
    @numeric.Mismatch(_) => true
    e => raise e
  }
  assert_eq(rejected, true)
}
