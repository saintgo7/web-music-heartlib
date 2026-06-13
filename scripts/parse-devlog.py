#!/usr/bin/env python3
"""
Dev Log Parser
Parse markdown dev-log files and convert to JSON format
"""

import os
import re
import json
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional


def parse_devlog_file(filepath: Path) -> Optional[Dict]:
    """Parse a single dev-log markdown file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        # Extract metadata
        data = {
            'filename': filepath.name,
            'filepath': str(filepath),
        }

        # Extract number from filename (e.g., "03-2026-01-06..." -> "03")
        filename_match = re.match(r'^(\d+)-', filepath.name)
        if filename_match:
            data['number'] = filename_match.group(1)

        # Extract title (first heading)
        title_match = re.search(r'^#\s+Development Log\s+#(\d+)\s+-\s+(.+?)\s+\((.+?)\)', content, re.MULTILINE)
        if title_match:
            data['log_number'] = title_match.group(1)
            data['title'] = title_match.group(2)
            data['type_korean'] = title_match.group(3)

        # Extract date
        date_match = re.search(r'\*\*Date\*\*:\s+(.+)', content)
        if date_match:
            data['date'] = date_match.group(1).strip()

        # Extract author
        author_match = re.search(r'\*\*Author\*\*:\s+(.+)', content)
        if author_match:
            data['author'] = author_match.group(1).strip()

        # Extract commit hash
        commit_match = re.search(r'\*\*Commit\*\*:\s+`(.+?)`', content)
        if commit_match:
            data['commit'] = commit_match.group(1).strip()

        # Extract type
        type_match = re.search(r'\*\*Type\*\*:\s+(\w+)', content)
        if type_match:
            data['type'] = type_match.group(1).strip()

        # Extract summary
        summary_match = re.search(r'##\s+Summary\s+\(요약\)\s+(.+?)(?=\n##|\Z)', content, re.DOTALL)
        if summary_match:
            summary = summary_match.group(1).strip()
            # Get first line as main summary
            lines = [line.strip() for line in summary.split('\n') if line.strip() and not line.startswith('#')]
            if lines:
                data['summary'] = lines[0]

        # Extract details
        details_match = re.search(r'###\s+Details\s+\(상세 내용\)\s+(.+?)(?=\n##|🤖|\Z)', content, re.DOTALL)
        if details_match:
            details = details_match.group(1).strip()
            # Parse bullet points
            detail_lines = [line.strip('- ').strip() for line in details.split('\n') if line.strip().startswith('-')]
            if detail_lines:
                data['details'] = detail_lines

        # Extract changes overview
        changes_match = re.search(r'Files Changed \(변경된 파일\)\s+\|\s+(\d+)', content)
        if changes_match:
            data['files_changed'] = int(changes_match.group(1))

        lines_added_match = re.search(r'Lines Added \(추가된 라인\)\s+\|\s+\+(\d+)', content)
        if lines_added_match:
            data['lines_added'] = int(lines_added_match.group(1))

        lines_deleted_match = re.search(r'Lines Deleted \(삭제된 라인\)\s+\|\s+-(\d+)', content)
        if lines_deleted_match:
            data['lines_deleted'] = int(lines_deleted_match.group(1))

        # Parse date to timestamp for sorting
        if 'date' in data:
            try:
                dt = datetime.strptime(data['date'], '%Y-%m-%d %H:%M:%S')
                data['timestamp'] = dt.isoformat()
            except:
                data['timestamp'] = data['date']

        # Extract full content for detail view
        data['full_content'] = content

        return data

    except Exception as e:
        print(f"Error parsing {filepath}: {e}")
        return None


def parse_all_devlogs(devlog_dir: Path) -> List[Dict]:
    """Parse all dev-log files in directory"""
    logs = []

    # Get all .md files except README.md
    md_files = sorted([f for f in devlog_dir.glob('*.md') if f.name != 'README.md'])

    print(f"Found {len(md_files)} dev-log files")

    for filepath in md_files:
        log_data = parse_devlog_file(filepath)
        if log_data:
            logs.append(log_data)
            print(f"[OK] Parsed: {filepath.name}")

    # Sort by log number (descending - newest first)
    logs.sort(key=lambda x: int(x.get('log_number', 0)), reverse=True)

    return logs


def analyze_file_categories(logs: List[Dict]) -> Dict:
    """Analyze file changes by category (frontend/backend/docs/etc)"""
    categories = {
        'frontend': 0,
        'backend': 0,
        'docs': 0,
        'config': 0,
        'other': 0
    }

    for log in logs:
        content = log.get('full_content', '')

        # Count frontend files
        frontend_patterns = ['frontend/', 'src/app/', 'src/components/', '.tsx', '.jsx', 'page.tsx']
        backend_patterns = ['server/', 'app/api/', 'app/models/', 'app/services/', '.py']
        docs_patterns = ['docs/', '.md', 'README']
        config_patterns = ['.yml', '.yaml', '.json', 'docker-compose', '.env', 'Dockerfile']

        for pattern in frontend_patterns:
            if pattern in content:
                categories['frontend'] += content.count(pattern)

        for pattern in backend_patterns:
            if pattern in content:
                categories['backend'] += content.count(pattern)

        for pattern in docs_patterns:
            if pattern in content:
                categories['docs'] += content.count(pattern)

        for pattern in config_patterns:
            if pattern in content:
                categories['config'] += content.count(pattern)

    return categories


def generate_statistics(logs: List[Dict]) -> Dict:
    """Generate statistics from parsed logs"""
    stats = {
        'total_logs': len(logs),
        'total_files_changed': sum(log.get('files_changed', 0) for log in logs),
        'total_lines_added': sum(log.get('lines_added', 0) for log in logs),
        'total_lines_deleted': sum(log.get('lines_deleted', 0) for log in logs),
        'by_type': {},
        'categories': analyze_file_categories(logs),
    }

    # Count by type
    for log in logs:
        log_type = log.get('type', 'unknown')
        if log_type not in stats['by_type']:
            stats['by_type'][log_type] = 0
        stats['by_type'][log_type] += 1

    return stats


def main():
    """Main function"""
    # Get project root
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    devlog_dir = project_root / 'docs' / 'dev-log'
    output_dir = project_root / 'docs' / 'html' / 'data'

    # Create output directory
    output_dir.mkdir(parents=True, exist_ok=True)

    # Parse all logs
    print("\n[Parsing] dev-log files...")
    logs = parse_all_devlogs(devlog_dir)

    # Generate statistics
    stats = generate_statistics(logs)

    # Save to JSON
    output_file = output_dir / 'dev-logs.json'
    output_data = {
        'generated_at': datetime.now().isoformat(),
        'statistics': stats,
        'logs': logs,
    }

    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(output_data, f, ensure_ascii=False, indent=2)

    print(f"\n[SUCCESS] Successfully parsed {len(logs)} logs")
    print(f"[Statistics]")
    print(f"   - Total commits: {stats['total_logs']}")
    print(f"   - Files changed: {stats['total_files_changed']}")
    print(f"   - Lines added: +{stats['total_lines_added']}")
    print(f"   - Lines deleted: -{stats['total_lines_deleted']}")
    print(f"   - By type: {stats['by_type']}")
    print(f"\n[Output] {output_file}")


if __name__ == '__main__':
    main()
