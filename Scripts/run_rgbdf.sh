#!/usr/bin/env bash 

# Путь к вашему набору данных
DATASET_PATH="/mnt/c/datasets/2024-10-09-21_01_08"

# Путь к словарю ORBvoc
VOCABULARY_PATH="../Vocabulary/ORBvoc.txt"

# Путь к вашему файлу конфигурации камеры
CAMERA_CONFIG_PATH="../Settings/cat3_pinhole_plvs.yaml"

# Исполняемый файл PLVS1 для монокулярного режима
EXECUTABLE="../Examples/RGB-D/rgbd_tum"

ASSOCIATIONS="associate.txt"

# Запуск
$EXECUTABLE $VOCABULARY_PATH $CAMERA_CONFIG_PATH $DATASET_PATH $DATASET_PATH/$ASSOCIATIONS
