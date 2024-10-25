#!/usr/bin/env bash 

# Путь к вашему набору данных
DATASET_PATH="/datasets/2024-09-04-23_12_43"

# Путь к словарю ORBvoc
VOCABULARY_PATH="../Vocabulary/ORBvoc.txt"

# Путь к вашему файлу конфигурации камеры
CAMERA_CONFIG_PATH="../Settings/cat3_pinhole_plvs.yaml"

# Исполняемый файл PLVS1 для монокулярного режима
EXECUTABLE="../Examples/Monocular/mono_tum"

# Запуск
$EXECUTABLE $VOCABULARY_PATH $CAMERA_CONFIG_PATH $DATASET_PATH

./evaluate_tum.sh $DATASET_PATH 
./move_output_to_results.sh