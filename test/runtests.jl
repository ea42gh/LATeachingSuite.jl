using Test

let
    pycall_exe = get(ENV, "JULIA_PYTHONCALL_EXE", "")
    if isempty(pycall_exe) || !isfile(pycall_exe)
        py = get(ENV, "PYTHON", "")
        if isempty(py) || !isfile(py)
            py = something(Sys.which("python3"), "")
        end
        ENV["JULIA_PYTHONCALL_EXE"] = py
    end
    ENV["JULIA_CONDAPKG_BACKEND"] = get(ENV, "JULIA_CONDAPKG_BACKEND", "Null")
    ENV["CONDAPKG_BACKEND"] = get(ENV, "CONDAPKG_BACKEND", "Null")

    repo = normpath(joinpath(@__DIR__, "..", ".."))
    py_paths = [
        joinpath(repo, ".pydeps"),
        joinpath(repo, "LAFigureSpecs"),
        joinpath(repo, "matrixlayout"),
    ]
    existing = get(ENV, "PYTHONPATH", "")
    parts = isempty(existing) ? String[] : split(existing, ':')
    for p in reverse(py_paths)
        if !(p in parts)
            pushfirst!(parts, p)
        end
    end
    ENV["PYTHONPATH"] = join(parts, ':')
end

using LATeachingSuite
using GenLAProblems
using LinearAlgebra

@testset "LATeachingSuite" begin
    @test !isdefined(LATeachingSuite, :nM)
    @test isdefined(LATeachingSuite, :ShowGE)
    @test isdefined(LATeachingSuite, :WorkflowDisplay)
    @test isdefined(LATeachingSuite, :PythonBridge)
    @test isdefined(LATeachingSuite, :load_LAFigureSpecs)
    @test isdefined(LATeachingSuite, :load_matrixlayout)
    @test isdefined(LATeachingSuite, :charpoly)
    @test isdefined(LATeachingSuite, :gram_schmidt_w)
    @test isdefined(LATeachingSuite, :normalize_columns)
    @test isdefined(LATeachingSuite, :qr_layout)
    @test isdefined(LATeachingSuite, :gram_schmidt_stable)
    @test isdefined(LATeachingSuite, :ref!)
    @test isdefined(LATeachingSuite, :show_layout!)
    @test isdefined(LATeachingSuite, :show_system)
    @test isdefined(LATeachingSuite, :create_cascade!)
    @test isdefined(LATeachingSuite, :show_backsubstitution!)
    @test isdefined(LATeachingSuite, :show_solution!)
    @test isdefined(LATeachingSuite, :show_backsubstitution)
    @test isdefined(LATeachingSuite, :show_forwardsubstitution)
    @test isdefined(LATeachingSuite, :show_solution)
    @test isdefined(LATeachingSuite, :solutions)
    @test isdefined(LATeachingSuite, :lhs_matrix)
    @test isdefined(LATeachingSuite, :rhs_matrix)
    @test isdefined(LATeachingSuite, :rhs_column)
    @test isdefined(LATeachingSuite, :ge_svg)
    @test isdefined(LATeachingSuite, :qr_svg)
    @test isdefined(LATeachingSuite, :qr_figure)
    @test isdefined(LATeachingSuite, :eig_svg)
    @test isdefined(LATeachingSuite, :svd_svg)
    @test isdefined(LATeachingSuite, :qr_matrices_from_spec)
    @test isdefined(LATeachingSuite, :qr_matrices_from_grid)
    @test isdefined(LATeachingSuite, :q_factor_from_spec)
    @test isdefined(LATeachingSuite, :r_factor_from_spec)
    @test isdefined(LATeachingSuite, :eig_matrices_from_spec)
    @test isdefined(LATeachingSuite, :svd_matrices_from_spec)
    @test isdefined(LATeachingSuite, :eig_eigenvalues)
    @test isdefined(LATeachingSuite, :svd_singular_values)
    @test isdefined(LATeachingSuite, :svd_rank)
    @test isdefined(LATeachingSuite, :eig_eigenvectors)
    @test isdefined(LATeachingSuite, :svd_left_vectors)
    @test isdefined(LATeachingSuite, :svd_right_vectors)
    @test isdefined(LATeachingSuite, :show_svg)
    @test isdefined(LATeachingSuite, :py_show_svg)
    @test isdefined(LATeachingSuite, :l_show_svd)
    @test isdefined(LATeachingSuite, :ge_bundle)
    @test isdefined(LATeachingSuite, :qr_bundle)
    @test isdefined(LATeachingSuite, :eig_bundle)
    @test isdefined(LATeachingSuite, :svd_bundle)
    @test isdefined(LATeachingSuite.WorkflowDisplay, :show_layout!)
    @test isdefined(LATeachingSuite.WorkflowDisplay, :ShowGE)
    @test isdefined(LATeachingSuite.PythonBridge, :ensure_pythoncall!)
    @test isdefined(LATeachingSuite.PythonBridge, :load_LAFigureSpecs)
    @test hasmethod(LATeachingSuite.load_LAFigureSpecs, Tuple{})
    @test hasmethod(LATeachingSuite.load_matrixlayout, Tuple{})
    @test hasmethod(LATeachingSuite.gram_schmidt_w, Tuple{Any})
    @test hasmethod(LATeachingSuite.normalize_columns, Tuple{Any})
    @test hasmethod(LATeachingSuite.qr_layout, Tuple{Any})
    @test any(m -> m.module === LATeachingSuite, methods(LATeachingSuite.ref!))
    @test hasmethod(LATeachingSuite.show_backsubstitution, Tuple{Any,Any})
    @test hasmethod(LATeachingSuite.ge_svg, Tuple{Any})
    @test hasmethod(LATeachingSuite.qr_figure, Tuple{Any})
    @test hasmethod(LATeachingSuite.eig_svg, Tuple{Any})
    @test hasmethod(LATeachingSuite.svd_svg, Tuple{Any})
    @test hasmethod(LATeachingSuite.qr_matrices_from_spec, Tuple{Any})
    @test hasmethod(LATeachingSuite.qr_matrices_from_grid, Tuple{Any})
    @test hasmethod(LATeachingSuite.q_factor_from_spec, Tuple{Any})
    @test hasmethod(LATeachingSuite.r_factor_from_spec, Tuple{Any})
    @test hasmethod(LATeachingSuite.eig_matrices_from_spec, Tuple{Any})
    @test hasmethod(LATeachingSuite.svd_matrices_from_spec, Tuple{Any})
    @test hasmethod(LATeachingSuite.eig_eigenvalues, Tuple{Any})
    @test hasmethod(LATeachingSuite.svd_singular_values, Tuple{Any})
    @test hasmethod(LATeachingSuite.svd_rank, Tuple{Any})
    @test hasmethod(LATeachingSuite.eig_eigenvectors, Tuple{Any,Any})
    @test hasmethod(LATeachingSuite.svd_left_vectors, Tuple{Any,Any})
    @test hasmethod(LATeachingSuite.svd_right_vectors, Tuple{Any,Any})
    @test hasmethod(LATeachingSuite.show_svg, Tuple{Any})

    A = Rational{Int}.([1 2; 3 4])
    B1 = Rational{Int}.([5 7; 6 8])
    B2 = Rational{Int}.([9; 10])
    pb = ShowGE(A, (B1, B2))
    ref!(pb; gj=true)
    xp, xh = solutions(pb)
    xp2, _ = solutions(pb; b_col=2)
    xp3, _ = solutions(pb; b_mat=2, b_col=1)
    @test lhs_matrix(pb) == pb.matrices[end][end][:, 1:size(A, 2)]
    @test rhs_matrix(pb, 1) == pb.matrices[end][end][:, size(A, 2) .+ (1:2)]
    @test rhs_matrix(pb, 2) == pb.matrices[end][end][:, size(A, 2) .+ (3:3)]
    @test rhs_column(pb, 1, 2) == rhs_matrix(pb, 1)[:, 2]
    @test rhs_column(pb, 2, 1) == vec(rhs_matrix(pb, 2))
    @test size(xp, 1) == size(A, 2)
    @test size(xp, 2) == 2
    @test xp2 == xp[:, 2]
    @test xp3 isa AbstractVector
    @test xh isa AbstractMatrix

    mats, pivots, _ = reduce_to_ref(A; gj=true)
    @test size(mats[end][end]) == size(A)
    @test pivots == [1, 2]

    Adef = Rational.(GenLAProblems.gen_non_diagonalizable_eigenproblem(2, 0; maxint=2))
    @test LATeachingSuite.charpoly(Adef) == LATeachingSuite.charpoly([2 1 0; 0 2 0; 0 0 0])

    Afrom = GenLAProblems.gen_from_jordan_form([GenLAProblems.jordan_block(2, 2), GenLAProblems.jordan_block(0, 1)]; maxint=2)
    @test LATeachingSuite.charpoly(Afrom) == LATeachingSuite.charpoly([2 1 0; 0 2 0; 0 0 0])

    Aqr = Rational{Int}.([1 1; 0 1])
    Wqr = LATeachingSuite.gram_schmidt_w(Aqr)
    Qqr = LATeachingSuite.normalize_columns(Wqr)
    Qs, Rs = LATeachingSuite.gram_schmidt_stable(Aqr)
    Qf, Rf = LATeachingSuite.gram_schmidt_stable(Float64.(Aqr))
    @test size(Wqr) == size(Aqr)
    @test size(Qqr) == size(Aqr)
    @test size(Qs) == size(Aqr)
    @test size(Rs) == size(Aqr)
    @test Qs * Rs == Aqr
    @test Qf * Rf ≈ Float64.(Aqr)
    @test LATeachingSuite.qr_layout(Aqr) !== nothing
end

include("test_wrapper_contracts.jl")
include("test_bundle_parity.jl")
