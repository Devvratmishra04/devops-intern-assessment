#!/usr/bin/env python3
"""
Jira Extraction Application – Test Runner
===========================================
Executes the full automated test suite and prints a formatted report
with execution metrics, pass/fail counts, and timing.

Usage:
    python run_tests.py
"""

import os
import sys
import time
import unittest
from datetime import datetime
from pathlib import Path


def main():
    # Change to the project root directory
    project_root = Path(__file__).resolve().parent
    os.chdir(project_root)

    print()
    print("=" * 70)
    print("  JIRA EXTRACTION APPLICATION – AUTOMATED TEST SUITE")
    print(f"  Executed: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 70)
    print()

    # Discover and load tests
    loader = unittest.TestLoader()
    suite = loader.discover("tests", pattern="test_*.py")

    # Count total tests
    def count_tests(suite):
        count = 0
        for test_group in suite:
            if hasattr(test_group, "__iter__"):
                count += count_tests(test_group)
            else:
                count += 1
        return count

    total = count_tests(suite)
    print(f"  Discovered {total} test cases across {len(list(suite))} test modules")
    print(f"  Test directory: tests/")
    print()
    print("-" * 70)
    print()

    # Run tests with verbose output
    start_time = time.time()
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    elapsed = time.time() - start_time

    # Print summary
    print()
    print("=" * 70)
    print("  TEST EXECUTION SUMMARY")
    print("=" * 70)
    print()

    passed = result.testsRun - len(result.failures) - len(result.errors) - len(result.skipped)
    status = "PASSED" if result.wasSuccessful() else "FAILED"
    status_marker = "[OK]" if result.wasSuccessful() else "[FAIL]"

    print(f"  {status_marker}  Overall Result:   {status}")
    print(f"  [#]  Total Tests:      {result.testsRun}")
    print(f"  [+]  Passed:           {passed}")
    print(f"  [-]  Failed:           {len(result.failures)}")
    print(f"  [!]  Errors:           {len(result.errors)}")
    print(f"  [>]  Skipped:          {len(result.skipped)}")
    print(f"  [T]  Execution Time:   {elapsed:.2f}s")
    print(f"  [%]  Pass Rate:        {(passed / result.testsRun * 100) if result.testsRun else 0:.1f}%")
    print()

    if result.failures:
        print("-" * 70)
        print("  FAILURES:")
        for test, traceback in result.failures:
            print(f"    [x] {test}")
        print()

    if result.errors:
        print("-" * 70)
        print("  ERRORS:")
        for test, traceback in result.errors:
            print(f"    [x] {test}")
        print()

    if result.skipped:
        print("-" * 70)
        print("  SKIPPED:")
        for test, reason in result.skipped:
            print(f"    [>] {test}: {reason}")
        print()

    print("=" * 70)
    print()

    # Exit with appropriate code
    sys.exit(0 if result.wasSuccessful() else 1)


if __name__ == "__main__":
    main()
