#!/usr/bin/env python3
"""
Statistics Page Generator
Generates development progress statistics page with charts
"""

import json
from pathlib import Path
from datetime import datetime


def generate_stats_html(data: dict) -> str:
    """Generate statistics HTML page"""
    stats = data['statistics']
    logs = data['logs']

    # Prepare data for charts
    categories = stats['categories']
    by_type = stats['by_type']

    # Calculate percentages for categories
    total_cat = sum(categories.values())
    cat_percentages = {k: round(v / total_cat * 100, 1) if total_cat > 0 else 0 for k, v in categories.items()}

    # Feature completion based on ROADMAP
    features_status = {
        'v1.0.0 - Basic Features': {'completed': 5, 'total': 5},
        'v1.1.0 - Core Enhancement': {'completed': 4, 'total': 4},
        'v1.2.0 - Management': {'completed': 1, 'total': 4},  # SuperAdmin 완료
        'v1.3.0 - Enterprise': {'completed': 0, 'total': 6},
        'v2.0.0 - Next Gen': {'completed': 0, 'total': 5},
    }

    categories_json = json.dumps(categories)
    by_type_json = json.dumps(by_type)
    features_json = json.dumps(features_status)

    html = f'''<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Development Statistics - PamOut</title>
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
            <h1>Development Statistics</h1>
            <p class="header-subtitle">PamOut 워크스테이션 관리 시스템 개발 현황</p>
        </div>
        <nav class="stats-nav">
            <a href="index.html" class="nav-link">Kanban Board</a>
            <a href="timeline.html" class="nav-link">Timeline</a>
            <a href="heatmap.html" class="nav-link">Heatmap</a>
            <a href="files.html" class="nav-link">Files</a>
            <a href="commit-size.html" class="nav-link">Commit Size</a>
            <a href="time-analysis.html" class="nav-link">Time Analysis</a>
            <a href="stats.html" class="nav-link active">Statistics</a>
        </nav>
    </header>

    <main class="stats-container">
        <!-- Overall Stats -->
        <section class="stats-overview">
            <div class="stat-card">
                <div class="stat-card-header">Total Commits</div>
                <div class="stat-card-value">{stats['total_logs']}</div>
            </div>
            <div class="stat-card">
                <div class="stat-card-header">Files Changed</div>
                <div class="stat-card-value">{stats['total_files_changed']}</div>
            </div>
            <div class="stat-card">
                <div class="stat-card-header">Lines Added</div>
                <div class="stat-card-value text-green">+{stats['total_lines_added']:,}</div>
            </div>
            <div class="stat-card">
                <div class="stat-card-header">Lines Deleted</div>
                <div class="stat-card-value text-red">-{stats['total_lines_deleted']:,}</div>
            </div>
        </section>

        <!-- Charts Grid -->
        <section class="charts-grid">
            <!-- Category Distribution -->
            <div class="chart-card">
                <h3 class="chart-title">Code Distribution</h3>
                <p class="chart-subtitle">프론트엔드 / 백엔드 / 문서 / 설정 비율</p>
                <canvas id="categoryChart"></canvas>
                <div class="chart-legend">
                    <div class="legend-item">
                        <span class="legend-dot" style="background: #10b981;"></span>
                        <span>Frontend: {cat_percentages['frontend']}%</span>
                    </div>
                    <div class="legend-item">
                        <span class="legend-dot" style="background: #3b82f6;"></span>
                        <span>Backend: {cat_percentages['backend']}%</span>
                    </div>
                    <div class="legend-item">
                        <span class="legend-dot" style="background: #f59e0b;"></span>
                        <span>Docs: {cat_percentages['docs']}%</span>
                    </div>
                    <div class="legend-item">
                        <span class="legend-dot" style="background: #8b5cf6;"></span>
                        <span>Config: {cat_percentages['config']}%</span>
                    </div>
                </div>
            </div>

            <!-- Commit Type Distribution -->
            <div class="chart-card">
                <h3 class="chart-title">Commit Types</h3>
                <p class="chart-subtitle">커밋 타입별 분포</p>
                <canvas id="typeChart"></canvas>
            </div>

            <!-- Feature Completion -->
            <div class="chart-card full-width">
                <h3 class="chart-title">Feature Completion Status</h3>
                <p class="chart-subtitle">버전별 기능 완료 현황 (ROADMAP 기준)</p>
                <div id="featureProgress"></div>
            </div>

            <!-- Next Steps -->
            <div class="chart-card full-width">
                <h3 class="chart-title">Next Steps</h3>
                <p class="chart-subtitle">향후 개발 계획</p>
                <div class="next-steps">
                    <div class="step-item pending">
                        <div class="step-badge">v1.2.0</div>
                        <div class="step-content">
                            <h4>User Management Enhancement</h4>
                            <p>RBAC, Permission UI, API Key Management, Audit Log</p>
                            <span class="step-duration">4-5 days</span>
                        </div>
                    </div>
                    <div class="step-item pending">
                        <div class="step-badge">v1.2.0</div>
                        <div class="step-content">
                            <h4>Workstation Grouping</h4>
                            <p>Group/Tag System, Batch Operations</p>
                            <span class="step-duration">3-4 days</span>
                        </div>
                    </div>
                    <div class="step-item pending">
                        <div class="step-badge">v1.2.0</div>
                        <div class="step-content">
                            <h4>Automation Workflow</h4>
                            <p>Scheduled Tasks, Workflow Engine, Event Triggers</p>
                            <span class="step-duration">5-6 days</span>
                        </div>
                    </div>
                    <div class="step-item pending">
                        <div class="step-badge">v1.2.0</div>
                        <div class="step-content">
                            <h4>GPU Monitoring</h4>
                            <p>NVIDIA/AMD GPU Metrics, GPU Dashboard, Alerts</p>
                            <span class="step-duration">3-4 days</span>
                        </div>
                    </div>
                </div>
            </div>
        </section>
    </main>

    <footer class="page-footer">
        <p>Generated at {data['generated_at']} | PamOut Workstation Manager</p>
        <p><a href="https://ws.abada.co.kr" target="_blank">https://ws.abada.co.kr</a></p>
    </footer>

    <script>
        const categories = {categories_json};
        const byType = {by_type_json};
        const features = {features_json};

        // Category Doughnut Chart
        new Chart(document.getElementById('categoryChart'), {{
            type: 'doughnut',
            data: {{
                labels: ['Frontend', 'Backend', 'Docs', 'Config'],
                datasets: [{{
                    data: [categories.frontend, categories.backend, categories.docs, categories.config],
                    backgroundColor: ['#10b981', '#3b82f6', '#f59e0b', '#8b5cf6'],
                    borderWidth: 0
                }}]
            }},
            options: {{
                responsive: true,
                maintainAspectRatio: true,
                plugins: {{
                    legend: {{
                        display: false
                    }}
                }}
            }}
        }});

        // Type Bar Chart
        new Chart(document.getElementById('typeChart'), {{
            type: 'bar',
            data: {{
                labels: Object.keys(byType),
                datasets: [{{
                    label: 'Commits',
                    data: Object.values(byType),
                    backgroundColor: '#3b82f6',
                    borderRadius: 4
                }}]
            }},
            options: {{
                responsive: true,
                maintainAspectRatio: true,
                plugins: {{
                    legend: {{
                        display: false
                    }}
                }},
                scales: {{
                    y: {{
                        beginAtZero: true,
                        ticks: {{
                            stepSize: 1
                        }}
                    }}
                }}
            }}
        }});

        // Feature Progress Bars
        const progressContainer = document.getElementById('featureProgress');
        Object.entries(features).forEach(([version, status]) => {{
            const percentage = (status.completed / status.total * 100).toFixed(0);
            const html = `
                <div class="progress-item">
                    <div class="progress-header">
                        <span class="progress-label">${{version}}</span>
                        <span class="progress-value">${{status.completed}} / ${{status.total}} (${{percentage}}%)</span>
                    </div>
                    <div class="progress-bar">
                        <div class="progress-fill" style="width: ${{percentage}}%"></div>
                    </div>
                </div>
            `;
            progressContainer.innerHTML += html;
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
    output_file = project_root / 'docs' / 'html' / 'stats.html'

    # Load data
    print("\n[Loading] dev-logs data...")
    with open(data_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    print(f"[OK] Loaded {data['statistics']['total_logs']} logs")

    # Generate HTML
    print("\n[Generating] Statistics page...")
    html = generate_stats_html(data)

    # Save HTML
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(html)

    print(f"[SUCCESS] Statistics page generated!")
    print(f"[Output] {output_file}")
    print(f"\n[Browser] Open in browser:")
    print(f"   file://{output_file}")


if __name__ == '__main__':
    main()
