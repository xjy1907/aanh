#!/bin/bash
# IPA pack script for abnh (wasd-compatible)
# Output: ~/Desktop/ipa/abnh.ipa

set -e
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

APP_PATH="${CODESIGNING_FOLDER_PATH}"
PROJECT_DIR="${SRCROOT:-${PROJECT_DIR}}"
ENTITLEMENTS_PATH="${PROJECT_DIR}/supports/entitlements.plist"
OUTPUT_DIR="${HOME}/Desktop/ipa"
SHELL_ENTITLEMENTS_PATH="${PROJECT_DIR}/supports/entitlements-shell.plist"
FULL_ENTITLEMENTS_PATH="${PROJECT_DIR}/supports/entitlements.plist"
IOS15_ENTITLEMENTS_PATH="${PROJECT_DIR}/supports/entitlements-ios15.plist"

echo "[Pack IPA] start"
echo "[Pack IPA] PROJECT_DIR=${PROJECT_DIR}"
echo "[Pack IPA] APP_PATH=${APP_PATH}"
echo "[Pack IPA] ENTITLEMENTS=${ENTITLEMENTS_PATH}"
echo "[Pack IPA] PLATFORM_NAME=${PLATFORM_NAME}"
echo "[Pack IPA] CONFIGURATION=${CONFIGURATION}"

if [ "${PLATFORM_NAME}" != "iphoneos" ]; then
  echo "[Pack IPA] skip non-device build"
  exit 0
fi

if [ -z "${APP_PATH}" ] || [ ! -d "${APP_PATH}" ]; then
  echo "[Pack IPA] ERROR: app not found: ${APP_PATH}"
  echo "[Pack IPA] Tip: choose Any iOS Device (arm64), Scheme Books"
  exit 1
fi

if [ ! -f "${ENTITLEMENTS_PATH}" ]; then
  echo "[Pack IPA] ERROR: entitlements missing: ${ENTITLEMENTS_PATH}"
  exit 1
fi

if ! command -v ldid >/dev/null 2>&1; then
  echo "[Pack IPA] ERROR: ldid not found. Install: brew install ldid"
  exit 1
fi
echo "[Pack IPA] ldid=$(command -v ldid)"

INFO_PLIST=""
for candidate in "${PROJECT_DIR}/Resources/Info.plist" "${PROJECT_DIR}/Resources/info.plist"; do
  if [ -f "${candidate}" ]; then
    INFO_PLIST="${candidate}"
    break
  fi
done

DISPLAY_NAME="${IPA_BASENAME:-}"
if [ -z "${DISPLAY_NAME}" ] && [ -n "${INFO_PLIST}" ]; then
  DISPLAY_NAME=$(/usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" "${INFO_PLIST}" 2>/dev/null || true)
fi
if [ -z "${DISPLAY_NAME}" ] || [ "${DISPLAY_NAME}" = "Books" ]; then
  DISPLAY_NAME="abnh"
fi
IPA_NAME="${DISPLAY_NAME}.ipa"
echo "[Pack IPA] IPA_NAME=${IPA_NAME}"

TEMP_DIR=$(mktemp -d)
cleanup() { rm -rf "${TEMP_DIR}"; }
trap cleanup EXIT

mkdir -p "${OUTPUT_DIR}"
rm -f "${OUTPUT_DIR}/${IPA_NAME}"

mkdir -p "${TEMP_DIR}/Payload"
cp -R "${APP_PATH}" "${TEMP_DIR}/Payload/"
APP_NAME=$(basename "${APP_PATH}")
COPIED_APP="${TEMP_DIR}/Payload/${APP_NAME}"
chmod -R u+rwX,go+rX "${COPIED_APP}"

EXECUTABLE_NAME=$(/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "${COPIED_APP}/Info.plist" 2>/dev/null || true)
if [ -z "${EXECUTABLE_NAME}" ]; then
  echo "[Pack IPA] ERROR: CFBundleExecutable missing"
  exit 1
fi
EXECUTABLE_PATH="${COPIED_APP}/${EXECUTABLE_NAME}"
if [ ! -f "${EXECUTABLE_PATH}" ]; then
  echo "[Pack IPA] ERROR: binary missing: ${EXECUTABLE_PATH}"
  exit 1
fi

HAS_STEP16=0
HAS_STEP15=0
HAS_STEP14=0
HAS_STEP13=0
HAS_STEP12=0
HAS_STEP11=0
HAS_STEP10=0
HAS_STEP9=0
HAS_STEP8=0
HAS_STEP7=0
HAS_STEP6=0
HAS_STEP5=0
HAS_STEP4B=0
HAS_STEP4=0
HAS_KEEP_DYLIB=0
HAS_STRIP_SHELL=0
if strings "${EXECUTABLE_PATH}" 2>/dev/null | grep -q 'STEP16-TFHOST'; then
  HAS_STEP16=1
  HAS_KEEP_DYLIB=1
fi
if strings "${EXECUTABLE_PATH}" 2>/dev/null | grep -q 'STEP15-METAL'; then
  HAS_STEP15=1
  HAS_KEEP_DYLIB=1
fi
if strings "${EXECUTABLE_PATH}" 2>/dev/null | grep -q 'STEP14-LIVECOVER'; then
  HAS_STEP14=1
  HAS_KEEP_DYLIB=1
fi
if strings "${EXECUTABLE_PATH}" 2>/dev/null | grep -q 'STEP13-DRAWSURF'; then
  HAS_STEP13=1
  HAS_KEEP_DYLIB=1
fi
if strings "${EXECUTABLE_PATH}" 2>/dev/null | grep -q 'STEP12-BBZVCS'; then
  HAS_STEP12=1
  HAS_KEEP_DYLIB=1
fi
if strings "${EXECUTABLE_PATH}" 2>/dev/null | grep -q 'STEP11-HUDHOST'; then
  HAS_STEP11=1
  HAS_KEEP_DYLIB=1
fi
if strings "${EXECUTABLE_PATH}" 2>/dev/null | grep -q 'STEP10-BBZHOST'; then
  HAS_STEP10=1
  HAS_KEEP_DYLIB=1
fi
if strings "${EXECUTABLE_PATH}" 2>/dev/null | grep -q 'STEP9-KREAD'; then
  HAS_STEP9=1
  HAS_KEEP_DYLIB=1
fi
if strings "${EXECUTABLE_PATH}" 2>/dev/null | grep -q 'STEP8-PATCHFIND'; then
  HAS_STEP8=1
  HAS_KEEP_DYLIB=1
fi
if strings "${EXECUTABLE_PATH}" 2>/dev/null | grep -q 'STEP7-KERNELCACHE'; then
  HAS_STEP7=1
  HAS_KEEP_DYLIB=1
fi
if strings "${EXECUTABLE_PATH}" 2>/dev/null | grep -q 'STEP6-XPF-RUN'; then
  HAS_STEP6=1
  HAS_KEEP_DYLIB=1
fi
if strings "${EXECUTABLE_PATH}" 2>/dev/null | grep -q 'STEP5-BOOT-UI'; then
  HAS_STEP5=1
  HAS_KEEP_DYLIB=1
fi
if strings "${EXECUTABLE_PATH}" 2>/dev/null | grep -q 'STEP4B-SAFE-ENT'; then
  HAS_STEP4B=1
  HAS_KEEP_DYLIB=1
fi
if strings "${EXECUTABLE_PATH}" 2>/dev/null | grep -q 'STEP4-FULL-ENT'; then
  HAS_STEP4=1
  HAS_KEEP_DYLIB=1
fi
if strings "${EXECUTABLE_PATH}" 2>/dev/null | grep -qE 'STEP3-DLOPEN-JB'; then
  HAS_KEEP_DYLIB=1
fi
if strings "${EXECUTABLE_PATH}" 2>/dev/null | grep -qE 'STEP2-UI-LIGHT|STEP2-UI-ONLY|SHELL3-NO-DYLIB|SHELL4-MIN-ENT|SHELL5-NOPCH'; then
  if [ "$HAS_STEP16" != "1" ] && [ "$HAS_STEP15" != "1" ] && [ "$HAS_STEP14" != "1" ] && [ "$HAS_STEP13" != "1" ] && [ "$HAS_STEP12" != "1" ] && [ "$HAS_STEP11" != "1" ] && [ "$HAS_STEP10" != "1" ] && [ "$HAS_STEP9" != "1" ] && [ "$HAS_STEP8" != "1" ] && [ "$HAS_STEP7" != "1" ] && [ "$HAS_STEP6" != "1" ] && [ "$HAS_STEP5" != "1" ] && [ "$HAS_STEP4B" != "1" ] && [ "$HAS_STEP4" != "1" ] && [ "$HAS_KEEP_DYLIB" != "1" ]; then
    HAS_STRIP_SHELL=1
  fi
fi

if [ "$HAS_STEP16" = "1" ] || [ "$HAS_STEP15" = "1" ] || [ "$HAS_STEP14" = "1" ] || [ "$HAS_STEP13" = "1" ] || [ "$HAS_STEP12" = "1" ] || [ "$HAS_STEP11" = "1" ] || [ "$HAS_STEP10" = "1" ] || [ "$HAS_STEP9" = "1" ] || [ "$HAS_STEP8" = "1" ] || [ "$HAS_STEP7" = "1" ] || [ "$HAS_STEP6" = "1" ] || [ "$HAS_STEP5" = "1" ] || [ "$HAS_STEP4B" = "1" ]; then
  if [ -f "${IOS15_ENTITLEMENTS_PATH}" ]; then
    ENTITLEMENTS_PATH="${IOS15_ENTITLEMENTS_PATH}"
    echo "[Pack IPA] STEP16/15/14/13/12/11/10/9/8/7/6/5/4B — using entitlements-ios15.plist (no banned keys)"
  fi
elif [ "$HAS_STEP4" = "1" ]; then
  if [ -f "${FULL_ENTITLEMENTS_PATH}" ]; then
    ENTITLEMENTS_PATH="${FULL_ENTITLEMENTS_PATH}"
    echo "[Pack IPA] STEP4 — using entitlements.plist (full)"
  fi
elif strings "${EXECUTABLE_PATH}" 2>/dev/null | grep -qE 'STEP3-DLOPEN-JB|STEP2-UI-LIGHT|STEP2-UI-ONLY|SHELL3-NO-DYLIB|SHELL4-MIN-ENT|SHELL5-NOPCH'; then
  if [ -f "${SHELL_ENTITLEMENTS_PATH}" ]; then
    ENTITLEMENTS_PATH="${SHELL_ENTITLEMENTS_PATH}"
    echo "[Pack IPA] using entitlements-shell.plist"
  fi
fi

if [ "$HAS_STRIP_SHELL" = "1" ]; then
  echo "[Pack IPA] step2/shell marker — stripping embedded dylibs"
  find "${COPIED_APP}" -name '*.dylib' -type f -print -delete 2>/dev/null || true
  find "${COPIED_APP}/Frameworks" -name '*.dylib' -type f -print -delete 2>/dev/null || true
else
  if [ "$HAS_STEP16" = "1" ]; then
    echo "[Pack IPA] STEP16 marker — keep/rename dylibs + ios15-safe entitlements"
  elif [ "$HAS_STEP15" = "1" ]; then
    echo "[Pack IPA] STEP15 marker — keep/rename dylibs + ios15-safe entitlements"
  elif [ "$HAS_STEP14" = "1" ]; then
    echo "[Pack IPA] STEP14 marker — keep/rename dylibs + ios15-safe entitlements"
  elif [ "$HAS_STEP13" = "1" ]; then
    echo "[Pack IPA] STEP13 marker — keep/rename dylibs + ios15-safe entitlements"
  elif [ "$HAS_STEP12" = "1" ]; then
    echo "[Pack IPA] STEP12 marker — keep/rename dylibs + ios15-safe entitlements"
  elif [ "$HAS_STEP11" = "1" ]; then
    echo "[Pack IPA] STEP11 marker — keep/rename dylibs + ios15-safe entitlements"
  elif [ "$HAS_STEP10" = "1" ]; then
    echo "[Pack IPA] STEP10 marker — keep/rename dylibs + ios15-safe entitlements"
  elif [ "$HAS_STEP9" = "1" ]; then
    echo "[Pack IPA] STEP9 marker — keep/rename dylibs + ios15-safe entitlements"
  elif [ "$HAS_STEP8" = "1" ]; then
    echo "[Pack IPA] STEP8 marker — keep/rename dylibs + ios15-safe entitlements"
  elif [ "$HAS_STEP7" = "1" ]; then
    echo "[Pack IPA] STEP7 marker — keep/rename dylibs + ios15-safe entitlements"
  elif [ "$HAS_STEP6" = "1" ]; then
    echo "[Pack IPA] STEP6 marker — keep/rename dylibs + ios15-safe entitlements"
  elif [ "$HAS_STEP5" = "1" ]; then
    echo "[Pack IPA] STEP5 marker — keep/rename dylibs + ios15-safe entitlements"
  elif [ "$HAS_STEP4B" = "1" ]; then
    echo "[Pack IPA] STEP4B marker — keep/rename dylibs + ios15-safe entitlements"
  elif [ "$HAS_STEP4" = "1" ]; then
    echo "[Pack IPA] STEP4 marker — keep/rename embedded dylibs + full entitlements"
  elif [ "$HAS_KEEP_DYLIB" = "1" ]; then
    echo "[Pack IPA] STEP3 marker — keep/rename embedded dylibs for deferred dlopen"
  fi
  rename_dylib() {
    local old="$1" new="$2"
    local src="${COPIED_APP}/${old}"
    local dst="${COPIED_APP}/${new}"
    if [ ! -f "${src}" ]; then
      return 0
    fi
    echo "[Pack IPA] rename ${old} -> ${new}"
    mv "${src}" "${dst}"
    install_name_tool -id "@executable_path/${new}" "${dst}" 2>/dev/null || true
    install_name_tool -change "@executable_path/${old}" "@executable_path/${new}" "${EXECUTABLE_PATH}" 2>/dev/null || true
    install_name_tool -change "@loader_path/${old}" "@executable_path/${new}" "${EXECUTABLE_PATH}" 2>/dev/null || true
    if [ -d "${COPIED_APP}/Frameworks" ]; then
      find "${COPIED_APP}/Frameworks" -type f ! -name "*.plist" ! -name "*.h" 2>/dev/null | while IFS= read -r bin; do
        install_name_tool -change "@executable_path/${old}" "@executable_path/${new}" "${bin}" 2>/dev/null || true
        install_name_tool -change "@loader_path/${old}" "@executable_path/${new}" "${bin}" 2>/dev/null || true
      done
    fi
    for d in "${COPIED_APP}"/*.dylib; do
      [ -f "${d}" ] || continue
      install_name_tool -change "@loader_path/${old}" "@loader_path/${new}" "${d}" 2>/dev/null || true
      install_name_tool -change "@executable_path/${old}" "@executable_path/${new}" "${d}" 2>/dev/null || true
    done
  }
  rename_dylib libjailbreak.dylib libNHSupport.dylib
  rename_dylib libchoma.dylib libNHCodec.dylib
  rename_dylib libxpf.dylib libNHParse.dylib
fi

echo "[Pack IPA] signing with ldid (${ENTITLEMENTS_PATH})..."
if ! ldid -S"${ENTITLEMENTS_PATH}" "${COPIED_APP}"; then
  echo "[Pack IPA] WARN: app-level ldid failed, try binary only"
  ldid -S"${ENTITLEMENTS_PATH}" "${EXECUTABLE_PATH}"
else
  ldid -S"${ENTITLEMENTS_PATH}" "${EXECUTABLE_PATH}" || true
fi

echo "[Pack IPA] zipping..."
(
  cd "${TEMP_DIR}"
  /usr/bin/zip -qr "${IPA_NAME}" Payload
)
mv "${TEMP_DIR}/${IPA_NAME}" "${OUTPUT_DIR}/${IPA_NAME}"
FILE_SIZE=$(du -h "${OUTPUT_DIR}/${IPA_NAME}" | awk '{print $1}')
echo "[Pack IPA] OK -> ${OUTPUT_DIR}/${IPA_NAME} (${FILE_SIZE})"
exit 0
