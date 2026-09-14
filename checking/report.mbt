///|
/// Versioned comparison report. Findings are bounded, totals are not truncated.
pub struct Report {
  mut code : Int
  mode : String
  rules : Json
  limit : Int
  findings : Array[Json]
  mut total : Int
  mut first : Json
  mut statistics : Json
}

///|
fn make_report(mode : String, rules : Json, limit : Int) -> Report {
  {
    code: 0,
    mode,
    rules,
    limit,
    findings: [],
    total: 0,
    first: Json::null(),
    statistics: {},
  }
}

///|
fn Report::add(
  self : Report,
  code : String,
  location : Json,
  details : Json,
  error? : Bool = false,
) -> Unit {
  let finding : Json = {
    "code": code,
    "location": location,
    "details": details,
  }
  if self.total == 0 {
    self.first = finding
  }
  self.total = self.total + 1
  if self.findings.length() < self.limit {
    self.findings.push(finding)
  }
  if error {
    self.code = 2
  } else if self.code == 0 {
    self.code = 1
  }
}

///|
/// Construct an operational error using the same report envelope as comparisons.
pub fn error_report(code : String, message : String) -> Report {
  let report = make_report("unknown", Json::null(), 100)
  report.add(code, Json::null(), { "message": message }, error=true)
  report
}

///|
/// 0: match; 1: regression; 2: invalid input/rules, incomparable source, or I/O.
pub fn Report::exit_code(self : Report) -> Int {
  self.code
}

///|
/// Schema 1: null first_difference on success, otherwise the first ordered finding.
pub fn Report::to_json(self : Report) -> Json {
  {
    "schema_version": 1,
    "tool_version": "0.1.0",
    "mode": self.mode,
    "status": if self.code == 0 {
      "match"
    } else if self.code == 1 {
      "mismatch"
    } else {
      "error"
    },
    "exit_code": self.code,
    "rules": self.rules,
    "findings_total": self.total,
    "findings": self.findings,
    "findings_truncated": self.total > self.findings.length(),
    "first_difference": self.first,
    "statistics": self.statistics,
  }
}

///|
pub fn Report::format(self : Report) -> String {
  let status = if self.code == 0 {
    "MATCH"
  } else if self.code == 1 {
    "MISMATCH"
  } else {
    "ERROR"
  }
  let lines = [
    "\{status} mode=\{self.mode} findings=\{self.total} exit=\{self.code}",
  ]
  if self.total > 0 {
    lines.push("first: " + canonical_json(self.first))
  }
  if self.total > self.findings.length() {
    lines.push("findings truncated; full count retained")
  }
  lines.join("\n")
}

///|
fn optional(value : Json?) -> Json {
  match value {
    None => { "present": false }
    Some(value) => { "present": true, "value": value }
  }
}

///|
fn reason(reason : @core.Reason) -> String {
  match reason {
    ValueMismatch => "value_mismatch"
    TypeMismatch => "type_mismatch"
    Missing => "missing"
    Unexpected => "unexpected"
    OutsideTolerance => "outside_tolerance"
    UnsupportedNumber => "unsupported_number"
    DepthLimit => "depth_limit"
  }
}

///|
fn add_difference(
  report : Report,
  diff : @core.Difference,
  location : Json,
) -> Unit {
  report.add(
    reason(diff.reason),
    location,
    { "expected": optional(diff.expected), "actual": optional(diff.actual) },
    error=diff.reason == @core.UnsupportedNumber ||
      diff.reason == @core.DepthLimit,
  )
}

///|
fn numeric_details(
  outcome : @numeric.Outcome,
  a : @numeric.Tensor,
  b : @numeric.Tensor,
) -> Json {
  let result : Map[String, Json] = Map([
    ("expected_shape", a.shape().to_json()),
    ("actual_shape", b.shape().to_json()),
    ("expected_dtype", a.dtype().to_json()),
    ("actual_dtype", b.dtype().to_json()),
  ])
  if outcome is Values(summary) {
    result["total"] = summary.total.to_json()
    result["mismatched"] = summary.mismatched.to_json()
    result["max_absolute_error"] = summary.max_absolute_error.to_json()
    result["samples"] = Json::array(
      summary.samples.map(fn(sample) {
        {
          "index": sample.index,
          "coordinate": sample.coordinate,
          "expected": sample.expected,
          "actual": sample.actual,
          "absolute_error": sample.absolute_error,
        }
      }),
    )
    result["samples_truncated"] = (summary.mismatched > summary.samples.length()).to_json()
  }
  Json::object(result)
}

///|
fn compare_tensor(
  report : Report,
  a : @numeric.Tensor,
  b : @numeric.Tensor,
  options : Options,
  location : Json,
) -> Json raise {
  let outcome = @numeric.compare(
    a,
    b,
    absolute=options.absolute,
    relative=options.relative,
    max_samples=options.max_samples,
  )
  let details = numeric_details(outcome, a, b)
  if !outcome.is_match() {
    let code = match outcome {
      ShapeMismatch(_, _) => "shape_mismatch"
      DtypeMismatch(_, _) => "dtype_mismatch"
      Values(_) => "numeric_mismatch"
    }
    report.add(code, location, details)
  }
  details
}
