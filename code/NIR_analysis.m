%% ======================== SECTION 1: DATA LOADING & AVERAGING ========================
clc; clear; close all;  % Clear workspace

% Define folder paths (relative to this script's own location, so the
% code runs the same on any machine/OS once the repo is cloned).
% Assumes the repo layout: code/NIR_new.m alongside data/nir/<group>/
script_dir = fileparts(mfilename('fullpath'));
data_root  = fullfile(script_dir, '..', 'data', 'nir');

control_folder   = fullfile(data_root, 'control');
microwave_folder = fullfile(data_root, 'microwave');
uv_folder        = fullfile(data_root, 'uv');

% Define common wavelength axis for interpolation
common_wavelength = 900:0.5:1700; 

% Load, interpolate, and average the scans for each group
disp('Processing Control samples (Label 0)...');
[control_means, control_labels] = loadAndAverageScans(control_folder, 0, common_wavelength);

disp('Processing Microwave samples (Label 1)...');
[microwave_means, microwave_labels] = loadAndAverageScans(microwave_folder, 1, common_wavelength);

disp('Processing UV samples (Label 2)...');
[uv_means, uv_labels] = loadAndAverageScans(uv_folder, 2, common_wavelength);

% Combine the averaged data from all groups into the final dataset
absorbance_data = [control_means; microwave_means; uv_means];
labels = [control_labels; microwave_labels; uv_labels];

fprintf('\nData loading and averaging complete.\n');
fprintf('Total number of seeds processed: %d\n', size(absorbance_data, 1));
fprintf('  - Control:   %d seeds\n', size(control_means, 1));
fprintf('  - Microwave: %d seeds\n', size(microwave_means, 1));
fprintf('  - UV:        %d seeds\n', size(uv_means, 1));

%% ================= SECTION 2: VISUALIZATION OF AVERAGED SPECTRA =================
% Define colors for each treatment group for consistency in plots
control_color = [0, 0, 1]; % Blue
microwave_color = [1, 0, 0]; % Red
uv_color = [0, 1, 0]; % Green

%% Plot 1: All 300 Seed-Averaged Spectra Together
figure('Name', 'All Seed-Mean Spectra', 'Color', 'w');
hold on;


plot(common_wavelength, absorbance_data(labels == 0, :)', 'Color', [control_color, 0.3]);
plot(common_wavelength, absorbance_data(labels == 1, :)', 'Color', [microwave_color, 0.3]);
plot(common_wavelength, absorbance_data(labels == 2, :)', 'Color', [uv_color, 0.3]);

h1 = plot(NaN, NaN, 'Color', control_color, 'LineWidth', 2.5);
h2 = plot(NaN, NaN, 'Color', microwave_color, 'LineWidth', 2.5);
h3 = plot(NaN, NaN, 'Color', uv_color, 'LineWidth', 2.5);

hold off;
title('Mean spectra of all seeds grouped by treatment');
xlabel('Wavelength (nm)');
ylabel('Absorbance (AU)');
legend([h1, h2, h3], {'Control', 'Microwave', 'UV'}, 'Location', 'best');
grid on;

%% Plot 2: Grand Mean Spectra of the Three Treatments
figure('Name', 'Grand Mean Spectra Comparison', 'Color', 'w');
hold on;

% Calculate and plot the grand mean for each treatment
mean_control = mean(absorbance_data(labels == 0, :), 1);
plot(common_wavelength, mean_control, 'Color', control_color, 'LineWidth', 2.5, 'DisplayName', 'Control');

mean_microwave = mean(absorbance_data(labels == 1, :), 1);
plot(common_wavelength, mean_microwave, 'Color', microwave_color, 'LineWidth', 2.5, 'DisplayName', 'Microwave');

mean_uv = mean(absorbance_data(labels == 2, :), 1);
plot(common_wavelength, mean_uv, 'Color', uv_color, 'LineWidth', 2.5, 'DisplayName', 'UV');

hold off;
title('Mean spectra for each treatment');
xlabel('Wavelength (nm)');
ylabel('Absorbance (AU)');
legend show;
grid on;


%% ======== SECTION 3: PRINCIPAL COMPONENT ANALYSIS (PCA) ON RAW DATA ========
disp('Performing PCA on raw and seed-mean data');

% Perform PCA on the absorbance data
[coeff, score, latent] = pca(absorbance_data);

% Manually calculate the 'explained' variance percentage from the 'latent' variable.
explained = 100 * latent / sum(latent);

%% Plot 1: 2D PCA Score Plot
% This plot shows how the seeds cluster in the space of the first two PCs.
figure('Name', '2D PCA Score Plot (Raw Data)', 'Color', 'w');
hold on;
scatter(score(labels == 0, 1), score(labels == 0, 2), 36, control_color, 'filled', 'DisplayName', 'Control');
scatter(score(labels == 1, 1), score(labels == 1, 2), 36, microwave_color, 'filled', 'DisplayName', 'Microwave');
scatter(score(labels == 2, 1), score(labels == 2, 2), 36, uv_color, 'filled', 'DisplayName', 'UV');
hold off;

title('2D PCA Score Plot of Raw Data');
xlabel(['Principal Component 1 (' num2str(explained(1), '%.2f') '%)']);
ylabel(['Principal Component 2 (' num2str(explained(2), '%.2f') '%)']);
legend show;
grid on;

%% Plot 2: 3D PCA Score Plot
% A 3D view can sometimes reveal separation not visible in 2D.
figure('Name', '3D PCA Score Plot (Raw Data)', 'Color', 'w');
hold on;
scatter3(score(labels == 0, 1), score(labels == 0, 2), score(labels == 0, 3), 36, control_color, 'filled', 'DisplayName', 'Control');
scatter3(score(labels == 1, 1), score(labels == 1, 2), score(labels == 1, 3), 36, microwave_color, 'filled', 'DisplayName', 'Microwave');
scatter3(score(labels == 2, 1), score(labels == 2, 2), score(labels == 2, 3), 36, uv_color, 'filled', 'DisplayName', 'UV');
hold off;

title('3D PCA Score Plot of Raw Data');
xlabel(['PC 1 (' num2str(explained(1), '%.2f') '%)']);
ylabel(['PC 2 (' num2str(explained(2), '%.2f') '%)']);
zlabel(['PC 3 (' num2str(explained(3), '%.2f') '%)']);
legend show;
grid on;
view(3); % Set the default view to 3D
rotate3d on; % Allow interactive rotation

%% Plot 3: PCA Loadings Plot
% This plot shows which wavelengths are most important for each PC.
% Peaks (positive or negative) indicate influential wavelengths.
figure('Name', 'PCA Loadings (Raw Data)', 'Color', 'w');
hold on;
plot(common_wavelength, coeff(:, 1), 'LineWidth', 2, 'DisplayName', 'PC1 Loadings');
plot(common_wavelength, coeff(:, 2), 'LineWidth', 2, 'DisplayName', 'PC2 Loadings');
plot(common_wavelength, coeff(:, 3), 'LineWidth', 2, 'DisplayName', 'PC3 Loadings');
hold off;
yline(0, 'k--', 'HandleVisibility', 'off'); % Add a zero line for reference

title('PCA Loadings for First Three Components');
xlabel('Wavelength (nm)');
ylabel('Loading Weight');
legend show;
grid on;

fprintf('PCA analysis on raw data complete.\n');
%% ================= SECTION 4: SPECTRAL PREPROCESSING =================
% --- CHOOSE YOUR PREPROCESSING METHOD ---
% 1: Raw Data (No Preprocessing)
% 2: Standard Normal Variate (SNV) 
% 3: Multiplicative Scatter Correction (MSC) 
% 4: Savitzky-Golay 1st Derivative 
% 5: Savitzky-Golay 2nd Derivative 
% 6: SNV + Savitzky-Golay 1st Derivative 
preprocessing_choice = 2; % <--- CHANGE THIS NUMBER (1-6) TO TEST DIFFERENT METHODS

% --- Parameters for Savitzky-Golay ---
% (Only used if you choose option 4, 5, or 6)
sg_poly_order = 2;   % Polynomial order (typically 2 or 3)
sg_window_size = 11; % Window size (must be an odd number)

disp('Performing spectral preprocessing...');

% Apply selected preprocessing method
switch preprocessing_choice
    case 1 % Raw Data
        preproc_data = absorbance_data;
        method_name = 'Raw Data (No Preprocessing)';

    case 2 % SNV
        % Vectorized SNV is faster and cleaner than a for-loop
        mean_spectra = mean(absorbance_data, 2);
        std_spectra = std(absorbance_data, 0, 2);
        preproc_data = (absorbance_data - mean_spectra) ./ std_spectra;
        method_name = 'SNV';

    case 3 % MSC
        % Assumes you have the msc_preprocess.m helper function
        preproc_data = msc_preprocess(absorbance_data);
        method_name = 'MSC';

    case 4 % Savitzky-Golay 1st Derivative
        % Assumes your helper function is modified to accept parameters
        preproc_data = savgol_derivative(absorbance_data, sg_poly_order, sg_window_size, 1);
        method_name = 'SG 1st Derivative';
        
    case 5 % Savitzky-Golay 2nd Derivative
        preproc_data = savgol_derivative(absorbance_data, sg_poly_order, sg_window_size, 2);
        method_name = 'SG 2nd Derivative';

    case 6 % SNV + Savitzky-Golay 1st Derivative
        % First, apply SNV
        mean_spectra = mean(absorbance_data, 2);
        std_spectra = std(absorbance_data, 0, 2);
        snv_temp_data = (absorbance_data - mean_spectra) ./ std_spectra;
        % Then, apply SG derivative to the SNV-corrected data
        preproc_data = savgol_derivative(snv_temp_data, sg_poly_order, sg_window_size, 1);
        method_name = 'SNV + SG 1st Derivative';
        
    otherwise
        error('Invalid preprocessing_choice. Please choose a number from 1 to 6.');
end

fprintf('Preprocessing complete. Method used: %s\n', method_name);

%% ================= SECTION 5: PREPROCESSED DATA VISUALIZATION & PCA =================
% This section visualizes the data AFTER applying the preprocessing method
% selected in Section 4. Rerun this section after changing the choice in Section 4.

disp(['Visualizing data preprocessed with: ' method_name]);

% Define colors for consistency
control_color = [0, 0, 1]; % Blue
microwave_color = [1, 0, 0]; % Red
uv_color = [0, 1, 0]; % Green

%% Plot 1: All 300 Preprocessed Spectra Together
figure('Name', ['All Spectra (' method_name ')'], 'Color', 'w');
hold on;

% Plot each group with its specific color
plot(common_wavelength, preproc_data(labels == 0, :)', 'Color', [control_color, 0.3]);
plot(common_wavelength, preproc_data(labels == 1, :)', 'Color', [microwave_color, 0.3]);
plot(common_wavelength, preproc_data(labels == 2, :)', 'Color', [uv_color, 0.3]);

h1 = plot(NaN, NaN, 'Color', control_color, 'LineWidth', 2.5);
h2 = plot(NaN, NaN, 'Color', microwave_color, 'LineWidth', 2.5);
h3 = plot(NaN, NaN, 'Color', uv_color, 'LineWidth', 2.5);

hold off;
title(['All Seed Spectra (' method_name ')']);
xlabel('Wavelength (nm)');
ylabel('Processed Absorbance Units');
legend([h1, h2, h3], {'Control', 'Microwave', 'UV'}, 'Location', 'best');
grid on;

%% Plot 2: Grand Mean of Preprocessed Spectra
figure('Name', ['Grand Means (' method_name ')'], 'Color', 'w');
hold on;

% Calculate and plot the grand mean for each treatment
plot(common_wavelength, mean(preproc_data(labels == 0, :), 1), 'Color', control_color, 'LineWidth', 2.5, 'DisplayName', 'Control');
plot(common_wavelength, mean(preproc_data(labels == 1, :), 1), 'Color', microwave_color, 'LineWidth', 2.5, 'DisplayName', 'Microwave');
plot(common_wavelength, mean(preproc_data(labels == 2, :), 1), 'Color', uv_color, 'LineWidth', 2.5, 'DisplayName', 'UV');

hold off;
title(['Grand Mean Spectra (' method_name ')']);
xlabel('Wavelength (nm)');
ylabel('Mean Processed Absorbance');
legend show;
grid on;

%% ======== PCA on Preprocessed Data ========
disp(['Performing PCA on data processed with: ' method_name]);

[coeff, score, latent] = pca(preproc_data);
explained = 100 * latent / sum(latent);

%% Plot 3: 2D PCA Score Plot (Preprocessed)
figure('Name', ['2D PCA (' method_name ')'], 'Color', 'w');
hold on;
scatter(score(labels == 0, 1), score(labels == 0, 2), 36, control_color, 'filled', 'DisplayName', 'Control');
scatter(score(labels == 1, 1), score(labels == 1, 2), 36, microwave_color, 'filled', 'DisplayName', 'Microwave');
scatter(score(labels == 2, 1), score(labels == 2, 2), 36, uv_color, 'filled', 'DisplayName', 'UV');
hold off;

title(['2D PCA Score Plot (' method_name ')']);
xlabel(['Principal Component 1 (' num2str(explained(1), '%.2f') '%)']);
ylabel(['Principal Component 2 (' num2str(explained(2), '%.2f') '%)']);
legend show;
grid on;

%% Plot 4: 3D PCA Score Plot (Preprocessed)
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

%% Plot 5: PCA Loadings Plot (Preprocessed)
figure('Name', ['Loadings (' method_name ')'], 'Color', 'w');
hold on;
plot(common_wavelength, coeff(:, 1), 'LineWidth', 2, 'DisplayName', 'PC1 Loadings');
plot(common_wavelength, coeff(:, 2), 'LineWidth', 2, 'DisplayName', 'PC2 Loadings');
plot(common_wavelength, coeff(:, 3), 'LineWidth', 2, 'DisplayName', 'PC3 Loadings');
hold off;
yline(0, 'k--', 'HandleVisibility', 'off');

title(['PCA Loadings (' method_name ')']);
xlabel('Wavelength (nm)');
ylabel('Loading Weight');
legend show;
grid on;

fprintf('Visualization and PCA for preprocessed data complete.\n');

%% ================= SECTION 6: PLS-DA CLASSIFICATION =================
% 1. Define Parameters
test_set_size = 0.3;    % Use 30% of the data for testing
max_components = 7;    % Test models with 1 up to 10 components

disp('Starting PLS-DA Classification...');

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
fprintf('\n===== PLS-DA Results =====\n');
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
figure('Name', 'PLS-DA Component Optimization', 'Color', 'w');
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
figure('Name', 'PLS-DA Confusion Matrix (Test Set)', 'Color', 'w');
confusionchart(Y_test, predicted_labels_test, ...
    'Title', ['Test Set Accuracy: ' num2str(accuracy_pls_test*100, '%.2f') '%'], ...
    'RowSummary', 'row-normalized', ...
    'ColumnSummary', 'column-normalized');

% Plot 3: Confusion Matrix for Training Set
figure('Name', 'PLS-DA Confusion Matrix (Training Set)', 'Color', 'w');
confusionchart(Y_train, predicted_labels_train, ...
    'Title', ['Training Set Accuracy: ' num2str(accuracy_pls_train*100, '%.2f') '%'], ...
    'RowSummary', 'row-normalized', ...
    'ColumnSummary', 'column-normalized');

% Plot 4: Combined Beta Coefficient Plot
% This plot shows the overall importance of each wavelength to the model.
figure('Name', 'PLS-DA Beta Coefficients', 'Color', 'w');

% Exclude the intercept (first row) from the beta coefficients
beta_coeffs = final_beta(2:end, :);

% To get a single curve, we calculate the magnitude (L2 norm) of the
% coefficients at each wavelength. This represents the overall importance.
single_beta_curve = sqrt(sum(beta_coeffs.^2, 2));

plot(common_wavelength, single_beta_curve, 'b', 'LineWidth', 1.5);
yline(0, 'k--', 'HandleVisibility','off'); % Add a zero line
title('Overall Importance of Wavelengths (Beta Coefficients)');
xlabel('Wavelength (nm)');
ylabel('Coefficient Magnitude');
grid on;

%% ================= SECTION 7: SVM CLASSIFICATION =================
disp('Starting SVM Classification...');

% 1. Train the SVM Model with Automatic Hyperparameter Optimization

% Create an SVM template. This is where we specify SVM-specific options
% like the Kernel Function. We set it to 'gaussian' here.
t = templateSVM('KernelFunction', 'gaussian');

% Now, call fitcecoc. We pass the data and the SVM template.
% 'OptimizeHyperparameters','auto' tells MATLAB to automatically find the
% best values for the SVM parameters (Box Constraint and Kernel Scale)
% to prevent overfitting and underfitting.
fprintf('Training SVM model and optimizing hyperparameters');
svm_model = fitcecoc(X_train, Y_train, 'Learners', t, ...
    'OptimizeHyperparameters', 'auto', ...
    'HyperparameterOptimizationOptions', struct('AcquisitionFunctionName', ...
    'expected-improvement-plus', 'ShowPlots', false, 'Verbose', 1));

% --- 2. Make Predictions ---
predicted_labels_svm_train = predict(svm_model, X_train);
predicted_labels_svm_test = predict(svm_model, X_test);

% --- 3. Evaluate Performance ---
accuracy_svm_train = mean(predicted_labels_svm_train == Y_train);
conf_mat_svm_train = confusionmat(Y_train, predicted_labels_svm_train);
accuracy_svm_test = mean(predicted_labels_svm_test == Y_test);
conf_mat_svm_test = confusionmat(Y_test, predicted_labels_svm_test);

% --- 4. Display Results ---
fprintf('\n===== Optimized SVM Results =====\n');
fprintf('\n--- Performance on TRAINING Set ---\n');
fprintf('Accuracy: %.2f%%\n', accuracy_svm_train * 100);
disp('Confusion Matrix:');
disp(conf_mat_svm_train);
fprintf('\n--- Performance on TEST Set ---\n');
fprintf('Accuracy: %.2f%%\n', accuracy_svm_test * 100);
disp('Confusion Matrix:');
disp(conf_mat_svm_test);

% --- 5. Plotting ---
% Plot 1: Confusion Matrix for Test Set
figure('Name', 'SVM Confusion Matrix (Test Set)', 'Color', 'w');
confusionchart(Y_test, predicted_labels_svm_test, ...
    'Title', ['SVM Test Set Accuracy: ' num2str(accuracy_svm_test*100, '%.2f') '%'], ...
    'RowSummary', 'row-normalized', ...
    'ColumnSummary', 'column-normalized');

% Plot 2: Confusion Matrix for Training Set
figure('Name', 'SVM Confusion Matrix (Training Set)', 'Color', 'w');
confusionchart(Y_train, predicted_labels_svm_train, ...
    'Title', ['SVM Training Set Accuracy: ' num2str(accuracy_svm_train*100, '%.2f') '%'], ...
    'RowSummary', 'row-normalized', ...
    'ColumnSummary', 'column-normalized');

% Plot 3: Linear SVM Beta Coefficients for Feature Importance
% NOTE: We train a separate LINEAR SVM because only linear models have
% simple, directly interpretable beta coefficients. This plot shows
% which wavelengths are most important to a linear classifier.
figure('Name', 'NIR Linear SVM Beta Coefficients', 'Color', 'w');

fprintf('Training a separate Linear SVM to analyze feature importance...\n');
% Train a linear SVM model on the full training data
linear_svm_model = fitcecoc(X_train, Y_train, 'Learners', 'linear');

% The model creates binary learners for each pair of classes.
% We will inspect the coefficients for the 'Control (0) vs Microwave (1)' learner.
% Note: The index {1} typically corresponds to the first pair of classes.
ctrl_vs_mw_learner = linear_svm_model.BinaryLearners{1};

% Extract the beta coefficients from this specific binary learner
beta_coeffs_svm = ctrl_vs_mw_learner.Beta;

plot(common_wavelength, beta_coeffs_svm, 'b', 'LineWidth', 1.5);
yline(0, 'k--', 'HandleVisibility','off');
title('SVM Beta Coefficient');
xlabel('Wavelength (nm)');
ylabel('Beta Coefficient');
grid on;


%% ================= SECTION 8: FINAL MODEL VALIDATION =================
% 1. Define Validation Parameters
k = 10;                     % Number of folds for cross-validation
n_permutations = 500;       % Number of permutations for the significance test
models_to_run = {'PLSDA', 'SVM'};
model_names_for_plot = {'PLS-DA', 'SVM'}; 

% Use the same cross-validation splits for all models for a fair comparison
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
        % Get indices for the current fold
        trainIdx = cv.training(fold);
        testIdx = cv.test(fold);
        
        % Get the data for the current fold
        X_train_cv = preproc_data(trainIdx, :);
        Y_train_cv = labels(trainIdx);
        X_test_cv = preproc_data(testIdx, :);
        Y_test_cv = labels(testIdx);
        
        % Train the specified model
        if strcmp(current_model, 'PLSDA')
            Y_train_cv_oh = dummyvar(Y_train_cv + 1);
            [~,~,~,~,beta_cv] = plsregress(X_train_cv, Y_train_cv_oh, best_ncomp);
            scores_cv = [ones(size(X_test_cv,1),1), X_test_cv] * beta_cv;
            [~,preds_cv] = max(scores_cv, [], 2);
            predicted_labels_cv = preds_cv - 1;
            
        elseif strcmp(current_model, 'SVM')
            t = templateSVM('KernelFunction', 'gaussian');
            svm_model_cv = fitcecoc(X_train_cv, Y_train_cv, 'Learners', t, ...
                'OptimizeHyperparameters', 'auto', ...
                'HyperparameterOptimizationOptions', struct('AcquisitionFunctionName',...
                'expected-improvement-plus', 'ShowPlots', false, 'Verbose', 0));
            predicted_labels_cv = predict(svm_model_cv, X_test_cv);
        end
        
        % Calculate and store the accuracy for this fold
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
            t = templateSVM('KernelFunction', 'gaussian');
            svm_model_p = fitcecoc(X_train_p, Y_train_p, 'Learners', t);
            predicted_labels_p = predict(svm_model_p, X_test_p);
        end
        
        null_accuracies(p) = mean(predicted_labels_p == Y_test_p);
    end
    
    p_value = sum(null_accuracies >= mean_cv_accuracy) / n_permutations;
    
    % Store Results
    
    final_results.(current_model).MeanAccuracy = mean_cv_accuracy;
    final_results.(current_model).StdAccuracy = std_cv_accuracy;
    final_results.(current_model).NullDistribution = null_accuracies;
    final_results.(current_model).PValue = p_value;
    
    fprintf('  Validation Complete for %s.\n', model_names_for_plot{i});
    fprintf('  Mean CV Accuracy: %.2f%% (+/- %.2f%%)\n', mean_cv_accuracy*100, std_cv_accuracy*100);
    fprintf('  p-value: %.4f\n', p_value);
end

