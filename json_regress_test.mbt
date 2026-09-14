///|
test "equal trees ignore object insertion order" {
  let left = @json.parse("{\"z\":[1,true,null],\"a\":{\"x\":\"你好\"}}")
  let right = @json.parse("{\"a\":{\"x\":\"你好\"},\"z\":[1,true,null]}")
  assert_eq(@json_regress.compare(left, right).length(), 0)
}

///|
test "strict defaults preserve business value differences" {
  let diffs = @json_regress.compare({ "price": 10, "status": "ok" }, {
    "price": 10.01,
    "status": "error",
  })
  assert_eq(diffs.map(fn(d) { d.path }), ["/price", "/status"])
  assert_eq(diffs[0].reason, @json_regress.ValueMismatch)
}

///|
test "missing is different from explicit null in both directions" {
  let diffs = @json_regress.compare({ "a": null }, { "b": null })
  assert_eq(diffs[0].path, "/a")
  assert_eq(diffs[0].reason, @json_regress.Missing)
  assert_eq(diffs[0].expected, Some(Json::null()))
  assert_eq(diffs[0].actual, None)
  assert_eq(diffs[1].reason, @json_regress.Unexpected)
}

///|
test "type mismatches are distinct from scalar value changes" {
  let diffs = @json_regress.compare([1, true, null, "x"], [
    "1", false, false, "y",
  ])
  assert_eq(diffs.map(fn(d) { d.reason }), [
    @json_regress.TypeMismatch,
    @json_regress.ValueMismatch,
    @json_regress.TypeMismatch,
    @json_regress.ValueMismatch,
  ])
}

///|
test "arrays retain position and detect extra and missing elements" {
  let diffs = @json_regress.compare([1, 2], [2, 1, 3])
  assert_eq(diffs.map(fn(d) { d.path }), ["/0", "/1", "/2"])
  assert_eq(diffs[2].reason, @json_regress.Unexpected)
  assert_eq(@json_regress.compare([1, 2], [1])[0].reason, @json_regress.Missing)
}

///|
test "ignore exact field and subtree without hiding siblings" {
  let rules = @json_regress.Rules::new(ignore_paths=["/meta", "/request_id"])
  let diffs = @json_regress.compare(
    { "meta": { "time": 1 }, "request_id": "old", "status": 1 },
    { "meta": [2], "status": 2 },
    rules~,
  )
  assert_eq(diffs.map(fn(d) { d.path }), ["/status"])
}

///|
test "ignore is exact rather than prefix or wildcard" {
  let diffs = @json_regress.compare(
    { "a": 1, "ab": 1, "*": 1 },
    { "a": 2, "ab": 2, "*": 2 },
    rules=@json_regress.Rules::new(ignore_paths=["/a"]),
  )
  assert_eq(diffs.map(fn(d) { d.path }), ["/*", "/ab"])
}

///|
test "JSON Pointer escaping includes literal tilde slash empty and unicode keys" {
  let rules = @json_regress.Rules::new(ignore_paths=[
    "/a~1b/~0x", "/", "/中文",
  ])
  let a : Json = { "a/b": { "~x": 1, "~1": 1 }, "": 1, "中文": 1 }
  let b : Json = { "a/b": { "~x": 2, "~1": 2 }, "": 2, "中文": 2 }
  let diffs = @json_regress.compare(a, b, rules~)
  assert_eq(diffs.map(fn(d) { d.path }), ["/a~1b/~01"])
}

///|
test "empty pointer ignores the root" {
  assert_eq(
    @json_regress.compare(
      { "a": 1 },
      null,
      rules=@json_regress.Rules::new(ignore_paths=[""]),
    ).length(),
    0,
  )
}

///|
test "array rule targets canonical index and may ignore absent node" {
  let rules = @json_regress.Rules::new(ignore_paths=["/1"])
  assert_eq(@json_regress.compare([1, 2], [1], rules~).length(), 0)
  assert_eq(
    @json_regress.compare(
      [1],
      [2],
      rules=@json_regress.Rules::new(ignore_paths=["/00"]),
    ).length(),
    1,
  )
}

///|
test "absolute tolerance includes boundary and handles zero and negatives" {
  let rules = @json_regress.Rules::new(tolerances=[
    { path: "", absolute: 0.125, relative: 0.0, },
  ])
  for (a, b) in [(0.0, 0.125), (-1.0, -1.125)] {
    assert_eq(
      @json_regress.compare(Json::number(a), Json::number(b), rules~).length(),
      0,
    )
  }
  assert_eq(
    @json_regress.compare(0, 0.126, rules~)[0].reason,
    @json_regress.OutsideTolerance,
  )
}

///|
test "relative tolerance is symmetric and based on maximum magnitude" {
  let rules = @json_regress.Rules::new(tolerances=[
    { path: "", absolute: 0.0, relative: 0.125, },
  ])
  assert_eq(@json_regress.compare(7, 8, rules~).length(), 0)
  assert_eq(@json_regress.compare(8, 7, rules~).length(), 0)
  assert_eq(@json_regress.compare(-7, -8, rules~).length(), 0)
  assert_eq(@json_regress.compare(6.99, 8, rules~).length(), 1)
  assert_eq(@json_regress.compare(0, 0, rules~).length(), 0)
  assert_eq(@json_regress.compare(0, 0.0001, rules~).length(), 1)
}

///|
test "absolute or relative tolerance can independently allow a match" {
  let rules = @json_regress.Rules::new(tolerances=[
    { path: "", absolute: 0.25, relative: 0.1, },
  ])
  assert_eq(@json_regress.compare(0, 0.25, rules~).length(), 0)
  assert_eq(@json_regress.compare(90, 100, rules~).length(), 0)
}

///|
test "per-path tolerance does not relax other fields or types" {
  let rules = @json_regress.Rules::new(tolerances=[
    { path: "/score", absolute: 0.02, relative: 0.0, },
  ])
  let diffs = @json_regress.compare(
    { "score": 0.8, "count": 100 },
    { "score": 0.81, "count": 101 },
    rules~,
  )
  assert_eq(diffs.map(fn(d) { d.path }), ["/count"])
  assert_eq(
    @json_regress.compare({ "score": 0.8 }, { "score": "0.8" }, rules~)[0].reason,
    @json_regress.TypeMismatch,
  )
}

///|
test "ignore takes precedence over a valid tolerance" {
  let rules = @json_regress.Rules::new(ignore_paths=["/x"], tolerances=[
    { path: "/x", absolute: 0.0, relative: 0.0, },
  ])
  assert_eq(
    @json_regress.compare({ "x": 1 }, { "x": "new" }, rules~).length(),
    0,
  )
}

///|
fn rejects(rules : @json_regress.Rules) -> Unit raise {
  let rejected = try {
    ignore(@json_regress.compare(null, null, rules~))
    false
  } catch {
    @json_regress.InvalidRule(_) => true
  }
  assert_true(rejected)
}

///|
test "malformed pointers are rejected before comparing equal input" {
  for path in ["a", "#/a", "/~", "/~2", "/a~x"] {
    rejects(@json_regress.Rules::new(ignore_paths=[path]))
    rejects(
      @json_regress.Rules::new(tolerances=[
        { path, absolute: 0.0, relative: 0.0, },
      ]),
    )
  }
}

///|
test "negative and nonfinite tolerance parameters are rejected" {
  for value in [-0.1, 0.0 / 0.0, 1.0 / 0.0] {
    rejects(
      @json_regress.Rules::new(tolerances=[
        { path: "", absolute: value, relative: 0.0, },
      ]),
    )
    rejects(
      @json_regress.Rules::new(tolerances=[
        { path: "", absolute: 0.0, relative: value, },
      ]),
    )
  }
}

///|
test "duplicate tolerances are rejected even under ignored root" {
  rejects(
    @json_regress.Rules::new(ignore_paths=[""], tolerances=[
      { path: "/x", absolute: 1.0, relative: 0.0, },
      { path: "/x", absolute: 2.0, relative: 0.0, },
    ]),
  )
}

///|
test "large integers that round to the same Double never pass" {
  let a = @json.parse("{\"n\":9007199254740992}")
  let b = @json.parse("{\"n\":9007199254740993}")
  assert_eq(
    @json_regress.compare(a, b)[0].reason,
    @json_regress.UnsupportedNumber,
  )
  assert_eq(
    @json_regress.compare(a, a)[0].reason,
    @json_regress.UnsupportedNumber,
  )
  assert_eq(
    @json_regress.compare(9007199254740991, 9007199254740990).length(),
    1,
  )
}

///|
test "nonfinite and preserved underflow representations fail closed" {
  for
    value in [
      Json::number(0.0 / 0.0),
      Json::number(1.0 / 0.0),
      Json::number(0.0, repr="1e-999"),
    ] {
    assert_eq(
      @json_regress.compare(value, value)[0].reason,
      @json_regress.UnsupportedNumber,
    )
  }
  assert_eq(@json_regress.compare(@json.parse("-0e-999"), 0).length(), 0)
}

///|
test "upstream Double precision loss cannot be reconstructed without repr" {
  // This documents a boundary of compare(Json, Json), not decimal equivalence.
  // The current core parser discards this number's original representation.
  let parsed = @json.parse("1e-999")
  assert_eq(parsed, Json::number(0.0))
  assert_eq(@json_regress.compare(parsed, 0).length(), 0)
}

///|
test "zero tolerance uses Double equality including signed zero" {
  let rules = @json_regress.Rules::new(tolerances=[
    { path: "", absolute: 0.0, relative: 0.0, },
  ])
  assert_eq(@json_regress.compare(-0.0, 0.0, rules~).length(), 0)
  assert_eq(@json_regress.compare(1, 1.000001, rules~).length(), 1)
}

///|
test "reports are stable with missing markers and canonical object rendering" {
  let a = @json.parse("{\"z\":null,\"a\":{\"z\":2,\"a\":1}}")
  let b = @json.parse("{\"a\":false}")
  assert_eq(
    @json_regress.format_differences(@json_regress.compare(a, b)),
    "\"/a\": TypeMismatch; expected={\"a\":1,\"z\":2}; actual=false\n\"/z\": Missing; expected=null; actual=<missing>",
  )
  assert_eq(@json_regress.format_differences([]), "JSON matched")
}

///|
test "root and newline paths render unambiguously" {
  assert_eq(
    @json_regress.format_differences(@json_regress.compare(1, 2)),
    "\"\": ValueMismatch; expected=1; actual=2",
  )
  assert_eq(
    @json_regress.format_differences(
      @json_regress.compare({ "\n": 1 }, { "\n": 2 }),
    ),
    "\"/\\n\": ValueMismatch; expected=1; actual=2",
  )
}

///|
test "reports use lexical order rather than MoonBit length-first comparison" {
  let diffs = @json_regress.compare({ "z": 1, "alphabet": 1, "ab": 1 }, {
    "z": 2,
    "alphabet": 2,
    "ab": 2,
  })
  assert_eq(diffs.map(fn(d) { d.path }), ["/ab", "/alphabet", "/z"])
  let rendered = @json_regress.format_differences(
    @json_regress.compare({ "z": 1, "alphabet": 2 }, false),
  )
  assert_eq(
    rendered, "\"\": TypeMismatch; expected={\"alphabet\":2,\"z\":1}; actual=false",
  )
}

///|
test "assertion raises a useful mismatch report and passes matching input" {
  @json_regress.assert_matches({ "a": 1 }, { "a": 1 })
  let message = try {
    @json_regress.assert_matches({ "a": 1 }, { "a": 2 })
    "not raised"
  } catch {
    @json_regress.Mismatch(message) => message
    e => raise e
  }
  assert_eq(message, "\"/a\": ValueMismatch; expected=1; actual=2")
}

///|
test "deep trees produce a depth difference rather than unbounded recursion" {
  let mut value : Json = null
  for _i = 0; _i < 130; _i = _i + 1 {
    value = Json::array([value])
  }
  assert_eq(
    @json_regress.compare(value, value)[0].reason,
    @json_regress.DepthLimit,
  )
}
