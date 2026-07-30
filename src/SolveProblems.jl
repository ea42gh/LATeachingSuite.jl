abstract type AbstractDescription end

Base.@kwdef struct FoundPivot <: AbstractDescription
    level::Int
    row::Int
    pivot_row::Int
    pivot_col::Int
    cur_rank::Int
    pivot_cols
end

Base.@kwdef struct RequireRowExchange <: AbstractDescription
    level::Int
    row_1::Int
    row_2::Int
    col::Int
    cur_rank::Int
    pivot_cols
end

Base.@kwdef struct RequireElimination <: AbstractDescription
    level::Int
    gj::Bool
    yes::Bool
    row::Int
    col::Int
    cur_rank::Int
    pivot_cols
end

Base.@kwdef struct RequireScaling <: AbstractDescription
    level::Int
    pivot_cols
end

Base.@kwdef struct DoElimination <: AbstractDescription
    level::Int
    pivot_row::Int
    pivot_col::Int
    gj::Bool
end

Base.@kwdef struct DoRowExchange <: AbstractDescription
    level::Int
    row_1::Int
    row_2::Int
    col::Int
    cur_rank::Int
end

Base.@kwdef struct DoScaling <: AbstractDescription
    level::Int
end

Base.@kwdef struct Finished <: AbstractDescription
    level::Int
    pivot_cols
end

function particular_solution(R, RHS::AbstractVecOrMat, pivot_cols)
    RHS = Matrix(RHS)
    M, N = size(R, 2), size(RHS, 2)
    r = length(pivot_cols)
    X = zeros(eltype(R), (M, N))
    X[pivot_cols, :] = RHS[1:r, :]
    X
end

function split_R_RHS(R_RHS, num_rhs::Integer)
    if num_rhs < 0
        throw(ArgumentError("num_rhs must be nonnegative"))
    end
    if num_rhs > size(R_RHS, 2)
        throw(ArgumentError("num_rhs exceeds number of columns in R_RHS"))
    end
    N = size(R_RHS, 2) - num_rhs
    R_RHS[:, 1:N], R_RHS[:, N + 1:end]
end

function split_R_RHS(R_RHS, rhs_groups::AbstractVector{<:Integer})
    if any(g -> g < 0, rhs_groups)
        throw(ArgumentError("rhs group sizes must be nonnegative"))
    end
    num_rhs = sum(rhs_groups)
    if num_rhs > size(R_RHS, 2)
        throw(ArgumentError("sum(rhs_groups) exceeds number of columns in R_RHS"))
    end
    N = size(R_RHS, 2) - num_rhs
    R = R_RHS[:, 1:N]
    groups = Vector{Any}()
    start_col = N + 1
    for g in rhs_groups
        stop_col = start_col + g - 1
        push!(groups, R_RHS[:, start_col:stop_col])
        start_col = stop_col + 1
    end
    return R, groups
end

function particular_solution(R_RHS, num_rhs::Int, pivot_cols)
    R, RHS = split_R_RHS(R_RHS, num_rhs)
    particular_solution(R, RHS, pivot_cols)
end

function homogeneous_solutions(R, pivot_cols)
    r = length(pivot_cols)
    c = findall(j -> j == 1, [i in pivot_cols ? 0 : 1 for i in 1:size(R, 2)])
    if length(c) == 0
        H = zeros(eltype(R), (size(R, 2), 1))
    else
        H = zeros(eltype(R), (size(R, 2), length(c)))
        for j in eachindex(c)
            H[c[j], j] = 1
            H[pivot_cols, j] = -R[1:r, c[j]]
        end
    end
    H
end

function find_pivot(A, row, col)
    for i in row:size(A, 1)
        if A[i, col] != 0
            return i
        end
    end
    -1
end

function non_zero_entry(A, row, col, gj)
    set = (row + 1):size(A, 1)
    if gj && row > 1
        set = [1:row-1; set]
    end
    for i in set
        if A[i, col] != 0
            return true
        end
    end
    false
end

function interchange(A, row_1, row_2)
    for j in 1:size(A, 2)
        A[row_1, j], A[row_2, j] = A[row_2, j], A[row_1, j]
    end
end

function eliminate(A, pivot_row, row, alpha)
    for j in 1:size(A, 2)
        A[row, j] += alpha * A[pivot_row, j]
    end
end

function normal_eq_reduce_to_ref(A; n=nothing, gj=false, find_pivot=find_pivot)
    if is_none_val(n)
        n = size(A, 2)
    else
        n = Int(n)
    end
    if eltype(A) == Complex{Int64}
        A = Complex{Rational{Int64}}.(copy(A))
    elseif eltype(A) == Int64
        A = Rational{Int64}.(copy(A))
    else
        A = copy(A)
    end

    if is_none_val(n)
        matrices = [[nothing, A], [A', A' * A]]
    else
        At = A[:, 1:n]'
        matrices = [[nothing, A], [At, At * A]]
    end

    _reduce_to_ref(matrices, n; gj=gj, find_pivot=find_pivot)
end

function reduce_to_ref(A; n=nothing, gj=false, find_pivot=find_pivot)
    if is_none_val(n)
        n = size(A, 2)
    else
        n = Int(n)
    end
    if eltype(A) == Complex{Int64}
        A = Complex{Rational{Int64}}.(copy(A))
    elseif eltype(A) == Int64
        A = Rational{Int64}.(copy(A))
    else
        A = copy(A)
    end
    matrices = [[nothing, A]]
    _reduce_to_ref(matrices, n; gj=gj, find_pivot=find_pivot)
end

function _reduce_to_ref(matrices, n; gj=false, find_pivot=find_pivot)
    A = copy(matrices[end][end])
    pivot_cols = Int[]
    description = []

    M, N = size(A)
    N = min(n, N)

    row = 1
    col = 1
    cur_rank = 0
    level = size(matrices, 1) - 1
    while true
        p = find_pivot(A, row, col)
        if p < 0
            col += 1
        else
            cur_rank += 1
            push!(pivot_cols, col)
            if p != row
                push!(description, RequireRowExchange(level=level, row_1=row, row_2=p, col=col, cur_rank=cur_rank, pivot_cols=copy(pivot_cols)))
                level += 1
                interchange(A, p, row)
                E = Matrix{eltype(A)}(I, M, M)
                interchange(E, p, row)
                push!(matrices, [E, copy(A)])
                push!(description, DoRowExchange(level=level, row_1=row, row_2=p, col=col, cur_rank=cur_rank))
            end
            push!(description, FoundPivot(level=level, row=row, pivot_row=p, pivot_col=col, cur_rank=cur_rank, pivot_cols=copy(pivot_cols)))

            if non_zero_entry(A, row, col, gj)
                push!(description, RequireElimination(level=level, gj=gj, yes=true, row=row, col=col, cur_rank=cur_rank, pivot_cols=copy(pivot_cols)))
                level += 1

                E = Matrix{eltype(A)}(I, M, M)
                for r in (row + 1):M
                    alpha = -A[r, col] // A[row, col]
                    eliminate(A, row, r, alpha)
                    eliminate(E, row, r, alpha)
                end
                if gj
                    for r in 1:(row - 1)
                        alpha = -A[r, col] // A[row, col]
                        eliminate(A, row, r, alpha)
                        eliminate(E, row, r, alpha)
                    end
                end
                push!(matrices, [E, copy(A)])
                push!(description, DoElimination(level=level, pivot_row=cur_rank, pivot_col=col, gj=gj))
            else
                push!(description, RequireElimination(level=level, gj=gj, yes=false, row=row, col=col, cur_rank=cur_rank, pivot_cols=copy(pivot_cols)))
            end
            col += 1
            row += 1
        end

        if (row > M) || (col > N)
            if gj && M > 0
                require_scaling = false
                E = Matrix{eltype(A)}(I, M, M)
                for i in eachindex(pivot_cols)
                    pivot_col = pivot_cols[i]
                    if isone(A[i, pivot_col]) == false
                        require_scaling = true
                    end
                    E[i, i] = 1 // A[i, pivot_col]
                end
                if require_scaling
                    push!(matrices, [E, E * A])
                    push!(description, RequireScaling(level=level, pivot_cols=copy(pivot_cols)))
                    level += 1
                    push!(description, DoScaling(level=level))
                end
            end
            push!(description, Finished(level=level, pivot_cols=copy(pivot_cols)))
            break
        end
    end

    matrices, pivot_cols, description
end

function ge_variable_type(pivot_cols, n)
    l = Vector{Any}([false for _ in 1:n])
    l[pivot_cols] .= true
    l
end

function _ge_decoration_keywords_from_records(pivot_records, background_records, path_records, variable_summary)
    return (
        pivot_locs = _ge_pivot_records_to_locs(pivot_records),
        decorations = _ge_background_records_to_decorations(background_records),
        rowechelon_paths = _ge_path_records_to_rowechelon(path_records),
        variable_summary = variable_summary,
    )
end

function _ge_decorations_impl(description, pivot_cols, sizeA;
    pivot_color="yellow!15", missing_pivot_color="gray!20",
    path_color="blue,line width=0.5mm")
    M, N = sizeA
    if description == []
        if pivot_cols == []
            pivot_records = nothing
            background_records = nothing
            path_records = nothing
            variable_types = nothing
        else
            pivot_locs = [(i - 1, pivot_cols[i] - 1) for i in eachindex(pivot_cols)]
            pivot_records = [[(0, 1), pivot_locs]]
            background_records = [[0, 1, pivot_locs, pivot_color]]
            path_records = [[0, 1, pivot_locs, "vh", path_color]]
            variable_types = ge_variable_type(pivot_cols, N)
        end
        return _ge_decoration_keywords_from_records(pivot_records, background_records, path_records, variable_types)
    end

    plist(pivot_cols) = [(row - 1, pivot_cols[row] - 1) for row in eachindex(pivot_cols)]

    function decorate_A!(pivot_dict, bg_dict, path_dict, description)
        update = true
        for desc in description
            level = desc.level
            if typeof(desc) == RequireElimination
                row = desc.row - 1
                col = desc.col - 1
                first = desc.gj ? 0 : row
                bg_dict[(level, 1)] = [bg_dict[(level, 1)], [level, 1, [(row, col), [(first, col), (M - 1, col)]], pivot_color, 1]]
                path_dict[(level, 1)] = [level, 1, plist(desc.pivot_cols), desc.yes ? "vv" : "vh", path_color]
            elseif typeof(desc) == FoundPivot
                pl = plist(desc.pivot_cols)
                pivot_dict[(level, 1)] = [(level, 1), pl]
                bg_dict[(level, 1)] = [level, 1, pl, pivot_color]
                update = true
            elseif typeof(desc) == RequireRowExchange
                len = length(desc.pivot_cols)
                if len >= 2
                    bg_dict[(level, 1)] = [[level, 1, [(desc.row_1 - 1, desc.col - 1), (desc.row_2 - 1, desc.col - 1)], missing_pivot_color],
                                           [level, 1, plist(desc.pivot_cols[1:end-1]), pivot_color]]
                elseif len == 1
                    bg_dict[(level, 1)] = [level, 1, [(desc.row_1 - 1, desc.col - 1), (desc.row_2 - 1, desc.col - 1)], missing_pivot_color]
                end
                if len != 0
                    pl = plist(desc.pivot_cols)
                    pivot_dict[(level, 1)] = [(level, 1), pl]
                    bg_dict[(level, 1)] = [level, 1, pl, pivot_color]
                    path_dict[(level, 1)] = [level, 1, pl, "vv", path_color]
                end
                update = true
            elseif typeof(desc) == RequireScaling
                if desc.pivot_cols != []
                    pl = plist(desc.pivot_cols)
                    if update
                        pivot_dict[(level, 1)] = [(level, 1), pl]
                        bg_dict[(level, 1)] = [level, 1, pl, pivot_color]
                    end
                    path_dict[(level, 1)] = [level, 1, pl, "vh", path_color]
                end
                update = true
            elseif typeof(desc) == Finished
                if desc.pivot_cols != []
                    pl = plist(desc.pivot_cols)
                    pivot_dict[(level, 1)] = [(level, 1), pl]
                    bg_dict[(level, 1)] = [level, 1, pl, pivot_color]
                    path_dict[(level, 1)] = [level, 1, pl, "vh", path_color]
                end
                update = true
            end
        end
    end

    function decorate_E!(pivot_dict, bg_dict, path_dict, description, M)
        for desc in description
            level = desc.level
            if typeof(desc) == DoElimination
                c = desc.pivot_row - 1
                pivot_dict[(level, 0)] = [(level, 0), [(c, c)]]
                if desc.gj
                    path_dict[(level, 0)] = [level, 0, [(0, c)], "vv", path_color]
                    bg_dict[(level, 0)] = [level, 0, [(c, c), [(0, c), (M - 1, c)]], pivot_color, 1]
                else
                    path_dict[(level, 0)] = [level, 0, [(c, c)], "vv", path_color]
                    bg_dict[(level, 0)] = [level, 0, [(c, c), [(c, c), (M - 1, c)]], pivot_color, 1]
                end
            elseif typeof(desc) == DoRowExchange
                pl = [(desc.row_1 - 1, desc.row_2 - 1), (desc.row_2 - 1, desc.row_1 - 1)]
                pivot_dict[(level, 0)] = [(level, 0), pl]
                bg_dict[(level, 0)] = [level, 0, pl, missing_pivot_color]
            elseif typeof(desc) == DoScaling
                pl = [(c, c) for c in 0:M-1]
                pivot_dict[(level, 0)] = [(level, 0), pl]
                bg_dict[(level, 0)] = [level, 0, pl, pivot_color]
            end
        end
    end

    pivot_dict = Dict{Tuple{Int, Int}, Any}()
    bg_dict = Dict{Tuple{Int, Int}, Any}()
    path_dict = Dict{Tuple{Int, Int}, Any}()

    decorate_A!(pivot_dict, bg_dict, path_dict, description)
    decorate_E!(pivot_dict, bg_dict, path_dict, description, M)

    pivot_records = [pair.second for pair in sort(collect(pivot_dict); by=first)]
    background_records = [pair.second for pair in sort(collect(bg_dict); by=first)]
    path_records = [pair.second for pair in sort(collect(path_dict); by=first)]
    return _ge_decoration_keywords_from_records(
        pivot_records,
        background_records,
        path_records,
        ge_variable_type(pivot_cols, N),
    )
end

function _ge_pivot_records_to_locs(pivot_records)
    pivot_records === nothing && return nothing
    return [Dict("grid" => Tuple(record[1]), "entries" => record[2]) for record in pivot_records]
end

function _ge_path_records_to_rowechelon(path_records)
    path_records === nothing && return nothing
    return [
        Dict(
            "grid" => (record[1], record[2]),
            "pivots" => record[3],
            "case" => record[4],
            "color" => (length(record) >= 5 ? record[5] : "blue"),
        )
        for record in path_records
    ]
end

function _ge_background_records_to_decorations(background_records)
    background_records === nothing && return nothing
    decorations = Any[]

    function append_record!(record)
        if !(record isa AbstractVector)
            return nothing
        end
        if length(record) < 4
            for item in record
                append_record!(item)
            end
            return nothing
        end

        grid = (record[1], record[2])
        locs = record[3]
        background = record[4]
        padding_pt = length(record) >= 5 ? record[5] : 0
        for loc in locs
            if loc isa Tuple
                push!(
                    decorations,
                    Dict(
                        "grid" => grid,
                        "entries" => [loc],
                        "background" => background,
                        "padding_pt" => padding_pt,
                    ),
                )
            else
                (r1, c1), (r2, c2) = loc
                push!(
                    decorations,
                    Dict(
                        "grid" => grid,
                        "rows" => (r1, r2),
                        "cols" => (c1, c2),
                        "background" => background,
                        "padding_pt" => padding_pt,
                    ),
                )
            end
        end
        nothing
    end

    for record in background_records
        append_record!(record)
    end
    return decorations
end

"""
    ge_decorations(description, pivot_cols, sizeA; kwargs...)

Return canonical GE decoration keyword fields for `ge_svg`.
"""
function ge_decorations(description, pivot_cols, sizeA; kwargs...)
    _ge_decorations_impl(description, pivot_cols, sizeA; kwargs...)
end

# ------------------------------------------------------------------------------
# ---------------------------------------------------------------------- charpoly
# ------------------------------------------------------------------------------
const Rq, λ = AbstractAlgebra.QQ["λ"]
const Qx, x = AbstractAlgebra.polynomial_ring(AbstractAlgebra.QQ, "x")
const _K_i = Ref{Any}(nothing)
const _Kλ = Ref{Any}(nothing)

function _get_number_field()
    if _K_i[] !== nothing
        return _K_i[]::Tuple
    end
    if isdefined(AbstractAlgebra, :NumberField)
        _K_i[] = AbstractAlgebra.NumberField(x^2 + 1, "i")
    elseif isdefined(AbstractAlgebra, :number_field)
        _K_i[] = AbstractAlgebra.number_field(x^2 + 1, "i")
    else
        error("AbstractAlgebra number field constructor not available.")
    end
    return _K_i[]::Tuple
end

function _get_K_lambda()
    if _Kλ[] !== nothing
        return _Kλ[]::Tuple
    end
    K, _ = _get_number_field()
    _Kλ[] = AbstractAlgebra.polynomial_ring(K, "λ")
    return _Kλ[]::Tuple
end

"""
    charpoly(A::AbstractMatrix{Rational{Int64}})

Compute the characteristic polynomial over rationals.
"""
function charpoly(A::AbstractMatrix{Rational{Int64}})
    M = matrix(Rq, Matrix(A))
    B = M - λ * one(M)
    det(B)
end

"""
    charpoly(A::AbstractMatrix{Int64})

Compute the characteristic polynomial over rationals for integer matrices.
"""
function charpoly(A::AbstractMatrix{Int64})
    M = matrix(Rq, Matrix(A))
    B = M - λ * one(M)
    det(B)
end

_to_complex_rational_field(z::Complex{Rational{Int64}}) = begin
    K, i = _get_number_field()
    K(real(z)) + K(imag(z)) * i
end

"""
    charpoly(A::AbstractMatrix{Complex{Rational{Int64}}})

Compute the characteristic polynomial over the Gaussian rationals.
"""
function charpoly(A::AbstractMatrix{Complex{Rational{Int64}}})
    K, _ = _get_number_field()
    Kλ, λc = _get_K_lambda()
    A2 = map(_to_complex_rational_field, A)
    M = matrix(K, A2)
    B = M - λc * one(M)
    det(B)
end

"""
    charpoly(A::AbstractMatrix{Complex{Int64}})

Compute the characteristic polynomial for complex integer matrices.
"""
function charpoly(A::AbstractMatrix{Complex{Int64}})
    charpoly(Complex{Rational{Int64}}.(A))
end

# ------------------------------------------------------------------------------
# ---------------------------------------------------------------- QR utilities
# ------------------------------------------------------------------------------
"""
    gram_schmidt_w(A) -> Matrix

Naive Gram-Schmidt producing an integer matrix of orthogonalized columns.
"""
function gram_schmidt_w(A)
    W = Array{Rational{Int64}}(undef, size(A))
    N = size(A, 2)
    for j in 1:N
        v_j = Rational.(A[:, j])
        for k in 1:j-1
            v_j = v_j - (dot(W[:, k], A[:, j]) / dot(W[:, k], W[:, k])) .* W[:, k]
        end
        lcm_den = reduce((x, y) -> lcm(x, denominator(y)), v_j, init=1)
        tmp = lcm_den .* v_j
        tmp_num = numerator.(tmp)
        d = reduce(gcd, tmp_num, init=tmp_num[1])
        W[:, j] = tmp ./ d
    end
    W
end

"""
    normalize_columns(int_W) -> Matrix

Normalize integer columns, introducing symbolic square roots when needed.
"""
function normalize_columns(int_W)
    norms_squared = [dot(view(int_W, :, i), view(int_W, :, i)) for i in 1:size(int_W, 2)]
    norms = []
    for norm_squared in norms_squared
        if norm_squared isa Rational
            if denominator(norm_squared) == 1
                sz = isqrt(numerator(norm_squared))
                if sz^2 == numerator(norm_squared)
                    push!(norms, sz)
                else
                    push!(norms, _ensure_symbolics().sqrt(norm_squared))
                end
            else
                push!(norms, _ensure_symbolics().sqrt(norm_squared))
            end
        else
            sz = isqrt(norm_squared)
            if sz^2 == norm_squared
                push!(norms, sz)
            else
                push!(norms, _ensure_symbolics().sqrt(norm_squared))
            end
        end
    end
    if all(x -> typeof(x) <: Integer, norms)
        norms = Int.(norms)
    end

    if eltype(norms) <: Integer
        Q = int_W .// norms'
    else
        Q = similar(int_W, eltype(norms))
        for i in 1:size(int_W, 2)
            Q[:, i] = view(int_W, :, i) ./ norms[i]'
        end
    end
    return Q
end

"""
    qr_layout(A) -> Any

Return a LaTeX-ready layout of the QR construction steps.
"""
function qr_layout(A)
    W = gram_schmidt_w(A)

    WtW = Diagonal(W'W)
    WtA = W'A
    S = ((x -> Rational{Int64}(round(sqrt(x)))).(WtW))^(-1)

    Qt = S * W'
    R = S * WtA

    matrices = [[nothing, nothing, A, W],
                [nothing, W', WtA, WtW],
                [S, Qt, R, nothing]]

    to_latex(matrices)
end

"""
    gram_schmidt_stable(A::AbstractMatrix{T}; reorthogonalize=false) where T<:Number

Compute a stable Gram-Schmidt QR factorization, optionally reorthogonalizing.
"""
function gram_schmidt_stable(A::AbstractMatrix{T}; reorthogonalize=false) where T<:Number
    if T <: AbstractFloat || T <: Complex{<:AbstractFloat}
        Awork = Matrix{T}(A)
        m, n = size(Awork)
        Q = zeros(T, m, n)
        R = zeros(T, n, n)
        E = zeros(T, n, n)

        for j in 1:n
            v = Awork[:, j]

            if reorthogonalize
                for i in 1:j-1
                    E[i, j] = dot(Q[:, i], v)
                    v -= E[i, j] * Q[:, i]
                end
            end

            R[j, j] = norm(v)
            Q[:, j] = v / R[j, j]

            for i in j+1:n
                E[j, i] = dot(Q[:, j], Awork[:, i])
                R[j, i] = E[j, i]
                Awork[:, i] -= E[j, i] * Q[:, j]
            end
        end

        return Q, R
    end

    Awork = Matrix{Any}(A)
    m, n = size(Awork)
    Q = Matrix{Any}(undef, m, n)
    R = fill(0, n, n)
    E = fill(0, n, n)

    dot_any(x, y) = sum(conj(x[i]) * y[i] for i in eachindex(x, y))

    for j in 1:n
        v = Vector{Any}(Awork[:, j])

        if reorthogonalize
            for i in 1:j-1
                E[i, j] = dot_any(view(Q, :, i), v)
                v = v .- E[i, j] .* view(Q, :, i)
            end
        end

        norm_sq = dot_any(v, v)
        R[j, j] = _ensure_symbolics().sqrt(norm_sq)
        Q[:, j] = v ./ R[j, j]

        for i in j+1:n
            E[j, i] = dot_any(view(Q, :, j), Vector{Any}(Awork[:, i]))
            R[j, i] = E[j, i]
            Awork[:, i] = Awork[:, i] .- E[j, i] .* Q[:, j]
        end
    end

    return Q, R
end
