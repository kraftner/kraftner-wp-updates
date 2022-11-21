#!/bin/bash

set -euo pipefail

# Setup colors
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

function solum_color() {
  printf "%b%s${NC}\n" "${1:-}" "${2:-}"
}

function solum_banner() {
  solum_color "${1:-}" "----------------------------------------------------------------------"
  FIRST=1
  for LINE in "${@:-}"
  do
      if [[ "$FIRST" != 1 ]]; then
        solum_color "${1:-}" " $LINE"
      fi
      FIRST=0
  done
  solum_color "${1:-}" "----------------------------------------------------------------------"
}

function solum_info() {
  solum_color $NC "${1:-}"
}

function solum_info_banner() {
  solum_banner $NC "${@:-}"
}

function solum_success() {
  solum_color $GREEN "${1:-}"
}

function solum_success_banner() {
  solum_banner $GREEN "${@:-}"
}

function solum_warn() {
  solum_color $ORANGE "${1:-}"
}

function solum_warn_banner() {
  solum_banner $ORANGE "${@:-}"
}

function solum_error() {
  solum_color $RED "${1:-}"
}

function solum_error_banner() {
  solum_banner $RED "${@:-}"
}

export RED GREEN ORANGE NC
export -f solum_color solum_banner
export -f solum_info solum_success solum_warn solum_error
export -f solum_info_banner solum_success_banner solum_warn_banner solum_error_banner