///|
/// Deterministic, untrained dynamics demo: [state, observation, action] -> state'.
/// Actual Linear/ReLU operations are provided by the pinned MoonXi-net library.
pub fn world_model_output() -> @numeric.Tensor raise {
  let fixture = @fixtures.world_model()
  let inputs = []
  for path in ["/state", "/observation", "/action"] {
    for value in @numeric.Tensor::from_json(fixture, pointer=path).data() {
      inputs.push(Float::from_double(value))
    }
  }
  let x : @nparray.NpArray = @tensor.Tensor::from_host(
    FixedArray::from_iter(inputs.iter()),
    [1, 4],
  )
  let first : @model.Linear[@nparray.NpArray] = {
    w: from_fixture(fixture, "/w1"),
    b: from_fixture(fixture, "/b1"),
  }
  let second : @model.Linear[@nparray.NpArray] = {
    w: from_fixture(fixture, "/w2"),
    b: from_fixture(fixture, "/b2"),
  }
  let hidden = @tensor.ImageTensor::relu(first.forward(x))
  adapt(second.forward(hidden))
}
