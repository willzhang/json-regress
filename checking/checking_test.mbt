///|
fn at(value : Json, key : String) -> Json {
  match value {
    Object(f) => f[key]
    _ => abort("expected object")
  }
}

///|
fn first(report : @checking.Report) -> Json {
  at(report.to_json(), "first_difference")
}

///|
fn code(report : @checking.Report) -> Json {
  at(first(report), "code")
}

///|
fn tensor(values : Array[Double]) -> Json {
  { "shape": [1, 2], "dtype": "float32", "data": values }
}

///|
fn point(
  id : String,
  step : Int,
  layer : String,
  values : Array[Double],
) -> Json {
  {
    "id": id,
    "episode_id": "demo",
    "step": step,
    "layer": layer,
    "tensor": tensor(values),
  }
}

///|
fn bundle(
  points : Array[Json],
  backend? : String = "native",
  model? : String = "demo/v1",
) -> Json {
  {
    "schema_version": 1,
    "metadata": {
      "model_id": model,
      "input_sha256": "0000000000000000000000000000000000000000000000000000000000000000",
      "weights_sha256": "1111111111111111111111111111111111111111111111111111111111111111",
      "generator": "test/v1",
      "backend": backend,
      "dtype": "float32",
      "randomness": "none",
    },
    "checkpoints": points,
  }
}

///|
test "JSON reports retain missing versus null and bounded findings" {
  let rules : Json = { "schema_version": 1, "mode": "json", "max_findings": 0 }
  let result = @checking.evaluate({ "a": null, "b": 1 }, {}, rules)
  assert_eq(result.exit_code(), 1)
  assert_eq(at(result.to_json(), "findings_total"), Json::number(2.0))
  assert_eq(at(result.to_json(), "findings_truncated"), Json::boolean(true))
  assert_eq(code(result), Json::string("missing"))
  assert_eq(at(at(first(result), "details"), "expected"), {
    "present": true,
    "value": null,
  })
  assert_eq(at(at(first(result), "details"), "actual"), { "present": false })
}

///|
test "file numeric rules preserve symmetric OR and count errors with zero samples" {
  let rules : Json = {
    "schema_version": 1,
    "mode": "tensor",
    "absolute": 0.5,
    "relative": 0.005,
    "max_samples": 0,
  }
  let a = tensor([100.0, 0.0])
  let result = @checking.evaluate(a, tensor([100.75, 0.0]), rules)
  assert_eq(result.exit_code(), 1) // additive allclose would accept 0.75: OR must reject.
  assert_eq(at(at(first(result), "details"), "samples"), Json::array([]))
  assert_eq(at(at(first(result), "details"), "mismatched"), Json::number(1.0))
  assert_eq(@checking.evaluate(a, tensor([100.25, 0.0]), rules).exit_code(), 0)
}

///|
test "shape mismatch is a regression while malformed tensor is an input error" {
  let rules : Json = { "schema_version": 1, "mode": "tensor" }
  assert_eq(
    code(
      @checking.evaluate(
        tensor([1.0, 2.0]),
        { "shape": [2, 1], "dtype": "float32", "data": [1, 2] },
        rules,
      ),
    ),
    Json::string("shape_mismatch"),
  )
  assert_eq(
    @checking.evaluate(
      tensor([1.0, 2.0]),
      { "shape": [2, 2], "dtype": "float32", "data": [1, 2] },
      rules,
    ).exit_code(),
    2,
  )
}

///|
test "invalid rules cannot silently disable checking" {
  let invalid : Array[Json] = [
    { "schema_version": 2, "mode": "tensor" },
    { "schema_version": 1, "mode": "tensor", "absolut": 1.0 },
    { "schema_version": 1, "mode": "tensor", "absolute": -1.0 },
    { "schema_version": 1, "mode": "json", "absolute": 1.0 },
    { "schema_version": 1, "mode": "json", "ignore_paths": ["bad"] },
    { "schema_version": 1, "mode": "tensor", "max_samples": 1001 },
    {
      "schema_version": 1,
      "mode": "checkpoints",
      "variable_metadata": ["backend", "backend"],
    },
  ]
  for rules in invalid {
    assert_eq(
      code(@checking.evaluate({}, {}, rules)),
      Json::string("invalid_rules"),
    )
  }
}

///|
test "parse failures and unsupported numbers fail closed with valid JSON reports" {
  let rules = "{\"schema_version\":1,\"mode\":\"tensor\"}"
  assert_eq(
    code(@checking.compare_text("{", "{}", rules)),
    Json::string("invalid_json"),
  )
  assert_eq(
    code(@checking.compare_text("{}", "{}", "{")),
    Json::string("invalid_rules"),
  )
  let result = @checking.compare_text(
    "1e999", "1e999", "{\"schema_version\":1,\"mode\":\"json\"}",
  )
  assert_eq(result.exit_code(), 2)
  let _ = @json.parse(@checking.canonical_json(result.to_json()))
  let underflow = "{\"shape\":[],\"dtype\":\"float32\",\"data\":[1e-400]}"
  assert_eq(@checking.compare_text(underflow, underflow, rules).exit_code(), 2)
}

///|
test "canonical reports are invariant to object insertion order" {
  assert_eq(@checking.canonical_json({ "z": 1, "aa": 2 }), "{\"aa\":2,\"z\":1}")
  let a : Json = { "z": 1, "a": 2 }
  let b : Json = { "a": 2, "z": 1 }
  let rules : Json = { "schema_version": 1, "mode": "json" }
  assert_eq(
    @checking.canonical_json(@checking.evaluate(a, {}, rules).to_json()),
    @checking.canonical_json(@checking.evaluate(b, {}, rules).to_json()),
  )
}

///|
test "model sources must match unless the exact metadata key is declared variable" {
  let points = [point("h", 0, "hidden", [1.0, 2.0])]
  let a = bundle(points)
  let b = bundle(points, backend="wasm")
  let strict : Json = { "schema_version": 1, "mode": "checkpoints" }
  let relaxed : Json = {
    "schema_version": 1,
    "mode": "checkpoints",
    "variable_metadata": ["backend"],
  }
  assert_eq(
    code(@checking.evaluate(a, b, strict)),
    Json::string("source_mismatch"),
  )
  assert_eq(@checking.evaluate(a, b, strict).exit_code(), 2)
  assert_eq(@checking.evaluate(a, b, relaxed).exit_code(), 0)
  assert_eq(
    code(@checking.evaluate(a, bundle(points, model="other/v1"), relaxed)),
    Json::string("source_mismatch"),
  )
  assert_eq(
    code(
      @checking.evaluate(a, b, {
        "schema_version": 1,
        "mode": "checkpoints",
        "variable_metadata": ["typo"],
      }),
    ),
    Json::string("invalid_rules"),
  )
}

///|
test "first checkpoint divergence identifies layer time and tensor coordinate" {
  let a = bundle([
    point("a", 0, "hidden", [1.0, 2.0]),
    point("b", 1, "latent", [3.0, 4.0]),
  ])
  let b = bundle([
    point("a", 0, "hidden", [1.0, 2.1]),
    point("b", 1, "latent", [4.0, 3.0]),
  ])
  let result = @checking.evaluate(a, b, {
    "schema_version": 1,
    "mode": "checkpoints",
    "absolute": 0.001,
  })
  assert_eq(at(result.to_json(), "findings_total"), Json::number(2.0))
  assert_eq(
    at(at(first(result), "location"), "checkpoint_id"),
    Json::string("a"),
  )
  assert_eq(at(at(first(result), "location"), "layer"), Json::string("hidden"))
  let samples = at(at(first(result), "details"), "samples")
  match samples {
    Array(items) => assert_eq(at(items[0], "coordinate"), [0, 1])
    _ => fail("missing samples")
  }
}

///|
test "missing reordered and retimed checkpoints cannot align into a pass" {
  let p = point("a", 0, "hidden", [1.0, 2.0])
  let q = point("b", 0, "latent", [3.0, 4.0])
  let a = bundle([p, q])
  let rules : Json = { "schema_version": 1, "mode": "checkpoints" }
  assert_eq(
    code(@checking.evaluate(a, bundle([q]), rules)),
    Json::string("missing_checkpoint"),
  )
  assert_eq(
    code(@checking.evaluate(a, bundle([q, p]), rules)),
    Json::string("checkpoint_order_mismatch"),
  )
  assert_eq(
    code(
      @checking.evaluate(
        a,
        bundle([p, point("b", 1, "latent", [3.0, 4.0])]),
        rules,
      ),
    ),
    Json::string("checkpoint_location_mismatch"),
  )
  assert_eq(@checking.evaluate(a, bundle([p, p]), rules).exit_code(), 2)
}

///|
test "trajectory reports follow numeric row order and preserve timing validation" {
  let a = @fixtures.rl()
  let rows = match a {
    Array(rows) => rows.copy()
    _ => abort("fixture")
  }
  let original = match rows[1] {
    Object(f) => f
    _ => abort("row")
  }
  let changed = Map([])
  for key, value in original {
    changed[key] = value
  }
  changed["reward"] = Json::number(-99.0)
  rows[1] = Json::object(changed)
  let rules : Json = { "schema_version": 1, "mode": "trajectory" }
  let result = @checking.evaluate(a, Json::array(rows), rules)
  assert_eq(
    at(at(first(result), "location"), "episode_id"),
    Json::string("goal"),
  )
  assert_eq(at(at(first(result), "location"), "step"), Json::number(1.0))
  assert_eq(at(at(first(result), "location"), "field"), Json::string("reward"))
  changed["step"] = Json::number(2.0)
  assert_eq(
    code(@checking.evaluate(a, Json::array(rows), rules)),
    Json::string("invalid_trajectory"),
  )
}

///|
test "portable replay recomputes mismatch and detects recorded-result drift" {
  let a = "{\"n\":1}"
  let b = "{\"n\":2}"
  let rules = "{\"schema_version\":1,\"mode\":\"json\"}"
  let result = @checking.compare_text(a, b, rules)
  let replay = @checking.replay_document(a, b, rules, result, {})
  assert_eq(
    @checking.canonical_json(
      @checking.replay_text(@checking.canonical_json(replay)).to_json(),
    ),
    @checking.canonical_json(result.to_json()),
  )
  let wrong = @checking.replay_document(
    a,
    b,
    rules,
    @checking.compare_text(a, a, rules),
    {},
  )
  assert_eq(
    code(@checking.replay_text(@checking.canonical_json(wrong))),
    Json::string("replay_drift"),
  )
}

///|
test "trajectory earliest finding uses step 2 before step 10" {
  let expected : Array[Json] = []
  let actual : Array[Json] = []
  for i in 0..<12 {
    let observation : Json = { "shape": [], "dtype": "float32", "data": [0] }
    let row : Json = {
      "episode_id": "long",
      "step": i,
      "observation": observation,
      "action": observation,
      "reward": 0,
      "next_observation": observation,
      "terminated": i == 11,
      "truncated": false,
    }
    expected.push(row)
    let changed : Map[String, Json] = Map([])
    match row {
      Object(f) =>
        for key, value in f {
          changed[key] = value
        }
      _ => abort("row")
    }
    if i == 2 || i == 10 {
      changed["reward"] = Json::number(1.0)
    }
    actual.push(Json::object(changed))
  }
  let result = @checking.evaluate(Json::array(expected), Json::array(actual), {
    "schema_version": 1,
    "mode": "trajectory",
  })
  assert_eq(at(at(first(result), "location"), "step"), Json::number(2.0))
  assert_eq(at(result.to_json(), "findings_total"), Json::number(2.0))
}

///|
test "missing trajectory row reports the row pointer without an empty-key suffix" {
  let expected = @fixtures.rl()
  let rows = match expected {
    Array(items) => items
    _ => abort("fixture")
  }
  let result = @checking.evaluate(
    expected,
    Json::array(rows.iter().take(3).to_array()),
    { "schema_version": 1, "mode": "trajectory" },
  )
  assert_eq(code(result), Json::string("missing"))
  assert_eq(at(at(first(result), "location"), "path"), Json::string("/3"))
}
