using Test
using LATeachingSuite
using GenLAProblems

function _py_ns_lat()
    py = GenLAProblems._ensure_pythoncall()
    types = Base.invokelatest(py.pyimport, "types")
    simple_namespace = Base.invokelatest(py.pygetattr, types, "SimpleNamespace")
    return Base.invokelatest(py.pycall, simple_namespace)
end

function _py_setattr_lat(obj, name::AbstractString, value)
    py = GenLAProblems._ensure_pythoncall()
    Base.invokelatest(py.pycall, py.pybuiltins.setattr, obj, name, value)
end

@testset "Top-level wrapper contracts" begin
    la = _py_ns_lat()
    ml = _py_ns_lat()

    _py_setattr_lat(la, "__version__", "la-test-version")
    _py_setattr_lat(la, "__build__", "la-test-build")
    _py_setattr_lat(ml, "__version__", "ml-test-version")
    _py_setattr_lat(ml, "__build__", "ml-test-build")

    old_la = GenLAProblems._LAFigureSpecs[]
    old_ml = GenLAProblems._matrixlayout[]
    try
        GenLAProblems._LAFigureSpecs[] = la
        GenLAProblems._matrixlayout[] = ml

        @test LATeachingSuite.load_LAFigureSpecs() === la
        @test LATeachingSuite.load_matrixlayout() === ml
        @test LATeachingSuite.la_version() == "la-test-version"
        @test LATeachingSuite.la_build() == "la-test-build"
        @test LATeachingSuite.ml_version() == "ml-test-version"
        @test LATeachingSuite.ml_build() == "ml-test-build"
    finally
        GenLAProblems._LAFigureSpecs[] = old_la
        GenLAProblems._matrixlayout[] = old_ml
    end
end

@testset "Workflow wrapper delegation contracts" begin
    @test LATeachingSuite.ShowGE === GenLAProblems.ShowGE

    @test hasmethod(LATeachingSuite.ref!, Tuple{Any})
    @test hasmethod(LATeachingSuite.show_layout!, Tuple{Any})
    @test hasmethod(LATeachingSuite.show_system, Tuple{Any})
    @test hasmethod(LATeachingSuite.create_cascade!, Tuple{Any})
    @test hasmethod(LATeachingSuite.show_backsubstitution!, Tuple{Any})
    @test hasmethod(LATeachingSuite.show_solution!, Tuple{Any})
    @test hasmethod(LATeachingSuite.show_backsubstitution, Tuple{Any,Any})
    @test hasmethod(LATeachingSuite.show_forwardsubstitution, Tuple{Any,Any})
    @test hasmethod(LATeachingSuite.show_solution, Tuple{Any})
    @test hasmethod(LATeachingSuite.solutions, Tuple{Any})
    @test hasmethod(LATeachingSuite.rhs_block, Tuple{Any})
    @test hasmethod(LATeachingSuite.show_ge_final, Tuple{Any,Any,Any})

    la_ge = _py_ns_lat()
    _py_setattr_lat(la_ge, "ge", (args...; kwargs...) -> "<svg>ge</svg>")
    old_ge_la = GenLAProblems._LAFigureSpecs[]
    try
        GenLAProblems._LAFigureSpecs[] = la_ge
        @test LATeachingSuite.ge_svg([[nothing, [1 0; 0 1]]]) isa GenLAProblems.SVGOut
    finally
        GenLAProblems._LAFigureSpecs[] = old_ge_la
    end

    la = _py_ns_lat()
    ml = _py_ns_lat()
    _py_setattr_lat(la, "gram_schmidt_qr_matrices", (A; kwargs...) -> Any[[nothing, nothing], [nothing, nothing]])
    _py_setattr_lat(la, "qr_tbl_spec_from_matrices", (mats; kwargs...) -> begin
        py = GenLAProblems._ensure_pythoncall()
        Base.invokelatest(py.pydict, Dict("kind" => "qr"))
    end)
    _py_setattr_lat(la, "qr_svg", (args...; kwargs...) -> "<svg>qr-direct</svg>")
    _py_setattr_lat(ml, "render_qr_svg", (; kwargs...) -> "<svg>qr</svg>")
    old_la = GenLAProblems._LAFigureSpecs[]
    old_ml = GenLAProblems._matrixlayout[]
    try
        GenLAProblems._LAFigureSpecs[] = la
        GenLAProblems._matrixlayout[] = ml
        svg, mats = LATeachingSuite.qr_figure([1 0; 0 1])
        @test svg isa GenLAProblems.SVGOut
        @test mats !== nothing
        @test LATeachingSuite.qr_svg([1 0; 0 1]) isa GenLAProblems.SVGOut
    finally
        GenLAProblems._LAFigureSpecs[] = old_la
        GenLAProblems._matrixlayout[] = old_ml
    end
end

@testset "Display helper wrapper contracts" begin
    @test_throws ErrorException LATeachingSuite.py_show_svg(123)
    @test_throws ErrorException LATeachingSuite.show_svg(123)
    I2 = [1.0 0.0; 0.0 1.0]
    @test LATeachingSuite.l_show_svd(I2, I2, I2, I2, 1) === nothing
end

@testset "Bundle wrapper forwarding contracts" begin
    la = _py_ns_lat()
    seen = Dict{Symbol,Dict{Symbol,Any}}()

    function fake_bundle(kind::Symbol)
        return function(args...; kwargs...)
            seen[kind] = Dict(kwargs)
            py = GenLAProblems._ensure_pythoncall()
            return Base.invokelatest(py.pydict, Dict(
                "spec" => Base.invokelatest(py.pydict, Dict("kind" => String(kind), "argc" => length(args))),
                "svg" => "<svg>$(kind)</svg>",
            ))
        end
    end

    _py_setattr_lat(la, "ge_tbl_bundle", fake_bundle(:ge))
    _py_setattr_lat(la, "qr_tbl_bundle", fake_bundle(:qr))
    _py_setattr_lat(la, "eig_tbl_bundle", fake_bundle(:eig))
    _py_setattr_lat(la, "svd_tbl_bundle", fake_bundle(:svd))

    old_la = GenLAProblems._LAFigureSpecs[]
    try
        GenLAProblems._LAFigureSpecs[] = la

        for (kind, fn) in [
            (:ge, LATeachingSuite.ge_bundle),
            (:qr, LATeachingSuite.qr_bundle),
            (:eig, LATeachingSuite.eig_bundle),
            (:svd, LATeachingSuite.svd_bundle),
        ]
            svg, spec = fn([1 0; 0 1]; output_dir="/tmp/lat", render_opts=Dict("crop" => "tight"))
            @test svg isa GenLAProblems.SVGOut
            @test occursin(string(kind), svg.svg)
            @test seen[kind][:output_dir] == "/tmp/lat"
            @test haskey(seen[kind], :render_opts)
            py = GenLAProblems._ensure_pythoncall()
            @test Base.invokelatest(py.pyconvert, String, spec["kind"]) == String(kind)
            @test Base.invokelatest(py.pyconvert, Int, spec["argc"]) == 1
        end
    finally
        GenLAProblems._LAFigureSpecs[] = old_la
    end
end
