module LATeachingSuite

using Reexport

@reexport using GenLAProblems

module WorkflowDisplay

using Reexport

@reexport using GenLAProblems.WorkflowDisplay

end

module PythonBridge

using Reexport

@reexport using GenLAProblems.PythonBridge

end

load_LAFigureSpecs() = GenLAProblems.load_LAFigureSpecs()
load_matrixlayout() = GenLAProblems.load_matrixlayout()
la_version() = GenLAProblems.la_version()
la_build() = GenLAProblems.la_build()
ml_version() = GenLAProblems.ml_version()
ml_build() = GenLAProblems.ml_build()
show_svg(args...; kwargs...) = GenLAProblems.show_svg(args...; kwargs...)
py_show_svg(args...; kwargs...) = GenLAProblems.py_show_svg(args...; kwargs...)
l_show_svd(args...; kwargs...) = GenLAProblems.l_show_svd(args...; kwargs...)

export WorkflowDisplay, PythonBridge
export load_LAFigureSpecs, load_matrixlayout
export la_version, la_build, ml_version, ml_build
export show_svg, py_show_svg, l_show_svd

end
