#!/usr/bin/env python3
"""
Commit Size Analysis Generator
Analyzes commit sizes and patterns
"""

import json
from pathlib import Path
from typing import Dict, List


def categorize_commit_size(lines_changed: int) -> str:
    """Categorize commit by size"""
    if lines_changed < 50:
        return 'small'
    elif lines_changed < 200:
        return 'medium'
    elif lines_changed < 500:
        return 'large'
    else:
        return 'xlarge'


def analyze_commit_sizes(logs: List[Dict]) -> Dict:
    """Analyze commit size distribution"""
    sizes = {'small': [], 'medium': [], 'large': [], 'xlarge': []}

    for log in logs:
        lines_added = log.get('lines_added', 0)
        lines_deleted = log.get('lines_deleted', 0)
        total_lines = lines_added + lines_deleted

        size_cat = categorize_commit_size(total_lines)
        sizes[size_cat].append({
            'log_number': log.get('log_number', '?'),
            'title': log.get('title', ''),
            'lines_added': lines_added,
            'lines_deleted': lines_deleted,
            'total_lines': total_lines,
            'files_changed': log.get('files_changed', 0),
            'date': log.get('date', ''),
            'commit': log.get('commit', 'N/A')[:7]
        })

    return sizes


def generate_html(data: Dict) -> str:
    """Generate commit size analysis HTML page"""
    stats = data['statistics']
    logs = data['logs']
    generated_at = data.get('generated_at', '')

    # Analyze commit sizes
    sizes = analyze_commit_sizes(logs)

    # Calculate statistics
    size_counts = {cat: len(commits) for cat, commits in sizes.items()}
    total = sum(size_counts.values())
    size_percentages = {cat: round(count / total * 100, 1) if total > 0 else 0
                       for cat, count in size_counts.items()}

    # Prepare data for JavaScript
    import json as json_module
    size_counts_json = json_module.dumps(size_counts, ensure_ascii=False)

    html = f'''<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Commit Size Analysis - PamOut</title>
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
            <h1>Commit Size Analysis</h1>
            <p class="header-subtitle">커밋 크기 패턴 분석</p>
        </div>
        <nav class="stats-nav">
            <a href="index.html" class="nav-link">Kanban Board</a>
            <a href="timeline.html" class="nav-link">Timeline</a>
            <a href="heatmap.html" class="nav-link">Heatmap</a>
            <a href="files.html" class="nav-link">Files</a>
            <a href="commit-size.html" class="nav-link active">Commit Size</a>
            <a href="stats.html" class="nav-link">Statistics</a>
        </nav>
    </header>

    <main class="commit-size-container">
        <!-- Summary Cards -->
        <section class="size-summary">
            <div class="size-card small">
                <div class="size-card-header">
                    <span class="size-badge">Small</span>
                    <span class="size-range">&lt; 50 lines</span>
                </div>
                <div class="size-card-value">{size_counts['small']}</div>
                <div class="size-card-percentage">{size_percentages['small']}%</div>
            </div>
            <div class="size-card medium">
                <div class="size-card-header">
                    <span class="size-badge">Medium</span>
                    <span class="size-range">50-200 lines</span>
                </div>
                <div class="size-card-value">{size_counts['medium']}</div>
                <div class="size-card-percentage">{size_percentages['medium']}%</div>
            </div>
            <div class="size-card large">
                <div class="size-card-header">
                    <span class="size-badge">Large</span>
                    <span class="size-range">200-500 lines</span>
                </div>
                <div class="size-card-value">{size_counts['large']}</div>
                <div class="size-card-percentage">{size_percentages['large']}%</div>
            </div>
            <div class="size-card xlarge">
                <div class="size-card-header">
                    <span class="size-badge">X-Large</span>
                    <span class="size-range">&gt; 500 lines</span>
                </div>
                <div class="size-card-value">{size_counts['xlarge']}</div>
                <div class="size-card-percentage">{size_percentages['xlarge']}%</div>
            </div>
        </section>

        <!-- Charts -->
        <section class="charts-grid">
            <div class="chart-card">
                <h3 class="chart-title">Size Distribution</h3>
                <p class="chart-subtitle">커밋 크기 분포</p>
                <canvas id="sizeChart"></canvas>
            </div>

            <div class="chart-card">
                <h3 class="chart-title">Best Practices</h3>
                <p class="chart-subtitle">권장 사항</p>
                <div class="best-practices">
                    <div class="practice-item">
                        <div class="practice-icon">✓</div>
                        <div class="practice-text">
                            <strong>Small commits preferred:</strong> Easier to review and debug
                        </div>
                    </div>
                    <div class="practice-item">
                        <div class="practice-icon">⚠</div>
                        <div class="practice-text">
                            <strong>Large commits:</strong> Consider breaking into smaller pieces
                        </div>
                    </div>
                    <div class="practice-item">
                        <div class="practice-icon">!</div>
                        <div class="practice-text">
                            <strong>X-Large commits:</strong> Review for potential split opportunities
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <!-- Commit Lists by Size -->
        <section class="commit-lists">
    '''

    # Add commit lists for each size category
    size_labels = {
        'small': {'title': 'Small Commits', 'color': '#10b981'},
        'medium': {'title': 'Medium Commits', 'color': '#3b82f6'},
        'large': {'title': 'Large Commits', 'color': '#f59e0b'},
        'xlarge': {'title': 'X-Large Commits', 'color': '#ef4444'}
    }

    for size_cat, info in size_labels.items():
        commits = sizes[size_cat]
        if commits:
            # Sort by total lines descending
            commits.sort(key=lambda x: x['total_lines'], reverse=True)

            html += f'''
            <div class="commit-list-section">
                <h3 class="commit-list-title">{info['title']} ({len(commits)})</h3>
                <div class="commit-list">
            '''

            for commit in commits[:10]:  # Show top 10
                html += f'''
                    <div class="commit-size-item">
                        <div class="commit-size-header">
                            <span class="commit-size-number">#{commit['log_number']}</span>
                            <span class="commit-size-hash">{commit['commit']}</span>
                        </div>
                        <div class="commit-size-title">{commit['title']}</div>
                        <div class="commit-size-stats">
                            <span class="stat-item">
                                <span class="stat-label">Files:</span> {commit['files_changed']}
                            </span>
                            <span class="stat-item">
                                <span class="stat-label text-green">+{commit['lines_added']}</span>
                            </span>
                            <span class="stat-item">
                                <span class="stat-label text-red">-{commit['lines_deleted']}</span>
                            </span>
                            <span class="stat-item">
                                <span class="stat-label">Total:</span> {commit['total_lines']} lines
                            </span>
                        </div>
                    </div>
                '''

            html += '''
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
        const sizeCounts = {size_counts_json};

        // Size Distribution Pie Chart
        new Chart(document.getElementById('sizeChart'), {{
            type: 'pie',
            data: {{
                labels: ['Small (<50)', 'Medium (50-200)', 'Large (200-500)', 'X-Large (>500)'],
                datasets: [{{
                    data: [sizeCounts.small, sizeCounts.medium, sizeCounts.large, sizeCounts.xlarge],
                    backgroundColor: ['#10b981', '#3b82f6', '#f59e0b', '#ef4444'],
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
    output_file = project_root / 'docs' / 'html' / 'commit-size.html'

    # Load data
    print("\n[Loading] dev-logs data...")
    with open(data_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    print(f"[OK] Loaded {data['statistics']['total_logs']} logs")

    # Generate HTML
    print("\n[Generating] Commit Size Analysis HTML...")
    html = generate_html(data)

    # Save HTML
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(html)

    print(f"[SUCCESS] Commit Size Analysis HTML generated successfully!")
    print(f"[Output] {output_file}")
    print(f"\n[Browser] Open in browser:")
    print(f"   file://{output_file}")


if __name__ == '__main__':
    main()
