using Oceananigans.Grids: halo_size
using Oceananigans.AbstractOperations: Ax, Ay, GridMetricOperation
# Has to be changed when the regression data is updated 

function compute_vertically_integrated_lateral_areas!(∫ᶻ_A)

    # we have to account for halos when calculating Integrated areas, in case 
    # a periodic domain, where it is not guaranteed that ηₙ == ηₙ₊₁ 
    # 2 halos (instead of only 1) are necessary to accomodate the preconditioner

    field_grid = ∫ᶻ_A.xᶠᶜᶜ.grid

    Axᶠᶜᶜ = GridMetricOperation((Face, Center, Center), Ax, field_grid)
    Ayᶜᶠᶜ = GridMetricOperation((Center, Face, Center), Ay, field_grid)

    sum!(∫ᶻ_A.xᶠᶜᶜ, Axᶠᶜᶜ)
    sum!(∫ᶻ_A.yᶜᶠᶜ, Ayᶜᶠᶜ)

    fill_halo_regions!(∫ᶻ_A.xᶠᶜᶜ, arch)
    fill_halo_regions!(∫ᶻ_A.yᶜᶠᶜ, arch)

    return nothing
end

"""
Compute the vertical integrated volume flux from the bottom to ``z=0`` (i.e., linear free-surface).

```
U★ = ∫ᶻ Ax * u★ dz
V★ = ∫ᶻ Ay * v★ dz
```
"""
### Note - what we really want is RHS = divergence of the vertically integrated volume flux
###        we can optimize this a bit later to do this all in one go to save using intermediate variables.
function compute_vertically_integrated_volume_flux!(∫ᶻ_U, model)

    # Fill halo regions for predictor velocity.
    fill_halo_regions!(model.velocities, model.architecture, model.clock, fields(model))

    sum!(∫ᶻ_U.u, Ax * model.velocites.u)
    sum!(∫ᶻ_U.v, Ay * model.velocites.v)

    # We didn't include right boundaries, so...
    fill_halo_regions!(∫ᶻ_U, model.architecture, model.clock, fields(model))

    return nothing
end
