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

SH_BACKEND ?= spharmt
FFTW_SOURCE ?= tarball
FFTW_ROOT ?= external/fftw
FFTW_PREFIX ?= $(CURDIR)/external/fftw/install
FFTW_VERSION ?= 3.3.10
FFTW_TARBALL_URL ?= https://www.fftw.org/fftw-$(FFTW_VERSION).tar.gz
FFTW_TARBALL ?= $(CURDIR)/external/fftw-$(FFTW_VERSION).tar.gz
FFTW_TARBALL_SRC ?= $(CURDIR)/external/fftw-$(FFTW_VERSION)
SHTNS_ROOT ?= external/shtns
SHTNS_PREFIX ?= $(CURDIR)/external/shtns/install
SHTNS_INCLUDES ?= -I$(SHTNS_PREFIX)/include
SHTNS_LIBDIR ?= -L$(SHTNS_PREFIX)/lib -L$(FFTW_PREFIX)/lib
SHTNS_LIBS ?= -lshtns -lfftw3

CPPFLAGS += -cpp
SH_BACKEND_OBJS =
ifeq ($(SH_BACKEND),shtns)
        CPPFLAGS += -DUSE_SHTNS_BACKEND
        SH_BACKEND_OBJS += sh_shtns_backend.o
endif


CPP = cpp -P -traditional
CPPINCLUDES = 
INCLUDES = -I$(NETCDF)/include -I.

ifneq ($(strip $(SHTNS_INCLUDES)),)
        INCLUDES += $(SHTNS_INCLUDES)
endif

# Specify NetCDF libraries, checking if netcdff is required (it will be present in v4 of netCDF)
LIBS = -L$(NETCDF)/lib
NCLIB = -lnetcdf
NCLIBF = -lnetcdff
ifneq ($(wildcard $(NETCDF)/lib/libnetcdff.*), ) # CHECK FOR NETCDF4
        LIBS += $(NCLIBF)
endif # CHECK FOR NETCDF4
LIBS += $(NCLIB)

ifneq ($(strip $(SHTNS_LIBDIR)),)
        LIBS += $(SHTNS_LIBDIR)
endif
ifeq ($(SH_BACKEND),shtns)
        LIBS += $(SHTNS_LIBS)
endif

RM = rm -f

##########################

.SUFFIXES: .f90 .o
.PHONY: fftw-build shtns-build shtns-build-local sh-backend-test


OBJS = sl_model_driver.o \
       sl_model_mod.o \
        sh_transform_adapter.o \
        $(SH_BACKEND_OBJS) \
       spharmt.o \
       user_specs_mod.o\
       sl_init_mod.o

all: slmodel.exe

sh-backend-test: sh_backend_test.exe

sh_backend_test.exe: test_sh_backends.o sh_transform_adapter.o spharmt.o sh_shtns_backend.o
	$(FC) $(LDFLAGS) -o $@ $^ $(LIBS)

fftw-build:
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
          cd "$(FFTW_TARBALL_SRC)" && ./configure --prefix="$(FFTW_PREFIX)" --enable-shared --disable-static; \
          cd "$(FFTW_TARBALL_SRC)" && make MAKEINFO=true && make MAKEINFO=true install; \
        else \
          cd "$(FFTW_ROOT)" && sh bootstrap.sh && ./configure --prefix="$(FFTW_PREFIX)" --enable-shared --disable-static && make MAKEINFO=true && make MAKEINFO=true install; \
        fi

shtns-build:
	cd $(SHTNS_ROOT) && ./configure --prefix=$(SHTNS_PREFIX) CPPFLAGS="-I$(FFTW_PREFIX)/include" LDFLAGS="-L$(FFTW_PREFIX)/lib" LIBS="-lfftw3" && make && make install

shtns-build-local: fftw-build shtns-build

slmodel.exe: $(OBJS)
	$(FC) $(LDFLAGS) -o $@ $(OBJS) $(LIBS)

sl_model_driver.o: sl_model_mod.o
sl_model_mod.o: sh_transform_adapter.o user_specs_mod.o sl_init_mod.o
sh_transform_adapter.o: spharmt.o
ifeq ($(SH_BACKEND),shtns)
sh_transform_adapter.o: sh_shtns_backend.o
endif

clean:
	$(RM) *.o *.mod slmodel.exe

%.o : %.f90
	$(FC) $(FFLAGS) $(CPPFLAGS) -c $< $(INCLUDES)

