# PhotoLib 工具集

这是一个用于照片处理和管理的工具集合。项目采用模块化设计，每个工具都位于独立的目录中。

## 项目结构

```
PhotoLib/
├── README.md
└── PhotoSync/          # 照片同步工具
    ├── sync_photos.py  # Python 实现
    ├── sync_photos.sh  # Shell 脚本实现
    ├── sync_photos.bat # Windows 批处理实现
    └── test_setup.py   # 测试配置
```

## 当前可用工具

### PhotoSync
照片同步工具，支持跨平台使用：
- Windows 用户使用 `sync_photos.bat`
- Unix/Linux/Mac 用户使用 `sync_photos.sh`
- 或者使用跨平台的 `sync_photos.py`

## 未来计划

计划添加更多照片处理工具，包括但不限于：
- 照片批量重命名工具
- 照片元数据编辑工具
- 照片压缩工具
- 照片分类工具
- 照片备份工具

## 使用说明

每个工具都有其独立的文档和使用说明，请参考相应目录下的 README 文件。

## 贡献指南

欢迎提交新的工具或改进现有工具。请确保：
1. 新工具放在独立的目录中
2. 提供完整的文档和使用说明
3. 包含必要的测试用例 