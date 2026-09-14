///|
fn trace_location(rows : Array[Json], i : Int, field : String) -> Json raise {
  let row = object(rows[i], "trajectory row")
  {
    "path": if field == "" {
      "/\{i}"
    } else {
      "/\{i}/\{field}"
    },
    "row": i,
    "episode_id": required(row, "episode_id"),
    "step": required(row, "step"),
    "field": field,
  }
}

///|
fn compare_trace(
  report : Report,
  expected : Json,
  actual : Json,
  options : Options,
) -> Unit raise {
  let result = @trajectory.compare(
    expected,
    actual,
    absolute=options.absolute,
    relative=options.relative,
    max_samples=options.max_samples,
  )
  let a = array(expected, "trajectory")
  let b = array(actual, "trajectory")
  let metadata : Map[String, @core.Difference] = Map([])
  let tensors : Map[String, Bool] = Map([])
  for diff in result.metadata {
    metadata[diff.path] = diff
  }
  for diff in result.tensors {
    tensors[diff.path] = true
  }
  let length = if a.length() > b.length() { a.length() } else { b.length() }
  for i in 0..<length {
    if i >= a.length() || i >= b.length() {
      if metadata.get("/\{i}") is Some(diff) {
        let rows = if i < a.length() { a } else { b }
        add_difference(report, diff, trace_location(rows, i, ""))
      }
      continue
    }
    for
      field in [
        "episode_id", "step", "observation", "action", "reward", "next_observation",
        "terminated", "truncated",
      ] {
      let location = trace_location(a, i, field)
      let path = "/\{i}/\{field}"
      if metadata.get(path) is Some(diff) {
        add_difference(report, diff, location)
      }
      if tensors.contains(path) {
        let left = @numeric.Tensor::from_json(a[i], pointer="/\{field}")
        let right = @numeric.Tensor::from_json(b[i], pointer="/\{field}")
        let _ = compare_tensor(report, left, right, options, location)
      }
    }
  }
  report.statistics = {
    "expected_steps": a.length(),
    "actual_steps": b.length(),
  }
}

///|
/// Compare validated JSON values using schema-1 rules; all expected errors become reports.
pub fn evaluate(expected : Json, actual : Json, rules : Json) -> Report {
  let options = try {
    validate_json(rules, 0, "")
    parse_options(rules)
  } catch {
    CheckError(_, message, _) => return error_report("invalid_rules", message)
    @core.InvalidRule(message) => return error_report("invalid_rules", message)
    @numeric.InvalidRule(message) =>
      return error_report("invalid_rules", message)
    _ =>
      return error_report("invalid_rules", "could not decode comparison rules")
  }
  let report = make_report(options.mode, options.document, options.max_findings)
  try {
    validate_json(expected, 0, "")
    validate_json(actual, 0, "")
    match options.mode {
      "json" => {
        let differences = @core.compare(
          expected,
          actual,
          rules=options.core_rules,
        )
        for diff in differences {
          add_difference(report, diff, { "path": diff.path })
        }
      }
      "tensor" => {
        let a = @numeric.Tensor::from_json(expected, pointer=options.pointer)
        let b = @numeric.Tensor::from_json(actual, pointer=options.pointer)
        report.statistics = compare_tensor(report, a, b, options, {
          "path": options.pointer,
        })
      }
      "trajectory" => compare_trace(report, expected, actual, options)
      "checkpoints" => compare_bundles(report, expected, actual, options)
      _ => () // parse_options rejects other modes.
    }
  } catch {
    CheckError(code, message, location) =>
      report.add(code, location, { "message": message }, error=true)
    @numeric.InvalidInput(message) =>
      report.add(
        "invalid_input",
        Json::null(),
        { "message": message },
        error=true,
      )
    @trajectory.InvalidTrajectory(message) =>
      report.add(
        "invalid_trajectory",
        Json::null(),
        { "message": message },
        error=true,
      )
    @numeric.InvalidRule(message) =>
      report.add(
        "invalid_rules",
        Json::null(),
        { "message": message },
        error=true,
      )
    @core.InvalidRule(message) =>
      report.add(
        "invalid_rules",
        Json::null(),
        { "message": message },
        error=true,
      )
    _ =>
      report.add(
        "comparison_error",
        Json::null(),
        { "message": "comparison could not complete" },
        error=true,
      )
  }
  report
}

///|
/// Parse original input text with the standard parser depth bound and reject number-token underflow before comparison.
pub fn compare_text(
  expected : String,
  actual : String,
  rules : String,
) -> Report {
  let r = parse_source(rules) catch {
    _ => return error_report("invalid_rules", "rules JSON could not be parsed")
  }
  let a = parse_source(expected) catch {
    CheckError(_, message, _) =>
      return error_report("invalid_input", "expected: " + message)
    _ =>
      return error_report("invalid_json", "expected JSON could not be parsed")
  }
  let b = parse_source(actual) catch {
    CheckError(_, message, _) =>
      return error_report("invalid_input", "actual: " + message)
    _ => return error_report("invalid_json", "actual JSON could not be parsed")
  }
  evaluate(a, b, r)
}
