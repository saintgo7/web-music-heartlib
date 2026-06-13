#!/usr/bin/env python3
"""
Activity Heatmap Generator for Dev Log
Generates GitHub-style activity heatmap from parsed dev-logs JSON
"""

import json
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, List
from collections import defaultdict


def get_date_only(date_str: str) -> str:
    """Get date only (YYYY-MM-DD)"""
    try:
        dt = datetime.strptime(date_str, '%Y-%m-%d %H:%M:%S')
        return dt.strftime('%Y-%m-%d')
    except:
        return date_str.split()[0] if ' ' in date_str else date_str


def count_commits_by_date(logs: List[Dict]) -> Dict[str, int]:
    """Count commits by date"""
    counts = defaultdict(int)
    for log in logs:
        date = get_date_only(log.get('date', ''))
        if date:
            counts[date] += 1
    return dict(counts)


def get_date_range(logs: List[Dict]) -> tuple:
    """Get min and max dates from logs"""
    dates = []
    for log in logs:
        date_str = get_date_only(log.get('date', ''))
        if date_str:
            try:
                dates.append(datetime.strptime(date_str, '%Y-%m-%d'))
            except:
                pass

    if not dates:
        return datetime.now(), datetime.now()

    return min(dates), max(dates)


def generate_heatmap_grid(commits_by_date: Dict[str, int], start_date: datetime, end_date: datetime) -> str:
    """Generate heatmap grid HTML"""

    # Calculate weeks needed
    days_diff = (end_date - start_date).days + 1
    weeks_needed = (days_diff + start_date.weekday()) // 7 + 1

    # Determine color intensity levels
    max_commits = max(commits_by_date.values()) if commits_by_date else 1

    def get_intensity_class(count: int) -> str:
        if count == 0:
            return 'intensity-0'
        elif count <= max_commits * 0.25:
            return 'intensity-1'
        elif count <= max_commits * 0.5:
            return 'intensity-2'
        elif count <= max_commits * 0.75:
            return 'intensity-3'
        else:
            return 'intensity-4'

    # Generate grid by weeks and days
    grid_html = '<div class="heatmap-grid">'

    # Month labels
    grid_html += '<div class="heatmap-months">'
    current_date = start_date
    for week in range(weeks_needed):
        week_start = start_date + timedelta(days=week * 7)
        if week == 0 or week_start.day <= 7:
            month_name = week_start.strftime('%b')
            grid_html += f'<div class="month-label">{month_name}</div>'
        else:
            grid_html += '<div class="month-label"></div>'
    grid_html += '</div>'

    # Day labels (Mon, Wed, Fri)
    grid_html += '<div class="heatmap-days">'
    day_labels = ['', 'Mon', '', 'Wed', '', 'Fri', '']
    for label in day_labels:
        grid_html += f'<div class="day-label">{label}</div>'
    grid_html += '</div>'

    # Heatmap cells
    grid_html += '<div class="heatmap-cells">'

    # Start from the first Monday before or on start_date
    current_date = start_date - timedelta(days=start_date.weekday())

    for week in range(weeks_needed):
        grid_html += '<div class="heatmap-week">'

        for day in range(7):
            cell_date = current_date + timedelta(days=week * 7 + day)
            date_str = cell_date.strftime('%Y-%m-%d')

            # Check if date is within range
            if cell_date < start_date or cell_date > end_date:
                grid_html += '<div class="heatmap-cell empty"></div>'
            else:
                count = commits_by_date.get(date_str, 0)
                intensity = get_intensity_class(count)
                weekday = cell_date.strftime('%a')
                formatted_date = cell_date.strftime('%Y-%m-%d (%a)')

                grid_html += f'''<div class="heatmap-cell {intensity}"
                    data-date="{date_str}"
                    data-count="{count}"
                    title="{formatted_date}: {count} commits">
                </div>'''

        grid_html += '</div>'

    grid_html += '</div>'
    grid_html += '</div>'

    return grid_html


def generate_legend_html() -> str:
    """Generate legend HTML"""
    return '''
    <div class="heatmap-legend">
        <span class="legend-label">Less</span>
        <div class="legend-squares">
            <div class="legend-square intensity-0"></div>
            <div class="legend-square intensity-1"></div>
            <div class="legend-square intensity-2"></div>
            <div class="legend-square intensity-3"></div>
            <div class="legend-square intensity-4"></div>
        </div>
        <span class="legend-label">More</span>
    </div>
    '''


def calculate_streak(commits_by_date: Dict[str, int], end_date: datetime) -> Dict:
    """Calculate current and longest streak"""
    current_streak = 0
    longest_streak = 0
    temp_streak = 0

    # Check last 365 days
    for i in range(365):
        check_date = end_date - timedelta(days=i)
        date_str = check_date.strftime('%Y-%m-%d')

        if commits_by_date.get(date_str, 0) > 0:
            temp_streak += 1
            if i == 0 or current_streak > 0:
                current_streak = temp_streak
        else:
            if temp_streak > longest_streak:
                longest_streak = temp_streak
            if current_streak > 0:
                temp_streak = 0

    if temp_streak > longest_streak:
        longest_streak = temp_streak

    return {
        'current': current_streak,
        'longest': longest_streak
    }


def generate_html(data: Dict) -> str:
    """Generate complete heatmap HTML page"""
    stats = data['statistics']
    logs = data['logs']
    generated_at = data.get('generated_at', '')

    # Get date range
    start_date, end_date = get_date_range(logs)

    # Count commits by date
    commits_by_date = count_commits_by_date(logs)

    # Calculate streaks
    streaks = calculate_streak(commits_by_date, end_date)

    # Calculate total active days
    total_active_days = len([d for d, c in commits_by_date.items() if c > 0])

    # Generate heatmap grid
    heatmap_html = generate_heatmap_grid(commits_by_date, start_date, end_date)
    legend_html = generate_legend_html()

    html = f'''<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Activity Heatmap - PamOut</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <!-- Dark Mode Toggle -->
    <button class="dark-mode-toggle" onclick="toggleDarkMode()" aria-label="Toggle Dark Mode">
        <span id="darkModeIcon">🌙</span>
        <span class="toggle-label" id="darkModeLabel">Dark</span>
    </button>

    <header class="page-header">
        <div class="header-content">
            <h1>Activity Heatmap</h1>
            <p class="header-subtitle">개발 활동 히트맵</p>
        </div>
        <nav class="stats-nav">
            <a href="index.html" class="nav-link">Kanban Board</a>
            <a href="timeline.html" class="nav-link">Timeline</a>
            <a href="heatmap.html" class="nav-link active">Heatmap</a>
            <a href="files.html" class="nav-link">Files</a>
            <a href="commit-size.html" class="nav-link">Commit Size</a>
            <a href="time-analysis.html" class="nav-link">Time Analysis</a>
            <a href="stats.html" class="nav-link">Statistics</a>
        </nav>
    </header>

    <main class="heatmap-container">
        <!-- Activity Summary -->
        <section class="heatmap-summary">
            <div class="summary-card">
                <div class="summary-value">{stats['total_logs']}</div>
                <div class="summary-label">Total Commits</div>
            </div>
            <div class="summary-card">
                <div class="summary-value">{total_active_days}</div>
                <div class="summary-label">Active Days</div>
            </div>
            <div class="summary-card">
                <div class="summary-value">{streaks['current']}</div>
                <div class="summary-label">Current Streak</div>
            </div>
            <div class="summary-card">
                <div class="summary-value">{streaks['longest']}</div>
                <div class="summary-label">Longest Streak</div>
            </div>
        </section>

        <!-- Heatmap -->
        <section class="heatmap-section">
            <div class="heatmap-header">
                <h2>Commit Activity</h2>
                <p class="heatmap-period">{start_date.strftime('%Y-%m-%d')} - {end_date.strftime('%Y-%m-%d')}</p>
            </div>

            {heatmap_html}

            {legend_html}
        </section>

        <!-- Top Days -->
        <section class="top-days-section">
            <h2>Most Active Days</h2>
            <div class="top-days-list">
    '''

    # Top 10 most active days
    sorted_dates = sorted(commits_by_date.items(), key=lambda x: x[1], reverse=True)[:10]
    for date_str, count in sorted_dates:
        try:
            dt = datetime.strptime(date_str, '%Y-%m-%d')
            weekday = dt.strftime('%a')
            formatted = dt.strftime('%Y-%m-%d')
            html += f'''
                <div class="top-day-item">
                    <div class="top-day-date">{formatted} ({weekday})</div>
                    <div class="top-day-bar">
                        <div class="top-day-fill" style="width: {(count / sorted_dates[0][1]) * 100}%"></div>
                    </div>
                    <div class="top-day-count">{count} commits</div>
                </div>
            '''
        except:
            pass

    html += f'''
            </div>
        </section>
    </main>

    <footer class="page-footer">
        <p>Generated at {generated_at} | PamOut Workstation Manager</p>
        <p><a href="https://ws.abada.co.kr" target="_blank">https://ws.abada.co.kr</a></p>
    </footer>

    <script>
        // Tooltip for heatmap cells
        document.querySelectorAll('.heatmap-cell:not(.empty)').forEach(cell => {{
            cell.addEventListener('mouseenter', function(e) {{
                const date = this.dataset.date;
                const count = this.dataset.count;
                const title = this.getAttribute('title');

                // You can add custom tooltip here if needed
                console.log(title);
            }});
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
    output_file = project_root / 'docs' / 'html' / 'heatmap.html'

    # Load data
    print("\n[Loading] dev-logs data...")
    with open(data_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    print(f"[OK] Loaded {data['statistics']['total_logs']} logs")

    # Generate HTML
    print("\n[Generating] Heatmap HTML...")
    html = generate_html(data)

    # Save HTML
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(html)

    print(f"[SUCCESS] Heatmap HTML generated successfully!")
    print(f"[Output] {output_file}")
    print(f"\n[Browser] Open in browser:")
    print(f"   file://{output_file}")


if __name__ == '__main__':
    main()
