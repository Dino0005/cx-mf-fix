#!/bin/bash

# Media Foundation fix for CrossOver bottles.
#
# Recipe (order matters):
#  1. Copy the nine DLLs into system32 (64-bit) and syswow64 (32-bit).
#     Remove before copying — Wine ships some as symlinks to its own builtins.
#  2. Override all nine to `native` via a single .reg file (not nine `reg add`
#     calls — nine wine start-ups waste almost a minute for no reason).
#     Overrides come BEFORE regsvr32 so registration runs against the Microsoft
#     DLLs rather than Wine's builtins.
#  3. Import mf.reg + wmf.reg in BOTH architectures. A 32-bit process reads the
#     redirected Wow6432Node view, so a 64-bit-only import leaves 32-bit games
#     seeing nothing.
#  4. regsvr32 the three COM modules in BOTH architectures. Registering
#     msmpeg2vdec writes the H.264 decoder's InputTypes/OutputTypes — without
#     this, Media Foundation enumerates no decoder and video stays black even
#     with every DLL correctly in place.
#
# Based on the community mf-install.sh / mf-fix-cx.sh procedure, aligned with
# the Silo MediaFoundationInstaller implementation.

WINE="/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine"

# Nine DLLs to copy and override
DLL_NAMES=(colorcnv mf mferror mfplat mfplay mfreadwrite msmpeg2adec msmpeg2vdec sqmapi)

# Three COM modules to register
COM_MODULES=(colorcnv msmpeg2adec msmpeg2vdec)

# ── Help ──────────────────────────────────────────────────────────────────────

function print_help {
    echo "Usage: mf-fix-cx.sh <BOTTLE_PATH>"
    echo ""
    echo "Applies the Media Foundation fix to a CrossOver bottle."
    echo ""
    echo "Example:"
    echo "  ./mf-fix-cx.sh \"/Users/username/Library/Application Support/CrossOver/Bottles/MyBottle\""
    echo ""
    echo "Exit codes:"
    echo "  0 : Success"
    echo "  1 : Missing argument or invalid path"
    echo "  2 : CrossOver not found"
    exit 0
}

# ── Sanity checks ─────────────────────────────────────────────────────────────

if [[ -z "$1" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    print_help
fi

WPATH="$1"
if [[ ! -d "$WPATH/drive_c" ]]; then
    echo "Error: '$WPATH' is not a valid CrossOver bottle (drive_c not found)."
    exit 1
fi

if [[ ! -f "$WINE" ]]; then
    echo "Error: CrossOver not found at /Applications/CrossOver.app"
    exit 2
fi

BOTTLE_NAME=$(basename "$WPATH")
export WINEPREFIX="$WPATH"
export WINEDEBUG="-all"
set -e

mydir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
DRIVE_C="$WPATH/drive_c"

echo ""
echo "=== Media Foundation Fix for CrossOver ==="
echo "Bottle: $BOTTLE_NAME"
echo ""

# ── Step 1: Copy DLLs ─────────────────────────────────────────────────────────

echo "Step 1/4 — Copying DLLs..."

for WINDIR in system32 syswow64; do
    SRC="$mydir/$WINDIR"
    DST="$DRIVE_C/windows/$WINDIR"
    mkdir -p "$DST"

    for NAME in "${DLL_NAMES[@]}"; do
        # Check both lowercase and mixed case
        for FILE in "$SRC/$NAME.dll" "$SRC/${NAME^^}.dll"; do
            if [[ -f "$FILE" ]]; then
                FNAME=$(basename "$FILE")
                # Remove first (Wine may use symlinks to its own builtins)
                rm -f "$DST/$FNAME"
                cp "$FILE" "$DST/$FNAME"
                echo "  ✓ $WINDIR/$FNAME"
            fi
        done
    done
done

echo "✓ DLLs copied"
echo ""

# ── Step 2: DLL overrides — single .reg file ──────────────────────────────────
# One wine start-up instead of nine.
# Overrides BEFORE regsvr32 so registration runs against Microsoft DLLs.

echo "Step 2/4 — Writing DLL overrides..."

OVERRIDE_REG="$DRIVE_C/cxmffix-overrides.reg"
{
    printf "REGEDIT4\r\n"
    printf "\r\n"
    printf "[HKEY_CURRENT_USER\\\\Software\\\\Wine\\\\DllOverrides]\r\n"
    for DLL in "${DLL_NAMES[@]}"; do
        printf "\"%s\"=\"native\"\r\n" "$DLL"
    done
} > "$OVERRIDE_REG"

"$WINE" --bottle "$BOTTLE_NAME" --cx-app "C:\\windows\\regedit.exe" /S "C:\\cxmffix-overrides.reg"
rm -f "$OVERRIDE_REG"

echo "✓ DLL overrides set"
echo ""

# ── Step 3: Import mf.reg + wmf.reg — both architectures ─────────────────────

echo "Step 3/4 — Importing registry files (64-bit + 32-bit)..."

for REGFILE in mf.reg wmf.reg; do
    SRC="$mydir/$REGFILE"
    if [[ ! -f "$SRC" ]]; then
        echo "  ⚠ $REGFILE not found, skipping"
        continue
    fi

    STAGED="$DRIVE_C/cxmffix-$REGFILE"
    cp "$SRC" "$STAGED"

    # 64-bit
    "$WINE" --bottle "$BOTTLE_NAME" --cx-app "C:\\windows\\regedit.exe" /S "C:\\cxmffix-$REGFILE"
    echo "  ✓ $REGFILE (64-bit)"

    # 32-bit via Wow6432Node
    "$WINE" --bottle "$BOTTLE_NAME" --cx-app "C:\\windows\\syswow64\\regedit.exe" /S "C:\\cxmffix-$REGFILE"
    echo "  ✓ $REGFILE (32-bit)"

    rm -f "$STAGED"
done

echo "✓ Registry files imported"
echo ""

# ── Step 4: regsvr32 — both architectures ────────────────────────────────────
# Registering msmpeg2vdec writes InputTypes/OutputTypes for the H.264 decoder.
# Without this, MF enumerates no decoder and video stays black.

echo "Step 4/4 — Registering COM components (64-bit + 32-bit)..."

for MODULE in "${COM_MODULES[@]}"; do
    # 64-bit
    "$WINE" --bottle "$BOTTLE_NAME" --cx-app "C:\\windows\\system32\\regsvr32.exe" /s "${MODULE}.dll"
    echo "  ✓ ${MODULE}.dll (64-bit)"

    # 32-bit
    "$WINE" --bottle "$BOTTLE_NAME" --cx-app "C:\\windows\\syswow64\\regsvr32.exe" /s "${MODULE}.dll"
    echo "  ✓ ${MODULE}.dll (32-bit)"
done

echo "✓ COM components registered"
echo ""
echo "=== Media Foundation fix completed successfully! ==="
echo ""
