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
DUCC_DIR ?= external/ducc
DUCC_INCLUDE ?= $(DUCC_DIR)/src
DUCC_BUILD_DIR ?= build/ducc
DUCC_OBJ_DIR ?= $(DUCC_BUILD_DIR)/obj
DUCC_TARGET_LIB ?= $(DUCC_BUILD_DIR)/libducc0.a
DUCC_SHIM_SRC ?= ducc_shim.cpp
DUCC_SHIM_OBJ ?= $(DUCC_BUILD_DIR)/ducc_shim.o
DUCC_SHIM_LIB ?= $(DUCC_BUILD_DIR)/libducc_shim.a
DUCC_CXXFLAGS ?= -O3 -std=c++17 -fPIC -I$(DUCC_INCLUDE)
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
	$(DUCC_DIR)/src/ducc0/wgridder/wgridder.cc \
	$(DUCC_DIR)/src/ducc0/infra/string_utils.cc \
	$(DUCC_DIR)/src/ducc0/infra/communication.cc \
	$(DUCC_DIR)/src/ducc0/infra/types.cc \
	$(DUCC_DIR)/src/ducc0/infra/system.cc \
	$(DUCC_DIR)/src/ducc0/infra/threading.cc \
	$(DUCC_DIR)/src/ducc0/infra/mav.cc

DUCC_OBJS = $(patsubst $(DUCC_DIR)/src/%.cc,$(DUCC_OBJ_DIR)/%.o,$(DUCC_SRCS))

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

RM = rm -f

##########################

.SUFFIXES: .f90 .o
.PHONY: ducc-submodule ducc-lib ducc-shim sh-backend-test


OBJS = sl_model_driver.o \
       sl_model_mod.o \
	sh_backend_mod.o \
	$(DUCC_OBJ) \
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

sl_model_driver.o: sl_model_mod.o
sl_model_mod.o: sh_backend_mod.o user_specs_mod.o sl_init_mod.o
sh_backend_mod.o: spharmt.o $(DUCC_OBJ)
test_sh_backends.o: sh_backend_mod.o

clean:
	$(RM) *.o *.mod slmodel.exe
	$(RM) -r $(DUCC_BUILD_DIR)

ducc-submodule:
	git submodule update --init --recursive $(DUCC_DIR)

ducc-lib: $(DUCC_TARGET_LIB)

ducc-shim: $(DUCC_SHIM_LIB)

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
	$(CXX) $(DUCC_CXXFLAGS) -c $< -o $@

$(DUCC_OBJ_DIR)/%.o: $(DUCC_DIR)/src/%.cc
	@mkdir -p $(dir $@)
	$(CXX) $(DUCC_CXXFLAGS) -c $< -o $@

ifeq ($(USE_DUCC),1)
sh-backend-test: $(SH_TEST_EXE)

$(SH_TEST_EXE): test_sh_backends.o sh_backend_mod.o spharmt.o $(DUCC_OBJ) $(DUCC_TARGET_LIB) $(DUCC_SHIM_LIB)
	$(FC) $(LDFLAGS) -o $@ test_sh_backends.o sh_backend_mod.o spharmt.o $(DUCC_OBJ) \
		-L$(DUCC_BUILD_DIR) -lducc_shim -lducc0 $(DUCC_CXX_STDLIB) $(DUCC_SYS_LIBS) $(DUCC_EXTRA_LIBS)
else
sh-backend-test:
	@echo "sh-backend-test requires USE_DUCC=1"
	@exit 2
endif

%.o : %.f90
	$(FC)  $(FFLAGS) -c  $< $(INCLUDES)

