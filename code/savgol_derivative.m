function deriv_data = savgol_derivative(data, poly_order, window_size, derivative_order)
    % This function applies a Savitzky-Golay filter to smooth the data
    % and optionally compute a derivative.
    % The parameters are now passed in as arguments.

    % First, apply the Savitzky-Golay smoothing filter.
    % The sgolayfilt function can operate on the entire matrix at once,
    % which is more efficient than a for-loop. The '2' at the end tells
    % it to filter along the second dimension (i.e., each row).
    smoothed_data = sgolayfilt(data, poly_order, window_size, [], 2);

    % If a derivative order greater than zero is specified, compute it.
    if derivative_order > 0
        % The diff function calculates the difference between adjacent elements.
        % The second '2' tells it to operate along dimension 2 (each row).
        % The third argument is the order of the derivative.
        deriv_data = diff(smoothed_data, derivative_order, 2);
        
        % NOTE: Taking a derivative shortens the data. To keep the matrix size
        % consistent, we pad the start of each row with zeros to add back the
        % columns that were lost.
        pad_size = derivative_order;
        deriv_data = padarray(deriv_data, [0, pad_size], 0, 'pre');
    else
        % If derivative order is 0, just return the smoothed data.
        deriv_data = smoothed_data;
    end
end