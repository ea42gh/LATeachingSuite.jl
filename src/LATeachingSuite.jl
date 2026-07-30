module LATeachingSuite

using Reexport
using LinearAlgebra
using AbstractAlgebra
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
using BlockArrays

@reexport using LAlatex
@reexport using GenLAProblems

is_none_val(x) = GenLAProblems.is_none_val(x)

const _symbolics_mod = Ref{Any}(nothing)

function _ensure_symbolics()
    if _symbolics_mod[] === nothing
        @eval import Symbolics
        _symbolics_mod[] = Base.invokelatest(() -> Symbolics)
    end
    return _symbolics_mod[]
end

ensure_pythoncall!() = PythonCall
_ensure_pythoncall() = PythonCall
_pyimport(name::String) = Base.invokelatest(PythonCall.pyimport, name)
_pycall(f, args...; kwargs...) = Base.invokelatest(PythonCall.pycall, f, args...; kwargs...)
_pygetattr(obj, name::Symbol) = Base.invokelatest(PythonCall.pygetattr, obj, String(name))

const _LAFigureSpecs = Ref{Any}(nothing)
const _matrixlayout = Ref{Any}(nothing)
const _sympy = Ref{Any}(nothing)

include("PythonBridgeUtils.jl")
include("SymPyHelpers.jl")
@reexport using .SymPyHelpers
using .SymPyHelpers: sym_to_julia_vec, sym_to_julia_mat

function Base.getproperty(::SympyProxy, name::Symbol)
    if _sympy[] === nothing
        _sympy[] = _pyimport("sympy")
    end
    attr = _pygetattr(_sympy[], name)
    builtins = _pyimport("builtins")
    if Base.invokelatest(PythonCall.pyconvert, Bool, _pycall(builtins.callable, attr))
        return (args...; kwargs...) -> _pycall(attr, args...; kwargs...)
    end
    return attr
end

mm_to_px(mm::Real) = float(mm) * 96.0 / 25.4
px_to_mm(px::Real) = float(px) * 25.4 / 96.0

_removed_artifact_keyword_error() = ArgumentError("Removed artifact keyword: tmp_dir. Use output_dir instead.")
_removed_tex_hook_error() = ArgumentError("Removed TeX hook keyword: preamble/extension. Use body_preamble/document_preamble instead.")
_reject_removed_artifact_keyword(kwargs) = haskey(kwargs, :tmp_dir) && throw(_removed_artifact_keyword_error())
function _reject_removed_tex_hook_keywords(kwargs)
    if haskey(kwargs, :preamble) || haskey(kwargs, :extension)
        throw(_removed_tex_hook_error())
    end
end

_ensure_blockarrays() = BlockArrays

function _py_is_none(x)
    if !isdefined(@__MODULE__, :PythonCall)
        return false
    end
    try
        Base.invokelatest(PythonCall.pyconvert, Any, x) === nothing
    catch
        false
    end
end

_py_is_py(x) = x isa PythonCall.Py

function _is_missing_python_module(err, module_name::AbstractString)
    msg = sprint(showerror, err)
    return occursin("ModuleNotFoundError", msg) && occursin("No module named '$module_name'", msg)
end

function load_LAFigureSpecs()
    if _LAFigureSpecs[] === nothing
        pc = _ensure_pythoncall()
        if pc === nothing
            return nothing
        end
        try
            _LAFigureSpecs[] = Base.invokelatest(pc.pyimport, "LAFigureSpecs")
        catch err
            if _is_missing_python_module(err, "LAFigureSpecs")
                error(
                    "Python module `LAFigureSpecs` is required by LATeachingSuite.\n" *
                    "Install it in the active Python environment.\n\n" *
                    "Original error:\n$err"
                )
            end
            rethrow(err)
        end
    end
    return _LAFigureSpecs[]
end

function load_matrixlayout()
    if _matrixlayout[] === nothing
        pc = _ensure_pythoncall()
        if pc === nothing
            return nothing
        end
        try
            _matrixlayout[] = Base.invokelatest(pc.pyimport, "matrixlayout")
        catch err
            if _is_missing_python_module(err, "matrixlayout")
                error(
                    "Python module `matrixlayout` is required by LATeachingSuite.\n" *
                    "Install it in the active Python environment.\n\n" *
                    "Original error:\n$err"
                )
            end
            rethrow(err)
        end
    end
    return _matrixlayout[]
end

function la_version()
    v = _pygetattr(load_LAFigureSpecs(), :__version__)
    return Base.invokelatest(PythonCall.pyconvert, String, v)
end

function la_build()
    v = _pygetattr(load_LAFigureSpecs(), :__build__)
    return Base.invokelatest(PythonCall.pyconvert, String, v)
end

function ml_version()
    v = _pygetattr(load_matrixlayout(), :__version__)
    return Base.invokelatest(PythonCall.pyconvert, String, v)
end

function ml_build()
    v = _pygetattr(load_matrixlayout(), :__build__)
    return Base.invokelatest(PythonCall.pyconvert, String, v)
end

function materialize_python_value(x)
    if x isa NamedTuple
        return (; (name => materialize_python_value(value) for (name, value) in pairs(x))...)
    elseif !_py_is_py(x)
        if x isa AbstractDict
            return Dict(materialize_python_value(k) => materialize_python_value(v) for (k, v) in pairs(x))
        elseif x isa Tuple
            return tuple((materialize_python_value(v) for v in x)...)
        elseif x isa AbstractArray
            return map(materialize_python_value, x)
        end
        return x
    end

    if _py_is_none(x)
        return nothing
    end

    converted = try
        Base.invokelatest(PythonCall.pyconvert, Any, x)
    catch
        x
    end

    if converted !== x
        return materialize_python_value(converted)
    end

    for T in (String, Int, Float64, Bool)
        try
            return Base.invokelatest(PythonCall.pyconvert, T, x)
        catch
        end
    end

    try
        shape = Base.invokelatest(PythonCall.pygetattr, x, "shape")
        shp = Base.invokelatest(PythonCall.pyconvert, Tuple, shape)
        if length(shp) == 2
            return map(materialize_python_value, sym_to_julia_mat(x))
        elseif length(shp) == 1
            return map(materialize_python_value, sym_to_julia_vec(x))
        end
    catch
    end

    try
        items_fn = Base.invokelatest(PythonCall.pygetattr, x, "items")
        items = _pycall(items_fn)
        pairs_vec = Base.invokelatest(PythonCall.pyconvert, Vector{Any}, items)
        return Dict(
            begin
                pair_t = Base.invokelatest(PythonCall.pyconvert, Tuple, pair)
                materialize_python_value(pair_t[1]) => materialize_python_value(pair_t[2])
            end for pair in pairs_vec
        )
    catch
    end

    try
        tup = Base.invokelatest(PythonCall.pyconvert, Tuple, x)
        return tuple((materialize_python_value(v) for v in tup)...)
    catch
    end

    try
        vec = Base.invokelatest(PythonCall.pyconvert, Vector{Any}, x)
        return map(materialize_python_value, vec)
    catch
    end

    return x
end

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
    lhs_matrix,
    rhs_matrix,
    rhs_column,
    ge_decorations,
    py_show_svg,
    show_svg,
    l_show_svd,
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
        _reject_removed_artifact_keyword(kwargs)
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

function _split_qr_figure_kwargs(kwargs)
    matrices_keys = Set([:allow_rank_deficient, :rank_deficient])
    spec_keys = Set([
        :array_names,
        :fig_scale,
        :body_preamble,
        :document_preamble,
        :nice_options,
        :label_color,
        :label_text_color,
        :known_zero_color,
        :decorators,
        :strict,
    ])
    render_keys = Set([
        :formatter,
        :toolchain_name,
        :crop,
        :padding,
        :frame,
        :exact_bbox,
        :output_dir,
        :output_stem,
        :render_opts,
        :strict,
    ])
    matrices_kw = Dict{Symbol,Any}()
    spec_kw = Dict{Symbol,Any}()
    render_kw = Dict{Symbol,Any}()
    for (k, v) in kwargs
        k === :tmp_dir && throw(_removed_artifact_keyword_error())
        if k === :preamble || k === :extension
            _reject_removed_tex_hook_keywords(kwargs)
        elseif k === :strict
            spec_kw[k] = v
            render_kw[k] = v
        elseif k in render_keys
            render_kw[k] = v
        elseif k in spec_keys
            spec_kw[k] = v
        elseif k in matrices_keys
            matrices_kw[k] = v
        else
            spec_kw[k] = v
        end
    end
    return matrices_kw, spec_kw, render_kw
end

function _render_qr_from_spec(spec; render_kw...)
    render_qr_svg = _pygetattr(load_matrixlayout(), :render_qr_svg)
    return _pycall(render_qr_svg; spec=spec, render_kw...)
end

const _ge_bundle = _bundle_wrapper(:ge_bundle)
const _qr_bundle = _bundle_wrapper(:qr_bundle)
const _eig_bundle = _bundle_wrapper(:eig_bundle)
const _svd_bundle = _bundle_wrapper(:svd_bundle)

ge_svg(args...; kwargs...) = _matrixlayout_ge(args...; kwargs...)
qr_svg(args...; kwargs...) = first(qr_bundle(args...; kwargs...))

_qr_figure_input(A::AbstractMatrix) = [[A[i, j] for j in axes(A, 2)] for i in axes(A, 1)]
_qr_figure_input(A) = A

function qr_figure(args...; kwargs...)
    length(args) == 1 || throw(ArgumentError("qr_figure expects a single matrix A"))
    matrices_kw, spec_kw, render_kw = _split_qr_figure_kwargs(kwargs)
    la = load_LAFigureSpecs()
    gram_schmidt_qr_matrices = _pygetattr(la, :gram_schmidt_qr_matrices)
    qr_spec_from_matrices = _pygetattr(la, :qr_spec_from_matrices)
    matrices = _pycall(gram_schmidt_qr_matrices, _qr_figure_input(args[1]); matrices_kw...)
    spec = _pycall(qr_spec_from_matrices, matrices; spec_kw...)
    svg = _render_qr_from_spec(spec; render_kw...)
    return _show_svg(svg), materialize_python_value(matrices)
end

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

q_factor_from_spec(spec) = qr_matrices_from_spec(spec).Q
r_factor_from_spec(spec) = qr_matrices_from_spec(spec).R

function eig_matrices_from_spec(spec; orthonormal::Bool=true)
    la = load_LAFigureSpecs()
    eig_from_spec = _pygetattr(la, :eig_matrices_from_spec)
    return materialize_python_value(_pycall(eig_from_spec, spec; orthonormal=orthonormal))
end

function svd_matrices_from_spec(spec; reduced::Bool=true)
    la = load_LAFigureSpecs()
    svd_from_spec = _pygetattr(la, :svd_matrices_from_spec)
    return materialize_python_value(_pycall(svd_from_spec, spec; reduced=reduced))
end

function qr_matrices_from_grid(mats)
    la = load_LAFigureSpecs()
    qr_from_grid = _pygetattr(la, :qr_matrices_from_grid)
    qr = _pycall(qr_from_grid, mats)
    getmat(name::String) = begin
        try
            materialize_python_value(qr[name])
        catch
            nothing
        end
    end
    return (
        A = getmat("A"),
        W = getmat("W"),
        WtA = getmat("WtA"),
        WtW = getmat("WtW"),
        S = getmat("S"),
        Qt = getmat("Qt"),
        Q = getmat("Q"),
        R = getmat("R"),
    )
end

function qr_matrices_dict_from_grid(mats)
    la = load_LAFigureSpecs()
    qr_from_grid = _pygetattr(la, :qr_matrices_dict_from_grid)
    return _pycall(qr_from_grid, mats)
end

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
export charpoly
export gram_schmidt_w, normalize_columns, qr_layout, gram_schmidt_stable
export split_R_RHS, particular_solution, homogeneous_solutions
export normal_eq_reduce_to_ref, reduce_to_ref
export ge_decorations
export ref!, show_layout!, show_system, create_cascade!
export show_backsubstitution!, show_solution!
export show_backsubstitution, show_forwardsubstitution, show_solution
export solutions, lhs_matrix, rhs_matrix, rhs_column
export ge_svg, qr_svg, eig_svg, svd_svg
export qr_figure
export show_svg, py_show_svg, l_show_svd
export ge_bundle, qr_bundle, eig_bundle, svd_bundle
export qr_matrices_from_spec, eig_matrices_from_spec, svd_matrices_from_spec
export qr_matrices_from_grid, qr_matrices_dict_from_grid
export q_factor_from_spec, r_factor_from_spec
export eig_eigenvalues, svd_singular_values
export svd_rank, eig_eigenvectors, svd_left_vectors, svd_right_vectors

end
