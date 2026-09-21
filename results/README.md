## Results

### NIR spectroscopy — raw data
![Mean NIR spectra by treatment](results/figures/nir-raw-spectra.jpg)
*Mean NIR absorbance spectra for control, microwave-aged, and UV-aged seeds (n = 300 seeds).*

![PCA of raw NIR data](results/figures/nir-raw-pca.jpg)
*PCA on the raw spectra already shows some grouping by treatment, though with overlap.*

### NIR spectroscopy — after preprocessing
![NIR PCA after SG1 preprocessing](results/figures/nir-sg1-pca.jpg)
*A Savitzky–Golay 1st derivative correction sharpened the separation between groups and revealed the spectral regions (900–950 nm, 1400–1450 nm, 1650–1700 nm) driving the differences.*

![NIR classification results](results/figures/nir-plsda-confusion-sg1.jpg)
*Both PLS-DA and SVM models reached 100% training, test, and cross-validation accuracy on the Savitsky-Golay 1st derivative preprocessed data.*

### Raman spectroscopy
![Raw Raman spectra and PCA](results/figures/raman-raw-spectra-pca.jpg)
*Raman spectra were dominated by background noise, and PCA little separation between treatment groups.*

![Raman overfitting](results/figures/raman-svm-confusion-overfit.jpg)
*Raman-based models reached up to 100% training accuracy but only ~60–70% cross-validation accuracy: a sign of overfitting.*

### Independent validation
![Tetrazolium test results](results/figures/tetrazolium-test.jpg)
*Tetrazolium staining, the standard destructive viability test, confirmed that microwave treatment severely reduced seed viability, validating what the NIR model detected non-destructively.*