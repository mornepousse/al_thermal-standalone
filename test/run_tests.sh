#!/bin/bash
# al_thermal driver test suite — run on target hardware
# Usage: bash run_tests.sh

set -u
PASS=0
FAIL=0
WARN=0

pass() { echo "  [PASS] $1"; PASS=$((PASS+1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }
warn() { echo "  [WARN] $1"; WARN=$((WARN+1)); }

echo "========================================"
echo " al_thermal driver test suite"
echo " $(date)"
echo "========================================"
echo

# -----------------------------------------------
echo "--- 1. Module loaded ---"
if lsmod | grep -q al_thermal; then
    pass "al_thermal module loaded"
else
    fail "al_thermal module NOT loaded"
fi
echo

# -----------------------------------------------
echo "--- 2. Thermal zone exists ---"
TZ_COUNT=0
for tz in /sys/class/thermal/thermal_zone*/type; do
    [ -f "$tz" ] || continue
    TYPE=$(cat "$tz" 2>/dev/null)
    TEMP_FILE=$(dirname "$tz")/temp
    TEMP=$(cat "$TEMP_FILE" 2>/dev/null)
    TEMP_C=$((TEMP / 1000))
    echo "       $(basename $(dirname $tz)): $TYPE = ${TEMP_C}°C"
    TZ_COUNT=$((TZ_COUNT+1))
done
if [ "$TZ_COUNT" -gt 0 ]; then
    pass "$TZ_COUNT thermal zone(s) found"
else
    fail "No thermal zones found"
fi
echo

# -----------------------------------------------
echo "--- 3. Temperature reading ---"
TEMP_FILE=$(find /sys/class/thermal -name "temp" 2>/dev/null | head -1)
if [ -n "$TEMP_FILE" ]; then
    TEMP=$(cat "$TEMP_FILE" 2>/dev/null)
    TEMP_C=$((TEMP / 1000))
    if [ "$TEMP_C" -gt 0 ] && [ "$TEMP_C" -lt 100 ]; then
        pass "Temperature: ${TEMP_C}°C (plausible range)"
    else
        fail "Temperature: ${TEMP_C}°C (out of plausible range 1-99)"
    fi
else
    fail "No temperature file found"
fi
echo

# -----------------------------------------------
echo "--- 4. Temperature stability ---"
if [ -n "$TEMP_FILE" ]; then
    T1=$(cat "$TEMP_FILE" 2>/dev/null)
    sleep 2
    T2=$(cat "$TEMP_FILE" 2>/dev/null)
    DIFF=$(( (T2 - T1) / 1000 ))
    if [ "$DIFF" -lt 0 ]; then DIFF=$(( -DIFF )); fi
    if [ "$DIFF" -le 5 ]; then
        pass "Stable: ${DIFF}°C change over 2s"
    else
        warn "Large change: ${DIFF}°C over 2s"
    fi
else
    warn "Skipped (no temp file)"
fi
echo

# -----------------------------------------------
echo "--- 5. Hwmon integration ---"
HWMON_FOUND=0
for h in /sys/class/hwmon/hwmon*/; do
    [ -d "$h" ] || continue
    NAME=$(cat "${h}name" 2>/dev/null)
    TEMP_F=$(ls "${h}"temp*_input 2>/dev/null | head -1)
    if [ -n "$TEMP_F" ]; then
        TEMP=$(cat "$TEMP_F" 2>/dev/null)
        TEMP_C=$((TEMP / 1000))
        echo "       $NAME: ${TEMP_C}°C ($TEMP_F)"
        HWMON_FOUND=$((HWMON_FOUND+1))
    fi
done
if [ "$HWMON_FOUND" -gt 0 ]; then
    pass "hwmon: $HWMON_FOUND sensor(s) found"
else
    warn "No hwmon temperature sensors"
fi
echo

# -----------------------------------------------
echo "--- 6. lm-sensors ---"
if command -v sensors &>/dev/null; then
    SENSORS_OUT=$(sensors 2>/dev/null)
    if [ -n "$SENSORS_OUT" ]; then
        pass "lm-sensors available"
        echo "$SENSORS_OUT" | while read l; do
            echo "       $l"
        done
    else
        warn "sensors command returned empty"
    fi
else
    warn "lm-sensors not installed"
fi
echo

# -----------------------------------------------
echo "--- 7. dmesg errors ---"
THERM_ERRS=$(dmesg 2>/dev/null | grep -iE "al.thermal|thermal" | grep -iE "error|fail|warn|bug|oops" | tail -5)
if [ -z "$THERM_ERRS" ]; then
    pass "No thermal errors in dmesg"
else
    fail "Thermal errors in dmesg:"
    echo "$THERM_ERRS" | while read l; do
        echo "       $l"
    done
fi
echo

# -----------------------------------------------
echo "========================================"
echo " Results: $PASS PASS, $FAIL FAIL, $WARN WARN"
echo "========================================"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
