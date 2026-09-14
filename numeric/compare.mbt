///|
pub(all) struct ElementDifference {
  index : Int
  coordinate : Array[Int]
  expected : Double
  actual : Double
  absolute_error : Double
} derive(Debug, Eq)

///|
pub(all) struct Summary {
  total : Int
  mismatched : Int
  max_absolute_error : Double
  samples : Array[ElementDifference]
} derive(Debug, Eq)

///|
pub(all) enum Outcome {
  ShapeMismatch(Array[Int], Array[Int])
  DtypeMismatch(String, String)
  Values(Summary)
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
fn coordinates(index : Int, shape : Array[Int]) -> Array[Int] {
  let result = Array::make(shape.length(), 0)
  let mut rest = index
  for i = shape.length() - 1; i >= 0; i = i - 1 {
    result[i] = rest % shape[i]
    rest = rest / shape[i]
  }
  result
}

///|
/// Symmetric absolute-OR-relative tolerance; at most eight samples by default.
/// Shape and dtype must match before any values are compared.
pub fn compare(
  expected : Tensor,
  actual : Tensor,
  absolute? : Double = 0.0,
  relative? : Double = 0.0,
  max_samples? : Int = 8,
) -> Outcome raise InvalidRule {
  for tolerance in [absolute, relative] {
    if tolerance < 0.0 || tolerance.is_nan() || tolerance.is_inf() {
      raise InvalidRule("tolerances must be finite and non-negative")
    }
  }
  if max_samples < 0 {
    raise InvalidRule("max_samples must be non-negative")
  }
  if expected.shape != actual.shape {
    return ShapeMismatch(expected.shape.copy(), actual.shape.copy())
  }
  if expected.dtype != actual.dtype {
    return DtypeMismatch(expected.dtype, actual.dtype)
  }
  let samples = []
  let mut mismatched = 0
  let mut max_absolute_error = 0.0
  for index, a in expected.data {
    let b = actual.data[index]
    let delta = (a - b).abs()
    let scale = if a.abs() > b.abs() { a.abs() } else { b.abs() }
    if delta > max_absolute_error {
      max_absolute_error = delta
    }
    if !(delta <= absolute || (scale > 0.0 && delta / scale <= relative)) {
      mismatched = mismatched + 1
      if samples.length() < max_samples {
        samples.push({
          index,
          coordinate: coordinates(index, expected.shape),
          expected: a,
          actual: b,
          absolute_error: delta,
        })
      }
    }
  }
  Values({
    total: expected.data.length(),
    mismatched,
    max_absolute_error,
    samples,
  })
}

///|
pub fn Outcome::is_match(self : Outcome) -> Bool {
  match self {
    Values(summary) => summary.mismatched == 0
    _ => false
  }
}

///|
fn format_axes(shape : Array[Int]) -> String {
  "[" + shape.map(fn(n) { n.to_string() }).join(", ") + "]"
}

///|
pub fn Outcome::format(self : Outcome) -> String {
  match self {
    ShapeMismatch(a, b) =>
      "shape mismatch: expected=\{format_axes(a)}; actual=\{format_axes(b)}"
    DtypeMismatch(a, b) => "dtype mismatch: expected=\{a}; actual=\{b}"
    Values(summary) => {
      let lines = [
        "values: total=\{summary.total}; mismatched=\{summary.mismatched}; max_absolute_error=\{summary.max_absolute_error}",
      ]
      for sample in summary.samples {
        lines.push(
          "index=\{sample.index}; coordinate=\{format_axes(sample.coordinate)}; expected=\{sample.expected}; actual=\{sample.actual}; absolute_error=\{sample.absolute_error}",
        )
      }
      if summary.mismatched > summary.samples.length() {
        lines.push(
          "... \{summary.mismatched - summary.samples.length()} additional mismatches omitted",
        )
      }
      lines.join("\n")
    }
  }
}

///|
pub fn assert_matches(
  expected : Tensor,
  actual : Tensor,
  absolute? : Double = 0.0,
  relative? : Double = 0.0,
  max_samples? : Int = 8,
) -> Unit raise {
  let outcome = compare(expected, actual, absolute~, relative~, max_samples~)
  if !outcome.is_match() {
    raise Mismatch(outcome.format())
  }
}
