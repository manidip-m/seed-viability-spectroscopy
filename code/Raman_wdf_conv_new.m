%% ==================== IMPROVED RAMAN WDF-TO-MAT CONVERTER ====================
clc; clear; close all;
diary('raman_processing_log.txt'); % Log all output

% --- 1. Setup ---
% Define folders and their corresponding numeric labels
folders = {
    'C:\Users\mmani\Documents\UCD_Assignments\Thesis\Data\Raman\ND_Ct_Raman', 0; 
    'C:\Users\mmani\Documents\UCD_Assignments\Thesis\Data\Raman\ND_Mw_Raman', 1;
    'C:\Users\mmani\Documents\UCD_Assignments\Thesis\Data\Raman\ND_UV_Raman', 2
};

% QC Parameters
MIN_SIGNAL = 100;    % Minimum median intensity
MAX_SAT_PTS = 10;    % Max allowed saturated points

% --- 2. Initialize Master Containers ---
% We will build these lists directly to ensure they are always aligned.
all_spectra_list = {};   % Cell array for valid spectra
all_labels_list = [];    % Vector for corresponding labels
all_info_list = {};      % Cell array for corresponding filenames
common_wn = [];          % To store the reference wavenumber axis

fprintf('=== Starting Raman Dataset Processing ===\n');
fprintf('Start Time: %s\n', datetime('now'));

%% --- 3. Process Each Treatment Folder ---
for treatment_idx = 1:size(folders,1)
    current_folder = folders{treatment_idx,1};
    current_label = folders{treatment_idx,2};
    
    fprintf('\nProcessing %s files (Label %d)...\n', ...
        get_treatment_name(current_label), current_label);
    
    files = dir(fullfile(current_folder, '*.wdf'));
    if isempty(files)
        warning('No .wdf files found in: %s', current_folder);
        continue;
    end
    
    valid_count_in_folder = 0;
    
    % --- Process each file in the folder ---
    for file_idx = 1:length(files)
        filepath = fullfile(current_folder, files(file_idx).name);
        
        try
            % Read the WDF file and perform quality checks
            [spectrum, wn, qc_passed] = process_wdf_file(filepath, MIN_SIGNAL, MAX_SAT_PTS);
            
            % If the file is valid, add its data to our master lists
            if qc_passed
                % Set the common wavenumber axis from the first valid file
                if isempty(common_wn)
                    common_wn = wn;
                    fprintf('Reference wavenumbers set (%.1f to %.1f cm⁻¹)\n', min(wn), max(wn));
                end
                
                % Interpolate if wavenumbers don't match (optional but safe)
                if ~isequal(wn, common_wn)
                    spectrum = interp1(wn, spectrum, common_wn, 'pchip', 0);
                end
                
                % Append the valid data to our master lists
                all_spectra_list{end+1} = spectrum;
                all_labels_list(end+1) = current_label;
                all_info_list{end+1} = files(file_idx).name;
                
                valid_count_in_folder = valid_count_in_folder + 1;
            end
            
        catch ME
            fprintf(2, 'ERROR processing %s: %s\n', files(file_idx).name, ME.message);
        end
        
        % Progress update
        if mod(file_idx, 50) == 0 || file_idx == length(files)
            fprintf('  Processed %d/%d files...\n', file_idx, length(files));
        end
    end
    fprintf('Completed %s: %d/%d files passed QC and were added.\n', ...
        get_treatment_name(current_label), valid_count_in_folder, length(files));
end

%% --- 4. Consolidate and Save Final Data ---
fprintf('\nConsolidating all valid data...\n');
% Convert the cell array of spectra into a single matrix
all_spectra = vertcat(all_spectra_list{:});
% Ensure labels and info are column vectors
all_labels = all_labels_list';
all_info = all_info_list';

% Save the final, aligned variables to the .mat file
output_file = 'RamanDataset_Processed.mat';
save(output_file, 'all_spectra', 'all_labels', 'common_wn', 'all_info', ...
    'MIN_SIGNAL', 'MAX_SAT_PTS', '-v7.3');

fprintf('\n=== Processing Complete ===\n');
fprintf('End Time: %s\n', datetime('now'));
fprintf('Total valid spectra saved: %d\n', size(all_spectra,1));
fprintf('Final Class Distribution:\n');
fprintf('  - Control: %d\n  - Microwave: %d\n  - UV: %d\n', ...
    sum(all_labels==0), sum(all_labels==1), sum(all_labels==2));
fprintf('Successfully saved aligned data to: %s\n', output_file);
diary off; % Close log file

%% ==================== HELPER FUNCTIONS ====================
function name = get_treatment_name(label)
    names = {'Control', 'Microwave', 'UV'};
    if label >= 0 && label < length(names)
        name = names{label + 1};
    else
        name = 'Unknown';
    end
end

function [spectrum, wavenumbers, qc_passed] = process_wdf_file(filepath, min_signal, max_sat)
    % This helper function remains the same as your original version.
    % It is assumed you have the WdfReader function/class available.
    spectrum = [];
    wavenumbers = [];
    qc_passed = false;
    wdf = WdfReader(filepath);
    if wdf.Count > 1
        spectra = wdf.GetSpectra(1, wdf.Count, 'double');
        spectrum = mean(spectra, 1);
    else
        spectrum = wdf.GetSpectra(1, 1, 'double');
    end
    wavenumbers = wdf.GetXList();
    if median(spectrum) < min_signal || any(~isfinite(spectrum))
        wdf.Close(); return;
    end
    if ismethod(wdf, 'GetOriginFlags')
        [saturated, ~] = wdf.GetOriginFlags(1, wdf.Count);
        if numel(saturated) > max_sat
            wdf.Close(); return;
        end
    end
    qc_passed = true;
    wdf.Close();
end