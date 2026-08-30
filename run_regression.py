#!/usr/bin/env python3
"""
run_regression.py
=================
Unified Automated QA Regression Suite Runner for LiverAI (Web & Mobile).

Usage:
  python run_regression.py --all         # Run Web, Mobile & Cross-Platform Regression
  python run_regression.py --web         # Run Web E2E & API tests only
  python run_regression.py --mobile      # Run Flutter Mobile tests only
  python run_regression.py --cross       # Run Cross-Platform Parity tests only
"""

import os
import sys
import time
import argparse
import subprocess

# Ensure UTF-8 output on Windows consoles if supported
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass


class Colors:
    HEADER = "\033[95m"
    BLUE = "\033[94m"
    CYAN = "\033[96m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    RED = "\033[91m"
    RESET = "\033[0m"
    BOLD = "\033[1m"
    UNDERLINE = "\033[4m"


def print_banner():
    print(f"\n{Colors.CYAN}{Colors.BOLD}=============================================================================={Colors.RESET}")
    print(f"{Colors.CYAN}{Colors.BOLD}       LiverAI Precision Diagnostics - Automated QA Regression Suite       {Colors.RESET}")
    print(f"{Colors.CYAN}{Colors.BOLD}=============================================================================={Colors.RESET}\n")


def run_command(title, cmd, cwd=None):
    print(f"{Colors.BLUE}[RUNNING]{Colors.RESET} {Colors.BOLD}{title}{Colors.RESET}")
    print(f"{Colors.YELLOW}Command:{Colors.RESET} {' '.join(cmd) if isinstance(cmd, list) else cmd}")
    start_time = time.time()

    proc = subprocess.run(
        cmd,
        cwd=cwd,
        shell=True,
        capture_output=False,
    )
    elapsed = time.time() - start_time

    if proc.returncode == 0:
        print(f"{Colors.GREEN}[PASSED]{Colors.RESET} {title} ({elapsed:.2f}s)\n")
        return True, elapsed
    else:
        print(f"{Colors.RED}[FAILED]{Colors.RESET} {title} (Exit Code: {proc.returncode}, {elapsed:.2f}s)\n")
        return False, elapsed


def main():
    parser = argparse.ArgumentParser(description="LiverAI QA Automation Test Suite Runner")
    parser.add_argument("--all", action="store_true", help="Run entire regression test suite")
    parser.add_argument("--web", action="store_true", help="Run Web E2E & API test suite")
    parser.add_argument("--mobile", action="store_true", help="Run Mobile Flutter test suite")
    parser.add_argument("--cross", action="store_true", help="Run Cross-Platform Parity test suite")
    parser.add_argument("-v", "--verbose", action="store_true", help="Verbose pytest output")

    args = parser.parse_args()

    # Default to all if no specific suite selected
    if not (args.web or args.mobile or args.cross or args.all):
        args.all = True

    print_banner()

    root_dir = os.path.dirname(os.path.abspath(__file__))
    flutter_dir = os.path.join(root_dir, "Liver Disease Detection App")

    results = []
    total_start = time.time()

    # 1. Web Test Suite
    if args.all or args.web:
        web_cmd = [sys.executable, "-m", "pytest", "tests/e2e/web/specs/", "-v" if args.verbose else "-q"]
        passed, duration = run_command("Web Application E2E Test Suite", web_cmd, cwd=root_dir)
        results.append(("Web E2E Suite", passed, duration))

    # 2. Cross-Platform Parity Suite
    if args.all or args.cross:
        cross_cmd = [sys.executable, "-m", "pytest", "tests/e2e/cross_platform/", "-v" if args.verbose else "-q"]
        passed, duration = run_command("Cross-Platform Parity Test Suite", cross_cmd, cwd=root_dir)
        results.append(("Cross-Platform Parity", passed, duration))

    # 3. Mobile (Flutter) Test Suite
    if args.all or args.mobile:
        if os.path.exists(flutter_dir):
            mobile_cmd = ["flutter", "test", "test/e2e/"]
            passed, duration = run_command("Mobile (Flutter) E2E Test Suite", mobile_cmd, cwd=flutter_dir)
            results.append(("Mobile (Flutter) Suite", passed, duration))
        else:
            print(f"{Colors.YELLOW}[SKIPPED]{Colors.RESET} Mobile directory not found.\n")

    total_duration = time.time() - total_start

    # Summary Table
    print(f"\n{Colors.BOLD}=============================================================================={Colors.RESET}")
    print(f"{Colors.BOLD}                          TEST EXECUTION SUMMARY                            {Colors.RESET}")
    print(f"{Colors.BOLD}=============================================================================={Colors.RESET}")
    print(f"{'Test Suite':<35} | {'Status':<12} | {'Duration':<10}")
    print("------------------------------------+--------------+-----------")

    all_passed = True
    for suite, passed, duration in results:
        status_str = f"{Colors.GREEN}PASSED{Colors.RESET}" if passed else f"{Colors.RED}FAILED{Colors.RESET}"
        if not passed:
            all_passed = False
        print(f"{suite:<35} | {status_str:<21} | {duration:.2f}s")

    print(f"==============================================================================")
    print(f"Total Execution Time: {total_duration:.2f}s")
    if all_passed:
        print(f"{Colors.GREEN}{Colors.BOLD}[SUCCESS] ALL AUTOMATED TEST SUITES PASSED CLEANLY!{Colors.RESET}\n")
        sys.exit(0)
    else:
        print(f"{Colors.RED}{Colors.BOLD}[FAILURE] SOME TESTS FAILED. PLEASE REVIEW LOGS ABOVE.{Colors.RESET}\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
