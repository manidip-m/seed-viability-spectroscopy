# Analysis Code

MATLAB scripts for chemometric analysis of NIR and Raman spectral data used in this study: spectral preprocessing, building classification model (PCA, PLS-DA, and SVM), and cross-validation of the model.

## Files

- `NIR_analysis.m` — main analysis pipeline for the NIR dataset
- `Raman_analysis.m` — main analysis pipeline for the Raman dataset
- `loadAndAverageScans.m` — loads NIR scan CSVs and averages replicate scans per seed
- `msc_preprocess.m` — Multiplicative Scatter Correction (MSC) preprocessing
- `savgol_derivative.m` — Savitzky–Golay derivative preprocessing
- `Raman_wdf_converter.m` — converts raw Renishaw `.wdf` Raman scans into the single `RamanDataset_Processed.mat` file used by `Raman_new.m`, applying basic quality control (drops spectra with weak signal or excessive saturation) along the way 

## Requirements

- MATLAB
- Statistics and Machine Learning Toolbox (PCA, PLS-DA, SVM, cross-validation, confusion matrices)
- Spectral data Preprocessing (Savitzky–Golay derivative, MSC, SNV)
- A `WdfReader`-capable MATLAB setup (typically via Renishaw's WiRE software or their published file-format toolkit) — only needed to run `Raman_wdf_conv_new.m`; not required for `Raman_analysis.m` itself

## Pipeline

Load spectral data → Average spectral data for each seed across treatments → PCA (raw) → Preprocess spectra → PCA (processed) → PLS-DA/SVM → 10-fold Cross-validation + permutation test

## Expected data layout

Data isn't included in this repo, but the scripts expect:

**NIR** — Raw data (.csv files) from the spectroscope's manufacturer software (see notes below).

**Raman** — a single `RamanDataset_Processed.mat` file containing `all_spectra`, `all_info`, and `common_wn`.

## How to run

1. Keep all files in this same folder — the helper functions just need to be on MATLAB's path, which the current folder is by default.
2. **(Raman only, from raw data)** If starting from raw `.wdf` scans rather than an existing `.mat` file, run `Raman_wdf_converter.m` first to produce `RamanDataset_Processed.mat`. Update the folder paths near the top of the script to point to your own raw scan folders first.
3. Open `NIR_analysis.m` or `Raman_analysis.m` in MATLAB.
4. In the spectral preprocessing section, set `preprocessing_choice` (1–6) to pick a method:
   1. Raw data (no preprocessing)
   2. Standard Normal Variate (SNV)
   3. Multiplicative Scatter Correction (MSC)
   4. Savitzky–Golay 1st derivative
   5. Savitzky–Golay 2nd derivative
   6. SNV + Savitzky–Golay 1st derivative
5. Run the script.

## Output

Each script prints the classification accuracy and preprocessing method used to the command window, and generates figures for the averaged spectra, PCA score plots, and confusion matrices for each classification model.

## Notes
While the pipelines are straightforward, the raw spectral data needs to be arranged systematically. 

In my NIR pipeline, I arranged the raw spectral data files as CSV files under `data/nir/control/`, `data/nir/microwave/`, and `data/nir/uv/`; files were named according to treatment and seed number and scan number `Code_<seed>_<scan>.csv`, with each seed scanned thrice (triplicates were averaged); each CSV file comprises a `***Scan Data***` header block followed by `Wavelength (nm)` and `Absorbance (AU)` columns.
Software used for obtaining spectral data: https://github.com/InnoSpectra/ISC-NIRScan-GUI

In the Raman pipeline, the files were arranged according to the treatment in folders similar to NIR pipeline. 