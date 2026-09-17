#!/usr/bin/env bash
set -euo pipefail

usage() {
    printf '%s\n' 'Usage: mdpdf INPUT.md [OUTPUT.pdf]'
    printf '%s\n' 'Render Markdown, including LaTex math, to PDF with Pandoc and Typst.'
}

if [ "$#" -eq 1 ] && { [ "$1" = '-h' ] || [ "$1" = '--help' ]; }; then
    usage
    exit 0
fi

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    usage >&2
    exit 2
fi

input="$1"
if [ ! -f "$input" ]; then
    printf 'Input file does not exist: %s\n' "$input" >&2
    exit 1
fi

output="${2:-${input%.*}.pdf}"
if ! command -v pandoc >/dev/null 2>&1; then
    printf '%s\n' 'pandoc is required. Run dotbins sync --current pandoc typst.' >&2
    exit 1
fi
if ! command -v typst >/dev/null 2>&1; then
    printf '%s\n' 'typst is required. Run dotbins sync --current pandoc typst.' >&2
    exit 1
fi

pandoc "$input" --pdf-engine=typst --output="$output"
printf 'Wrote %s\n' "$output"
