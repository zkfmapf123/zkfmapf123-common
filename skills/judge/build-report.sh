#!/bin/bash
# Usage: build-report.sh <judge-*.md> [out.html]
# Drops the markdown into report-template.html; the page renders it client-side.
set -euo pipefail
md="$1"; out="${2:-${md%.md}.html}"
tpl="$(dirname "$0")/report-template.html"
MD="$md" TPL="$tpl" python3 - > "$out" <<'PY'
import os,re
md=open(os.environ['MD'],encoding='utf-8').read()
title=next((l[2:].strip() for l in md.splitlines() if l.startswith('# ')),'judge')[:80]
md=md.replace('</script','<\\/script')
tpl=open(os.environ['TPL'],encoding='utf-8').read()
print(tpl.replace('{{TITLE}}',title).replace('{{MARKDOWN}}',md),end='')
PY
echo "$out"
