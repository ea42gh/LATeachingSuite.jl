FROM ea42gh/la-course:0.2

ENV JULIA_CONDAPKG_BACKEND=Null
ENV CONDAPKG_BACKEND=Null
ENV JULIA_PYTHONCALL_EXE=/usr/local/bin/python3
ENV JULIA_PROJECT=/home/jovyan/LATeachingSuite
ENV JULIACALL_PROJECT=/home/jovyan/LATeachingSuite
ENV PYTHON_JULIACALL_EXE=/usr/local/julia/bin/julia
ENV PYTHON_JULIACALL_PROJECT=/home/jovyan/LATeachingSuite
ENV PYJULIAPKG_PROJECT=/home/jovyan/LATeachingSuite
ENV JULIAPKG_PROJECT=/home/jovyan/LATeachingSuite
ENV JULIA_PKG_PRECOMPILE_AUTO=0
ENV JULIA_NUM_THREADS=1
ENV JULIA_NUM_PRECOMPILE_TASKS=1
ENV OPENBLAS_NUM_THREADS=1
ENV MKL_NUM_THREADS=1
ENV OMP_NUM_THREADS=1
ENV TERM=xterm-256color
ENV INPUTRC=/home/jovyan/.inputrc
ENV XDG_DATA_HOME=/home/jovyan/.local/share
ENV JUPYTER_DATA_DIR=/home/jovyan/.local/share/jupyter

USER root
WORKDIR /tmp

RUN mkdir -p /home/jovyan/LATeachingSuite \
 && chown -R jovyan:jovyan /home/jovyan/LATeachingSuite

RUN /usr/local/bin/python3 -m pip install --no-cache-dir --upgrade pip setuptools wheel \
 && /usr/local/bin/python3 -m pip install --no-cache-dir \
    sympy \
    "matrixlayout[render] @ git+https://github.com/ea42gh/matrixlayout.git@a449033c1b4ebce9913dfd2f3820b88c76b6f5e8" \
    "LAFigureSpecs @ git+https://github.com/ea42gh/LAFigureSpecs.git@84bec61d56f07fffa4ca7e9c0476c12e2847e274"

USER jovyan
WORKDIR /home/jovyan/LATeachingSuite

COPY . /home/jovyan/LATeachingSuite

USER root
RUN chown -R jovyan:jovyan /home/jovyan/LATeachingSuite

RUN mkdir -p /home/jovyan/work \
 && chown -R jovyan:jovyan /home/jovyan/work \
 && chmod -R u+rwX /home/jovyan/work

COPY --chown=jovyan:jovyan LATeachingSuite_demo.ipynb /home/jovyan/work/LATeachingSuite_demo.ipynb

USER jovyan

RUN bash binder/postBuild

EXPOSE 8888
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--no-browser", "--ServerApp.token=", "--ServerApp.password=", "--ServerApp.root_dir=/home/jovyan/work", "--notebook-dir=/home/jovyan/work"]
