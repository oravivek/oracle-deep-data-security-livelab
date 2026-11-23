#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
lab_runtime="$PWD/.local/ollama/ollama"
if [[ ! -x "$lab_runtime" ]]; then
  echo 'The local Ollama runtime is missing. Install Ollama from https://ollama.com/download/mac.' >&2
  exit 1
fi
export OLLAMA_HOST=127.0.0.1:11434
export OLLAMA_MODELS="$PWD/.local/ollama-models"
export OLLAMA_NO_CLOUD=1
export OLLAMA_NUM_PARALLEL=1
export OLLAMA_MAX_LOADED_MODELS=1
export OLLAMA_CONTEXT_LENGTH=4096
exec "$lab_runtime" serve
