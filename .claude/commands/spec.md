# Spec

Plan and implement a feature using Test-Driven Development (TDD) methodology with requirements clarification.

## Usage
Provide a description of the feature you want to implement, and I will:

1. **Clarify Requirements**: Ask targeted questions to understand the specific requirements, scope, user experience, technical constraints, and success criteria
2. **Gather Context**: Use the context-gatherer agent to understand existing codebase patterns, related components, and testing conventions
3. **Fetch Documentation**: Use the context7-docs-fetcher agent to get up-to-date documentation for Rails 8, RSpec, and any relevant libraries
4. **Create TDD Plan**: Design a comprehensive implementation plan following test-driven development principles

## TDD Workflow
The command follows this structured approach:

### Phase 0: Requirements Clarification
- Ask clarifying questions about feature scope and boundaries
- Understand user personas and use cases
- Identify technical constraints and preferences
- Define success criteria and acceptance tests
- Clarify integration points with existing systems
- Wait for the user to respond to the questions before continuing

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

## Examples

### Basic Usage
```
/spec Add user avatar upload feature with image resizing and cloud storage
```

### What Happens Next
After providing your feature description, I will ask clarifying questions such as:
- What file types should be supported? (JPEG, PNG, GIF, etc.)
- What are the size limits and resize requirements?
- Should we use local storage or cloud storage? (S3, Cloudinary, etc.)
- Who can upload/view avatars? (authentication/authorization requirements)
- Are there any specific UI/UX requirements?
- Do we need image processing capabilities? (cropping, filters, etc.)

Then I'll create a comprehensive TDD plan including:
- Model specs for user avatar associations
- Controller specs for upload endpoints
- Integration specs for the complete workflow
- Implementation following Rails 8 and project conventions
