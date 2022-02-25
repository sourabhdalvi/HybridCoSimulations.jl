function get_no_of_scenarios(devices::U
) where {U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}}} where {D <: PSY.Component}

    no_of_scenarios = nothing
    for d in devices
        if isnothing(no_of_scenarios)
            no_of_scenarios = PSY.get_ext(d)["no_of_scenarios"]
        else
            @assert no_of_scenarios == PSY.get_ext(d)["no_of_scenarios"]
        end
    end
    return no_of_scenarios
end
