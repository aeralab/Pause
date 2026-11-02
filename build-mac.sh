#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
command -v xcodebuild >/dev/null || { echo '需要已安装完整 Xcode 的 Mac。' >&2; exit 1; }
xcodebuild -version
sdk=$(xcrun --sdk iphoneos --show-sdk-version)
python3 -c 'import sys; v=tuple(map(int,sys.argv[1].split("."))); sys.exit(0 if v >= (26,5) else "需要 iOS 26.5+ SDK；旧 Xcode 14.2 无法编译本项目。")' "$sdk"
command -v xcodegen >/dev/null || { echo '请先安装 XcodeGen。' >&2; exit 1; }
mode=${1:-open}
if [ "$mode" != 'open' ] && [ "$mode" != 'check' ] && [ "$mode" != 'archive' ]; then
  echo '用法：bash build-mac.sh [open|check|archive]' >&2; exit 1
fi
if [ "$mode" = 'archive' ] && { [ -z "${TEAM_ID:-}" ] || [ -z "${BUNDLE_PREFIX:-}" ]; }; then
  echo '归档需要 TEAM_ID 与唯一 BUNDLE_PREFIX。不要在此输入账号密码。' >&2; exit 1
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
    raise SystemExit('BUNDLE_PREFIX 格式无效')
for name in ['project.yml','Stop.entitlements','Shared/Repository.swift','Shared/ScreenTime.swift']:
    p=stage/name
    p.write_text(p.read_text().replace('com.onepersoncompany',prefix))
PYSETUP
(cd "$stage" && xcodegen generate)
printf '\n独立工程位置：%s/Stop.xcodeproj\n' "$stage"
if [ "$mode" = 'open' ]; then
  open "$stage/Stop.xcodeproj"
  echo '请为全部四个 target 配置签名和权限，再用真实 iPhone 验证。'
elif [ "$mode" = 'check' ]; then
  xcodebuild -project "$stage/Stop.xcodeproj" -scheme Stop -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
else
  xcodebuild -project "$stage/Stop.xcodeproj" -scheme Stop -destination 'generic/platform=iOS' -configuration Release -archivePath "$stage/Stop.xcarchive" DEVELOPMENT_TEAM="$TEAM_ID" CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates archive
  printf '\n归档位置：%s/Stop.xcarchive\n' "$stage"
  echo '未执行测试或上传；请完成真机验证，再从 Organizer 验证和分发。'
fi
