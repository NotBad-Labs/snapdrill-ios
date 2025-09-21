import re
import sys
from collections import defaultdict

def fix_markdown_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # --- Remove empty headings (lines with only '#' characters) ---
    lines = [line for line in lines if not re.match(r'^\s*#+\s*$', line)]

    # --- Fix MD041: First line must be a top-level heading ---
    if lines and not lines[0].startswith('# '):
        # Find first non-empty line
        for i, line in enumerate(lines):
            if line.strip():
                # If it's not already a heading, make it one
                if not line.startswith('#'):
                    lines.insert(i, '# ' + lines.pop(i).strip() + '\n')
                break

    content = "".join(lines)

    # --- Fix MD012: No multiple consecutive blank lines ---
    content = re.sub(r'\n{3,}', '\n\n', content)

    # --- Fix MD009: Trailing spaces ---
    content = re.sub(r' +\n', '\n', content)

    # --- Fix MD022: Headings should be surrounded by blank lines ---
    # Add blank line before heading if missing
    content = re.sub(r'(?<=[^\n])\n(#{1,6} )', r'\n\n\1', content)
    # Add blank line after heading if missing
    content = re.sub(r'(#{1,6} .*)\n(?=[^\n])', r'\1\n\n', content)

    # --- Fix MD024: No duplicate headings in the same document ---
    lines = content.split('\n')
    headings = defaultdict(list)
    for i, line in enumerate(lines):
        match = re.match(r'^(#+)\s+(.*)', line)
        if match:
            level = len(match.group(1))
            text = match.group(2).strip()
            # Clean existing IDs for accurate counting
            clean_text = re.sub(r'\s*{#.*}\s*$', '', text)
            if clean_text: # Only count non-empty headings
                headings[clean_text].append((i, level))

    for text, occurrences in headings.items():
        if len(occurrences) > 1:
            for j, (line_num, level) in enumerate(occurrences):
                # Don't add ID to the first occurrence
                if j > 0:
                    original_heading_text = lines[line_num].lstrip('# ').strip()
                    # Create a simple unique ID
                    unique_id = f"{text.lower().replace(' ', '-')}-{j}"
                    # Check if it already has an ID
                    if not re.search(r'\s*{#.*}\s*$', original_heading_text):
                         lines[line_num] = f"{'#' * level} {original_heading_text} {{#{unique_id}}}"


    content = '\n'.join(lines)

    # --- Final cleanup: Ensure single blank lines and trim whitespace ---
    lines = content.split('\n')
    # Remove leading/trailing whitespace from the whole file
    final_lines = [line.rstrip() for line in lines]
    content = '\n'.join(final_lines).strip()
    # Ensure it ends with a single newline
    if content:
        content += '\n'


    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        for file_path in sys.argv[1:]:
            fix_markdown_file(file_path)
            print(f"✅ Formatted {file_path}")
    else:
        print("❌ Please provide a file path.")
