using Test
using LATeachingSuite
using GenLAProblems

function _py_keys_set(d)
    py = GenLAProblems._ensure_pythoncall()
    keys_obj = GenLAProblems._pycall(Base.invokelatest(py.pygetattr, d, "keys"))
    return Set(Base.invokelatest(py.pyconvert, Vector{String}, keys_obj))
end

@testset "bundle spec parity with LAFigureSpecs" begin
    GenLAProblems._ensure_pythoncall()
    la = LATeachingSuite.load_LAFigureSpecs()
    A = [1 0; 0 1]

    for (bundle_sym, jl_fn) in [
        (:ge_tbl_bundle, LATeachingSuite.ge_bundle),
        (:eig_tbl_bundle, LATeachingSuite.eig_bundle),
        (:svd_tbl_bundle, LATeachingSuite.svd_bundle),
        (:qr_tbl_bundle, LATeachingSuite.qr_bundle),
    ]
        py_bundle = GenLAProblems._pycall(GenLAProblems._pygetattr(la, bundle_sym), A)
        py_spec = py_bundle["spec"]
        _svg, jl_spec = jl_fn(A)
        @test _py_keys_set(py_spec) == _py_keys_set(jl_spec)
    end
end
