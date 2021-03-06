[Mesh]
  type = FileMesh
  boundary_name = 'bottom top inside outside'
  boundary_id = '109 110 112 111'
  file = Cylinder_quarter_smooth_thick1.msh
[]

[GlobalParams]
  displacements = 'disp_x disp_y'
  porepressure = 'porepressure'
  block = '0'
[]

[Variables]
  inactive = 'disp_z'
  [disp_x]
  []
  [disp_y]
  []
  [disp_z]
    block = '0'
  []
  [porepressure]
    scaling = '1E9' # Notice the scaling, to make porepressure's kernels roughly of same magnitude as disp's kernels
  []
  [damage]
  []
  [temperature]
    block = '0 '
  []
[]

[AuxVariables]
  [stress_r_r]
    order = CONSTANT
    family = MONOMIAL
  []
  [stress_theta_theta]
    order = CONSTANT
    family = MONOMIAL
  []
  [stress_r_theta]
    order = CONSTANT
    family = MONOMIAL
  []
  [strain_r_r]
    order = CONSTANT
    family = MONOMIAL
  []
  [strain_theta_theta]
    order = CONSTANT
    family = MONOMIAL
  []
  [strain_r_theta]
    order = CONSTANT
    family = MONOMIAL
  []
  [mech_dissip]
    order = CONSTANT
    family = MONOMIAL
  []
[]

[Functions]
  inactive = 'temp_ic'
  [temp_ic]
    type = ParsedFunction
    value = 'sqrt(x*x+y*y)/0.9 - 1/9' # -sqrt(x*x+y*y)/0.9 + 10/9
  []
  [inner_pressure_fct]
    type = ParsedFunction
    value = '1e-3+4e-2*t' # 1e-3+4e-2*t
  []
  [timestep_function]
    # max(1e-7,min(1e1, dt*max(0.2,1-5*(T-T_old-0.2))))
    #
    # max(1e-7,min(1e-2, dt*max(0.1,0.1-5*(T-T_old-0.2))))
    #
    # if(T>3.5, 1e-5, max(1e-7,min(1e-2, dt*max(0.2,1-5*(T-T_old-0.2)))))
    # if(t>0.0169, 1e-7, if(t>0.0168, 2e-6, max(1e-7,min(1e-2, dt*max(0.2, 1-5*(T-T_old-0.2))))))
    type = ParsedFunction
    value = '2e-4' # if(t<0.07, 2e-3, 5e-4)
  []
  [outer_pressure_fct]
    type = ParsedFunction
    value = '1e-3'
  []
[]

[Kernels]
  inactive = 'poromech damage_kernel diff_temp'
  [dp_dt]
    type = TimeDerivative
    variable = porepressure
  []
  [mass_diff]
    type = RedbackMassDiffusion
    variable = porepressure
  []
  [poromech]
    type = RedbackPoromechanics
    variable = porepressure
    block = '0'
  []
  [damage_dt]
    type = TimeDerivative
    variable = damage
  []
  [damage_kernel]
    type = RedbackDamage
    variable = damage
  []
  [dt_temp]
    type = TimeDerivative
    variable = temperature
  []
  [diff_temp]
    type = RedbackThermalDiffusion
    variable = temperature
    time_factor = 1e-3
  []
  [mech_dissip]
    type = RedbackMechDissip
    variable = temperature
  []
  [Thermal_press]
    type = RedbackThermalPressurization
    variable = porepressure
    temperature = 'temperature'
  []
[]

[AuxKernels]
  [plastic_strain_r_r]
    type = RedbackPolarTensorMaterialAux
    variable = strain_r_r
    rank_two_tensor = plastic_strain
    index_j = 0
    index_i = 0
  []
  [plastic_strain_r_theta]
    type = RedbackPolarTensorMaterialAux
    variable = strain_r_theta
    rank_two_tensor = plastic_strain
    index_j = 1
    index_i = 0
  []
  [plastic_strain_theta_theta]
    type = RedbackPolarTensorMaterialAux
    variable = strain_theta_theta
    rank_two_tensor = plastic_strain
    index_j = 1
    index_i = 1
  []
  [stress_r_r]
    type = RedbackPolarTensorMaterialAux
    variable = stress_r_r
    rank_two_tensor = stress
    index_j = 0
    index_i = 0
  []
  [stress_r_theta]
    type = RedbackPolarTensorMaterialAux
    variable = stress_r_theta
    rank_two_tensor = stress
    index_j = 1
    index_i = 0
  []
  [stress_theta_theta]
    type = RedbackPolarTensorMaterialAux
    variable = stress_theta_theta
    rank_two_tensor = stress
    index_j = 1
    index_i = 1
  []
  [mech_dissip]
    type = MaterialRealAux
    variable = mech_dissip
    property = mechanical_dissipation_mech
  []
[]

[BCs]
  [Pressure]
    [press_outer]
      function = outer_pressure_fct
      boundary = '2'
      disp_y = 'disp_y'
      disp_x = 'disp_x'
    []
    [press_inner]
      function = inner_pressure_fct
      boundary = '0'
      disp_y = 'disp_y'
      disp_x = 'disp_x'
    []
  []
  [confine_x]
    type = DirichletBC
    variable = disp_x
    boundary = '3'
    value = 0
  []
  [confine_y]
    type = DirichletBC
    variable = disp_y
    boundary = '1'
    value = 0
  []
[]

[Materials]
  [no_mech]
    type = RedbackMaterial
    solid_compressibility = 1000
    gr = 5e3
    disp_y = 'disp_y'
    disp_x = 'disp_x'
    pore_pres = 'porepressure'
    pressurization_coefficient = 1e-3 # 1e-7
    ar = 10
    total_porosity = '0.1'
    temperature = 'temperature'
    phi0 = 0.1
    is_mechanics_on = true
    fluid_thermal_expansion = 1e-1 # 0
    inverse_lewis_number_tilde = 'porepressure'
  []
  [plastic_material]
    type = RedbackMechMaterialDP
    disp_y = 'disp_y'
    disp_x = 'disp_x'
    pore_pres = 'porepressure'
    damage = 'damage'
    yield_stress = '0 0.001 0.1 0.0008' # 0 0.006 1 0.006
    damage_coefficient = 3e3
    damage_method = BrittleDamage
    poisson_ratio = 0.25
    youngs_modulus = 100
    temperature = 'temperature'
  []
[]

[Postprocessors]
  inactive = 'max_temp max_temp_old nli nnli'
  [max_temp]
    type = NodalMaxValue
    variable = 'temperature'
  []
  [new_timestep]
    type = FunctionValuePostprocessor
    function = timestep_function
  []
  [max_temp_old]
    type = NodalMaxValue
    variable = 'temperature'
    execute_on = 'timestep_begin'
  []
  [old_timestep]
    type = TimestepSize
    execute_on = 'timestep_begin'
  []
  [max_r_theta]
    type = ElementExtremeValue
    variable = 'strain_r_theta'
  []
  [nli]
    type = NumLinearIterations
  []
  [nnli]
    type = NumNonlinearIterations
  []
  [avg_dissip]
    type = ElementAverageValue
    variable = 'mech_dissip'
  []
  [disp_hole_x]
    type = PointValue
    variable = disp_x
    point = '0.1 0 0'
  []
  [Num_elements]
    type = NumElems
  []
[]

[Preconditioning]
  inactive = 'SMP'
  [andy]
    type = SMP
    line_search = 'basic'
    full = true
    solve_type = NEWTON
    petsc_options = '-snes_monitor   -snes_linesearch_monitor   -ksp_monitor'
    petsc_options_iname = '-ksp_type -pc_type  -snes_atol -snes_rtol -snes_max_it -ksp_max_it -ksp_atol -sub_pc_type -sub_pc_factor_shift_type'
    petsc_options_value = 'gmres        asm        1E-10          1E-5        200                500                  1e-8        lu                      NONZERO'
  []
  [SMP]
    type = SMP
    full = true
    solve_type = PJFNK
    petsc_options_iname = '-ksp_type -pc_type -sub_pc_type -ksp_gmres_restart -ksp_atol'
    petsc_options_value = 'gmres asm lu 201 1e-8'
  []
[]

[Executioner]
  # [./TimeStepper]
  # type = PostprocessorDT
  # postprocessor = dt
  # dt = 0.003
  # [../]
  type = Transient
  end_time = 10.0 # 0.2
  dt = 1e-3 # 1e-5
  l_tol = 1e-5 # 1e-05
  [TimeStepper]
    type = ConstantDT
    dt = 1e-3
    growth_factor = 2
  []
[]

[Outputs]
  exodus = true
  execute_on = 'timestep_end initial'
  file_base = Cylinder_quarter_smooth_thicker_1
[]

[ICs]
  inactive = 'random_dmg_IC'
  [random_temp_IC]
    type = RandomIC
    variable = temperature
    seed = 40
  []
  [random_dmg_IC]
    type = RandomIC
    variable = damage
  []
[]

[RedbackMechAction]
  [mechanics]
    temp = temperature
    pore_pres = porepressure
    disp_y = disp_y
    disp_x = disp_x
  []
[]
