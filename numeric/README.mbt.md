# Numeric tensor regression

Import `willzhang/json_regress/numeric` as `@numeric`. Shape and dtype are strict;
the flat row-major data uses symmetric absolute-OR-relative tolerance.

```mbt check
///|
test "numeric readme example" {
  let expected = @numeric.Tensor::from_json(
    {
      "prediction": { "shape": [1, 2], "dtype": "float32", "data": [0.5, 1.0] },
    },
    pointer="/prediction",
  )
  let actual = @numeric.Tensor::new([1, 2], "float32", [0.5001, 1.0])
  @numeric.assert_matches(expected, actual, absolute=0.001)
  let wrong_shape = @numeric.Tensor::new([2, 1], "float32", [0.5, 1.0])
  assert_eq(@numeric.compare(expected, wrong_shape).is_match(), false)
}
```

`Tensor::new` and its array accessors copy storage. Empty shape `[]` is a scalar;
any zero axis needs empty data. Dimensions are non-negative Int values, with
checked element-count multiplication. Dtype is source metadata, not a binary
storage conversion. Nonfinite values and magnitudes at least `2^53` are rejected.

`compare` returns a shape/dtype mismatch or a value summary. A value summary
counts every mismatch and the maximum absolute error over all elements. It
includes the first eight failing coordinates by default; `max_samples=0` still
fails and counts every error. `absolute` and `relative` both default to zero.

The tolerance is `abs(a-b) <= absolute` OR
`abs(a-b)/max(abs(a),abs(b)) <= relative`, with two zeros equal.
There is no broadcasting, reshape, transpose, or automatic dtype conversion.
The existing JSON parser precision and underflow limits still apply.
