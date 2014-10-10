#!/bin/bash
# Do not run this script directly. 
# Instead, run one of:
#   make run
#   make run-cpu
#   make run-mic
#   make run-both
# Make sure there're executable binaries before running any of these


source /opt/intel/composerxe/bin/compilervars.sh intel64
source /opt/intel/impi/5.0.1.035/bin64/mpivars.sh
export I_MPI_MIC=1
export I_MPI_DAPL_PROVIDER_LIST=ofa-v2-scif0
export I_MPI_FABRICS=dapl
export IMBHOST=${I_MPI_ROOT}/bin64/IMB-MPI1
export IMBMIC=${I_MPI_ROOT}/mic/bin/IMB-MPI1
ulimit -s unlimited

#Uncomment to give snapshot of available bandwidth 
#mpirun -np 1 -genv I_MPI_DEBUG=5  -host localhost ${IMBHOST} PingPong : -np 1 -host mic2 ${IMBMIC}
#mpirun -np 1 -genv I_MPI_DEBUG=5  -host localhost ${IMBHOST} PingPong : -np 1 -host mic3 ${IMBMIC}
#mpirun -np 1 -genv I_MPI_DEBUG=5  -host localhost ${IMBHOST} PingPong : -np 1 -host mic1 ${IMBMIC}
#mpirun -np 1 -genv I_MPI_DEBUG=5  -host localhost ${IMBHOST} PingPong : -np 1 -host mic0 ${IMBMIC}

if [ $# -ne 1 ]
then
    echo "Usage: ./run.sh [CPU|MIC|HETEROGENEOUS]" 
    exit
fi

if [ $1 == "CPU" ]
then
    echo "Running seq.cpu"
    ./seq.cpu
    echo -e "\nRunning omp.cpu"
    ./omp.cpu
    echo -e "\nRunning omp2.cpu"
    ./omp2.cpu

elif [ $1 == "MIC" ]
then
    export SINK_LD_LIBRARY_PATH=${MIC_LD_LIBRARY_PATH}
    echo -e "\nRunning seq.mic"
    micnativeloadex ./seq.mic 
    
    echo -e "\nRunning omp.mic"
    micnativeloadex ./omp.mic -e "OMP_NUM_THRAEDS=120" -e "KMP_AFFINITY=granularity=thread,compact" -e "KMP_PLACE_THREADS=60c,2t"

    echo -e "\nRunning omp2.mic"
    micnativeloadex ./omp2.mic -e "OMP_NUM_THRAEDS=60" -e "KMP_AFFINITY=granularity=thread,scatter" -e "KMP_PLACE_THREADS=60c,1t"
    
elif [ $1 == "HETEROGENEOUS" ]
then
    echo -e "\nRunning mpi.cpu on CPU and mpi.mic on MIC"
    export MIC_LD_LIB_DIR="$LD_LIBRARY_PATH:/opt/intel/lib/mic:/opt/intel/mkl/lib/mic"
    mpirun -np 1 -host localhost ./mpi.cpu \
	: -np 1 -host mic0 -env LD_LIBRARY_PATH=${MIC_LD_LIB_DIR} -env OMP_NUM_THRAEDS 60 -env KMP_PLACE_THREADS 60c,1t -env KMP_AFFINITY granularity=thread,scatter ./mpi.mic \
	: -np 1 -host mic1 -env LD_LIBRARY_PATH=${MIC_LD_LIB_DIR} -env OMP_NUM_THRAEDS 60 -env KMP_PLACE_THREADS 60c,1t -env KMP_AFFINITY granularity=thread,scatter ./mpi.mic \
	: -np 1 -host mic2 -env LD_LIBRARY_PATH=${MIC_LD_LIB_DIR} -env OMP_NUM_THRAEDS 60 -env KMP_PLACE_THREADS 60c,1t -env KMP_AFFINITY granularity=thread,scatter ./mpi.mic \
	: -np 1 -host mic3 -env LD_LIBRARY_PATH=${MIC_LD_LIB_DIR} -env OMP_NUM_THRAEDS 60 -env KMP_PLACE_THREADS 60c,1t -env KMP_AFFINITY granularity=thread,scatter ./mpi.mic
 
else
    echo "No matching case"
fi

echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~DONE~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
