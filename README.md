# vLLM Server

Generic [vLLM](https://github.com/vllm-project/vllm) + [vLLM-Omni](https://github.com/vllm-project/vllm-omni) Docker image for serving any LLM or TTS model.

One image, any model — just set environment variables at runtime.

## Requirements

- NVIDIA GPU with 8GB+ VRAM
- CUDA driver 12.9+
- Docker with [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)

## Build

```bash
docker build -t naturelbenton/vllm-server:latest .
```

## Quick start

### TTS (Qwen3-TTS)

```bash
docker run --gpus all -p 8000:8000 \
  -e MODEL=Qwen/Qwen3-TTS-12Hz-0.6B-Base \
  -e OMNI=true \
  -v vllm-cache:/root/.cache/huggingface \
  --entrypoint /entrypoint.sh \
  naturelbenton/vllm-server:latest
```

### LLM (Qwen3-32B)

```bash
docker run --gpus all -p 8000:8000 \
  -e MODEL=Qwen/Qwen3-32B-Instruct \
  -e OMNI=false \
  -e MAX_MODEL_LEN=4096 \
  -v vllm-cache:/root/.cache/huggingface \
  --entrypoint /entrypoint.sh \
  naturelbenton/vllm-server:latest
```

## Docker Compose integration

```yaml
services:
  # TTS service (multimodal — uses vLLM-Omni)
  vllm-tts:
    image: naturelbenton/vllm-server:latest
    entrypoint: /entrypoint.sh
    ports:
      - "8091:8000"
    environment:
      - MODEL=Qwen/Qwen3-TTS-12Hz-0.6B-Base
      - OMNI=true
    volumes:
      - vllm-cache:/root/.cache/huggingface
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]

  # LLM service (standard vLLM)
  vllm-llm:
    image: naturelbenton/vllm-server:latest
    entrypoint: /entrypoint.sh
    ports:
      - "8092:8000"
    environment:
      - MODEL=Qwen/Qwen3-32B-Instruct
      - OMNI=false
      - MAX_MODEL_LEN=4096
    volumes:
      - vllm-cache:/root/.cache/huggingface
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]

volumes:
  vllm-cache:
```

Models are downloaded from HuggingFace at first startup. Set `HF_TOKEN` for gated models. The `vllm-cache` volume persists downloads between restarts.

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `MODEL` | `Qwen/Qwen3-TTS-12Hz-0.6B-Base` | HuggingFace model ID |
| `PORT` | `8000` | Server port |
| `MAX_MODEL_LEN` | (auto) | Max context/sequence length (omit for TTS models) |
| `QUANTIZATION` | (none) | Quantization: `bitsandbytes`, `fp8`, `awq`, `gptq` |
| `OMNI` | `true` | Enable vLLM-Omni for multimodal models (TTS, audio) |
| `DTYPE` | `bfloat16` | Model dtype: `bfloat16`, `float16`, `auto` |
| `GPU_MEMORY` | `0.9` | Fraction of GPU memory to use (0.0-1.0) |
| `TENSOR_PARALLEL` | (none) | Tensor parallel size (for multi-GPU setups) |
| `HF_TOKEN` | (none) | HuggingFace token for gated models |
| `VLLM_ALLOW_LONG_MAX_MODEL_LEN` | (none) | Set to `1` for TTS models that need large internal sequence lengths |
| `EXTRA` | (none) | Any additional vLLM CLI args (e.g. `--enforce-eager --enable-prefix-caching`) |

## Supported models

Any model supported by vLLM or vLLM-Omni. See:
- [vLLM-Omni supported models](https://docs.vllm.ai/projects/vllm-omni/en/latest/models/supported_models/) (TTS, audio, multimodal)
- [vLLM supported models](https://docs.vllm.ai/en/latest/models/supported_models.html) (LLMs)

### Tested TTS models

| Model | Size | VRAM | `OMNI` | Notes |
|-------|------|------|--------|-------|
| `Qwen/Qwen3-TTS-12Hz-0.6B-Base` | 0.6B | ~2 GB | `true` | Voice cloning, requires `VLLM_ALLOW_LONG_MAX_MODEL_LEN=1` |
| `Qwen/Qwen3-TTS-12Hz-1.7B-Base` | 1.7B | ~4 GB | `true` | Voice cloning, requires `VLLM_ALLOW_LONG_MAX_MODEL_LEN=1` |
| `mistralai/Voxtral-4B-TTS-2603` | 4B | ~8 GB | `true` | Voice cloning, 9 languages, 20 preset voices |

### Tested LLM models

| Model | Size | VRAM | `OMNI` | Notes |
|-------|------|------|--------|-------|
| `Qwen/Qwen3-32B-Instruct` | 32B | ~16 GB (Q4) | `false` | Needs `MAX_MODEL_LEN` + quantization for 16GB GPUs |

## API

### TTS mode (`OMNI=true`)

OpenAI-compatible audio endpoints:

- `POST /v1/audio/speech` — synthesize text to audio
- `GET /v1/audio/voices` — list available voices
- `GET /health` — liveness check

### LLM mode (`OMNI=false`)

OpenAI-compatible chat endpoints:

- `POST /v1/chat/completions` — chat completion
- `POST /v1/completions` — text completion
- `GET /v1/models` — list loaded models
- `GET /health` — liveness check

## References

- [vLLM](https://github.com/vllm-project/vllm) — high-throughput LLM inference
- [vLLM-Omni](https://github.com/vllm-project/vllm-omni) — multimodal extension (TTS, audio, vision)
- [Qwen3-TTS](https://huggingface.co/Qwen/Qwen3-TTS-12Hz-0.6B-Base) — text-to-speech model
