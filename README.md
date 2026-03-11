# 1DSeaLevelModel_FWTW

*This code is made public for the benifit of scientific community.

This repository houses a 1D pseudo-spectral forward sea-level model with the time window algorithm introduced in Han et al. (2022, GMD).

The sea-level model in this repository branches out from the ice-age sea-level code (sl_model.f90 housed in the other repository "SL_MODEL", https://github.com/GomezGroup/SL_MODEL) and implements forward modelling algorithm developed by Gomez et al. (2010) and the new time window algorithm developed by Han et al. (2022); hence, the name of the model is SL_MODEL_FWTW (ForWard TimeWindow). This model can be configured to run either as a standalone or coupled to a dynamic ice-sheet model with or without activating the time window algorithm.

*Note: The fundamental difference between the ice-age sea-level calculations and forward sea-level calculations is the previous knowledge of the inital topography boundary condition - it is unknown in the ice-age calculations whereas known in the forward calculations.


To the users of this code (whether the time window algorithm is utilized or not in their use), we kindly ask to cite the following references (from most recent) along with the DOI of this repository (https://doi.org/10.5281/zenodo.5775235):

1. Time window algorithm: Han et al., 2022. Capturing the Interactions Between Ice Sheets, Sea Level and the Solid Earth on a Range of Timescales: A new “time window” algorithm, Geosci. Model Dev., 15, 1355–1373. https://doi.org/10.5194/gmd-15-1355-2022

2. Forward sea-level algorithm: Gomez et al., 2010. A new projection of sea level change in response to collapse of marinesectors of the Antarctic Ice Sheet, Geophysical Journal International (GJI). https://doi.org/10.1111/j.1365-246X.2009.04419.x

3. Ice-age sea-level algorithm: Kendall et al., 2005. On post-glacial sea level II. Numerical formulation and comparative results on spherically symmetric models, Geophysical Journal International (GJI). https://doi.org/10.1111/j.1365-246X.2005.02553.x


## Spherical Harmonic Backends

The model now supports runtime selection of spherical harmonic backend through the namelist option `sh_backend` in the `&others` group.

- `spharmt`: default pure Fortran backend.
- `ducc`: optional DUCC backend (must be compiled in).

If `sh_backend='ducc'` is requested in a binary built without DUCC support, the model terminates with a clear error.

For main model runs, DUCC runtime tuning can also be set in `namelist.sealevel` under `&others`:

- `ducc_direct_map = .true.` enables the direct Fortran-strided map path (`.false.` uses fallback copy path).
- `ducc_sht_threads = 1` sets DUCC transform threads (must be positive to take effect).

### Fetch DUCC source submodule

```bash
make ducc-submodule
```

This initializes/updates the DUCC source at `external/ducc`.

### Build without DUCC (default)

```bash
make clean
make
```

### Build with DUCC enabled

```bash
make clean
make USE_DUCC=1
```

By default, `DUCC_DIR=external/ducc` and `DUCC_INCLUDE=$(DUCC_DIR)/src`.
When `USE_DUCC=1`, the Makefile now builds a local static DUCC library at
`build/ducc/libducc0.a` automatically.
It also builds a local C-ABI shim library at `build/ducc/libducc_shim.a`.

You can also build it explicitly:

```bash
make ducc-lib
make ducc-shim
```

## Standalone Backend Comparison Test

You can compare transform differences and CPU timing between `spharmt` and `ducc`
without running the full sea-level solver:

```bash
make clean
make USE_DUCC=1 sh-backend-test
./sh_backend_test.exe
```

The test reports:
- Relative spectral difference (DUCC vs spharmt)
- Relative spatial difference after synthesis
- Round-trip relative errors for each backend
- `cpu_time` timings and speedup ratios for `spat2spec` and `spec2spat`
- Overhead breakdown (`grid generation`, per-backend init, warmup, benchmark total)

### DUCC Performance Defaults and Tuning

Current default plan prioritizes DUCC throughput while preserving a fallback:

- Direct Fortran-strided DUCC map path is enabled by default.
- DUCC shim default thread count is 1 unless overridden.

Runtime controls:

```bash
# Force fallback copy path instead of direct strided map path
DUCC_DIRECT_MAP=0 ./sh_backend_test.exe

# Set DUCC transform threads
DUCC_SHT_THREADS=4 ./sh_backend_test.exe
```

Build-time defaults (override when invoking `make`):

```bash
# Compile shim with fallback path as default
make USE_DUCC=1 DUCC_DIRECT_MAP_DEFAULT=0

# Compile shim with a different default thread count
make USE_DUCC=1 DUCC_SHT_THREADS_DEFAULT=4
```

Notes:
- `DUCC_LIBS` should include the C-ABI shim library providing `ducc_sh_init`, `ducc_sh_destroy`, `ducc_sh_spat2spec`, and `ducc_sh_spec2spat`.
- The Makefile links DUCC with the platform C++ stdlib automatically (`-lc++` on macOS, `-lstdc++` otherwise).
