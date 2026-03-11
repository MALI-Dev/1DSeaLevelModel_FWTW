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
SHTNS_INCLUDES ?=
SHTNS_LIBDIR ?=
SHTNS_LIBS ?= -lshtns -lfftw3

ADAPTER_CPPFLAGS =
ifeq ($(SH_BACKEND),shtns)
        ADAPTER_CPPFLAGS += -DUSE_SHTNS_BACKEND
endif


CPP = cpp -P -traditional
CPPFLAGS = 
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


OBJS = sl_model_driver.o \
       sl_model_mod.o \
        sh_transform_adapter.o \
       spharmt.o \
       user_specs_mod.o\
       sl_init_mod.o

all: slmodel.exe

slmodel.exe: $(OBJS)
	$(FC) $(LDFLAGS) -o $@ $(OBJS) $(LIBS)

sl_model_driver.o: sl_model_mod.o
sl_model_mod.o: sh_transform_adapter.o user_specs_mod.o sl_init_mod.o
sh_transform_adapter.o: spharmt.o

sh_transform_adapter.o : sh_transform_adapter.f90
	$(FC) $(FFLAGS) -cpp $(ADAPTER_CPPFLAGS) -c $< $(INCLUDES)

clean:
	$(RM) *.o *.mod slmodel.exe

%.o : %.f90
	$(FC)  $(FFLAGS) -c  $< $(INCLUDES)

