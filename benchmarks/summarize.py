"""Summarize measured raw.json only. No built-in/synthetic performance numbers."""
import json
import math
import statistics
import sys
from pathlib import Path

def summarize(data):
    result = {}
    for phase in ("before", "after"):
        trials = [t for t in data["trials"] if t["phase"] == phase]
        if len(trials) < 5 or any(t["count"] != 100 or (not math.isfinite(t["elapsed_ms"]) or t["elapsed_ms"] < 0) for t in trials):
            raise ValueError("At least five valid trials per phase are required")
        values = sorted(t["elapsed_ms"] for t in trials)
        result[phase] = {"n": len(values), "median_ms": statistics.median(values),
                         "min_ms": min(values), "max_ms": max(values)}
    baseline = result["before"]["median_ms"]
    result["median_reduction_percent"] = (100 * (baseline - result["after"]["median_ms"]) / baseline if baseline else None)
    return result

if __name__ == "__main__":
    print(json.dumps(summarize(json.loads(Path(sys.argv[1]).read_text(encoding="utf-8-sig"))), indent=2))
