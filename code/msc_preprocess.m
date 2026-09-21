function msc_data = msc_preprocess(absorbance_data)
    % Compute the mean spectrum as the reference
    mean_spectrum = mean(absorbance_data, 1);
    
    % Perform MSC correction for each spectrum
    msc_data = zeros(size(absorbance_data));
    for i = 1:size(absorbance_data, 1)
        spectrum = absorbance_data(i, :);
        X = [mean_spectrum', ones(length(mean_spectrum), 1)]; % Regression matrix
        coeff = X \ spectrum'; % Solve coefficients
        corrected_spectrum = (spectrum - coeff(2)) / coeff(1);
        msc_data(i, :) = corrected_spectrum;
    end
end