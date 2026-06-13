#!/usr/bin/env python3
"""
HTML Generator for Dev Log Kanban Board
Generates static HTML kanban board from parsed dev-logs JSON
"""

import json
from pathlib import Path
from datetime import datetime
from typing import Dict, List


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


def generate_card_html(log: Dict, index: int) -> str:
    """Generate HTML for a single card"""
    log_type = log.get('type', 'unknown')
    type_info = get_type_info(log_type)

    title = log.get('title', 'Untitled')
    date = format_date(log.get('date', ''))
    commit = log.get('commit', 'N/A')[:7]
    log_number = log.get('log_number', '?')

    files_changed = log.get('files_changed', 0)
    lines_added = log.get('lines_added', 0)
    lines_deleted = log.get('lines_deleted', 0)

    details_html = ''
    if 'details' in log:
        details_items = log['details'][:3]  # Show first 3 items
        details_html = '<ul class="card-details">' + ''.join([
            f'<li>{detail}</li>' for detail in details_items
        ]) + '</ul>'

    return f'''
    <div class="card" data-type="{log_type}" data-number="{log_number}" data-log-index="{index}" onclick="openModal({index})">
        <div class="card-header">
            <div class="card-header-left">
                <span class="card-number">#{log_number}</span>
                <span class="card-type" style="background-color: {type_info['color']}">
                    {type_info['icon']} {type_info['en']}
                </span>
            </div>
            <button class="bookmark-btn" data-log-number="{log_number}" onclick="toggleBookmark(event, '{log_number}')" title="Bookmark this commit">
                <span class="bookmark-icon">☆</span>
            </button>
        </div>
        <h3 class="card-title">{title}</h3>
        {details_html}
        <div class="card-meta">
            <div class="meta-item">
                <span class="meta-label">Date:</span>
                <span>{date}</span>
            </div>
            <div class="meta-item">
                <span class="meta-label">Changes:</span>
                <span>{files_changed} files, <span class="text-green">+{lines_added}</span> <span class="text-red">-{lines_deleted}</span></span>
            </div>
            <div class="meta-item">
                <span class="meta-label">Commit:</span>
                <span class="commit-hash">{commit}</span>
            </div>
        </div>
        <div class="card-footer">
            <span class="view-detail">View Details →</span>
        </div>
    </div>
    '''


def generate_column_html(column_type: str, logs: List[Dict], all_logs: List[Dict]) -> str:
    """Generate HTML for a kanban column"""
    type_info = get_type_info(column_type)

    # Find indices in the main logs list
    cards_html_list = []
    for log in logs:
        log_number = log.get('log_number')
        # Find index in all_logs
        index = next((i for i, l in enumerate(all_logs) if l.get('log_number') == log_number), 0)
        cards_html_list.append(generate_card_html(log, index))

    cards_html = '\n'.join(cards_html_list)

    return f'''
    <div class="kanban-column">
        <div class="column-header" style="border-color: {type_info['color']}; background-color: {type_info['color']}15">
            <h2>
                <span class="column-badge">{type_info['icon']}</span>
                {type_info['en']}
                <span class="column-count">{len(logs)}</span>
            </h2>
        </div>
        <div class="column-cards">
            {cards_html if cards_html else '<div class="empty-column">No logs yet</div>'}
        </div>
    </div>
    '''


def generate_html(data: Dict) -> str:
    """Generate complete HTML page"""
    stats = data['statistics']
    logs = data['logs']
    generated_at = data.get('generated_at', '')

    # Group logs by type
    logs_by_type = {}
    for log in logs:
        log_type = log.get('type', 'unknown')
        if log_type not in logs_by_type:
            logs_by_type[log_type] = []
        logs_by_type[log_type].append(log)

    # Generate columns for main types
    main_types = ['feat', 'fix', 'docs', 'ci']
    columns_html = ''
    for column_type in main_types:
        column_logs = logs_by_type.get(column_type, [])
        columns_html += generate_column_html(column_type, column_logs, logs)

    # Other types column
    other_types = [t for t in logs_by_type.keys() if t not in main_types]
    other_logs = []
    for t in other_types:
        other_logs.extend(logs_by_type[t])
    if other_logs:
        columns_html += generate_column_html('chore', other_logs, logs)

    # Prepare logs data for JavaScript
    import json as json_module
    logs_json = json_module.dumps(logs, ensure_ascii=False)

    html = f'''<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PamOut Development Progress</title>
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
            <h1>PamOut Development Progress</h1>
            <p class="header-subtitle">워크스테이션 관리 시스템 개발 로그</p>
        </div>
        <nav class="stats-nav">
            <a href="index.html" class="nav-link active">Kanban Board</a>
            <a href="timeline.html" class="nav-link">Timeline</a>
            <a href="heatmap.html" class="nav-link">Heatmap</a>
            <a href="files.html" class="nav-link">Files</a>
            <a href="commit-size.html" class="nav-link">Commit Size</a>
            <a href="time-analysis.html" class="nav-link">Time Analysis</a>
            <a href="deployment.html" class="nav-link">Deployment</a>
            <a href="stats.html" class="nav-link">Statistics</a>
        </nav>

        <!-- Search and Filter -->
        <div class="search-filter-bar">
            <div class="search-box">
                <input type="text" id="searchInput" placeholder="Search commits..." />
                <button class="advanced-search-toggle" id="advancedSearchToggle" onclick="toggleAdvancedSearch()">
                    Advanced ▼
                </button>
            </div>
            <div class="filter-buttons">
                <button class="filter-btn active" data-type="all">All</button>
                <button class="filter-btn" data-type="bookmarked">★ Bookmarked</button>
                <button class="filter-btn" data-type="feat">Features</button>
                <button class="filter-btn" data-type="fix">Fixes</button>
                <button class="filter-btn" data-type="docs">Docs</button>
                <button class="filter-btn" data-type="ci">CI/CD</button>
            </div>
        </div>

        <!-- Advanced Search Panel -->
        <div class="advanced-search-panel" id="advancedSearchPanel">
            <div class="advanced-search-grid">
                <div class="search-field">
                    <label for="dateFrom">Date From</label>
                    <input type="date" id="dateFrom" />
                </div>
                <div class="search-field">
                    <label for="dateTo">Date To</label>
                    <input type="date" id="dateTo" />
                </div>
                <div class="search-field">
                    <label for="filePathFilter">File Path Contains</label>
                    <input type="text" id="filePathFilter" placeholder="e.g., src/api/" />
                </div>
                <div class="search-field">
                    <label for="commitHashFilter">Commit Hash</label>
                    <input type="text" id="commitHashFilter" placeholder="e.g., abc1234" />
                </div>
                <div class="search-field">
                    <label for="linesMin">Min Lines Changed</label>
                    <input type="number" id="linesMin" min="0" placeholder="0" />
                </div>
                <div class="search-field">
                    <label for="linesMax">Max Lines Changed</label>
                    <input type="number" id="linesMax" min="0" placeholder="1000" />
                </div>
            </div>
            <div class="advanced-search-actions">
                <button class="btn-apply-filters" onclick="applyAdvancedFilters()">Apply Filters</button>
                <button class="btn-reset-filters" onclick="resetAdvancedFilters()">Reset</button>
            </div>
        </div>

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

    <main class="kanban-board">
        {columns_html}
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
        // Set global logsData for modal
        window.logsData = {logs_json};

        // Search functionality
        const searchInput = document.getElementById('searchInput');
        const allCards = document.querySelectorAll('.card');

        searchInput.addEventListener('input', function(e) {{
            const searchTerm = e.target.value.toLowerCase();

            allCards.forEach(card => {{
                const title = card.querySelector('.card-title').textContent.toLowerCase();
                const details = card.querySelector('.card-details')?.textContent.toLowerCase() || '';
                const matches = title.includes(searchTerm) || details.includes(searchTerm);

                card.style.display = matches ? 'block' : 'none';
            }});

            updateEmptyColumns();
        }});

        // Filter functionality
        const filterButtons = document.querySelectorAll('.filter-btn');
        let activeFilter = 'all';

        filterButtons.forEach(btn => {{
            btn.addEventListener('click', function() {{
                // Update active button
                filterButtons.forEach(b => b.classList.remove('active'));
                this.classList.add('active');

                activeFilter = this.dataset.type;

                // Filter cards
                allCards.forEach(card => {{
                    const cardType = card.dataset.type;
                    const searchTerm = searchInput.value.toLowerCase();
                    const title = card.querySelector('.card-title').textContent.toLowerCase();
                    const details = card.querySelector('.card-details')?.textContent.toLowerCase() || '';

                    const matchesType = activeFilter === 'all' || cardType === activeFilter;
                    const matchesSearch = title.includes(searchTerm) || details.includes(searchTerm);

                    card.style.display = (matchesType && matchesSearch) ? 'block' : 'none';
                }});

                updateEmptyColumns();
            }});
        }});

        function updateEmptyColumns() {{
            const columns = document.querySelectorAll('.kanban-column');
            columns.forEach(column => {{
                const visibleCards = column.querySelectorAll('.card[style*="display: block"], .card:not([style*="display: none"])');
                const emptyMsg = column.querySelector('.empty-column');

                if (visibleCards.length === 0 && !emptyMsg) {{
                    const cardsContainer = column.querySelector('.column-cards');
                    cardsContainer.innerHTML = '<div class="empty-column">No matching logs</div>';
                }} else if (visibleCards.length > 0 && emptyMsg) {{
                    emptyMsg.remove();
                }}
            }});
        }}

        // Advanced Search Functions
        function toggleAdvancedSearch() {{
            const panel = document.getElementById('advancedSearchPanel');
            const toggle = document.getElementById('advancedSearchToggle');
            const isVisible = panel.style.display === 'block';

            panel.style.display = isVisible ? 'none' : 'block';
            toggle.textContent = isVisible ? 'Advanced ▼' : 'Advanced ▲';
        }}

        function applyAdvancedFilters() {{
            const dateFrom = document.getElementById('dateFrom').value;
            const dateTo = document.getElementById('dateTo').value;
            const filePathFilter = document.getElementById('filePathFilter').value.toLowerCase();
            const commitHashFilter = document.getElementById('commitHashFilter').value.toLowerCase();
            const linesMin = parseInt(document.getElementById('linesMin').value) || 0;
            const linesMax = parseInt(document.getElementById('linesMax').value) || Infinity;

            allCards.forEach(card => {{
                const logIndex = parseInt(card.dataset.logIndex);
                const log = logsData[logIndex];
                if (!log) {{
                    card.style.display = 'none';
                    return;
                }}

                // Date filter
                let matchesDate = true;
                if (dateFrom || dateTo) {{
                    const logDate = log.date.split(' ')[0]; // YYYY-MM-DD
                    if (dateFrom && logDate < dateFrom) matchesDate = false;
                    if (dateTo && logDate > dateTo) matchesDate = false;
                }}

                // File path filter
                let matchesFilePath = true;
                if (filePathFilter) {{
                    const fullContent = (log.full_content || '').toLowerCase();
                    matchesFilePath = fullContent.includes(filePathFilter);
                }}

                // Commit hash filter
                let matchesCommit = true;
                if (commitHashFilter) {{
                    const commit = (log.commit || '').toLowerCase();
                    matchesCommit = commit.includes(commitHashFilter);
                }}

                // Lines changed filter
                const linesChanged = (log.lines_added || 0) + (log.lines_deleted || 0);
                const matchesLines = linesChanged >= linesMin && linesChanged <= linesMax;

                // Basic search
                const searchTerm = searchInput.value.toLowerCase();
                const title = (log.title || '').toLowerCase();
                const details = (log.details || []).join(' ').toLowerCase();
                const matchesSearch = !searchTerm || title.includes(searchTerm) || details.includes(searchTerm);

                // Type filter
                const cardType = card.dataset.type;
                const matchesType = activeFilter === 'all' || cardType === activeFilter;

                // Combine all filters
                const shouldShow = matchesDate && matchesFilePath && matchesCommit &&
                                   matchesLines && matchesSearch && matchesType;

                card.style.display = shouldShow ? 'block' : 'none';
            }});

            updateEmptyColumns();
        }}

        function resetAdvancedFilters() {{
            document.getElementById('dateFrom').value = '';
            document.getElementById('dateTo').value = '';
            document.getElementById('filePathFilter').value = '';
            document.getElementById('commitHashFilter').value = '';
            document.getElementById('linesMin').value = '';
            document.getElementById('linesMax').value = '';

            // Re-apply basic filters only
            allCards.forEach(card => {{
                const searchTerm = searchInput.value.toLowerCase();
                const title = card.querySelector('.card-title').textContent.toLowerCase();
                const details = card.querySelector('.card-details')?.textContent.toLowerCase() || '';
                const cardType = card.dataset.type;

                const matchesType = activeFilter === 'all' || cardType === activeFilter;
                const matchesSearch = !searchTerm || title.includes(searchTerm) || details.includes(searchTerm);

                card.style.display = (matchesType && matchesSearch) ? 'block' : 'none';
            }});

            updateEmptyColumns();
        }}

        // Bookmark Functions
        let bookmarks = JSON.parse(localStorage.getItem('bookmarks') || '[]');

        // Load bookmarks on page load
        function loadBookmarks() {{
            bookmarks.forEach(logNumber => {{
                const btn = document.querySelector(`.bookmark-btn[data-log-number="${{logNumber}}"]`);
                if (btn) {{
                    btn.classList.add('bookmarked');
                    btn.querySelector('.bookmark-icon').textContent = '★';
                }}
            }});
        }}

        function toggleBookmark(event, logNumber) {{
            event.stopPropagation(); // Prevent card click

            const btn = event.currentTarget;
            const icon = btn.querySelector('.bookmark-icon');
            const isBookmarked = bookmarks.includes(logNumber);

            if (isBookmarked) {{
                // Remove bookmark
                bookmarks = bookmarks.filter(num => num !== logNumber);
                btn.classList.remove('bookmarked');
                icon.textContent = '☆';
            }} else {{
                // Add bookmark
                bookmarks.push(logNumber);
                btn.classList.add('bookmarked');
                icon.textContent = '★';
            }}

            // Save to localStorage
            localStorage.setItem('bookmarks', JSON.stringify(bookmarks));

            // If bookmarked filter is active, update view
            if (activeFilter === 'bookmarked') {{
                filterByBookmarks();
            }}
        }}

        function filterByBookmarks() {{
            allCards.forEach(card => {{
                const logNumber = card.dataset.number;
                const isBookmarked = bookmarks.includes(logNumber);
                card.style.display = isBookmarked ? 'block' : 'none';
            }});
            updateEmptyColumns();
        }}

        // Update filter functionality to handle bookmarked filter
        filterButtons.forEach(btn => {{
            btn.addEventListener('click', function() {{
                // Update active button
                filterButtons.forEach(b => b.classList.remove('active'));
                this.classList.add('active');

                activeFilter = this.dataset.type;

                if (activeFilter === 'bookmarked') {{
                    filterByBookmarks();
                }} else {{
                    // Filter cards
                    allCards.forEach(card => {{
                        const cardType = card.dataset.type;
                        const searchTerm = searchInput.value.toLowerCase();
                        const title = card.querySelector('.card-title').textContent.toLowerCase();
                        const details = card.querySelector('.card-details')?.textContent.toLowerCase() || '';

                        const matchesType = activeFilter === 'all' || cardType === activeFilter;
                        const matchesSearch = title.includes(searchTerm) || details.includes(searchTerm);

                        card.style.display = (matchesType && matchesSearch) ? 'block' : 'none';
                    }});

                    updateEmptyColumns();
                }}
            }});
        }});

        // Load bookmarks on page load
        loadBookmarks();
    </script>
</body>
</html>'''

    return html


def main():
    """Main function"""
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    data_file = project_root / 'docs' / 'html' / 'data' / 'dev-logs.json'
    output_file = project_root / 'docs' / 'html' / 'index.html'

    # Load data
    print("\n[Loading] dev-logs data...")
    with open(data_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    print(f"[OK] Loaded {data['statistics']['total_logs']} logs")

    # Generate HTML
    print("\n[Generating] HTML...")
    html = generate_html(data)

    # Save HTML
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(html)

    print(f"[SUCCESS] HTML generated successfully!")
    print(f"[Output] {output_file}")
    print(f"\n[Browser] Open in browser:")
    print(f"   file://{output_file}")


if __name__ == '__main__':
    main()
