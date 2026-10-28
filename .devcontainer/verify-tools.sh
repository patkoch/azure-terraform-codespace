#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -un)" != "vscode" ]]; then
    echo "Run this check as the dev container's vscode user." >&2
    exit 1
fi

az version
terraform version
tflint --version
git --version

work_dir="$(mktemp -d)"
trap 'rm -rf -- "$work_dir"' EXIT
cd "$work_dir"

# Use Terraform's built-in provider: no Azure credentials or downloads needed.
cat > main.tf <<'EOF'
terraform {
  required_version = ">= 1.4.0"
}

resource "terraform_data" "smoke_test" {
  input = "devcontainer verification"
}
EOF

terraform fmt -check
terraform init -backend=false -input=false -no-color
terraform validate -no-color
terraform plan -input=false -lock=false -no-color
tflint --format compact
AZURE_CORE_COLLECT_TELEMETRY=false az group create --help > /dev/null

echo "Terraform, TFLint, and Azure CLI checks passed as $(id -un)."
