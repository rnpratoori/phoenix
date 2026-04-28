nx = 50     # number of elements per side
ny = 25     # number of elements per side
dx = 2       # ND size of the side
dy = 1       # ND size of the side

k1 = 1
k2 = 0.1
kbg = 0.05
kv = 100
D_p1 = 0.05
D_p2 = 0.01
D_t = 1
D_v = 200


[Mesh]
    # generate a 2D mesh
    type = GeneratedMesh
    dim = 2
    nx = ${nx}
    ny = ${ny}
    xmax = ${dx}
    ymax = ${dy}
    uniform_refine = 2
    add_subdomain_ids = '1'
[]

[MeshModifiers]
    [void]
        type = CoupledVarThresholdElementSubdomainModifier
        coupled_var = c_v
        criterion_type = ABOVE
        subdomain_id = 1
        # complement_subdomain_id = 0
        threshold = 1e-3
        execute_on = 'TIMESTEP_BEGIN'
        force_preic = true
        allow_duplicate_execution_on_initial = true
        reinitialization_strategy = 'NONE'
    []
[]

[Variables]
    # solvent volume fraction
    [c_s]
    []
    # polymer volume fraction
    [c_p1]
    []
    [c_p2]
    []
    # void volume fraction
    [c_v]
    []
    # tissue volume fraction
    [c_t]
    []
[]

[ICs]
    [c_s]
        type = ConstantIC
        value = 0
        variable = c_s
    []
    [c_p1]
        type = SolutionIC
        from_variable = 'c1_total'
        solution_uo = 2phase
        variable = c_p1
        from_subdomains = '0 1'
    []
    [c_p2]
        type = SolutionIC
        from_variable = 'c2_total'
        solution_uo = 2phase
        variable = c_p2
        from_subdomains = '0 1'
    []
    [c_v]
        type = SolutionIC
        from_variable = 'cv_total'
        solution_uo = 2phase
        variable = c_v
        from_subdomains = '0 1'
    []
    [c_t]
        type = ConstantIC
        value = 0
        variable = c_t
    []
[]

[UserObjects]
    [2phase]
        type = SolutionUserObject
        mesh = 'ic_2pv/2pv_0.5_ic_0.10_0.4.e'
        system_variables = 'c1_total c2_total cv_total'
        timestep = LATEST
    []
[]

[BCs]
    [top_s]
        type = DirichletBC
        variable = c_s
        boundary = top
        value = 1
    []
[]

[Kernels]
    # Solvent kernels
    [c_s_dt]
        type = TimeDerivative
        variable = c_s
    []
    [c_s_diff]
        type = MatDiffusion
        variable = c_s
        diffusivity = D_s
    []
    [c_s_react1]
        type = ADMatCoupledForce
        v = c_p1
        variable = c_s
        mat_prop_coef = C_s
        coef = ${fparse -k1}
    []
    [c_s_react2]
        type = ADMatCoupledForce
        v = c_p2
        variable = c_s
        mat_prop_coef = C_s
        coef = ${fparse -k2}
    []
    [c_s_fill]
        type = ADMatCoupledForce
        v = c_v
        variable = c_s
        mat_prop_coef = C_s_bound
        coef = ${fparse kv}
    []
    # Polymer kernels
    [c_p1_dt]
        type = TimeDerivative
        variable = c_p1
    []
    [c_p1_react]
        type = ADMatCoupledForce
        v = c_s
        variable = c_p1
        mat_prop_coef = C_p1
        coef = ${fparse -k1}
    []
    [c_p1_react2]
        type = ADMatCoupledForce
        v = c_t
        variable = c_p1
        mat_prop_coef = C_p1
        coef = ${fparse -kbg}
    []
    [c_p2_dt]
        type = TimeDerivative
        variable = c_p2
    []
    [c_p2_react]
        type = ADMatCoupledForce
        v = c_s
        variable = c_p2
        mat_prop_coef = C_p2
        coef = ${fparse -k2}
    []
    [c_p2_react2]
        type = ADMatCoupledForce
        v = c_t
        variable = c_p2
        mat_prop_coef = C_p2
        coef = ${fparse -kbg}
    []
    # Void kernels
    [c_v_dt]
        type = TimeDerivative
        variable = c_v
    []
    [c_v_react]
        type = ADMatCoupledForce
        v = c_t
        variable = c_v
        mat_prop_coef = C_v
        coef = ${fparse -kbg}
    []
    # Tissue kernels
    [c_t_dt]
        type = TimeDerivative
        variable = c_t
    []
    [c_t_react1]
        type = ADMatCoupledForce
        v = c_p1
        mat_prop_coef = C_s
        variable = c_t
        coef = ${fparse k1}
    []
    [c_t_react2]
        type = ADMatCoupledForce
        v = c_p2
        mat_prop_coef = C_s
        variable = c_t
        coef = ${fparse k2}
    []
    [c_t_react3]
        type = ADMatCoupledForce
        v = 'c_p1 c_p2 c_v'
        mat_prop_coef = C_t
        variable = c_t
        coef = ${fparse kbg}
    []
[]

[Materials]
    # Solvent properties
    [diffusivity_s]
        type = DerivativeParsedMaterial
        property_name = D_s
        coupled_variables = 'c_p1 c_p2 c_t c_v'
        constant_names = 'D_p1 D_p2 D_t D_v'
        constant_expressions = '${D_p1} ${D_p2} ${D_t} ${D_v}'
        expression = 'D_p1*c_p1 + D_p2*c_p2 + D_t*c_t + D_v*c_v'
    []
    # Variables as materials
    [C_s]
        type = ADParsedMaterial
        property_name = C_s
        coupled_variables = 'c_s'
        expression = 'max(c_s, 0)'
    []
    [C_s_bound]
        type = ADParsedMaterial
        property_name = C_s_bound
        coupled_variables = 'c_s'
        expression = 'if(c_s>1e-3, (c_s^0.5)*(1-c_s), 0)'
    []
    [C_p1]
        type = ADParsedMaterial
        property_name = C_p1
        coupled_variables = 'c_p1'
        expression = 'max(c_p1, 0)'
    []
    [C_p2]
        type = ADParsedMaterial
        property_name = C_p2
        coupled_variables = 'c_p2'
        expression = 'max(c_p2, 0)'
    []
    [C_v]
        type = ADParsedMaterial
        property_name = C_v
        coupled_variables = 'c_v'
        expression = 'max(c_v, 0)'
    []
    [C_t]
        type = ADParsedMaterial
        property_name = C_t
        coupled_variables = 'c_t'
        expression = 'max(c_t, 0)'
    []
    [C_bg]
        type = ADParsedMaterial
        property_name = C_bg
        coupled_variables = 'c_p1 c_p2 c_v'
        expression = 'c_p1 + c_p2 + c_v'
        # expression = 'c_p1 + c_p2'
    []
[]

[Preconditioning]
    [coupled]
      type = SMP
      full = true
    []
[]

[Postprocessors]
    [./elapsed]
        type = PerfGraphData
        section_name = "Root"
        data_type = total
    [../]
[]

[Executioner]
    type = Transient
    solve_type = 'NEWTON'
    scheme = bdf2

    petsc_options = '-ksp_converged_reason -snes_converged_reason -snes_ksp_ew'

    # petsc_options_iname = '-pc_type -ksp_type -pc_factor_mat_solver_type'
    # petsc_options_value = 'lu       preonly   mumps'

    petsc_options_iname = '-pc_type -ksp_type'
    petsc_options_value = 'hypre gmres'

    line_search = 'basic'

    l_tol = 1e-10
    l_abs_tol = 1e-10
    l_max_its = 200
    nl_max_its = 20
    nl_abs_tol = 1e-10

    [TimeStepper]
        # Turn on time stepping
        type = IterationAdaptiveDT
        dt = 1.0e-8
        cutback_factor = 0.8
        growth_factor = 1.5
        optimal_iterations = 10
    []

    dtmax = 1e0

    end_time = 1e3 # seconds

    # # Automatic scaling for u and w
    automatic_scaling = true

    # [Adaptivity]
    #     coarsen_fraction = 0.1
    #     refine_fraction = 0.7
    #     max_h_level = 2
    # []
[]

[Times]
  [output_times]
    type = TimeIntervalTimes
    time_interval = 1
    always_include_end_time = true
  []
[]

[Outputs]
    [ex]
        type = Exodus
        file_base = output/pstv_max
        execute_on = 'INITIAL TIMESTEP_END'
        time_step_interval = 1
        # sync_times_object = output_times
        # sync_only = true
    []
[]

# [Debug]
#     show_var_residual_norms = true
# []