///|
#cfg(target="native")
fn backend() -> String {
  "native"
}

///|
#cfg(target="wasm")
fn backend() -> String {
  "wasm"
}

///|
#cfg(target="wasm-gc")
fn backend() -> String {
  "wasm-gc"
}

///|
#cfg(target="js")
fn backend() -> String {
  "js"
}

///|
fn main {
  println(
    @checking.canonical_json(
      try! @integration.world_model_checkpoints(backend()),
    ),
  )
}
