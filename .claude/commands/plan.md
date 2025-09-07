# Plan

Create comprehensive Product Requirements Documents (PRDs) and project plans using the planning-prd-agent.

## Description
This command triggers the planning-prd-agent to create detailed technical specifications, user stories, implementation roadmaps, and task breakdowns for any feature or project.

## Usage
Provide a description of what you want to plan:

```
/plan Add user authentication with OAuth providers
/plan Build a real-time chat system with message history
/plan Create an admin dashboard with user management
```

## What This Command Does

When you use `/plan`, I will automatically invoke the **planning-prd-agent** to:

1. **Analyze Requirements** - Break down your request into clear, actionable specifications
2. **Design Architecture** - Define technical approach, data models, and system boundaries
3. **Create User Stories** - Write detailed stories with acceptance criteria  
4. **Plan Implementation** - Generate task breakdowns with estimates and dependencies
5. **Assess Risks** - Identify potential challenges and mitigation strategies
6. **Generate Task Files** - Create assignment files for delegating work to specialized agents

## Output Format
The planning-prd-agent will generate:
- Executive summary with problem statement and solution approach
- Technical requirements and architecture specifications
- User stories with clear acceptance criteria
- Implementation roadmap with task breakdowns and estimates
- Risk analysis with mitigation strategies
- Task assignment file for team delegation

## Example Output
For `/plan Add user authentication`, you'll receive:
- Authentication flow diagrams and security considerations
- User stories for login, registration, and password reset
- Technical tasks for implementing OAuth, session management, etc.
- Database schema for user accounts and authentication tokens
- Testing strategy and acceptance criteria
- Risk assessment for security vulnerabilities

The planning-prd-agent excels at bridging high-level product vision with detailed technical implementation, making it perfect for comprehensive project planning.