# MoonXi-net CPU integration

This optional module imports the real `model.Linear` and `nparray.NpArray` implementations. The core library has no MoonXi dependency. The exact source commit, MIT license, toolchain and randomness conditions are recorded in [upstream.json](upstream.json).

From the repository root:

```sh
python3 scripts/fetch-moonxi.py
bash scripts/moon-local.sh -C integrations/moonxi test -p local/json_regress_moonxi --target native
```

The first run may download `moonbitlang/x@0.4.43` from Mooncakes. Run `moon update` if the registry index is missing. This module's `moon.work` selects only the CPU upstream module and the local regression library; it does not load the upstream CUDA workspace. Upstream deprecated API warnings are recorded as upstream warnings, not hidden by changing its source or relaxing our core checks.

`adapt` reads the framework's actual shape and Float storage. Shape is not inferred from expected output. Six tests on Native and Wasm cover the real two-row Linear output and a deterministic Linear–ReLU–Linear dynamics demo against independent Python references, with numeric, layout, dtype and nonfinite negative cases.

Run `bash scripts/moon-local.sh -C integrations/moonxi run cmd/showcases --target native` from the repository root for both demonstrations. Run `python3 scripts/generate-references.py --check` to verify JSON, embedded MoonBit fixture source and SHA-256 records.

For interface/format maintenance, select only our packages: `moon info . cmd/showcases cmd/export` and `moon fmt . cmd/showcases cmd/export` inside this module. Unqualified workspace formatting also visits upstream members.


`cmd/export` runs the real three-step recurrent model and emits nine checkpoint tensors, tagged with the compiled backend. Run it with `--target native` or `--target wasm`. `python3 scripts/check-ml-replay.py` checks independent Python references, actual cross-backend outputs, deliberate failures and portable comparison replay. See [file comparison](../../docs/FILE_COMPARISON.md).
