#!/bin/bash
#
# Update HTML Kanban Board
# Parses dev-logs and regenerates HTML
#

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  [UPDATE] Dev Log Kanban Board"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 1: Parse dev-logs
echo "Step 1/2: Parsing dev-log files..."
python3 "$SCRIPT_DIR/parse-devlog.py"

if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to parse dev-logs"
    exit 1
fi

echo ""

# Step 2: Generate HTML
echo "Step 2/5: Generating HTML..."
python3 "$SCRIPT_DIR/generate-html.py"

if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to generate HTML"
    exit 1
fi

echo ""

# Step 3: Generate Timeline
echo "Step 3/5: Generating Timeline..."
python3 "$SCRIPT_DIR/generate-timeline.py"

if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to generate timeline"
    exit 1
fi

echo ""

# Step 4: Generate Heatmap
echo "Step 4/6: Generating Heatmap..."
python3 "$SCRIPT_DIR/generate-heatmap.py"

if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to generate heatmap"
    exit 1
fi

echo ""

# Step 5: Generate Files History
echo "Step 5/8: Generating Files History..."
python3 "$SCRIPT_DIR/generate-files-history.py"

if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to generate files history"
    exit 1
fi

echo ""

# Step 6: Generate Commit Size Analysis
echo "Step 6/8: Generating Commit Size Analysis..."
python3 "$SCRIPT_DIR/generate-commit-size.py"

if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to generate commit size analysis"
    exit 1
fi

echo ""

# Step 7: Generate Time Analysis
echo "Step 7/8: Generating Time Analysis..."
python3 "$SCRIPT_DIR/generate-time-analysis.py"

if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to generate time analysis"
    exit 1
fi

echo ""

# Step 8: Generate Deployment History
echo "Step 8/9: Generating Deployment History..."
python3 "$SCRIPT_DIR/generate-deployment.py"

if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to generate deployment history"
    exit 1
fi

echo ""

# Step 9: Generate Statistics
echo "Step 9/9: Generating Statistics..."
python3 "$SCRIPT_DIR/generate-stats.py"

if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to generate statistics"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  [SUCCESS] Update complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "[Browser] Open in browser:"
echo "   file://$PROJECT_ROOT/docs/html/index.html"
echo ""
