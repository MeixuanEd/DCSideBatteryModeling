struct ModelJacobian
    J_func::Function
    J_Matrix::Matrix{Float64}
end

function calc_jacobian_function()
    _, model_rhs, _, variables, params = ode_model_4th_order(nothing)
    @assert length(model_rhs) == length(variables)
    variable_count = length(variables)
    _eqs = zeros(length(model_rhs)) .~ model_rhs
    _nl_system = MTK.NonlinearSystem(_eqs, [variables...], [params...][2:end])
    nlsys_jac = MTK.calculate_jacobian(_nl_system, expression = Val{false})[2] # second is in-place
    return nlsys_jac
end

#Added temporarily while the stack overflow issue is resolved
function get_4th_order_jacobian_expression()
    _, model_rhs, _, variables, params = ode_model_4th_order(nothing)
    @assert length(model_rhs) == length(variables)
    variable_count = length(variables)
    _eqs = zeros(length(model_rhs)) .~ model_rhs
    _nl_system = MTK.NonlinearSystem(_eqs, [variables...], [params...][2:end])
    nlsys_jac = MTK.generate_jacobian(_nl_system)[2] # second is in-place
    return nlsys_jac
end

function get_2nd_order_jacobian_expression()
    _, model_rhs, _, variables, params = ode_model_2nd_order(nothing)
    @assert length(model_rhs) == length(variables)
    variable_count = length(variables)
    _eqs = zeros(length(model_rhs)) .~ model_rhs
    _nl_system = MTK.NonlinearSystem(_eqs, [variables...], [params...][2:end])
    nlsys_jac = MTK.generate_jacobian(_nl_system)[2] # second is in-place
    return nlsys_jac
end

function get_0th_order_jacobian_expression()
    _, model_rhs, _, variables, params = ode_model_0th_order(nothing)
    @assert length(model_rhs) == length(variables)
    variable_count = length(variables)
    _eqs = zeros(length(model_rhs)) .~ model_rhs
    _nl_system = MTK.NonlinearSystem(_eqs, [variables...], [params...][2:end])
    nlsys_jac = MTK.generate_jacobian(_nl_system)[2] # second is in-place
    return nlsys_jac
end

#Added temporarily while the stack overflow issue is resolved
function get_2nd_pade_jacobian_expression()
    _, model_rhs, _, variables, params = ode_model_4th_order_2nd_pade(nothing)
    @assert length(model_rhs) == length(variables)
    variable_count = length(variables)
    _eqs = zeros(length(model_rhs)) .~ model_rhs
    _nl_system = MTK.NonlinearSystem(_eqs, [variables...], [params...][2:end])
    nlsys_jac = MTK.generate_jacobian(_nl_system)[2] # second is in-place
    return nlsys_jac
end

#Added temporarily while the stack overflow issue is resolved
function get_dc_model_jacobian_expression()
    _, model_rhs, _, variables, params = reduced_dc_model(nothing)
    @assert length(model_rhs) == length(variables)
    variable_count = length(variables)
    _eqs = zeros(length(model_rhs)) .~ model_rhs
    _nl_system = MTK.NonlinearSystem(_eqs, [variables...], [params...][2:end])
    nlsys_jac = MTK.generate_jacobian(_nl_system)[2] # second is in-place
    return nlsys_jac
end

function instantiate_jacobian(M::ModelOperatingPoint)
    jac = get_jacobian_function()
    jac_eval = (out, u0, params) -> jac(out, u0, params)
    param_eval = (out, params) -> jac(out, M.u0, params)
    n = length(M.u0)
    J = zeros(n, n)
    #_parameter_values = [x.second for x in M.parameters]
    param_eval(J, M.parameters)
    return ModelJacobian(jac_eval, J)
end

function (J::ModelJacobian)(M::ModelOperatingPoint)
    #_parameters = [x.second for x in M.parameters]
    J.J_func(J.J_Matrix, M.u0, M.parameters)
    return J.J_Matrix
end
