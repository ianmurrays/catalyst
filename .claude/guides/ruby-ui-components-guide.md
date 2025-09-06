# Ruby UI Components Guide

## Overview

Catalyst includes Ruby UI - a comprehensive component library built with Phlex and styled with Tailwind CSS. These components provide a consistent, accessible foundation for building user interfaces.

## Installation & Setup

```bash
bin/rails g ruby_ui:install        # Install Ruby UI system
bin/rails g ruby_ui:component:all  # Generate all available components
bin/rails g ruby_ui:component ComponentName  # Generate specific component
```

## Architecture

### Base Classes
- `Components::RubyUI::Base` - Base class for all Ruby UI components
- `Components::Base` - Base class for custom application components  
- `Views::Base` - Base class for application views

### Directory Structure
```
app/
├── components/
│   ├── ruby_ui/           # Generated Ruby UI components
│   │   ├── accordion/
│   │   ├── button/
│   │   └── ...
│   └── layout/            # Custom application components
└── views/                 # Application views
```

## Available Components

### Layout & Navigation
- **Accordion** - Collapsible content sections
- **Breadcrumb** - Navigation breadcrumbs
- **Separator** - Visual dividers
- **Sheet** - Slide-out panels
- **Tabs** - Tabbed content areas

### Content Display
- **Alert** - Status messages and notifications
- **Avatar** - User profile images
- **Badge** - Status indicators and labels
- **Card** - Content containers
- **Typography** - Text styling components

### Form Elements
- **Button** - Action buttons with variants
- **Checkbox** - Boolean input controls
- **Form** - Form wrapper with validation
- **Input** - Text input fields
- **Masked Input** - Formatted input fields
- **Radio Button** - Single selection controls
- **Select** - Dropdown selection
- **Switch** - Toggle controls
- **Textarea** - Multi-line text input

### Interactive Elements
- **Dialog** - Modal dialogs
- **Alert Dialog** - Confirmation dialogs
- **Dropdown Menu** - Context menus
- **Context Menu** - Right-click menus
- **Hover Card** - Hover-triggered content
- **Popover** - Positioned floating content
- **Tooltip** - Contextual help text

### Data Display
- **Table** - Data tables with sorting
- **Calendar** - Date selection
- **Chart** - Data visualization
- **Progress** - Progress indicators
- **Skeleton** - Loading placeholders

### Navigation
- **Combobox** - Searchable select
- **Command** - Command palette
- **Pagination** - Page navigation

### Utilities
- **Aspect Ratio** - Maintain element proportions
- **Clipboard** - Copy to clipboard functionality
- **Codeblock** - Syntax-highlighted code
- **Collapsible** - Show/hide content
- **Link** - Styled links
- **Shortcut Key** - Keyboard shortcut display
- **Theme Toggle** - Light/dark mode switcher

## Usage Patterns

### Basic Component Usage
```ruby
# Simple button
render RubyUI::Button::Button.new do
  t("common.buttons.save")
end

# Button with variant
render RubyUI::Button::Button.new(variant: :primary, size: :lg) do
  t("common.buttons.submit")
end
```

### Card Components
```ruby
render RubyUI::Card::Card.new do
  render RubyUI::Card::CardHeader.new do
    render RubyUI::Card::CardTitle.new do
      t("profile.title")
    end
    render RubyUI::Card::CardDescription.new do
      t("profile.description") 
    end
  end
  
  render RubyUI::Card::CardContent.new do
    # Card content here
  end
  
  render RubyUI::Card::CardFooter.new do
    render RubyUI::Button::Button.new do
      t("common.buttons.edit")
    end
  end
end
```

### Form Components
```ruby
render RubyUI::Form::Form.new do
  div(class: "space-y-4") do
    # Input field
    render RubyUI::Form::FormField.new do
      render RubyUI::Form::FormLabel.new do
        t("common.labels.email")
      end
      render RubyUI::Input::Input.new(
        type: "email",
        placeholder: t("forms.email.placeholder")
      )
    end
    
    # Submit button
    render RubyUI::Button::Button.new(type: "submit") do
      t("common.buttons.submit")
    end
  end
end
```

### Dialog Components
```ruby
render RubyUI::Dialog::Dialog.new do
  render RubyUI::Dialog::DialogTrigger.new do
    render RubyUI::Button::Button.new do
      t("actions.delete")
    end
  end
  
  render RubyUI::Dialog::DialogContent.new do
    render RubyUI::Dialog::DialogHeader.new do
      render RubyUI::Dialog::DialogTitle.new do
        t("dialogs.confirm_delete.title")
      end
      render RubyUI::Dialog::DialogDescription.new do
        t("dialogs.confirm_delete.message")
      end
    end
    
    render RubyUI::Dialog::DialogFooter.new do
      render RubyUI::Button::Button.new(variant: :outline) do
        t("common.buttons.cancel")
      end
      render RubyUI::Button::Button.new(variant: :destructive) do
        t("common.buttons.delete")
      end
    end
  end
end
```

## Customization

### Theming
Components use CSS custom properties for theming:

```css
/* In your CSS */
:root {
  --primary: 222.2 84% 4.9%;
  --primary-foreground: 210 40% 98%;
  --secondary: 210 40% 96%;
  --secondary-foreground: 222.2 84% 4.9%;
}
```

### Component Variants
Most components support multiple variants:

```ruby
# Button variants
render RubyUI::Button::Button.new(variant: :default)    # Default style
render RubyUI::Button::Button.new(variant: :primary)    # Primary action
render RubyUI::Button::Button.new(variant: :secondary)  # Secondary action
render RubyUI::Button::Button.new(variant: :outline)    # Outlined button
render RubyUI::Button::Button.new(variant: :ghost)      # Minimal button
render RubyUI::Button::Button.new(variant: :destructive) # Danger action

# Sizes
render RubyUI::Button::Button.new(size: :sm)    # Small
render RubyUI::Button::Button.new(size: :md)    # Medium (default)
render RubyUI::Button::Button.new(size: :lg)    # Large
```

### Custom Styling
```ruby
# Add custom classes
render RubyUI::Button::Button.new(class: "my-custom-class") do
  t("custom.button")
end

# Use Tailwind utilities
render RubyUI::Card::Card.new(class: "hover:shadow-lg transition-shadow") do
  # Card content
end
```

## Component Generation

### Generate Single Component
```bash
# Generate just the Button component
bin/rails g ruby_ui:component Button

# Generate Form-related components
bin/rails g ruby_ui:component Form Input Textarea
```

### Regenerate Components
```bash
# Update existing components to latest version
bin/rails g ruby_ui:component:all --force
```

### Component Structure
Generated components follow this structure:
```
app/components/ruby_ui/button/
├── button.rb              # Main component class
├── button_controller.js   # Stimulus controller (if needed)
└── button.css            # Component-specific styles (if needed)
```

## Best Practices

### 1. Always Use i18n
```ruby
# ❌ Bad
render RubyUI::Button::Button.new do
  "Save Changes"
end

# ✅ Good  
render RubyUI::Button::Button.new do
  t("common.buttons.save_changes")
end
```

### 2. Use Semantic Variants
```ruby
# ✅ Good - Clear intent
render RubyUI::Button::Button.new(variant: :destructive) do
  t("actions.delete_account")
end

render RubyUI::Alert::Alert.new(variant: :success) do
  t("flash.profile_updated")
end
```

### 3. Consistent Spacing
```ruby
# Use consistent spacing classes
div(class: "space-y-4") do
  # Multiple components with consistent spacing
end

div(class: "flex gap-2") do  
  # Buttons in a row
end
```

### 4. Accessibility
Ruby UI components come with accessibility features built-in:
- Proper ARIA labels
- Keyboard navigation
- Screen reader support
- Focus management

```ruby
# Components handle accessibility automatically
render RubyUI::Dialog::Dialog.new do
  # Proper focus trap and ARIA attributes handled
end
```

### 5. Responsive Design
```ruby
# Use Tailwind responsive classes
render RubyUI::Card::Card.new(class: "w-full md:w-1/2 lg:w-1/3") do
  # Responsive card
end
```

## Testing Components

### Component Specs
```ruby
# spec/components/ruby_ui/button/button_spec.rb
RSpec.describe RubyUI::Button::Button do
  it "renders with default variant" do
    component = described_class.new { "Click me" }
    
    expect(render_with_view_context(component)).to have_selector(
      "button",
      text: "Click me"
    )
  end
  
  it "applies variant classes" do
    component = described_class.new(variant: :primary) { "Primary" }
    
    expect(render_with_view_context(component)).to have_selector(
      "button.bg-primary"
    )
  end
end
```

### Integration Testing
```ruby
# In feature specs
feature "User profile" do
  scenario "updating profile information" do
    visit edit_profile_path
    
    # Test Ruby UI components in context
    expect(page).to have_selector("[data-ruby-ui='button']", text: "Save Changes")
    
    fill_in "Name", with: "New Name"
    click_button "Save Changes"
    
    expect(page).to have_selector("[data-ruby-ui='alert'][data-variant='success']")
  end
end
```

## Troubleshooting

### Common Issues

1. **Component not found**
   - Run `bin/rails g ruby_ui:component ComponentName`
   - Check component is in `app/components/ruby_ui/`

2. **Styling issues**
   - Ensure Tailwind CSS is properly configured
   - Check CSS custom properties are defined
   - Verify component CSS is being loaded

3. **JavaScript not working**
   - Check Stimulus controllers are being loaded
   - Verify importmap includes component JS

### Debug Mode
```ruby
# Add debug information to components
render RubyUI::Button::Button.new(data: { debug: true }) do
  "Debug Button"
end
```