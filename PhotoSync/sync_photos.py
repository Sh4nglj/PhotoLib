import os
import glob
import re
import shutil
from pathlib import Path

def get_file_base_name(filename):
    """提取文件名的基本部分（不含扩展名）"""
    return os.path.splitext(os.path.basename(filename))[0]

def sync_deleted_photos(parent_dir=None, jpg_dir=None, raw_dir=None, dry_run=True, move_to_trash=False, trash_dir=None):
    """
    同步删除：删除raw文件夹中对应于jpg文件夹中已删除的照片
    
    参数:
        parent_dir: 父目录路径，如果提供，则jpg_dir和raw_dir将自动设置为其子目录
        jpg_dir: jpg照片目录路径
        raw_dir: raw照片目录路径
        dry_run: 如果为True，只显示将被删除的文件而不实际删除
        move_to_trash: 如果为True，将文件移动到回收站而不是直接删除
        trash_dir: 回收站目录路径（仅当move_to_trash为True时使用）
    """
    # 根据parent_dir自动设置jpg_dir和raw_dir
    if parent_dir:
        jpg_dir = os.path.join(parent_dir, "jpg")
        raw_dir = os.path.join(parent_dir, "raw")
    
    # 确保目录存在
    if not os.path.isdir(jpg_dir):
        raise ValueError(f"JPG目录不存在: {jpg_dir}")
    if not os.path.isdir(raw_dir):
        raise ValueError(f"RAW目录不存在: {raw_dir}")
    
    if move_to_trash and not trash_dir:
        trash_dir = os.path.join(os.path.dirname(raw_dir), "deleted_photos")
    
    if move_to_trash and not os.path.exists(trash_dir):
        os.makedirs(trash_dir)
    
    # 获取jpg文件的基本名称集合
    jpg_files = glob.glob(os.path.join(jpg_dir, "**/*.jpg"), recursive=True)
    jpg_files.extend(glob.glob(os.path.join(jpg_dir, "**/*.jpeg"), recursive=True))
    jpg_files.extend(glob.glob(os.path.join(jpg_dir, "**/*.JPG"), recursive=True))
    jpg_files.extend(glob.glob(os.path.join(jpg_dir, "**/*.JPEG"), recursive=True))
    
    jpg_base_names = {get_file_base_name(f) for f in jpg_files}
    
    # 查找raw文件 - 扩展支持更多相机品牌的RAW格式
    raw_extensions = [
        # 常见RAW格式
        ".raw", ".RAW",
        # 索尼(Sony)
        ".arw", ".ARW", 
        # 佳能(Canon)
        ".cr2", ".CR2", ".cr3", ".CR3", 
        # 尼康(Nikon)
        ".nef", ".NEF", 
        # Adobe DNG格式（通用）
        ".dng", ".DNG", 
        # 奥林巴斯(Olympus)
        ".orf", ".ORF", 
        # 松下(Panasonic)
        ".rw2", ".RW2", 
        # 富士(Fujifilm)
        ".raf", ".RAF", 
        # 宾得(Pentax)
        ".pef", ".PEF", 
        # 适马(Sigma)
        ".x3f", ".X3F",
        # 徕卡(Leica)
        ".rwl", ".RWL", ".dng", ".DNG",
        # 哈苏(Hasselblad)
        ".3fr", ".3FR", ".fff", ".FFF",
        # 理光(Ricoh)
        ".rwl", ".RWL",
        # Phase One
        ".iiq", ".IIQ",
        # 柯达(Kodak)
        ".kdc", ".KDC", ".dcr", ".DCR",
        # 三星(Samsung)
        ".srw", ".SRW"
    ]
    
    raw_files = []
    
    print("搜索RAW文件...")
    for ext in raw_extensions:
        found_files = glob.glob(os.path.join(raw_dir, f"**/*{ext}"), recursive=True)
        if found_files:
            print(f"找到 {len(found_files)} 个 {ext} 格式文件")
        raw_files.extend(found_files)
    
    print(f"总共找到 {len(raw_files)} 个RAW文件")
    
    to_delete = []
    
    # 检查哪些RAW文件需要删除（对应的JPG已被删除）
    for raw_file in raw_files:
        raw_base_name = get_file_base_name(raw_file)
        if raw_base_name not in jpg_base_names:
            to_delete.append(raw_file)
    
    # 显示将要删除的文件
    if to_delete:
        print(f"找到 {len(to_delete)} 个需要删除的RAW文件:")
        for f in to_delete:
            print(f"  - {f}")
        
        # 如果不是试运行，执行删除操作
        if not dry_run:
            for f in to_delete:
                if move_to_trash:
                    # 移动到回收站
                    dest = os.path.join(trash_dir, os.path.basename(f))
                    print(f"移动文件到回收站: {f} -> {dest}")
                    shutil.move(f, dest)
                else:
                    # 直接删除
                    print(f"删除文件: {f}")
                    os.remove(f)
            
            print(f"已{'移动' if move_to_trash else '删除'} {len(to_delete)} 个文件")
    else:
        print("没有找到需要删除的RAW文件。")

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="同步删除RAW照片目录中对应于已从JPG目录中删除的照片")
    
    # 创建互斥组：要么使用parent_dir，要么使用jpg_dir和raw_dir
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--dir", dest="parent_dir", help="照片的父目录路径，其下应有jpg和raw子目录")
    group.add_argument("--jpg", dest="jpg_dir", help="JPG照片目录的路径")
    
    # 如果使用jpg_dir，则raw_dir是必需的
    parser.add_argument("--raw", dest="raw_dir", help="RAW照片目录的路径（与--jpg一起使用时必需）")
    parser.add_argument("--execute", action="store_true", help="执行实际删除操作（默认为试运行模式）")
    parser.add_argument("--trash", action="store_true", help="移动到回收站而不是直接删除")
    parser.add_argument("--trash-dir", help="自定义回收站目录（默认在raw目录同级创建deleted_photos文件夹）")
    
    args = parser.parse_args()
    
    # 检查参数逻辑
    if args.jpg_dir and not args.raw_dir:
        parser.error("使用--jpg时，必须同时指定--raw")
    
    sync_deleted_photos(
        parent_dir=args.parent_dir,
        jpg_dir=args.jpg_dir,
        raw_dir=args.raw_dir,
        dry_run=not args.execute,
        move_to_trash=args.trash,
        trash_dir=args.trash_dir
    )

if __name__ == "__main__":
    main() 