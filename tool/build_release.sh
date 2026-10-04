#!/usr/bin/env bash
# Builds a release after the preflight confirms the config is real mode.
#   tool/build_release.sh <apk|appbundle|ipa> config/release.json [extra flutter args]
set -euo pipefail
target="${1:?target (apk, appbundle, ipa)}"
defines="${2:?define file (JSON)}"
shift 2
dart run tool/check_release_config.dart "$defines"
flutter build "$target" --release --dart-define-from-file="$defines" "$@"
