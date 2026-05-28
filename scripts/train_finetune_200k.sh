#!/bin/bash
export CUDA_VISIBLE_DEVICES=1,4,5,6
cd /home/xiwang/project/UniGen/dplm

conda run -n genx python train.py \
    experiment=dplm2/dplm2_650m \
    name=dplm2_finetune_200k \
    datamodule.data_dir=/home/xiwang/project/UniGen/dplm/data-bin \
    datamodule.csv_file=pdb_swissprot.csv \
    datamodule.max_tokens=4000 \
    datamodule.max_len=512 \
    trainer.devices=4 \
    trainer.max_steps=100000 \
    trainer.val_check_interval=500 \
    trainer.enable_progress_bar=false \
    trainer.num_sanity_val_steps=0 \
    logger=wandb \
    logger.wandb.project=genx \
    logger.wandb.name=dplm2_finetune_200k \
    2>&1 | tee /data/xiwang_home/project/UniGen/GenX/logs/train_dplm2_finetune.log
