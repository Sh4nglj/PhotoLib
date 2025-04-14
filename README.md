# 摄影文件同步删除工具

这个工具可以帮助摄影师同步删除RAW文件夹中对应于已从JPG文件夹中删除的照片。

## 使用场景

作为摄影师，你通常会有两个文件夹：
- `jpg` 文件夹：存放JPG格式的照片预览文件
- `raw` 文件夹：存放相机的原始RAW格式文件

当你通过JPG预览筛选照片并删除不需要的照片后，这个工具可以帮你自动同步删除RAW文件夹中对应的原始文件，保持两个文件夹的内容同步。

## 可用版本

该工具提供三个版本，功能相同但适用于不同环境：

1. **Python版本** (`sync_photos.py`) - 需要Python环境
2. **Bash脚本版本** (`sync_photos.sh`) - 适用于macOS/Linux系统
3. **批处理脚本版本** (`sync_photos.bat`) - 适用于Windows系统

## 使用方法

以下示例使用Python版本的命令，对于Bash版本和批处理版本，只需替换文件名部分即可。

### 使用父目录参数（推荐）

如果你的jpg和raw文件夹位于同一个父目录下，可以直接指定父目录：

```bash
# Python版本
python sync_photos.py --dir /path/to/parent/folder

# macOS/Linux版本
./sync_photos.sh --dir /path/to/parent/folder

# Windows版本
sync_photos.bat --dir C:\path\to\parent\folder
```

程序会自动查找该目录下的`jpg`和`raw`子目录。

### 分别指定jpg和raw目录

如果你的jpg和raw目录不在同一个父目录下，可以分别指定：

```bash
# Python版本
python sync_photos.py --jpg /path/to/jpg/folder --raw /path/to/raw/folder

# macOS/Linux版本
./sync_photos.sh --jpg /path/to/jpg/folder --raw /path/to/raw/folder

# Windows版本
sync_photos.bat --jpg C:\path\to\jpg\folder --raw C:\path\to\raw\folder
```

### 其他选项

执行实际删除操作（默认为试运行模式）：

```bash
python sync_photos.py --dir /path/to/parent/folder --execute
```

将文件移动到回收站而不是直接删除：

```bash
python sync_photos.py --dir /path/to/parent/folder --execute --trash
```

指定自定义回收站目录：

```bash
python sync_photos.py --dir /path/to/parent/folder --execute --trash --trash-dir /path/to/trash/folder
```

## 参数说明

所有版本支持相同的命令行参数：

- `--dir`：照片的父目录路径，其下应有jpg和raw子目录
- `--jpg`：JPG照片目录的路径（与`--raw`一起使用）
- `--raw`：RAW照片目录的路径（与`--jpg`一起使用）
- `--execute`：执行实际删除操作（默认为试运行模式）
- `--trash`：移动到回收站而不是直接删除
- `--trash-dir`：自定义回收站目录（默认在raw目录同级创建deleted_photos文件夹）
- `--help`：显示帮助信息

## 平台特定说明

### macOS/Linux版本 (sync_photos.sh)

使用前需要赋予执行权限：

```bash
chmod +x sync_photos.sh
```

### Windows版本 (sync_photos.bat)

- 直接双击或在命令提示符中运行
- 对于包含空格的路径，请使用引号包围，例如：`sync_photos.bat --dir "C:\My Photos"`

## 注意事项

1. 脚本通过文件名（不含扩展名）匹配JPG和RAW文件，确保你的文件命名一致
2. 首次运行时建议不使用`--execute`参数，先查看将要删除的文件列表
3. 使用`--trash`选项可以将文件移动到回收站，便于后续恢复

## 支持的RAW格式

该工具支持多种相机品牌的RAW格式文件：

- 通用：`.raw`, `.RAW`, `.dng`, `.DNG`
- 索尼(Sony)：`.arw`, `.ARW`
- 佳能(Canon)：`.cr2`, `.CR2`, `.cr3`, `.CR3`
- 尼康(Nikon)：`.nef`, `.NEF`
- 富士(Fujifilm)，包括GFX系列：`.raf`, `.RAF`
- 奥林巴斯(Olympus)：`.orf`, `.ORF`
- 松下(Panasonic)：`.rw2`, `.RW2`
- 宾得(Pentax)：`.pef`, `.PEF`
- 适马(Sigma)：`.x3f`, `.X3F`
- 徕卡(Leica)：`.rwl`, `.RWL`
- 哈苏(Hasselblad)：`.3fr`, `.3FR`, `.fff`, `.FFF`
- 理光(Ricoh)：`.rwl`, `.RWL`
- Phase One：`.iiq`, `.IIQ`
- 柯达(Kodak)：`.kdc`, `.KDC`, `.dcr`, `.DCR`
- 三星(Samsung)：`.srw`, `.SRW` 