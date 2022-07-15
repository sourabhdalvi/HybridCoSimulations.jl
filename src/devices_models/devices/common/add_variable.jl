

function PSI.add_variable!(
    container::PSI.OptimizationContainer,
    variable_type::T,
    devices::U,
    formulation,
) where {
    T <: CurtailedEnergy,
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
} where {D <: PSY.Component}
    @assert !isempty(devices)
    time_steps = PSI.get_time_steps(container)
    settings = PSI.get_settings(container)
    binary = PSI.get_variable_binary(variable_type, D, formulation)
    no_of_scenarios = get_no_of_scenarios(devices)

    variable = PSI.add_variable_container!(
        container,
        variable_type,
        D,
        [PSY.get_name(d) for d in devices],
        1:no_of_scenarios,
        time_steps,
    )

    for t in time_steps, d in devices, r in 1:no_of_scenarios
        name = PSY.get_name(d)
        variable[name, r, t] = JuMP.@variable(
            container.JuMPmodel,
            base_name = "$(variable_type)_$(D)_{$(name), $(r), $(t)}",
            binary = binary
        )

        ub = PSI.get_variable_upper_bound(variable_type, d, formulation)
        ub !== nothing && JuMP.set_upper_bound(variable[name, r, t], ub)

        lb = PSI.get_variable_lower_bound(variable_type, d, formulation)
        lb !== nothing &&
            !binary &&
            JuMP.set_lower_bound(variable[name, r, t], lb)

        if PSI.get_warm_start(settings)
            init = PSI.get_variable_warm_start_value(variable_type, d, formulation)
            init !== nothing && JuMP.set_start_value(variable[name, r, t], init)
        end
    end

    return
end

# function PSI.add_variable!(
#     container::PSI.OptimizationContainer,
#     variable_type::T,
#     devices::U,
#     formulation,
# ) where {
#     T <: Union{EnergyAboveInitial, EnergySlackVariableK1, EnergySlackVariableK2},
#     U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
# } where {D <: PSY.Component}
#     @assert !isempty(devices)
#     time_steps = PSI.get_time_steps(container)
#     settings = PSI.get_settings(container)
#     binary = PSI.get_variable_binary(variable_type, D, formulation)

#     variable = PSI.add_variable_container!(
#         container,
#         variable_type,
#         D,
#         [PSY.get_name(d) for d in devices],
#     )

#     for d in devices
#         name = PSY.get_name(d)
#         variable[name] = JuMP.@variable(
#             container.JuMPmodel,
#             base_name = "$(variable_type)_$(D)_{$(name)}",
#             binary = binary
#         )

#         ub = PSI.get_variable_upper_bound(variable_type, d, formulation)
#         ub !== nothing && JuMP.set_upper_bound(variable[name], ub)

#         lb = PSI.get_variable_lower_bound(variable_type, d, formulation)
#         lb !== nothing &&
#             !binary &&
#             JuMP.set_lower_bound(variable[name], lb)

#         if PSI.get_warm_start(settings)
#             init = PSI.get_variable_warm_start_value(variable_type, d, formulation)
#             init !== nothing && JuMP.set_start_value(variable[name], init)
#         end
#     end

#     return
# end
