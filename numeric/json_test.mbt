///|
fn rejects_json(value : Json, pointer? : String = "") -> Bool {
  try {
    let _ = @numeric.Tensor::from_json(value, pointer~)
    false
  } catch {
    @numeric.InvalidInput(_) => true
  }
}

///|
test "JSON adapter selects escaped keys and canonical array indexes" {
  let doc : Json = {
    "a/b": { "~1": [{ "": { "shape": [1], "dtype": "float32", "data": [2] } }] },
  }
  let tensor = @numeric.Tensor::from_json(doc, pointer="/a~1b/~01/0/")
  assert_eq(tensor.data(), [2.0])
  assert_eq(@numeric.Tensor::from_json(tensor.to_json()).data(), [2.0])
  for
    path in [
      "a/b", "/a~", "/a~2b", "/missing", "/a~1b/~01/00/", "/a~1b/~01/-/", "/a~1b/~01/2147483648/",
    ] {
    assert_eq(rejects_json(doc, pointer=path), true)
  }
}

///|
test "JSON adapter rejects malformed schema without silent coercion" {
  for
    value in [
      Json::null(),
      { "shape": [1], "dtype": "float32" },
      { "shape": [1], "dtype": "float32", "data": [null] },
      { "shape": [1], "dtype": "float32", "data": ["1"] },
      { "shape": [1], "dtype": "float32", "data": [[1]] },
      { "shape": [1.5], "dtype": "float32", "data": [1] },
      { "shape": [2147483648], "dtype": "float32", "data": [] },
      { "shape": [-1], "dtype": "float32", "data": [] },
      { "shape": [0], "dtype": null, "data": [] },
    ] {
    assert_eq(rejects_json(value), true)
  }
  assert_eq(
    @numeric.Tensor::from_json({
      "shape": [],
      "dtype": "float64",
      "data": [1],
      "schema": "v1",
    }).size(),
    1,
  )
}

///|
test "preserved underflow and nonfinite JSON numbers are rejected" {
  for
    value in [
      Json::number(0.0, repr="1e-999"),
      Json::number(0.0 / 0.0),
      Json::number(1.0 / 0.0),
    ] {
    assert_eq(
      rejects_json({ "shape": [1], "dtype": "float64", "data": [value] }),
      true,
    )
  }
}
