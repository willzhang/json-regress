///|
suberror CheckError {
  CheckError(String, String, Json)
} derive(Debug)

///|
fn object(value : Json, label : String) -> Map[String, Json] raise CheckError {
  match value {
    Object(fields) => fields
    _ =>
      raise CheckError(
        "invalid_input",
        "\{label} must be an object",
        Json::null(),
      )
  }
}

///|
fn required(fields : Map[String, Json], key : String) -> Json raise CheckError {
  match fields.get(key) {
    Some(value) => value
    None =>
      raise CheckError(
        "invalid_input",
        "missing required field: \{key}",
        Json::null(),
      )
  }
}

///|
fn exact_fields(
  fields : Map[String, Json],
  allowed : Array[String],
) -> Unit raise CheckError {
  let keys = fields.keys().to_array()
  keys.sort_by(fn(a, b) { a.lexical_compare(b) })
  for key in keys {
    if !allowed.contains(key) {
      raise CheckError("invalid_input", "unknown field: \{key}", Json::null())
    }
  }
}

///|
fn string(value : Json, label : String) -> String raise CheckError {
  match value {
    String(text) => text
    _ =>
      raise CheckError(
        "invalid_input",
        "\{label} must be a string",
        Json::null(),
      )
  }
}

///|
fn nonempty(value : Json, label : String) -> String raise CheckError {
  let text = string(value, label)
  if text == "" {
    raise CheckError(
      "invalid_input",
      "\{label} must not be empty",
      Json::null(),
    )
  }
  text
}

///|
fn array(value : Json, label : String) -> Array[Json] raise CheckError {
  match value {
    Array(items) => items
    _ =>
      raise CheckError(
        "invalid_input",
        "\{label} must be an array",
        Json::null(),
      )
  }
}

///|
fn number(value : Json) -> Double raise CheckError {
  match value {
    Number(n, repr~) if !n.is_inf() && !n.is_nan() => {
      if n == 0.0 {
        if repr is Some(text) {
          for char in text {
            if char == 'e' || char == 'E' {
              break
            }
            if char >= '1' && char <= '9' {
              raise CheckError(
                "invalid_input",
                "preserved number underflow",
                Json::null(),
              )
            }
          }
        }
      }
      n
    }
    _ =>
      raise CheckError(
        "invalid_input",
        "expected a finite number",
        Json::null(),
      )
  }
}

///|
fn integer(value : Json, label : String) -> Int raise CheckError {
  let n = number(value)
  if n < 0.0 || n > 2147483647.0 || n.floor() != n {
    raise CheckError(
      "invalid_input",
      "\{label} must be a non-negative Int",
      Json::null(),
    )
  }
  n.to_int()
}

///|
fn escape_pointer(key : String) -> String {
  key.replace_all(old="~", new="~0").replace_all(old="/", new="~1")
}

///|
// The file boundary rejects non-JSON numbers even inside ignored subtrees.
fn validate_json(
  value : Json,
  depth : Int,
  path : String,
) -> Unit raise CheckError {
  if depth > 128 {
    raise CheckError("invalid_input", "document exceeds depth 128", {
      "path": path,
    })
  }
  match value {
    Number(n, ..) if n.is_nan() || n.is_inf() =>
      raise CheckError("invalid_input", "non-finite JSON number", {
        "path": path,
      })
    Object(fields) => {
      let keys = fields.keys().to_array()
      keys.sort_by(fn(a, b) { a.lexical_compare(b) })
      for key in keys {
        validate_json(fields[key], depth + 1, "\{path}/\{escape_pointer(key)}")
      }
    }
    Array(items) =>
      for i, item in items {
        validate_json(item, depth + 1, "\{path}/\{i}")
      }
    _ => ()
  }
}

///|
/// Stable JSON encoding with lexicographically sorted object keys.
/// Intended for validated reports and inputs, not non-finite programmatic Json.
pub fn canonical_json(value : Json) -> String {
  match value {
    Object(fields) => {
      let keys = fields.keys().to_array()
      keys.sort_by(fn(a, b) { a.lexical_compare(b) })
      "{" +
      keys
      .map(fn(key) {
        Json::string(key).stringify() + ":" + canonical_json(fields[key])
      })
      .join(",") +
      "}"
    }
    Array(items) => "[" + items.map(canonical_json).join(",") + "]"
    _ => value.stringify()
  }
}

///|
priv struct Options {
  mode : String
  absolute : Double
  relative : Double
  max_samples : Int
  max_findings : Int
  pointer : String
  core_rules : @core.Rules
  variable_metadata : Array[String]
  document : Json
}

///|
fn parse_options(document : Json) -> Options raise {
  let f = object(document, "rules")
  let version = integer(required(f, "schema_version"), "schema_version")
  if version != 1 {
    raise CheckError(
      "invalid_rules",
      "unsupported rules schema_version",
      Json::null(),
    )
  }
  let mode = string(required(f, "mode"), "mode")
  let common = ["schema_version", "mode", "max_findings"]
  let specific = match mode {
    "json" => ["ignore_paths", "tolerances"]
    "tensor" => ["absolute", "relative", "max_samples", "pointer"]
    "trajectory" => ["absolute", "relative", "max_samples"]
    "checkpoints" =>
      ["absolute", "relative", "max_samples", "variable_metadata"]
    _ =>
      raise CheckError(
        "invalid_rules",
        "unknown comparison mode: \{mode}",
        Json::null(),
      )
  }
  exact_fields(f, common + specific)
  let absolute = number(f.get("absolute").unwrap_or(Json::number(0.0)))
  let relative = number(f.get("relative").unwrap_or(Json::number(0.0)))
  let max_samples = integer(
    f.get("max_samples").unwrap_or(Json::number(8.0)),
    "max_samples",
  )
  let max_findings = integer(
    f.get("max_findings").unwrap_or(Json::number(100.0)),
    "max_findings",
  )
  if max_samples > 1000 || max_findings > 1000 {
    raise CheckError(
      "invalid_rules",
      "sample/finding limits must be at most 1000",
      Json::null(),
    )
  }
  let empty = @numeric.Tensor::new([0], "float64", [])
  let _ = @numeric.compare(empty, empty, absolute~, relative~, max_samples~)
  let pointer = string(f.get("pointer").unwrap_or(Json::string("")), "pointer")
  let ignore_paths = array(
    f.get("ignore_paths").unwrap_or(Json::array([])),
    "ignore_paths",
  ).map(value => string(value, "ignore path"))
  let tolerances : Array[@core.Tolerance] = array(
    f.get("tolerances").unwrap_or(Json::array([])),
    "tolerances",
  ).map(value => {
    let rule = object(value, "tolerance")
    exact_fields(rule, ["path", "absolute", "relative"])
    {
      path: string(required(rule, "path"), "path"),
      absolute: number(rule.get("absolute").unwrap_or(Json::number(0.0))),
      relative: number(rule.get("relative").unwrap_or(Json::number(0.0))),
    }
  })
  let core_rules = @core.Rules::new(ignore_paths~, tolerances~)
  let _ = @core.compare(Json::null(), Json::null(), rules=core_rules)
  // Validate tensor pointer syntax even when the selected data are absent.
  let _ = @core.compare(
    Json::null(),
    Json::null(),
    rules=@core.Rules::new(ignore_paths=[pointer]),
  )
  let variable_metadata = array(
    f.get("variable_metadata").unwrap_or(Json::array([])),
    "variable_metadata",
  ).map(value => nonempty(value, "variable metadata key"))
  let seen : Map[String, Bool] = Map([])
  for key in variable_metadata {
    if seen.contains(key) {
      raise CheckError(
        "invalid_rules",
        "duplicate variable metadata key: \{key}",
        Json::null(),
      )
    }
    seen[key] = true
  }
  {
    mode,
    absolute,
    relative,
    max_samples,
    max_findings,
    pointer,
    core_rules,
    variable_metadata,
    document,
  }
}

///|
// The parser can discard an underflowed literal's repr. Scan number tokens in
// already-valid JSON text (outside strings) before exposing that lossy result.
fn parse_source(text : String) -> Json raise {
  let document = @json.parse(text)
  let chars = text.iter().to_array()
  let mut i = 0
  let mut quoted = false
  while i < chars.length() {
    let char = chars[i]
    if quoted {
      if char == '\\' {
        i = i + 2
        continue
      }
      if char == '"' {
        quoted = false
      }
      i = i + 1
    } else if char == '"' {
      quoted = true
      i = i + 1
    } else if char == '-' || (char >= '0' && char <= '9') {
      let token = StringBuilder()
      while i < chars.length() {
        let c = chars[i]
        if (c >= '0' && c <= '9') ||
          c == '-' ||
          c == '+' ||
          c == '.' ||
          c == 'e' ||
          c == 'E' {
          token.write_char(c)
          i = i + 1
        } else {
          break
        }
      }
      let literal = token.to_string()
      if @json.parse(literal) is Number(n, ..) {
        let _ = number(Json::number(n, repr=literal))
      }
    } else {
      i = i + 1
    }
  }
  document
}
