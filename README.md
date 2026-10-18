# cenote

**DeepSeek-V4.1-Flash on one RTX 3090, natively on Windows. No WSL.**

cenote is a Windows port of the DeepSeek-V4.1 engine in [Xolotl](https://github.com/Indras-Mirror/Xolotl) by
Indras Mirror. Xolotl runs DeepSeek-V4.1-Flash on one 24 GB GPU by keeping the hottest experts in VRAM, the next tier
in a pinned RAM arena and the rest on NVMe, and serves it through an OpenAI / Anthropic-compatible API with tool
calls. Upstream it runs on Linux; cenote builds and serves it with MSVC + CUDA on Windows 11.

> **Credit where it belongs.** The engine, the server, the GSQ quant format and the DeepSeek-V4.1 work are
> [Xolotl](https://github.com/Indras-Mirror/Xolotl)'s (Indras Mirror), built on [Strata](https://github.com/Niko1221/Strata)
> (Niko1221) and [ggml / llama.cpp](https://github.com/ggml-org/llama.cpp). The model is DeepSeek's; the quants are
> IndrasMirror's. **cenote adds only the Windows port, a Windows-only crash fix and settings measured on a 3090.** MIT,
> with every upstream notice kept. The upstream README follows below, unchanged.
>
> Maintained by **vrami** ([@vrami_dev](https://x.com/vrami_dev)), a mascot account run by a real person. The rig and
> the code are real.

### What cenote changes

- **`tools/v41/engine/ds41_sys.hpp`:** a small portability layer.
  - Files: positional reads through `CreateFileW` with overlapped I/O, `FILE_FLAG_NO_BUFFERING` for O_DIRECT, 64-bit offsets.
  - Memory: `_aligned_malloc` / `_aligned_free` pairs; `GlobalMemoryStatusEx` for free RAM.
  - The Linux paths are unchanged.
- **MSVC builds:** MSVC forms of the CPU kernels' GCC attributes, an 8 MiB stack reserve for `ds41_generate`, `--engram` folders separated by `;`. The Engram raw-device trick stays Linux-only.
- **A Windows-only crash, fixed.** Every prompt over 96 tokens corrupted the heap (0xC0000374).
  - MSVC's linker takes llama.cpp's `mul_mat_q_case<T>` from `ggml-cuda.lib`, which is built with CUDA graphs and so has a larger `ggml_backend_cuda_context`, while `strata_mmq` allocated the smaller struct.
  - GNU ld keeps `strata_mmq`'s own copy, so Linux never hit it.
  - Fix: `GGML_CUDA_USE_GRAPHS` for `strata_mmq` (CMakeLists.txt).
- **Windows tooling:**
  - `build-win.bat` (6 parallel jobs by default)
  - serve configs `tools/v41/serve/strata-ds41-win.json` and `strata-ds41-1017-win.json`
  - a resumable, sha256-checked Hugging Face downloader `tools/xolotl/win_fetch_files.py`
  - setup steps: [docs/cenote/WINDOWS.md](docs/cenote/WINDOWS.md)

### Numbers

RTX 3090 24 GB (PCIe 4.0 x16), Ryzen 7 5800X, 128 GB DDR4-3200, Windows 11. Model:
[IndrasMirror/DeepSeek-V4.1-Flash-GSQ-Uncensored](https://huggingface.co/IndrasMirror/DeepSeek-V4.1-Flash-GSQ-Uncensored)
(September build). Served decode, greedy, 400 tokens, median of 3:

| Config | Prose | Code | Agent JSON | Average |
| --- | ---: | ---: | ---: | ---: |
| Xolotl's served config (64 GiB arena) | 13.0 tok/s | 17.4 tok/s | 15.7 tok/s | 15.4 |
| cenote (72 GiB arena, `STRATA_TIER_BATCH_PCIE=0.75`) | 14.7 tok/s | 22.1 tok/s | 18.8 tok/s | 18.5 |

A fresh 13,294-token prompt read in 63.45 s (209.5 tok/s). The method, every variant tried and the raw results are in
[docs/cenote/BENCHMARKS.md](docs/cenote/BENCHMARKS.md). DeepSeek-V4.1-Flash-1017 numbers are coming.

---

<p align="center"><img src="docs/brand/assets/readme-header-1200.png" alt="Xolotl - frontier MoE models on one gaming PC" width="100%"></p>

<h1 align="center">Xolotl</h1>

<p align="center"><b>DeepSeek-V4.1-Flash - all 552 billion parameters - on one gaming PC, at 27 tok/s.</b><br>
Plus GLM-5.3-Flash, Qwen3.8-Flash-Next and Qwen3.8-27B: one engine, one OpenAI / Anthropic-compatible server.<br>
Built on <a href="https://github.com/Niko1221/Strata">Strata</a> and heavily extended · Linux · NVIDIA · MIT</p>

> **A Strata fork.** Xolotl keeps [Strata](https://github.com/Niko1221/Strata)'s engine, server and kernels at its
> core (merged at 0.1.44.1) and adds ~71,000 lines on top: the DeepSeek-V4.1 and V4-Flash engines, the GLM-5.3-Flash
> engine and the Qwen3.8-27B dense port, each with its own quantisation and expert-tiering work.
>
> **Starred this as Strata-DSV4.1?** You are in the right place. Strata-DSV4.1 grew into **Xolotl**: the same
> DeepSeek-V4.1 engine (faster now), plus GLM-5.3-Flash and the Qwen3.8 models, in one tree. Old links and clones
> redirect here; nothing DeepSeek-V4.1 was removed.

## What one PC can do

**One RTX 4090 (24 GB) · Ryzen 7 5700X · 90 GB DDR4 · one NVMe drive.** Every number is measured on that machine,
through the real server, while it solved real tasks (21 HumanEval problems, 10 tool-call tasks, 3 agentic bug-fix
loops), greedy, thinking on with a 32K-token thinking budget.

| Model | Size | Prefill | Decode | HumanEval | Tool calls | Agentic | Context |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| **[DeepSeek-V4.1-Flash](https://huggingface.co/IndrasMirror/DeepSeek-V4.1-Flash-GSQ-Uncensored)** | 552B MoE | **180-320 tok/s** | **26.8 tok/s** | 21/21 | 10/10 | 3/3 | 512K |
| **GLM-5.3-Flash** | 320B MoE | **290-375 tok/s** | **25.3 tok/s** | 19/21 | 10/10 | 3/3 | 512K |
| **Qwen3.8-Flash-Next** | 125B MoE | **3,000-3,430 tok/s** | **127.8 tok/s** | 21/21 | 10/10 | 3/3 | 200K |
| **Qwen3.8-27B** (dense) | 27B | **1,240-1,390 tok/s** | **98.5 tok/s** | 21/21 | 10/10 | 3/3 | 200K |

<sub>Decode = generation speed during those tasks. Prefill = a fresh 6K-17K-token prompt through the server
(`tools/throughput.py`; Qwen3.8-Flash-Next: 3,430 / 3,005 tok/s at 6.5K / 16.7K, Qwen3.8-27B: 1,385 / 1,244 tok/s,
DeepSeek-V4.1: 178 / 268 tok/s at 6.1K / 16.5K - its prompt batch is sized from free VRAM, ~6-9K tokens per sweep
on a 24 GB card with the speculative-decode draft loaded).
DeepSeek-V4.1 with the speculative-decode draft off the card during long prompts (the default since 2026-10-17):
187 / 317 tok/s at 6.4K / 16.7K. GLM-5.3-Flash: soft prune + `--route-bias 0.25`
(`tools/glm/serve/strata-glm-maya-abl-512k-bias.json`), prefill 301 / 374 tok/s at 6.1K / 15.6K and 368-376 on fresh
30K / 44K prompts. How close the DeepSeek quant gets to DeepSeek's own API on the same tasks:
[docs/xolotl/BENCHMARKS.md](docs/xolotl/BENCHMARKS.md#deepseek-v41-quant-vs-the-deepseek-api).</sub>

**What that means in practice:**

- **A 552B frontier model as a local coding agent.** Point Claude Code, Codex, opencode or Open WebUI at it - tool
  calls, streaming, prefix reuse across agent turns, a thinking budget.
- **No server farm.** The weights (152 GiB for DeepSeek-V4.1) live across VRAM, pinned RAM and NVMe; the engine
  carries up the experts each token needs.
- **Fast where it counts.** The Qwen models run at 100-130 tok/s; an agent's small follow-up turn on DeepSeek-V4.1
  costs ~8 s on a 6K-16K context, and the engine learns the conversation's experts between turns.

## Quick start

Linux, an NVIDIA GPU with 24 GB, CUDA 12.x/13.x, and RAM for the arena (90 GB was used above).

```bash
git clone https://github.com/Indras-Mirror/Xolotl.git xolotl && cd xolotl
bash tools/xolotl/fetch-llama.sh   # llama.cpp at the pinned commit + tools/xolotl/ggml/xolotl-ggml.patch -> third_party/llama.cpp
cmake -S . -B build-xolotl -G Ninja -DCMAKE_BUILD_TYPE=Release -DSTRATA_ENABLE_CUDA=ON -DSTRATA_GGML_CUDA=ON \
  -DSTRATA_MMQ_KQUANTS=ON -DCMAKE_CUDA_ARCHITECTURES=89 -DSTRATA_GGML_DIR=$PWD/third_party/llama.cpp -DSTRATA_DSV41_FQ_OP=ON \
  -DSTRATA_DSV41_HC_MIX=ON
ninja -C build-xolotl      # strata, strata-dense, glm_generate, ds41_generate, ds4_generate
```

Get a model: DeepSeek-V4.1-Flash is **[IndrasMirror/DeepSeek-V4.1-Flash-GSQ-Uncensored](https://huggingface.co/IndrasMirror/DeepSeek-V4.1-Flash-GSQ-Uncensored)**
(152 GiB, our GSQ mixed ternary / 2-bit / 3-bit quant - the card has the download and Engram steps). Then serve it
(edit the model paths in its config first):

```bash
python3 tools/v41/serve/serve_ds41.py --engine strata --config tools/v41/serve/strata-ds41.json --port 8150           # DeepSeek-V4.1-Flash
python3 tools/glm/serve/serve_glm.py  --engine strata --config tools/glm/serve/strata-glm-maya-abl-512k.json --port 8144  # GLM-5.3-Flash
python3 -m serve.server --engine strata --config <your-qwen-flash.json> --port 8130                                    # Qwen3.8-Flash-Next
python3 -m serve.server --engine strata --config <your-27b.json> --port 8090                                          # Qwen3.8-27B (exe: build-xolotl/strata-dense)
```

Then point any OpenAI- or Anthropic-compatible client at `http://127.0.0.1:<port>/v1`.

### Will it run on my machine? (DeepSeek-V4.1)

What I've measured is one setup: **RTX 4090 (24 GB), 90 GB DDR4, Linux, NVMe**. Beyond that:

- **OS:** Linux only for the DeepSeek engine for now (the launcher and the expert/Engram disk reads are Linux-specific).
  The Strata core runs on Windows, but the DeepSeek side doesn't yet. WSL2 might work but is untested; keep the model
  files inside WSL's own filesystem, not on a Windows drive.
- **GPU:** NVIDIA, compute capability 7.5 or newer (RTX 20/30/40/50). Build with your card's architecture:
  `-DCMAKE_CUDA_ARCHITECTURES=86` for RTX 30, `89` for RTX 40, `120` for RTX 50 (use CUDA 13.x for RTX 50; 12.8 builds
  had prompt-path crashes).
- **VRAM:** 24 GB is what I run. 16 GB should load but is untested, and prompts get processed in smaller batches, so
  prefill will be slower. Below 16 GB won't work.
- **RAM:** 90 GB here, with a 64 GB expert cache in RAM. Less RAM means a smaller cache, so more experts come off the
  NVMe each token and decode is slower. More RAM helps: around 256 GB holds every expert.
- **Disks:** about 152 GiB for the quant plus ~200 GB for the Engram tables. Both want a fast NVMe on ext4 or NTFS.
  **Not exFAT** (Linux's exFAT driver serialises parallel reads; expert reads were 5x slower here) and not a hard
  drive (the Engram lookups are ~48 small random reads per token).

## How it works, in one paragraph

A mixture-of-experts model only uses a few experts per token. Xolotl keeps every expert somewhere - the hottest in
VRAM, tens of GiB in a pinned RAM arena the GPU reads by DMA, the rest on NVMe read at the drive's ceiling - and
moves the ones each token's router asks for, a layer ahead. Each model adds its own tricks: DeepSeek-V4.1 gets a
calibrated mixed-precision quantisation, speculative decoding with exact sampling, a bit-exact 4-bit KV cache for 512K
context and an arena that adapts to the conversation; GLM-5.3-Flash gets its abliteration LoRA on every path and soft
pruning; the Qwen models get MTP speculative decoding. **[Read the full write-up](docs/xolotl/HOW_IT_WORKS.md).**

## Read more

| | |
| --- | --- |
| [How Xolotl works](docs/xolotl/HOW_IT_WORKS.md) | the three memory tiers, per-model engines, the server, the agent-loop work |
| [Benchmarks](docs/xolotl/BENCHMARKS.md) | every measured number, exactness checks, how to measure your own PC |
| [DeepSeek-V4.1-Flash engine](docs/DEEPSEEK_V41.md) | GSQ quantisation, DSpark, the fp4 KV cache, Engram |
| [GLM-5.3-Flash engine](docs/glm) | KDA + MLA attention, the LoRA on routed experts, soft pruning |
| [Qwen3.8 / upstream Strata](README.strata.md) | the Strata engine this grew from |
| [Brand kit](docs/brand/XOLOTL_BRAND.md) | logo, banner, palette |

## Credits

<img src="docs/brand/assets/logo-circle-400.png" alt="Xolotl" width="110" align="right">

Built on **[Strata](https://github.com/Niko1221/Strata)** by Niko1221 (its engine, server and kernels, merged at
0.1.44.1) and [ggml / llama.cpp](https://github.com/ggml-org/llama.cpp); the Qwen3.8-27B dense port is
[perronemirko](https://github.com/perronemirko/Strata)'s. The DeepSeek-V4.1 and GLM-5.3-Flash engines, the GSQ quant
and the unification are Indras Mirror's. Model weights: DeepSeek, Zhipu AI, Qwen, with quants and fine-tunes by
peasantsmith, ukisai, d0xin and gcsa-abliterix.

*Xolotl* is Quetzalcoatl's dark twin, who carries the dead up from the underworld - as the engine carries experts up
from RAM and NVMe. Research code from one developer, measured on one PC; reports from other hardware welcome. MIT.
