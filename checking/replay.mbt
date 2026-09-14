///|
/// A portable comparison replay, preserving the exact original JSON texts.
/// This captures a comparison, not execution of a model or environment.
pub fn replay_document(
  expected : String,
  actual : String,
  rules : String,
  report : Report,
  source_manifest : Json,
) -> Json {
  {
    "schema_version": 1,
    "kind": "json-regress-comparison-replay",
    "tool_version": "0.1.0",
    "expected_text": expected,
    "actual_text": actual,
    "rules_text": rules,
    "recorded_report": report.to_json(),
    "source_manifest": source_manifest,
  }
}

///|
/// Recompute the comparison and check that its report agrees with the captured one.
pub fn replay_text(text : String) -> Report {
  try {
    let document = @json.parse(text)
    let f = object(document, "replay")
    exact_fields(f, [
      "schema_version", "kind", "tool_version", "expected_text", "actual_text", "rules_text",
      "recorded_report", "source_manifest",
    ])
    if integer(required(f, "schema_version"), "schema_version") != 1 ||
      string(required(f, "kind"), "kind") != "json-regress-comparison-replay" ||
      string(required(f, "tool_version"), "tool_version") != "0.1.0" {
      return error_report(
        "invalid_replay", "unsupported replay schema, kind, or tool version",
      )
    }
    let _ = object(required(f, "source_manifest"), "source_manifest")
    let result = compare_text(
      string(required(f, "expected_text"), "expected_text"),
      string(required(f, "actual_text"), "actual_text"),
      string(required(f, "rules_text"), "rules_text"),
    )
    if canonical_json(result.to_json()) !=
      canonical_json(required(f, "recorded_report")) {
      return error_report(
        "replay_drift", "recomputed report differs from recorded_report",
      )
    }
    result
  } catch {
    CheckError(_, message, _) => error_report("invalid_replay", message)
    _ => error_report("invalid_replay", "replay JSON could not be parsed")
  }
}
