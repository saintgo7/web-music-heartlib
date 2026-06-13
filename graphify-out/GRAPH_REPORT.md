# Graph Report - .  (2026-06-14)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 942 nodes · 1575 edges · 110 communities (75 shown, 35 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 47 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `ebd64018`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_HeartCodec Implementation|HeartCodec Implementation]]
- [[_COMMUNITY_Flow Matching & ODE|Flow Matching & ODE]]
- [[_COMMUNITY_UI Layout Components|UI Layout Components]]
- [[_COMMUNITY_Analytics & Stats Logic|Analytics & Stats Logic]]
- [[_COMMUNITY_Frontend Page Routing|Frontend Page Routing]]
- [[_COMMUNITY_CICD Infrastructure|CI/CD Infrastructure]]
- [[_COMMUNITY_AI Model Pipelines|AI Model Pipelines]]
- [[_COMMUNITY_HeartMuLa Model Architecture|HeartMuLa Model Architecture]]
- [[_COMMUNITY_Devlog Analysis Tools|Devlog Analysis Tools]]
- [[_COMMUNITY_Frontend Page Content|Frontend Page Content]]
- [[_COMMUNITY_HTML Report Generation|HTML Report Generation]]
- [[_COMMUNITY_Monitoring Dashboard Setup|Monitoring Dashboard Setup]]
- [[_COMMUNITY_TypeScript App Config|TypeScript App Config]]
- [[_COMMUNITY_Project Planning & Specs|Project Planning & Specs]]
- [[_COMMUNITY_Cloudflare Automation|Cloudflare Automation]]
- [[_COMMUNITY_Deployment Scripts|Deployment Scripts]]
- [[_COMMUNITY_GitHub Secrets Setup|GitHub Secrets Setup]]
- [[_COMMUNITY_Post-Deployment Verification|Post-Deployment Verification]]
- [[_COMMUNITY_Frontend Build Tooling|Frontend Build Tooling]]
- [[_COMMUNITY_TypeScript Node Config|TypeScript Node Config]]
- [[_COMMUNITY_Local Test Environment|Local Test Environment]]
- [[_COMMUNITY_Production Release Build|Production Release Build]]
- [[_COMMUNITY_Monitoring Configuration|Monitoring Configuration]]
- [[_COMMUNITY_Rollback Procedures|Rollback Procedures]]
- [[_COMMUNITY_Performance Load Testing|Performance Load Testing]]
- [[_COMMUNITY_KV Store Seeding|KV Store Seeding]]
- [[_COMMUNITY_Commit Heatmap Generation|Commit Heatmap Generation]]
- [[_COMMUNITY_NPM Scripts|NPM Scripts]]
- [[_COMMUNITY_Deployment Frequency Analysis|Deployment Frequency Analysis]]
- [[_COMMUNITY_Tech Stack Overview|Tech Stack Overview]]
- [[_COMMUNITY_Application Build System|Application Build System]]
- [[_COMMUNITY_Deployment Runbooks|Deployment Runbooks]]
- [[_COMMUNITY_Productivity Time Analysis|Productivity Time Analysis]]
- [[_COMMUNITY_Project Metadata|Project Metadata]]
- [[_COMMUNITY_API Latency Testing|API Latency Testing]]
- [[_COMMUNITY_Technical Requirements|Technical Requirements]]
- [[_COMMUNITY_System Integration|System Integration]]
- [[_COMMUNITY_Commit Size Analysis|Commit Size Analysis]]
- [[_COMMUNITY_File History Analysis|File History Analysis]]
- [[_COMMUNITY_Analytics API Utility|Analytics API Utility]]
- [[_COMMUNITY_System Architecture Stack|System Architecture Stack]]
- [[_COMMUNITY_Search & Filter Logic|Search & Filter Logic]]
- [[_COMMUNITY_Security Auditing|Security Auditing]]
- [[_COMMUNITY_Project Management Tracking|Project Management Tracking]]
- [[_COMMUNITY_Cloudflare Deployment Guide|Cloudflare Deployment Guide]]
- [[_COMMUNITY_E2E Test Suite|E2E Test Suite]]
- [[_COMMUNITY_Frontend Dependencies|Frontend Dependencies]]
- [[_COMMUNITY_KV Backup Utility|KV Backup Utility]]
- [[_COMMUNITY_Frontend API Modules|Frontend API Modules]]
- [[_COMMUNITY_Production Checklist|Production Checklist]]
- [[_COMMUNITY_General Stats Generation|General Stats Generation]]
- [[_COMMUNITY_Version Dependencies|Version Dependencies]]
- [[_COMMUNITY_Installer Development|Installer Development]]
- [[_COMMUNITY_Load Testing Deps|Load Testing Deps]]
- [[_COMMUNITY_Performance Testing Guide|Performance Testing Guide]]
- [[_COMMUNITY_Release Documentation|Release Documentation]]
- [[_COMMUNITY_Testing Report Tools|Testing Report Tools]]
- [[_COMMUNITY_Core Page Components|Core Page Components]]
- [[_COMMUNITY_App Entry & Performance|App Entry & Performance]]
- [[_COMMUNITY_Repository Metadata|Repository Metadata]]
- [[_COMMUNITY_TS Config References|TS Config References]]
- [[_COMMUNITY_Activity Visualization|Activity Visualization]]
- [[_COMMUNITY_Build Verification|Build Verification]]
- [[_COMMUNITY_Test Execution Script|Test Execution Script]]
- [[_COMMUNITY_HTML Update Script|HTML Update Script]]
- [[_COMMUNITY_Test Setup Verification|Test Setup Verification]]
- [[_COMMUNITY_GitHub Issues Setup|GitHub Issues Setup]]
- [[_COMMUNITY_GitHub Issues Setup V2|GitHub Issues Setup V2]]
- [[_COMMUNITY_Network Retry Utility|Network Retry Utility]]
- [[_COMMUNITY_Frontend Stack|Frontend Stack]]
- [[_COMMUNITY_ModelScope Integration|ModelScope Integration]]
- [[_COMMUNITY_Experiment Assets|Experiment Assets]]
- [[_COMMUNITY_Branding Assets|Branding Assets]]
- [[_COMMUNITY_Lyrics Data|Lyrics Data]]
- [[_COMMUNITY_Metadata Tags|Metadata Tags]]
- [[_COMMUNITY_KV Recovery Script|KV Recovery Script]]
- [[_COMMUNITY_Verification Utility|Verification Utility]]
- [[_COMMUNITY_Installer Workflow|Installer Workflow]]
- [[_COMMUNITY_Website Deployment Workflow|Website Deployment Workflow]]
- [[_COMMUNITY_Linting Workflow|Linting Workflow]]
- [[_COMMUNITY_Bookmark Management|Bookmark Management]]
- [[_COMMUNITY_Theme Management|Theme Management]]
- [[_COMMUNITY_Python Linting|Python Linting]]
- [[_COMMUNITY_Shell Linting|Shell Linting]]
- [[_COMMUNITY_Security Scanning|Security Scanning]]
- [[_COMMUNITY_NSIS Validation|NSIS Validation]]
- [[_COMMUNITY_HeartCLAP Model|HeartCLAP Model]]
- [[_COMMUNITY_HeartTranscriptor Model|HeartTranscriptor Model]]
- [[_COMMUNITY_Security Vulnerability Templates|Security Vulnerability Templates]]
- [[_COMMUNITY_Theme Management|Theme Management]]
- [[_COMMUNITY_About Page|About Page]]
- [[_COMMUNITY_FAQ Page|FAQ Page]]
- [[_COMMUNITY_Gallery Page|Gallery Page]]
- [[_COMMUNITY_Tutorial Page|Tutorial Page]]

## God Nodes (most connected - your core abstractions)
1. `compilerOptions` - 20 edges
2. `compilerOptions` - 18 edges
3. `scripts` - 16 edges
4. `fetch()` - 15 edges
5. `main()` - 15 edges
6. `main()` - 15 edges
7. `main()` - 14 edges
8. `main()` - 14 edges
9. `main()` - 13 edges
10. `print_header()` - 13 edges

## Surprising Connections (you probably didn't know these)
- `analyticsReporter()` --calls--> `fetch()`  [INFERRED]
  web/src/utils/performance.ts → functions/api/index.js
- `checkValidServiceWorker()` --calls--> `fetch()`  [INFERRED]
  web/src/utils/serviceWorker.ts → functions/api/index.js
- `cacheFirst()` --calls--> `fetch()`  [INFERRED]
  web/public/sw.js → functions/api/index.js
- `networkFirst()` --calls--> `fetch()`  [INFERRED]
  web/public/sw.js → functions/api/index.js
- `staleWhileRevalidate()` --calls--> `fetch()`  [INFERRED]
  web/public/sw.js → functions/api/index.js

## Import Cycles
- 1-file cycle: `scripts/generate-deployment.py -> scripts/generate-deployment.py`
- 1-file cycle: `scripts/generate-heatmap.py -> scripts/generate-heatmap.py`

## Communities (110 total, 35 thin omitted)

### Community 0 - "HeartCodec Implementation"
Cohesion: 0.06
Nodes (19): HeartCodecConfig, HeartCodec, HeartCodecConfig, InplaceFunction, Conv1d, ConvTranspose1d, DownsampleLayer, get_padding() (+11 more)

### Community 1 - "Flow Matching & ODE"
Cohesion: 0.08
Nodes (16): LongTensor, FlowMatching, Fixed euler solver for ODEs.         Args:             x (torch.Tensor): random, AdaLayerNormSingleFlow, LlamaAttention, LlamaMLP, LlamaTransformer, LlamaTransformerBlock (+8 more)

### Community 2 - "UI Layout Components"
Cohesion: 0.06
Nodes (17): DownloadOption, downloadOptions, Feature, features, FooterLink, FooterSection, footerSections, Sample (+9 more)

### Community 3 - "Analytics & Stats Logic"
Cohesion: 0.11
Nodes (26): corsHeaders, extractReferrerSource(), getAnalytics(), getDateRange(), recordAnalytics(), sanitizePath(), VALID_EVENT_TYPES, corsHeaders (+18 more)

### Community 4 - "Frontend Page Routing"
Cohesion: 0.08
Nodes (20): AboutPage, App(), DownloadPage, FAQPage, GalleryPage, HomePage, TutorialPage, analyticsReporter() (+12 more)

### Community 5 - "CI/CD Infrastructure"
Cohesion: 0.10
Nodes (28): Automated Backup Workflow, CLOUDFLARE_ACCOUNT_ID, CLOUDFLARE_API_TOKEN, Cloudflare KV, Cloudflare Pages, Cloudflare Workers, GitHub Actions, GitHub Releases (+20 more)

### Community 6 - "AI Model Pipelines"
Cohesion: 0.10
Nodes (14): Any, AutomaticSpeechRecognitionPipeline, BitsAndBytesConfig, HeartCodec, HeartMuLa, Pipeline, HeartTranscriptorPipeline, HeartMuLaGenConfig (+6 more)

### Community 7 - "HeartMuLa Model Architecture"
Cohesion: 0.14
Nodes (16): HeartMuLaConfig, _create_causal_mask(), HeartMuLa, _index_causal_mask(), llama3_2_300M(), llama3_2_3B(), llama3_2_400M(), llama3_2_7B() (+8 more)

### Community 8 - "Devlog Analysis Tools"
Cohesion: 0.13
Nodes (21): Path, analyze_file_categories(), generate_statistics(), main(), parse_all_devlogs(), parse_devlog_file(), Parse all dev-log files in directory, Analyze file changes by category (frontend/backend/docs/etc) (+13 more)

### Community 9 - "Frontend Page Content"
Cohesion: 0.09
Nodes (11): DownloadOption, downloadOptions, categories, faqData, FAQItem, allTags, Sample, sampleData (+3 more)

### Community 10 - "HTML Report Generation"
Cohesion: 0.15
Nodes (20): format_date(), generate_card_html(), generate_column_html(), generate_html(), get_type_info(), main(), Generate HTML for a kanban column, Generate complete HTML page (+12 more)

### Community 11 - "Monitoring Dashboard Setup"
Cohesion: 0.30
Nodes (20): create_dashboards(), create_notification_policy(), full_setup(), load_env(), log_error(), log_info(), log_section(), log_success() (+12 more)

### Community 12 - "TypeScript App Config"
Cohesion: 0.09
Nodes (21): compilerOptions, allowImportingTsExtensions, erasableSyntaxOnly, jsx, lib, module, moduleDetection, moduleResolution (+13 more)

### Community 13 - "Project Planning & Specs"
Cohesion: 0.11
Nodes (21): Build Installers Workflow, ABADA Music Studio, Cloudflare Infrastructure, HeartMuLa AI Model, Cross-Platform Installer, LazyImage Component, React 18 with TypeScript, Final Evaluation (+13 more)

### Community 14 - "Cloudflare Automation"
Cohesion: 0.40
Nodes (19): check_prerequisites(), create_kv_namespaces(), create_pages_project(), log(), main(), print_error(), print_header(), print_info() (+11 more)

### Community 15 - "Deployment Scripts"
Cohesion: 0.37
Nodes (18): build_website(), check_environment(), cleanup(), create_deployment_log(), deploy_pages(), deploy_workers(), log(), main() (+10 more)

### Community 16 - "GitHub Secrets Setup"
Cohesion: 0.41
Nodes (18): check_existing_secrets(), check_github_cli(), collect_and_set_secrets(), detect_github_repo(), log(), main(), print_error(), print_header() (+10 more)

### Community 17 - "Post-Deployment Verification"
Cohesion: 0.37
Nodes (18): check_api_endpoints(), check_cloudflare_cache(), check_dns_configuration(), check_performance_baseline(), check_ssl_certificate(), check_website_accessibility(), generate_report(), main() (+10 more)

### Community 18 - "Frontend Build Tooling"
Cohesion: 0.10
Nodes (20): devDependencies, autoprefixer, @axe-core/playwright, eslint, @eslint/js, eslint-plugin-react-hooks, eslint-plugin-react-refresh, globals (+12 more)

### Community 19 - "TypeScript Node Config"
Cohesion: 0.10
Nodes (19): compilerOptions, allowImportingTsExtensions, erasableSyntaxOnly, lib, module, moduleDetection, moduleResolution, noEmit (+11 more)

### Community 20 - "Local Test Environment"
Cohesion: 0.35
Nodes (17): build_and_validate(), check_system_requirements(), command_exists(), create_sample_tests(), create_test_directories(), install_dependencies(), main(), prepare_test_data() (+9 more)

### Community 21 - "Production Release Build"
Cohesion: 0.38
Nodes (18): build_production(), check_requirements(), clean_build(), create_git_tag(), install_dependencies(), main(), print_error(), print_header() (+10 more)

### Community 22 - "Monitoring Configuration"
Cohesion: 0.37
Nodes (17): create_dashboard_config(), get_zone_id(), load_environment(), log(), main(), print_error(), print_header(), print_info() (+9 more)

### Community 23 - "Rollback Procedures"
Cohesion: 0.43
Nodes (18): check_environment(), confirm_action(), generate_rollback_report(), list_deployments(), log(), main(), print_error(), print_header() (+10 more)

### Community 24 - "Performance Load Testing"
Cohesion: 0.11
Nodes (5): apiResponseTime, errorRate, options, pageLoadTime, successfulRequests

### Community 25 - "KV Store Seeding"
Cohesion: 0.41
Nodes (17): clear_existing_data(), kv_delete(), kv_put(), load_kv_ids(), log(), main(), print_error(), print_header() (+9 more)

### Community 26 - "Commit Heatmap Generation"
Cohesion: 0.21
Nodes (15): calculate_streak(), count_commits_by_date(), generate_heatmap_grid(), generate_html(), generate_legend_html(), get_date_only(), get_date_range(), main() (+7 more)

### Community 27 - "NPM Scripts"
Cohesion: 0.12
Nodes (16): scripts, build, build:analyze, dev, lint, preview, test:e2e, test:e2e:chromium (+8 more)

### Community 28 - "Deployment Frequency Analysis"
Cohesion: 0.23
Nodes (13): analyze_deployment_frequency(), categorize_deployment(), format_date(), generate_html(), get_deployment_logs(), main(), parse_date(), datetime (+5 more)

### Community 29 - "Tech Stack Overview"
Cohesion: 0.21
Nodes (12): Cloudflare Workers, Cloudflare KV Store, Gradio, HuggingFace Hub, NSIS, Performance Optimization Guide, Phase 2 Master Plan, Cloudflare Pages (+4 more)

### Community 30 - "Application Build System"
Cohesion: 0.17
Nodes (12): ABADA Music Studio, Cloudflare Pages, Terser, TypeScript Compiler (tsc), Build Verification Checklist, Vite, vite.config.ts, HeartMuLa Model (+4 more)

### Community 31 - "Deployment Runbooks"
Cohesion: 0.20
Nodes (12): build-installers.yml, Cloudflare Pages, Cloudflare Workers, deploy-website.yml, Deployment Process Guide, mula_install.sh, MuLa_Installer.dmg, MuLa_Setup_x64.exe (+4 more)

### Community 32 - "Productivity Time Analysis"
Cohesion: 0.29
Nodes (9): analyze_by_hour(), analyze_by_weekday(), find_most_productive_time(), generate_html(), main(), Analyze commits by hour of day, Analyze commits by day of week, Find most productive time period (+1 more)

### Community 33 - "Project Metadata"
Cohesion: 0.20
Nodes (9): author, description, homepage, keywords, license, name, private, type (+1 more)

### Community 34 - "API Latency Testing"
Cohesion: 0.22
Nodes (4): analyticsLatency, downloadStatsLatency, galleryLatency, options

### Community 35 - "Technical Requirements"
Cohesion: 0.25
Nodes (9): Phase 2 Requirements Specification, Download Stats API Requirement, Cloudflare Pages Deployment Requirement, Windows x64 Installer Requirement, Page Loading Requirement, Phase 3 Testing Implementation Summary, GitHub Actions E2E Workflow, Playwright E2E Test Suite (+1 more)

### Community 36 - "System Integration"
Cohesion: 0.22
Nodes (9): ConversationTTS, HeartCodec, HeartMuLa, run_music_generation.py, ABADA Music Studio, Cloudflare Workers API, heartlib, Installer (+1 more)

### Community 37 - "Commit Size Analysis"
Cohesion: 0.36
Nodes (7): analyze_commit_sizes(), categorize_commit_size(), generate_html(), main(), Categorize commit by size, Analyze commit size distribution, Generate commit size analysis HTML page

### Community 38 - "File History Analysis"
Cohesion: 0.36
Nodes (7): analyze_file_changes(), categorize_files(), generate_html(), main(), Analyze file changes across all commits, Categorize files by type, Generate files history HTML page

### Community 39 - "Analytics API Utility"
Cohesion: 0.33
Nodes (6): Analytics API, analytics utility, collectPerformanceMetrics, conversions, sendRUMData, sendToAnalytics

### Community 40 - "System Architecture Stack"
Cohesion: 0.33
Nodes (6): Desktop Installer Stack, Infrastructure Stack, Cloudflare Workers, HuggingFace, MuLa Application, PyTorch

### Community 41 - "Search & Filter Logic"
Cohesion: 0.33
Nodes (6): applyAdvancedFilters, filterByBookmarks, resetAdvancedFilters, toggleAdvancedSearch, toggleBookmark, updateEmptyColumns

### Community 42 - "Security Auditing"
Cohesion: 0.40
Nodes (5): Production Health Check, Code Security Scan, Create Security Summary, Dependency Audit, Security Headers Check

### Community 44 - "Project Management Tracking"
Cohesion: 0.50
Nodes (5): Kanban Board, Optimization, Performance Analysis, Security Review, Development Statistics

### Community 45 - "Cloudflare Deployment Guide"
Cohesion: 0.50
Nodes (5): Cloudflare KV Store, Cloudflare Pages, Cloudflare Workers, Production Deployment Guide, Wrangler CLI

### Community 46 - "E2E Test Suite"
Cohesion: 0.40
Nodes (5): GitHub Actions, k6, Playwright, test-all.sh, ABADA Music Studio Test Suite

### Community 47 - "Frontend Dependencies"
Cohesion: 0.40
Nodes (5): dependencies, react, react-dom, react-router-dom, web-vitals

### Community 48 - "KV Backup Utility"
Cohesion: 0.67
Nodes (4): KV Store backup script, abada-music-api, GALLERY KV Namespace, STATS KV Namespace

### Community 49 - "Frontend API Modules"
Cohesion: 0.50
Nodes (4): analytics.js, download-stats.js, gallery.js, index.js

### Community 50 - "Production Checklist"
Cohesion: 0.50
Nodes (4): Production Checklist, DNS Configuration, Cloudflare KV Namespaces, SSL/TLS Certificates

### Community 51 - "General Stats Generation"
Cohesion: 0.67
Nodes (3): generate_stats_html(), main(), Generate statistics HTML page

### Community 52 - "Version Dependencies"
Cohesion: 0.67
Nodes (3): Playwright 1.57.0, React 19.2.0, Version 1.0.0

### Community 53 - "Installer Development"
Cohesion: 0.67
Nodes (3): MuLa Installer Development Plan, heartlib, MuLa Installer

### Community 55 - "Performance Testing Guide"
Cohesion: 0.67
Nodes (3): Performance Test Guide, k6, PageSpeed Insights API

### Community 56 - "Release Documentation"
Cohesion: 0.67
Nodes (3): Quick Start Guide, Release Package Summary, Official Release v1.0.0

### Community 57 - "Testing Report Tools"
Cohesion: 0.67
Nodes (3): api-test.js, load-test.js, report-generator.js

### Community 58 - "Core Page Components"
Cohesion: 0.67
Nodes (3): App.tsx, DownloadPage, HomePage

### Community 59 - "App Entry & Performance"
Cohesion: 0.67
Nodes (3): main.tsx, performance.ts, serviceWorker.ts

### Community 60 - "Repository Metadata"
Cohesion: 0.67
Nodes (3): repository, type, url

## Knowledge Gaps
- **275 isolated node(s):** `corsHeaders`, `VALID_EVENT_TYPES`, `corsHeaders`, `VALID_OS`, `DOWNLOAD_URLS` (+270 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **35 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `fetch()` connect `Analytics & Stats Logic` to `Frontend Page Routing`?**
  _High betweenness centrality (0.006) - this node is a cross-community bridge._
- **Why does `analyticsReporter()` connect `Frontend Page Routing` to `Analytics & Stats Logic`?**
  _High betweenness centrality (0.003) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `fetch()` (e.g. with `cacheFirst()` and `networkFirst()`) actually correct?**
  _`fetch()` has 5 INFERRED edges - model-reasoned connections that need verification._
- **What connects `corsHeaders`, `VALID_EVENT_TYPES`, `corsHeaders` to the rest of the system?**
  _307 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `HeartCodec Implementation` be split into smaller, more focused modules?**
  _Cohesion score 0.06219426974143955 - nodes in this community are weakly interconnected._
- **Should `Flow Matching & ODE` be split into smaller, more focused modules?**
  _Cohesion score 0.07729468599033816 - nodes in this community are weakly interconnected._
- **Should `UI Layout Components` be split into smaller, more focused modules?**
  _Cohesion score 0.05689900426742532 - nodes in this community are weakly interconnected._