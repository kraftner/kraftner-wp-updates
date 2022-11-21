#!/bin/bash

set -euo pipefail

function solum_help_command(){
  solum_success "$(printf " %-15s%s\n" "$1" "$2")"
}

function solum_help_dev_command(){
  solum_warn "$(printf " %-15s%s\n" "$1" "$2")"
}

solum_info "Usage: cli [command] [options]"

solum_info

solum_success "Commands:"
solum_help_command "init" "Initialize a new plugin."
solum_help_command "start" "Start the development environment."
solum_help_command "stop" "Stop the development environment without destroying it."
solum_help_command "clean" "Destroy the development environment."
if [ "${1:-}" = "--dev" ];
then
  solum_help_dev_command "clean --all" "Destroy the development environment and delete all generated project files."
fi

solum_help_command "rebuild" "Run »clean« and »start« together."
if [ "${1:-}" = "--dev" ];
then
  solum_help_dev_command "reset" "Run »clean --all«, »init« and »start« together."
fi

solum_help_command "wp" "Run a WP-CLI command."
solum_help_command "composer" "Run a composer command."
solum_help_command "npm" "Run a npm command."
solum_help_command "help" "Display this help message."
solum_help_dev_command "help --dev" "Display this help message including commands exclusively for development of Solum itself."
