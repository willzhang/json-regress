///|
/// A tolerance applies only to this exact RFC 6901 JSON Pointer.
pub(all) struct Tolerance {
  path : String
  absolute : Double
  relative : Double
} derive(Debug, Eq)

///|
pub(all) struct Rules {
  ignore_paths : Array[String]
  tolerances : Array[Tolerance]
} derive(Debug)

///|
pub fn Rules::new(
  ignore_paths? : Array[String] = [],
  tolerances? : Array[Tolerance] = [],
) -> Rules {
  { ignore_paths, tolerances, }
}

///|
pub(all) enum Reason {
  ValueMismatch
  TypeMismatch
  Missing
  Unexpected
  OutsideTolerance
  UnsupportedNumber
  DepthLimit
} derive(Debug, Eq)

///|
/// None represents an absent node; Some(Null) represents JSON null.
pub(all) struct Difference {
  path : String
  reason : Reason
  expected : Json?
  actual : Json?
} derive(Debug, Eq)

///|
pub suberror InvalidRule {
  InvalidRule(String)
} derive(Debug)

///|
pub suberror Mismatch {
  Mismatch(String)
} derive(Debug)

///|
fn valid_pointer(path : String) -> Bool {
  if path == "" {
    return true
  }
  let chars = path.iter().to_array()
  if chars[0] != '/' {
    return false
  }
  let mut i = 1
  while i < chars.length() {
    if chars[i] == '~' {
      if i + 1 >= chars.length() || (chars[i + 1] != '0' && chars[i + 1] != '1') {
        return false
      }
      i = i + 2
    } else {
      i = i + 1
    }
  }
  true
}

///|
fn validate(rules : Rules) -> Unit raise InvalidRule {
  for path in rules.ignore_paths {
    if !valid_pointer(path) {
      raise InvalidRule("Invalid JSON Pointer: \{path}")
    }
  }
  let seen : Map[String, Bool] = Map([])
  for rule in rules.tolerances {
    if !valid_pointer(rule.path) {
      raise InvalidRule("Invalid JSON Pointer: \{rule.path}")
    }
    for value in [rule.absolute, rule.relative] {
      if value < 0.0 || value.is_nan() || value.is_inf() {
        raise InvalidRule(
          "Tolerance must be finite and non-negative: \{rule.path}",
        )
      }
    }
    if seen.contains(rule.path) {
      raise InvalidRule("Duplicate tolerance path: \{rule.path}")
    }
    seen[rule.path] = true
  }
}

///|
fn child_path(path : String, key : String) -> String {
  let escaped = key
    .replace_all(old="~", new="~0")
    .replace_all(old="/", new="~1")
  "\{path}/\{escaped}"
}

///|
fn kind(value : Json) -> String {
  match value {
    Null => "null"
    True | False => "boolean"
    Number(_, ..) => "number"
    String(_) => "string"
    Array(_) => "array"
    Object(_) => "object"
  }
}

///|
// Conservatively fail closed for unsafe magnitudes and parser underflow.
// Ordinary finite decimals still use Double semantics, not exact decimal math.
fn supported_number(value : Double, repr : String?) -> Bool {
  if value.is_nan() || value.is_inf() || value.abs() >= 9007199254740992.0 {
    return false
  }
  if value == 0.0 {
    if repr is Some(text) {
      for char in text {
        if char == 'e' || char == 'E' {
          break
        }
        if char >= '1' && char <= '9' {
          return false
        }
      }
    }
  }
  true
}

///|
fn walk(
  expected : Json?,
  actual : Json?,
  path : String,
  depth : Int,
  rules : Rules,
  output : Array[Difference],
) -> Unit {
  if rules.ignore_paths.contains(path) {
    return
  }
  let reason : Reason = match (expected, actual) {
    (None, None) => return
    (Some(_), None) => Missing
    (None, Some(_)) => Unexpected
    (Some(left), Some(right)) =>
      if depth > 128 {
        DepthLimit
      } else {
        match (left, right) {
          (Object(a), Object(b)) => {
            let keys = a.keys().to_array()
            for key in b.keys() {
              if !a.contains(key) {
                keys.push(key)
              }
            }
            keys.sort_by(fn(a, b) { a.lexical_compare(b) })
            for key in keys {
              walk(
                a.get(key),
                b.get(key),
                child_path(path, key),
                depth + 1,
                rules,
                output,
              )
            }
            return
          }
          (Array(a), Array(b)) => {
            let length = if a.length() > b.length() {
              a.length()
            } else {
              b.length()
            }
            for i = 0; i < length; i = i + 1 {
              walk(a.get(i), b.get(i), "\{path}/\{i}", depth + 1, rules, output)
            }
            return
          }
          (Number(a, repr=ar), Number(b, repr=br)) =>
            if !supported_number(a, ar) || !supported_number(b, br) {
              UnsupportedNumber
            } else {
              let mut tolerance : Tolerance? = None
              for rule in rules.tolerances {
                if rule.path == path {
                  tolerance = Some(rule)
                }
              }
              match tolerance {
                None => if a == b { return } else { ValueMismatch }
                Some(rule) => {
                  // Divide by scale to avoid overflow in relative * scale.
                  let delta = (a - b).abs()
                  let scale = if a.abs() > b.abs() { a.abs() } else { b.abs() }
                  if delta <= rule.absolute ||
                    (scale > 0.0 && delta / scale <= rule.relative) {
                    return
                  }
                  OutsideTolerance
                }
              }
            }
          _ =>
            if kind(left) != kind(right) {
              TypeMismatch
            } else if left == right {
              return
            } else {
              ValueMismatch
            }
        }
      }
  }
  output.push({ path, reason, expected, actual, })
}

///|
/// Compare JSON with exact path rules. Empty output means a match.
/// Invalid rules raise an error even when the inputs are equal or ignored.
/// Results are sorted lexicographically by encoded JSON Pointer.
pub fn compare(
  expected : Json,
  actual : Json,
  rules? : Rules = Rules::new(),
) -> Array[Difference] raise InvalidRule {
  validate(rules)
  let output = []
  walk(Some(expected), Some(actual), "", 0, rules, output)
  output.sort_by(fn(a, b) { a.path.lexical_compare(b.path) })
  output
}

///|
fn render_value(value : Json, depth : Int) -> String {
  if depth > 128 {
    return "<depth-limit>"
  }
  match value {
    Object(fields) => {
      let keys = fields.keys().to_array()
      keys.sort_by(fn(a, b) { a.lexical_compare(b) })
      let pairs = keys.map(fn(key) {
        let field = match fields.get(key) {
          Some(v) => v
          None => Json::null()
        }
        "\{Json::string(key).stringify()}:\{render_value(field, depth + 1)}"
      })
      "{" + pairs.join(",") + "}"
    }
    Array(values) =>
      "[" + values.map(fn(v) { render_value(v, depth + 1) }).join(",") + "]"
    Number(n, ..) if n.is_nan() => "<NaN>"
    Number(n, ..) if n.is_inf() => "<infinite>"
    _ => value.stringify()
  }
}

///|
fn render_optional(value : Json?) -> String {
  match value {
    None => "<missing>"
    Some(v) => render_value(v, 0)
  }
}

///|
/// Render paths as quoted pointers so root, empty keys and newlines are clear.
pub fn format_differences(items : Array[Difference]) -> String {
  if items.is_empty() {
    return "JSON matched"
  }
  items
  .map(fn(item) {
    let path = Json::string(item.path).stringify()
    "\{path}: \{item.reason.label()}; expected=\{render_optional(item.expected)}; actual=\{render_optional(item.actual)}"
  })
  .join("\n")
}

///|
fn Reason::label(self : Reason) -> String {
  match self {
    ValueMismatch => "ValueMismatch"
    TypeMismatch => "TypeMismatch"
    Missing => "Missing"
    Unexpected => "Unexpected"
    OutsideTolerance => "OutsideTolerance"
    UnsupportedNumber => "UnsupportedNumber"
    DepthLimit => "DepthLimit"
  }
}

///|
/// Raise Mismatch with a readable report; configuration errors remain distinct.
pub fn assert_matches(
  expected : Json,
  actual : Json,
  rules? : Rules = Rules::new(),
) -> Unit raise {
  let differences = compare(expected, actual, rules~)
  if !differences.is_empty() {
    raise Mismatch(format_differences(differences))
  }
}
