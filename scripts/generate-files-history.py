#!/usr/bin/env python3
"""
Files History Generator
Generates file change history analysis page
"""

import json
from pathlib import Path
from collections import defaultdict, Counter
from typing import Dict, List


def analyze_file_changes(logs: List[Dict]) -> Dict:
    """Analyze file changes across all commits"""
    file_changes = defaultdict(int)
    file_lines = defaultdict(lambda: {'added': 0, 'deleted': 0})
    file_commits = defaultdict(list)

    for log in logs:
        commit_hash = log.get('commit', 'N/A')[:7]
        log_number = log.get('log_number', '?')
        date = log.get('date', '')
        title = log.get('title', '')

        # Parse full content for file changes
        full_content = log.get('full_content', '')
        lines = full_content.split('\n')

        current_file = None
        for line in lines:
            # Detect file paths in markdown tables
            if '`~`' in line or '`+`' in line or '`-`' in line:
                parts = line.split('|')
                if len(parts) >= 3:
                    file_path = parts[2].strip().replace('`', '')
                    if file_path and file_path != 'File':
                        current_file = file_path
                        file_changes[current_file] += 1
                        file_commits[current_file].append({
                            'commit': commit_hash,
                            'log_number': log_number,
                            'date': date,
                            'title': title
                        })

    return {
        'file_changes': dict(file_changes),
        'file_commits': dict(file_commits)
    }


def categorize_files(file_changes: Dict[str, int]) -> Dict:
    """Categorize files by type"""
    categories = {
        'frontend': [],
        'backend': [],
        'docs': [],
        'config': [],
        'other': []
    }

    for file_path, count in file_changes.items():
        if any(x in file_path.lower() for x in ['frontend/', 'src/app/', 'src/components/', '.tsx', '.jsx', 'styles/']):
            categories['frontend'].append((file_path, count))
        elif any(x in file_path.lower() for x in ['server/', 'app/', '.py', 'api/']):
            categories['backend'].append((file_path, count))
        elif any(x in file_path.lower() for x in ['docs/', '.md', 'readme']):
            categories['docs'].append((file_path, count))
        elif any(x in file_path.lower() for x in ['.yml', '.yaml', '.json', '.toml', 'config', 'docker']):
            categories['config'].append((file_path, count))
        else:
            categories['other'].append((file_path, count))

    # Sort each category by count
    for cat in categories:
        categories[cat].sort(key=lambda x: x[1], reverse=True)

    return categories


def generate_html(data: Dict) -> str:
    """Generate files history HTML page"""
    stats = data['statistics']
    logs = data['logs']
    generated_at = data.get('generated_at', '')

    # Analyze file changes
    analysis = analyze_file_changes(logs)
    file_changes = analysis['file_changes']
    file_commits = analysis['file_commits']

    # Get top changed files
    top_files = sorted(file_changes.items(), key=lambda x: x[1], reverse=True)[:20]

    # Categorize files
    categories = categorize_files(file_changes)

    # Prepare data for JavaScript
    import json as json_module
    top_files_data = {file: count for file, count in top_files}
    top_files_json = json_module.dumps(top_files_data, ensure_ascii=False)
    categories_count = {cat: len(files) for cat, files in categories.items()}
    categories_json = json_module.dumps(categories_count, ensure_ascii=False)

    html = f'''<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>File Changes History - PamOut</title>
    <link rel="stylesheet" href="styles.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <!-- Dark Mode Toggle -->
    <button class="dark-mode-toggle" onclick="toggleDarkMode()" aria-label="Toggle Dark Mode">
        <span id="darkModeIcon">🌙</span>
        <span class="toggle-label" id="darkModeLabel">Dark</span>
    </button>

    <header class="page-header">
        <div class="header-content">
            <h1>File Changes History</h1>
            <p class="header-subtitle">파일별 변경 내역 분석</p>
        </div>
        <nav class="stats-nav">
            <a href="index.html" class="nav-link">Kanban Board</a>
            <a href="timeline.html" class="nav-link">Timeline</a>
            <a href="heatmap.html" class="nav-link">Heatmap</a>
            <a href="files.html" class="nav-link active">Files</a>
            <a href="commit-size.html" class="nav-link">Commit Size</a>
            <a href="time-analysis.html" class="nav-link">Time Analysis</a>
            <a href="stats.html" class="nav-link">Statistics</a>
        </nav>
    </header>

    <main class="files-container">
        <!-- Summary Cards -->
        <section class="files-summary">
            <div class="summary-card">
                <div class="summary-value">{len(file_changes)}</div>
                <div class="summary-label">Unique Files</div>
            </div>
            <div class="summary-card">
                <div class="summary-value">{sum(file_changes.values())}</div>
                <div class="summary-label">Total Changes</div>
            </div>
            <div class="summary-card">
                <div class="summary-value">{len(categories['frontend'])}</div>
                <div class="summary-label">Frontend Files</div>
            </div>
            <div class="summary-card">
                <div class="summary-value">{len(categories['backend'])}</div>
                <div class="summary-label">Backend Files</div>
            </div>
        </section>

        <!-- Charts Grid -->
        <section class="charts-grid">
            <!-- Top Changed Files Chart -->
            <div class="chart-card full-width">
                <h3 class="chart-title">Most Changed Files</h3>
                <p class="chart-subtitle">파일별 변경 횟수 TOP 20</p>
                <canvas id="topFilesChart"></canvas>
            </div>

            <!-- Category Distribution -->
            <div class="chart-card">
                <h3 class="chart-title">Files by Category</h3>
                <p class="chart-subtitle">카테고리별 파일 분포</p>
                <canvas id="categoryChart"></canvas>
            </div>

            <!-- Hot Files Table -->
            <div class="chart-card">
                <h3 class="chart-title">Hot Files</h3>
                <p class="chart-subtitle">가장 자주 변경되는 파일</p>
                <div class="hot-files-list">
    '''

    # Add top 10 hot files
    for i, (file_path, count) in enumerate(top_files[:10], 1):
        file_name = file_path.split('/')[-1]
        commits_list = file_commits.get(file_path, [])
        commits_count = len(commits_list)

        html += f'''
                    <div class="hot-file-item">
                        <div class="hot-file-rank">#{i}</div>
                        <div class="hot-file-info">
                            <div class="hot-file-name">{file_name}</div>
                            <div class="hot-file-path">{file_path}</div>
                        </div>
                        <div class="hot-file-count">{count} changes</div>
                    </div>
        '''

    html += f'''
                </div>
            </div>
        </section>

        <!-- Detailed File List by Category -->
        <section class="files-by-category">
            <h2 class="section-title">Files by Category</h2>
    '''

    # Add category sections
    category_labels = {
        'frontend': 'Frontend',
        'backend': 'Backend',
        'docs': 'Documentation',
        'config': 'Configuration',
        'other': 'Other'
    }

    for cat, label in category_labels.items():
        if categories[cat]:
            html += f'''
            <div class="category-section">
                <h3 class="category-title">{label} ({len(categories[cat])} files)</h3>
                <div class="file-table">
                    <table>
                        <thead>
                            <tr>
                                <th>File</th>
                                <th>Changes</th>
                            </tr>
                        </thead>
                        <tbody>
            '''

            for file_path, count in categories[cat][:15]:  # Show top 15 per category
                html += f'''
                            <tr>
                                <td class="file-cell">{file_path}</td>
                                <td class="count-cell">{count}</td>
                            </tr>
                '''

            html += '''
                        </tbody>
                    </table>
                </div>
            </div>
            '''

    html += f'''
        </section>
    </main>

    <footer class="page-footer">
        <p>Generated at {generated_at} | PamOut Workstation Manager</p>
        <p><a href="https://ws.abada.co.kr" target="_blank">https://ws.abada.co.kr</a></p>
    </footer>

    <script>
        const topFilesData = {top_files_json};
        const categoriesData = {categories_json};

        // Top Files Bar Chart
        const topFilesLabels = Object.keys(topFilesData).map(path => {{
            const parts = path.split('/');
            return parts[parts.length - 1];
        }});
        const topFilesValues = Object.values(topFilesData);

        new Chart(document.getElementById('topFilesChart'), {{
            type: 'bar',
            data: {{
                labels: topFilesLabels,
                datasets: [{{
                    label: 'Changes',
                    data: topFilesValues,
                    backgroundColor: '#3b82f6',
                    borderRadius: 4
                }}]
            }},
            options: {{
                responsive: true,
                maintainAspectRatio: false,
                indexAxis: 'y',
                plugins: {{
                    legend: {{
                        display: false
                    }}
                }},
                scales: {{
                    x: {{
                        beginAtZero: true,
                        ticks: {{
                            stepSize: 1
                        }}
                    }}
                }}
            }}
        }});

        // Category Doughnut Chart
        new Chart(document.getElementById('categoryChart'), {{
            type: 'doughnut',
            data: {{
                labels: ['Frontend', 'Backend', 'Docs', 'Config', 'Other'],
                datasets: [{{
                    data: Object.values(categoriesData),
                    backgroundColor: ['#10b981', '#3b82f6', '#f59e0b', '#8b5cf6', '#6b7280'],
                    borderWidth: 0
                }}]
            }},
            options: {{
                responsive: true,
                maintainAspectRatio: true,
                plugins: {{
                    legend: {{
                        position: 'bottom'
                    }}
                }}
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
    output_file = project_root / 'docs' / 'html' / 'files.html'

    # Load data
    print("\n[Loading] dev-logs data...")
    with open(data_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    print(f"[OK] Loaded {data['statistics']['total_logs']} logs")

    # Generate HTML
    print("\n[Generating] Files History HTML...")
    html = generate_html(data)

    # Save HTML
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(html)

    print(f"[SUCCESS] Files History HTML generated successfully!")
    print(f"[Output] {output_file}")
    print(f"\n[Browser] Open in browser:")
    print(f"   file://{output_file}")


if __name__ == '__main__':
    main()
