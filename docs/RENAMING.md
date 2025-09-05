# Rails Application Renaming Guide

This Rails application includes a powerful renaming script that allows you to easily transform it into a new application with a different name. This is particularly useful when using this app as a template for new projects.

## Quick Start

The easiest way to rename your application is to run the interactive script:

```bash
bin/rename
```

This will:
1. Auto-detect your current application name
2. Prompt you for the new name
3. Show you a preview of what will change
4. Ask for confirmation before making changes
5. Create backups of modified files
6. Apply all necessary changes

## Command Line Usage

### Basic Usage

```bash
# Interactive mode
bin/rename

# Direct mode with new name
bin/rename MyNewApp

# Preview changes without executing (dry run)
bin/rename MyNewApp --dry-run

# Skip confirmation prompts
bin/rename MyNewApp --force

# Specify current name explicitly
bin/rename MyNewApp --from CurrentApp
```

### Options

- `--dry-run`: Preview all changes without modifying any files
- `--backup`: Create backups of all modified files (enabled by default in dry-run)
- `--force`: Skip confirmation prompts and uncommitted changes warning
- `--from NAME`: Explicitly specify the current application name

### Examples

```bash
# See what would change without making modifications
bin/rename "ECommerce Platform" --dry-run

# Rename with automatic backup
bin/rename BlogEngine --backup

# Quick rename without prompts
bin/rename InventorySystem --force
```

## What Gets Renamed

The script intelligently updates your application name in multiple formats across various files:

### Core Rails Files
- `config/application.rb` - Main application module
- `config/deploy.yml` - Deployment configuration
- `Dockerfile` - Docker build commands

### Frontend/UI Files
- `app/views/layouts/application.html.erb` - Page titles
- `app/views/pwa/manifest.json.erb` - PWA name and description
- View files containing the app name

### Optional Files (if present)
- `package.json` - NPM package name
- `config/initializers/session_store.rb` - Session cookie names
- `config/database.yml` - Database names

## Name Format Conversions

The script automatically converts between different naming conventions:

| Format | Example |
|--------|---------|
| CamelCase (Module) | `MyNewApp` |
| snake_case | `my_new_app` |
| kebab-case | `my-new-app` |
| lowercase | `mynewapp` |
| Human readable | `My New App` |

## Validation Rules

Your new application name must:
- Start with a capital letter
- Contain only letters and numbers
- Be a valid Ruby constant name
- Not conflict with Rails reserved words

### Reserved Words
The script prevents you from using these reserved names:
- `Application`, `Configuration`, `Rails`
- `ActiveRecord`, `ActionController`, `ActionView`
- `ActionMailer`, `ActiveJob`, `ActiveStorage`, `ActiveSupport`
- `App`, `Test`, `Development`, `Production`, `Staging`

## Safety Features

### Backup System
- Automatic backups are created before making changes
- Backups are stored in `backups/rename_YYYYMMDD_HHMMSS/`
- Original file structure is preserved in backups

### Git Integration
- Warns if you have uncommitted changes
- Suggests next steps after renaming
- Provides rollback guidance

### Dry Run Mode
- Preview all changes before applying them
- Shows exact replacements that will be made
- Lists all files that will be modified

## After Renaming

Once the rename is complete, you should:

1. **Clear Rails cache**:
   ```bash
   rails tmp:clear
   ```

2. **Verify the application works**:
   ```bash
   bin/rails console
   bin/rails server
   ```

3. **Run your test suite**:
   ```bash
   bundle exec rspec
   # or whatever test command you use
   ```

4. **Update git remote** (if repository name changed):
   ```bash
   git remote set-url origin git@github.com:username/new-repo-name.git
   ```

5. **Commit the changes**:
   ```bash
   git add .
   git commit -m "Rename application to MyNewApp"
   ```

## Troubleshooting

### Rollback Changes
If something goes wrong, you can manually restore from the backup:

```bash
# List available backups
ls backups/

# Restore specific files from backup
cp -r backups/rename_20250905_143022/config/application.rb config/
```

### Common Issues

**"Could not detect current application name"**
- Make sure you're running the script from the Rails root directory
- Check that `config/application.rb` exists and contains a valid module declaration

**"Invalid application name"**
- Ensure your name starts with a capital letter
- Use only letters and numbers
- Avoid Rails reserved words

**"Uncommitted changes detected"**
- Commit your current changes first, or use `--force` to proceed anyway

### Manual Verification
After renaming, check these files manually:
- `config/application.rb` - Module name should be updated
- `bin/rails console` - Should show new application class
- Application title in browser

## Advanced Usage

### Custom Patterns
If you have additional files with custom naming patterns that need renaming, you can:
1. Edit the `bin/rename` script to add new file patterns in the `get_files_to_change` method
2. Add custom replacement rules in the `transform_file_content` method
3. Test with `--dry-run` before applying

### Batch Operations
For multiple similar applications, consider:
1. Creating a shell script that calls `bin/rename` with different names
2. Using the `--force` option to skip interactive prompts
3. Automating git operations for each renamed app

## Contributing

If you find files or patterns that should be included in the rename script:
1. Test your changes with `--dry-run`
2. Update the script's file detection and replacement logic
3. Update this documentation
4. Test thoroughly before committing

## Support

If you encounter issues with the rename script:
1. Check this documentation first
2. Try `bin/rename --dry-run` to debug the issue
3. Look at the backup files to understand what changed
4. Check the git log to see recent changes to the script