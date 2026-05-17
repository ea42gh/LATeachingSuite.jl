module LATeachingSuite

using Reexport

@reexport using GenLAProblems

module WorkflowDisplay

using Reexport

@reexport using GenLAProblems: (
    ShowGE,
    ref!,
    show_layout!,
    show_system,
    create_cascade!,
    show_backsubstitution!,
    show_solution!,
    show_backsubstitution,
    show_forwardsubstitution,
    show_solution,
    solutions,
    rhs_block,
    show_ge_final,
    py_show_svg,
    show_svg,
    l_show_svd,
    nM,
    mm_to_px,
    px_to_mm,
)

end

module PythonBridge

using Reexport

@reexport using GenLAProblems: (
    ensure_pythoncall!,
    load_LAFigureSpecs,
    load_matrixlayout,
    la_version,
    la_build,
    ml_version,
    ml_build,
    materialize_python_value,
    sympy,
    svd_matrices_from_spec,
    eig_matrices_from_spec,
    qr_matrices_from_grid,
    qr_matrices_dict_from_grid,
)

end

export WorkflowDisplay, PythonBridge

end
