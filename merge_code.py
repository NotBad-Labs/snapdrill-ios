import os

# 配置：想要扫描的扩展名
EXTENSIONS = {'.swift', '.xctestplan'}
# 配置：想要忽略的目录
IGNORE_DIRS = {
    '.git', '.build', 'DerivedData', 'Pods', 
    'Carthage', 'Fastlane', '.xcodeproj', 
    'Assets.xcassets', 'Preview Content'
}

def is_ignored(path):
    parts = path.split(os.sep)
    for part in parts:
        if part in IGNORE_DIRS:
            return True
    return False

def merge_files(output_file='project_code_dump.txt'):
    root_dir = os.getcwd()
    
    with open(output_file, 'w', encoding='utf-8') as outfile:
        outfile.write(f"# Project Dump: {os.path.basename(root_dir)}\n\n")
        
        file_count = 0
        line_count = 0
        
        for root, dirs, files in os.walk(root_dir):
            # 过滤忽略的目录
            dirs[:] = [d for d in dirs if d not in IGNORE_DIRS]
            
            for file in files:
                if is_ignored(os.path.join(root, file)):
                    continue
                    
                _, ext = os.path.splitext(file)
                if ext in EXTENSIONS:
                    file_path = os.path.join(root, file)
                    rel_path = os.path.relpath(file_path, root_dir)
                    
                    try:
                        with open(file_path, 'r', encoding='utf-8') as infile:
                            content = infile.read()
                            
                            # 写入文件分隔符和路径，方便我识别
                            outfile.write(f"\n{'='*80}\n")
                            outfile.write(f"// FILE PATH: {rel_path}\n")
                            outfile.write(f"{'='*80}\n\n")
                            
                            outfile.write(content)
                            outfile.write("\n")
                            
                            file_count += 1
                            line_count += content.count('\n')
                    except Exception as e:
                        print(f"Skipping {rel_path}: {e}")

        print(f"✅ 完成！")
        print(f"📄 已合并文件数: {file_count}")
        print(f"📊 总代码行数: {line_count}")
        print(f"💾 输出文件: {output_file}")

if __name__ == '__main__':
    merge_files()
