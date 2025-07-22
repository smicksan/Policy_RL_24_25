#!/bin/bash

# Create a folder for the output in case it does not exist
#DATE_TIME=$(date +%Y%m%dT%H%M%S)

# Loop through all PDF files in the current directory
#for pdf_file in elencoburl_*.pdf; do

# Create a folder for the output in case it does not exist
DATE_TIME=$(date +%Y%m%dT%H%M%S)

# List all matching PDFs
pdf_files=(elencoburl_*.pdf)

# Check if there are any matching files
if [ ${#pdf_files[@]} -eq 0 ]; then
    echo "No files matching 'elencoburl_*.pdf' found in the current directory."
    exit 1
fi

# List the files
echo "The following files will be processed:"
for pdf in "${pdf_files[@]}"; do
    echo "$pdf"
done

# Ask the user whether to continue
read -p "Do you want to proceed with these files? (Y/N): " user_input

# Convert input to uppercase for consistency
user_input=$(echo "$user_input" | tr '[:lower:]' '[:upper:]')

if [ "$user_input" != "Y" ]; then
    echo "Operation cancelled by the user."
    exit 0
fi


OUTPUT_DIR="pdf2policy_$DATE_TIME"

if [ ! -d ${OUTPUT_DIR} ]
then
	mkdir -p ${OUTPUT_DIR}
fi	

# Loop through all PDF files in the current directory
for pdf_file in "${pdf_files[@]}"; do
    # Check if any PDF files exist
    [ -e "$pdf_file" ] || continue

    pdf_without_extension="${pdf_file%.pdf}"
		
    # Generate the new file name by replacing the .pdf extension with .txt
	txt_file="$OUTPUT_DIR/${pdf_file%.pdf}.txt"

	# Debug: Print the PDF and corresponding new text file name
	echo "Processing PDF file: $pdf_file"
	pdftotext -layout -f 1 -l 5 "$pdf_file" "$txt_file"

	# echo "Saving extracted text to: $txt_file"

	# Extract lines for the table of contents
	start_line=$(grep -n -m 1 -E 'SOMMARIO' "$txt_file" | cut -d: -f1 | sort -n | tail -n 1)

	start_long_text=$(grep -n '\.\ \{2,\}\.' "$txt_file" | cut -d: -f1 | sort -rn | head -n 1)
	start_long_text=$((start_long_text + 1))

	# Extract policy titles
	policy_title=$(sed -n "${start_line},${start_long_text}p" "$txt_file" | sed -E "
	  s/([0-9]{4})-? *n\./\1 - n\./g;
	  s/ -n\./ - n\./g;
	  s/([0-9]{4} - n\.)([A-Z]+\/[0-9]+|[0-9]+)/\1 \2/;
	" | sed -nE "/[0-9]{4} - n\. ([A-Z]+\/[0-9]+|[0-9]+)$/p")

	# Extract policy id 
	policy_id=$(echo "$policy_title" | awk '{print $NF}' | tr -d '/')

	# extract page numbers
	page_numbers=$(sed -n "${start_line},${start_long_text}p" "$txt_file" | grep -o '\(\.\s*\)\{3,\}[0-9]\+' | grep -o '[0-9]\+')

	# Remove temporary text file
	rm "$txt_file"

	prev_page=""
	policy_counter=1

	# Get the total number of pages in the PDF to handle the last page
	total_pdf_pages=$(pdfinfo "$pdf_file" | awk '/^Pages:/ {print $2}')

	# echo "$total_pdf_pages"

	# Loop through the line numbers
	for page in $page_numbers; do
		if [ -z "$prev_page" ]; then
			# If prev_line is empty, store the current line as prev_line
			prev_page=$page
		else
			# Select last page before new policy
			prev_page_1=$((page - 1))
			
			# Select policy_id with the policy_counter index
			policy_sel=$(echo "$policy_id" | sed "${policy_counter}q;d")
			
			# Otherwise, process the pair (prev_line to current line)
			echo "Processing policy $policy_sel: pages $prev_page to $page"
			
			qpdf --empty --pages "$pdf_file" $prev_page-$prev_page_1 -- "$OUTPUT_DIR/${pdf_without_extension}_policy${policy_sel}_${prev_page}_${prev_page_1}.pdf"		
			
			# Update prev_line to the current line
			prev_page=$page
			
			# Increment the policy counter for the next policy
			((policy_counter++))
		fi
	done

	# Handle the last page number if there's an odd number of line numbers
	if [ -n "$prev_page" ]; then
		echo "Processing last policy $policy_sel: $prev_page to $total_pdf_pages"
		# Directly extract the range of pages and output to the desired PDF
		qpdf --empty --pages "$pdf_file" $prev_page-$total_pdf_pages -- "$OUTPUT_DIR/${pdf_without_extension}_policy${policy_sel}_${prev_page}_${total_pdf_pages}.pdf"

	fi
	echo ""	
		
done

exit



