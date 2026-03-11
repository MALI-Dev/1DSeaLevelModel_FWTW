# IBM with Xlf compilers
#FC = xlf90
#FFLAGS = -qrealsize=8 -g -C
#LDFLAGS = -g -C

# pgf90
# FC = pgf90
# FFLAGS = -r8 -O3
# LDFLAGS = -O3

# ifort
#FC = ifort
#FFLAGS = -real-size 64 -O3
#LDFLAGS = -O3

# absoft
#FC = f90
#FFLAGS = -dp -O3
#LDFLAGS = -O3

# gfortran
FC = gfortran
FFLAGS = -O3 -m64 -ffree-line-length-none -fdefault-real-8 -fconvert=big-endian -ffpe-summary=none -g
LDFLAGS = -O3 -m64
CXX ?= g++
AR ?= ar
RANLIB ?= ranlib

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
MACOS_SDKROOT ?= $(shell xcrun --show-sdk-path)
FFLAGS += -isysroot $(MACOS_SDKROOT)
LDFLAGS += -Wl,-syslibroot,$(MACOS_SDKROOT)
endif


CPP = cpp -P -traditional
CPPFLAGS = 
CPPINCLUDES = 
INCLUDES = -I$(NETCDF)/include -I.

USE_DUCC ?= 0
USE_SHTNS ?= 0
DUCC_DIR ?= external/ducc
DUCC_INCLUDE ?= $(DUCC_DIR)/src
DUCC_BUILD_DIR ?= build/ducc
DUCC_OBJ_DIR ?= $(DUCC_BUILD_DIR)/obj
DUCC_TARGET_LIB ?= $(DUCC_BUILD_DIR)/libducc0.a
DUCC_SHIM_SRC ?= ducc_shim.cpp
DUCC_SHIM_OBJ ?= $(DUCC_BUILD_DIR)/ducc_shim.o
DUCC_SHIM_LIB ?= $(DUCC_BUILD_DIR)/libducc_shim.a
DUCC_CXXFLAGS ?= -O3 -std=c++17 -fPIC -I$(DUCC_INCLUDE)
DUCC_DIRECT_MAP_DEFAULT ?= 1
DUCC_SHT_THREADS_DEFAULT ?= 1
DUCC_SHIM_DEFS ?= -DDUCC_DIRECT_MAP_DEFAULT=$(DUCC_DIRECT_MAP_DEFAULT) -DDUCC_SHT_THREADS_DEFAULT=$(DUCC_SHT_THREADS_DEFAULT)
DUCC_CXX_STDLIB ?= -lstdc++
ifeq ($(UNAME_S),Darwin)
DUCC_CXXFLAGS += -isysroot $(MACOS_SDKROOT)
DUCC_CXX_STDLIB := -lc++
endif
DUCC_SYS_LIBS ?= -lpthread
DUCC_EXTRA_LIBS ?=

DUCC_SRCS = \
	$(DUCC_DIR)/src/ducc0/healpix/healpix_base.cc \
	$(DUCC_DIR)/src/ducc0/healpix/healpix_tables.cc \
	$(DUCC_DIR)/src/ducc0/math/gl_integrator.cc \
	$(DUCC_DIR)/src/ducc0/math/pointing.cc \
	$(DUCC_DIR)/src/ducc0/math/gridding_kernel.cc \
	$(DUCC_DIR)/src/ducc0/math/geom_utils.cc \
	$(DUCC_DIR)/src/ducc0/math/wigner3j.cc \
	$(DUCC_DIR)/src/ducc0/math/space_filling.cc \
	$(DUCC_DIR)/src/ducc0/sht/sht.cc \
	$(DUCC_DIR)/src/ducc0/fft/fft_inst1.cc \
	$(DUCC_DIR)/src/ducc0/fft/fft_inst2.cc \
	$(DUCC_DIR)/src/ducc0/wgridder/wgridder.cc \
	$(DUCC_DIR)/src/ducc0/infra/string_utils.cc \
	$(DUCC_DIR)/src/ducc0/infra/communication.cc \
	$(DUCC_DIR)/src/ducc0/infra/types.cc \
	$(DUCC_DIR)/src/ducc0/infra/system.cc \
	$(DUCC_DIR)/src/ducc0/infra/threading.cc \
	$(DUCC_DIR)/src/ducc0/infra/mav.cc

DUCC_OBJS = $(patsubst $(DUCC_DIR)/src/%.cc,$(DUCC_OBJ_DIR)/%.o,$(DUCC_SRCS))

FFTW_DIR ?= external/fftw
FFTW_MODE ?= binary
FFTW_SOURCE ?= tarball
FFTW_BUILD_DIR ?= build/fftw
FFTW_STAGE_DIR ?= $(FFTW_BUILD_DIR)/stage
FFTW_BUILD_SUBDIR ?= $(FFTW_BUILD_DIR)/build
FFTW_CONFIGURE_ARGS ?= --enable-threads --enable-static --disable-shared
FFTW_VERSION ?= 3.3.10
FFTW_TARBALL_URL ?= https://www.fftw.org/fftw-$(FFTW_VERSION).tar.gz
FFTW_TARBALL ?= $(CURDIR)/external/fftw-$(FFTW_VERSION).tar.gz
FFTW_TARBALL_SRC ?= $(CURDIR)/external/fftw-$(FFTW_VERSION)
ifeq ($(FFTW_MODE),binary)
FFTW_PREFIX ?= $(CURDIR)/external/fftw/install
else ifeq ($(FFTW_MODE),source)
FFTW_PREFIX ?= $(CURDIR)/build/fftw/stage/install
else
$(error Unsupported FFTW_MODE=$(FFTW_MODE). Use FFTW_MODE=binary or FFTW_MODE=source)
endif
FFTW_TARGET_LIB ?= $(FFTW_PREFIX)/lib/libfftw3.a

SHTNS_DIR ?= external/shtns
SHTNS_BUILD_DIR ?= build/shtns
SHTNS_STAGE_DIR ?= $(SHTNS_BUILD_DIR)/stage
SHTNS_PREFIX ?= $(SHTNS_STAGE_DIR)/install
SHTNS_TARGET_LIB ?= $(SHTNS_PREFIX)/lib/libshtns.a
SHTNS_INCLUDE ?= $(SHTNS_PREFIX)/include
SHTNS_LIBDIR ?= $(SHTNS_PREFIX)/lib
SHTNS_CONFIGURE_ARGS ?=

# Specify NetCDF libraries, checking if netcdff is required (it will be present in v4 of netCDF)
LIBS = -L$(NETCDF)/lib
NCLIB = -lnetcdf
NCLIBF = -lnetcdff
ifneq ($(wildcard $(NETCDF)/lib/libnetcdff.*), ) # CHECK FOR NETCDF4
	LIBS += $(NCLIBF)
endif # CHECK FOR NETCDF4
LIBS += $(NCLIB)

ifeq ($(USE_DUCC),1)
ifneq ($(DUCC_INCLUDE),)
INCLUDES += -I$(DUCC_INCLUDE)
endif
ifeq ($(wildcard $(DUCC_DIR)/CMakeLists.txt),)
$(error USE_DUCC=1 but DUCC submodule not found at $(DUCC_DIR). Run `make ducc-submodule`)
endif
LIBS += -L$(DUCC_BUILD_DIR) -lducc_shim -lducc0 $(DUCC_CXX_STDLIB) $(DUCC_SYS_LIBS) $(DUCC_EXTRA_LIBS)
DUCC_OBJ = ducc_backend_mod.o
else
DUCC_OBJ = ducc_backend_stub_mod.o
endif

SH_TEST_LIBS =
ifeq ($(USE_DUCC),1)
SH_TEST_LIBS += -L$(DUCC_BUILD_DIR) -lducc_shim -lducc0 $(DUCC_CXX_STDLIB) $(DUCC_SYS_LIBS) $(DUCC_EXTRA_LIBS)
endif

ifeq ($(USE_SHTNS),1)
ifneq ($(SHTNS_INCLUDE),)
INCLUDES += -I$(SHTNS_INCLUDE)
endif
LIBS += -L$(SHTNS_LIBDIR) -L$(FFTW_PREFIX)/lib -lshtns -lfftw3
SH_TEST_LIBS += -L$(SHTNS_LIBDIR) -L$(FFTW_PREFIX)/lib -lshtns -lfftw3
SHTNS_OBJ = shtns_backend_mod.o
else
SHTNS_OBJ = shtns_backend_stub_mod.o
endif

RM = rm -f

##########################

.SUFFIXES: .f90 .o
.PHONY: ducc-submodule ducc-lib ducc-shim fftw-submodule fftw-check fftw-lib shtns-submodule shtns-lib shtns-build-local sh-backend-test


OBJS = sl_model_driver.o \
       sl_model_mod.o \
	sh_backend_mod.o \
	$(DUCC_OBJ) \
	$(SHTNS_OBJ) \
       spharmt.o \
       user_specs_mod.o\
       sl_init_mod.o

all: slmodel.exe

SH_TEST_EXE = sh_backend_test.exe

slmodel.exe: $(OBJS)
	$(FC) $(LDFLAGS) -o $@ $(OBJS) $(LIBS)

ifeq ($(USE_DUCC),1)
slmodel.exe: $(DUCC_TARGET_LIB) $(DUCC_SHIM_LIB)
endif
ifeq ($(USE_SHTNS),1)
slmodel.exe: $(SHTNS_TARGET_LIB)
endif

sl_model_driver.o: sl_model_mod.o
sl_model_mod.o: sh_backend_mod.o user_specs_mod.o sl_init_mod.o
sh_backend_mod.o: spharmt.o $(DUCC_OBJ) $(SHTNS_OBJ)
shtns_backend_mod.o: $(SHTNS_TARGET_LIB)
test_sh_backends.o: sh_backend_mod.o

clean:
	$(RM) *.o *.mod slmodel.exe
	$(RM) -r $(DUCC_BUILD_DIR)
	$(RM) -r $(FFTW_BUILD_DIR)
	$(RM) -r $(SHTNS_BUILD_DIR)

ducc-submodule:
	git submodule update --init --recursive $(DUCC_DIR)

fftw-submodule:
	@if [ -d "$(FFTW_DIR)" ]; then \
		echo "Using existing FFTW source directory: $(FFTW_DIR)"; \
	else \
		git submodule update --init --recursive $(FFTW_DIR); \
	fi

shtns-submodule:
	@if [ -d "$(SHTNS_DIR)" ]; then \
		echo "Using existing SHTns source directory: $(SHTNS_DIR)"; \
	else \
		git submodule update --init --recursive $(SHTNS_DIR); \
	fi

ducc-lib: $(DUCC_TARGET_LIB)

ducc-shim: $(DUCC_SHIM_LIB)

fftw-check:
	@if [ ! -f "$(FFTW_PREFIX)/include/fftw3.h" ]; then \
		echo "Missing FFTW header: $(FFTW_PREFIX)/include/fftw3.h"; \
		echo "Install FFTW binaries there or run make FFTW_MODE=source fftw-lib"; \
		exit 2; \
	fi
	@if [ ! -f "$(FFTW_PREFIX)/lib/libfftw3.a" ] && [ ! -f "$(FFTW_PREFIX)/lib/libfftw3.dylib" ] && [ ! -f "$(FFTW_PREFIX)/lib/libfftw3.so" ]; then \
		echo "Missing FFTW library under $(FFTW_PREFIX)/lib (expected libfftw3.a/.dylib/.so)"; \
		echo "Install FFTW binaries there or run make FFTW_MODE=source fftw-lib"; \
		exit 2; \
	fi

ifeq ($(FFTW_MODE),source)
fftw-lib: $(FFTW_TARGET_LIB)
else
fftw-lib: fftw-check
endif

shtns-lib: $(SHTNS_TARGET_LIB)

shtns-build-local: fftw-lib shtns-lib

$(DUCC_TARGET_LIB): ducc-submodule $(DUCC_OBJS)
	@mkdir -p $(DUCC_BUILD_DIR)
	$(AR) rcs $@ $(DUCC_OBJS)
	$(RANLIB) $@

$(DUCC_SHIM_LIB): ducc-submodule $(DUCC_TARGET_LIB) $(DUCC_SHIM_OBJ)
	@mkdir -p $(DUCC_BUILD_DIR)
	$(AR) rcs $@ $(DUCC_SHIM_OBJ)
	$(RANLIB) $@

$(DUCC_SHIM_OBJ): $(DUCC_SHIM_SRC)
	@mkdir -p $(DUCC_BUILD_DIR)
	$(CXX) $(DUCC_CXXFLAGS) $(DUCC_SHIM_DEFS) -c $< -o $@

$(DUCC_OBJ_DIR)/%.o: $(DUCC_DIR)/src/%.cc
	@mkdir -p $(dir $@)
	$(CXX) $(DUCC_CXXFLAGS) -c $< -o $@

$(FFTW_TARGET_LIB): fftw-submodule
	@mkdir -p $(FFTW_BUILD_SUBDIR)
	@if [ "$(FFTW_SOURCE)" = "tarball" ]; then \
		mkdir -p "$(CURDIR)/external"; \
		if [ ! -f "$(FFTW_TARBALL)" ]; then \
			if command -v curl >/dev/null 2>&1; then \
				curl -L "$(FFTW_TARBALL_URL)" -o "$(FFTW_TARBALL)"; \
			elif command -v wget >/dev/null 2>&1; then \
				wget -O "$(FFTW_TARBALL)" "$(FFTW_TARBALL_URL)"; \
			else \
				echo "Need curl or wget to download FFTW tarball."; \
				exit 1; \
			fi; \
		fi; \
		rm -rf "$(FFTW_TARBALL_SRC)"; \
		tar -xzf "$(FFTW_TARBALL)" -C "$(CURDIR)/external"; \
		cd $(FFTW_BUILD_SUBDIR) && "$(FFTW_TARBALL_SRC)/configure" --prefix=$(abspath $(FFTW_PREFIX)) $(FFTW_CONFIGURE_ARGS); \
	elif [ "$(FFTW_SOURCE)" = "submodule" ]; then \
		if [ -d "$(FFTW_DIR)" ]; then \
			cd "$(FFTW_DIR)" && sh bootstrap.sh; \
		else \
			echo "FFTW submodule directory not found: $(FFTW_DIR)"; \
			exit 1; \
		fi; \
		cd $(FFTW_BUILD_SUBDIR) && "$(CURDIR)/$(FFTW_DIR)/configure" --prefix=$(abspath $(FFTW_PREFIX)) $(FFTW_CONFIGURE_ARGS); \
	else \
		echo "Unsupported FFTW_SOURCE=$(FFTW_SOURCE). Use tarball or submodule."; \
		exit 1; \
	fi
	$(MAKE) -C $(FFTW_BUILD_SUBDIR) MAKEINFO=true
	$(MAKE) -C $(FFTW_BUILD_SUBDIR) MAKEINFO=true install

$(SHTNS_TARGET_LIB): shtns-submodule fftw-lib
	@mkdir -p $(SHTNS_BUILD_DIR)
	cd $(SHTNS_DIR) && ./configure --prefix=$(abspath $(SHTNS_PREFIX)) \
		CPPFLAGS="-I$(abspath $(FFTW_PREFIX))/include" LDFLAGS="-L$(abspath $(FFTW_PREFIX))/lib" LIBS="-lfftw3" $(SHTNS_CONFIGURE_ARGS)
	$(MAKE) -C $(SHTNS_DIR)
	$(MAKE) -C $(SHTNS_DIR) install

ifneq ($(filter 1,$(USE_DUCC) $(USE_SHTNS)),)
sh-backend-test: $(SH_TEST_EXE)

$(SH_TEST_EXE): test_sh_backends.o sh_backend_mod.o spharmt.o $(DUCC_OBJ) $(SHTNS_OBJ)
	$(FC) $(LDFLAGS) -o $@ test_sh_backends.o sh_backend_mod.o spharmt.o $(DUCC_OBJ) $(SHTNS_OBJ) $(SH_TEST_LIBS)

ifeq ($(USE_DUCC),1)
$(SH_TEST_EXE): $(DUCC_TARGET_LIB) $(DUCC_SHIM_LIB)
endif
ifeq ($(USE_SHTNS),1)
$(SH_TEST_EXE): $(SHTNS_TARGET_LIB)
endif
else
sh-backend-test:
	@echo "sh-backend-test requires at least one optional backend: USE_DUCC=1 or USE_SHTNS=1"
	@exit 2
endif

%.o : %.f90
	$(FC)  $(FFLAGS) -c  $< $(INCLUDES)

