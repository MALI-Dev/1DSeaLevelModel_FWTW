#include <array>
#include <complex>
#include <cstdio>
#include <cstddef>
#include <cstdlib>
#include <new>
#include <string>
#include <vector>

#include "ducc0/sht/sht.h"
#include "ducc0/infra/mav.h"

namespace {

using dcomplex = std::complex<double>;

struct DuccPlan {
    int nlon;
    int nlat;
    int ntrunc;
    std::vector<std::size_t> mstart;
    std::vector<double> ringfactor;
};

DuccPlan *as_plan(void *ptr)
{
    return reinterpret_cast<DuccPlan *>(ptr);
}

std::array<std::size_t, 3> map_shape(const DuccPlan &p)
{
    return {1u, static_cast<std::size_t>(p.nlat), static_cast<std::size_t>(p.nlon)};
}

std::size_t alm_extent(const DuccPlan &p)
{
    const std::size_t n = static_cast<std::size_t>(p.ntrunc + 1);
    return n * (n + 1) / 2;
}

} // namespace

extern "C" {

void *ducc_sh_init(int nlon, int nlat, int ntrunc, double re)
{
    (void)re;
    if (nlon <= 0 || nlat <= 0 || ntrunc < 0) {
        std::fprintf(stderr, "ducc_sh_init: invalid dimensions nlon=%d nlat=%d ntrunc=%d\n", nlon, nlat, ntrunc);
        return nullptr;
    }

    try {
        auto *plan = new DuccPlan();
        plan->nlon = nlon;
        plan->nlat = nlat;
        plan->ntrunc = ntrunc;
        plan->mstart.resize(static_cast<std::size_t>(ntrunc + 1));
        plan->ringfactor.assign(static_cast<std::size_t>(nlat), 1.0);

        std::size_t idx = 0;
        for (int m = 0; m <= ntrunc; ++m) {
            plan->mstart[static_cast<std::size_t>(m)] = idx;
            idx += static_cast<std::size_t>(ntrunc + 1 - m);
        }

        return plan;
    } catch (const std::exception &ex) {
        std::fprintf(stderr, "ducc_sh_init exception: %s\n", ex.what());
        return nullptr;
    } catch (...) {
        std::fprintf(stderr, "ducc_sh_init unknown exception\n");
        return nullptr;
    }
}

void ducc_sh_destroy(void *plan)
{
    delete as_plan(plan);
}

void ducc_sh_spat2spec(void *plan_ptr, const double *z, void *u, int nlat, int nlon, int ntrunc)
{
    auto *plan = as_plan(plan_ptr);
    if (plan == nullptr || z == nullptr || u == nullptr) {
        std::fprintf(stderr, "ducc_sh_spat2spec: null input pointer\n");
        std::abort();
    }
    if (plan->nlat != nlat || plan->nlon != nlon || plan->ntrunc != ntrunc) {
        std::fprintf(stderr, "ducc_sh_spat2spec: dimension mismatch with plan\n");
        std::abort();
    }

    try {
        std::vector<double> mapbuf(static_cast<std::size_t>(nlat) * static_cast<std::size_t>(nlon));
        for (int j = 0; j < nlon; ++j) {
            for (int i = 0; i < nlat; ++i) {
                mapbuf[static_cast<std::size_t>(i) * static_cast<std::size_t>(nlon) + static_cast<std::size_t>(j)] =
                    z[static_cast<std::size_t>(i) + static_cast<std::size_t>(j) * static_cast<std::size_t>(nlat)];
            }
        }

        ducc0::cmav<double, 3> map(
            mapbuf.data(),
            map_shape(*plan));
        ducc0::vmav<dcomplex, 2> alm(
            reinterpret_cast<dcomplex *>(u),
            std::array<std::size_t, 2>{1u, alm_extent(*plan)});
        ducc0::cmav<std::size_t, 1> mstart(
            plan->mstart.data(),
            std::array<std::size_t, 1>{plan->mstart.size()});
        ducc0::cmav<double, 1> ringfactor(
            plan->ringfactor.data(),
            std::array<std::size_t, 1>{plan->ringfactor.size()});

        ducc0::analysis_2d(
            alm,
            map,
            0,
            static_cast<std::size_t>(plan->ntrunc),
            mstart,
            1,
            std::string("GL"),
            0.0,
            ringfactor,
            1);
    } catch (const std::exception &ex) {
        std::fprintf(stderr, "ducc_sh_spat2spec exception: %s\n", ex.what());
        std::abort();
    } catch (...) {
        std::fprintf(stderr, "ducc_sh_spat2spec unknown exception\n");
        std::abort();
    }
}

void ducc_sh_spec2spat(void *plan_ptr, double *z, const void *u, int nlat, int nlon, int ntrunc)
{
    auto *plan = as_plan(plan_ptr);
    if (plan == nullptr || z == nullptr || u == nullptr) {
        std::fprintf(stderr, "ducc_sh_spec2spat: null input pointer\n");
        std::abort();
    }
    if (plan->nlat != nlat || plan->nlon != nlon || plan->ntrunc != ntrunc) {
        std::fprintf(stderr, "ducc_sh_spec2spat: dimension mismatch with plan\n");
        std::abort();
    }

    try {
        std::vector<double> mapbuf(static_cast<std::size_t>(nlat) * static_cast<std::size_t>(nlon));

        ducc0::cmav<dcomplex, 2> alm(
            reinterpret_cast<const dcomplex *>(u),
            std::array<std::size_t, 2>{1u, alm_extent(*plan)});
        ducc0::vmav<double, 3> map(
            mapbuf.data(),
            map_shape(*plan));
        ducc0::cmav<std::size_t, 1> mstart(
            plan->mstart.data(),
            std::array<std::size_t, 1>{plan->mstart.size()});
        ducc0::cmav<double, 1> ringfactor(
            plan->ringfactor.data(),
            std::array<std::size_t, 1>{plan->ringfactor.size()});

        ducc0::synthesis_2d(
            alm,
            map,
            0,
            static_cast<std::size_t>(plan->ntrunc),
            mstart,
            1,
            std::string("GL"),
            0.0,
            ringfactor,
            1,
            ducc0::STANDARD);

        for (int j = 0; j < nlon; ++j) {
            for (int i = 0; i < nlat; ++i) {
                z[static_cast<std::size_t>(i) + static_cast<std::size_t>(j) * static_cast<std::size_t>(nlat)] =
                    mapbuf[static_cast<std::size_t>(i) * static_cast<std::size_t>(nlon) + static_cast<std::size_t>(j)];
            }
        }
    } catch (const std::exception &ex) {
        std::fprintf(stderr, "ducc_sh_spec2spat exception: %s\n", ex.what());
        std::abort();
    } catch (...) {
        std::fprintf(stderr, "ducc_sh_spec2spat unknown exception\n");
        std::abort();
    }
}

}
