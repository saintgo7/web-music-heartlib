# Contributing to ABADA Music Studio

Thank you for your interest in contributing to ABADA Music Studio! This document provides guidelines and instructions for contributing to the project.

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Development Setup](#development-setup)
3. [Branch Naming Conventions](#branch-naming-conventions)
4. [Commit Message Format](#commit-message-format)
5. [Pull Request Process](#pull-request-process)
6. [Testing Requirements](#testing-requirements)
7. [Code Review Process](#code-review-process)
8. [Release Process](#release-process)
9. [Licensing Agreement](#licensing-agreement)

---

## Getting Started

### Ways to Contribute

You can contribute in many ways:

**Non-Code Contributions**:
- Report bugs
- Suggest features
- Improve documentation
- Answer questions in Discussions
- Share your music in the gallery
- Write tutorials or blog posts
- Translate documentation

**Code Contributions**:
- Fix bugs
- Implement features
- Improve performance
- Write tests
- Refactor code
- Update dependencies

### Finding Tasks

**Good First Issues**:
Look for issues labeled `good first issue` - these are beginner-friendly tasks.

**Help Wanted**:
Issues labeled `help wanted` are ready for community contribution.

**Feature Requests**:
Check the roadmap in `docs/ROADMAP.md` for planned features.

### Before You Start

1. **Check existing issues** - Someone might already be working on it
2. **Discuss major changes** - Open an issue first for large features
3. **Read the docs** - Familiarize yourself with the codebase
4. **Join Discord** - Ask questions in #dev channel

---

## Development Setup

### Prerequisites

**Required**:
- Git
- Node.js 18+ (for web development)
- Python 3.10+ (for AI components)
- Code editor (VS Code recommended)

**Optional**:
- Docker (for testing installers)
- NSIS (for Windows installer development)
- create-dmg (for macOS installer)

### Local Setup

1. **Fork the Repository**
   ```bash
   # Click "Fork" button on GitHub
   ```

2. **Clone Your Fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/web-music-heartlib.git
   cd web-music-heartlib
   ```

3. **Add Upstream Remote**
   ```bash
   git remote add upstream https://github.com/saintgo7/web-music-heartlib.git
   ```

4. **Install Dependencies**

   **For Web Development**:
   ```bash
   cd web
   npm install
   ```

   **For Python Development**:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -e .
   ```

5. **Verify Setup**
   ```bash
   # Web
   cd web
   npm run dev

   # Python
   python -m pytest
   ```

### Development Environment

**Recommended VS Code Extensions**:
- ESLint
- Prettier
- Python
- Tailwind CSS IntelliSense
- GitLens
- Error Lens

**VS Code Settings** (`.vscode/settings.json`):
```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "typescript.preferences.importModuleSpecifier": "relative",
  "python.linting.enabled": true,
  "python.linting.pylintEnabled": true
}
```

---

## Branch Naming Conventions

### Format

```
<type>/<description>
```

### Types

- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `refactor/` - Code refactoring
- `test/` - Adding or updating tests
- `chore/` - Maintenance tasks
- `perf/` - Performance improvements

### Examples

```bash
feature/dark-mode
fix/windows-installer-gpu-detection
docs/installation-guide-update
refactor/gallery-component-cleanup
test/add-e2e-download-tests
chore/update-dependencies
perf/optimize-model-loading
```

### Best Practices

- Use lowercase with hyphens
- Be descriptive but concise
- Reference issue number if applicable: `fix/123-windows-installer`
- Keep branch names under 50 characters

---

## Commit Message Format

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation changes
- `style` - Code style changes (formatting, no logic change)
- `refactor` - Code refactoring
- `perf` - Performance improvements
- `test` - Adding or updating tests
- `build` - Build system changes
- `ci` - CI/CD changes
- `chore` - Maintenance tasks
- `revert` - Revert previous commit

### Scope

Optional, indicates affected component:
- `web` - Web application
- `installer` - Installer scripts
- `ci` - CI/CD pipelines
- `docs` - Documentation
- `deps` - Dependencies

### Subject

- Use imperative mood ("add" not "added" or "adds")
- Don't capitalize first letter
- No period at the end
- Maximum 50 characters

### Body

- Optional, provide context
- Explain what and why, not how
- Wrap at 72 characters
- Separate from subject with blank line

### Footer

- Reference issues: `Closes #123` or `Fixes #456`
- Note breaking changes: `BREAKING CHANGE: description`

### Examples

**Simple commit**:
```
feat(web): add dark mode toggle to settings page
```

**With body**:
```
fix(installer): correct GPU detection on Windows 11

The nvidia-smi command output format changed in Windows 11.
Updated parsing logic to handle both old and new formats.

Fixes #234
```

**Breaking change**:
```
refactor(api): change gallery endpoint response format

Gallery API now returns structured metadata instead of flat objects.
This provides better extensibility for future features.

BREAKING CHANGE: Gallery API response format changed. Clients
must update to handle new nested structure.

Closes #345
```

**Multiple issues**:
```
feat(web): add music sharing to social media

Users can now share their generated music directly to:
- Twitter/X
- Facebook
- LinkedIn

Closes #123, #124, #125
```

---

## Pull Request Process

### Before Submitting

**Checklist**:
- [ ] Code follows project style guidelines
- [ ] All tests pass (`npm test`, `pytest`)
- [ ] New tests added for new features
- [ ] Documentation updated if needed
- [ ] Commits follow conventional format
- [ ] Branch is up to date with main
- [ ] No merge conflicts
- [ ] Lint checks pass (`npm run lint`)

### Creating a Pull Request

1. **Push to Your Fork**
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Open Pull Request on GitHub**
   - Go to original repository
   - Click "New Pull Request"
   - Select your fork and branch
   - Fill out the template

3. **PR Title Format**
   ```
   [Type] Brief description of changes
   ```

   Examples:
   - `[Feature] Add dark mode to web interface`
   - `[Fix] Resolve Windows installer GPU detection`
   - `[Docs] Update installation guide for macOS`

4. **PR Description Template**
   ```markdown
   ## Description
   Brief description of changes

   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Breaking change
   - [ ] Documentation update

   ## Testing
   Describe how you tested the changes

   ## Screenshots (if applicable)
   Add screenshots for UI changes

   ## Checklist
   - [ ] Tests pass locally
   - [ ] Documentation updated
   - [ ] Commit messages follow conventions
   - [ ] No new warnings or errors

   ## Related Issues
   Closes #123
   ```

### Pull Request Labels

Maintainers will add labels:
- `bug` - Bug fix
- `enhancement` - New feature
- `documentation` - Documentation changes
- `good first issue` - Good for newcomers
- `help wanted` - Looking for contributors
- `priority:high` - High priority
- `priority:low` - Low priority
- `wip` - Work in progress
- `needs-review` - Ready for review
- `needs-testing` - Needs testing
- `approved` - Approved for merge

---

## Testing Requirements

### Test Coverage Goals

- **Minimum**: 70% overall coverage
- **Target**: 80% overall coverage
- **Critical paths**: 100% coverage

### Running Tests

**Web Tests**:
```bash
cd web

# Unit tests
npm test

# E2E tests
npm run test:e2e

# Coverage report
npm run test:coverage
```

**Python Tests**:
```bash
# All tests
pytest

# With coverage
pytest --cov=heartlib --cov-report=html

# Specific test file
pytest tests/test_model.py
```

### Writing Tests

**Unit Test Example (TypeScript)**:
```typescript
// web/src/components/__tests__/Button.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { Button } from '../Button';

describe('Button', () => {
  it('renders with correct text', () => {
    render(<Button>Click Me</Button>);
    expect(screen.getByText('Click Me')).toBeInTheDocument();
  });

  it('calls onClick when clicked', () => {
    const handleClick = vi.fn();
    render(<Button onClick={handleClick}>Click</Button>);

    fireEvent.click(screen.getByText('Click'));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });
});
```

**Integration Test Example (Python)**:
```python
# tests/test_generation.py
import pytest
from heartlib import MusicGenerator

def test_generate_music():
    """Test basic music generation"""
    generator = MusicGenerator(model_path="./test_models")

    result = generator.generate(
        lyrics="[Verse] Test lyrics",
        tags="piano,calm"
    )

    assert result.success
    assert result.audio_data is not None
    assert len(result.audio_data) > 0
```

**E2E Test Example (Playwright)**:
```typescript
// web/tests/e2e/download.spec.ts
import { test, expect } from '@playwright/test';

test('download page shows correct platform', async ({ page }) => {
  await page.goto('/download');

  // Check Windows download button appears
  const windowsBtn = page.getByText('Download for Windows');
  await expect(windowsBtn).toBeVisible();

  // Click and verify redirect
  await windowsBtn.click();
  expect(page.url()).toContain('github.com/releases');
});
```

### Test Organization

```
tests/
├── unit/              # Unit tests
│   ├── components/   # React component tests
│   ├── utils/        # Utility function tests
│   └── api/          # API tests
├── integration/       # Integration tests
│   ├── installer/    # Installer tests
│   └── generation/   # Music generation tests
└── e2e/              # End-to-end tests
    ├── home.spec.ts
    ├── download.spec.ts
    └── gallery.spec.ts
```

---

## Code Review Process

### Review Timeline

- **Initial Response**: Within 2 business days
- **Full Review**: Within 1 week
- **Follow-up**: Within 2 business days after changes

### Review Criteria

Reviewers check for:

**Code Quality**:
- Follows style guidelines
- Well-structured and readable
- Appropriate error handling
- No code duplication
- Efficient algorithms

**Testing**:
- Adequate test coverage
- Tests actually test the feature
- Edge cases covered
- Tests are maintainable

**Documentation**:
- Code comments where needed
- API documentation updated
- User-facing docs updated
- Changelog entry added

**Security**:
- No sensitive data exposed
- Input validation present
- Dependencies are safe
- No known vulnerabilities

### Addressing Feedback

1. **Read Carefully**: Understand all comments
2. **Ask Questions**: If unclear, ask for clarification
3. **Make Changes**: Commit fixes to same branch
4. **Respond**: Reply to comments when done
5. **Request Re-review**: Click "Re-request review"

### Approval Process

- **1 approval required** for minor changes
- **2 approvals required** for major changes
- **All reviewers must approve** for breaking changes
- **Maintainer approval** required for merge

---

## Release Process

### Version Numbering

We use [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH

1.2.3
│ │ │
│ │ └─ Patch: Bug fixes
│ └─── Minor: New features (backward compatible)
└───── Major: Breaking changes
```

### Release Types

**Patch Release** (1.0.x):
- Bug fixes only
- No new features
- Backward compatible
- Released as needed

**Minor Release** (1.x.0):
- New features
- Improvements
- Backward compatible
- Released monthly

**Major Release** (x.0.0):
- Breaking changes
- Major features
- API changes
- Released quarterly

### Release Checklist

**Pre-Release**:
- [ ] All tests pass
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version numbers bumped
- [ ] Release notes drafted
- [ ] Installers built and tested

**Release**:
- [ ] Create Git tag
- [ ] Build release artifacts
- [ ] Upload to GitHub Releases
- [ ] Deploy website updates
- [ ] Publish announcements
- [ ] Update roadmap

**Post-Release**:
- [ ] Monitor for critical bugs
- [ ] Respond to user feedback
- [ ] Plan next release
- [ ] Thank contributors

### Creating a Release

**For Maintainers**:

1. **Update Version**
   ```bash
   # Update package.json, version files
   npm version minor  # or major, patch
   ```

2. **Update CHANGELOG**
   ```markdown
   ## [1.1.0] - 2026-04-01

   ### Added
   - Dark mode support
   - Multi-language UI

   ### Fixed
   - Windows GPU detection
   - macOS installer permissions

   ### Changed
   - Improved model loading speed
   ```

3. **Create Tag**
   ```bash
   git tag -a v1.1.0 -m "Release v1.1.0"
   git push origin v1.1.0
   ```

4. **GitHub Actions** automatically:
   - Builds installers
   - Creates GitHub Release
   - Deploys website
   - Sends notifications

---

## Licensing Agreement

### Contributor License

By contributing to ABADA Music Studio, you agree that:

1. **You own the rights** to your contribution or have permission to contribute it

2. **You grant ABADA Inc.** an irrevocable, worldwide, royalty-free license to use, modify, and distribute your contribution

3. **Your contribution is licensed** under the MIT License, same as the project

4. **You understand** the project uses the HeartMuLa model under CC BY-NC 4.0

### MIT License Summary

**You CAN**:
- Use commercially
- Modify
- Distribute
- Use privately

**You MUST**:
- Include copyright notice
- Include license text

**You CANNOT**:
- Hold liable

### Third-Party Code

When including third-party code:

1. **Check License Compatibility**: Must be compatible with MIT
2. **Add Attribution**: Credit original author
3. **Include License**: Add their license file
4. **Document in NOTICES**: List all third-party code

**Compatible Licenses**:
- MIT
- Apache 2.0
- BSD 2-Clause, 3-Clause
- ISC

**Incompatible Licenses**:
- GPL (copyleft)
- Proprietary
- Creative Commons ShareAlike (SA)

---

## Style Guidelines

### TypeScript/JavaScript

**Formatting**: We use Prettier (auto-format on save)

```typescript
// Good
export function generateMusic(lyrics: string, tags: string[]): Promise<Audio> {
  if (!lyrics) {
    throw new Error('Lyrics required');
  }

  return api.generate({ lyrics, tags });
}

// Bad
export function generateMusic(lyrics,tags){
if(!lyrics) throw new Error('Lyrics required')
return api.generate({lyrics,tags})}
```

**Naming Conventions**:
- `camelCase` for variables and functions
- `PascalCase` for components and classes
- `UPPER_CASE` for constants
- Prefix interfaces with `I` (optional)

**Best Practices**:
- Prefer `const` over `let`
- Use async/await over promises
- Destructure props in components
- Use TypeScript types everywhere
- Avoid `any` type

### Python

**Formatting**: We use Black (auto-format)

```python
# Good
def generate_music(lyrics: str, tags: list[str]) -> bytes:
    """Generate music from lyrics and tags.

    Args:
        lyrics: Song lyrics with structure markers
        tags: Style tags (e.g., ['piano', 'calm'])

    Returns:
        Audio data as bytes
    """
    if not lyrics:
        raise ValueError("Lyrics required")

    return model.generate(lyrics=lyrics, tags=tags)

# Bad
def generateMusic(lyrics,tags):
    if not lyrics: raise ValueError("Lyrics required")
    return model.generate(lyrics=lyrics,tags=tags)
```

**Naming Conventions**:
- `snake_case` for functions and variables
- `PascalCase` for classes
- `UPPER_CASE` for constants
- Private methods prefix with `_`

**Best Practices**:
- Type hints everywhere
- Docstrings for all public functions
- Use f-strings for formatting
- Follow PEP 8
- Maximum line length: 88 (Black default)

---

## Getting Help

### Documentation

- **README.md**: Project overview
- **docs/**: Detailed documentation
- **Wiki**: Guides and tutorials
- **FAQ**: Common questions

### Communication Channels

- **GitHub Discussions**: Questions and discussions
- **Discord #dev**: Real-time development chat
- **GitHub Issues**: Bug reports and features
- **Email**: dev@abada.kr for private inquiries

### Asking Questions

**Good Question**:
```
Title: How to test installer on different Windows versions?

Body:
I'm working on fix/installer-windows-detection (PR #123).

I need to test the GPU detection on Windows 10 and 11,
but I only have Windows 11. What's the recommended way
to test other versions?

I checked docs/TESTING.md but didn't find info on
Windows version testing.

Thanks!
```

**Tips**:
- Search first
- Be specific
- Provide context
- Show what you tried
- Be patient and polite

---

## Recognition

### Contributors List

All contributors are added to:
- CONTRIBUTORS.md
- Release notes
- About page on website
- Annual thank-you post

### Significant Contributions

Special recognition for:
- First-time contributors
- Major features
- Critical bug fixes
- Documentation improvements
- Community support

### Swag Program

Active contributors may receive:
- ABADA Music Studio stickers
- T-shirts
- Special Discord role
- Early access to features

---

## Thank You

Thank you for contributing to ABADA Music Studio! Your time and effort help make AI music accessible to everyone.

Every contribution matters - whether it's a single line of code, a bug report, or helping someone in Discord.

**Together, we're building something amazing.**

---

## Questions?

- **General**: contact@abada.kr
- **Technical**: dev@abada.kr
- **Discord**: #dev channel

**Happy Contributing!**

---

**Document Version**: 1.0.0
**Last Updated**: February 28, 2026
**Maintainers**: ABADA Development Team
