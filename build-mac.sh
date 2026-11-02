#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
command -v xcodebuild >/dev/null || { echo '��Ҫ�Ѱ�װ���� Xcode �� Mac��' >&2; exit 1; }
xcodebuild -version
sdk=$(xcrun --sdk iphoneos --show-sdk-version)
python3 -c 'import sys; v=tuple(map(int,sys.argv[1].split("."))); sys.exit(0 if v >= (26,5) else "��Ҫ iOS 26.5+ SDK���� Xcode 14.2 �޷����뱾��Ŀ��")' "$sdk"
command -v xcodegen >/dev/null || { echo '���Ȱ�װ XcodeGen��' >&2; exit 1; }
mode=${1:-open}
if [ "$mode" != 'open' ] && [ "$mode" != 'check' ] && [ "$mode" != 'archive' ]; then
  echo '�÷���bash build-mac.sh [open|check|archive]' >&2; exit 1
fi
if [ "$mode" = 'archive' ] && { [ -z "${TEAM_ID:-}" ] || [ -z "${BUNDLE_PREFIX:-}" ]; }; then
  echo '�鵵��Ҫ TEAM_ID ��Ψһ BUNDLE_PREFIX����Ҫ�ڴ������˺����롣' >&2; exit 1
fi
export BUNDLE_PREFIX=${BUNDLE_PREFIX:-com.onepersoncompany}
stage=$(mktemp -d "${TMPDIR:-/tmp}/stop-build.XXXXXX")
cp -R App Monitor Shared Tests Shield ShieldAction "$stage/"
cp project.yml Stop.entitlements "$stage/"
export STOP_STAGE="$stage"
python3 - <<'PYSETUP'
import os,re
from pathlib import Path
stage=Path(os.environ['STOP_STAGE'])
prefix=os.environ['BUNDLE_PREFIX']
if not re.fullmatch(r'[A-Za-z][A-Za-z0-9-]*(?:\.[A-Za-z][A-Za-z0-9-]*)+',prefix):
    raise SystemExit('BUNDLE_PREFIX ��ʽ��Ч')
for name in ['project.yml','Stop.entitlements','Shared/Repository.swift','Shared/ScreenTime.swift']:
    p=stage/name
    p.write_text(p.read_text().replace('com.onepersoncompany',prefix))
PYSETUP
(cd "$stage" && xcodegen generate)
printf '\n��������λ�ã�%s/Stop.xcodeproj\n' "$stage"
if [ "$mode" = 'open' ]; then
  open "$stage/Stop.xcodeproj"
  echo '��Ϊȫ���ĸ� target ����ǩ����Ȩ�ޣ�������ʵ iPhone ��֤��'
elif [ "$mode" = 'check' ]; then
  xcodebuild -project "$stage/Stop.xcodeproj" -scheme Stop -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
else
  xcodebuild -project "$stage/Stop.xcodeproj" -scheme Stop -destination 'generic/platform=iOS' -configuration Release -archivePath "$stage/Stop.xcarchive" DEVELOPMENT_TEAM="$TEAM_ID" CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates archive
  printf '\n�鵵λ�ã�%s/Stop.xcarchive\n' "$stage"
  echo 'δִ�в��Ի��ϴ�������������֤���ٴ� Organizer ��֤�ͷַ���'
fi
