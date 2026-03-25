#!/bin/bash
# Full reproduction: Table 2 (nref=5,10) + Figure 4 (Options A, B, C)
# Uses srun so each job blocks until complete — no polling needed.
cd /home/nk725/NoisyFlow
source /home/nk725/.venv/bin/activate

SRUN_BASE="srun --partition=gpu_devel --gpus=1 --cpus-per-task=4 --mem=16G --time=1:00:00"
SRUN_LONG="srun --partition=gpu_devel --gpus=1 --cpus-per-task=4 --mem=16G --time=2:00:00"

run_job() {
    local name=$1
    local config=$2
    local logfile=$3
    local srun_args=${4:-$SRUN_BASE}

    echo "[run] ${name} started at $(date)"
    ${srun_args} --job-name=${name} --output=${logfile} \
        bash -c "source /home/nk725/.venv/bin/activate && cd /home/nk725/NoisyFlow && python run.py --config ${config}"
    echo "[run] ${name} done at $(date)"
    grep -o "'acc': [0-9.]*" ${logfile} 2>/dev/null | head -1
}

echo "=== TABLE 2: nref=5 ==="
for s in 0 1 2 3 4; do
    run_job "t2_r5_s${s}" \
        "configs/cellot_lupus_kang_table2_ref5_seed${s}.yaml" \
        "logs/table2_ref5_seed${s}.log"
done

echo "=== TABLE 2: nref=10 ==="
for s in 0 1 2 3 4; do
    run_job "t2_r10_s${s}" \
        "configs/cellot_lupus_kang_table2_ref10_seed${s}.yaml" \
        "logs/table2_ref10_seed${s}.log"
done

echo "=== FIGURE 4: Option A ==="
run_job "fig4_optA" \
    "configs/privacy_curve_optA_gpu.yaml" \
    "logs/fig4_optA.log" \
    "$SRUN_LONG"

echo "=== FIGURE 4: Option B ==="
run_job "fig4_optB" \
    "configs/privacy_curve_optB_gpu.yaml" \
    "logs/fig4_optB.log" \
    "$SRUN_LONG"

echo "=== FIGURE 4: Option C ==="
run_job "fig4_optC" \
    "configs/privacy_curve_optC_gpu.yaml" \
    "logs/fig4_optC.log" \
    "$SRUN_LONG"

echo "=== ALL JOBS COMPLETE at $(date) ==="
echo "=== Generating Figure 4... ==="
python scripts/plot_privacy_curve_stage2_schemes.py \
    --private tex/privacy_utility_cellot_ref50_acc_ref_plus_synth.json \
    --syn     tex/privacy_curve_stage2_syn_nodp.json \
    --mixed   tex/privacy_curve_stage2_mixed_dp.json \
    --output  tex/figure4_repro_full.pdf \
    --png     tex/figure4_repro_full.png
echo "=== Figure 4 saved to tex/figure4_repro_full.pdf and .png ==="

echo "=== TABLE 1: Mixture of Gaussians ==="
run_job "mog_t1" \
    "configs/mog_table1_option_c.yaml" \
    "logs/mog_table1.log"
echo "=== MoG Table 1 done ==="
grep "RF-synth\|RF-ref_only\|RF-ref+syn\|Final stats" logs/mog_table1.log 2>/dev/null
