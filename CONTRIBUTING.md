# Contributing to Tarkov Unlockables

Thank you for your interest in contributing! This project welcomes contributions from the community.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally
3. **Create a branch** for your changes
4. **Make your changes**
5. **Run the test suite** to ensure nothing breaks
6. **Submit a pull request**

## Development Setup

```bash
# Clone the repo
git clone https://github.com/your-username/tarkov-unlockables.git
cd tarkov-unlockables

# Install dependencies
bundle install

# Set up the database
bin/rails db:prepare

# Run the test suite
bin/rails test
```

## Code Style

This project uses:

- **RuboCop** for Ruby linting (config in `.rubocop.yml`)
- **Brakeman** for security scanning
- **Bundler-audit** for gem vulnerability checks
- **Fasterer** for performance idioms
- **RubyCritic** for code quality (score ≥ 75 required)

Run all checks locally:

```bash
bundle exec rubocop
bundle exec brakeman --no-pager --exit-on-warn
bundle exec bundler-audit
bundle exec fasterer
bundle exec rubycritic --no-browser --format json app/
```

## Testing

```bash
# Run all tests
bin/rails test

# Run with coverage
COVERAGE=true bin/rails test

# Run a specific test
bin/rails test test/path/to/test_file.rb
```

**Coverage requirement**: 99.8% line coverage minimum.

## Pull Request Process

1. **Keep PRs focused** - one feature/fix per PR
2. **Write clear commit messages** - follow [Conventional Commits](https://www.conventionalcommits.org/)
3. **Update tests** - add tests for new features, update existing tests for bug fixes
4. **Update documentation** - README, CHANGELOG, comments as needed
5. **Ensure CI passes** - all checks must pass before merge

## Commit Message Format

```
type(scope): brief description

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`, `ci`

Examples:
```
feat(sync): add market price backfill for food items
docs(readme): add deploy instructions for Render
```

## Code Review

All PRs require at least one review. Reviewers will check:
- Code correctness and style
- Test coverage
- Security implications
- Performance impact
- Documentation updates

## Reporting Issues

- **Bugs**: Use the bug report template
- **Features**: Use the feature request template
- **Security**: See SECURITY.md

## Questions?

Open a discussion or issue for any questions about contributing.