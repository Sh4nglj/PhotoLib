#!/bin/bash

# 同步删除：删除raw文件夹中对应于jpg文件夹中已删除的照片

# 默认设置
DRY_RUN=true
MOVE_TO_TRASH=false
TRASH_DIR=""

# 帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --dir <目录>       照片的父目录路径，其下应有jpg和raw子目录"
    echo "  --jpg <目录>       JPG照片目录的路径（与--raw一起使用）"
    echo "  --raw <目录>       RAW照片目录的路径（与--jpg一起使用）"
    echo "  --execute          执行实际删除操作（默认为试运行模式）"
    echo "  --trash            移动到回收站而不是直接删除"
    echo "  --trash-dir <目录> 自定义回收站目录"
    echo "  --help             显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 --dir ~/Photos"
    echo "  $0 --jpg ~/Photos/jpg --raw ~/Photos/raw --execute"
    echo "  $0 --dir ~/Photos --execute --trash"
    exit 0
}

# 解析命令行参数
while [ "$#" -gt 0 ]; do
    case "$1" in
        --dir)
            PARENT_DIR="$2"
            shift 2
            ;;
        --jpg)
            JPG_DIR="$2"
            shift 2
            ;;
        --raw)
            RAW_DIR="$2"
            shift 2
            ;;
        --execute)
            DRY_RUN=false
            shift
            ;;
        --trash)
            MOVE_TO_TRASH=true
            shift
            ;;
        --trash-dir)
            TRASH_DIR="$2"
            shift 2
            ;;
        --help)
            show_help
            ;;
        *)
            echo "错误: 未知选项 $1"
            show_help
            ;;
    esac
done

# 检查参数逻辑
if [ -n "$PARENT_DIR" ]; then
    # 使用父目录
    JPG_DIR="${PARENT_DIR}/jpg"
    RAW_DIR="${PARENT_DIR}/raw"
elif [ -n "$JPG_DIR" ] && [ -n "$RAW_DIR" ]; then
    # 使用分别指定的目录
    :
else
    echo "错误: 必须指定 --dir 或同时指定 --jpg 和 --raw"
    show_help
fi

# 确保目录存在
if [ ! -d "$JPG_DIR" ]; then
    echo "错误: JPG目录不存在: $JPG_DIR"
    exit 1
fi

if [ ! -d "$RAW_DIR" ]; then
    echo "错误: RAW目录不存在: $RAW_DIR"
    exit 1
fi

# 设置回收站目录
if [ "$MOVE_TO_TRASH" = true ] && [ -z "$TRASH_DIR" ]; then
    TRASH_DIR="$(dirname "$RAW_DIR")/deleted_photos"
fi

if [ "$MOVE_TO_TRASH" = true ] && [ ! -d "$TRASH_DIR" ]; then
    mkdir -p "$TRASH_DIR"
fi

# 定义RAW格式扩展名
RAW_EXTENSIONS=(".raw" ".RAW" ".arw" ".ARW" ".cr2" ".CR2" ".cr3" ".CR3" 
                ".nef" ".NEF" ".dng" ".DNG" ".orf" ".ORF" ".rw2" ".RW2" 
                ".raf" ".RAF" ".pef" ".PEF" ".x3f" ".X3F" ".rwl" ".RWL" 
                ".3fr" ".3FR" ".fff" ".FFF" ".iiq" ".IIQ" ".kdc" ".KDC" 
                ".dcr" ".DCR" ".srw" ".SRW")

# 创建临时文件
JPG_NAMES_FILE=$(mktemp)
RAW_NAMES_FILE=$(mktemp)
TO_DELETE_FILE=$(mktemp)

echo "搜索JPG文件..."
# 查找所有JPG文件，并提取基本文件名（不含扩展名）
find "$JPG_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) -print0 | 
    while IFS= read -r -d $'\0' file; do
        basename=$(basename "$file")
        filename="${basename%.*}"
        echo "$filename" >> "$JPG_NAMES_FILE"
    done

echo "搜索RAW文件..."
# 查找所有RAW文件
RAW_COUNT=0
for ext in "${RAW_EXTENSIONS[@]}"; do
    # 查找当前扩展名的文件
    count=0
    find "$RAW_DIR" -type f -iname "*$ext" -print0 | 
        while IFS= read -r -d $'\0' file; do
            basename=$(basename "$file")
            filename="${basename%.*}"
            echo "$filename|$file" >> "$RAW_NAMES_FILE"
            ((count++))
        done
    
    if [ $count -gt 0 ]; then
        echo "找到 $count 个 $ext 格式文件"
        ((RAW_COUNT+=count))
    fi
done

echo "总共找到 $RAW_COUNT 个RAW文件"

# 查找需要删除的RAW文件 - 存在于RAW目录但不存在于JPG目录
echo "对比文件列表..."
while IFS="|" read -r raw_name raw_file; do
    if ! grep -q "^$raw_name$" "$JPG_NAMES_FILE"; then
        echo "$raw_file" >> "$TO_DELETE_FILE"
    fi
done < "$RAW_NAMES_FILE"

# 统计要删除的文件数量
TO_DELETE_COUNT=$(wc -l < "$TO_DELETE_FILE")
TO_DELETE_COUNT=$(echo "$TO_DELETE_COUNT" | tr -d ' ')

# 显示并处理要删除的文件
if [ "$TO_DELETE_COUNT" -gt 0 ]; then
    echo "找到 $TO_DELETE_COUNT 个需要删除的RAW文件:"
    while IFS= read -r file; do
        echo "  - $file"
    done < "$TO_DELETE_FILE"
    
    # 如果不是试运行，执行删除操作
    if [ "$DRY_RUN" = false ]; then
        while IFS= read -r file; do
            if [ "$MOVE_TO_TRASH" = true ]; then
                # 移动到回收站
                filename=$(basename "$file")
                dest="$TRASH_DIR/$filename"
                echo "移动文件到回收站: $file -> $dest"
                mv "$file" "$dest"
            else
                # 直接删除
                echo "删除文件: $file"
                rm "$file"
            fi
        done < "$TO_DELETE_FILE"
        
        if [ "$MOVE_TO_TRASH" = true ]; then
            echo "已移动 $TO_DELETE_COUNT 个文件到回收站"
        else
            echo "已删除 $TO_DELETE_COUNT 个文件"
        fi
    else
        echo "试运行模式 - 以上文件将会被删除/移动，添加 --execute 参数执行实际操作"
    fi
else
    echo "没有找到需要删除的RAW文件。"
fi

# 清理临时文件
rm "$JPG_NAMES_FILE"
rm "$RAW_NAMES_FILE"
rm "$TO_DELETE_FILE" 