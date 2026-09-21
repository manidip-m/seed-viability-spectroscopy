%% ======================== HELPER FUNCTIONS ========================

function [seed_means, seed_labels] = loadAndAverageScans(folder_path, label, common_wavelength)
    % This function loads all CSV files, groups them by seed number,
    % averages the scans for each seed, and returns the mean spectra and labels.

    % Get a list of all csv files in the specified folder
    files = dir(fullfile(folder_path, '*.csv'));
    if isempty(files)
        error('No CSV files found in folder: %s', folder_path);
    end

    % Helper function to extract the seed number from a filename
    % Assumes format like 'ND_Ct_SEEDNUMBER_SCANNUMBER.csv'
    get_seed_number = @(name) str2double(regexp(name, '(?<=_)\d+(?=_)', 'match', 'once'));

    % Find all unique seed numbers present in the folder
    all_seed_numbers = arrayfun(get_seed_number, {files.name});
    unique_seeds = unique(all_seed_numbers);
    num_unique_seeds = length(unique_seeds);
    
    % Initialize matrices to store the final averaged data
    seed_means = zeros(num_unique_seeds, length(common_wavelength));
    seed_labels = repmat(label, num_unique_seeds, 1);

    % Loop through each unique seed
    for i = 1:num_unique_seeds
        current_seed_num = unique_seeds(i);
        
        % Find all file entries that match the current seed number
        is_current_seed = (all_seed_numbers == current_seed_num);
        seed_files = files(is_current_seed);
        num_scans_for_seed = length(seed_files);
        
        % Create a temporary matrix to hold all scans for this one seed
        temp_scan_data = zeros(num_scans_for_seed, length(common_wavelength));
        
        % Load and interpolate each scan for the current seed
        for j = 1:num_scans_for_seed
            file_path = fullfile(folder_path, seed_files(j).name);
            header_line = find_starts_with('***Scan Data***', file_path);
            T = readtable(file_path, 'HeaderLines', header_line, 'VariableNamingRule', 'preserve');
            
            wavelength = T.("Wavelength (nm)");
            absorbance = T.("Absorbance (AU)");
            
            % Interpolate the spectrum and store it
            temp_scan_data(j,:) = interp1(wavelength, absorbance, common_wavelength, 'pchip');
        end
        
        % Calculate the mean spectrum for the current seed and store it
        seed_means(i, :) = mean(temp_scan_data, 1);
        fprintf('  Processed Seed %d (averaged %d scans)\n', current_seed_num, num_scans_for_seed);
    end
end

% You should also have your 'find_starts_with' function here
% function header_line = find_starts_with(str, file_path) ... end