@echo off
setlocal

set "BASE_PATH=C:\OMRON\Soft-NA\Storage\SDCard"
set "DATASETS_PATH=%BASE_PATH%\Data Logging\Log Files"
set "OPERATION_PATH=%BASE_PATH%\OperationLog"

:: Create base directories if they don't exist
mkdir "%DATASETS_PATH%\DataSet0" 2>nul
mkdir "%DATASETS_PATH%\DataSet1" 2>nul
mkdir "%DATASETS_PATH%\DataSet2" 2>nul
mkdir "%OPERATION_PATH%" 2>nul

:: Delete existing test folders
for %%G in (0,1,2) do (
    rd /s /q "%DATASETS_PATH%\DataSet%%G\*" 2>nul
)
rd /s /q "%OPERATION_PATH%\*" 2>nul

:: Create test folders in mixed order
:: Group 1: Newer than 18 days (after 07.11.2024) - 12 folders
for %%G in (0,1,2) do (
    mkdir "%DATASETS_PATH%\DataSet%%G\20241125"
    mkdir "%DATASETS_PATH%\DataSet%%G\20241108"
    mkdir "%DATASETS_PATH%\DataSet%%G\20241120"
    mkdir "%DATASETS_PATH%\DataSet%%G\20241112"
    mkdir "%DATASETS_PATH%\DataSet%%G\20241118"
    mkdir "%DATASETS_PATH%\DataSet%%G\20241115"
    mkdir "%DATASETS_PATH%\DataSet%%G\20241122"
    mkdir "%DATASETS_PATH%\DataSet%%G\20241110"
    mkdir "%DATASETS_PATH%\DataSet%%G\20241124"
    mkdir "%DATASETS_PATH%\DataSet%%G\20241116"
    mkdir "%DATASETS_PATH%\DataSet%%G\20241121"
    mkdir "%DATASETS_PATH%\DataSet%%G\20241109"
)

:: Group 2: Older than 18 days (before 07.11.2024) - 8 folders
for %%G in (0,1,2) do (
    mkdir "%DATASETS_PATH%\DataSet%%G\20241106"
    mkdir "%DATASETS_PATH%\DataSet%%G\20241101"
    mkdir "%DATASETS_PATH%\DataSet%%G\20241105"
    mkdir "%DATASETS_PATH%\DataSet%%G\20241102"
    mkdir "%DATASETS_PATH%\DataSet%%G\20241104"
    mkdir "%DATASETS_PATH%\DataSet%%G\20241107"
    mkdir "%DATASETS_PATH%\DataSet%%G\20241103"
    mkdir "%DATASETS_PATH%\DataSet%%G\20241111"
)

:: Create same folders in OperationLog
:: Group 1: Newer than 18 days
mkdir "%OPERATION_PATH%\20241125"
mkdir "%OPERATION_PATH%\20241108"
mkdir "%OPERATION_PATH%\20241120"
mkdir "%OPERATION_PATH%\20241112"
mkdir "%OPERATION_PATH%\20241118"
mkdir "%OPERATION_PATH%\20241115"
mkdir "%OPERATION_PATH%\20241122"
mkdir "%OPERATION_PATH%\20241110"
mkdir "%OPERATION_PATH%\20241124"
mkdir "%OPERATION_PATH%\20241116"
mkdir "%OPERATION_PATH%\20241121"
mkdir "%OPERATION_PATH%\20241109"

:: Group 2: Older than 18 days
mkdir "%OPERATION_PATH%\20241106"
mkdir "%OPERATION_PATH%\20241101"
mkdir "%OPERATION_PATH%\20241105"
mkdir "%OPERATION_PATH%\20241102"
mkdir "%OPERATION_PATH%\20241104"
mkdir "%OPERATION_PATH%\20241107"
mkdir "%OPERATION_PATH%\20241103"
mkdir "%OPERATION_PATH%\20241111"

echo Test directories created successfully!
