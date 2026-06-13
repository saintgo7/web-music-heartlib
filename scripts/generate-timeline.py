#!/usr/bin/env python3
"""
Timeline View Generator for Dev Log
Generates chronological timeline view from parsed dev-logs JSON
"""

import json
from pathlib import Path
from datetime import datetime
from typing import Dict, List
from collections import defaultdict


TYPE_LABELS = {
    'feat': {'en': 'Features', 'ko': '기능 추가', 'color': '#10b981', 'icon': 'NEW'},
    'fix': {'en': 'Fixes', 'ko': '버그 수정', 'color': '#ef4444', 'icon': 'FIX'},
    'docs': {'en': 'Docs', 'ko': '문서', 'color': '#3b82f6', 'icon': 'DOC'},
    'refactor': {'en': 'Refactor', 'ko': '리팩토링', 'color': '#8b5cf6', 'icon': 'REF'},
    'test': {'en': 'Tests', 'ko': '테스트', 'color': '#f59e0b', 'icon': 'TEST'},
    'chore': {'en': 'Chore', 'ko': '기타', 'color': '#6b7280', 'icon': 'CHORE'},
    'ci': {'en': 'CI/CD', 'ko': 'CI/CD', 'color': '#06b6d4', 'icon': 'CI'},
    'setup': {'en': 'Setup', 'ko': '설정', 'color': '#84cc16', 'icon': 'SETUP'},
}


def get_type_info(log_type: str) -> Dict:
    """Get type information"""
    return TYPE_LABELS.get(log_type, {
        'en': log_type.title(),
        'ko': log_type,
        'color': '#64748b',
        'icon': 'LOG'
    })


def format_date(date_str: str) -> str:
    """Format date string"""
    try:
        dt = datetime.strptime(date_str, '%Y-%m-%d %H:%M:%S')
        return dt.strftime('%Y-%m-%d %H:%M')
    except:
        return date_str


def get_date_only(date_str: str) -> str:
    """Get date only (YYYY-MM-DD)"""
    try:
        dt = datetime.strptime(date_str, '%Y-%m-%d %H:%M:%S')
        return dt.strftime('%Y-%m-%d')
    except:
        return date_str.split()[0] if ' ' in date_str else date_str


def get_weekday(date_str: str) -> str:
    """Get weekday in Korean"""
    weekdays = ['월', '화', '수', '목', '금', '토', '일']
    try:
        dt = datetime.strptime(date_str, '%Y-%m-%d')
        return weekdays[dt.weekday()]
    except:
        return ''


def group_logs_by_date(logs: List[Dict]) -> Dict[str, List[Dict]]:
    """Group logs by date"""
    grouped = defaultdict(list)
    for log in logs:
        date = get_date_only(log.get('date', ''))
        grouped[date].append(log)
    return dict(grouped)


def generate_timeline_item_html(log: Dict, index: int) -> str:
    """Generate HTML for a single timeline item"""
    log_type = log.get('type', 'unknown')
    type_info = get_type_info(log_type)

    title = log.get('title', 'Untitled')
    time = format_date(log.get('date', ''))
    commit = log.get('commit', 'N/A')[:7]
    log_number = log.get('log_number', '?')

    files_changed = log.get('files_changed', 0)
    lines_added = log.get('lines_added', 0)
    lines_deleted = log.get('lines_deleted', 0)

    return f'''
    <div class="timeline-item" data-type="{log_type}" data-log-index="{index}" onclick="openModal({index})">
        <div class="timeline-marker" style="background-color: {type_info['color']}"></div>
        <div class="timeline-content">
            <div class="timeline-header">
                <span class="timeline-number">#{log_number}</span>
                <span class="timeline-type" style="background-color: {type_info['color']}">
                    {type_info['icon']} {type_info['en']}
                </span>
                <span class="timeline-time">{time}</span>
            </div>
            <h3 class="timeline-title">{title}</h3>
            <div class="timeline-meta">
                <span class="meta-item">
                    <span class="meta-label">Commit:</span> {commit}
                </span>
                <span class="meta-item">
                    <span class="meta-label">Changes:</span> {files_changed} files,
                    <span class="text-green">+{lines_added}</span>
                    <span class="text-red">-{lines_deleted}</span>
                </span>
            </div>
        </div>
    </div>
    '''


def generate_html(data: Dict) -> str:
    """Generate complete timeline HTML page"""
    stats = data['statistics']
    logs = data['logs']
    generated_at = data.get('generated_at', '')

    # Sort logs by date (newest first)
    sorted_logs = sorted(logs, key=lambda x: x.get('date', ''), reverse=True)

    # Group by date
    logs_by_date = group_logs_by_date(sorted_logs)

    # Generate timeline HTML
    timeline_html = ''
    for date in sorted(logs_by_date.keys(), reverse=True):
        date_logs = logs_by_date[date]
        weekday = get_weekday(date)
        count = len(date_logs)

        timeline_html += f'''
        <div class="timeline-date-group">
            <div class="timeline-date-header">
                <h2 class="timeline-date">{date} ({weekday})</h2>
                <span class="timeline-count">{count} commits</span>
            </div>
            <div class="timeline-items">
        '''

        for log in date_logs:
            # Find index in original logs list
            log_number = log.get('log_number')
            index = next((i for i, l in enumerate(logs) if l.get('log_number') == log_number), 0)
            timeline_html += generate_timeline_item_html(log, index)

        timeline_html += '''
            </div>
        </div>
        '''

    # Prepare logs data for JavaScript
    import json as json_module
    logs_json = json_module.dumps(logs, ensure_ascii=False)

    html = f'''<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Development Timeline - PamOut</title>
    <link rel="stylesheet" href="styles.css">
    <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
    <script src="scripts.js"></script>
</head>
<body>
    <!-- Dark Mode Toggle -->
    <button class="dark-mode-toggle" onclick="toggleDarkMode()" aria-label="Toggle Dark Mode">
        <span id="darkModeIcon">🌙</span>
        <span class="toggle-label" id="darkModeLabel">Dark</span>
    </button>

    <header class="page-header">
        <div class="header-content">
            <h1>Development Timeline</h1>
            <p class="header-subtitle">시간순 개발 히스토리</p>
        </div>
        <nav class="stats-nav">
            <a href="index.html" class="nav-link">Kanban Board</a>
            <a href="timeline.html" class="nav-link active">Timeline</a>
            <a href="heatmap.html" class="nav-link">Heatmap</a>
            <a href="files.html" class="nav-link">Files</a>
            <a href="commit-size.html" class="nav-link">Commit Size</a>
            <a href="time-analysis.html" class="nav-link">Time Analysis</a>
            <a href="stats.html" class="nav-link">Statistics</a>
        </nav>

        <div class="stats-bar">
            <div class="stat-item">
                <span class="stat-label">Total Commits</span>
                <span class="stat-value">{stats['total_logs']}</span>
            </div>
            <div class="stat-item">
                <span class="stat-label">Files Changed</span>
                <span class="stat-value">{stats['total_files_changed']}</span>
            </div>
            <div class="stat-item">
                <span class="stat-label">Lines Added</span>
                <span class="stat-value text-green">+{stats['total_lines_added']}</span>
            </div>
            <div class="stat-item">
                <span class="stat-label">Lines Deleted</span>
                <span class="stat-value text-red">-{stats['total_lines_deleted']}</span>
            </div>
        </div>
    </header>

    <main class="timeline-container">
        {timeline_html}
    </main>

    <footer class="page-footer">
        <p>Generated at {generated_at} | PamOut Workstation Manager</p>
        <p><a href="https://ws.abada.co.kr" target="_blank">https://ws.abada.co.kr</a></p>
    </footer>

    <!-- Modal -->
    <div id="detailModal" class="modal" onclick="closeModal(event)">
        <div class="modal-content" onclick="event.stopPropagation()">
            <div class="modal-header">
                <h2 id="modalTitle"></h2>
                <button class="modal-close" onclick="closeModal()">&times;</button>
            </div>
            <div class="modal-body">
                <div id="modalBody" class="markdown-content"></div>
            </div>
        </div>
    </div>

    <script>
        const logsData = {logs_json};

        // Configure marked options
        marked.setOptions({{
            breaks: true,
            gfm: true,
            headerIds: false,
            mangle: false
        }});

        function openModal(index) {{
            const log = logsData[index];
            if (!log) return;

            const modal = document.getElementById('detailModal');
            const modalTitle = document.getElementById('modalTitle');
            const modalBody = document.getElementById('modalBody');

            // Set title
            modalTitle.textContent = `#${{log.log_number}} - ${{log.title}}`;

            // Parse and render markdown
            const content = log.full_content || '';
            const html = marked.parse(content);

            // Safe rendering: Create temporary div, set innerHTML, then move to modal
            const tempDiv = document.createElement('div');
            tempDiv.innerHTML = html;
            modalBody.innerHTML = '';
            modalBody.appendChild(tempDiv);

            modal.style.display = 'flex';
            document.body.style.overflow = 'hidden';
        }}

        function closeModal(event) {{
            if (event && event.target.classList.contains('modal-content')) {{
                return;
            }}
            const modal = document.getElementById('detailModal');
            modal.style.display = 'none';
            document.body.style.overflow = 'auto';
        }}

        // Close modal on ESC key
        document.addEventListener('keydown', function(event) {{
            if (event.key === 'Escape') {{
                closeModal();
            }}
        }});

        // Dark Mode Toggle
        function toggleDarkMode() {{
            document.body.classList.toggle('dark-mode');
            const isDark = document.body.classList.contains('dark-mode');
            const icon = document.getElementById('darkModeIcon');
            const label = document.getElementById('darkModeLabel');
            icon.textContent = isDark ? '☀️' : '🌙';
            label.textContent = isDark ? 'Light' : 'Dark';
            localStorage.setItem('darkMode', isDark ? 'enabled' : 'disabled');
        }}

        // Load dark mode preference
        if (localStorage.getItem('darkMode') === 'enabled') {{
            document.body.classList.add('dark-mode');
            document.getElementById('darkModeIcon').textContent = '☀️';
            document.getElementById('darkModeLabel').textContent = 'Light';
        }}
    </script>
</body>
</html>'''

    return html


def main():
    """Main function"""
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    data_file = project_root / 'docs' / 'html' / 'data' / 'dev-logs.json'
    output_file = project_root / 'docs' / 'html' / 'timeline.html'

    # Load data
    print("\n[Loading] dev-logs data...")
    with open(data_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    print(f"[OK] Loaded {data['statistics']['total_logs']} logs")

    # Generate HTML
    print("\n[Generating] Timeline HTML...")
    html = generate_html(data)

    # Save HTML
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(html)

    print(f"[SUCCESS] Timeline HTML generated successfully!")
    print(f"[Output] {output_file}")
    print(f"\n[Browser] Open in browser:")
    print(f"   file://{output_file}")


if __name__ == '__main__':
    main()
