# --------------------------------------------------------------------------------------------------------------
"""
    show_system(pb; b_mat=1, b_col=1, var_name="x", fig_scale=1)

Render the linear system associated with a `ShowGE` problem.
"""
function _system_matrix_rhs(pb::ShowGE{T}; b_mat=1, b_col=1) where T <: Number
    A = pb.A
    rhs = _rhs_blocks(pb)
    if !isempty(rhs)
       b = rhs_column(pb, b_mat, b_col; step=:final)
    else
       b = zeros(eltype(pb.A), size(A,1), 1)
    end
    A = _python_exact_literal_if_needed(A)
    b = _python_exact_literal_if_needed(b)
    return A, b
end

function show_system(  pb::ShowGE{T}; b_mat=1, b_col=1, var_name::String="x", fig_scale=1, output_dir=nothing, output_stem=nothing, render_opts=nothing) where T <: Number
    A, b = _system_matrix_rhs(pb; b_mat=b_mat, b_col=b_col)
    la = load_LAFigureSpecs()
    linear_system_tex = _pygetattr(la, :linear_system_tex)
    tex = _pycall(linear_system_tex, A, b; var_name=var_name)
    py = _ensure_pythoncall()
    tex = Base.invokelatest(py.pyconvert, String, tex)
    bs = load_matrixlayout()
    backsubst_svg = _pygetattr(bs, :backsubst_svg)
    resolved_output_dir, resolved_output_stem = _resolve_ge_output_targets(pb, output_dir, output_stem)
    svg = _pycall(backsubst_svg; system_txt=tex, show_system=true,
                  show_cascade=false, show_solution=false,
                  fig_scale=fig_scale, output_dir=resolved_output_dir,
                  output_stem=resolved_output_stem,
                  render_opts=render_opts)
    svg_str = Base.invokelatest(py.pyconvert, String, svg)
    return SVGOut(svg_str)
end
"""
    create_cascade!(pb::ShowGE; b_mat=1, b_col=1, var_name="x")

Initialize cascade state for substitution displays.
"""
function create_cascade!(  pb::ShowGE{T}; b_mat=1, b_col=1, var_name::String="x" ) where T <: Number
    pb.cascade = nothing
end
# --------------------------------------------------------------------------------------------------------------
function _encode_exact(x)
    if x isa Rational
        return (numerator(x), denominator(x))
    elseif x isa Complex{<:Rational}
        r, i = real(x), imag(x)
        return ((numerator(r), denominator(r)), (numerator(i), denominator(i)))
    end
    return x
end

_is_int_pair(x) = x isa Tuple && length(x) == 2 && x[1] isa Integer && x[2] isa Integer
_is_encoded_complex_rational(x) = x isa Tuple && length(x) == 2 && _is_int_pair(x[1]) && _is_int_pair(x[2])
_is_exact_bridge_scalar(x) = x isa Rational || x isa Complex{<:Rational} || _is_int_pair(x) || _is_encoded_complex_rational(x)
_needs_python_exact_literal(A) = A isa AbstractArray && any(_is_exact_bridge_scalar, A)

function _rational_str(r::Rational)
    return string(numerator(r), "/", denominator(r))
end

function _complex_rational_str(z::Complex{<:Rational})
    re = real(z)
    im = imag(z)
    if im == 0
        return _rational_str(re)
    end
    im_str = _rational_str(abs(im))
    if re == 0
        return string(im < 0 ? "-" : "", im_str, "*I")
    end
    sign = im < 0 ? "-" : "+"
    return string(_rational_str(re), " ", sign, " ", im_str, "*I")
end

function _encode_exact_vector(b::AbstractVector)
    out = Vector{Any}(undef, length(b))
    for i in eachindex(b)
        val = b[i]
        if val isa Rational
            out[i] = _encode_exact(val)
        elseif val isa Complex{<:Rational}
            out[i] = _encode_exact(val)
        else
            out[i] = val
        end
    end
    return out
end

function _python_matrix_literal(A::AbstractMatrix)
    return [[_encode_exact(A[i, j]) for j in axes(A, 2)] for i in axes(A, 1)]
end

function _python_vector_literal(b::AbstractVector)
    return [_encode_exact(b[i]) for i in eachindex(b)]
end

function _python_exact_literal(A)
    if A isa AbstractMatrix
        return _python_matrix_literal(A)
    elseif A isa AbstractVector
        return _python_vector_literal(A)
    end
    return A
end

_python_exact_literal_if_needed(A) = _needs_python_exact_literal(A) ? _python_exact_literal(A) : A

function _rhs_vector(b, b_col)
    if b isa AbstractMatrix
        if size(b, 2) == 1
            return vec(b)
        end
        if b_col isa Integer && 1 <= b_col <= size(b, 2)
            return b[:, b_col]
        end
        return b[:, 1]
    end
    return b
end

function _backsub_ref(pb::ShowGE; b_mat=1, b_col=1)
    if isdefined(pb, :matrices) && pb.matrices !== nothing
        Ab = pb.matrices[end][end]
    else
        rhs = _combined_rhs_matrix(pb)
        Ab_full = rhs === nothing ? pb.A : [pb.A rhs]
        mats, _, _ = reduce_to_ref(Ab_full, n=size(pb.A, 2), gj=false)
        Ab = mats[end][end]
    end
    if Ab isa AbstractArray{<:AbstractString} || any(x -> x isa AbstractString, Ab)
        gj = false
        if isdefined(pb, :desc)
            for d in pb.desc
                if hasproperty(d, :gj) && getproperty(d, :gj) === true
                    gj = true
                    break
                end
            end
        end
        rhs = _combined_rhs_matrix(pb)
        if rhs !== nothing
            Ab_full = [pb.A rhs]
        else
            Ab_full = pb.A
        end
        mats, _, _ = reduce_to_ref(Ab_full, n=size(pb.A, 2), gj=gj)
        Ab = mats[end][end]
    end
    A = Ab[:, 1:size(pb.A, 2)]
    if _rhs_col_count(pb) > 0
        global_col = _rhs_global_col_index(pb, Int(b_mat), Int(b_col))
        b = Ab[:, size(pb.A, 2) + global_col]
    else
        b = zeros(eltype(A), size(A, 1), 1)
    end
    b = _rhs_vector(b, b_col)
    A = _python_exact_literal_if_needed(A)
    b = _python_exact_literal_if_needed(b)
    return A, b
end

function _forwardsub_ref(pb::ShowGE; b_mat=1, b_col=1, exact=true)
    A = pb.A
    if _rhs_col_count(pb) > 0
        b = rhs_column(pb, Int(b_mat), Int(b_col); step=:final)
    else
        b = zeros(eltype(A), size(A, 1), 1)
    end
    b = _rhs_vector(b, b_col)
    if exact
        A = _python_exact_literal_if_needed(A)
        b = _python_exact_literal_if_needed(b)
    end
    return A, b
end

function _relabel_cascade(lines, n; var_name::String="x", param_name::String="\\alpha")
    if !(lines isa AbstractVector{<:AbstractString})
        py = _ensure_pythoncall()
        lines = Base.invokelatest(py.pyconvert, Vector{String}, lines)
    end
    line_list = [String(x) for x in lines]
    var_pat = Regex(string(replace(var_name, "\\" => "\\\\"), "_(\\d+)"))
    param_pat = Regex(string(replace(param_name, "\\" => "\\\\"), "_(\\d+)"))
    out = Vector{String}(undef, length(line_list))
    for (i, line) in enumerate(line_list)
        line2 = replace(line, var_pat => (s -> begin
            m = match(var_pat, s)
            idx = parse(Int, m.captures[1])
            new_idx = n - idx + 1
            string(var_name, "_", new_idx)
        end))
        line2 = replace(line2, param_pat => (s -> begin
            m = match(param_pat, s)
            idx = parse(Int, m.captures[1])
            new_idx = n - idx + 1
            string(param_name, "_", new_idx)
        end))
        out[i] = line2
    end
    return out
end

function _display_cascade(lines)
    if !(lines isa AbstractVector{<:AbstractString})
        py = _ensure_pythoncall()
        lines = Base.invokelatest(py.pyconvert, Vector{String}, lines)
    end
    tex = join(lines, "\n")
    display(MIME"text/latex"(), tex)
    return tex
end

function _backsubst_svg_kwargs(; fig_scale=nothing, output_dir=nothing, output_stem=nothing, render_opts=nothing)
    kwargs = Dict{Symbol, Any}()
    if fig_scale !== nothing
        kwargs[:fig_scale] = fig_scale
    end
    if output_dir !== nothing
        kwargs[:output_dir] = output_dir
    end
    if output_stem !== nothing
        kwargs[:output_stem] = output_stem
    end
    kwargs[:render_opts] = _normalize_render_opts(render_opts)
    return kwargs
end
function _render_backsubst_svg(lines; fig_scale=nothing, output_dir=nothing, output_stem=nothing, render_opts=nothing)
    ml = load_matrixlayout()
    backsubst_svg = _pygetattr(ml, :backsubst_svg)
    kwargs = _backsubst_svg_kwargs(fig_scale=fig_scale, output_dir=output_dir, output_stem=output_stem, render_opts=render_opts)
    kwargs[:cascade_txt] = _ge_to_pylist(lines)
    kwargs[:show_system] = false
    kwargs[:show_cascade] = true
    kwargs[:show_solution] = false
    svg = _pycall(backsubst_svg; kwargs...)
    return _show_svg(svg)
end

function _render_solution_svg(solution_tex; fig_scale=nothing, output_dir=nothing, output_stem=nothing, render_opts=nothing)
    ml = load_matrixlayout()
    backsubst_svg = _pygetattr(ml, :backsubst_svg)
    kwargs = _backsubst_svg_kwargs(fig_scale=fig_scale, output_dir=output_dir, output_stem=output_stem, render_opts=render_opts)
    kwargs[:solution_txt] = solution_tex
    kwargs[:show_system] = false
    kwargs[:show_cascade] = false
    kwargs[:show_solution] = true
    svg = _pycall(backsubst_svg; kwargs...)
    return _show_svg(svg)
end

function _display_tex(tex)
    if !(tex isa AbstractString)
        py = _ensure_pythoncall()
        tex = Base.invokelatest(py.pyconvert, String, tex)
    end
    display(MIME"text/latex"(), tex)
    return tex
end
"""
    show_backsubstitution!(pb; b_mat=1, b_col=1, var_name="x", fig_scale=1)

Render the back-substitution cascade for a `ShowGE` problem.
"""
function show_backsubstitution!(  pb::ShowGE{T}; b_mat=1, b_col=1, var_name::String="x", param_name::String="\\alpha", fig_scale=1, output_dir=nothing, output_stem=nothing, render_opts=nothing ) where T <: Number
    global_col = _rhs_col_count(pb) > 0 ? _rhs_global_col_index(pb, Int(b_mat), Int(b_col)) : 0
    if global_col > 0 && isdefined(pb, :rhs_status) && global_col <= length(pb.rhs_status) && pb.rhs_status[global_col] == :inconsistent
        val = _inconsistent_rhs_value(pb, global_col)
        rhs_txt = val === nothing ? "?" : _rhs_val_to_tex(val)
        lines = [string("0 = ", rhs_txt), "\\text{No Solution}"]
        resolved_output_dir, resolved_output_stem = _resolve_ge_output_targets(pb, output_dir, output_stem)
        return _render_backsubst_svg(lines; fig_scale=fig_scale, output_dir=resolved_output_dir, output_stem=resolved_output_stem, render_opts=render_opts)
    end
    A, b = _backsub_ref(pb; b_mat=b_mat, b_col=b_col)
    lines = load_LAFigureSpecs().backsubstitution_tex(A, b, var_name=var_name, param_name=param_name)
    resolved_output_dir, resolved_output_stem = _resolve_ge_output_targets(pb, output_dir, output_stem)
    return _render_backsubst_svg(lines; fig_scale=fig_scale, output_dir=resolved_output_dir, output_stem=resolved_output_stem, render_opts=render_opts)
end
# --------------------------------------------------------------------------------------------------------------
function show_forwardsubstitution!(  pb::ShowGE{T}; b_mat=1, b_col=1, var_name::String="x", param_name::String="\\alpha", fig_scale=1, output_dir=nothing, output_stem=nothing, render_svg=true, render_opts=nothing ) where T <: Number
    A, b = _forwardsub_ref(pb; b_mat=b_mat, b_col=b_col, exact=false)
    Arev = A[end:-1:1, end:-1:1]
    brev = b[end:-1:1]
    A2 = _python_exact_literal_if_needed(Arev)
    b2 = _python_exact_literal_if_needed(brev)
    lines = load_LAFigureSpecs().backsubstitution_tex(A2, b2, var_name=var_name, param_name=param_name)
    lines = _relabel_cascade(lines, size(A, 1); var_name=var_name, param_name=param_name)
    if render_svg
        resolved_output_dir, resolved_output_stem = _resolve_ge_output_targets(pb, output_dir, output_stem)
        return _render_backsubst_svg(lines; fig_scale=fig_scale, output_dir=resolved_output_dir, output_stem=resolved_output_stem, render_opts=render_opts)
    end
    return _display_cascade(lines)
end
# --------------------------------------------------------------------------------------------------------------
"""
    show_solution!(pb; b_mat=1, b_col=1, var_name="x", fig_scale=1)

Render the solution vector/form for a `ShowGE` problem.
"""
function show_solution!(  pb::ShowGE{T}; b_mat=1, b_col=1, var_name::String="x", param_name::String="\\alpha", fig_scale=1, output_dir=nothing, output_stem=nothing, render_opts=nothing ) where T <: Number
    global_col = _rhs_col_count(pb) > 0 ? _rhs_global_col_index(pb, Int(b_mat), Int(b_col)) : 0
    if global_col > 0 && isdefined(pb, :rhs_status) && global_col <= length(pb.rhs_status) && pb.rhs_status[global_col] == :inconsistent
        return Vector{T}()
    end
    A, b = _backsub_ref(pb; b_mat=b_mat, b_col=b_col)
    tex = load_LAFigureSpecs().standard_solution_tex(A, b, var_name=var_name, param_name=param_name)
    resolved_output_dir, resolved_output_stem = _resolve_ge_output_targets(pb, output_dir, output_stem)
    return _render_solution_svg(tex; fig_scale=fig_scale, output_dir=resolved_output_dir, output_stem=resolved_output_stem, render_opts=render_opts)
end
# ==============================================================================================================
raw"""
    show_backsubstitution(A, b; var_name="x", fig_scale=1, output_dir="/tmp/la/run", render_svg=true)

    Render the back-substitution cascade for the upper-triangular system `A * x = b`
    using `LAFigureSpecs.backsubstitution_tex`. Works with Integer/Float as well as
    exact `Rational` and `Complex{Rational}` inputs (those are converted to tuples so
    SymPy reconstructs exact rationals on the Python side).
"""
function show_backsubstitution(A, b; var_name::String="x", param_name::String="\\alpha", fig_scale=1, output_dir="/tmp/la/run", output_stem=nothing, render_svg=true, render_opts=nothing)
    A2 = _python_exact_literal_if_needed(A)
    b2 = _python_exact_literal_if_needed(b)
    lines = load_LAFigureSpecs().backsubstitution_tex(A2, b2, var_name=var_name, param_name=param_name)
    if render_svg
        return _render_backsubst_svg(lines; fig_scale=fig_scale, output_dir=output_dir, output_stem=output_stem, render_opts=render_opts)
    end
    return _display_cascade(lines)
end
# --------------------------------------------------------------------------------------------------------------
raw"""
    show_forwardsubstitution(A, b; var_name="x", fig_scale=1, output_dir="/tmp/la/run", render_svg=true)

Render the forward-substitution cascade for the lower-triangular system `A * x = b`
using the LAFigureSpecs backsubstitution cascade on a reversed system, then relabeling indices.
Supports Integer/Float as well as exact `Rational` and `Complex{Rational}` inputs
converted to tuples for exact SymPy reconstruction.
"""
function show_forwardsubstitution(A, b; var_name::String="x", param_name::String="\\alpha", fig_scale=1, output_dir="/tmp/la/run", output_stem=nothing, render_svg=true, render_opts=nothing)
    Arev = A[end:-1:1, end:-1:1]
    brev = b[end:-1:1]
    A2 = _python_exact_literal_if_needed(Arev)
    b2 = _python_exact_literal_if_needed(brev)
    lines = load_LAFigureSpecs().backsubstitution_tex(A2, b2, var_name=var_name, param_name=param_name)
    lines = _relabel_cascade(lines, size(A, 1); var_name=var_name, param_name=param_name)
    if render_svg
        return _render_backsubst_svg(lines; fig_scale=fig_scale, output_dir=output_dir, output_stem=output_stem, render_opts=render_opts)
    end
    return _display_cascade(lines)
end
# ==============================================================================================================
