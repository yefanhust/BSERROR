# Requires to have intel compiler and Intel Xeon Phi coprocessor

CXXFLAGS=-Wall -std=c99 -mkl -openmp -O2
MICFLAGS=-mmic 
HOSTFLAGS=-xAVX

all: par_mpi.c par_omp.c par_omp2.c seq.c inc/*
	mpiicc $(CXXFLAGS) $(MICFLAGS) -o mpi.mic par_mpi.c
	mpiicc $(CXXFLAGS) $(HOSTFLAGS) -o mpi.cpu par_mpi.c
	icc $(CXXFLAGS) $(MICFLAGS) -o omp.mic par_omp.c
	icc $(CXXFLAGS) $(HOSTFLAGS) -o omp.cpu par_omp.c
	icc $(CXXFLAGS) $(MICFLAGS) -o omp2.mic par_omp2.c
	icc $(CXXFLAGS) $(HOSTFLAGS) -o omp2.cpu par_omp2.c
	icc $(CXXFLAGS) $(MICFLAGS) -o seq.mic seq.c
	icc $(CXXFLAGS) $(HOSTFLAGS) -o seq.cpu seq.c

clean: 
	rm -f *.cpu *.mic run *.out

run: run-cpu run-mic run-both

run-cpu:
	./run.sh CPU

run-mic:
	./run.sh MIC

run-both:
	./run.sh HETEROGENEOUS
