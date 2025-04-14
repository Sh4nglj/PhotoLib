@echo off
setlocal EnableDelayedExpansion

:: 同步删除：删除raw文件夹中对应于jpg文件夹中已删除的照片

:: 默认设置
set DRY_RUN=true
set MOVE_TO_TRASH=false
set TRASH_DIR=

:: 帮助信息函数
goto :main

:show_help
    echo 用法: %0 [选项]
    echo.
    echo 选项:
    echo   --dir ^<目录^>       照片的父目录路径，其下应有jpg和raw子目录
    echo   --jpg ^<目录^>       JPG照片目录的路径（与--raw一起使用）
    echo   --raw ^<目录^>       RAW照片目录的路径（与--jpg一起使用）
    echo   --execute          执行实际删除操作（默认为试运行模式）
    echo   --trash            移动到回收站而不是直接删除
    echo   --trash-dir ^<目录^> 自定义回收站目录
    echo   --help             显示此帮助信息
    echo.
    echo 示例:
    echo   %0 --dir C:\Photos
    echo   %0 --jpg C:\Photos\jpg --raw C:\Photos\raw --execute
    echo   %0 --dir C:\Photos --execute --trash
    exit /b 0

:main
:: 解析命令行参数
:parse_args
if "%~1"=="" goto :check_args
if "%~1"=="--dir" (
    set "PARENT_DIR=%~2"
    shift /1
    shift /1
    goto :parse_args
)
if "%~1"=="--jpg" (
    set "JPG_DIR=%~2"
    shift /1
    shift /1
    goto :parse_args
)
if "%~1"=="--raw" (
    set "RAW_DIR=%~2"
    shift /1
    shift /1
    goto :parse_args
)
if "%~1"=="--execute" (
    set DRY_RUN=false
    shift /1
    goto :parse_args
)
if "%~1"=="--trash" (
    set MOVE_TO_TRASH=true
    shift /1
    goto :parse_args
)
if "%~1"=="--trash-dir" (
    set "TRASH_DIR=%~2"
    shift /1
    shift /1
    goto :parse_args
)
if "%~1"=="--help" (
    call :show_help
    exit /b 0
)
echo 错误: 未知选项 %1
call :show_help
exit /b 1

:check_args
:: 检查参数逻辑
if defined PARENT_DIR (
    :: 使用父目录
    set "JPG_DIR=%PARENT_DIR%\jpg"
    set "RAW_DIR=%PARENT_DIR%\raw"
) else if defined JPG_DIR if defined RAW_DIR (
    :: 使用分别指定的目录
    rem 什么都不做
) else (
    echo 错误: 必须指定 --dir 或同时指定 --jpg 和 --raw
    call :show_help
    exit /b 1
)

:: 确保目录存在
if not exist "%JPG_DIR%\" (
    echo 错误: JPG目录不存在: %JPG_DIR%
    exit /b 1
)

if not exist "%RAW_DIR%\" (
    echo 错误: RAW目录不存在: %RAW_DIR%
    exit /b 1
)

:: 设置回收站目录
for %%i in ("%RAW_DIR%") do set "RAW_DIR_PARENT=%%~dpi"
if "%MOVE_TO_TRASH%"=="true" if not defined TRASH_DIR (
    set "TRASH_DIR=%RAW_DIR_PARENT%deleted_photos"
)

if "%MOVE_TO_TRASH%"=="true" if not exist "%TRASH_DIR%\" (
    mkdir "%TRASH_DIR%"
)

:: 创建临时文件
set "TEMP_DIR=%TEMP%\sync_photos_temp"
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"
set "JPG_NAMES_FILE=%TEMP_DIR%\jpg_names.txt"
set "RAW_NAMES_FILE=%TEMP_DIR%\raw_names.txt"
set "TO_DELETE_FILE=%TEMP_DIR%\to_delete.txt"

:: 清空临时文件
if exist "%JPG_NAMES_FILE%" del "%JPG_NAMES_FILE%"
if exist "%RAW_NAMES_FILE%" del "%RAW_NAMES_FILE%"
if exist "%TO_DELETE_FILE%" del "%TO_DELETE_FILE%"

echo 搜索JPG文件...
:: 查找所有JPG文件，并提取基本文件名（不含扩展名）
for /r "%JPG_DIR%" %%f in (*.jpg *.jpeg *.JPG *.JPEG) do (
    set "filename=%%~nf"
    echo !filename!>>"%JPG_NAMES_FILE%"
)

echo 搜索RAW文件...
:: 定义RAW格式扩展名
set "RAW_EXTENSIONS=.raw .RAW .arw .ARW .cr2 .CR2 .cr3 .CR3 .nef .NEF .dng .DNG .orf .ORF .rw2 .RW2 .raf .RAF .pef .PEF .x3f .X3F .rwl .RWL .3fr .3FR .fff .FFF .iiq .IIQ .kdc .KDC .dcr .DCR .srw .SRW"
set RAW_COUNT=0

:: 查找所有RAW文件
for %%e in (%RAW_EXTENSIONS%) do (
    set COUNT=0
    for /r "%RAW_DIR%" %%f in (*%%e) do (
        set /a COUNT+=1
        set "raw_filename=%%~nf"
        echo !raw_filename!^|%%f>>"%RAW_NAMES_FILE%"
    )
    if !COUNT! gtr 0 (
        echo 找到 !COUNT! 个 %%e 格式文件
        set /a RAW_COUNT+=!COUNT!
    )
)

echo 总共找到 %RAW_COUNT% 个RAW文件

:: 查找需要删除的RAW文件 - 存在于RAW目录但不存在于JPG目录
echo 对比文件列表...
for /f "tokens=1,2 delims=|" %%a in (%RAW_NAMES_FILE%) do (
    set "FOUND=false"
    for /f "usebackq" %%c in ("%JPG_NAMES_FILE%") do (
        if "%%a"=="%%c" set "FOUND=true"
    )
    if "!FOUND!"=="false" (
        echo %%b>>"%TO_DELETE_FILE%"
    )
)

:: 统计要删除的文件数量
set TO_DELETE_COUNT=0
for /f %%a in (%TO_DELETE_FILE%) do set /a TO_DELETE_COUNT+=1

:: 显示并处理要删除的文件
if %TO_DELETE_COUNT% gtr 0 (
    echo 找到 %TO_DELETE_COUNT% 个需要删除的RAW文件:
    for /f "usebackq" %%a in ("%TO_DELETE_FILE%") do (
        echo   - %%a
    )
    
    :: 如果不是试运行，执行删除操作
    if "%DRY_RUN%"=="false" (
        for /f "usebackq" %%a in ("%TO_DELETE_FILE%") do (
            if "%MOVE_TO_TRASH%"=="true" (
                :: 移动到回收站
                for %%f in ("%%a") do set "filename=%%~nxf"
                echo 移动文件到回收站: %%a -^> %TRASH_DIR%\!filename!
                move "%%a" "%TRASH_DIR%\"
            ) else (
                :: 直接删除
                echo 删除文件: %%a
                del "%%a"
            )
        )
        
        if "%MOVE_TO_TRASH%"=="true" (
            echo 已移动 %TO_DELETE_COUNT% 个文件到回收站
        ) else (
            echo 已删除 %TO_DELETE_COUNT% 个文件
        )
    ) else (
        echo 试运行模式 - 以上文件将会被删除/移动，添加 --execute 参数执行实际操作
    )
) else (
    echo 没有找到需要删除的RAW文件。
)

:: 清理临时文件
del "%JPG_NAMES_FILE%" 2>nul
del "%RAW_NAMES_FILE%" 2>nul
del "%TO_DELETE_FILE%" 2>nul
rmdir "%TEMP_DIR%" 2>nul

endlocal 