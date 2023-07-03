from snakemake.utils import min_version
min_version("7.23.0")

configfile: "config.yaml"

localrules: all, plot_core_scalability, plot_node_scalability

rule all:
    input:
        "results/core_scalability.png",
        "results/node_scalability.png"



rule plot_core_scalability:
    output:
        "results/core_scalability.png"
    input:
        expand('results/single_node/{num_cores}_cores.dat', num_cores=config['num_cores_single_node'])
    params:
        rundir = lambda wildcards, input: os.path.dirname(input[0]),
    shell:
        """
        set -x
        origdir=`pwd`
        cat {input} > timings
        mv timings {params.rundir}
        cd {params.rundir} 
        python ${{origdir}}/scripts/analyze_efficiency.py
        mv core_scalability.png ${{origdir}}/{output} 
        """




rule plot_node_scalability:
    output:
        "results/node_scalability.png"
    input:
        expand('results/multi_node/{num_nodes}_nodes_{num_cores_on_node}.dat', num_nodes=config['num_nodes'],
                num_cores_on_node=config['num_cores_on_node'])
    params:
        rundir = lambda wildcards, input: os.path.dirname(input[0]),
    shell:
        """
        origdir=`pwd`
        cat {input} > timings
        mv timings {params.rundir}
        cd {params.rundir} 
        python ${{origdir}}/scripts/analyze_efficiency.py
        mv core_scalability.png ${{origdir}}/{output} 
        """



rule run_single_node:
    input:
        'input/in.lj.singleNode'
    output:
        'results/single_node/{num_cores}_cores.dat'
    params:
        nodes = 1,
        threads = lambda wildcards: wildcards['num_cores'],
        rundir = lambda wildcards, output: os.path.dirname(output[0]),
        lmp = config['LMP']
    threads: lambda wildcards: int(wildcards['num_cores'])
    log:
        'log/log.lammps.{num_cores}.GNU'
    shell:
        """
        set -x
        module load gcc/gcc-12.1
        #module load openmpi/openmpi-4.1.5
        BASE_MPI=/usr/mpi/gcc/openmpi-4.1.5a1/
        export PATH="${{BASE_MPI}}/bin:$PATH"
        export LD_LIBRARY_PATH="${{BASE_MPI}}/lib:$LD_LIBRARY_PATH"
        ORIGDIR=`pwd`

        COMP=GNU
        RUNDIR={params.rundir}

        #send job
        cd $RUNDIR
        cat $PBS_NODEFILE
        mpirun -n {params.threads} --bind-to none --hostfile ${{PBS_NODEFILE}} {params.lmp} -in ${{ORIGDIR}}/{input[0]} -screen none -log ${{ORIGDIR}}/{log}
        cd ${{ORIGDIR}}
        grep Loop {log} >& {output}
        """

rule run_multi_node:
    input:
        'input/in.lj.multiNode'
    output:
        'results/multi_node/{num_nodes}_nodes_{num_cores_on_node}.dat'
    params:
        nodes = lambda wildcards: wildcards['num_nodes'],
        threads = lambda wildcards: wildcards['num_cores_on_node'],
        rundir = lambda wildcards, output: os.path.dirname(output[0]),
        total_procs = lambda wildcards: int(wildcards['num_nodes']) * int(wildcards['num_cores_on_node']),
        lmp = config['LMP']
    log:
        'log/log.lammps.{num_nodes}X{num_cores_on_node}.GNU'
    shell:
        """
        set -x
        module load gcc/gcc-12.1.0
        BASE_MPI=/usr/mpi/gcc/openmpi-4.1.5a1/
        export PATH="${{BASE_MPI}}/bin:$PATH"
        export LD_LIBRARY_PATH="${{BASE_MPI}}/lib:$LD_LIBRARY_PATH"
        ORIGDIR=`pwd`

        COMP=GNU
        RUNDIR={params.rundir}

        #send job
        cd $RUNDIR
        cat $PBS_NODEFILE
        mpirun -n {params.total_procs} --hostfile ${{PBS_NODEFILE}} {params.lmp} -in ${{ORIGDIR}}/{input[0]} -screen none -log ${{ORIGDIR}}/{log}
        cd ${{ORIGDIR}}
        grep Loop {log} >& {output}
        """
