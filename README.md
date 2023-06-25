General
========
The workflow separated to core and node scalability checks. Core scalability checks scalibility on same node.
Node scalability checks scalability in multi node configurtartion.

Edit the file `config.yaml` to set the parameters of the workflow.

Running
========
```bash
snakemake --cluster 'qsub -q hirshb-new -l nodes={params.nodes}:ppn={params.threads}' --cluster-cancel 'qdel' --latency-wait 30  -j 10 plot_node_scalability
```
