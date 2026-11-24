function _named_qr_matrices(qr)
    getmat(name::String) = begin
        if qr isa NamedTuple
            return getproperty(qr, Symbol(name))
        elseif qr isa AbstractDict
            return get(qr, name, get(qr, Symbol(name), nothing))
        end
        return nothing
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

function _show_svg(svg)
    if svg === nothing
        return SVGOut("")
    end
    if _py_is_py(svg)
        _ensure_pythoncall()
        py = getfield(@__MODULE__, :PythonCall)
        if _py_is_none(svg)
            return SVGOut("")
        end
        return SVGOut(Base.invokelatest(py.pyconvert, String, svg))
    elseif svg isa AbstractString
        return SVGOut(svg)
    elseif isdefined(@__MODULE__, :PythonCall)
        py = getfield(@__MODULE__, :PythonCall)
        try
            return SVGOut(Base.invokelatest(py.pyconvert, String, svg))
        catch
        end
    end
    return svg
end

"""
    py_show_svg(svg)

Display an SVG in a Python notebook (e.g., %%julia cell) via IPython.display.SVG.
Accepts `SVGOut`, raw SVG strings, or PythonCall.Py SVG objects.
"""
function py_show_svg(svg)
    try
        _ensure_pythoncall()
        ip = _pyimport("IPython.display")
        py_display = _pygetattr(ip, :display)
        py_svg = _pygetattr(ip, :SVG)
        if svg isa SVGOut
            return _pycall(py_display, _pycall(py_svg, svg.svg))
        elseif svg isa AbstractString
            return _pycall(py_display, _pycall(py_svg, svg))
        elseif _py_is_py(svg)
            s = Base.invokelatest(getfield(@__MODULE__, :PythonCall).pyconvert, String, svg)
            return _pycall(py_display, _pycall(py_svg, s))
        else
            error("py_show_svg expects SVGOut, SVG string, or PythonCall.Py")
        end
    catch
        if svg isa SVGOut
            return Base.display(svg)
        elseif svg isa AbstractString
            return Base.display(SVGOut(svg))
        end
        error("py_show_svg expects SVGOut, SVG string, or PythonCall.Py")
    end
end

"""
    show_svg(svg)

Alias for `py_show_svg`, for notebook-friendly SVG display.
"""
show_svg(svg) = py_show_svg(svg)

"""
    svd_blocks(U, Σ, V, r)

Return `(Ub, Σb, Vb)` as `BlockArray`s partitioned after the first `r`
singular vectors. Columns of `U` and `V`, and both axes of `Σ`, are split
into active and complementary blocks; empty partitions are omitted.

Accepts full, economy, or rank-reduced factors satisfying `A = U * Σ * V'`.
Entries and dimensions are preserved exactly. This helper partitions the
supplied factors; it does not compute or validate a singular decomposition.
"""
function svd_blocks(U::AbstractMatrix, Σ::AbstractMatrix, V::AbstractMatrix, r::Integer)
    size(U, 2) == size(Σ, 1) && size(V, 2) == size(Σ, 2) ||
        throw(DimensionMismatch("U, Σ, V must have compatible SVD dimensions"))
    0 <= r <= min(size(Σ)...) ||
        throw(ArgumentError("r must lie between zero and the smaller dimension of Σ"))
    partition(n) = filter(>(0), [r, n - r])
    # BlockArrays arithmetic requires concrete scalar types. Promote mixed
    # integer/rational storage without approximating any entries.
    function block_entries(M)
        isconcretetype(eltype(M)) && return M
        isempty(M) && return zeros(Int, size(M))
        T = mapreduce(typeof, promote_type, M)
        return T.(M)
    end
    BA = _ensure_blockarrays()
    Ub = BA.BlockArray(block_entries(U), [size(U, 1)], partition(size(U, 2)))
    Σb = BA.BlockArray(block_entries(Σ), partition(size(Σ, 1)), partition(size(Σ, 2)))
    Vb = BA.BlockArray(block_entries(V), [size(V, 1)], partition(size(V, 2)))
    return Ub, Σb, Vb
end

"""
    l_show_svd(A, U, Σ, Vt, rankA)

Display an SVD factorization with block structure separating the rank and null
space components.
"""
function l_show_svd(A, U, Σ, Vt, rankA)
    Ub, Σb, Vb = svd_blocks(U, Σ, Vt', rankA)
    Vtb = Vb'
    display(l_show(LaTeXString("A = U \\Sigma V^T : "), A, " = ", Ub, Σb, Vtb))
    return nothing
end

function _normalize_render_opts(render_opts)
    if render_opts === nothing
        return Dict{String,Any}()
    elseif !(render_opts isa AbstractDict)
        return Dict{String,Any}(render_opts)
    else
        return Dict{String,Any}(render_opts)
    end
end
