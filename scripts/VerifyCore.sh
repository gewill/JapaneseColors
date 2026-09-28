#!/bin/bash
# Offline model/resource regressions; no app build, signing or simulator required.
set -euo pipefail

repository_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
verification_dir="$(mktemp -d "${TMPDIR:-/tmp}/jcolors-verify.XXXXXX")"
trap 'rm -rf "$verification_dir"' EXIT
cd "$repository_dir"

python3 scripts/ValidateResources.py
xcrun swiftc -swift-version 6 -strict-concurrency=complete \
  JColors/Models/ColorModel.swift JColors/Models/ColorCatalog.swift \
  JColors/Models/ModelTool.swift JColors/Models/FavoritesStore.swift \
  JColors/Models/AppRoute.swift JColors/Models/AutoChangeCoordinator.swift scripts/VerifyModels.swift \
  -o "$verification_dir/verify-models"
"$verification_dir/verify-models" "$repository_dir"

xcrun swiftc -parse-as-library -swift-version 6 -strict-concurrency=complete \
  JColors/Models/ColorModel.swift JColors/Models/ColorCatalog.swift \
  JColors/Shared/WidgetAccess.swift JColorsWidgets/DailyColorSchedule.swift \
  scripts/VerifyWidgets.swift -o "$verification_dir/verify-widgets"
"$verification_dir/verify-widgets" "$repository_dir/scripts/byMonth"

xcrun swiftc -parse-as-library -swift-version 6 -strict-concurrency=complete \
  JColors/Models/ColorModel.swift JColors/Models/ColorCatalog.swift \
  JColors/Extensions/ColorExtensions.swift scripts/VerifyContrast.swift \
  -o "$verification_dir/verify-contrast"
"$verification_dir/verify-contrast" "$repository_dir/scripts/byMonth"
