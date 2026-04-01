#!/bin/bash
set -e

MODEL_ID="${MODEL:-Qwen/Qwen3-TTS-12Hz-0.6B-Base}"
PORT="${PORT:-8000}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-}"
QUANTIZATION="${QUANTIZATION:-}"
OMNI="${OMNI:-true}"
DTYPE="${DTYPE:-bfloat16}"
GPU_MEMORY="${GPU_MEMORY:-0.9}"
TENSOR_PARALLEL="${TENSOR_PARALLEL:-}"
EXTRA="${EXTRA:-}"

echo "=== vLLM Server ==="
echo "Model: $MODEL_ID"
echo "Port: $PORT"
echo "Omni: $OMNI"
echo "Dtype: $DTYPE"
echo "GPU memory: $GPU_MEMORY"
[ -n "$MAX_MODEL_LEN" ] && echo "Max model len: $MAX_MODEL_LEN"
[ -n "$QUANTIZATION" ] && echo "Quantization: $QUANTIZATION"
[ -n "$TENSOR_PARALLEL" ] && echo "Tensor parallel: $TENSOR_PARALLEL"
[ -n "$EXTRA" ] && echo "Extra args: $EXTRA"

EXTRA_ARGS=()
if [ -n "$MAX_MODEL_LEN" ]; then
    EXTRA_ARGS+=(--max-model-len "$MAX_MODEL_LEN")
fi
if [ -n "$QUANTIZATION" ]; then
    EXTRA_ARGS+=(--quantization "$QUANTIZATION")
fi
if [ "$OMNI" = "true" ]; then
    EXTRA_ARGS+=(--omni)
fi
if [ -n "$TENSOR_PARALLEL" ]; then
    EXTRA_ARGS+=(--tensor-parallel-size "$TENSOR_PARALLEL")
fi

# shellcheck disable=SC2086
exec vllm serve "$MODEL_ID" \
    --port "$PORT" \
    --dtype "$DTYPE" \
    --gpu-memory-utilization "$GPU_MEMORY" \
    --trust-remote-code \
    "${EXTRA_ARGS[@]}" \
    $EXTRA
