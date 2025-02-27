#!/bin/bash

python3 -m sglang.launch_server \
  --model-path TinyLlama/TinyLlama-1.1B-Chat-v1.0 \
  --device cuda \
  --dtype half \
  --attention-backend flashinfer \
  --mem-fraction-static 0.8
