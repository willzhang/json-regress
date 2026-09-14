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
  let layer : @model.Linear[@nparray.NpArray] = {
    w: @nparray.NpArray::from2d([[0.5, -1.0], [2.0, 0.25], [-0.5, 1.5]]),
    b: @nparray.NpArray::from2d([[0.125, -0.25]]),
  }
  let input = @nparray.NpArray::from2d([[1.0, -2.0, 0.5], [0.0, 1.0, -1.0]])
  adapt(layer.forward(input))
}
