using BlockArrays: Block, BlockArray, blocklengths

@testset "SVD block partitions" begin
    @test LATeachingSuite.WorkflowDisplay.svd_blocks === svd_blocks
    la = LATeachingSuite.load_LAFigureSpecs()
    symbolics = LATeachingSuite._ensure_symbolics()
    simplify(M) = symbolics.simplify.(symbolics.expand.(M))
    for A in (
        [3 0 4 0; 0 0 0 0; 0 -10 0 0] // 5,
        [3 1; 1 3; 0 0],
        [1 0; 0 2; 0 0], [1 0 0; 0 2 0],
        [1 0; 0 1], zeros(Int, 3, 4),
    ), reduced in (false, true)
        spec = LATeachingSuite._pycall(
            LATeachingSuite._pygetattr(la, :svd_spec),
            LATeachingSuite._qr_figure_input(A),
        )
        U, S, V, r = svd_matrices_from_spec(spec; reduced=reduced)
        Ub, Sb, Vb = svd_blocks(U, S, V, r)
        # The combined extractor must match explicit extraction + partitioning.
        combined = svd_matrices_from_spec(spec; blocked=true, reduced=reduced)
        @test combined[4] == r
        for (expected, actual) in zip((Ub, Sb, Vb), combined[1:3])
            @test actual isa BlockArray
            @test isequal(Matrix(actual), Matrix(expected))
            @test axes(actual) == axes(expected)
        end
        if !reduced
            defaults = svd_matrices_from_spec(spec; blocked=true)
            @test isequal(defaults, combined)
        else
            defaults = svd_matrices_from_spec(spec)
            @test all(M -> !(M isa BlockArray), defaults[1:3])
            @test isequal(defaults, (U, S, V, r))
        end
        for (original, blocked) in zip((U, S, V), (Ub, Sb, Vb))
            @test blocked isa BlockArray
            @test size(blocked) == size(original)
            @test isequal(Matrix(blocked), original)
        end
        partition(n) = filter(>(0), [r, n - r])
        @test collect(blocklengths(axes(Ub, 2))) == partition(size(U, 2))
        @test collect(blocklengths(axes(Sb, 1))) == partition(size(S, 1))
        @test collect(blocklengths(axes(Sb, 2))) == partition(size(S, 2))
        @test collect(blocklengths(axes(Vb, 2))) == partition(size(V, 2))
        @test all(iszero, simplify(Ub * Sb * Vb' - A))
        if r > 0
            @test isequal(Matrix(Ub[:, Block(1)]), U[:, 1:r])
            @test isequal(Matrix(Sb[Block(1), Block(1)]), S[1:r, 1:r])
            @test isequal(Matrix(Vb[:, Block(1)]), V[:, 1:r])
        end
        @test !isempty(l_show(Ub, Sb, Vb'))
    end

    # Partitioning also preserves exact complex factors and uses the adjoint.
    U = Complex{Rational{Int}}[im 0; 0 1]
    V = Complex{Rational{Int}}[1 0; 0 im]
    S = [2 0; 0 0]
    Ub, Sb, Vb = svd_blocks(U, S, V, 1)
    @test Ub * Sb * Vb' == U * S * V'
    @test eltype(Ub) == eltype(U)
    @test eltype(Vb) == eltype(V)
    @test occursin("|", L_show(Ub, Sb, Vb'))

    # Economy factors need not be square.
    Ub, Sb, Vb = svd_blocks([1 0; 0 1; 0 0], [2 0; 0 0], [1 0; 0 1], 1)
    @test size(Ub) == (3, 2)
    @test Ub * Sb * Vb' == [2 0; 0 0; 0 0]
    @test_throws ArgumentError svd_blocks(U, S, V, -1)
    @test_throws ArgumentError svd_blocks(U, S, V, 3)
    @test_throws DimensionMismatch svd_blocks(U[:, 1:1], S, V, 1)
    @test_throws DimensionMismatch svd_blocks(U, S, V[:, 1:1], 1)
end
