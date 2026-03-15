## csvdb handoff

Date: 2026-03-14 UTC
Workspace: `/home/wecker/git/qec_team/qeclib/dbwz8/csvdb`

### Current production run

- SLURM array jobs: `4353503` on `cpus`, `4353544` on `cgpus`
- Run dir: `/home/wecker/git/qec_team/qeclib/dbwz8/csvdb/slurm_runs/qdist_array/20260314T135554Z`
- Workset table: `ionq-qec.csvdb_core._qdist_buffered_frontier_20260314T135554Z`
- Total shards: `728`
- Uploads enabled: yes
- Migrated shard range: `288-727` moved from `4353503` to `4353544`

Latest snapshot when this note was written:

- `uploaded=8`
- `compute=8`
- `started=18`
- Active shard estimate: `10`
- Average uploaded shard time: about `28m`
- Rough ETA from the split run: about `34h 27m`
- Original `cpus` array now owns pending range `13-287`
- New `cgpus` array owns range `288-727`

### Smoke run already completed

- Smoke SLURM job: `4353480`
- Smoke output dir: `/home/wecker/git/qec_team/qeclib/dbwz8/csvdb/slurm_runs/qdist_smoke/20260314T135410Z-job4353480`
- Smoke attempts and summaries were successfully loaded into BigQuery

### Important fixes made before the run

- Added `pytest-xdist` to dev deps in `pyproject.toml` and updated `uv.lock`
- Fixed `scripts/submit_qdist_array.sh` to pass SLURM nice as `--nice=10000`
- Fixed `scripts/submit_qdist_array.sh` JSON parsing to allow spaces after `:`
- Reused the already-materialized production workset after the first submitter failure

### Notes on shard 00000

- Shard `00000` reached compute completion and generated:
  - `attempts.ndjson`
  - `summary.ndjson`
  - `worker_metrics.json`
- During the last check it was still in the upload/merge phase
- Earlier completed reference shards were `00002`, `00003`, and `00004`

### Monitoring commands

Queue status:

```bash
watch -n 30 "squeue -j 4353503,4353544 -o '%.18i %.2t %.10M %R' | sed -n '1,20p'"
```

One-shot monitor script with both jobs:

```bash
scripts/monitor_qdist_array.sh --once --no-clear \
  --run-dir /home/wecker/git/qec_team/qeclib/dbwz8/csvdb/slurm_runs/qdist_array/20260314T135554Z \
  --job-id 4353503,4353544
```

Progress counters:

```bash
RUN=/home/wecker/git/qec_team/qeclib/dbwz8/csvdb/slurm_runs/qdist_array/20260314T135554Z
TOTAL=728
uploaded=$(find "$RUN/shards" -name load_summary.json 2>/dev/null | wc -l)
compute=$(find "$RUN/shards" -name worker_metrics.json 2>/dev/null | wc -l)
started=$(find "$RUN/shards" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
printf 'uploaded=%d/%d (%.2f%%) compute_done=%d/%d (%.2f%%) started=%d/%d (%.2f%%)\n' \
  "$uploaded" "$TOTAL" "$(awk -v a=$uploaded -v b=$TOTAL 'BEGIN{print 100*a/b}')" \
  "$compute" "$TOTAL" "$(awk -v a=$compute -v b=$TOTAL 'BEGIN{print 100*a/b}')" \
  "$started" "$TOTAL" "$(awk -v a=$started -v b=$TOTAL 'BEGIN{print 100*a/b}')"
```

ETA estimate from completed shard wall times:

```bash
RUN=/home/wecker/git/qec_team/qeclib/dbwz8/csvdb/slurm_runs/qdist_array/20260314T135554Z
TOTAL=728
uploaded=$(find "$RUN/shards" -name load_summary.json -print 2>/dev/null | wc -l)
active=$(squeue -j 4353503,4353544 -h -o '%i %t' | awk '$2=="R"{c++} END{print c+0}')
avg=$(find "$RUN/shards" -name worker_metrics.json -print0 2>/dev/null | \
  xargs -0 -r grep -h '"wall_elapsed_seconds":' | sed 's/[^0-9.]//g' | \
  awk '{s+=$1;n++} END{if(n) print s/n; else print 0}')
remaining=$((TOTAL-uploaded))
awk -v rem="$remaining" -v act="$active" -v avg="$avg" \
  'BEGIN{if(act>0 && avg>0) printf("ETA %.1f hours\n", rem*avg/(act*3600)); else print "ETA unavailable yet"}'
```

Watch first shard logs:

```bash
tail -f /home/wecker/git/qec_team/qeclib/dbwz8/csvdb/slurm_runs/qdist_array/20260314T135554Z/slurm-4353503_0.err
```

### If resuming

Start by checking:

1. `squeue -j 4353503,4353544`
2. uploaded/compute counters under the run dir
3. whether `shards/00000/load_summary.json` exists yet
4. if a shard looks stuck, compare its files to completed shards `00002-00004`

---

## Next ingest readiness (SLURM ingest pipeline)

Before the next ingest run:

1. Commit/push the SLURM ingest changes and pull them on `obsidian`.
2. Verify prerequisites on `obsidian`:
   - SLURM access (`sbatch`, `squeue`)
   - active `qeclib` env / `uv`
   - Drive + GCP auth (`CSVDB_SERVICE_ACCOUNT_FILE` or ADC)
3. Run pipeline wiring dry-run:

```bash
scripts/submit_ingest_slurm.sh --dry-run
```

4. Run a tiny rehearsal with no BQ writes:

```bash
scripts/submit_ingest_slurm.sh \
  --max-files 1 \
  --analysis-mode best_effort \
  --enable-distance-stage \
  --dry-run
```

5. Run a small real SLURM submission still without BQ writes:
   - do **not** pass `--apply-bq-writes`
   - do **not** pass `--submit-distance`

6. Monitor progress:

```bash
scripts/monitor_ingest_slurm.sh --run-dir ./slurm_runs/ingest_array/<RUN_ID>
```

### Serial distance dependency (current default)

Distance stage is intentionally serialized after orthogonality finalization.

- Current dependency: `afterok:$FINALIZE_ORTH_JOB_ID`
- Throughput rollback if needed: switch back to `afterok:$FINALIZE_BASE_JOB_ID`

This rollback note is in:

- `scripts/submit_ingest_slurm.sh`
- `README.md`
