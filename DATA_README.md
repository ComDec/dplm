# Data and Checkpoints Guide

This document describes all data files, checkpoints, and large assets needed to
train, fine-tune, and evaluate DPLM / DPLM-2 models. None of these files are
stored in git; each must be downloaded separately after cloning.

---

## Directory structure after setup

```
dplm/
  data-bin/
    uniref50_hf/          # UniRef50 sequences (HuggingFace datasets format)
    pdb_swissprot/        # PDB + SwissProt structures (HuggingFace datasets format)
    pdb_swissprot.csv     # 220k-row CSV mapping PDB/SwissProt entries to structure tokens, sequences, metadata
    metadata/
      pdb_afdb_cameo.csv  # ~347k-row metadata CSV for PDB, AlphaFold DB, and CAMEO entries
      pdb_date.csv        # ~450-row PDB date-split test set metadata
    cameo2022/
      aatype.fasta        # amino acid sequences for CAMEO 2022 test set
      struct.fasta        # tokenized structure tokens for CAMEO 2022 test set
      preprocessed/       # preprocessed .pkl files per protein chain
    PDB_date/
      aatype.fasta        # amino acid sequences for PDB date-split test set
      struct.fasta        # tokenized structure tokens for PDB date-split test set
      preprocessed/       # preprocessed .pkl files per PDB entry (~3.9 GB)
    cath_4.2/             # CATH 4.2 dataset (inverse folding)
    cath_4.3/             # CATH 4.3 dataset (inverse folding)
    scaffolding-pdbs/     # motif scaffolding PDB files and tokenized FASTA files
  logs/                   # training outputs: checkpoints, Hydra configs, wandb logs
  generation-results/     # inference outputs
```

---

## 1. DPLM-2 metadata (test sets and evaluation data)

**File:** `dplm2_metadata.tar.gz` (~817 MB)

**Contains:** preprocessed CAMEO 2022 test set, PDB date-split test set, and
associated metadata CSVs. After extraction these populate
`data-bin/cameo2022/`, `data-bin/PDB_date/`, and `data-bin/metadata/`.

**Source:** Zenodo record 15424801 (published by the DPLM authors).

**Download and extract:**

```bash
bash scripts/download_metadata.sh
```

Or manually:

```bash
wget -O dplm2_metadata.tar.gz \
  "https://zenodo.org/records/15424801/files/dplm2_metadata.tar.gz?download=1"
mkdir -p data-bin
tar -xzvf dplm2_metadata.tar.gz -C ./data-bin/
```

**Origin of test data:**
- CAMEO 2022 structures are from [EigenFold](https://github.com/bjing2016/EigenFold).
- PDB date-split test set is from [MultiFlow](https://github.com/jasonkyuyim/multiflow).
- The DPLM authors preprocessed and tokenized these into `.pkl` and `.fasta` files.

---

## 2. PDB + SwissProt training data (DPLM-2)

**Directory:** `data-bin/pdb_swissprot/` (HuggingFace datasets Arrow format)

**Purpose:** Primary training data for DPLM-2. Contains experimental PDB
structures and AlphaFold2-predicted SwissProt structures, preprocessed with
structure tokenization.

**Source:** HuggingFace dataset [`airkingbd/pdb_swissprot`](https://huggingface.co/datasets/airkingbd/pdb_swissprot).

**Download:**

```bash
bash scripts/download_pdb_swissprot_hf.sh
```

Or manually:

```bash
pip install huggingface_hub
mkdir -p data-bin
huggingface-cli download airkingbd/pdb_swissprot \
  --repo-type dataset --local-dir ./data-bin/pdb_swissprot
```

### pdb_swissprot.csv

**File:** `data-bin/pdb_swissprot.csv` (~774 MB, ~220k rows)

This CSV is an index/metadata file that maps each protein to its structure
tokens, amino acid sequence, pLDDT scores, resolution, secondary structure
fractions, and other annotations. It is used by the `TokenizedProteinDatamodule`
when training DPLM-2 in CSV mode (as opposed to HuggingFace datasets mode).

The CSV can be regenerated from the HuggingFace dataset, or it may already exist
if extracted from the metadata archive. For the GenX fine-tuning workflow
(`scripts/train_finetune_200k.sh`), this CSV is loaded directly via the
`datamodule.csv_file=pdb_swissprot.csv` config override.

**If you only need HuggingFace datasets mode**, you do not need this CSV.

---

## 3. UniRef50 training data (DPLM pretraining)

**Directory:** `data-bin/uniref50_hf/` (HuggingFace datasets Arrow format)

**Purpose:** ~42 million protein sequences used for pretraining DPLM (sequence-only model).

**Source:** HuggingFace dataset [`airkingbd/uniref50`](https://huggingface.co/datasets/airkingbd/uniref50),
originally from the [EvoDiff](https://www.biorxiv.org/content/10.1101/2023.09.11.556673v1)
preprocessed version of UniRef50 ([Zenodo](https://zenodo.org/record/6564798)).

**Download:**

```bash
bash scripts/download_uniref50_hf.sh
```

Or manually:

```bash
pip install huggingface_hub
mkdir -p data-bin
huggingface-cli download airkingbd/uniref50 \
  --repo-type dataset --local-dir ./data-bin/uniref50_hf
```

---

## 4. CATH datasets (inverse folding)

**Directories:** `data-bin/cath_4.2/`, `data-bin/cath_4.3/`

**Purpose:** Training and evaluation data for inverse folding (structure-conditioned sequence generation).

**Sources:**
- CATH 4.2: [Ingraham et al., NeurIPS 2019](https://papers.nips.cc/paper/2019/hash/f3a4ff4839c56a5f460c88cce3666a2b-Abstract.html)
- CATH 4.3: [Hsu et al., ICML 2022](https://www.biorxiv.org/content/10.1101/2022.04.10.487779v1) (via Meta FAIR)

**Download:**

```bash
bash scripts/download_cath.sh
```

Or manually:

```bash
mkdir -p data-bin
# CATH 4.2
wget -r -nd -np http://people.csail.mit.edu/ingraham/graph-protein-design/data/cath/ \
  -P data-bin/cath_4.2

# CATH 4.3
mkdir -p data-bin/cath_4.3
wget -r -nd -np https://dl.fbaipublicfiles.com/fair-esm/data/cath4.3_topologysplit_202206/chain_set.jsonl \
  -P data-bin/cath_4.3
wget -r -nd -np https://dl.fbaipublicfiles.com/fair-esm/data/cath4.3_topologysplit_202206/split.jsonl \
  -P data-bin/cath_4.3
```

---

## 5. Motif scaffolding PDB files

**Directory:** `data-bin/scaffolding-pdbs/`

**Purpose:** PDB files and tokenized structure FASTA files for the motif
scaffolding benchmark (24 problems from FrameFlow/EvoDiff).

**Source:** Zenodo record 15424801.

**Download:**

```bash
bash scripts/download_motif_scaffolds.sh
```

Or manually:

```bash
wget -O motif_scaffolding_pdbs.tar.gz \
  "https://zenodo.org/records/15424801/files/motif_scaffolding_pdbs.tar.gz?download=1"
mkdir -p data-bin
tar -xzvf motif_scaffolding_pdbs.tar.gz -C ./data-bin/
```

---

## 6. Model checkpoints

### Pretrained models (from upstream)

All pretrained DPLM and DPLM-2 checkpoints are hosted on HuggingFace and loaded
automatically by `from_pretrained()`:

| Model | HuggingFace ID | Size |
|-------|----------------|------|
| DPLM 150M | [`airkingbd/dplm_150m`](https://huggingface.co/airkingbd/dplm_150m) | 150M params |
| DPLM 650M | [`airkingbd/dplm_650m`](https://huggingface.co/airkingbd/dplm_650m) | 650M params |
| DPLM 3B | [`airkingbd/dplm_3b`](https://huggingface.co/airkingbd/dplm_3b) | 3B params |
| DPLM-2 150M | [`airkingbd/dplm2_150m`](https://huggingface.co/airkingbd/dplm2_150m) | 150M params |
| DPLM-2 650M | [`airkingbd/dplm2_650m`](https://huggingface.co/airkingbd/dplm2_650m) | 650M params |
| DPLM-2 3B | [`airkingbd/dplm2_3b`](https://huggingface.co/airkingbd/dplm2_3b) | 3B params |
| DPLM-2 Bit 650M | [`airkingbd/dplm2_bit_650m`](https://huggingface.co/airkingbd/dplm2_bit_650m) | 650M params |

These are downloaded and cached automatically by HuggingFace Hub when you call:

```python
from byprot.models.dplm2 import MultimodalDiffusionProteinLanguageModel as DPLM2
model = DPLM2.from_pretrained("airkingbd/dplm2_650m")
```

### Fine-tuned checkpoints (local training outputs)

Training produces checkpoints under `logs/<experiment_name>/checkpoints/`. For
example, a DPLM-2 fine-tuning run on PDB+SwissProt with 200k-step config
produces:

```
logs/dplm2_finetune_200k/
  checkpoints/
    last.ckpt           # most recent checkpoint
    best.ckpt           # best validation loss
    step_*.ckpt         # periodic saves
  .hydra/               # Hydra config snapshot
  train.log
  wandb/                # W&B run data
```

These are generated by your own training runs and are NOT distributed. Each
`.ckpt` file is typically 2-4 GB for a 650M-parameter model. The `logs/`
directory is gitignored.

---

## Quick setup (download everything)

To set up all data for DPLM-2 training and evaluation:

```bash
# 1. Metadata (CAMEO 2022, PDB date test sets)
bash scripts/download_metadata.sh

# 2. PDB + SwissProt training data
bash scripts/download_pdb_swissprot_hf.sh

# 3. (Optional) UniRef50 for DPLM pretraining
bash scripts/download_uniref50_hf.sh

# 4. (Optional) CATH for inverse folding
bash scripts/download_cath.sh

# 5. (Optional) Motif scaffolding PDBs
bash scripts/download_motif_scaffolds.sh
```

---

## Notes

- The `data-bin/` directory and all its contents are gitignored. After a fresh
  clone, it will be empty and must be populated using the scripts above.
- Archives (`*.tar.gz`) downloaded to the repo root can be deleted after
  extraction.
- The `data-bin/README.md` file (tracked in upstream) documents the provenance
  of the CAMEO 2022 and PDB date test sets.
