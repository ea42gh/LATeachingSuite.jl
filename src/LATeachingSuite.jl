module LATeachingSuite

using Reexport
using LinearAlgebra
using LAlatex
using LaTeXStrings: LaTeXString

let pycall_exe = get(ENV, "JULIA_PYTHONCALL_EXE", "")
    if isempty(pycall_exe) || !isfile(pycall_exe)
        py = get(ENV, "PYTHON", "")
        if isempty(py) || !isfile(py)
            py = something(Sys.which("python3"), "")
        end
        ENV["JULIA_PYTHONCALL_EXE"] = py
    end
end

using PythonCall

@reexport using LAlatex
@reexport using GenLAProblems

ensure_pythoncall!() = GenLAProblems.ensure_pythoncall!()
load_LAFigureSpecs() = GenLAProblems.load_LAFigureSpecs()
load_matrixlayout() = GenLAProblems.load_matrixlayout()
la_version() = GenLAProblems.la_version()
la_build() = GenLAProblems.la_build()
ml_version() = GenLAProblems.ml_version()
ml_build() = GenLAProblems.ml_build()
materialize_python_value(x) = GenLAProblems.materialize_python_value(x)
mm_to_px(mm::Real) = GenLAProblems.mm_to_px(mm)
px_to_mm(px::Real) = GenLAProblems.px_to_mm(px)

is_none_val(x) = GenLAProblems.is_none_val(x)
_ensure_pythoncall() = GenLAProblems._ensure_pythoncall()
_pyimport(name::String) = GenLAProblems._pyimport(name)
_pycall(f, args...; kwargs...) = GenLAProblems._pycall(f, args...; kwargs...)
_pygetattr(obj, name::Symbol) = GenLAProblems._pygetattr(obj, name)
_pygetattr_fallback(obj, name::Symbol, mod::String) = GenLAProblems._pygetattr_fallback(obj, name, mod)
_py_is_none(x) = GenLAProblems._py_is_none(x)
_py_is_py(x) = GenLAProblems._py_is_py(x)
_ensure_blockarrays() = GenLAProblems._ensure_blockarrays()
_ensure_symbolics() = GenLAProblems._ensure_symbolics()
_normalize_render_opts(args...; kwargs...) = GenLAProblems._normalize_render_opts(args...; kwargs...)

const _LAFigureSpecs = GenLAProblems._LAFigureSpecs
const _matrixlayout = GenLAProblems._matrixlayout
const _sympy = GenLAProblems._sympy

const sympy = GenLAProblems.sympy
const nM = GenLAProblems.nM

include("DisplayInterop.jl")
include("SolveProblems.jl")
include("ge.jl")

module WorkflowDisplay

using Reexport

@reexport using ..LATeachingSuite:
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
    px_to_mm

end

module PythonBridge

using Reexport

@reexport using ..LATeachingSuite:
    ensure_pythoncall!,
    load_LAFigureSpecs,
    load_matrixlayout,
    la_version,
    la_build,
    ml_version,
    ml_build,
    materialize_python_value,
    sympy

end

function _bundle_result(dict)
    py_get = Base.invokelatest(PythonCall.pygetattr, dict, "get")
    spec = _pycall(py_get, "spec")
    svg = _pycall(py_get, "svg")
    render_error = _pycall(py_get, "render_error")
    if _py_is_py(svg) && _py_is_none(svg)
        svg = nothing
    end
    if _py_is_py(render_error) && _py_is_none(render_error)
        render_error = nothing
    end
    return spec, svg, render_error
end

function _bundle_wrapper(bundle_sym::Symbol)
    return function (args...; kwargs...)
        la = load_LAFigureSpecs()
        bundle_fn = _pygetattr(la, bundle_sym)
        spec, svg, render_error = _bundle_result(_pycall(bundle_fn, args...; kwargs...))
        if render_error !== nothing
            msg = materialize_python_value(render_error)
            if !(msg isa AbstractString)
                msg = string(msg)
            end
            error("LAFigureSpecs.$bundle_sym render failed.\n$msg")
        end
        return _show_svg(svg), spec
    end
end

const _ge_bundle = _bundle_wrapper(:ge_bundle)
const _qr_bundle = _bundle_wrapper(:qr_bundle)
const _eig_bundle = _bundle_wrapper(:eig_bundle)
const _svd_bundle = _bundle_wrapper(:svd_bundle)

ge_svg(args...; kwargs...) = matrixlayout_ge(args...; kwargs...)
qr_svg(args...; kwargs...) = first(qr_bundle(args...; kwargs...))

_spec_get(spec, key::AbstractString) = spec isa AbstractDict ? spec[key] : spec[key]
_spec_list(spec, key::AbstractString) = collect(materialize_python_value(_spec_get(spec, key)))

function _spec_values_equal(a, b)
    a2 = materialize_python_value(a)
    b2 = materialize_python_value(b)
    if a2 == b2
        return true
    end
    try
        return materialize_python_value(sympy.simplify(a2 - b2)) == 0
    catch
        return string(a2) == string(b2)
    end
end

function qr_matrices_from_spec(spec)
    matrices = _spec_get(spec, "matrices")
    mats = materialize_python_value(matrices)
    row1, row2, row3 = (collect(r) for r in mats)
    A = row1[3]
    W = row1[4]
    WtA = row2[3]
    WtW = row2[4]
    S = row3[1]
    Qt = row3[2]
    R = row3[3]
    Q = Qt === nothing ? nothing : transpose(Qt)
    return (A=A, W=W, WtA=WtA, WtW=WtW, S=S, Qt=Qt, Q=Q, R=R)
end

eig_matrices_from_spec(spec; kwargs...) = GenLAProblems.eig_matrices_from_spec(spec; kwargs...)
svd_matrices_from_spec(spec; kwargs...) = GenLAProblems.svd_matrices_from_spec(spec; kwargs...)

function eig_eigenvalues(spec)
    lambdas = _spec_list(spec, "lambda")
    mas = [Int(m) for m in _spec_list(spec, "ma")]
    return collect(zip(mas, lambdas))
end

function eig_eigenvectors(spec, λ; orthonormal::Bool=true)
    lambdas = _spec_list(spec, "lambda")
    vec_key = orthonormal ? "qvecs" : "evecs"
    groups = haskey(materialize_python_value(spec), vec_key) ? _spec_list(spec, vec_key) : _spec_list(spec, "evecs")
    for (lam, grp) in zip(lambdas, groups)
        if _spec_values_equal(lam, λ)
            return grp
        end
    end
    return nothing
end

function svd_singular_values(spec)
    sigmas = _spec_list(spec, "sigma")
    mas = [Int(m) for m in _spec_list(spec, "ma")]
    return collect(zip(mas, sigmas))
end

function svd_rank(spec)
    sigmas = _spec_list(spec, "sigma")
    mas = [Int(m) for m in _spec_list(spec, "ma")]
    rank = 0
    for (σ, m) in zip(sigmas, mas)
        if !_spec_values_equal(σ, 0)
            rank += m
        end
    end
    return rank
end

function svd_left_vectors(spec, σ)
    sigmas = _spec_list(spec, "sigma")
    groups = _spec_list(spec, "uvecs")
    for (sigma, grp) in zip(sigmas, groups)
        if _spec_values_equal(sigma, σ)
            return grp
        end
    end
    return nothing
end

function svd_right_vectors(spec, σ; orthonormal::Bool=true)
    sigmas = _spec_list(spec, "sigma")
    vec_key = orthonormal ? "qvecs" : "evecs"
    groups = _spec_list(spec, vec_key)
    for (sigma, grp) in zip(sigmas, groups)
        if _spec_values_equal(sigma, σ)
            return grp
        end
    end
    return nothing
end

function eig_svg(args...; kwargs...)
    la = load_LAFigureSpecs()
    svg_fn = _pygetattr(la, :eig_svg)
    return _show_svg(_pycall(svg_fn, args...; kwargs...))
end

function svd_svg(args...; kwargs...)
    la = load_LAFigureSpecs()
    svg_fn = _pygetattr(la, :svd_svg)
    return _show_svg(_pycall(svg_fn, args...; kwargs...))
end

ge_bundle(args...; kwargs...) = _ge_bundle(args...; kwargs...)
qr_bundle(args...; kwargs...) = _qr_bundle(args...; kwargs...)
eig_bundle(args...; kwargs...) = _eig_bundle(args...; kwargs...)
svd_bundle(args...; kwargs...) = _svd_bundle(args...; kwargs...)

export WorkflowDisplay, PythonBridge, ShowGE
export load_LAFigureSpecs, load_matrixlayout
export la_version, la_build, ml_version, ml_build
export split_R_RHS, particular_solution, homogeneous_solutions
export normal_eq_reduce_to_ref, reduce_to_ref
export ref!, show_layout!, show_system, create_cascade!
export show_backsubstitution!, show_solution!
export show_backsubstitution, show_forwardsubstitution, show_solution
export solutions, rhs_block
export ge_svg, qr_svg, eig_svg, svd_svg
export show_svg, py_show_svg, l_show_svd
export ge_bundle, qr_bundle, eig_bundle, svd_bundle
export qr_matrices_from_spec, eig_matrices_from_spec, svd_matrices_from_spec
export eig_eigenvalues, svd_singular_values
export svd_rank, eig_eigenvectors, svd_left_vectors, svd_right_vectors

end
