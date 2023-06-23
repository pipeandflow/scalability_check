Running
========
```bash
snakemake --cluster 'qsub -q hirshb-new -l nodes={params.nodes}:ppn={params.threads}' --cluster-cancel 'qdel' --latency-wait 30  -j 10 plot_node_scalability
```
