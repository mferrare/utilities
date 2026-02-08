#!/bin/bash
# Example utility script
# This is a template for creating utility scripts

# Display usage information
usage() {
    local exit_code=${1:-1}
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -v, --version  Show version information"
    exit $exit_code
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage 0
            ;;
        -v|--version)
            echo "Example Script v1.0.0"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage 1
            ;;
    esac
    shift
done

# Main script logic
echo "Example utility script running..."
echo "This is a template for creating your own utility scripts."

exit 0
