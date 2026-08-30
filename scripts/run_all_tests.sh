#!/usr/bin/env bash
set -e

echo "============================================================"
echo "   LiverAI Precision Diagnostics — QA Regression Suite     "
echo "============================================================"

echo -e "\n--> Running Web E2E & Cross-Platform Tests..."
python -m pytest tests/e2e/ -v

echo -e "\n--> Running Mobile (Flutter) E2E Tests..."
cd "Liver Disease Detection App"
flutter test test/e2e/
cd ..

echo -e "\n============================================================"
echo "   ALL REGRESSION SUITES PASSED SUCCESSFULLY (100%)       "
echo "============================================================"
