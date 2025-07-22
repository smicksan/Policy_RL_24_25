## Research project on public environment and health public policy data from the Lombardy Region 2024-2025

**Author:** Sandra Mickwitz  
**Email:** sandra.mickwitz01@icatt.it  
**Institution:** Università Cattolica del Sacro Cuore  
**Date:** 19th of February 2025  

## Introduction
This repository contains cleaned and pre-processed data for research on public environment and health policy in the Lombardy Region. 
Data was collected 17th of February 2025. 
 
Text to sentence splitter using heuristic algorithm by Philipp Koehn and Josh Schroeder has been used and can be found here https://github.com/mediacloud/sentence-splitter/blob/develop/README.rst. 
The output format of the sentence splitted files, was csv and later transformed into Excel, the final data set in csv format can be found in the Dataset directory. 

## Dataset Description
40 public policies from the Regione Lombardia from the years 2012, 2013, and 2014 have been mined with a script from the following website: 
[Consultazione Burl](https://www.consultazioniburl.servizirl.it/ConsultazioneBurl/).

### **Policy Selection per Year**
- **2012:**
  - Sectors selected:
    - D.G. Sistemi verdi e paesaggio (1)
    - D.G. Sanita (1)
    - D.G. Ambiente, energia e reti (3)
  - Total: **5 policies**
- **2013:**
  - Sectors selected:
    - D.G. Sanita (6)
    - D.G. Ambiente, energia e reti (11)
  - Total: **15 policies**
- **2014:**
  - Sectors selected:
    - D.G. Sanita (2)
    - D.G. Ambiente, energia e reti (18)
  - Total: **20 policies**

## Preprocessing Steps
Once the policies had been selected, with this script, was run through the destination folder of where the pdf policy documents should be downloaded to.
```bash
./burlexport.sh 2011 1 2 
```
the following script was executed in each folder containing the policies for each year:
```bash
./pdf2policy.sh
```
The reason for this script is that each PDF document with the indicated `pdf_id` contains multiple policies. 
The script helps separate policies that were not specifically targeted from the relevant sector policies.

The following script was used to transform the pdf chunked policies into .txt files for sentence splitting. 
```bash
./pdf2text.sh
```
### **Script Execution and Review**
- The script creates a new subfolder containing the chunked policies.
- The single files were manually reviewed to filter out policies that did not meet the targeted sector's requirements.
