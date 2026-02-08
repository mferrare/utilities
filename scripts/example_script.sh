#!/bin/bash
# Example utility script
# This is a template for creating utility scripts

# Display usage information
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -v, --version  Show version information"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -v|--version)
            echo "Example Script v1.0.0"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
    shift
done

# Main script logic
echo "Example utility script running..."
echo "This is a template for creating your own utility scripts."
