## Research project 2024-2025 on public environment and health public policy data from the Lombardy Region 

**Author:** Sandra Mickwitz  
**Email:** sandra.mickwitz01@icatt.it  
**Institution:** Università Cattolica del Sacro Cuore  

## Introduction
This repository contains cleaned and pre-processed data for research on public environment and health policy in the Lombardy Region. 
Data was collected between the 3rd and the 4th of September 2025. The pre-processing steps outlined here explain how to download data from the BURL platform and prepare it for use with different classification models. The Jupyter notebook tutorials will be made available shortly. 
 
Text to sentence splitter using heuristic algorithm by Philipp Koehn and Josh Schroeder has been used and can be found here https://github.com/mediacloud/sentence-splitter/blob/develop/README.rst. 
The output format of the sentence splitted files, was csv and later transformed into Excel, the final data set in csv format can be found in the Dataset directory. 

## Dataset Description
120 public policies from the Regione Lombardia from the years 2018, 2019, and 2020 have been manually downloaded from the following website: 
[Consultazione Burl](https://www.consultazioniburl.servizirl.it/ConsultazioneBurl/).

Following filters were applied through the semantic search:
**Direzione** this filter indicates the policy type 
**Anno bollettino** this filter indicates the year of the policy type 

The policy act pdf document was downloaded from page 1 and page 2. 

### **Policy act type Selection per Year**
- **2018:**
  - Sectors selected:
    - D.G. Ambiente e Clima (20)
    - D.G. Welfare (20)
  - Total: **40 policies**
- **2019:**
   - Sectors selected:
    - D.G. Ambiente e Clima (20)
    - D.G. Welfare (20)
  - Total: **40 policies**
- **2020:**
    - Sectors selected:
    - D.G. Ambiente e Clima (20)
    - D.G. Welfare (20)
  - Total: **40 policies**

## Preprocessing Steps
The following script was used to transform the pdf policies into .txt files for sentence splitting. 
```bash
./pdf2text.sh
```
## Jupter Notebook tutorial for data cleaning and sentence splitting will be uploaded 
