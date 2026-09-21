# seed-viability-spectroscopy

## About This Project

<img src="assets/thesis_ga.jpg">

Farmers and seed companies want to know: "Will this seed grow?" The usual way to check the seeds' viability, or their ability to grow into a plant, is destructive, i.e., by cutting seeds open to test them or planting one and waiting for it to germinate. 
This project explores a faster, non-destructive alternative method of testing seed viability using cutting edge spectroscopy methods (both expensive and affordable ones) combined with powerful machine learning models. 

In this thesis project, I artificially aged lima bean seeds using microwave and UV exposure to mimic the natural ageing of seeds over time, and compared two spectroscopic techniques—near-infrared spectroscopy and Raman spectroscopy. I built machine learning models and trained them to spot the subtle ageing-related chemical changes on the seeds against a control set (non-aged seeds). 
A handheld portable NIR spectroscope was remarkably good at this job, providing nearly ~98% accuracy in detecting aged seeds from fresh seeds. A simple takeaway from my project would be: A portable NIR spectroscope could give farmers and the agri-food industry a quick and reliable seed quality check without any wastage, improving efficiency and sustainability. 


## Results

### NIR spectroscopy — raw data
<img src="results/figures/nir-raw-spectra.jpg" width="600" alt="Mean NIR spectra by treatment">

*Mean NIR absorbance spectra for control, microwave-aged, and UV-aged seeds (n = 300 seeds).*

<img src="results/figures/nir-raw-pca.jpg" width="600" alt="PCA of raw NIR data">

*PCA on the raw spectra already shows some grouping by treatment, though with overlap.*

### NIR spectroscopy — after preprocessing
<img src="results/figures/nir-sg1-pca.jpg" width="600" alt="NIR PCA after SG1 preprocessing">

*A Savitzky–Golay 1st-derivative correction sharpened the separation between groups and revealed the spectral regions (900–950 nm, 1400–1450 nm, 1650–1700 nm) driving the differences.*

<img src="results/figures/nir-plsda-confusion-sg1.jpg" width="700" alt="NIR classification results">

*Both PLS-DA and SVM models reached 100% training, test, and cross-validation accuracy on the SG1-preprocessed data.*

### Raman spectroscopy
<img src="results/figures/raman-raw-spectra-pca.jpg" width="600" alt="Raw Raman spectra and PCA">

*Raman spectra were dominated by background noise, and PCA showed no clear separation between treatment groups.*

<img src="results/figures/raman-svm-confusion-overfit.jpg" width="600" alt="Raman overfitting">

*Raman-based models reached up to 100% training accuracy but only ~60–70% cross-validation accuracy — a sign of overfitting rather than genuine separability.*

### Independent validation
<img src="results/figures/tetrazolium-test.jpg" width="500" alt="Tetrazolium test results">

*Tetrazolium staining, the standard destructive viability test, confirmed that microwave treatment severely reduced seed viability — validating what the NIR model detected non-destructively.*