#!/usr/bin/env bash
# Generates the android/ and ios/ folders when they are missing and applies the settings this app needs.
# Idempotent: safe to run locally and in CI before every build.
#
#   scripts/setup_platforms.sh              # android + ios
#   scripts/setup_platforms.sh android      # only one platform
#   CLEARTEXT=1 scripts/setup_platforms.sh # allow http:// backends (local development only!)
set -euo pipefail

cd "$(dirname "$0")/.."
platforms="${1:-android,ios}"

if [[ "$platforms" == *android* && ! -d android ]] || [[ "$platforms" == *ios* && ! -d ios ]]; then
  flutter create . --platforms="$platforms" --project-name ddarungi_noti --org kr.ddarungi
fi

if [[ "$platforms" == *android* ]]; then
  python3 - <<'PY'
import os, re, sys

path = "android/app/src/main/AndroidManifest.xml"
if not os.path.exists(path):
    sys.exit("missing " + path)
xml = open(path, encoding="utf-8").read()

# Release builds do not get INTERNET from the template (only debug/profile do), but the Kakao map
# (WebView) and the API client need it. Location is used for "my location" on the map.
wanted = [
    "android.permission.INTERNET",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.ACCESS_COARSE_LOCATION",
    "android.permission.POST_NOTIFICATIONS",
]
missing = [p for p in wanted if p not in xml]
if missing:
    lines = "".join('\n    <uses-permission android:name="%s"/>' % p for p in missing)
    xml, n = re.subn(r"(<manifest\b[^>]*>)", lambda m: m.group(1) + lines, xml, count=1)
    if n != 1:
        sys.exit("could not find <manifest> in " + path)

if os.environ.get("CLEARTEXT") == "1" and "usesCleartextTraffic" not in xml:
    xml, n = re.subn(r"<application\b", '<application android:usesCleartextTraffic="true"', xml, count=1)
    if n != 1:
        sys.exit("could not find <application> in " + path)

open(path, "w", encoding="utf-8").write(xml)
print("patched", path)
PY
fi

if [[ "$platforms" == *ios* ]]; then
  python3 - <<'PY'
import os, plistlib, sys

path = "ios/Runner/Info.plist"
if not os.path.exists(path):
    sys.exit("missing " + path)
with open(path, "rb") as f:
    plist = plistlib.load(f)

plist.setdefault(
    "NSLocationWhenInUseUsageDescription",
    "지도에서 내 주변 따릉이 대여소를 보여드리기 위해 위치 정보를 사용합니다.",
)
if os.environ.get("CLEARTEXT") == "1":
    plist["NSAppTransportSecurity"] = {"NSAllowsLocalNetworking": True}

with open(path, "wb") as f:
    plistlib.dump(plist, f)
print("patched", path)
PY
fi
