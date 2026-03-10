clearvars
close all
%%
Mode = "Autofit";   % Choose: Sim/Fit/Autofit
Lambda = 632.8e-9;
PrismDegree = 90; % (!) Still working on this
AutofitGranularity = 500;
DataFullPath = 'DeionizedWaterInGlass.xlsx'; % Data must be a .txt file with two columns: angle (in degree) and reflectance

% Parameters for N-layers: [n], [k], [d]. Put two limit values for auto-fitting, e.g., [nMin, nMax]
% Leave the square brackets empty to for unused layers.
InputLayers = {...
    % Layer #1 - Prism
    [1.5 1.9], [0], [0];
    % Layer #2 - Metal
    [0.11], [3.6352], [48.6]; 
    % Layer #3 - Sample
    [1.44], [0.257], [9.1];
    % Layer #4 - Sample
    [1.3333], [0], [0];
    [], [], [];
    [], [], [];
    [], [], [];
    [], [], [];
    [], [], []; ...
    [], [], []; ...
    };

% --- DO NOT EDIT BELOW ---

% Range of degree

if Mode == "Sim"
    ExperimentalData(:, 1) = 20 : 0.1 : 60 ;
    ExperimentalData(:, 2) = NaN;
    ThetaRange = ExperimentalData(:, 1);
else
    try ExperimentalData = readmatrix(DataFullPath);
        ThetaRange = ExperimentalData(:, 1);
    catch
        error("Experimental data not found or could not be loaded!");
    end
end
ThetaRange = deg2rad(ThetaRange);

InputLayers = InputLayers(any(~cellfun(@isempty, InputLayers), 2), :);     % Trim empty rows
NumOfLayers = height(InputLayers);
if cellfun(@(X) any(isnan(X) | ~isnumeric(X)), InputLayers)
    error('All parameter values must be numeric.');
end

if Mode == "Autofit"
    TwoValuesParams = cellfun(@(X) numel(X) == 2, InputLayers);
    if all(~TwoValuesParams, 'all')
        warning('Auto-fitting requires at least one parameter to be input as lower and upper limits.');
    end
    AutofitInterval = num2cell(cellfun(@(X) round(mean(X), 1, 'significant')/AutofitGranularity, InputLayers(TwoValuesParams)));
    InputLayers(TwoValuesParams) = cellfun(@(X, Y) X(1):Y:X(end), InputLayers(TwoValuesParams), ...
        AutofitInterval, UniformOutput = false);
    Layers = combvec(InputLayers{:});
    Layers = reshape(Layers, [], 3, size(Layers, 2));
else
    SingleValueParams = cellfun(@(X) numel(X) == 1, InputLayers);
    if any(~SingleValueParams, 'all')
        error('A range of values is given. Use auto-fitting instead.')
    end
    Layers = cell2mat(InputLayers);
end
Layers(:, 3, :) = 1e-9 * Layers(:, 3, :);
Layers(:, 4, :) = arrayfun(@(n, k) complex(n.^2 - k.^2, 2 .* n .* k), ...
    Layers(:, 1, :), Layers(:, 2, :)); % Dielectric constant
NumOfIterations = size(Layers, 3);

qCalculate = @(n1, e, th) sqrt( e - n1.^2 * sin(th).^2 ) ./ e;
betaCalculate = @(n1, d, e, th) (2*d*pi / Lambda) .* sqrt(e - n1.^2*sin(th).^2);

[RMSE, Corr2] = deal(NaN(size(Layers, 3), 1));
[R, T] = deal(NaN(length(ThetaRange), NumOfIterations));
BestSet = 1;
for s = 1 : NumOfIterations
    
    % Calculations
    Theta = pi/4 + asin( 1/Layers(1, 1, s) * sin(ThetaRange - pi/4) ); % !!!
%         Theta = pi/3 + asin( 1/Layers(1, 1, s) * sin(ThetaRange - pi/3) ); % !!!

    for t = 1 : length(Theta)
        
        q = qCalculate(Layers(1, 1, s), Layers(:, 4, s), Theta(t));
        Beta = betaCalculate(Layers(1, 1, s), Layers(:, 3, s), Layers(:, 4, s), Theta(t));
        for l = 2 : NumOfLayers - 1
            m(l, 1, 1) = cos(Beta(l));
            m(l, 1, 2) = -1i*sin(Beta(l)) / q(l);
            m(l, 2, 1) = -1i*sin(Beta(l)) * q(l);
            m(l, 2, 2) = cos(Beta(l));
        end
        
        M = [1 0; 0 1];
        for l = 2 : NumOfLayers - 1
            M1(:, :) = m(l, :, :);
            M = M * M1;
        end
        
        rp = ( (M(1, 1)+M(1, 2)*q(end))*q(1) - (M(2, 1)+M(2, 2)*q(end)) ) / ...
            ( (M(1, 1)+M(1, 2)*q(end))*q(1) + (M(2, 1)+M(2, 2)*q(end)) );
        tp = 2*q(1) / ( (M(1, 1)+M(1, 2)*q(end)) * q(1)+(M(2, 1)+M(2, 2)*q(end)) );
        R(t, s) = rp * conj(rp); % Reflectance
        T(t, s) = tp*conj(tp) / cos(Theta(t))*Layers(1, 1, s)*q(end); % Transmission
        
    end
    
    ThetaVecDeg = rad2deg(ThetaRange);
    if Mode ~= "Sim"
        % Correlation values
        Corr = corrcoef(ExperimentalData(:, 2), R(:, s));
        Corr2(s) = Corr(1, 2)^2;
        RMSE(s) = sqrt( sse(ExperimentalData(:, 2), R(:, s)) / (height(ExperimentalData) - 1) );
    end
    
    % Plotting
    if Mode ~= "Sim" && s == 1
        scatter(ExperimentalData(:, 1), ExperimentalData(:, 2) , 'r.', DisplayName = 'Experimental');
        hold on
    end
    
    if Mode == "Autofit"
        if RMSE(s) == min(RMSE)
            SmoothThetaVec = ThetaVecDeg(1) : 0.1 : ThetaVecDeg(end);
            SmoothR = spline(ThetaVecDeg, R(:, s), SmoothThetaVec);
            if exist('SimHndl', 'var')
                delete(SimHndl);
                delete(ParamHndl);
            end
            SimHndl = plot(SmoothThetaVec, SmoothR, 'b', DisplayName = 'Prediction');
            ParamHndl = annotation('textbox', [0.14,0.12,0.27,0.12], String = composeParams(s, Layers, RMSE, Corr2),...
                Interpreter = 'latex');
            drawnow;
            BestSet = s;
        end
    else
        SmoothThetaVec = ThetaVecDeg(1) : 0.1 : ThetaVecDeg(end);
        SmoothR = spline(ThetaVecDeg, R(:, s), SmoothThetaVec);
        SimHndl = plot(SmoothThetaVec, SmoothR, 'b', DisplayName = 'Prediction');
    end
    
    % Progress 
    ProgressPercent = round(100*s/NumOfIterations, 0); 
    if ~ rem(ProgressPercent, 2)
        if exist('ProgressHndl', 'var')
            delete(ProgressHndl);
        end
        ProgressHndl = annotation('textbox', String = sprintf('Auto-fitting progress: %d%%', ProgressPercent), ...
            EdgeColor = 'none', Position = [0.2, 0.1, 0.2, 0.2]);
        drawnow;
    end
        
end

delete(ProgressHndl);
legend;
if Mode ~= "Sim"
   disp('Best-fitting paramaters:'); 
   disp([Layers(:, 1:2, BestSet), Layers(:, 3, BestSet)/1e-9]);
end
    
%% Local functions
function ComposedText = composeParams(i, Layers, RMSE, Corr2)
    temp = Layers(:, :, i);
    temp(:, 3) = temp(:, 3) / 1e-9; 
    ComposedText = compose("RMSE = %.4f, $R^2 = %.4f$\n\n", RMSE(i), Corr2(i));
    for l = 1 : height(temp)
        ComposedText = ComposedText + compose( "Layer %d: $n = %.4f, \\kappa = %.4f, d = %.4f, \\varepsilon = %.4f + %.4fi$\n", ...
            l, temp(l, 1), temp(l, 2), temp(l, 3), real(temp(l, 4)), imag(temp(l, 4)) );
    end
end
