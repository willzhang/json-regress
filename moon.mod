// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "willzhang/json_regress"

version = "0.1.0"

readme = "README.mbt.md"

repository = "https://github.com/willzhang/json-regress"

license = "Apache-2.0"

keywords = [ "json", "regression", "testing", "tensor" ]

preferred_target = "wasm"

description = "JSON, tensor and trajectory regression assertions with explicit tolerances and structured differences."
