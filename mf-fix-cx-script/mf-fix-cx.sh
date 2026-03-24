#!/bin/bash

# Check Wine prefix validity
function sanity {
	if [[ -z "$WPATH" ]]; then
		echo "Wine prefix path is not set"
		exit 3
	fi
	if [[ ! -d "$WPATH/drive_c" ]]; then
		echo "The prefix path ('$WPATH') does not appear to be a valid prefix"
		exit 4
	fi
}

# Help message
function print_help {
	echo "Usage: mf-fix-cx.sh <PREFIX WPATH>"
	echo ""
	echo "This script applies the Media Foundation fix to CrossOver bottles."
	echo ""
	echo "<PREFIX WPATH> is the path to the CrossOver bottle"
	echo ""
	echo "Example usage:"
	echo "  chmod +x mf-fix-cx.sh"
	echo "  ./mf-fix-cx.sh \"/Users/username/Library/Application Support/CrossOver/Bottles/BottleName\""
	echo ""
	echo "Exit codes:"
	echo "    0 : Success"
	echo "    3 : Wine prefix path not set"
	echo "    4 : The provided path does not appear to be a valid Wine prefix"
	exit 0
}

# Copy DLL files
function run_copies {
	cd "${mydir}/system32"
	arr=(*)
	for (( i=0; i<${#arr[@]}; i++ )); do
		if [[ -h "${WPATH}/drive_c/windows/system32/${arr[$i]}" ]]; then
			echo "system32/${arr[$i]} is a symbolic link"
			if [[ -w "${WPATH}/drive_c/windows/system32/${arr[$i]}" ]]; then
				echo "system32/${arr[$i]} is normally writable"
				rm "${WPATH}/drive_c/windows/system32/${arr[$i]}" && cp "${arr[$i]}" "${WPATH}/drive_c/windows/system32/"
			else
				echo "system32/${arr[$i]} is not normally writable, sudo is required"
				sudo rm "${WPATH}/drive_c/windows/system32/${arr[$i]}" && cp "${arr[$i]}" "${WPATH}/drive_c/windows/system32/"
			fi
		else
			echo "system32/${arr[$i]} is not a symbolic link"
			if [[ -w "${WPATH}/drive_c/windows/system32/${arr[$i]}" ]]; then
				echo "system32/${arr[$i]} is normally writable"
				cp "${arr[$i]}" "${WPATH}/drive_c/windows/system32/"
			else
				echo "system32/${arr[$i]} is not normally writable, sudo is required"
				sudo cp "${arr[$i]}" "${WPATH}/drive_c/windows/system32/"
			fi
		fi
	done
	cd "${mydir}/syswow64"
	arr=(*)
	for (( i=0; i<${#arr[@]}; i++ )); do
		if [[ -h "${WPATH}/drive_c/windows/syswow64/${arr[$i]}" ]]; then
			echo "syswow64/${arr[$i]} is a symbolic link"
			if [[ -w "${WPATH}/drive_c/windows/syswow64/${arr[$i]}" ]]; then
				echo "syswow64/${arr[$i]} is normally writable"
				rm "${WPATH}/drive_c/windows/syswow64/${arr[$i]}" && cp "${arr[$i]}" "${WPATH}/drive_c/windows/syswow64/"
			else
				echo "syswow64/${arr[$i]} is not normally writable, sudo is required"
				sudo rm "${WPATH}/drive_c/windows/syswow64/${arr[$i]}" && cp "${arr[$i]}" "${WPATH}/drive_c/windows/syswow64/"
			fi
		else
			echo "syswow64/${arr[$i]} is not a symbolic link"
			if [[ -w "${WPATH}/drive_c/windows/syswow64/${arr[$i]}" ]]; then
				echo "syswow64/${arr[$i]} is normally writable"
				cp "${arr[$i]}" "${WPATH}/drive_c/windows/syswow64/"
			else
				echo "syswow64/${arr[$i]} is not normally writable, sudo is required"
				sudo cp "${arr[$i]}" "${WPATH}/drive_c/windows/syswow64/"
			fi
		fi
	done
}

# Override DLLs
function dll_override {
	"/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine" --bottle "$BOTTLE_NAME" --cx-app reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v $1 /d native /f
}

shopt -s nullglob

# Main
if [[ -z "$1" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
	print_help
fi

if [[ -d "$1" ]]; then
	WPATH="$1"
	BOTTLE_NAME=$(basename "$WPATH")
	export WINEPREFIX="$1"
else
	echo "The provided path is not a valid directory: $1"
	exit 2
fi

# Check that the path is set correctly
sanity

# Exit immediately if a command exits with a non-zero status
set -e

# Disable Wine debug messages
export WINEDEBUG="-all"

# Get the script directory
mydir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

# Copy DLL files
run_copies

# Set Wine DLL overrides
dll_override "colorcnv"
dll_override "mf"
dll_override "mferror"
dll_override "mfplat"
dll_override "mfplay"
dll_override "mfreadwrite"
dll_override "msmpeg2adec"
dll_override "msmpeg2vdec"
dll_override "sqmapi"

cd "$mydir"

# Add registry keys to the prefix
"/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine" --bottle "$BOTTLE_NAME" --cx-app start regedit.exe mf.reg
"/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine" --bottle "$BOTTLE_NAME" --cx-app start regedit.exe wmf.reg

# Register the DLLs
"/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine" --bottle "$BOTTLE_NAME" --cx-app regsvr32 colorcnv.dll
"/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine" --bottle "$BOTTLE_NAME" --cx-app regsvr32 msmpeg2adec.dll
"/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine" --bottle "$BOTTLE_NAME" --cx-app regsvr32 msmpeg2vdec.dll

echo ""
echo "Media Foundation fix completed successfully!"
