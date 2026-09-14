#!/usr/bin/env python3
"""Native CLI acceptance in an unrelated directory. No network, third-party Python, or shell eval."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def run_checks(binary):
    cases = 0
    with tempfile.TemporaryDirectory(prefix="json-regress-cli-") as directory:
        work = Path(directory)
        def write(name, value, raw=False):
            path = work / name
            path.write_text(value if raw else json.dumps(value, allow_nan=False), encoding="utf-8")
            return name
        def call(arguments, expected):
            nonlocal cases
            result = subprocess.run([str(binary), *arguments, "--format", "json"], cwd=work,
                                    text=True, capture_output=True, timeout=20)
            assert result.returncode == expected, (arguments, result.returncode, result.stdout, result.stderr)
            report = json.loads(result.stdout)
            assert report["schema_version"] == 1 and report["exit_code"] == expected
            cases += 1
            return report, result.stdout
        def compare(expected=0, extra=()):
            return call(["compare", "expected.json", "actual.json", "rules.json", *extra], expected)
        rules = {"schema_version": 1, "mode": "json"}
        write("rules.json", rules)
        write("expected.json", {"price": 10, "request/id": "left"})
        write("actual.json", {"request/id": "right", "price": 10.001})
        write("rules.json", dict(rules, ignore_paths=["/request~1id"], tolerances=[{"path": "/price", "absolute": 0.002}]))
        original = (work / "expected.json").read_bytes()
        good, output = compare(extra=["--report", "report.json", "--repro", "unused-repro.json"])
        assert not (work / "unused-repro.json").exists()
        assert json.loads((work / "report.json").read_text()) == good
        assert compare()[1] == output
        assert compare(2, ["--report", "expected.json"])[0]["first_difference"]["code"] == "usage_error"
        assert (work / "expected.json").read_bytes() == original
        (work / "alias.json").symlink_to(work / "expected.json")
        compare(2, ["--report", "alias.json"])
        assert (work / "expected.json").read_bytes() == original
        write("actual.json", {"price": 99, "request/id": "right"})
        failed, _ = compare(1, ["--repro", "failed.json"])
        snapshot = json.loads((work / "failed.json").read_text())
        assert snapshot["expected_text"] == original.decode()
        moved = work / "elsewhere"
        moved.mkdir()
        shutil.move(work / "failed.json", moved / "failure.json")
        # Original inputs no longer exist: replay must rely on captured text alone.
        for name in ("expected.json", "actual.json", "rules.json"):
            (work / name).unlink()
        replayed, _ = call(["replay", "elsewhere/failure.json"], 1)
        assert replayed == failed
        snapshot["recorded_report"]["exit_code"] = 0
        write("drift.json", snapshot)
        assert call(["replay", "drift.json"], 2)[0]["first_difference"]["code"] == "replay_drift"
        call(["compare", "missing", "missing", "missing"], 2)
        write("rules.json", {"schema_version": 1, "mode": "tensor"})
        tensor = {"shape": [1, 2], "dtype": "float32", "data": [1, 2]}
        write("expected.json", tensor)
        write("actual.json", dict(tensor, shape=[2, 1]))
        assert compare(1)[0]["first_difference"]["code"] == "shape_mismatch"
        write("actual.json", dict(tensor, data=[2, 1]))
        assert compare(1)[0]["first_difference"]["details"]["samples"][0]["coordinate"] == [0, 0]
        write("actual.json", dict(tensor, shape=[2, 2]))
        assert compare(2)[0]["first_difference"]["code"] == "invalid_input"
        write("actual.json", "{", raw=True)
        assert compare(2)[0]["first_difference"]["code"] == "invalid_json"
        write("actual.json", tensor)
        write("rules.json", {"schema_version": 1, "mode": "tensor", "absolute": -1})
        assert compare(2)[0]["first_difference"]["code"] == "invalid_rules"
        write("rules.json", {"schema_version": 1, "mode": "tensor"})
        write("actual.json", '{"shape":[],"dtype":"float32","data":[1e-400]}', raw=True)
        assert compare(2)[0]["first_difference"]["code"] == "invalid_input"
        # Numeric-looking strings and escaped quotes must not trigger lexical checks.
        write("rules.json", rules)
        strange = {"value": 'a\\" 1e-999 and -2e400', "zero": 0}
        write("expected.json", strange)
        write("actual.json", strange)
        compare()
        call(["compare", "expected.json", "actual.json", "rules.json", "--unknown", "x"], 2)
        call(["replay", "elsewhere/failure.json", "--repro", "no.json"], 2)
        call([], 2)
        help_result = subprocess.run([str(binary), "--help"], cwd=work, capture_output=True, text=True)
        assert help_result.returncode == 0 and "Usage:" in help_result.stdout
        cases += 1
    print(f"CLI acceptance: {cases} process cases passed (exit codes, external cwd, stable reports, protected inputs, portable replay).")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--binary", type=Path)
    args = parser.parse_args()
    binary = args.binary
    if binary is None:
        build = subprocess.run(["bash", str(ROOT / "scripts/build-cli.sh")], check=True, capture_output=True, text=True)
        binary = Path(build.stdout.strip())
    run_checks(binary.resolve())
