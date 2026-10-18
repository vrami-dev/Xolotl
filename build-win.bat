@echo off
rem Windows build of Xolotl (windows-native branch): MSVC 2022 + CUDA 12.8, RTX 3090 (sm_86).
rem   build-win.bat configure      - CMake configure into build-win
rem   build-win.bat <target...>    - ninja -k 0 the given targets (default ds41_generate)
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul || exit /b 1
set "PATH=%~dp0.venv-build\Scripts;C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.8\bin;%PATH%"
cd /d "%~dp0"
if /i "%~1"=="configure" (
  cmake -S . -B build-win -G Ninja -DCMAKE_BUILD_TYPE=Release ^
    -DSTRATA_ENABLE_CUDA=ON -DSTRATA_GGML_CUDA=ON -DSTRATA_MMQ_KQUANTS=ON ^
    -DCMAKE_CUDA_ARCHITECTURES=86 ^
    "-DCMAKE_CUDA_COMPILER=C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v12.8/bin/nvcc.exe" ^
    -DSTRATA_GGML_DIR=%~dp0third_party/llama.cpp ^
    -DSTRATA_DSV41_FQ_OP=ON -DSTRATA_DSV41_HC_MIX=ON
  exit /b %errorlevel%
)
set "TARGETS=%*"
if "%TARGETS%"=="" set "TARGETS=ds41_generate"
ninja -C build-win -k 0 %TARGETS%
