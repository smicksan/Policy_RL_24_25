#!/bin/bash

# PDF to Single-Column Text Extraction Script for macOS
# Author: Sandra Mickwitz | Version: 1.4 | Date: February 2025

# Check if poppler is installed
if ! command -v pdftotext &> /dev/null
then
    echo "Error: poppler is not installed. Please install it using 'brew install poppler'."
    exit 1
fi

# Automatically detect the script's directory (used as input directory)
INPUT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Create a timestamped output directory inside the input folder
DATE_TIME=$(date +%Y%m%dT%H%M%S)
OUTPUT_DIR="${INPUT_DIR}/text_output_${DATE_TIME}"
mkdir -p "$OUTPUT_DIR"

# Get list of PDFs
PDF_FILES=("$INPUT_DIR"/*.pdf)

# Progress tracking variables
TOTAL_PDFS=${#PDF_FILES[@]}
CURRENT_PDF=0

echo "Found $TOTAL_PDFS PDF files in '$INPUT_DIR'. Extracting text..."

# Function to check if PDF has multiple columns (by checking line spacing heuristics)
is_multicolumn() {
    local pdf_file="$1"
    local xml_output="${pdf_file%.pdf}.xml"

    # Convert PDF to structured XML
    pdftohtml -xml -nodrm "$pdf_file" "$xml_output"

    # Count the number of unique text-block positions
    local block_positions=$(grep -oP 'top="\d+"' "$xml_output" | sort | uniq -c | wc -l)

    # Remove temporary XML file
    rm -f "$xml_output"

    # If there are multiple block positions, assume multiple columns
    if [ "$block_positions" -gt 50 ]; then
        return 0  # Multi-column detected
    else
        return 1  # Single-column
    fi
}

# Function to extract text in a single-column format
extract_text() {
    local pdf_file="$1"
    local output_file="$2"

    if is_multicolumn "$pdf_file"; then
        # Use pdftotext with -raw to ensure a single-column text output
        pdftotext -raw "$pdf_file" "$output_file"
    else
        # Default text extraction for single-column PDFs
        pdftotext "$pdf_file" "$output_file"
    fi
}

# Function to clean and merge broken lines in text files
clean_text() {
    local input_file="$1"
    local output_file="$2"

    awk '{
        if (NF == 0) {
            print ""; next;
        }
        if (substr($0, length($0), 1) != "-") {
            printf "%s ", $0;
        } else {
            print "";
        }
    }' "$input_file" > "$output_file"
}

# Function to show progress bar
show_progress() {
    local current=$1
    local total=$2
    local bar_length=40
    local percent=$((100 * current / total))
    local done=$((bar_length * current / total))
    local remaining=$((bar_length - done))
    
    local done_bar=$(printf "%${done}s" | tr " " "#")
    local remaining_bar=$(printf "%${remaining}s" | tr " " "-")

    echo -ne "\rProgress: [${done_bar}${remaining_bar}] $current/$total PDFs ($percent%)"
}

# Loop through PDF files and extract text
for PDF_FILE in "${PDF_FILES[@]}"; do
    ((CURRENT_PDF++))
    
    # Get filename without extension
    BASENAME=$(basename "$PDF_FILE" .pdf)
    OUTPUT_RAW_TEXT_FILE="$OUTPUT_DIR/$BASENAME.raw.txt"
    OUTPUT_CLEAN_TEXT_FILE="$OUTPUT_DIR/$BASENAME.txt"

    # Extract text while ensuring a single-column format
    extract_text "$PDF_FILE" "$OUTPUT_RAW_TEXT_FILE"

    # Clean and merge broken lines for coherence
    clean_text "$OUTPUT_RAW_TEXT_FILE" "$OUTPUT_CLEAN_TEXT_FILE"

    # Remove raw text file after processing
    rm "$OUTPUT_RAW_TEXT_FILE"

    echo "Extracted and cleaned text saved: $OUTPUT_CLEAN_TEXT_FILE"

    # Show progress
    show_progress "$CURRENT_PDF" "$TOTAL_PDFS"
done

echo ""
echo "Extraction complete! Text files are saved in '$OUTPUT_DIR'."
exit 0
