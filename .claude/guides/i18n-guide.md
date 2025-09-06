# Internationalization (i18n) Guide

## Critical Requirement

**CRITICAL**: All user-facing strings in views MUST be internationalized using the `t()` helper.

### ❌ Never Do This
```ruby
# BAD - Hard-coded English text
h1 { "Welcome to our application" }
p { "Please enter your email address" }
button { "Submit Form" }
```

### ✅ Always Do This
```ruby
# GOOD - Internationalized text
h1 { t("views.welcome.title") }
p { t("forms.email.instruction") }
button { t("common.buttons.submit") }
```

## Current i18n Setup

- **Supported locales**: English (en), Spanish (es), Danish (da)
- **Default locale**: English
- **Locale files**: Located in `config/locales/`
- **LocaleService**: Provides helper methods for language management
- **Rails I18n gem**: Included for additional locale support

## LocaleService

The `LocaleService` class provides utilities for working with available locales:

```ruby
# Get all available locales
LocaleService.available_locales
# => [:en, :es, :da]

# Get formatted language options for dropdowns
LocaleService.language_options
# => [["English", "en"], ["Español (Spanish)", "es"], ["Dansk (Danish)", "da"]]

# Get locale name in native language
LocaleService.locale_name(:es, native: true)
# => "Español"

# Get locale name translated to current locale
LocaleService.locale_name(:es, native: false)
# => "Spanish"
```

## I18n Best Practices

### 1. Use Descriptive Key Names
```ruby
# ❌ BAD - Generic keys
t("title")
t("button")

# ✅ GOOD - Specific, hierarchical keys
t("views.pages_home.title")
t("common.buttons.save_changes")
```

### 2. Group Related Strings Logically
```yaml
# config/locales/en.yml
en:
  views:
    pages_home:
      title: "Welcome to Catalyst"
      subtitle: "Rails 8 application template"
    profile:
      edit:
        title: "Edit Profile"
  common:
    buttons:
      save: "Save"
      cancel: "Cancel"
  flash:
    success: "Changes saved successfully"
    error: "Something went wrong"
```

### 3. Use Interpolation for Dynamic Content
```ruby
# ✅ GOOD - Use interpolation
t("navigation.greeting", name: current_user.name)
t("flash.items_updated", count: items.count)
```

```yaml
# config/locales/en.yml
en:
  navigation:
    greeting: "Hello, %{name}"
  flash:
    items_updated:
      one: "%{count} item updated"
      other: "%{count} items updated"
```

### 4. Handle Pluralization
```ruby
# Use Rails' built-in pluralization
t("comments.count", count: @comments.count)
```

```yaml
en:
  comments:
    count:
      zero: "No comments"
      one: "1 comment" 
      other: "%{count} comments"
```

### 5. Test All Supported Locales
```ruby
# In tests, verify all locales work
%i[en es da].each do |locale|
  I18n.with_locale(locale) do
    # Test your views/components
  end
end
```

## Common Patterns

### Navigation and UI Elements
```ruby
# Navigation
link_to t("navigation.profile"), profile_path
link_to t("navigation.logout"), logout_path

# Buttons
render RubyUI::Button::Button.new do
  t("common.buttons.save_changes")
end

# Form labels
label { t("common.labels.email") }
```

### Flash Messages
```ruby
# In controllers
flash[:success] = t("flash.profile.updated")
flash[:error] = t("flash.auth.login_failed")

# In views
flash.each do |type, message|
  div(class: "alert alert-#{type}") { message }
end
```

### Page Titles and Headers
```ruby
# In views
h1 { t("views.#{controller_name}.#{action_name}.title") }
h2 { t("views.profile.sections.personal_info") }
```

## Adding New Locales

1. Create new locale file in `config/locales/`
2. Update `config/application.rb`:
```ruby
config.i18n.available_locales = [:en, :es, :da, :fr] # Add :fr
```
3. Add translations to `LocaleService` expectations in locale files
4. Test thoroughly with new locale

## Development Workflow

1. **Write views with t() helpers first** - never hard-code strings
2. **Add translation keys to locale files** - start with English
3. **Use I18n.t with `raise: true`** during development to catch missing keys
4. **Test with different locales** before considering a feature complete
5. **Use translation management tools** for larger projects

## Debugging Missing Translations

```ruby
# In development, add to application.rb to raise on missing translations
config.i18n.raise_on_missing_translations = true

# Or check for missing translations in tests
I18n.exception_handler = proc do |exception, locale, key, options|
  raise exception.to_exception
end
```