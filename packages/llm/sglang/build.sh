#!/usr/bin/env bash
set -ex

# Set versions for FlashInfer and SGLang
FLASHINFER_VERSION="v0.2.0"
SGLANG_VERSION="v0.4.1.post7"

# Install required system libraries
apt-get update && \
    apt-get install -y libavformat58 libavfilter7 && \
    rm -rf /var/lib/apt/lists/*


# Build FlashInfer
echo "Building FlashInfer ${FLASHINFER_VERSION}"
rm -rf /workspace/flashinfer
git clone --recurse-submodules -b ${FLASHINFER_VERSION} https://github.com/flashinfer-ai/flashinfer.git /workspace/flashinfer
cd /workspace/flashinfer

export MAX_JOBS=$(nproc)
export TORCH_CUDA_ARCH_LIST="8.7"
export FLASHINFER_ENABLE_AOT=1

pip install -e . --no-build-isolation -v

# Build SGLang
echo "Building SGLang ${SGLANG_VERSION}"
rm -rf /workspace/sglang
git clone --recurse-submodules -b ${SGLANG_VERSION} https://github.com/sgl-project/sglang.git /workspace/sglang
cd /workspace/sglang

# Remove dependencies
sed -i '/sgl-kernel/d' python/pyproject.toml
sed -i '/flashinfer/d' python/pyproject.toml
sed -i '/xgrammar/d' python/pyproject.toml

# Build SGL Kernel
cd sgl-kernel
export SGL_KERNEL_ENABLE_BF16=1
pip install -e . --no-build-isolation -v
cd ..

# Patch SGLang utils.py
if test -f "python/sglang/srt/utils.py"; then
    sed -i '/return min(memory_values)/s/.*/        return None/' python/sglang/srt/utils.py
    sed -i '/if not memory_values:/,+1d' python/sglang/srt/utils.py
fi

# Install SGLang
pip3 install --no-cache-dir -e "python[all]"

# Install Gemlite python packages
pip3 install gemlite

# Validate installations
pip3 show sglang
python3 -c 'import sglang'

# Final message
echo "Build completed successfully."
