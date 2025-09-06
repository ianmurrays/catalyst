# Spec

Plan and implement a feature using Test-Driven Development (TDD) methodology.

## Usage
Provide a description of the feature you want to implement, and I will:

1. **Gather Context**: Use the context-gatherer agent to understand existing codebase patterns, related components, and testing conventions
2. **Fetch Documentation**: Use the context7-docs-fetcher agent to get up-to-date documentation for Rails 8, RSpec, and any relevant libraries
3. **Create TDD Plan**: Design a comprehensive implementation plan following test-driven development principles

## TDD Workflow
The command follows this structured approach:

### Phase 1: Discovery & Planning
- Analyze existing codebase patterns and conventions
- Identify related components and potential impact areas  
- Research relevant documentation and best practices
- Create detailed feature specification with acceptance criteria

### Phase 2: Test-First Implementation
- **Write failing specs first** following project's RSpec conventions
- Implement the minimum code needed to make specs pass
- **Run specs** to verify they pass (`bundle exec rspec`)
- Refactor while keeping tests green
- **Run Rubocop** to ensure code quality (`bin/rubocop -a`)
- **Verify complete test suite** passes

### Phase 3: Validation
- Ensure all new functionality is properly tested
- Verify integration with existing systems
- Confirm adherence to project conventions from CLAUDE.md
- Run final quality checks (Rubocop, full test suite)

## Example
```
/spec Add user avatar upload feature with image resizing and cloud storage
```

This will create a comprehensive TDD plan for implementing user avatar uploads, including:
- Model specs for user avatar associations
- Controller specs for upload endpoints  
- Integration specs for the complete workflow
- Implementation following Rails 8 and project conventions