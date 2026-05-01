#!/usr/bin/env bash
# Run all Capitalo headless tests. Exits 1 if any fail.
# Usage: ./tests/run_all.sh

set -e
cd "$(dirname "$0")/.."

TESTS=(
    "RunBigNumberTest"
    "CityViewTest"
    "HUDTest"
    "ShopUpgradeModalTest"
    "FloatingNumberLayerTest"
    "TutorialControllerTest"
    "SaveRoundTripTest"
    "OfflineEarningsTest"
)

FAILED=()

for t in "${TESTS[@]}"; do
    echo "=== $t ==="
    if ! godot --headless --script "tests/$t.gd" --path . 2>&1 | tail -8; then
        FAILED+=("$t")
    fi
    echo
done

if [ ${#FAILED[@]} -ne 0 ]; then
    echo "FAILED: ${FAILED[*]}"
    exit 1
fi

echo "ALL TESTS PASSED"
