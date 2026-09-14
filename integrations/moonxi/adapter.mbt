///|
/// Copies the actual framework shape and Float storage into validated data.
pub fn adapt(array : @nparray.NpArray) -> @numeric.Tensor raise {
  @numeric.Tensor::new(
    @tensor.Tensor::dims(array).iter().to_array(),
    "float32",
    array.data.iter().map(fn(v) { v.to_double() }).to_array(),
  )
}

///|
/// A fixed CPU Linear layer from the real MoonXi-net model package.
pub fn linear_output() -> @numeric.Tensor raise {
  let reference = @fixtures.linear()
  let layer : @model.Linear[@nparray.NpArray] = {
    w: from_fixture(reference, "/weight"),
    b: from_fixture(reference, "/bias"),
  }
  let input = from_fixture(reference, "/input")
  adapt(layer.forward(input))
}

///|
fn from_fixture(document : Json, pointer : String) -> @nparray.NpArray raise {
  let tensor = @numeric.Tensor::from_json(document, pointer~)
  @tensor.Tensor::from_host(
    FixedArray::from_iter(
      tensor.data().iter().map(fn(v) { Float::from_double(v) }),
    ),
    tensor.shape(),
  )
}
