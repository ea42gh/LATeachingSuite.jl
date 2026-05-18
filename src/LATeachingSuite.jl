module LATeachingSuite

using Reexport

@reexport using GenLAProblems

module WorkflowDisplay

using Reexport

@reexport using GenLAProblems.WorkflowDisplay

end

module PythonBridge

using Reexport

@reexport using GenLAProblems.PythonBridge

end

const ShowGE = GenLAProblems.ShowGE

function _bundle_result(dict)
    py = GenLAProblems._ensure_pythoncall()
    py_get = Base.invokelatest(py.pygetattr, dict, "get")
    spec = GenLAProblems._pycall(py_get, "spec")
    svg = GenLAProblems._pycall(py_get, "svg")
    if GenLAProblems._py_is_py(svg) && GenLAProblems._py_is_none(svg)
        svg = nothing
    end
    return spec, svg
end

function _bundle_wrapper(bundle_sym::Symbol)
    return function (args...; kwargs...)
        la = GenLAProblems.load_LAFigureSpecs()
        bundle_fn = GenLAProblems._pygetattr(la, bundle_sym)
        spec, svg = _bundle_result(GenLAProblems._pycall(bundle_fn, args...; kwargs...))
        return GenLAProblems._show_svg(svg), spec
    end
end

load_LAFigureSpecs() = GenLAProblems.load_LAFigureSpecs()
load_matrixlayout() = GenLAProblems.load_matrixlayout()
la_version() = GenLAProblems.la_version()
la_build() = GenLAProblems.la_build()
ml_version() = GenLAProblems.ml_version()
ml_build() = GenLAProblems.ml_build()
ref!(args...; kwargs...) = GenLAProblems.ref!(args...; kwargs...)
show_layout!(args...; kwargs...) = GenLAProblems.show_layout!(args...; kwargs...)
show_system(args...; kwargs...) = GenLAProblems.show_system(args...; kwargs...)
create_cascade!(args...; kwargs...) = GenLAProblems.create_cascade!(args...; kwargs...)
show_backsubstitution!(args...; kwargs...) = GenLAProblems.show_backsubstitution!(args...; kwargs...)
show_solution!(args...; kwargs...) = GenLAProblems.show_solution!(args...; kwargs...)
show_backsubstitution(args...; kwargs...) = GenLAProblems.show_backsubstitution(args...; kwargs...)
show_forwardsubstitution(args...; kwargs...) = GenLAProblems.show_forwardsubstitution(args...; kwargs...)
show_solution(args...; kwargs...) = GenLAProblems.show_solution(args...; kwargs...)
solutions(args...; kwargs...) = GenLAProblems.solutions(args...; kwargs...)
rhs_block(args...; kwargs...) = GenLAProblems.rhs_block(args...; kwargs...)
show_ge_final(args...; kwargs...) = GenLAProblems.show_ge_final(args...; kwargs...)
ge_svg(args...; kwargs...) = GenLAProblems._nm_ge_svg(args...; kwargs...)
qr_svg(args...; kwargs...) = GenLAProblems._nm_qr_svg(args...; kwargs...)
qr_figure(args...; kwargs...) = GenLAProblems._nm_gram_schmidt_qr(args...; kwargs...)
show_svg(args...; kwargs...) = GenLAProblems.show_svg(args...; kwargs...)
py_show_svg(args...; kwargs...) = GenLAProblems.py_show_svg(args...; kwargs...)
l_show_svd(args...; kwargs...) = GenLAProblems.l_show_svd(args...; kwargs...)
ge_bundle(args...; kwargs...) = _bundle_wrapper(:ge_tbl_bundle)(args...; kwargs...)
qr_bundle(args...; kwargs...) = _bundle_wrapper(:qr_tbl_bundle)(args...; kwargs...)
eig_bundle(args...; kwargs...) = _bundle_wrapper(:eig_tbl_bundle)(args...; kwargs...)
svd_bundle(args...; kwargs...) = _bundle_wrapper(:svd_tbl_bundle)(args...; kwargs...)

export WorkflowDisplay, PythonBridge, ShowGE
export load_LAFigureSpecs, load_matrixlayout
export la_version, la_build, ml_version, ml_build
export ref!, show_layout!, show_system, create_cascade!
export show_backsubstitution!, show_solution!
export show_backsubstitution, show_forwardsubstitution, show_solution
export solutions, rhs_block, show_ge_final
export ge_svg, qr_svg, qr_figure
export show_svg, py_show_svg, l_show_svd
export ge_bundle, qr_bundle, eig_bundle, svd_bundle

end
