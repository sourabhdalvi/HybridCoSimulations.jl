
function PSI.axis_array_to_dataframe(
    array::DenseAxisArray{T, 3, K},
    key::PSI.OptimizationContainerKey,
) where {T, K}
    device, scenarios, time_steps = size(array)
    reshap_array = convert(Matrix, transpose(reshape(array.data, (device*scenarios,time_steps))))
    return DataFrames.DataFrame(reshap_array, PSI.get_column_names(key, array))
end

function PSI.get_column_names(
    key::PSI.OptimizationContainerKey,
    array::DenseAxisArray{T, 1, K},
) where {T, K <: NTuple{1, Vector{String}}}
    return axes(array)[1]
end

function PSI.get_column_names(
    ::PSI.OptimizationContainerKey,
    array::DenseAxisArray{T, 3, K},
) where {T, K }
    device, scenarios, time_steps = size(array)
    # reshap_array = convert(Matrix, transpose(reshape(array.data, (device*scenarios,time_steps))))
    col_names = string.(axes(array)[1])
    col_names = [col*"_$(i)" for i in 1:scenarios for col in col_names]
    return col_names
end

function PSI.to_matrix(array::DenseAxisArray{T, 3, K}) where {T, K}
    ax = axes(array)
    data = Matrix{Float64}(undef, length(ax[3]), length(ax[1])*length(ax[2]))
    for t in ax[3], (scen_id, scen) in enumerate(ax[2]), (ix, name) in enumerate(ax[1])
        data[t, (scen_id+ix-1)] = PSI.jump_value(array[name, scen, t])
    end
    return data
end

function PSI._calc_dimensions(
    array::DenseAxisArray,
    key::PSI.VariableKey{T, U},
    num_rows::Int,
    horizon::Int,
) where {T <: CurtailedEnergy, U <: PSY.HybridSystem}
    ax = axes(array)
    columns = PSI.get_column_names(key, array)
    if length(ax) == 1
        dims = (horizon, 1, num_rows)
    elseif length(ax) == 2
        dims = (horizon, length(columns), num_rows)
    elseif length(ax) == 3
        # This is specific to CurtailedEnergy
        dims = (horizon, length(columns), num_rows)
    else
        error("unsupported data size $(length(ax))")
    end

    return Dict("columns" => columns, "dims" => dims)
end

function PSI._calc_dimensions(
    array::DenseAxisArray,
    key::PSI.ParameterKey{T, U},
    num_rows::Int,
    horizon::Int,
) where {T <: ProductionLowerBoundParameter, U <: PSY.HybridSystem}
    ax = axes(array)
    columns = PSI.get_column_names(key, array)
    if length(ax) == 1
        dims = (horizon, 1, num_rows)
    elseif length(ax) == 2
        dims = (horizon, length(columns), num_rows)
    elseif length(ax) == 3
        # This is specific to ProductionLowerBoundParameter
        dims = (horizon, length(columns), num_rows)
    else
        error("unsupported data size $(length(ax))")
    end

    return Dict("columns" => columns, "dims" => dims)
end
