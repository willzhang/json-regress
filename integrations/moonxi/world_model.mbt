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

///|
fn checkpoint(
  step : Int,
  layer : String,
  output : @nparray.NpArray,
) -> Json raise {
  {
    "id": "\{step}/\{layer}",
    "episode_id": "fixed-rollout",
    "step": step,
    "layer": layer,
    "tensor": adapt(output).to_json(),
  }
}

///|
/// Execute three recurrent steps in the real CPU library and capture all layers.
/// Provenance digests describe the shared fixed specification, not a signature.
pub fn world_model_checkpoints(backend : String) -> Json raise {
  let spec = @fixtures.rollout_spec()
  let fields = match spec {
    Object(f) => f
    _ => abort("invalid embedded spec")
  }
  let state = match fields["state"] {
    Array(values) =>
      values.map(fn(value) {
        match value {
          Number(n, ..) => Float::from_double(n)
          _ => abort("invalid spec state")
        }
      })
    _ => abort("invalid state")
  }
  let actions = match fields["actions"] {
    Array(values) => values
    _ => abort("invalid actions")
  }
  let observations = match fields["observations"] {
    Array(values) => values
    _ => abort("invalid observations")
  }
  let base = @fixtures.world_model()
  let first : @model.Linear[@nparray.NpArray] = {
    w: from_fixture(base, "/w1"),
    b: from_fixture(base, "/b1"),
  }
  let second : @model.Linear[@nparray.NpArray] = {
    w: from_fixture(base, "/w2"),
    b: from_fixture(base, "/b2"),
  }
  let points = []
  for step in 0..<actions.length() {
    let input = state.copy()
    for values in [observations[step], actions[step]] {
      match values {
        Array(items) =>
          for item in items {
            match item {
              Number(n, ..) => input.push(Float::from_double(n))
              _ => abort("invalid input")
            }
          }
        _ => abort("invalid input array")
      }
    }
    let x : @nparray.NpArray = @tensor.Tensor::from_host(
      FixedArray::from_iter(input.iter()),
      [1, 4],
    )
    let preactivation = first.forward(x)
    points.push(checkpoint(step, "linear1", preactivation))
    let hidden = @tensor.ImageTensor::relu(preactivation)
    points.push(checkpoint(step, "relu", hidden))
    let output = second.forward(hidden)
    points.push(checkpoint(step, "latent", output))
    // Feedback comes from the actual Float output, never from reference values.
    state[0] = output.data[0]
    state[1] = output.data[1]
  }
  let reference = @fixtures.world_model_checkpoints()
  let metadata : Map[String, Json] = Map([])
  match reference {
    Object(f) =>
      match f["metadata"] {
        Object(source) =>
          for key, value in source {
            metadata[key] = value
          }
        _ => abort("invalid reference metadata")
      }
    _ => abort("invalid reference")
  }
  metadata["backend"] = backend.to_json()
  metadata["generator"] = Json::string(
    "moonxi-b485c25faaefa768e035a534fb1e64fdbfac68a6/rollout-v1",
  )
  {
    "schema_version": 1,
    "metadata": Json::object(metadata),
    "checkpoints": points,
  }
}
