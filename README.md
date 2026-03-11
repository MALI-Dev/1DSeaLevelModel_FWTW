# 1DSeaLevelModel_FWTW

*This code is made public for the benifit of scientific community.

This repository houses a 1D pseudo-spectral forward sea-level model with the time window algorithm introduced in Han et al. (2022, GMD).

The sea-level model in this repository branches out from the ice-age sea-level code (sl_model.f90 housed in the other repository "SL_MODEL", https://github.com/GomezGroup/SL_MODEL) and implements forward modelling algorithm developed by Gomez et al. (2010) and the new time window algorithm developed by Han et al. (2022); hence, the name of the model is SL_MODEL_FWTW (ForWard TimeWindow). This model can be configured to run either as a standalone or coupled to a dynamic ice-sheet model with or without activating the time window algorithm.

*Note: The fundamental difference between the ice-age sea-level calculations and forward sea-level calculations is the previous knowledge of the inital topography boundary condition - it is unknown in the ice-age calculations whereas known in the forward calculations.


To the users of this code (whether the time window algorithm is utilized or not in their use), we kindly ask to cite the following references (from most recent) along with the DOI of this repository (https://doi.org/10.5281/zenodo.5775235):

1. Time window algorithm: Han et al., 2022. Capturing the Interactions Between Ice Sheets, Sea Level and the Solid Earth on a Range of Timescales: A new “time window” algorithm, Geosci. Model Dev., 15, 1355–1373. https://doi.org/10.5194/gmd-15-1355-2022

2. Forward sea-level algorithm: Gomez et al., 2010. A new projection of sea level change in response to collapse of marinesectors of the Antarctic Ice Sheet, Geophysical Journal International (GJI). https://doi.org/10.1111/j.1365-246X.2009.04419.x

3. Ice-age sea-level algorithm: Kendall et al., 2005. On post-glacial sea level II. Numerical formulation and comparative results on spherically symmetric models, Geophysical Journal International (GJI). https://doi.org/10.1111/j.1365-246X.2005.02553.x


## Backend Build Options

The spherical harmonic transform path can be selected at build time.

- Default (legacy spharmt path):

```bash
make clean
make
```

- SHTns path (native Fortran interface):

```bash
make clean
make shtns-build-local
make SH_BACKEND=shtns
```

By default, the root Makefile expects FFTW and SHTns as submodules and uses:

- `FFTW_ROOT=external/fftw`
- `FFTW_PREFIX=<repo>/external/fftw/install`

- `SHTNS_ROOT=external/shtns`
- `SHTNS_PREFIX=<repo>/external/shtns/install`
- `SHTNS_INCLUDES=-I$(SHTNS_PREFIX)/include`
- `SHTNS_LIBDIR=-L$(SHTNS_PREFIX)/lib -L$(FFTW_PREFIX)/lib`

You can still override these variables if SHTns is installed elsewhere.

Notes:

- The selected FFTW repository is a source-generator tree. Building from that repo requires running `bootstrap.sh` and therefore additional build tools (e.g., autoconf/automake/libtool and OCaml tooling) before `configure` and `make`.
- The `fftw-build` helper runs `make MAKEINFO=true` so a missing Texinfo `makeinfo` executable does not block the FFTW build.
- The helper target `make shtns-build-local` builds and installs FFTW first, then configures and builds SHTns against that local FFTW install.
- The SHTns backend expects the Fortran include file `shtns.f` to be reachable through `SHTNS_INCLUDES`.
- The default SHTns link list is `-lshtns -lfftw3` and can be overridden with `SHTNS_LIBS="..."`.
- If `SH_BACKEND=shtns` is selected without valid SHTns include/lib paths, compilation will fail.


## Simple Backend Comparison Test (No Love Numbers Needed)

If you want to validate transform behavior before running the full sea-level model,
you can run the standalone transform-only test program. This does not require any
Love-number inputs.

```bash
make clean
make shtns-build-local
make SH_BACKEND=shtns sh-backend-test
./sh_backend_test.exe
```

What it does:

- Builds a smooth synthetic spatial field on a small lat-lon grid.
- Runs spatial-to-spectral and spectral-to-spatial with both backends.
- Reports:
	- relative spectral difference (SHTns vs spharmt)
	- relative spatial difference after synthesis
	- round-trip relative error for each backend

Interpretation:

- Round-trip errors should be small for both backends.
- Backend-to-backend differences should be small and stable; if not, this usually
	indicates normalization or indexing mismatch to tune in the SHTns adapter.
