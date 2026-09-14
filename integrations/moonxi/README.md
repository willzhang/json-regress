# MoonXi-net CPU integration

This optional module imports the real `model.Linear` and `nparray.NpArray` implementations. The core library has no MoonXi dependency. The exact source commit, MIT license, toolchain and randomness conditions are recorded in [upstream.json](upstream.json).

From the repository root:

```sh
python3 scripts/fetch-moonxi.py
bash scripts/moon-local.sh -C integrations/moonxi test -p local/json_regress_moonxi --target native
```

The first run may download `moonbitlang/x@0.4.43` from Mooncakes. Run `moon update` if the registry index is missing. This module's `moon.work` selects only the CPU upstream module and the local regression library; it does not load the upstream CUDA workspace. Upstream deprecated API warnings are recorded as upstream warnings, not hidden by changing its source or relaxing our core checks.

`adapt` reads the framework's actual shape and Float storage. Shape is not inferred from expected output. A fixed two-row Linear forward pass provides the initial smoke test; numerical reference checks are added separately.
