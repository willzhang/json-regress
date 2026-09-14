///|
fn api_response() -> Unit raise {
  let expected : Json = {
    "request_id": "old",
    "generated_at": "2026-09-13",
    "price": 49.5,
    "status": "ok",
  }
  let good : Json = {
    "request_id": "new",
    "generated_at": "2026-09-14",
    "price": 49.5,
    "status": "ok",
  }
  let bad : Json = {
    "request_id": "new",
    "generated_at": "2026-09-14",
    "price": 59.5,
    "status": "ok",
  }
  let rules = @regress.Rules::new(ignore_paths=["/request_id", "/generated_at"])
  @regress.assert_matches(expected, good, rules~)
  let differences = @regress.compare(expected, bad, rules~)
  assert_eq(differences.map(fn(d) { d.path }), ["/price"])
  println("[API response] changing metadata: PASS; incorrect price: caught")
  println(@regress.format_differences(differences))
}

///|
fn experiment_metrics() -> Unit raise {
  let expected : Json = { "loss": 0.25, "score": 0.8, "sample_count": 100 }
  let good : Json = { "loss": 0.251, "score": 0.804, "sample_count": 100 }
  let bad : Json = { "loss": 0.28, "score": 0.804, "sample_count": 99 }
  let rules = @regress.Rules::new(tolerances=[
    { path: "/loss", absolute: 0.002, relative: 0.0, },
    { path: "/score", absolute: 0.0, relative: 0.01, },
  ])
  @regress.assert_matches(expected, good, rules~)
  let differences = @regress.compare(expected, bad, rules~)
  assert_eq(differences.map(fn(d) { d.path }), ["/loss", "/sample_count"])
  println(
    "[Experiment metrics] small numeric drift: PASS; loss/count regression: caught",
  )
  println(@regress.format_differences(differences))
}

///|
fn generated_config() -> Unit raise {
  let expected : Json = {
    "meta": { "host": "dev" },
    "retry": null,
    "enabled": true,
    "targets": ["cpu", "gpu"],
  }
  let good : Json = {
    "meta": { "host": "ci" },
    "retry": null,
    "enabled": true,
    "targets": ["cpu", "gpu"],
  }
  let bad : Json = {
    "meta": { "host": "ci" },
    "enabled": false,
    "targets": ["gpu", "cpu"],
  }
  let rules = @regress.Rules::new(ignore_paths=["/meta"])
  @regress.assert_matches(expected, good, rules~)
  let differences = @regress.compare(expected, bad, rules~)
  assert_eq(differences.map(fn(d) { d.path }), [
    "/enabled", "/retry", "/targets/0", "/targets/1",
  ])
  assert_eq(differences[1].reason, @regress.Missing)
  println(
    "[Generated config] environment metadata: PASS; missing/null, switch and order regressions: caught",
  )
  println(@regress.format_differences(differences))
}

///|
fn main {
  try! api_response()
  try! experiment_metrics()
  try! generated_config()
}
