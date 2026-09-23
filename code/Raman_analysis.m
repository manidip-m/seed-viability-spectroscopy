%% SECTION 1: DATA LOADING & ACCURATE AVERAGING
clc; clear; close all; % Clear workspace

% 1. Load Data
% Load the pre-compiled .mat file containing all Raman scans and info
load('RamanDataset_Processed.mat');
fprintf('Raman .mat file loaded successfully.\n');

% 2. Parse Filenames to Create Seed IDs
% Convert the 'all_info' character array to a cell array of strings (filenames)
filenames = all_info;
num_total_scans = length(filenames);
seed_identifiers = cell(num_total_scans, 1); % To store IDs like 'Ct_100'

fprintf('Parsing %d filenames to identify unique seeds...\n', num_total_scans);
for i = 1:num_total_scans
    tokens = regexp(filenames{i}, '_([A-Za-z]+)_(\d+)_', 'tokens');
    
    if ~isempty(tokens)
        treatment = tokens{1}{1}; 
        seed_num = tokens{1}{2};  
        
        % Create a unique, consistent identifier for each seed
        seed_identifiers{i} = [treatment '_' seed_num];
    else
        seed_identifiers{i} = 'unknown';
        warning('Could not parse filename: %s', filenames{i});
    end
end

% 3. Group and Average Spectra by Unique Seed ID
% Find all the unique seeds that were identified
unique_seeds = unique(seed_identifiers);
num_unique_seeds = length(unique_seeds);

% Initialize final data matrices
wavenumber = common_wn';
raman_data = zeros(num_unique_seeds, length(wavenumber));
labels = zeros(num_unique_seeds, 1);
treatment_map = containers.Map({'Ct', 'Mw', 'uv'}, {0, 1, 2});

fprintf('Found %d unique seeds. Averaging spectra for each...\n', num_unique_seeds);
for i = 1:num_unique_seeds
    current_seed_id = unique_seeds{i};
    
    % Find all rows (scans) that match the current unique seed ID
    is_current_seed = strcmp(seed_identifiers, current_seed_id);
    
    % Extract all replicate spectra for this seed
    replicate_spectra = all_spectra(is_current_seed, :);
    
    % Calculate the mean spectrum for this seed
    raman_data(i, :) = mean(replicate_spectra, 1);
    
    % Determine the numeric label from the seed ID string
    if contains(current_seed_id, 'Ct', 'IgnoreCase', true)
        labels(i) = 0;
    elseif contains(current_seed_id, 'Mw', 'IgnoreCase', true)
        labels(i) = 1;
    elseif contains(current_seed_id, 'uv', 'IgnoreCase', true)
        labels(i) = 2;
    end
end

% 4. Final Verification
fprintf('\nData loading and averaging complete.\n');
fprintf('Final seed-averaged dataset size: %d seeds x %d wavenumbers.\n', size(raman_data, 1), size(raman_data, 2));
fprintf('Final label distribution:\n');
fprintf('  - Control:   %d seeds\n', sum(labels == 0));
fprintf('  - Microwave: %d seeds\n', sum(labels == 1));
fprintf('  - UV:        %d seeds\n', sum(labels == 2));

%% SECTION 2: VISUALIZATION OF AVERAGED SPECTRA 
disp('Generating plots for seed-averaged Raman spectra...');

% 1. Define Colors and Labels for Plotting
control_color = [0, 0, 1]; % Blue
microwave_color = [1, 0, 0]; % Red
uv_color = [0, 1, 0]; % Green
class_names = {'Control', 'Microwave', 'UV'};

%% 2. Plot 1: All 300 Seed-Averaged Spectra Together
figure('Name', 'All Seed-Averaged Raman Spectra', 'Color', 'w');
hold on;

% Plot each group with its specific color and slight transparency
plot(wavenumber, raman_data(labels == 0, :)', 'Color', [control_color, 0.3]);
plot(wavenumber, raman_data(labels == 1, :)', 'Color', [microwave_color, 0.3]);
plot(wavenumber, raman_data(labels == 2, :)', 'Color', [uv_color, 0.3]);

h1 = plot(NaN, NaN, 'Color', control_color, 'LineWidth', 2.5);
h2 = plot(NaN, NaN, 'Color', microwave_color, 'LineWidth', 2.5);
h3 = plot(NaN, NaN, 'Color', uv_color, 'LineWidth', 2.5);

hold off;
title('All Seed-Averaged Raman Spectra by Treatment');
xlabel('Wavenumber (cm^{-1})');
ylabel('Mean Raman Intensity (a.u.)');
legend([h1, h2, h3], class_names, 'Location', 'best');
grid on;

%% 3. Plot 2: Grand Mean Spectra of the Three Treatments
figure('Name', 'Grand Mean Raman Spectra Comparison', 'Color', 'w');
hold on;

% Calculate and plot the grand mean for each treatment
mean_control = mean(raman_data(labels == 0, :), 1);
plot(wavenumber, mean_control, 'Color', control_color, 'LineWidth', 2.5, 'DisplayName', 'Control');

mean_microwave = mean(raman_data(labels == 1, :), 1);
plot(wavenumber, mean_microwave, 'Color', microwave_color, 'LineWidth', 2.5, 'DisplayName', 'Microwave');

mean_uv = mean(raman_data(labels == 2, :), 1);
plot(wavenumber, mean_uv, 'Color', uv_color, 'LineWidth', 2.5, 'DisplayName', 'UV');

hold off;
title('Grand Mean Raman Spectra for Each Treatment Group');
xlabel('Wavenumber (cm^{-1})');
ylabel('Mean Raman Intensity (a.u.)');
legend show;
grid on;

%% SECTION 3: PRINCIPAL COMPONENT ANALYSIS (PCA) ON RAW DATA 
disp('Performing PCA on raw, seed-averaged Raman data...');

% 1. Perform PCA
[coeff, score, latent] = pca(raman_data);
explained = 100 * latent / sum(latent);


% Plot 1: 2D PCA Score Plot
figure('Name', '2D PCA Score Plot (Raw Raman Data)', 'Color', 'w');
hold on;
scatter(score(labels == 0, 1), score(labels == 0, 2), 36, control_color, 'filled', 'DisplayName', 'Control');
scatter(score(labels == 1, 1), score(labels == 1, 2), 36, microwave_color, 'filled', 'DisplayName', 'Microwave');
scatter(score(labels == 2, 1), score(labels == 2, 2), 36, uv_color, 'filled', 'DisplayName', 'UV');
hold off;

title('2D PCA Score Plot of Raw Raman Data');
xlabel(['Principal Component 1 (' num2str(explained(1), '%.2f') '%)']);
ylabel(['Principal Component 2 (' num2str(explained(2), '%.2f') '%)']);
legend show;
grid on;

% Plot 2: 3D PCA Score Plot
figure('Name', '3D PCA Score Plot (Raw Raman Data)', 'Color', 'w');
hold on;
scatter3(score(labels == 0, 1), score(labels == 0, 2), score(labels == 0, 3), 36, control_color, 'filled', 'DisplayName', 'Control');
scatter3(score(labels == 1, 1), score(labels == 1, 2), score(labels == 1, 3), 36, microwave_color, 'filled', 'DisplayName', 'Microwave');
scatter3(score(labels == 2, 1), score(labels == 2, 2), score(labels == 2, 3), 36, uv_color, 'filled', 'DisplayName', 'UV');
hold off;

title('3D PCA Score Plot of Raw Raman Data');
xlabel(['PC 1 (' num2str(explained(1), '%.2f') '%)']);
ylabel(['PC 2 (' num2str(explained(2), '%.2f') '%)']);
zlabel(['PC 3 (' num2str(explained(3), '%.2f') '%)']);
legend show;
grid on;
view(3); % Set the default view to 3D
rotate3d on; % Allow interactive rotation

% Plot 3: PCA Loadings Plot
figure('Name', 'PCA Loadings (Raw Raman Data)', 'Color', 'w');
hold on;
plot(wavenumber, coeff(:, 1), 'LineWidth', 2, 'DisplayName', 'PC1 Loadings');
plot(wavenumber, coeff(:, 2), 'LineWidth', 2, 'DisplayName', 'PC2 Loadings');
plot(wavenumber, coeff(:, 3), 'LineWidth', 2, 'DisplayName', 'PC3 Loadings');
hold off;
yline(0, 'k--', 'HandleVisibility', 'off'); % Add a zero line for reference

title('PCA Loadings for First Three Components');
xlabel('Wavenumber (cm^{-1})');
ylabel('Loading Weight');
legend show;
grid on;

fprintf('PCA analysis on raw data complete.\n');

%% SECTION 4: SPECTRAL PREPROCESSING 
% CHOOSE PREPROCESSING METHOD
% 1: Raw Data (No Preprocessing)
% 2: Baseline Correction Only (Asymmetric Least Squares)
% 3: Baseline Correction + SNV
% 4: Baseline Correction + MSC
% 5: Baseline Correction + Savitzky-Golay 1st Derivative
% 6: Baseline Correction + Savi3tzky-Golay 2nd Derivative
preprocessing_choice = 5; % <- CHANGE THIS NUMBER (1-6) TO TEST DIFFERENT METHODS

% Parameters for Savitzky-Golay
sg_poly_order = 2;   % Polynomial order (typically 2 or 3)
sg_window_size = 11; % Window size (must be an odd number)

% Parameters for Baseline Correction (ALS)
asymmetry_param = 0.01; % p (0.001-0.1) - How much to penalize points above the baseline
smoothness_param = 1e5;  % lambda (1e2-1e9) - How smooth the baseline should be

disp('Performing spectral preprocessing...');

% Apply selected preprocessing method
switch preprocessing_choice
    case 1 % Raw Data
        preproc_data = raman_data;
        method_name = 'Raw Data (No Preprocessing)';

    case 2 % Baseline Correction Only
        preproc_data = baseline_als(raman_data, smoothness_param, asymmetry_param);
        method_name = 'Baseline Correction';

    case 3 % Baseline Correction + SNV
        baseline_corrected = baseline_als(raman_data, smoothness_param, asymmetry_param);
        mean_spectra = mean(baseline_corrected, 2);
        std_spectra = std(baseline_corrected, 0, 2);
        preproc_data = (baseline_corrected - mean_spectra) ./ std_spectra;
        method_name = 'Baseline + SNV';

    case 4 % Baseline Correction + MSC
        baseline_corrected = baseline_als(raman_data, smoothness_param, asymmetry_param);
        preproc_data = msc_preprocess(baseline_corrected);
        method_name = 'Baseline + MSC';

    case 5 % Baseline Correction + Savitzky-Golay 1st Derivative
        baseline_corrected = baseline_als(raman_data, smoothness_param, asymmetry_param);
        preproc_data = savgol_derivative(baseline_corrected, sg_poly_order, sg_window_size, 1);
        method_name = 'Baseline + SG 1st Derivative';
        
    case 6 % Baseline Correction + Savitzky-Golay 2nd Derivative
        baseline_corrected = baseline_als(raman_data, smoothness_param, asymmetry_param);
        preproc_data = savgol_derivative(baseline_corrected, sg_poly_order, sg_window_size, 2);
        method_name = 'Baseline + SG 2nd Derivative';
        
    otherwise
        error('Invalid preprocessing_choice. Please choose a number from 1 to 6.');
end

fprintf('Preprocessing complete. Method used: %s\n', method_name);


%% SECTION 5: PREPROCESSED DATA VISUALIZATION & PCA
% This section visualizes the data AFTER applying the preprocessing method
% selected in Section 3. Rerun this section after changing the choice in Section 3.

disp(['Visualizing data preprocessed with: ' method_name]);

% Define Colors
control_color = [0, 0, 1]; % Blue
microwave_color = [1, 0, 0]; % Red
uv_color = [0, 1, 0]; % Green

%% Plot 1: All 300 Preprocessed Spectra Together
figure('Name', ['All Spectra (' method_name ')'], 'Color', 'w');
hold on;
plot(wavenumber, preproc_data(labels == 0, :)', 'Color', [control_color, 0.3]);
plot(wavenumber, preproc_data(labels == 1, :)', 'Color', [microwave_color, 0.3]);
plot(wavenumber, preproc_data(labels == 2, :)', 'Color', [uv_color, 0.3]);
h1 = plot(NaN, NaN, 'Color', control_color, 'LineWidth', 2.5);
h2 = plot(NaN, NaN, 'Color', microwave_color, 'LineWidth', 2.5);
h3 = plot(NaN, NaN, 'Color', uv_color, 'LineWidth', 2.5);
hold off;
title(['All Seed Spectra (' method_name ')']);
xlabel('Wavenumber (cm^{-1})');
ylabel('Processed Raman Intensity');
legend([h1, h2, h3], {'Control', 'Microwave', 'UV'}, 'Location', 'best');
grid on;

%% Plot 2: Grand Mean of Preprocessed Spectra
figure('Name', ['Grand Means (' method_name ')'], 'Color', 'w');
hold on;
plot(wavenumber, mean(preproc_data(labels == 0, :), 1), 'Color', control_color, 'LineWidth', 2.5, 'DisplayName', 'Control');
plot(wavenumber, mean(preproc_data(labels == 1, :), 1), 'Color', microwave_color, 'LineWidth', 2.5, 'DisplayName', 'Microwave');
plot(wavenumber, mean(preproc_data(labels == 2, :), 1), 'Color', uv_color, 'LineWidth', 2.5, 'DisplayName', 'UV');
hold off;
title(['Grand Mean Spectra (' method_name ')']);
xlabel('Wavenumber (cm^{-1})');
ylabel('Mean Processed Intensity');
legend show;
grid on;

%% PCA on Preprocessed Data 
disp(['Performing PCA on data processed with: ' method_name]);
[coeff, score, latent] = pca(preproc_data);
explained = 100 * latent / sum(latent);

%% Plot 3: 2D PCA Score Plot
figure('Name', ['2D PCA (' method_name ')'], 'Color', 'w');
hold on;
scatter(score(labels == 0, 1), score(labels == 0, 2), 36, control_color, 'filled', 'DisplayName', 'Control');
scatter(score(labels == 1, 1), score(labels == 1, 2), 36, microwave_color, 'filled', 'DisplayName', 'Microwave');
scatter(score(labels == 2, 1), score(labels == 2, 2), 36, uv_color, 'filled', 'DisplayName', 'UV');
hold off;
title(['2D PCA Score Plot (' method_name ')']);
xlabel(['PC 1 (' num2str(explained(1), '%.2f') '%)']);
ylabel(['PC 2 (' num2str(explained(2), '%.2f') '%)']);
legend show;
grid on;

%% Plot 4: 3D PCA Score Plot 
figure('Name', ['3D PCA (' method_name ')'], 'Color', 'w');
hold on;
scatter3(score(labels == 0, 1), score(labels == 0, 2), score(labels == 0, 3), 36, control_color, 'filled', 'DisplayName', 'Control');
scatter3(score(labels == 1, 1), score(labels == 1, 2), score(labels == 1, 3), 36, microwave_color, 'filled', 'DisplayName', 'Microwave');
scatter3(score(labels == 2, 1), score(labels == 2, 2), score(labels == 2, 3), 36, uv_color, 'filled', 'DisplayName', 'UV');
hold off;
title(['3D PCA Score Plot (' method_name ')']);
xlabel(['PC 1 (' num2str(explained(1), '%.2f') '%)']);
ylabel(['PC 2 (' num2str(explained(2), '%.2f') '%)']);
zlabel(['PC 3 (' num2str(explained(3), '%.2f') '%)']);
legend show;
grid on;
view(3);
rotate3d on;

%% Plot 5: PCA Loadings Plot 
figure('Name', ['Loadings (' method_name ')'], 'Color', 'w');
hold on;
plot(wavenumber, coeff(:, 1), 'LineWidth', 2, 'DisplayName', 'PC1 Loadings');
plot(wavenumber, coeff(:, 2), 'LineWidth', 2, 'DisplayName', 'PC2 Loadings');
plot(wavenumber, coeff(:, 3), 'LineWidth', 2, 'DisplayName', 'PC3 Loadings');
hold off;
yline(0, 'k--', 'HandleVisibility', 'off');
title(['PCA Loadings (' method_name ')']);
xlabel('Wavenumber (cm^{-1})');
ylabel('Loading Weight');
legend show;
grid on;

fprintf('Visualization and PCA for preprocessed data complete.\n');

%% SECTION 6: PLS-DA CLASSIFICATION 
% 1. Define Parameters
test_set_size = 0.3;    % Use 30% of the data for testing
max_components = min(8, size(preproc_data,1)-1);

disp('Starting PLS-DA Classification on Raman Data...');

% 2. Split Data into Training and Test Sets
cv = cvpartition(labels, 'HoldOut', test_set_size);
train_idx = cv.training;
test_idx = cv.test;
X_train = preproc_data(train_idx, :);
Y_train = labels(train_idx);
X_test = preproc_data(test_idx, :);
Y_test = labels(test_idx);
fprintf('Data split: %d training samples, %d test samples.\n', size(X_train, 1), size(X_test, 1));

% 3. Prepare Labels for PLS-DA 
Y_train_oh = dummyvar(Y_train + 1);
Y_test_oh = dummyvar(Y_test + 1);

% 4. Find the Optimal Number of Components
mse_values = zeros(max_components, 1);
fprintf('Finding optimal number of components (1 to %d)...\n', max_components);
for ncomp = 1:max_components
    [~, ~, ~, ~, beta] = plsregress(X_train, Y_train_oh, ncomp);
    Y_pred = [ones(size(X_test, 1), 1), X_test] * beta;
    mse_values(ncomp) = mean(mean((Y_pred - Y_test_oh).^2));
end
[~, best_ncomp] = min(mse_values);
fprintf('Optimal number of components found: %d\n', best_ncomp);

% 5. Train and Evaluate the Final Model 
[~, ~, ~, ~, final_beta] = plsregress(X_train, Y_train_oh, best_ncomp);
% Predictions on the TEST set 
Y_pred_scores_test = [ones(size(X_test, 1), 1), X_test] * final_beta;
[~, class_indices_test] = max(Y_pred_scores_test, [], 2);
predicted_labels_test = class_indices_test - 1;
accuracy_pls_test = mean(predicted_labels_test == Y_test);
conf_mat_pls_test = confusionmat(Y_test, predicted_labels_test);
% Predictions on the TRAINING set 
Y_pred_scores_train = [ones(size(X_train, 1), 1), X_train] * final_beta;
[~, class_indices_train] = max(Y_pred_scores_train, [], 2);
predicted_labels_train = class_indices_train - 1;
accuracy_pls_train = mean(predicted_labels_train == Y_train);
conf_mat_pls_train = confusionmat(Y_train, predicted_labels_train);

% 6. Display Results 
fprintf('\n===== PLS-DA Results (Raman Data) =====\n');
fprintf('Optimal Components: %d\n', best_ncomp);
fprintf('\n--- Performance on TRAINING Set ---\n');
fprintf('Accuracy: %.2f%%\n', accuracy_pls_train * 100);
disp('Confusion Matrix:');
disp(conf_mat_pls_train);
fprintf('\n--- Performance on TEST Set ---\n');
fprintf('Accuracy: %.2f%%\n', accuracy_pls_test * 100);
disp('Confusion Matrix:');
disp(conf_mat_pls_test);

% 7. Plotting
% Plot 1: Component Optimization Plot
figure('Name', 'Raman PLS-DA Component Optimization', 'Color', 'w');
plot(1:max_components, mse_values, 'b-o', 'LineWidth', 1.5);
hold on;
plot(best_ncomp, mse_values(best_ncomp), 'ro', 'MarkerSize', 10, 'LineWidth', 2);
xlabel('Number of PLS Components');
ylabel('Mean Squared Error (MSE) on Test Set');
title('PLS-DA Model Performance vs. Complexity');
legend('MSE per component', 'Optimal Component', 'Location', 'best');
grid on;
hold off;

% Plot 2: Confusion Matrix for Test Set
figure('Name', 'Raman PLS-DA Confusion Matrix (Test Set)', 'Color', 'w');
confusionchart(Y_test, predicted_labels_test, ...
    'Title', ['Test Set Accuracy: ' num2str(accuracy_pls_test*100, '%.2f') '%'], ...
    'RowSummary', 'row-normalized', ...
    'ColumnSummary', 'column-normalized');

% Plot 3: Confusion Matrix for Training Set
figure('Name', 'Raman PLS-DA Confusion Matrix (Training Set)', 'Color', 'w');
confusionchart(Y_train, predicted_labels_train, ...
    'Title', ['Training Set Accuracy: ' num2str(accuracy_pls_train*100, '%.2f') '%'], ...
    'RowSummary', 'row-normalized', ...
    'ColumnSummary', 'column-normalized');

% Plot 4: Combined Beta Coefficient Plot
figure('Name', 'Raman PLS-DA Beta Coefficients (Overall Magnitude)', 'Color', 'w');
beta_coeffs_mag = final_beta(2:end, :);
single_beta_curve_mag = sqrt(sum(beta_coeffs_mag.^2, 2));
plot(wavenumber, single_beta_curve_mag, 'b', 'LineWidth', 1.5);
yline(0, 'k--', 'HandleVisibility','off');
title('Overall Importance of Wavenumbers (Beta Coefficients)');
xlabel('Wavenumber (cm^{-1})');
ylabel('Coefficient Magnitude');
grid on;


%% SECTION 7: SVM CLASSIFICATION 
disp('Starting SVM Classification on Raman Data...');

% 1. Train the SVM Model with Automatic Hyperparameter Optimization
% Create an SVM template to specify the Gaussian kernel.
t = templateSVM('KernelFunction', 'gaussian');

% Train the multi-class SVM, automatically finding the best parameters.
fprintf('Training SVM model and optimizing hyperparameters (this may take a minute)...\n');
svm_model = fitcecoc(X_train, Y_train, 'Learners', t, ...
    'OptimizeHyperparameters', 'auto', ...
    'HyperparameterOptimizationOptions', struct('AcquisitionFunctionName', ...
    'expected-improvement-plus', 'ShowPlots', false, 'Verbose', 1));

% 2. Make Predictions
predicted_labels_svm_train = predict(svm_model, X_train);
predicted_labels_svm_test = predict(svm_model, X_test);

% 3. Evaluate Performance
accuracy_svm_train = mean(predicted_labels_svm_train == Y_train);
conf_mat_svm_train = confusionmat(Y_train, predicted_labels_svm_train);
accuracy_svm_test = mean(predicted_labels_svm_test == Y_test);
conf_mat_svm_test = confusionmat(Y_test, predicted_labels_svm_test);

% 4. Display Results
fprintf('\n===== Optimized SVM Results (Raman Data) =====\n');
fprintf('\n--- Performance on TRAINING Set ---\n');
fprintf('Accuracy: %.2f%%\n', accuracy_svm_train * 100);
disp('Confusion Matrix:');
disp(conf_mat_svm_train);
fprintf('\n--- Performance on TEST Set ---\n');
fprintf('Accuracy: %.2f%%\n', accuracy_svm_test * 100);
disp('Confusion Matrix:');
disp(conf_mat_svm_test);

% 5. Plotting
% Plot 1: Confusion Matrix for Test Set
figure('Name', 'Raman SVM Confusion Matrix (Test Set)', 'Color', 'w');
confusionchart(Y_test, predicted_labels_svm_test, ...
    'Title', ['Optimized SVM Test Set Accuracy: ' num2str(accuracy_svm_test*100, '%.2f') '%'], ...
    'RowSummary', 'row-normalized', 'ColumnSummary', 'column-normalized');

% Plot 2: Confusion Matrix for Training Set
figure('Name', 'Raman SVM Confusion Matrix (Training Set)', 'Color', 'w');
confusionchart(Y_train, predicted_labels_svm_train, ...
    'Title', ['Optimized SVM Training Set Accuracy: ' num2str(accuracy_svm_train*100, '%.2f') '%'], ...
    'RowSummary', 'row-normalized', 'ColumnSummary', 'column-normalized');

% Plot 3: Linear SVM Beta Coefficients for Feature Importance
% NOTE: We train a separate LINEAR SVM here because only linear models
% have simple, directly interpretable beta coefficients. This plot shows
% which wavenumbers are most important to a linear classifier.
figure('Name', 'Raman Linear SVM Beta Coefficients', 'Color', 'w');

fprintf('Training a separate Linear SVM to analyze feature importance...\n');
% Train a linear SVM model on the full training data
linear_svm_model = fitcecoc(X_train, Y_train, 'Learners', 'linear');

% The model automatically creates binary learners for each pair of classes.
% We will inspect the coefficients for the 'Control (0) vs Microwave (1)' learner.
ctrl_vs_mw_learner = linear_svm_model.BinaryLearners{1}; 

% Extract the beta coefficients from this learner
beta_coeffs_svm = ctrl_vs_mw_learner.Beta;

plot(wavenumber, beta_coeffs_svm, 'b', 'LineWidth', 1.5);
yline(0, 'k--', 'HandleVisibility','off');
title('Linear SVM Beta Coefficients (Control vs. Microwave)');
xlabel('Wavenumber (cm^{-1})');
ylabel('Beta Coefficient');
grid on;

%% SECTION 8: FINAL MODEL VALIDATION 
%1. Define Validation Parameters
k = 10;                     % Number of folds for cross-validation
n_permutations = 500;       % Number of permutations for the significance test
models_to_run = {'PLSDA', 'SVM'};
model_names_for_plot = {'PLS-DA', 'SVM'};
cv = cvpartition(labels, 'KFold', k, 'Stratify', true);

% 2. Initialize Storage for Results
final_results = struct();

% 3. Start the Validation Loop for Each Model
for i = 1:length(models_to_run)
    current_model = models_to_run{i};
    fprintf('\n===== Starting Validation for %s =====\n', model_names_for_plot{i});
    
    % 10-Fold Cross-Validation
    fold_accuracies = zeros(k, 1);
    for fold = 1:k
        trainIdx = cv.training(fold);
        testIdx = cv.test(fold);
        X_train_cv = preproc_data(trainIdx, :);
        Y_train_cv = labels(trainIdx);
        X_test_cv = preproc_data(testIdx, :);
        Y_test_cv = labels(testIdx);
        
        if strcmp(current_model, 'PLSDA')
            Y_train_cv_oh = dummyvar(Y_train_cv + 1);
            [~,~,~,~,beta_cv] = plsregress(X_train_cv, Y_train_cv_oh, best_ncomp);
            scores_cv = [ones(size(X_test_cv,1),1), X_test_cv] * beta_cv;
            [~,preds_cv] = max(scores_cv, [], 2);
            predicted_labels_cv = preds_cv - 1;
        elseif strcmp(current_model, 'SVM')
            svm_model_cv = fitcecoc(X_train_cv, Y_train_cv, 'Learners', t, ...
                'OptimizeHyperparameters', 'auto', ...
                'HyperparameterOptimizationOptions', struct('AcquisitionFunctionName',...
                'expected-improvement-plus', 'ShowPlots', false, 'Verbose', 0));
            predicted_labels_cv = predict(svm_model_cv, X_test_cv);
        end
        
        fold_accuracies(fold) = mean(predicted_labels_cv == Y_test_cv);
        fprintf('  Fold %d/%d Accuracy: %.2f%%\n', fold, k, fold_accuracies(fold)*100);
    end
    
    mean_cv_accuracy = mean(fold_accuracies);
    std_cv_accuracy = std(fold_accuracies);
    
    % Permutation Testing
    fprintf('  Running Permutation Test (%d iterations)...\n', n_permutations);
    null_accuracies = zeros(n_permutations, 1);
    for p = 1:n_permutations
        shuffled_labels = labels(randperm(length(labels)));
        cv_perm = cvpartition(shuffled_labels, 'HoldOut', 0.3);
        X_train_p = preproc_data(cv_perm.training,:);
        Y_train_p = shuffled_labels(cv_perm.training);
        X_test_p = preproc_data(cv_perm.test,:);
        Y_test_p = shuffled_labels(cv_perm.test);
        
        if strcmp(current_model, 'PLSDA')
            Y_train_p_oh = dummyvar(Y_train_p + 1);
            [~,~,~,~,beta_p] = plsregress(X_train_p, Y_train_p_oh, best_ncomp);
            scores_p = [ones(size(X_test_p,1),1), X_test_p] * beta_p;
            [~,preds_p] = max(scores_p, [], 2);
            predicted_labels_p = preds_p - 1;
        elseif strcmp(current_model, 'SVM')
            svm_model_p = fitcecoc(X_train_p, Y_train_p, 'Learners', t);
            predicted_labels_p = predict(svm_model_p, X_test_p);
        end
        
        null_accuracies(p) = mean(predicted_labels_p == Y_test_p);
    end
    
    p_value = sum(null_accuracies >= mean_cv_accuracy) / n_permutations;
    
    % Results
    final_results.(current_model).MeanAccuracy = mean_cv_accuracy;
    final_results.(current_model).StdAccuracy = std_cv_accuracy;
    final_results.(current_model).PValue = p_value;
    
    fprintf('  Validation Complete for %s.\n', model_names_for_plot{i});
    fprintf('  Mean CV Accuracy: %.2f%% (+/- %.2f%%)\n', mean_cv_accuracy*100, std_cv_accuracy*100);
    fprintf('  p-value: %.4f\n', p_value);
end
