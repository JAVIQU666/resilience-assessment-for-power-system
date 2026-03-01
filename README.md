## 🚀 Code Running Instructions

### Step 0: Pre-run Preparation (Before running `env`)

Before running the `env` folder, please prepare the following climate pathway data:

- SSP1-2.6  
- SSP2-4.5  
- SSP3-7.0  
- SSP5-8.5  

For each pathway, the following files/folders are required:

- `exwindmax` folder (maximum wind speed data)
- `tempday` folder (daily temperature data)
- `prday` folder (daily precipitation data)

In addition, the following file must be added to the `data` folder:

- `loadcurvehourly2020.csv`

File format of `loadcurvehourly2020.csv`:

- Column 1: County index  
- Column 2: Annual total load  
- Columns 3–8762: Hourly load data (8760 hours)

Please ensure the data format is correct before proceeding.

---

### Step 1: Prepare Data

Copy all files in the `data` folder into the following directories:

- `env`
- `distribution_level`
- `regional_level`
- `national_level`

Make sure each folder contains the required input data before running the code.

---

### Step 2: Execution Order

Run the programs in the following order:

1. `env`
2. `distribution_level`
3. `regional_level`
4. `national_level`

Please execute each folder sequentially.

---

### ⚠️ Important Notes

- The output results from each previous stage must be provided as input to the subsequent folders.
- Before running the next folder, ensure that all required output files from the previous stage have been correctly generated and copied.
- Do not change the execution order, as the model depends on stage-by-stage data transfer.

---
