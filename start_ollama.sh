#!/usr/bin/env bash
# Start a local-only model service; do not start a second service on port 11434.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
if [[ -x "$PWD/.local/ollama/ollama" ]]; then
  lab_runtime="$PWD/.local/ollama/ollama"
  export OLLAMA_MODELS="$PWD/.local/ollama-models"
elif command -v ollama >/dev/null 2>&1; then
  lab_runtime="$(command -v ollama)"
else
  echo 'Install Ollama from https://ollama.com/download first.' >&2
  exit 1
fi
export OLLAMA_HOST=127.0.0.1:11434
export OLLAMA_NO_CLOUD=1
export OLLAMA_NUM_PARALLEL=1
export OLLAMA_MAX_LOADED_MODELS=1
export OLLAMA_CONTEXT_LENGTH=4096
exec "$lab_runtime" serve
