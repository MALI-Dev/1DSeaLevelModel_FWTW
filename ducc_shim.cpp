#include <cstdio>
#include <cstddef>
#include <cstdlib>

extern "C" {

void *ducc_sh_init(int nlon, int nlat, int ntrunc, double re)
{
    (void)nlon;
    (void)nlat;
    (void)ntrunc;
    (void)re;

    std::fprintf(stderr,
                 "DUCC shim initialization is not implemented yet in ducc_shim.cpp. "
                 "Please implement ducc_sh_init/ducc_sh_spat2spec/ducc_sh_spec2spat.\n");
    return nullptr;
}

void ducc_sh_destroy(void *plan)
{
    (void)plan;
}

void ducc_sh_spat2spec(void *plan, const double *z, void *u, int nlat, int nlon, int ntrunc)
{
    (void)plan;
    (void)z;
    (void)u;
    (void)nlat;
    (void)nlon;
    (void)ntrunc;

    std::fprintf(stderr,
                 "DUCC shim function ducc_sh_spat2spec is not implemented.\n");
    std::abort();
}

void ducc_sh_spec2spat(void *plan, double *z, const void *u, int nlat, int nlon, int ntrunc)
{
    (void)plan;
    (void)z;
    (void)u;
    (void)nlat;
    (void)nlon;
    (void)ntrunc;

    std::fprintf(stderr,
                 "DUCC shim function ducc_sh_spec2spat is not implemented.\n");
    std::abort();
}

}
