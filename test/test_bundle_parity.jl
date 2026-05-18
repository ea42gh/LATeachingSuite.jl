using Test
using LATeachingSuite
using GenLAProblems

function _py_ns_bundle()
    py = GenLAProblems._ensure_pythoncall()
    types = Base.invokelatest(py.pyimport, "types")
    simple_namespace = Base.invokelatest(py.pygetattr, types, "SimpleNamespace")
    return Base.invokelatest(py.pycall, simple_namespace)
end

function _py_setattr_bundle(obj, name::AbstractString, value)
    py = GenLAProblems._ensure_pythoncall()
    Base.invokelatest(py.pycall, py.pybuiltins.setattr, obj, name, value)
end

function _py_keys_set(d)
    py = GenLAProblems._ensure_pythoncall()
    keys_obj = GenLAProblems._pycall(Base.invokelatest(py.pygetattr, d, "keys"))
    return Set(Base.invokelatest(py.pyconvert, Vector{String}, keys_obj))
end

@testset "bundle spec parity with backend-provided specs" begin
    la = _py_ns_bundle()
    py = GenLAProblems._ensure_pythoncall()

    function fake_bundle(kind::String)
        return function(args...; kwargs...)
            spec = Base.invokelatest(py.pydict, Dict(
                "kind" => kind,
                "grid" => "demo",
                "argc" => length(args),
            ))
            return Base.invokelatest(py.pydict, Dict(
                "spec" => spec,
                "svg" => "<svg>$kind</svg>",
            ))
        end
    end

    _py_setattr_bundle(la, "ge_tbl_bundle", fake_bundle("ge"))
    _py_setattr_bundle(la, "eig_tbl_bundle", fake_bundle("eig"))
    _py_setattr_bundle(la, "svd_tbl_bundle", fake_bundle("svd"))
    _py_setattr_bundle(la, "qr_tbl_bundle", fake_bundle("qr"))

    old_la = GenLAProblems._LAFigureSpecs[]
    A = [1 0; 0 1]
    try
        GenLAProblems._LAFigureSpecs[] = la
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
    finally
        GenLAProblems._LAFigureSpecs[] = old_la
    end
end
