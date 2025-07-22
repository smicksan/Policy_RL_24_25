#!/bin/bash

# Parameters for the BURL API
#SERIE=$1
#WEEK=$2
YEAR=$1
WEEK_START=$2
WEEK_END=$3
TOTAL_WEEKS=$((WEEK_END - WEEK_START + 1))

start_time=$(date +%s)

bold=$(tput bold)
normal=$(tput sgr0)


echo ""
echo "******************************************************************************"
echo "   \('')/               ${bold}BURL Extraction Script${normal}"
echo "   -(  )-          ${bold}Author: navarral | Date: January 2024${normal}"
echo "   /(__)\                      ${bold}Version: 1.0${normal}"
echo "******************************************************************************"
echo ""
echo "${bold}Usage:${normal} tbc"
echo ""
echo "${bold}Requirements:${normal} poppler (Linux and Mac) or xpdf (Windows)"
echo "- Linux install: sudo apt install poppler-utils"
echo "- Mac install: brew install poppler"
echo "- Windows install: download from https://www.xpdfreader.com/download.html"
echo ""
echo ""
# Function to print a progress bar
bar_size=40
bar_char_done="#"
bar_char_todo="-"
bar_percentage_scale=2

function show_progress {
    current="$1"
    total="$2"

    # calculate the progress in percentage 
    percent=$(bc <<< "scale=$bar_percentage_scale; 100 * $current / $total" )
    # The number of done and todo characters
    done=$(bc <<< "scale=0; $bar_size * $percent / 100" )
    todo=$(bc <<< "scale=0; $bar_size - $done" )

    # build the done and todo sub-bars
    done_sub_bar=$(printf "%${done}s" | tr " " "${bar_char_done}")
    todo_sub_bar=$(printf "%${todo}s" | tr " " "${bar_char_todo}")

    # output the bar
    echo -ne "\rProgress : [${done_sub_bar}${todo_sub_bar}] ${current}/${total} Weeks"

    # Convert estimated time left to a readable format
    minutes=$((estimated_time_left / 60))
    seconds=$((estimated_time_left % 60))

    echo -ne " Estimated time left: ${minutes}m ${seconds}s"
}

# Create a folder for the output in case it does not exist
DATE_TIME=$(date +%Y%m%dT%H%M%S)
OUTPUT_DIR="burl_${YEAR}_$DATE_TIME"

if [ ! -d ${OUTPUT_DIR} ]
then
    mkdir -p ${OUTPUT_DIR}
fi

# Output TSV file 
TSV_FILENAME="$OUTPUT_DIR/burl_dataset_$DATE_TIME.tsv"
# Print the column headers
echo -e "year\tweek\tpdf_id\tlaw_type\tdate\tlaw_id\tsector\ttitle" > "$TSV_FILENAME"

WEEK_DONE=0

# Record the start time for the first iteration
first_iteration_start_time=$(date +%s)

# Iterate for a year
for WEEK in $(seq $WEEK_START $WEEK_END); do
    # Calculate progress
    # Record the start time for each iteration
    iteration_start_time=$(date +%s)

    # Print the progress bar
    show_progress "$WEEK_DONE" "$TOTAL_WEEKS"
	# Set the path to the HTML file
	OUTPUT_HTML="$OUTPUT_DIR/elencoburl_${YEAR}_${WEEK}.html"
	# echo "$OUTPUT_HTML"
	wget --no-check-certificate --post-data="anno=$YEAR&serie=&bol=$WEEK&data_serie_strad=&cerca=Cerca" -q https://www.consultazioniburl.servizirl.it/ConsultazioneBurl/ElencoBurl --output-document "$OUTPUT_HTML"
	# Use grep to extract lines containing the pattern and then use awk to extract the unique PDF files
	PDF_LIST=($(grep -A6 -E '<td>(Serie Ordinaria|Supplementi)</td>' "$OUTPUT_HTML" | grep -o '<input type="hidden" name="idBurl" value="[0-9]*" />' | awk -F'"' '{print $6}' | sort -u))
	# PDF_LIST=($(grep -o '<input type="hidden" name="idBurl" value="[0-9]*" />' "$OUTPUT_HTML" | awk -F'"' '{print $6}' | sort -u))
	# Set the possible law value types in a variable
	law_types="Delibera Giunta regionale|Decreto direttore generale|Decreto dirigente unità organizzativa|Decreto dirigente struttura|Deliberazione Consiglio regionale|Decreto Presidente Regione Lombardia|Comunicato regionale|Decreto segretario generale Giunta regionale|Legge regionale|Regolamento regionale|Ordinanza Presidente Giunta regionale|T\.c\. legge regionale|Circolare regionale"
	
	# Print the extracted values
	for PDF_N in "${PDF_LIST[@]}"; do
		PDF_FILENAME="$OUTPUT_DIR/elencoburl_$PDF_N.pdf"
		# echo "downloading $PDF_FILENAME"
		wget --no-check-certificate --post-data="idBurl=$PDF_N&apriAllegato=" -q https://www.consultazioniburl.servizirl.it/ConsultazioneBurl/ApriAllegato --output-document "$PDF_FILENAME"
		
		# Convert PDF to text
		TXT_FILENAME="$OUTPUT_DIR/elencoburl_$PDF_N.txt"
		pdftotext -layout "$PDF_FILENAME" "$TXT_FILENAME"
		
		# Extract relevant information from TXT files
		# TSV_FILENAME="$OUTPUT_DIR/elencoburl_$PDF_N.tsv"
		
		# Extract line where double column starts in the file
		#start_double_column_line=$(grep -n -m 1 -E '•' "$TXT_FILENAME"| cut -d: -f1)
		start_long_text=$(grep -n '\.\ \{2,\}\.' "$TXT_FILENAME" | cut -d: -f1 | sort -rn | head -n 1)
		start_long_text=$((start_long_text + 1))
		
		# Extract lines for the sectors in atti dirigenziali
		line_numbers=$(grep -n -E '^(D\.G\.|Presidenza).*$' "$TXT_FILENAME" | grep -v -E '[[:space:]]{4,}' | awk -v start_long_text="$start_long_text" -F: '$1 <= start_long_text {print $1}')
	
		# echo "This is the start double line: $start_long_text"
		
		# Extract line where the laws start
		start_line=$(grep -n -m 1 -E 'SOMMARIO' "$TXT_FILENAME" | cut -d: -f1 | sort -n | tail -n 1)
		# start_line=$(grep -n -m 1 -E 'A) CONSIGLIO REGIONALE|B) PRESIDENTE DELLA GIUNTA REGIONALE|C) GIUNTA REGIONALE E ASSESSORI|D) ATTI DIRIGENZIALI' "$TXT_FILENAME" | cut -d: -f1 | sort -n | tail -n 1)

		# Add start and end to line_numbers
		line_numbers="$start_line
		$line_numbers
		$start_long_text"
		
		# echo "$line_numbers"
		
		# Initialize variables
		line_ranges=()
		prev_line=""

		# Process each line number
		while read -r line_number; do
			if [ -n "$prev_line" ]; then
				line_ranges+=("${prev_line},$((line_number-1))")
			fi
			prev_line="$line_number"
		done <<< "$line_numbers"

		# Add the last range if there is one
		if [ -n "$prev_line" ]; then
			# Adjust the calculation for the last range
			if [ "${#line_ranges[@]}" -eq 1 ]; then
				line_ranges+=("${start_line},$((prev_line))")
			else
				line_ranges+=("${prev_line},$((line_number-1))")
			fi
		fi

		# Select line ranges excluding those with negative values
		selected_line_ranges=()
		for line_chunk in "${line_ranges[@]}"; do
			# Check if the line range contains negative values
			if [[ ! "$line_chunk" =~ -1 ]]; then
				selected_line_ranges+=("$line_chunk")
			fi
		done

		# Print line ranges excluding those with negative values
		for line_chunk in "${selected_line_ranges[@]}"; do
			# echo "Processing Line Range: $line_chunk"  
			# Extract D.G. matches  
			sector=$(sed "${line_chunk}!d" "$TXT_FILENAME" | grep -E "D\.G\.|Presidenza")
			# Capture the entire output of the command in the matched_content variable
			# matched_laws=$(sed "${line_chunk}!d" "$TXT_FILENAME" | tr "\n" " "| tr -s ' ' | sed "s/\(\.\ \{1\}\.\ \{1\}\)\{1,\}/JJJ\n/g" | sed -n -E "s/.*($law_types.*JJJ)/\1/p" | tr -d "JJJ" )
			
			# matching pattern written in Jan 2024
			
			matched_laws=$(sed "${line_chunk}!d" "$TXT_FILENAME" | tr "\n" " "| tr -s ' ' | sed "s/\(\.\ \{1\}\.\ \{1\}\)\{1,\}/JJJ\n/g" | sed -n -E "s/($law_types)/AAA\1/p" | sed -n -E "s/($law_types)/JKW\1/p" | sed -e "s/.*JKW\(.*\)JJJ.*/\1/" | sed -E "s/([0-9]{4})-? *n\./\1 - n\./g" | sed -E "s/ -n\./ - n\./g" | sed -E "s/([0-9]{4} - n\.)([A-Z]+\/[0-9]+|[0-9]+)/\1 \2/" | sed -E "s/($law_types)\s*([0-9]{1,2})/\1 \2/" | sed -E "s/([0-9]{1,2})([a-zA-Z]+ [0-9]{4})/\1 \2/" | sed -E "s/([0-9]{1,2} [a-zA-Z]+)([0-9]{4})/\1 \2/")
			# Extract information using awk and sed
			# sed "${line_chunk}!d" "$TXT_FILENAME" | grep -oE "($law_types) [0-9]{1,2} [a-zA-Z]+ [0-9]{4} - n\. ([A-Z]+\/[0-9]+|[0-9]+)" | awk -v sector="$sector" '
			

			echo "$matched_laws" | awk -v sector="$sector" -v pdf_id="$PDF_N" -v week_n="$WEEK" -v year_n="$YEAR" '
			{  
				
				
				month_names["gennaio"]="01"; month_names["febbraio"]="02"; month_names["febbrio"]="02"; month_names["marzo"]="03"; month_names["aprile"]="04"; month_names["maggio"]="05"; month_names["giugno"]="06"; month_names["luglio"]="07"; month_names["agosto"]="08"; month_names["settembre"]="09"; month_names["ottobre"]="10"; month_names["ottobrem"]="10"; month_names["oottobre"]="10"; month_names["novembre"]="11"; month_names["dicembre"]="12"; month_names["dicembe"]="12"; month_names["dicmbre"]="12";
			
				# Determine law type
				is_dduo = ($4 == "organizzativa")
				is_dgr = ($2 == "Giunta")
				is_ddg = ($2 == "direttore")
				is_dds = ($3 == "struttura")
				is_dcr = ($2 == "Consiglio")
				is_dprl = ($2 == "Presidente")
				is_cr = ($1 == "Comunicato")
				is_dsggr = ($2 == "segretario")
				is_legge = ($1 == "Legge")
				is_rl = ($1 == "Regolamento")
				is_opgr = ($1 == "Ordinanza")
				is_tclr = ($1 == "T.c.")
				is_cir = ($1 == "Circolare")
			
				# Set the variable based on the conditions		
				law_type_var = (is_dduo ? "dduo" : (is_dgr ? "dgr" : (is_ddg ? "ddg" : (is_dds ? "dds" : (is_dcr ? "dcr" : (is_dprl ? "dprl" : (is_cr ? "cr" : (is_dsggr ? "dsggr" : (is_legge ? "legge" : (is_rl ? "rl" : (is_opgr ? "opgr" : (is_tclr ? "tclr" : (is_cir ? "cir" : "")))))))))))));
				
				# Set the law_id variable based on the conditions
				law_id = (is_dduo || is_dprl || is_opgr) ? $10 : (is_cr || is_legge || is_rl || is_tclr || is_cir ? $8 : (is_dsggr ? $11 : $9));
				
				law_title = ""

				for (i = 1; i <= NF; i++) {
					law_title = law_title " " $i;
				}

				day_position = (is_dduo || is_dprl || is_opgr) ? 5 : (is_cr || is_legge || is_rl || is_cir? 3 : (is_dsggr ? 6 : 4));
				month_position = (is_dduo || is_dprl || is_opgr) ? 6 : (is_cr || is_legge || is_rl || is_cir ? 4 : (is_dsggr ? 7 : 5));
				year_position = (is_dduo || is_dprl || is_opgr) ? 7 : (is_cr || is_legge || is_rl || is_cir ? 5 : (is_dsggr ? 8 : 6));
			
				day = $(day_position);
				month = $(month_position);
				year = $(year_position);
				
				# Check if sector is empty and set it to "NA"
				sector = (sector == "") ? "NA" : sector;
				
				printf "%d\t%d\t%s\t%s\t%04d-%02d-%02d\t%s\t%s\t%s\n", year_n, week_n, pdf_id, law_type_var, year, month_names[tolower(month)], day, law_id, sector, law_title;
				
			}' >> "$TSV_FILENAME"
			
		done

		
		# Remove temporary text file
		rm "$TXT_FILENAME"
		# exit 1
	done
	
	rm "$OUTPUT_HTML"
	
	#Update iteration
	((WEEK_DONE++))

    # Record the end time for each iteration
    iteration_end_time=$(date +%s)

    # Calculate the time taken for the current iteration
    iteration_time=$((iteration_end_time - iteration_start_time))

    # Calculate the estimated time left based on the first iteration and update in each iteration
    if [ "$WEEK_DONE" -eq 1 ]; then
        estimated_time_left=$((TOTAL_WEEKS * iteration_time))
        #echo "Estimated time left (based on first iteration): $estimated_time_left seconds"
    else
        estimated_time_left=$((estimated_time_left - iteration_time))
        #echo "Estimated time left (updated): $estimated_time_left seconds"
    fi

    # Call the show_progress function
    show_progress "$WEEK_DONE" "$TOTAL_WEEKS" "$estimated_time_left"
    
	

done

# rm "$OUTPUT_DIR"/*.txt
# Print a message indicating where the file was saved
echo ""
echo ""
echo "Results saved to: $TSV_FILENAME"
echo ""
end_time=$(date +%s)
echo "Execution time: $(($end_time-$start_time)) seconds"








