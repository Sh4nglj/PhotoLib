#!/usr/bin/env python3
"""
这个脚本创建一个测试环境来验证sync_photos.py的功能。
它将创建示例的jpg和raw文件夹，并填充一些样本文件用于测试。
"""

import os
import shutil
import argparse

def setup_test_environment(base_dir="."):
    """创建测试环境"""
    # 创建目录结构
    jpg_dir = os.path.join(base_dir, "jpg")
    raw_dir = os.path.join(base_dir, "raw")
    
    # 如果目录已存在，询问是否删除
    if os.path.exists(jpg_dir) or os.path.exists(raw_dir):
        response = input("测试目录已存在，是否删除并重新创建？(y/n): ")
        if response.lower() == 'y':
            if os.path.exists(jpg_dir):
                shutil.rmtree(jpg_dir)
            if os.path.exists(raw_dir):
                shutil.rmtree(raw_dir)
        else:
            print("操作取消")
            return
    
    # 创建目录
    os.makedirs(jpg_dir, exist_ok=True)
    os.makedirs(raw_dir, exist_ok=True)
    
    # 创建测试文件 - 两个文件夹中都存在的匹配文件
    sample_files = [
        "IMG_0001", "IMG_0002", "IMG_0003", "IMG_0004", "IMG_0005",
        "DSC_1001", "DSC_1002", "DSC_1003"
    ]
    
    # 不同相机品牌的文件格式
    extensions_map = {
        "IMG_": ".CR2",  # 佳能Canon
        "DSC_": ".ARW",  # 索尼Sony
        "DSCF": ".RAF",  # 富士Fuji
        "P": ".RW2"      # 松下Panasonic
    }
    
    # 创建基本样本文件 - JPG和对应的RAW文件
    for filename in sample_files:
        # 创建JPG文件
        with open(os.path.join(jpg_dir, f"{filename}.jpg"), "w") as f:
            f.write("Sample JPG content")
        
        # 创建RAW文件 - 根据文件名前缀选择RAW格式
        prefix = filename[:4]
        raw_ext = ".raw"  # 默认格式
        
        for prefix_key, ext in extensions_map.items():
            if filename.startswith(prefix_key):
                raw_ext = ext
                break
                
        with open(os.path.join(raw_dir, f"{filename}{raw_ext}"), "w") as f:
            f.write(f"Sample {raw_ext} RAW content")
    
    # 富士GFX样本文件
    fuji_samples = ["DSCF0001", "DSCF0002", "DSCF0003"]
    for filename in fuji_samples:
        # 创建JPG文件
        with open(os.path.join(jpg_dir, f"{filename}.jpg"), "w") as f:
            f.write("Fuji JPG content")
        
        # 创建RAF文件
        with open(os.path.join(raw_dir, f"{filename}.RAF"), "w") as f:
            f.write("Fuji RAF content")
    
    # 额外创建一些RAW文件，模拟已删除的JPG文件
    extra_raw_files = [
        ("IMG_0006", ".CR2"),  # Canon
        ("IMG_0007", ".CR2"),  # Canon
        ("DSC_1004", ".ARW"),  # Sony
        ("DSC_1005", ".ARW"),  # Sony
        ("DSCF0004", ".RAF"),  # Fuji
        ("DSCF0005", ".RAF"),  # Fuji
        ("P1000001", ".RW2")   # Panasonic
    ]
    
    for filename, ext in extra_raw_files:
        with open(os.path.join(raw_dir, f"{filename}{ext}"), "w") as f:
            f.write(f"Sample {ext} RAW content that should be deleted")
    
    # 额外创建一些JPG文件，没有对应的RAW文件
    extra_jpg_files = ["IMG_0008", "IMG_0009", "DSC_1006", "DSCF0006"]
    
    for filename in extra_jpg_files:
        with open(os.path.join(jpg_dir, f"{filename}.jpg"), "w") as f:
            f.write("Sample JPG content without RAW")
    
    print("测试环境创建成功！")
    print(f"JPG目录: {jpg_dir}")
    print(f"RAW目录: {raw_dir}")
    print(f"父目录: {base_dir}")
    print("\n要使用新的父目录参数测试同步删除功能，请运行:")
    print(f"python sync_photos.py --dir {base_dir}")
    print("\n或者使用旧的分开参数:")
    print(f"python sync_photos.py --jpg {jpg_dir} --raw {raw_dir}")
    print("\n要执行实际删除操作，添加 --execute 参数:")
    print(f"python sync_photos.py --dir {base_dir} --execute")
    print("\n预期应该删除的RAW文件:")
    for filename, ext in extra_raw_files:
        print(f"  - {filename}{ext}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="创建测试环境")
    parser.add_argument("--dir", default=".", help="创建测试环境的基础目录路径")
    
    args = parser.parse_args()
    setup_test_environment(args.dir) 