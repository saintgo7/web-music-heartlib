#!/usr/bin/env python3
"""
Time Analysis Generator
Analyzes commit patterns by hour, day of week, etc.
"""

import json
from pathlib import Path
from datetime import datetime
from collections import defaultdict
from typing import Dict, List


def analyze_by_hour(logs: List[Dict]) -> Dict[int, int]:
    """Analyze commits by hour of day"""
    hours = defaultdict(int)

    for log in logs:
        date_str = log.get('date', '')
        try:
            dt = datetime.strptime(date_str, '%Y-%m-%d %H:%M:%S')
            hours[dt.hour] += 1
        except:
            pass

    return dict(hours)


def analyze_by_weekday(logs: List[Dict]) -> Dict[str, int]:
    """Analyze commits by day of week"""
    weekdays = defaultdict(int)
    weekday_names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']

    for log in logs:
        date_str = log.get('date', '')
        try:
            dt = datetime.strptime(date_str, '%Y-%m-%d %H:%M:%S')
            day_name = weekday_names[dt.weekday()]
            weekdays[day_name] += 1
        except:
            pass

    # Ensure all weekdays are present
    result = {day: weekdays.get(day, 0) for day in weekday_names}
    return result


def find_most_productive_time(hours: Dict[int, int]) -> str:
    """Find most productive time period"""
    if not hours:
        return "No data"

    max_hour = max(hours.items(), key=lambda x: x[1])[0]

    if 6 <= max_hour < 12:
        period = "Morning (06:00-12:00)"
    elif 12 <= max_hour < 18:
        period = "Afternoon (12:00-18:00)"
    elif 18 <= max_hour < 24:
        period = "Evening (18:00-24:00)"
    else:
        period = "Night (00:00-06:00)"

    return period


def generate_html(data: Dict) -> str:
    """Generate time analysis HTML page"""
    stats = data['statistics']
    logs = data['logs']
    generated_at = data.get('generated_at', '')

    # Analyze time patterns
    hours = analyze_by_hour(logs)
    weekdays = analyze_by_weekday(logs)

    # Fill missing hours with 0
    hours_filled = {h: hours.get(h, 0) for h in range(24)}

    # Calculate statistics
    most_productive = find_most_productive_time(hours)
    most_active_hour = max(hours.items(), key=lambda x: x[1])[0] if hours else 0
    most_active_day = max(weekdays.items(), key=lambda x: x[1])[0] if weekdays else 'N/A'

    # Weekend vs Weekday
    weekend_commits = weekdays.get('Sat', 0) + weekdays.get('Sun', 0)
    weekday_commits = sum(weekdays.values()) - weekend_commits

    # Prepare data for JavaScript
    import json as json_module
    hours_json = json_module.dumps([hours_filled[h] for h in range(24)], ensure_ascii=False)
    weekdays_json = json_module.dumps(list(weekdays.values()), ensure_ascii=False)

    html = f'''<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Time Analysis - PamOut</title>
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
            <h1>Time Analysis</h1>
            <p class="header-subtitle">시간대별 커밋 패턴 분석</p>
        </div>
        <nav class="stats-nav">
            <a href="index.html" class="nav-link">Kanban Board</a>
            <a href="timeline.html" class="nav-link">Timeline</a>
            <a href="heatmap.html" class="nav-link">Heatmap</a>
            <a href="files.html" class="nav-link">Files</a>
            <a href="commit-size.html" class="nav-link">Commit Size</a>
            <a href="time-analysis.html" class="nav-link active">Time Analysis</a>
            <a href="stats.html" class="nav-link">Statistics</a>
        </nav>
    </header>

    <main class="time-analysis-container">
        <!-- Summary Cards -->
        <section class="time-summary">
            <div class="summary-card">
                <div class="summary-value">{most_active_hour:02d}:00</div>
                <div class="summary-label">Peak Hour</div>
            </div>
            <div class="summary-card">
                <div class="summary-value">{most_active_day}</div>
                <div class="summary-label">Most Active Day</div>
            </div>
            <div class="summary-card">
                <div class="summary-value">{weekday_commits}</div>
                <div class="summary-label">Weekday Commits</div>
            </div>
            <div class="summary-card">
                <div class="summary-value">{weekend_commits}</div>
                <div class="summary-label">Weekend Commits</div>
            </div>
        </section>

        <!-- Insights -->
        <section class="insights-section">
            <div class="insight-card">
                <h3 class="insight-title">Most Productive Time</h3>
                <div class="insight-value">{most_productive}</div>
                <p class="insight-description">가장 활발하게 작업하는 시간대입니다</p>
            </div>
            <div class="insight-card">
                <h3 class="insight-title">Work Pattern</h3>
                <div class="insight-value">
                    {round(weekday_commits / (weekday_commits + weekend_commits) * 100, 1) if (weekday_commits + weekend_commits) > 0 else 0}% Weekday
                </div>
                <p class="insight-description">주중/주말 작업 비율</p>
            </div>
        </section>

        <!-- Charts -->
        <section class="charts-grid">
            <div class="chart-card full-width">
                <h3 class="chart-title">Commits by Hour</h3>
                <p class="chart-subtitle">시간대별 커밋 분포 (24시간)</p>
                <canvas id="hourChart"></canvas>
            </div>

            <div class="chart-card">
                <h3 class="chart-title">Commits by Day of Week</h3>
                <p class="chart-subtitle">요일별 커밋 분포</p>
                <canvas id="weekdayChart"></canvas>
            </div>

            <div class="chart-card">
                <h3 class="chart-title">Time Recommendations</h3>
                <p class="chart-subtitle">작업 시간 패턴 분석</p>
                <div class="recommendations">
                    <div class="recommendation-item">
                        <div class="rec-icon">⏰</div>
                        <div class="rec-content">
                            <strong>Peak hours:</strong> Schedule important tasks during {most_active_hour:02d}:00-{(most_active_hour+2)%24:02d}:00
                        </div>
                    </div>
                    <div class="recommendation-item">
                        <div class="rec-icon">📅</div>
                        <div class="rec-content">
                            <strong>Best day:</strong> {most_active_day} shows highest activity
                        </div>
                    </div>
                    <div class="recommendation-item">
                        <div class="rec-icon">⚖️</div>
                        <div class="rec-content">
                            <strong>Work-life balance:</strong> {'Good balance maintained' if weekend_commits < weekday_commits * 0.3 else 'Consider more rest on weekends'}
                        </div>
                    </div>
                </div>
            </div>
        </section>
    </main>

    <footer class="page-footer">
        <p>Generated at {generated_at} | PamOut Workstation Manager</p>
        <p><a href="https://ws.abada.co.kr" target="_blank">https://ws.abada.co.kr</a></p>
    </footer>

    <script>
        const hoursData = {hours_json};
        const weekdaysData = {weekdays_json};

        // Hour Chart
        new Chart(document.getElementById('hourChart'), {{
            type: 'line',
            data: {{
                labels: Array.from({{length: 24}}, (_, i) => `${{i.toString().padStart(2, '0')}}:00`),
                datasets: [{{
                    label: 'Commits',
                    data: hoursData,
                    borderColor: '#3b82f6',
                    backgroundColor: 'rgba(59, 130, 246, 0.1)',
                    fill: true,
                    tension: 0.4,
                    pointRadius: 4,
                    pointHoverRadius: 6
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

        // Weekday Chart
        new Chart(document.getElementById('weekdayChart'), {{
            type: 'bar',
            data: {{
                labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                datasets: [{{
                    label: 'Commits',
                    data: weekdaysData,
                    backgroundColor: '#10b981',
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
    output_file = project_root / 'docs' / 'html' / 'time-analysis.html'

    # Load data
    print("\n[Loading] dev-logs data...")
    with open(data_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    print(f"[OK] Loaded {data['statistics']['total_logs']} logs")

    # Generate HTML
    print("\n[Generating] Time Analysis HTML...")
    html = generate_html(data)

    # Save HTML
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(html)

    print(f"[SUCCESS] Time Analysis HTML generated successfully!")
    print(f"[Output] {output_file}")
    print(f"\n[Browser] Open in browser:")
    print(f"   file://{output_file}")


if __name__ == '__main__':
    main()
