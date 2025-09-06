# Phlex Testing Guide for Rails Applications

This guide documents best practices for testing Phlex components in Rails applications, based on lessons learned while implementing and testing components in this codebase.

## Overview

Phlex components in Rails applications often need access to Rails helpers like `link_to`, route helpers, and other view context methods. The key insight is to leverage Rails' own testing infrastructure rather than manually mocking everything.

## Core Principle: Use Rails View Context

The most important principle when testing Phlex components that use Rails helpers is to render them with a proper Rails view context that provides all the necessary helpers automatically.

### ❌ Wrong Approach: Manual Mocking

```ruby
# DON'T DO THIS - overly complex and fragile
let(:component) do
  comp = MyComponent.new
  allow(comp).to receive(:link_to) do |text, path, options = {}|
    %(<a href="#{path}"#{options[:class] ? %( class="#{options[:class]}") : ""}>#{text}</a>).html_safe
  end
  allow(comp).to receive(:root_path).and_return("/")
  comp
end

let(:html) { component.call }
```

### ✅ Correct Approach: Rails View Context

```ruby
# DO THIS - leverages Rails testing infrastructure
let(:component) do
  comp = MyComponent.new
  # Only mock business logic, not Rails helpers
  allow(comp).to receive(:current_user).and_return(user)
  comp
end

let(:html) { render_with_view_context(component) }
```

## Setting Up Component Helpers

Create a helper module that provides the proper Rails integration:

```ruby
# spec/support/component_helpers.rb
module ComponentHelpers
  # Create a mock view context for Rails integration
  def view_context
    @view_context ||= ActionView::TestCase::TestController.new.view_context
  end

  # Helper for rendering components with Rails integration
  def render_with_view_context(component)
    view_context.render(component)
  end

  # Other helpful methods for parsing HTML
  def render_fragment(component = nil, &block)
    html = if component
      render_with_view_context(component)
    else
      block.call
    end
    Nokogiri::HTML5.fragment(html)
  end
end

RSpec.configure do |config|
  config.include ComponentHelpers
end
```

## Testing Patterns

### Basic Component Structure Testing

```ruby
RSpec.describe Components::MyComponent do
  let(:component) { described_class.new }

  describe "structure" do
    let(:html) { render_with_view_context(component) }
    let(:doc) { Nokogiri::HTML5(html) }

    it "renders expected elements" do
      expect(doc.css('.my-component')).not_to be_empty
    end

    it "includes proper styling" do
      element = doc.css('.my-component').first
      expect(element['class']).to include('expected-class')
    end
  end
end
```

### Testing Components with Rails Helpers

```ruby
RSpec.describe Components::Layout::Navbar do
  let(:component) do
    comp = described_class.new
    # Mock only business logic, not Rails helpers
    allow(comp).to receive(:current_user).and_return(user)
    allow(comp).to receive(:logged_in?).and_return(true)
    mock_translations_for(comp) # Helper for I18n
    comp
  end

  describe "navigation links" do
    let(:html) { render_with_view_context(component) }
    let(:doc) { Nokogiri::HTML5(html) }

    it "renders brand as clickable link" do
      brand_link = doc.css('a').first
      expect(brand_link).not_to be_nil
      expect(brand_link['href']).to eq('/')
      expect(brand_link.text).to eq('MyApp')
    end
  end
end
```

### Testing Full View Integration

For views that use layouts and complex component hierarchies:

```ruby
RSpec.describe Views::MyView do
  let(:view) do
    view = described_class.new
    # Setup any view-specific mocks
    mock_translations_for(view)
    view
  end

  describe "#around_template" do
    let(:html) { render_with_view_context(view) }
    let(:doc) { Nokogiri::HTML5(html) }

    it "renders complete layout with components" do
      expect(html).to start_with("<!doctype html>")
      expect(doc.css('header')).not_to be_empty # navbar
      expect(doc.css('main')).not_to be_empty   # content
    end
  end
end
```

## Common Issues and Solutions

### Issue 1: `undefined method 'default_url_options' for nil`

**Problem**: Component uses Rails routing helpers but doesn't have proper Rails context.

**Solution**: Use `render_with_view_context` instead of `component.call` directly.

```ruby
# ❌ This will fail
let(:html) { component.call }

# ✅ This works
let(:html) { render_with_view_context(component) }
```

### Issue 2: HTML Escaping Issues

**Problem**: Manual mocks return strings that get escaped by Phlex.

**Solution**: Don't manually mock Rails helpers; use the view context instead.

### Issue 3: Over-mocking

**Problem**: Tests become complex with too many manual mocks for Rails functionality.

**Solution**: Mock only your business logic. Let Rails provide its own helpers.

```ruby
# ❌ Don't mock Rails helpers
allow(comp).to receive(:link_to)
allow(comp).to receive(:root_path)
allow(comp).to receive(:form_with)

# ✅ Mock only business logic
allow(comp).to receive(:current_user)
allow(comp).to receive(:logged_in?)
```

## What to Mock vs What Not to Mock

### ✅ DO Mock:
- Business logic methods (`current_user`, `logged_in?`, etc.)
- External service calls
- I18n translations (with helper methods)
- Authentication tokens for testing

### ❌ DON'T Mock:
- Rails helpers (`link_to`, `form_with`, `url_for`)
- Route helpers (`root_path`, `users_path`, etc.)
- Rails view context methods
- HTML generation methods

## Helper Methods for Common Scenarios

### Translation Mocking

```ruby
def mock_translations_for(component)
  allow(component).to receive(:t) do |key, **options|
    case key.to_s
    when "app.name"
      "MyApp"
    when "navigation.home"
      "Home"
    else
      key.to_s
    end
  end
end
```

### Authentication Mocking

```ruby
def mock_auth_helpers(logged_in: false, user: nil)
  allow_any_instance_of(Components::Layout::Navbar).to receive(:logged_in?).and_return(logged_in)
  allow_any_instance_of(Components::Layout::Navbar).to receive(:current_user).and_return(user)
  allow_any_instance_of(Components::Layout::Navbar).to receive(:form_authenticity_token).and_return("test-token")
end
```

## Performance Considerations

- The Rails view context approach is actually more performant than complex manual mocking
- It reduces test complexity and maintenance burden
- It provides better test reliability by using Rails' own infrastructure

## Integration with Different Component Types

### Simple Components (No Rails Dependencies)
Use basic `component.call` - no special setup needed.

### Components with Rails Helpers
Use `render_with_view_context(component)`.

### Layout Components
Use `render_with_view_context(component)` and mock authentication/business logic.

### View Classes
Use `render_with_view_context(view)` for full layout integration testing.

## References

- [Phlex Testing Documentation](https://www.phlex.fun/components/testing.html#working-with-rails)
- Rails ActionView::TestCase documentation
- This codebase's `spec/support/component_helpers.rb` for implementation examples

## Key Takeaways

1. **Simplicity is key** - Don't over-mock Rails functionality
2. **Use Rails testing infrastructure** - ActionView::TestCase provides what you need
3. **Mock business logic, not framework code** - Focus on testing your component logic
4. **Test with realistic context** - Components should work the same way in tests as in production
5. **Keep tests maintainable** - Complex mocking leads to brittle tests

This approach leads to more reliable, maintainable, and simpler tests that actually verify your components work correctly with Rails.