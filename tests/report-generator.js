#!/usr/bin/env node

/**
 * Test Report Generator
 *
 * Aggregates test results from various sources and generates
 * comprehensive HTML and JSON reports
 *
 * Usage:
 *   node tests/report-generator.js [options]
 *
 * Options:
 *   --e2e-results <path>     Path to E2E results JSON
 *   --perf-results <path>    Path to performance results JSON
 *   --output <path>          Output directory for reports
 */

const fs = require('fs');
const path = require('path');

// Configuration
const config = {
  e2eResultsPath: './web/test-results/e2e-results.json',
  perfResultsPath: './test-reports/load-test-summary.json',
  outputDir: './test-reports',
  timestamp: new Date().toISOString(),
};

// Parse command line arguments
const args = process.argv.slice(2);
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--e2e-results' && args[i + 1]) {
    config.e2eResultsPath = args[i + 1];
    i++;
  } else if (args[i] === '--perf-results' && args[i + 1]) {
    config.perfResultsPath = args[i + 1];
    i++;
  } else if (args[i] === '--output' && args[i + 1]) {
    config.outputDir = args[i + 1];
    i++;
  }
}

// Ensure output directory exists
if (!fs.existsSync(config.outputDir)) {
  fs.mkdirSync(config.outputDir, { recursive: true });
}

/**
 * Load E2E test results
 */
function loadE2EResults() {
  try {
    if (fs.existsSync(config.e2eResultsPath)) {
      const data = fs.readFileSync(config.e2eResultsPath, 'utf8');
      return JSON.parse(data);
    }
  } catch (error) {
    console.warn('Could not load E2E results:', error.message);
  }
  return null;
}

/**
 * Load performance test results
 */
function loadPerfResults() {
  try {
    if (fs.existsSync(config.perfResultsPath)) {
      const data = fs.readFileSync(config.perfResultsPath, 'utf8');
      return JSON.parse(data);
    }
  } catch (error) {
    console.warn('Could not load performance results:', error.message);
  }
  return null;
}

/**
 * Analyze E2E results
 */
function analyzeE2EResults(results) {
  if (!results || !results.suites) {
    return {
      total: 0,
      passed: 0,
      failed: 0,
      skipped: 0,
      duration: 0,
      passRate: 0,
    };
  }

  let total = 0;
  let passed = 0;
  let failed = 0;
  let skipped = 0;

  const countTests = (suite) => {
    if (suite.specs) {
      suite.specs.forEach((spec) => {
        total++;
        if (spec.ok) passed++;
        else if (spec.tests && spec.tests.some((t) => t.status === 'skipped')) skipped++;
        else failed++;
      });
    }
    if (suite.suites) {
      suite.suites.forEach(countTests);
    }
  };

  results.suites.forEach(countTests);

  return {
    total,
    passed,
    failed,
    skipped,
    duration: results.duration || 0,
    passRate: total > 0 ? ((passed / total) * 100).toFixed(2) : 0,
  };
}

/**
 * Analyze performance results
 */
function analyzePerfResults(results) {
  if (!results || !results.metrics) {
    return {
      totalRequests: 0,
      failedRequests: 0,
      avgResponseTime: 0,
      p95ResponseTime: 0,
      errorRate: 0,
    };
  }

  const metrics = results.metrics;

  return {
    totalRequests: metrics.http_reqs?.count || 0,
    failedRequests: metrics.http_req_failed?.values?.rate
      ? Math.round(metrics.http_req_failed.values.rate * (metrics.http_reqs?.count || 0))
      : 0,
    avgResponseTime: metrics.http_req_duration?.values?.avg?.toFixed(2) || 0,
    p95ResponseTime: metrics.http_req_duration?.values?.['p(95)']?.toFixed(2) || 0,
    errorRate: metrics.http_req_failed?.values?.rate
      ? (metrics.http_req_failed.values.rate * 100).toFixed(2)
      : 0,
  };
}

/**
 * Generate HTML report
 */
function generateHTMLReport(e2eAnalysis, perfAnalysis) {
  const html = `
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ABADA Music Studio - Test Report</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
      line-height: 1.6;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      min-height: 100vh;
      padding: 20px;
    }
    .container {
      max-width: 1200px;
      margin: 0 auto;
    }
    .header {
      background: white;
      padding: 40px;
      border-radius: 20px;
      box-shadow: 0 20px 60px rgba(0,0,0,0.3);
      margin-bottom: 30px;
      text-align: center;
    }
    .header h1 {
      font-size: 2.5em;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      margin-bottom: 10px;
    }
    .header .timestamp {
      color: #666;
      font-size: 0.9em;
    }
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 20px;
      margin-bottom: 30px;
    }
    .card {
      background: white;
      padding: 30px;
      border-radius: 15px;
      box-shadow: 0 10px 30px rgba(0,0,0,0.2);
    }
    .card h2 {
      font-size: 1.5em;
      margin-bottom: 20px;
      color: #333;
      border-bottom: 3px solid #667eea;
      padding-bottom: 10px;
    }
    .metric {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 15px 0;
      border-bottom: 1px solid #eee;
    }
    .metric:last-child {
      border-bottom: none;
    }
    .metric-label {
      font-weight: 600;
      color: #555;
    }
    .metric-value {
      font-size: 1.5em;
      font-weight: bold;
      color: #667eea;
    }
    .status-badge {
      display: inline-block;
      padding: 8px 20px;
      border-radius: 25px;
      font-weight: bold;
      font-size: 1.2em;
      text-transform: uppercase;
    }
    .status-passed {
      background: #10b981;
      color: white;
    }
    .status-failed {
      background: #ef4444;
      color: white;
    }
    .status-warning {
      background: #f59e0b;
      color: white;
    }
    .progress-bar {
      width: 100%;
      height: 30px;
      background: #e5e7eb;
      border-radius: 15px;
      overflow: hidden;
      margin: 10px 0;
    }
    .progress-fill {
      height: 100%;
      background: linear-gradient(90deg, #10b981 0%, #059669 100%);
      transition: width 0.3s ease;
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
      font-weight: bold;
    }
    .chart-container {
      margin: 20px 0;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin: 20px 0;
    }
    th, td {
      padding: 12px;
      text-align: left;
      border-bottom: 1px solid #ddd;
    }
    th {
      background: #f8f9fa;
      font-weight: 600;
      color: #333;
    }
    .footer {
      text-align: center;
      color: white;
      margin-top: 30px;
      padding: 20px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>테스트 리포트</h1>
      <p class="timestamp">생성 시각: ${new Date(config.timestamp).toLocaleString('ko-KR')}</p>
    </div>

    <div class="grid">
      <!-- E2E Test Results -->
      <div class="card">
        <h2>E2E 테스트 결과</h2>
        <div class="metric">
          <span class="metric-label">총 테스트</span>
          <span class="metric-value">${e2eAnalysis.total}</span>
        </div>
        <div class="metric">
          <span class="metric-label">통과</span>
          <span class="metric-value" style="color: #10b981;">${e2eAnalysis.passed}</span>
        </div>
        <div class="metric">
          <span class="metric-label">실패</span>
          <span class="metric-value" style="color: #ef4444;">${e2eAnalysis.failed}</span>
        </div>
        <div class="metric">
          <span class="metric-label">건너뜀</span>
          <span class="metric-value" style="color: #f59e0b;">${e2eAnalysis.skipped}</span>
        </div>
        <div class="progress-bar">
          <div class="progress-fill" style="width: ${e2eAnalysis.passRate}%">
            ${e2eAnalysis.passRate}%
          </div>
        </div>
        <div style="text-align: center; margin-top: 20px;">
          <span class="status-badge ${e2eAnalysis.passRate >= 95 ? 'status-passed' : e2eAnalysis.passRate >= 80 ? 'status-warning' : 'status-failed'}">
            ${e2eAnalysis.passRate >= 95 ? 'PASSED' : e2eAnalysis.passRate >= 80 ? 'WARNING' : 'FAILED'}
          </span>
        </div>
      </div>

      <!-- Performance Test Results -->
      <div class="card">
        <h2>성능 테스트 결과</h2>
        <div class="metric">
          <span class="metric-label">총 요청</span>
          <span class="metric-value">${perfAnalysis.totalRequests.toLocaleString()}</span>
        </div>
        <div class="metric">
          <span class="metric-label">실패 요청</span>
          <span class="metric-value" style="color: #ef4444;">${perfAnalysis.failedRequests}</span>
        </div>
        <div class="metric">
          <span class="metric-label">평균 응답시간</span>
          <span class="metric-value">${perfAnalysis.avgResponseTime}ms</span>
        </div>
        <div class="metric">
          <span class="metric-label">P95 응답시간</span>
          <span class="metric-value">${perfAnalysis.p95ResponseTime}ms</span>
        </div>
        <div class="metric">
          <span class="metric-label">에러율</span>
          <span class="metric-value" style="color: ${perfAnalysis.errorRate < 1 ? '#10b981' : '#ef4444'};">${perfAnalysis.errorRate}%</span>
        </div>
        <div style="text-align: center; margin-top: 20px;">
          <span class="status-badge ${perfAnalysis.errorRate < 1 && perfAnalysis.p95ResponseTime < 2000 ? 'status-passed' : 'status-warning'}">
            ${perfAnalysis.errorRate < 1 && perfAnalysis.p95ResponseTime < 2000 ? 'PASSED' : 'WARNING'}
          </span>
        </div>
      </div>
    </div>

    <!-- Detailed Metrics -->
    <div class="card">
      <h2>상세 메트릭</h2>
      <table>
        <thead>
          <tr>
            <th>카테고리</th>
            <th>메트릭</th>
            <th>값</th>
            <th>임계값</th>
            <th>상태</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>E2E</td>
            <td>통과율</td>
            <td>${e2eAnalysis.passRate}%</td>
            <td>> 95%</td>
            <td><span class="status-badge ${e2eAnalysis.passRate >= 95 ? 'status-passed' : 'status-failed'}" style="font-size: 0.8em;">
              ${e2eAnalysis.passRate >= 95 ? 'PASS' : 'FAIL'}
            </span></td>
          </tr>
          <tr>
            <td>성능</td>
            <td>에러율</td>
            <td>${perfAnalysis.errorRate}%</td>
            <td>< 1%</td>
            <td><span class="status-badge ${perfAnalysis.errorRate < 1 ? 'status-passed' : 'status-failed'}" style="font-size: 0.8em;">
              ${perfAnalysis.errorRate < 1 ? 'PASS' : 'FAIL'}
            </span></td>
          </tr>
          <tr>
            <td>성능</td>
            <td>P95 응답시간</td>
            <td>${perfAnalysis.p95ResponseTime}ms</td>
            <td>< 2000ms</td>
            <td><span class="status-badge ${perfAnalysis.p95ResponseTime < 2000 ? 'status-passed' : 'status-failed'}" style="font-size: 0.8em;">
              ${perfAnalysis.p95ResponseTime < 2000 ? 'PASS' : 'FAIL'}
            </span></td>
          </tr>
        </tbody>
      </table>
    </div>

    <div class="footer">
      <p>ABADA Music Studio - 자동화된 테스트 리포트</p>
      <p>© 2026 ABADA Inc. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
  `;

  return html;
}

/**
 * Generate JSON report
 */
function generateJSONReport(e2eAnalysis, perfAnalysis) {
  return {
    timestamp: config.timestamp,
    e2e: e2eAnalysis,
    performance: perfAnalysis,
    thresholds: {
      e2e_pass_rate: { target: 95, actual: e2eAnalysis.passRate, passed: e2eAnalysis.passRate >= 95 },
      perf_error_rate: { target: 1, actual: perfAnalysis.errorRate, passed: perfAnalysis.errorRate < 1 },
      perf_p95: { target: 2000, actual: perfAnalysis.p95ResponseTime, passed: perfAnalysis.p95ResponseTime < 2000 },
    },
  };
}

/**
 * Main execution
 */
function main() {
  console.log('Generating test reports...');

  // Load results
  const e2eResults = loadE2EResults();
  const perfResults = loadPerfResults();

  // Analyze results
  const e2eAnalysis = analyzeE2EResults(e2eResults);
  const perfAnalysis = analyzePerfResults(perfResults);

  console.log('E2E Results:', e2eAnalysis);
  console.log('Performance Results:', perfAnalysis);

  // Generate reports
  const htmlReport = generateHTMLReport(e2eAnalysis, perfAnalysis);
  const jsonReport = generateJSONReport(e2eAnalysis, perfAnalysis);

  // Save reports
  const htmlPath = path.join(config.outputDir, 'test-report.html');
  const jsonPath = path.join(config.outputDir, 'test-report.json');

  fs.writeFileSync(htmlPath, htmlReport);
  fs.writeFileSync(jsonPath, JSON.stringify(jsonReport, null, 2));

  console.log(`HTML report saved to: ${htmlPath}`);
  console.log(`JSON report saved to: ${jsonPath}`);

  // Exit with error code if tests failed
  const overallPassed =
    e2eAnalysis.passRate >= 95 && perfAnalysis.errorRate < 1 && perfAnalysis.p95ResponseTime < 2000;

  process.exit(overallPassed ? 0 : 1);
}

main();
