#!/usr/bin/env bash
set -euo pipefail

workspace="${GITHUB_WORKSPACE:-$(pwd)}"
electronics_dir="$workspace/Electronics"
config="$electronics_dir/kibot_yaml/kibot_main.yaml"
changelog="$electronics_dir/CHANGELOG.md"
sheet_wks="$electronics_dir/Templates/KDT_Template_PCB_GIT_A4.kicad_wks"
git_url=""

if [[ -n "${GITHUB_REPOSITORY:-}" ]]; then
  git_url="https://github.com/${GITHUB_REPOSITORY}"
fi

if [[ ! -f "$config" ]]; then
  echo "KiBot config not found at $config"
  exit 1
fi

if [[ ! -f "$sheet_wks" ]]; then
  echo "Sheet template not found at $sheet_wks"
  exit 1
fi

variant="${KIBOT_VARIANT:-CHECKED}"
revision=""

if [[ "${KIBOT_IS_RELEASE:-false}" == "true" && -n "${GITHUB_REF_NAME:-}" ]]; then
  revision="${GITHUB_REF_NAME}"
elif [[ -f "$changelog" ]]; then
  revision="$(python3 "$electronics_dir/kibot_resources/scripts/get_changelog_version.py" -f "$changelog" || true)"
  if [[ "$revision" == File* || "$revision" == "An error occurred:"* ]]; then
    revision=""
  fi
fi

if kicad-cli --version | grep -q '^9\.'; then
  all_group="all_group_k9"
else
  all_group="all_group"
fi

cd "$electronics_dir"

mapfile -t projects < <(find Circuits -name '*.kicad_pro' -print | sort)
if [[ ${#projects[@]} -eq 0 ]]; then
  echo "No KiCad projects found under Electronics/Circuits"
  exit 1
fi

for proj in "${projects[@]}"; do
  proj_dir="$(dirname "$proj")"
  base="$(basename "$proj" .kicad_pro)"
  sch="$proj_dir/$base.kicad_sch"
  pcb="$proj_dir/$base.kicad_pcb"

  if [[ ! -f "$sch" ]]; then
    echo "Skipping $proj (missing $sch)"
    continue
  fi

  has_pcb=true
  if [[ ! -f "$pcb" ]] || ! grep -q "(layers" "$pcb"; then
    has_pcb=false
  fi

  case "$variant" in
    DRAFT|PRELIMINARY|CHECKED|RELEASED)
      out_dir="$proj_dir"
      ;;
    *)
      out_dir="$proj_dir/Variants"
      ;;
  esac

  common_args=(
    -c "$config"
    -e "$sch"
    -d "$out_dir"
    -g "variant=$variant"
    -E "PROJECT_NAME=$base"
    -E "BOARD_NAME=$base"
    -E "SHEET_WKS=$sheet_wks"
  )

  if [[ "$has_pcb" == true ]]; then
    common_args+=(-b "$pcb")
  fi

  if [[ -n "$revision" ]]; then
    common_args+=(-E "REVISION=$revision")
  fi

  if [[ -n "$git_url" ]]; then
    common_args+=(-E "GIT_URL=$git_url")
  fi

  echo "Running KiBot for $proj (variant=$variant)"
  if [[ "$has_pcb" == false ]]; then
    echo "PCB missing or invalid for $base; running schematic-only outputs."
    kibot --skip-pre set_text_variables,draw_fancy_stackup,erc,drc "${common_args[@]}" pdf_schematic csv_bom
    continue
  fi
  case "$variant" in
    DRAFT)
      kibot --skip-pre set_text_variables,draw_fancy_stackup,erc,drc "${common_args[@]}" md_readme
      kibot --skip-pre draw_fancy_stackup,erc,drc "${common_args[@]}" draft_group
      ;;
    PRELIMINARY)
      kibot --skip-pre erc,drc "${common_args[@]}" notes
      kibot --skip-pre erc,drc "${common_args[@]}" "$all_group"
      ;;
    CHECKED|RELEASED|*)
      kibot --skip-pre set_text_variables,draw_fancy_stackup,erc,drc "${common_args[@]}" notes
      kibot "${common_args[@]}" "$all_group"
      ;;
  esac
done
