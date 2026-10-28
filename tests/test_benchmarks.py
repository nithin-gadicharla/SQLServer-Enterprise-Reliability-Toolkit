import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location("summary", Path(__file__).parents[1] / "benchmarks/summarize.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

class SummaryTests(unittest.TestCase):
    def sample(self, before=2, after=1):
        return {"trials": [{"phase": p, "count": 100, "elapsed_ms": v} for p,v in [("before",before),("after",after)] for _ in range(5)]}

    def test_known_medians(self):
        self.assertEqual(module.summarize(self.sample())["median_reduction_percent"], 50)

    def test_no_divide_by_zero(self):
        self.assertIsNone(module.summarize(self.sample(0,0))["median_reduction_percent"])

    def test_reject_incomplete_or_wrong_result(self):
        for data in ({"trials": []}, self.sample()):
            if data["trials"]:
                data["trials"][0]["count"] = 99
            with self.assertRaises(ValueError):
                module.summarize(data)

    def test_rejects_nonfinite_times(self):
        with self.assertRaises(ValueError):
            module.summarize(self.sample(float("nan"),1))

    def test_retains_regression(self):
        self.assertEqual(module.summarize(self.sample(1,2))["median_reduction_percent"], -100)

if __name__ == "__main__":
    unittest.main()
