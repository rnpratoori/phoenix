nx = 50     # number of elements per side
ny = 25     # number of elements per side
dx = 2       # ND size of the side
dy = 1       # ND size of the side

k1 = 2
k2 = 1
# kv = 100
D_p1 = 5
D_p2 = 1
D_t = 10
D_v = 100


[GlobalParams]
    displacements = 'disp_x disp_y'
    large_kinematics = true
[]

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
        threshold = 0
        execute_on = 'INITIAL TIMESTEP_BEGIN'
        force_preic = false
        allow_duplicate_execution_on_initial = true
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
    [disp_x]
    []
    [disp_y]
    []
[]

[AuxVariables]
    [stress_xx]
        order = CONSTANT
        family = MONOMIAL
    []
    [stress_max]
        order = CONSTANT
        family = MONOMIAL
    []
    [stress_min]
        order = CONSTANT
        family = MONOMIAL
    []
    [theta]
        order = CONSTANT
        family = MONOMIAL
    []
[]

[AuxKernels]
    [stress_xx]
      type = RankTwoAux
      variable = stress_xx
      rank_two_tensor = cauchy_stress
      index_i = 0
      index_j = 0
      execute_on = 'timestep_end'
    []
    [stress_max]
        type = RankTwoScalarAux
        rank_two_tensor = cauchy_stress
        variable = stress_max
        scalar_type = MaxPrincipal
    []
    [stress_min]
        type = RankTwoScalarAux
        rank_two_tensor = cauchy_stress
        variable = stress_min
        scalar_type = MinPrincipal
    []
    [theta]
        type = ParsedAux
        coupled_variables = 'stress_max stress_min'
        expression = 'atan(stress_max/(stress_min + 1e-10))'
        variable = theta
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
    # Mechanical
    [left_symmetry]
        type = DirichletBC
        variable = disp_x
        boundary = left
        value = 0
    []
    [right_load]
        type = Pressure
        variable = disp_x
        boundary = right
        factor = -1e9
    []
    [bottom_fix]
        type = DirichletBC
        variable = disp_y
        boundary = bottom
        value = 0
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
        mat_prop_coef = kbg
        coef = -1
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
        mat_prop_coef = kbg
        coef = -1
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
        mat_prop_coef = kbg
        coef = -1
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
        coef = ${k1}
    []
    [c_t_react2]
        type = ADMatCoupledForce
        v = c_p2
        mat_prop_coef = C_s
        variable = c_t
        coef = ${k2}
    []
    [c_t_react3]
        type = ADMatReaction
        reaction_rate = kb
        variable = c_t
    []
    # Mechanical Kernels
    [sdx]
      type = TotalLagrangianStressDivergence
      variable = disp_x
      component = 0
    []
    [sdy]
      type = TotalLagrangianStressDivergence
      variable = disp_y
      component = 1
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
        expression = 'c_s'
    []
    [C_p1]
        type = ADParsedMaterial
        property_name = C_p1
        coupled_variables = 'c_p1'
        expression = 'c_p1'
    []
    [C_p2]
        type = ADParsedMaterial
        property_name = C_p2
        coupled_variables = 'c_p2'
        expression = 'c_p2'
    []
    [C_v]
        type = ADParsedMaterial
        property_name = C_v
        coupled_variables = 'c_v'
        expression = 'c_v'
    []
    [kbg]
        type = ADParsedMaterial
        property_name = kbg
        coupled_variables = 'theta'
        expression = '1 + cos(theta)^2'
    []
    [kbd]
        type = ADParsedMaterial
        property_name = kbd
        expression = -1
    []
    [kb]
        type = ADDerivativeSumMaterial
        property_name = kb
        coupled_variables = 'theta'
        sum_materials = 'kbg kbd'
    []
    # Mechanical properties
    [strain]
        type = ComputeLagrangianStrain
    []
    [hyperelastic]
        type = ComputeNeoHookeanStress
        lambda = 1e9
        mu = 1e9
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
    [reaction_force_x]
        type        = SideIntegralVariablePostprocessor
        variable    = stress_xx
        boundary    = right
        execute_on  = 'timestep_end'
    []
    [avg_disp_right]
      type = SideAverageValue
      variable = disp_x
      boundary = right
      execute_on = 'timestep_end'
    []
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
        file_base = output/pstvm
        time_step_interval = 1
        execute_on = 'INITIAL TIMESTEP_END'
    []
[]

[Debug]
    show_material_props = true
[]