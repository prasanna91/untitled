#!/bin/bash

# 🚀 QuikApp Project Name Update Script
# Automatically updates APP_NAME in all Codemagic workflows to use project name from pubspec.yaml
# Converts project name to lowercase with no spaces

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to get project name from pubspec.yaml
get_project_name() {
    local project_name
    project_name=$(grep "^name:" pubspec.yaml | sed 's/name:[[:space:]]*//' | tr -d '"')
    
    if [ -z "$project_name" ]; then
        print_error "Could not extract project name from pubspec.yaml"
        exit 1
    fi
    
    echo "$project_name"
}

# Function to convert project name to APP_NAME format (lowercase, no spaces)
convert_to_app_name() {
    local project_name="$1"
    # Convert to lowercase and remove spaces
    echo "$project_name" | tr '[:upper:]' '[:lower:]' | tr -d ' '
}

# Function to backup codemagic.yaml
backup_codemagic() {
    local backup_file="codemagic.yaml.backup.$(date +%Y%m%d_%H%M%S)"
    cp codemagic.yaml "$backup_file"
    print_status "Backup created: $backup_file"
    echo "$backup_file"
}

# Function to update APP_NAME in a specific workflow
update_workflow_app_name() {
    local workflow_name="$1"
    local new_app_name="$2"
    local temp_file="codemagic_temp.yaml"
    
    print_status "Updating workflow: $workflow_name"
    
    # Create a temporary file with the updated content
    awk -v workflow="$workflow_name" -v app_name="$new_app_name" '
    BEGIN { in_workflow = 0; updated = 0 }
    {
        # Check if we are entering the target workflow
        if ($0 ~ "^  " workflow ":") {
            in_workflow = 1
            print $0
            next
        }
        
        # Check if we are leaving the workflow (next workflow or end of workflows)
        if (in_workflow && $0 ~ /^  [a-zA-Z-]+:/) {
            in_workflow = 0
        }
        
        # If we are in the target workflow and find APP_NAME, update it
        if (in_workflow && $0 ~ /APP_NAME:[[:space:]]*\$APP_NAME/) {
            sub(/\$APP_NAME/, app_name)
            updated = 1
            print_status "Updated APP_NAME in $workflow_name workflow"
        }
        
        print $0
    }
    END {
        if (!updated) {
            print_error "APP_NAME not found in $workflow_name workflow"
        }
    }' codemagic.yaml > "$temp_file"
    
    # Replace original file with updated content
    mv "$temp_file" codemagic.yaml
    
    if [ $? -eq 0 ]; then
        print_success "Successfully updated $workflow_name workflow"
    else
        print_error "Failed to update $workflow_name workflow"
        return 1
    fi
}

# Function to update all workflows
update_all_workflows() {
    local new_app_name="$1"
    local workflows=("android-free" "android-paid" "android-publish" "ios-workflow" "combined")
    local success_count=0
    local total_workflows=${#workflows[@]}
    
    print_status "Updating APP_NAME in all $total_workflows workflows..."
    
    for workflow in "${workflows[@]}"; do
        if update_workflow_app_name "$workflow" "$new_app_name"; then
            ((success_count++))
        fi
    done
    
    print_status "Updated $success_count out of $total_workflows workflows"
    
    if [ $success_count -eq $total_workflows ]; then
        print_success "All workflows updated successfully!"
        return 0
    else
        print_warning "Some workflows may not have been updated"
        return 1
    fi
}

# Function to validate the updated codemagic.yaml
validate_codemagic() {
    print_status "Validating updated codemagic.yaml..."
    
    # Check if the file is valid YAML
    if command -v python3 &> /dev/null; then
        if python3 -c "import yaml; yaml.safe_load(open('codemagic.yaml'))" 2>/dev/null; then
            print_success "codemagic.yaml is valid YAML"
        else
            print_error "codemagic.yaml contains invalid YAML syntax"
            return 1
        fi
    else
        print_warning "Python3 not available, skipping YAML validation"
    fi
    
    # Check if all APP_NAME entries were updated
    local app_name_count
    local updated_count
    
    app_name_count=$(grep -c "APP_NAME:" codemagic.yaml || echo "0")
    updated_count=$(grep -c "APP_NAME: $1" codemagic.yaml || echo "0")
    
    print_status "Found $app_name_count APP_NAME entries, $updated_count updated to new value"
    
    if [ "$app_name_count" -eq "$updated_count" ]; then
        print_success "All APP_NAME entries updated successfully"
        return 0
    else
        print_warning "Some APP_NAME entries may not have been updated"
        return 1
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -d, --dry-run       Show what would be changed without making changes"
    echo "  -b, --backup        Create backup before making changes (default)"
    echo "  -n, --no-backup     Don't create backup"
    echo "  -v, --verbose       Verbose output"
    echo ""
    echo "This script automatically updates the APP_NAME variable in all Codemagic workflows"
    echo "to use the project name from pubspec.yaml with lowercase and no spaces."
    echo ""
    echo "Example:"
    echo "  $0                    # Update with backup"
    echo "  $0 --dry-run         # Show changes without applying"
    echo "  $0 --no-backup       # Update without backup"
}

# Main function
main() {
    local dry_run=false
    local create_backup=true
    local verbose=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -d|--dry-run)
                dry_run=true
                shift
                ;;
            -b|--backup)
                create_backup=true
                shift
                ;;
            -n|--no-backup)
                create_backup=false
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Check if we're in the right directory
    if [ ! -f "pubspec.yaml" ]; then
        print_error "pubspec.yaml not found. Please run this script from the project root directory."
        exit 1
    fi
    
    if [ ! -f "codemagic.yaml" ]; then
        print_error "codemagic.yaml not found. Please run this script from the project root directory."
        exit 1
    fi
    
    print_status "🚀 Starting QuikApp Project Name Update..."
    
    # Get project name from pubspec.yaml
    local project_name
    project_name=$(get_project_name)
    print_status "Project name from pubspec.yaml: $project_name"
    
    # Convert to APP_NAME format
    local new_app_name
    new_app_name=$(convert_to_app_name "$project_name")
    print_status "Converting to APP_NAME format: $new_app_name"
    
    if [ "$dry_run" = true ]; then
        print_status "DRY RUN MODE - No changes will be made"
        print_status "Would update APP_NAME to: $new_app_name"
        
        # Show what would be changed
        echo ""
        print_status "Current APP_NAME entries in codemagic.yaml:"
        grep -n "APP_NAME:" codemagic.yaml || print_warning "No APP_NAME entries found"
        
        echo ""
        print_status "Would update these workflows:"
        echo "  - android-free"
        echo "  - android-paid"
        echo "  - android-publish"
        echo "  - ios-workflow"
        echo "  - combined"
        
        exit 0
    fi
    
    # Create backup if requested
    local backup_file=""
    if [ "$create_backup" = true ]; then
        backup_file=$(backup_codemagic)
    fi
    
    # Update all workflows
    if update_all_workflows "$new_app_name"; then
        print_success "All workflows updated successfully!"
    else
        print_warning "Some workflows may not have been updated"
    fi
    
    # Validate the updated file
    if validate_codemagic "$new_app_name"; then
        print_success "Validation passed!"
    else
        print_warning "Validation issues detected"
    fi
    
    # Show summary
    echo ""
    print_success "🎉 Project name update completed!"
    echo "  Project name: $project_name"
    echo "  APP_NAME: $new_app_name"
    if [ -n "$backup_file" ]; then
        echo "  Backup: $backup_file"
    fi
    echo ""
    print_status "You can now commit the updated codemagic.yaml file"
    
    if [ "$verbose" = true ]; then
        echo ""
        print_status "Updated APP_NAME entries:"
        grep -n "APP_NAME: $new_app_name" codemagic.yaml || print_warning "No updated entries found"
    fi
}

# Run main function with all arguments
main "$@"
