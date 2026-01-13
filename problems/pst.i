nx = 200     # number of elements per side
ny = 100     # number of elements per side
dx = 2       # ND size of the side
dy = 1       # ND size of the side

k = 1
D_p = 1
D_t = 10


[Mesh]
    # [2p]
        # generate a 2D mesh
        type = GeneratedMesh
        dim = 2
        nx = ${nx}
        ny = ${ny}
        xmax = ${dx}
        ymax = ${dy}
    # []
[]

[Variables]
    # solvent volume fraction
    [c_s]
    []
    # polymer volume fraction
    [c_p]
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
    [c_p]
        type = ConstantIC
        value = 1
        variable = c_p
    []
    [c_t]
        type = ConstantIC
        value = 0
        variable = c_t
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
    [c_s_react]
        type = ADMatCoupledForce
        v = c_p
        variable = c_s
        mat_prop_coef = C_s
        coef = ${fparse -k}
    []
    # Polymer kernels
    [c_p_dt]
        type = TimeDerivative
        variable = c_p
    []
    [c_p_react]
        type = ADMatCoupledForce
        v = c_s
        variable = c_p
        mat_prop_coef = C_p
        coef = ${fparse -k}
    []
    # Tissue kernels
    [c_t_dt]
        type = TimeDerivative
        variable = c_t
    []
    [c_t_react]
        type = ADMatCoupledForce
        v = c_p
        mat_prop_coef = C_s
        variable = c_t
        coef = ${k}
    []
[]

[Materials]
    # Solvent properties
    [diffusivity_s]
        type = DerivativeParsedMaterial
        property_name = D_s
        coupled_variables = 'c_p c_t'
        constant_names = 'D_p D_t'
        constant_expressions = '${D_p} ${D_t}'
        expression = 'D_p*c_p + D_t*c_t'
    []
    # Tissue properties
    [reaction_t]
        type = ADParsedMaterial
        property_name = C_ps
        coupled_variables = 'c_p c_s'
        expression = 'c_p*c_s'
    []
    # Variables as materials
    [C_s]
        type = ADParsedMaterial
        property_name = C_s
        coupled_variables = 'c_s'
        expression = 'c_s'
    []
    [C_p]
        type = ADParsedMaterial
        property_name = C_p
        coupled_variables = 'c_p'
        expression = 'c_p'
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

    petsc_options = '-ksp_converged_reason -snes_converged_reason -snes_ksp_ew '

    petsc_options_iname = '-pc_type -ksp_type -pc_factor_mat_solver_type'
    petsc_options_value = 'lu       preonly   mumps'

    line_search = 'basic'

    l_tol = 1e-10
    l_abs_tol = 1e-10
    l_max_its = 200
    nl_max_its = 100
    nl_abs_tol = 1e-10

    [TimeStepper]
        # Turn on time stepping
        type = IterationAdaptiveDT
        dt = 1.0e-8
        cutback_factor = 0.8
        growth_factor = 1.5
        optimal_iterations = 10
    []

    dtmax = 1e-2

    end_time = 1e0 # seconds

    # # Automatic scaling for u and w
    automatic_scaling = true

    # [Adaptivity]
    #     coarsen_fraction = 0.1
    #     refine_fraction = 0.7
    #     max_h_level = 2
    # []
[]

[Outputs]
    [ex]
        type = Exodus
        file_base = output/pst_t1
        time_step_interval = 1
        execute_on = 'INITIAL TIMESTEP_END'
    []
[]

# [Debug]
#     show_var_residual_norms = true
# []