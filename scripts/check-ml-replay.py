#!/usr/bin/env python3
"""Execute real producers on Native/Wasm, compare independent references, replay injected failures."""
import argparse
import copy
import json
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
ARTIFACTS = ROOT / "artifacts/ml-replay"


def produce(target, package, module=None):
    command = ["bash", str(ROOT / "scripts/moon-local.sh")]
    if module:
        command += ["-C", module]
    command += ["run", package, "--target", target]
    result = subprocess.run(command, cwd=ROOT, text=True, capture_output=True, timeout=180)
    name = "world-model" if module else "rl"
    (ARTIFACTS / f"{name}-{target}.log").write_text(result.stderr)
    if result.returncode:
        raise RuntimeError(f"Actual {name}/{target} producer failed; see {ARTIFACTS}/{name}-{target}.log")
    document = json.loads(result.stdout)
    path = ARTIFACTS / f"{name}-{target}.json"
    path.write_text(result.stdout)
    return path, document


def main(binary):
    ARTIFACTS.mkdir(parents=True, exist_ok=True)
    models, traces = {}, {}
    for target in ("native", "wasm"):
        models[target] = produce(target, "cmd/export", "integrations/moonxi")
        traces[target] = produce(target, "cmd/export_rl")
        assert models[target][1]["metadata"]["backend"] == target
    summary = {"schema_version": 1, "actual_producers": ["MoonXi CPU Linear/ReLU 3-step model", "project-authored deterministic RL environment"],
               "targets": ["native", "wasm"], "comparisons": [], "negative_controls": []}
    with tempfile.TemporaryDirectory(prefix="json-regress-ml-replay-") as directory:
        work = Path(directory)
        def compare(a, b, rules, expected_exit, name, expected_code=None):
            repro = work / f"{name}.repro.json"
            result = subprocess.run([str(binary), "compare", str(a), str(b), str(rules), "--format", "json", "--repro", str(repro)],
                                    cwd=work, text=True, capture_output=True, timeout=30)
            assert result.returncode == expected_exit, (name, result.returncode, result.stdout, result.stderr)
            report = json.loads(result.stdout)
            (ARTIFACTS / f"{name}.report.json").write_text(result.stdout)
            if expected_code:
                assert report["first_difference"]["code"] == expected_code, (name, report)
                # Copy to a different name; CLI must use captured content, not external paths.
                portable = work / f"moved-{name}.json"
                portable.write_bytes(repro.read_bytes())
                replay = subprocess.run([str(binary), "replay", str(portable), "--format", "json"],
                                        cwd=work, text=True, capture_output=True, timeout=30)
                assert replay.returncode == expected_exit and json.loads(replay.stdout) == report, (name, replay.stdout)
                (ARTIFACTS / f"{name}.repro.json").write_bytes(portable.read_bytes())
                summary["negative_controls"].append({"name": name, "exit_code": expected_exit, "first_difference": report["first_difference"], "replay": "passed"})
            else:
                assert not repro.exists()
                summary["comparisons"].append({"name": name, "exit_code": expected_exit, "statistics": report["statistics"]})
            return report
        model_rules = ROOT / "examples/files/checkpoints.rules.json"
        trace_rules = ROOT / "examples/files/trajectory.rules.json"
        for target in ("native", "wasm"):
            compare(ROOT / "fixtures/world_model_checkpoints.json", models[target][0], model_rules, 0, f"python-vs-{target}")
            compare(ROOT / "fixtures/rl.json", traces[target][0], trace_rules, 0, f"rl-python-vs-{target}")
        compare(models["native"][0], models["wasm"][0], model_rules, 0, "model-native-vs-wasm")
        compare(traces["native"][0], traces["wasm"][0], trace_rules, 0, "rl-native-vs-wasm")
        def mutant(name, edit, code, status=1, trace=False):
            reference = traces["native"][1] if trace else models["native"][1]
            candidate = copy.deepcopy(reference)
            edit(candidate)
            path = work / f"{name}.json"
            path.write_text(json.dumps(candidate, allow_nan=False))
            report = compare(traces["native"][0] if trace else models["native"][0], path,
                             trace_rules if trace else model_rules, status, name, code)
            path.unlink()
            # Prove the exported evidence remains usable after the generated candidate is removed.
            result = subprocess.run([str(binary), "replay", str(ARTIFACTS / f"{name}.repro.json"), "--format", "json"], capture_output=True, text=True, timeout=30)
            assert result.returncode == status and json.loads(result.stdout) == report
            return report
        def corrupt_hidden(doc):
            doc["checkpoints"][3]["tensor"]["data"][1] += 0.1
        hidden = mutant("hidden-layer-error", corrupt_hidden, "numeric_mismatch")
        assert hidden["first_difference"]["location"]["checkpoint_id"] == "1/linear1"
        assert hidden["first_difference"]["details"]["samples"][0]["coordinate"] == [0, 1]
        def swap_layout(doc):
            doc["checkpoints"][5]["tensor"]["data"].reverse()
        layout = mutant("same-shape-layout-error", swap_layout, "numeric_mismatch")
        assert layout["first_difference"]["location"]["layer"] == "latent"
        def time_shift(doc):
            for point in doc["checkpoints"]:
                point["step"] += 1
        mutant("checkpoint-time-shift", time_shift, "checkpoint_location_mismatch")
        mutant("missing-checkpoint", lambda doc: doc["checkpoints"].pop(3), "missing_checkpoint")
        mutant("source-mismatch", lambda doc: doc["metadata"].update(input_sha256="f" * 64), "source_mismatch", 2)
        reward = mutant("rl-reward-error", lambda doc: doc[1].update(reward=-99), "outside_tolerance", trace=True)
        assert reward["first_difference"]["location"]["episode_id"] == "goal"
        assert reward["first_difference"]["location"]["step"] == 1
        mutant("rl-time-shift", lambda doc: doc[1].update(step=2), "invalid_trajectory", 2, trace=True)
    (ARTIFACTS / "summary.json").write_text(json.dumps(summary, indent=2, ensure_ascii=False) + "\n")
    print(f"ML acceptance: {len(summary['comparisons'])} real-output comparisons and {len(summary['negative_controls'])} injected failures with portable replay passed.")
    for item in summary["comparisons"]:
        if "max_absolute_error" in item["statistics"]:
            print(f"  {item['name']}: max_absolute_error={item['statistics']['max_absolute_error']}")
    print(f"Evidence: {ARTIFACTS / 'summary.json'}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--binary", type=Path)
    args = parser.parse_args()
    binary = args.binary
    if binary is None:
        result = subprocess.run(["bash", str(ROOT / "scripts/build-cli.sh")], check=True, capture_output=True, text=True)
        binary = Path(result.stdout.strip())
    main(binary.resolve())
