///|
priv struct Checkpoint {
  id : String
  episode : String
  step : Int
  layer : String
  tensor : @numeric.Tensor
}

///|
priv struct Bundle {
  metadata : Map[String, Json]
  points : Array[Checkpoint]
}

///|
fn parse_bundle(document : Json) -> Bundle raise {
  let f = object(document, "checkpoint bundle")
  exact_fields(f, ["schema_version", "metadata", "checkpoints"])
  if integer(required(f, "schema_version"), "schema_version") != 1 {
    raise CheckError(
      "invalid_input",
      "unsupported checkpoint schema_version",
      Json::null(),
    )
  }
  let metadata = object(required(f, "metadata"), "metadata")
  for
    key in [
      "model_id", "input_sha256", "weights_sha256", "generator", "backend", "dtype",
      "randomness",
    ] {
    let text = nonempty(required(metadata, key), key)
    if key == "input_sha256" || key == "weights_sha256" {
      if text.length() != 64 ||
        !text
        .iter()
        .all(fn(c) { (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') }) {
        raise CheckError(
          "invalid_input",
          "\{key} must be a lowercase SHA-256 hex digest",
          Json::null(),
        )
      }
    }
  }
  let points = []
  let ids : Map[String, Bool] = Map([])
  let positions : Map[String, Bool] = Map([])
  let episodes : Map[String, Bool] = Map([])
  for value in array(required(f, "checkpoints"), "checkpoints") {
    let row = object(value, "checkpoint")
    exact_fields(row, ["id", "episode_id", "step", "layer", "tensor"])
    let point : Checkpoint = {
      id: nonempty(required(row, "id"), "id"),
      episode: nonempty(required(row, "episode_id"), "episode_id"),
      step: integer(required(row, "step"), "step"),
      layer: nonempty(required(row, "layer"), "layer"),
      tensor: @numeric.Tensor::from_json(required(row, "tensor")),
    }
    let position = canonical_json({
      "episode": point.episode,
      "step": point.step,
      "layer": point.layer,
    })
    if ids.contains(point.id) || positions.contains(position) {
      raise CheckError(
        "invalid_input",
        "duplicate checkpoint id or episode/step/layer",
        { "checkpoint_id": point.id },
      )
    }
    if points.length() > 0 {
      let previous : Checkpoint = points[points.length() - 1]
      if point.episode == previous.episode {
        if point.step < previous.step {
          raise CheckError(
            "invalid_input",
            "checkpoint steps must not decrease",
            { "checkpoint_id": point.id },
          )
        }
      } else if episodes.contains(point.episode) {
        raise CheckError(
          "invalid_input",
          "checkpoint episodes must be contiguous",
          { "checkpoint_id": point.id },
        )
      }
    }
    ids[point.id] = true
    positions[position] = true
    episodes[point.episode] = true
    points.push(point)
  }
  { metadata, points, }
}

///|
fn point_location(point : Checkpoint, index : Int) -> Json {
  {
    "path": "/checkpoints/\{index}/tensor",
    "checkpoint_index": index,
    "checkpoint_id": point.id,
    "episode_id": point.episode,
    "step": point.step,
    "layer": point.layer,
  }
}

///|
fn compare_bundles(
  report : Report,
  expected : Json,
  actual : Json,
  options : Options,
) -> Unit raise {
  let a = parse_bundle(expected)
  let b = parse_bundle(actual)
  report.statistics = {
    "expected_checkpoints": a.points.length(),
    "actual_checkpoints": b.points.length(),
  }
  let keys = a.metadata.keys().to_array()
  for key in b.metadata.keys() {
    if !a.metadata.contains(key) {
      keys.push(key)
    }
  }
  keys.sort_by(fn(a, b) { a.lexical_compare(b) })
  for key in options.variable_metadata {
    if !a.metadata.contains(key) || !b.metadata.contains(key) {
      raise CheckError(
        "invalid_rules",
        "variable metadata must exist on both sides: \{key}",
        Json::null(),
      )
    }
  }
  for key in keys {
    if options.variable_metadata.contains(key) {
      continue
    }
    let left = a.metadata.get(key)
    let right = b.metadata.get(key)
    if left != right {
      report.add(
        "source_mismatch",
        { "path": "/metadata/\{escape_pointer(key)}" },
        { "expected": optional(left), "actual": optional(right) },
        error=true,
      )
    }
  }
  // Incomparable sources must not yield misleading numeric regressions.
  if report.exit_code() != 0 {
    return
  }
  let actual_indices : Map[String, Int] = Map([])
  let expected_ids : Map[String, Bool] = Map([])
  for i, point in b.points {
    actual_indices[point.id] = i
  }
  for i, point in a.points {
    expected_ids[point.id] = true
    let location = point_location(point, i)
    match actual_indices.get(point.id) {
      None => report.add("missing_checkpoint", location, { "id": point.id })
      Some(j) => {
        let other = b.points[j]
        if i != j {
          report.add("checkpoint_order_mismatch", location, {
            "expected_index": i,
            "actual_index": j,
          })
        }
        if point.episode != other.episode ||
          point.step != other.step ||
          point.layer != other.layer {
          report.add("checkpoint_location_mismatch", location, {
            "actual_location": point_location(other, j),
          })
        }
      }
    }
  }
  for j, point in b.points {
    if !expected_ids.contains(point.id) {
      report.add("unexpected_checkpoint", point_location(point, j), {
        "id": point.id,
      })
    }
  }
  // Structural diagnostics precede numerical comparison; no silent realignment.
  if report.exit_code() != 0 {
    return
  }
  let mut max_error = 0.0
  for i, point in a.points {
    let details = compare_tensor(
      report,
      point.tensor,
      b.points[i].tensor,
      options,
      point_location(point, i),
    )
    if details is Object(fields) {
      if fields.get("max_absolute_error") is Some(Number(n, ..)) {
        if n > max_error {
          max_error = n
        }
      }
    }
  }
  report.statistics = {
    "expected_checkpoints": a.points.length(),
    "actual_checkpoints": b.points.length(),
    "compared_checkpoints": a.points.length(),
    "max_absolute_error": max_error,
  }
}
