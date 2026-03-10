classdef SPRSoftware_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                matlab.ui.Figure
        GridLayout              matlab.ui.container.GridLayout
        LeftPanel               matlab.ui.container.Panel
        SimulationPanel         matlab.ui.container.Panel
        FinerLabel_3            matlab.ui.control.Label
        CoarserLabel_2          matlab.ui.control.Label
        FinerLabel              matlab.ui.control.Label
        CoarserLabel            matlab.ui.control.Label
        FittingModeLabel        matlab.ui.control.Label
        FittingModeButtonGroup  matlab.ui.container.ButtonGroup
        AutoButton              matlab.ui.control.RadioButton
        ManualButton            matlab.ui.control.RadioButton
        OffButton               matlab.ui.control.RadioButton
        ResetRangesButton       matlab.ui.control.Button
        AutofitValueLabel       matlab.ui.control.Label
        AutofitRunButton        matlab.ui.control.Button
        dSlider                 matlab.ui.control.Slider
        nmSliderLabel           matlab.ui.control.Label
        dRightButton            matlab.ui.control.Button
        dLeftButton             matlab.ui.control.Button
        kSlider                 matlab.ui.control.Slider
        kLabel                  matlab.ui.control.Label
        kRightButton            matlab.ui.control.Button
        kLeftButton             matlab.ui.control.Button
        nSlider                 matlab.ui.control.Slider
        SliderLabel             matlab.ui.control.Label
        LayerSelectionDropDown  matlab.ui.control.DropDown
        ButtonTuningSlider      matlab.ui.control.Slider
        ButtonTuningLabel       matlab.ui.control.Label
        AutofitSlider           matlab.ui.control.Slider
        AutofitLabel            matlab.ui.control.Label
        nRightButton            matlab.ui.control.Button
        nLeftButton             matlab.ui.control.Button
        LayerParamUITable       matlab.ui.control.Table
        StatusLamp              matlab.ui.control.Lamp
        StatusTextArea          matlab.ui.control.TextArea
        SetupPanel              matlab.ui.container.Panel
        ResetApp                matlab.ui.control.Button
        PrismTypeDropDown       matlab.ui.control.DropDown
        PrismtypeDropDownLabel  matlab.ui.control.Label
        LambdaEditField         matlab.ui.control.NumericEditField
        nmLabel                 matlab.ui.control.Label
        PrismAngleEditField     matlab.ui.control.NumericEditField
        PrismangleLabel         matlab.ui.control.Label
        LoadDataTextArea        matlab.ui.control.TextArea
        LoadDataButton          matlab.ui.control.Button
        NumOfLayersSpinner      matlab.ui.control.Spinner
        NooflayersSpinnerLabel  matlab.ui.control.Label
        RightPanel              matlab.ui.container.Panel
        RightPanelGridLayout    matlab.ui.container.GridLayout
        TabGroup                matlab.ui.container.TabGroup
        MainTab                 matlab.ui.container.Tab
        MainTabGridLayout       matlab.ui.container.GridLayout
        InfoPanel               matlab.ui.container.Panel
        Slider                  matlab.ui.control.RangeSlider
        SliderLabel_2           matlab.ui.control.Label
        InfoTextArea            matlab.ui.control.EditField
        AppNameLabel            matlab.ui.control.Label
        MainUIAxes              matlab.ui.control.UIAxes
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end


    properties (Access = public)
        LayerList
        Lambda = 632.8e-9 
        PrismDegree = 60 % (!) Still working on this
        AutofitTuning = 50
        DataPath
        ParamRanges = {[0.001 3], [0 5], [0 100]}
        Layers = cell(10, 9)
        UsedLayers
        SelectedLayer
        ButtonTuningSize
        ParamTuningSize
        FittingMode
        ExperimentalData
        DefaultStatus = 'App is ready.'
        ScatterDataHndl
        LineSimulationHndl
        IsDataLoaded = false
        LayersTabExtended;
        ThetaRange
        SelectedCell
        ParamLetters = ["n", "k", "d"]
        ColumnIdx = [2, 5, 8]
        AppVersion = '1.0'
        AppShortName = 'PRISMA'
        AppFullName = 'Plasma Resonance Integrated Software with Model Auto-Fitting'
        SimHndl
    end


    methods (Access = private)

        function LayerList = listLayers(app)
            LayerList = "Layer " + string(1:app.NumOfLayersSpinner.Value);
        end

        function updateParamTable(app)
            app.UsedLayers = app.Layers(1:app.NumOfLayersSpinner.Value, :);
            app.LayerParamUITable.Data = app.UsedLayers;
        end

        function setInitialSlider(app, SetRange, SetValue)
            if SetRange
                [app.nSlider.Limits, app.kSlider.Limits, app.dSlider.Limits] = deal(app.ParamRanges{:});
            end
            if SetValue
                [app.Layers{:, 2}, app.nSlider.Value]  = deal(min(app.nSlider.Limits));
                [app.Layers{:, 5}, app.kSlider.Value]  = deal(min(app.kSlider.Limits));
                [app.Layers{:, 8}, app.dSlider.Value]  = deal(min(app.dSlider.Limits));
            end

        end

        function extendSliderRange(app, SliderValue, SliderHandle, Increment)
            if SliderValue >= SliderHandle.Limits(2)
                SliderHandle.Limits(2) = SliderHandle.Limits(2) + Increment;
                set(app.ResetRangesButton, Visible = 'on', Enable = 'on');
            end
        end

        function updateStatus(app, StatusText)
            app.StatusTextArea.Value = StatusText;
            StatusTimer = timer(StartDelay = 8, ...
                TimerFcn = @(~, ~) set(app.StatusTextArea, Value = app.DefaultStatus));
            start(StatusTimer);
        end

        function ScatterDataHndl = plotExperimentalData(app)
            ScatterDataHndl = scatter(app.MainUIAxes, app.ExperimentalData(:, 1), ...
                app.ExperimentalData(:, 2), 'r.');
        end

        function setupMainAxes(app)
            set(app.MainUIAxes, Box = 'on');
        end

        function setupSimulation(app)
            if ~app.IsDataLoaded
                app.ExperimentalData(:, 1) = 30 : 0.1 : 70;
                app.ExperimentalData(:, 2) = NaN;
            end
        end

        function updateSliderValue(app)
            app.nSlider.Value = app.Layers{app.SelectedLayer, 2};
            app.kSlider.Value = app.Layers{app.SelectedLayer, 5};
            app.dSlider.Value = app.Layers{app.SelectedLayer, 8};
        end

        function sliderChangesTableSelection(app, ParamIdx)
            app.LayerParamUITable.Selection = [app.SelectedLayer, ParamIdx];
        end

        function simulateData(app, Mode)
            app.StatusLamp.Color = [1,0,0];
            app.StatusTextArea.Value = "Simulation in progress...";
            if strcmp(Mode, 'Auto')
                RelatedColumns = reshape(1:9, 3, 3)';
                for l = 1 : height(app.UsedLayers)
                    for c = 1 : height(RelatedColumns)
                        ReshapedLayers{l, c} = cell2mat(app.UsedLayers(l, RelatedColumns(c, :))); %#ok<*AGROW>
                        if  numel(ReshapedLayers{l, c}) == 3
                            ReshapedLayers{l, c}(2) = [];
                        end
                    end
                end
                LayersWithRanges = cellfun(@(X) numel(X) == 2, ReshapedLayers);
                AutofitInterval = num2cell(  cellfun( @(X) round(mean(X), 1, 'significant') ...
                    / app.AutofitSlider.Value, ReshapedLayers(LayersWithRanges) )  );
                AutofitVectors = ReshapedLayers;
                AutofitVectors(LayersWithRanges) = cellfun( @(X, Y) X(1) : Y : X(end), ...
                    AutofitVectors(LayersWithRanges), AutofitInterval, UniformOutput = false );
                SimulationLayers = combvec(AutofitVectors{:});
                SimulationLayers = reshape(SimulationLayers, [], 3, size(SimulationLayers, 2));
                SimulationLayers(:, 3, :) = 1e-9 * SimulationLayers(:, 3, :);
                SimulationLayers(:, 4, :) = arrayfun(@(n, k) complex(n.^2 - k.^2, 2 .* n .* k), ...
                    SimulationLayers(:, 1, :), SimulationLayers(:, 2, :)); % Dielectric constant         
                NumOfIterations = size(SimulationLayers, 3);
            elseif strcmp(Mode, 'Manual')
                for i = 1 : height(app.UsedLayers)
                    for j = 1 : width(app.UsedLayers)
                        if isempty(app.UsedLayers{i, j})
                            SimulationLayers(i, j) = NaN;
                        else
                            SimulationLayers(i, j) = app.UsedLayers{i, j};
                        end
                    end
                end
                SimulationLayers = SimulationLayers(:, [2, 5, 8]);
                SimulationLayers(:, 3, :) = 1e-9 * SimulationLayers(:, 3, :);
                SimulationLayers(:, 4, :) = arrayfun(@(n, k) complex(n.^2 - k.^2, 2 .* n .* k), ...
                    SimulationLayers(:, 1, :), SimulationLayers(:, 2, :)); % Dielectric constant
                NumOfIterations = 1;
            end

            qCalculate = @(n1, e, th) sqrt( e - n1.^2 * sin(th).^2 ) ./ e;
            betaCalculate = @(n1, d, e, th) (2*d*pi / app.Lambda) .* sqrt(e - n1.^2*sin(th).^2);

            ThetaRangeRad = deg2rad(app.ThetaRange);
            [RMSE, Corr2] = deal(NaN(NumOfIterations, 1));
            [R, T] = deal(NaN(length(ThetaRangeRad), NumOfIterations));
            BestSet = 1;

            for s = 1 : NumOfIterations
                % Calculations
                Theta = deg2rad(app.PrismDegree) + asin( 1/SimulationLayers(1, 1, s) * sin(ThetaRangeRad - deg2rad(app.PrismDegree)) ); % (!) WIP
                for t = 1 : length(Theta)
                    q = qCalculate(SimulationLayers(1, 1, s), SimulationLayers(:, 4, s), Theta(t));
                    Beta = betaCalculate(SimulationLayers(1, 1, s), SimulationLayers(:, 3, s), SimulationLayers(:, 4, s), Theta(t));
                    for l = 2 : height(SimulationLayers) - 1
                        m(l, 1, 1) = cos(Beta(l));
                        m(l, 1, 2) = -1i*sin(Beta(l)) / q(l);
                        m(l, 2, 1) = -1i*sin(Beta(l)) * q(l);
                        m(l, 2, 2) = cos(Beta(l));
                    end
                    M = [1 0; 0 1];
                    for l = 2 : height(SimulationLayers) - 1
                        M1(:, :) = m(l, :, :);
                        M = M * M1;
                    end
                    rp = ( (M(1, 1)+M(1, 2)*q(end))*q(1) - (M(2, 1)+M(2, 2)*q(end)) ) / ...
                        ( (M(1, 1)+M(1, 2)*q(end))*q(1) + (M(2, 1)+M(2, 2)*q(end)) );
                    tp = 2*q(1) / ( (M(1, 1)+M(1, 2)*q(end)) * q(1)+(M(2, 1)+M(2, 2)*q(end)) );
                    R(t, s) = rp * conj(rp); % Reflectance
                    T(t, s) = tp*conj(tp) / cos(Theta(t))*SimulationLayers(1, 1, s)*q(end); % Transmission
              
                end

                % Correlation values
                ThetaVecDeg = app.ThetaRange;
                Corr = corrcoef(app.ExperimentalData(:, 2), R(:, s));
                Corr2(s) = Corr(1, 2)^2;
                RMSE(s) = sqrt( sse(app.ExperimentalData(:, 2), R(:, s)) / (height(app.ExperimentalData) - 1) );

                % Plotting
                if (strcmp(Mode, 'Auto') && RMSE(s) == min(RMSE)) || strcmp(Mode, 'Manual')
                    SmoothThetaVec = ThetaVecDeg(1) : 0.1 : ThetaVecDeg(end);
                    SmoothR = spline(ThetaVecDeg, R(:, s), SmoothThetaVec);
                    try %#ok<TRYNC>
                        delete(app.SimHndl);
                        delete(ParamHndl);
                    end
                    hold(app.MainUIAxes, 'on');
                    app.SimHndl = plot(app.MainUIAxes, SmoothThetaVec, SmoothR, 'b', DisplayName = 'Prediction');
                    % ParamHndl = annotation('textbox', [0.14,0.12,0.27,0.12], String = composeParams(s, AutofitLayers, RMSE, Corr2),...
                    %     Interpreter = 'latex');
                    drawnow;
                    BestSet = s;

                    BestSetString = num2str(BestSet);
                    RMSEString = num2str(RMSE(BestSet));
                    app.InfoTextArea.Value = ['Runs = ' BestSetString];
                    app.InfoTextArea.Value = ['RMSE = ' RMSEString];
                end

                % SmoothThetaVec = ThetaVecDeg(1) : 0.1 : ThetaVecDeg(end);
                % SmoothR = spline(ThetaVecDeg, R(:, s), SmoothThetaVec);
                % SimHndl = plot(SmoothThetaVec, SmoothR, 'b', DisplayName = 'Prediction');

                % Progress
                if strcmp(Mode, 'Auto')
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


            end
            app.InfoTextArea.Value = sprintf('n1 = %.4f | n2 = %.4f | n3 = %.4f | k = %.4f', SimulationLayers(1,1,BestSet),SimulationLayers(2,1,BestSet),SimulationLayers(3,1,BestSet),SimulationLayers(2,2,BestSet));
            app.StatusLamp.Color = [0,1,0];
            app.StatusTextArea.Value = "Simulation completes.";
            app.LayerParamUITable.Data(1,2) = num2cell(SimulationLayers(1,1,BestSet));
            app.LayerParamUITable.Data(2,2) = num2cell(SimulationLayers(2,1,BestSet));
            app.LayerParamUITable.Data(3,2) = num2cell(SimulationLayers(3,1,BestSet));
            % app.LayerParamUITable.Data(1,5) = num2cell(SimulationLayers())
           
        end

    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.StatusTextArea.Value = app.DefaultStatus;
            app.UIFigure.Name = sprintf('%s v%s', app.AppShortName, app.AppVersion);
            app.AppNameLabel.Text = sprintf('%s (%s) v%s', app.AppFullName, app.AppShortName, app.AppVersion);
            app.LayerSelectionDropDown.Items = listLayers(app);
            app.LambdaEditField.Value = app.Lambda / 1e-9;
            app.PrismAngleEditField.Value = app.PrismDegree;
            app.SelectedLayer = app.NumOfLayersSpinner.Value;
            app.AutoButton.Enable = 'off';
            FittingModeButtonGroupSelectionChanged(app);

            TableColumnNames = {'𝑛₁', '𝑛', '𝑛₂', 'k₁', 'k', 'k₂', '𝑑₁', '𝑑', '𝑑₂'};
            set(app.LayerParamUITable, ColumnName = TableColumnNames, RowName = 'numbered', ...
                ColumnEditable = false, ColumnWidth = repelem({45}, 1, 9)) ;
           
            setInitialSlider(app, true, true);
            updateParamTable(app);
            set(app.ResetRangesButton, Visible = 'off', Enable = 'off');
            ButtonTuningSliderValueChanged(app);
            LayerSelectionDropDownValueChanged(app);
            setupMainAxes(app);
        end

        % Value changed function: ButtonTuningSlider
        function ButtonTuningSliderValueChanged(app, event)
            app.ButtonTuningSlider.Value = round(app.ButtonTuningSlider.Value, 0);
            app.ButtonTuningSize = app.ButtonTuningSlider.Value;
            app.ParamTuningSize = [mean(app.nSlider.Limits), mean(app.kSlider.Limits), mean(app.dSlider.Limits)] ... 
                / 10^app.ButtonTuningSize;
        end

        % Value changing function: AutofitSlider
        function AutofitSliderValueChanging(app, event)
            app.AutofitSlider.Value = round(event.Value, 0);
            app.AutofitValueLabel.Text = num2str(app.AutofitSlider.Value);
        end

        % Value changed function: NumOfLayersSpinner
        function NumOfLayersSpinnerValueChanged(app, event)
            app.UsedLayers = app.Layers(1:event.Value, :);
            app.LayerSelectionDropDown.Items = listLayers(app);
            updateParamTable(app);
        end

        % Value changing function: nSlider
        function nSliderValueChanging(app, event)
            app.Layers{app.SelectedLayer, 2} = event.Value;
            updateParamTable(app);
            sliderChangesTableSelection(app, 2);
            if app.ManualButton.Value
                simulateData(app,'Manual');
            end
        end

        % Value changed function: LayerSelectionDropDown
        function LayerSelectionDropDownValueChanged(app, event)
            app.SelectedLayer = str2double(erase(app.LayerSelectionDropDown.Value, "Layer "));
            updateSliderValue(app);
        end

        % Value changing function: kSlider
        function kSliderValueChanging(app, event)
            app.Layers{app.SelectedLayer, 5} = event.Value;
            updateParamTable(app);
            sliderChangesTableSelection(app, 5);
            if app.ManualButton.Value
                simulateData(app,'Manual');
            end
        end

        % Value changing function: dSlider
        function dSliderValueChanging(app, event)
            app.Layers{app.SelectedLayer, 8} = event.Value;
            updateParamTable(app);
            sliderChangesTableSelection(app, 8);
            if app.ManualButton.Value
                simulateData(app,'Manual');
            end
        end

        % Value changed function: nSlider
        function nSliderValueChanged(app, event)
            extendSliderRange(app, event.Value, app.nSlider, 0.5)
        end

        % Value changed function: kSlider
        function kSliderValueChanged(app, event)
            extendSliderRange(app, event.Value, app.kSlider, 0.5)
        end

        % Value changed function: dSlider
        function dSliderValueChanged(app, event)
            extendSliderRange(app, event.Value, app.dSlider, 5)
        end

        % Button pushed function: ResetRangesButton
        function ResetRangesButtonPushed(app, event)
            setInitialSlider(app, true, false);
            set(app.ResetRangesButton, Visible = 'off', Enable = 'off');
        end

        % Button pushed function: dLeftButton, dRightButton, kLeftButton, 
        % ...and 3 other components
        function TuningButtonPushed(app, event)
            PushedButton = event.Source.Tag;
            ColIdx = app.ColumnIdx(PushedButton(1) == app.ParamLetters);  
            ExtendValue = [0.5, 0.5, 5];
            Sign = PushedButton(2);
            sliderChangesTableSelection(app, ColIdx);

            if Sign == 'r'
                Change = + app.ParamTuningSize(PushedButton(1) == app.ParamLetters);
            else
                Change = - app.ParamTuningSize(PushedButton(1) == app.ParamLetters);
            end

            SliderName = PushedButton(1) + "Slider";
            NewValue = app.(SliderName).Value + Change;
            if NewValue > app.(SliderName).Limits(1) && NewValue < app.(SliderName).Limits(2)
                app.(SliderName).Value = NewValue;
                app.Layers{app.SelectedLayer, ColIdx} = app.(SliderName).Value;
            else
                extendSliderRange(app, NewValue, app.(SliderName), ExtendValue(ColIdx));
            end
            updateParamTable(app);
        end

        % Button pushed function: LoadDataButton
        function LoadDataButtonPushed(app, event)
            switch app.LoadDataButton.Text
                case 'Load data'
                    [DataName, app.DataPath] = uigetfile('*.*', 'Load experimental data');
                    figure(app.UIFigure);
                    DataFullPath = fullfile(app.DataPath, DataName);
                    try app.ExperimentalData = readmatrix(DataFullPath);
                        app.ExperimentalData = rmmissing(app.ExperimentalData);
                        app.ThetaRange = app.ExperimentalData(:, 1);
                        app.LoadDataTextArea.Value = DataFullPath;
                        app.LoadDataButton.Text = 'Clear data';
                        app.ScatterDataHndl = plotExperimentalData(app);
                        updateStatus(app, "Data has been loaded and plotted.");
                        app.IsDataLoaded = true;
                        app.AutoButton.Enable = 'on';
                    catch
                        updateStatus(app, "(!) Data could not be read. Only *.txt, *.xlsx, *.csv are supported.")
                    end
                case 'Clear data'
                    app.LoadDataTextArea.Value = '';
                    app.ExperimentalData = [];
                    app.LoadDataButton.Text = 'Load data';
                    delete(app.ScatterDataHndl);
                    app.IsDataLoaded = false;
                    app.AutoButton.Value = false;
                    app.AutoButton.Enable = 'off';
            end

        end

        % Selection changed function: FittingModeButtonGroup
        function FittingModeButtonGroupSelectionChanged(app, event)
            app.FittingMode = app.FittingModeButtonGroup.SelectedObject.Text;

            ManualFitGroup =  [app.nSlider, app.kSlider, app.dSlider, ...
                app.SliderLabel, app.kLabel, app.nmSliderLabel, ...
                app.nRightButton, app.nLeftButton, ...
                app.kLeftButton, app.kRightButton, app.dLeftButton, ...
                app.dRightButton, app.LayerSelectionDropDown, app.ButtonTuningLabel, ...
                app.ButtonTuningSlider];
            AutoFitGroup = [app.AutofitLabel, app.AutofitRunButton, app.AutofitSlider];
            set([ManualFitGroup, AutoFitGroup], Enable = 'off');
            set(ManualFitGroup, Enable = 'on');
            if strcmp(app.FittingMode, 'Auto')
                set(AutoFitGroup, Enable = 'on');
            end

            switch app.FittingMode
                case 'Manual'
                    InactiveColumnColor = uistyle(BackgroundColor = [0.9, 0.9, 0.9]);
                    addStyle(app.LayerParamUITable, InactiveColumnColor, 'column', ...
                        setdiff(1:9, app.ColumnIdx));
                case 'Auto'
                    app.LayerParamUITable.ColumnEditable( setdiff(1:9, app.ColumnIdx)) = true;
                    removeStyle(app.LayerParamUITable);
            end

        end

        % Cell edit callback: LayerParamUITable
        function LayerParamUITableCellEdit(app, event)
            % Validate input value
            NewData = str2double(event.NewData);
            if isnan(NewData)
                app.LayerParamUITable.Data{event.Indices(1), event.Indices(2)} = [];
                updateStatus(app, 'Please enter numeric value only.');
                return;
            end       
            app.Layers{event.Indices(1), event.Indices(2)} = NewData;
            app.UsedLayers = app.Layers(1:app.NumOfLayersSpinner.Value, :);
        end

        % Button pushed function: AutofitRunButton
        function AutofitRunButtonPushed(app, event)
            % Check error cells
            ErrorCellColor = uistyle('BackgroundColor', [1, 0.8, 0.8]);

            ErrorCell = false(size(app.UsedLayers));
            ErrorCellTimer = timer(StartDelay = 1, ...
                TimerFcn = @(~, ~) removeStyle(app.LayerParamUITable));

            IsNoLimitsEntered = all(cellfun(@isempty, app.UsedLayers(:, setdiff(1:9, app.ColumnIdx))), 'all');
            if IsNoLimitsEntered
                updateStatus(app, 'No limits were entered');
                ErrorCell(:, setdiff(1:9, app.ColumnIdx)) = true;
                [ErrorCellIdx(:, 1), ErrorCellIdx(:, 2)] = find(ErrorCell);
                addStyle(app.LayerParamUITable, ErrorCellColor, 'cell', ErrorCellIdx);
                start(ErrorCellTimer);
                return;
            end

            for l = 1 : height(app.UsedLayers)
                for c = app.ColumnIdx
                    if xor(isempty(app.UsedLayers{l, c-1}), isempty(app.UsedLayers{l, c+1}))                
                        ErrorCell(l, [c-1, c+1]) = true;
                    end
                    if all(~cellfun(@isempty, app.UsedLayers(l, [c-1, c+1]))) && ...
                            app.UsedLayers{l, c-1} > app.UsedLayers{l, c+1}
                        ErrorCell(l, [c-1, c+1]) = true;
                    end
                end
            end
            if any(ErrorCell, 'all')
                [ErrorCellIdx(:, 1), ErrorCellIdx(:, 2)] = find(ErrorCell);
                addStyle(app.LayerParamUITable, ErrorCellColor, 'cell', ErrorCellIdx);
                start(ErrorCellTimer);
                return;
            end

            simulateData(app, 'Auto');
            % Perform auto-fitting
            clearvars ReshapedLayersLimits
            RelatedColumns = reshape(1:9, 3, 3)';
            for l = 1 : height(app.UsedLayers)
                for c = 1 : height(RelatedColumns)
                    ReshapedLayers{l, c} = cell2mat(app.UsedLayers(l, RelatedColumns(c, :))); %#ok<*AGROW>
                    if  numel(ReshapedLayers{l, c}) == 3
                        ReshapedLayers{l, c}(2) = [];
                    end
                end
            end

            LayersWithRanges = cellfun(@(X) numel(X) == 2, ReshapedLayers);
            AutofitInterval = num2cell(  cellfun( @(X) round(mean(X), 1, 'significant') ...
                / app.AutofitSlider.Value, ReshapedLayers(LayersWithRanges) )  );
            AutofitVectors = ReshapedLayers;
            AutofitVectors(LayersWithRanges) = cellfun( @(X, Y) X(1) : Y : X(end), ...
                AutofitVectors(LayersWithRanges), AutofitInterval, UniformOutput = false );
            AutofitLayers = combvec(AutofitVectors{:});
            AutofitLayers = reshape(AutofitLayers, [], 3, size(AutofitLayers, 2));
            AutofitLayers(:, 3, :) = 1e-9 * AutofitLayers(:, 3, :);
            AutofitLayers(:, 4, :) = arrayfun(@(n, k) complex(n.^2 - k.^2, 2 .* n .* k), ...
                AutofitLayers(:, 1, :), AutofitLayers(:, 2, :)); % Dielectric constant
            NumOfIterations = size(AutofitLayers, 3);

            qCalculate = @(n1, e, th) sqrt( e - n1.^2 * sin(th).^2 ) ./ e;
            betaCalculate = @(n1, d, e, th) (2*d*pi / app.Lambda) .* sqrt(e - n1.^2*sin(th).^2);

            ThetaRangeRad = deg2rad(app.ThetaRange);
            [RMSE, Corr2] = deal(NaN(size(AutofitLayers, 3), 1));
            [R, T] = deal(NaN(length(ThetaRangeRad), NumOfIterations));
            BestSet = 1;

            for s = 1 : NumOfIterations
                % Calculations
                Theta = pi/4 + asin( 1/AutofitLayers(1, 1, s) * sin(ThetaRangeRad - pi/4) ); % (!) KIV
                for t = 1 : length(Theta)
                    q = qCalculate(AutofitLayers(1, 1, s), AutofitLayers(:, 4, s), Theta(t));
                    Beta = betaCalculate(AutofitLayers(1, 1, s), AutofitLayers(:, 3, s), AutofitLayers(:, 4, s), Theta(t));
                    for l = 2 : height(AutofitLayers) - 1
                        m(l, 1, 1) = cos(Beta(l));
                        m(l, 1, 2) = -1i*sin(Beta(l)) / q(l);
                        m(l, 2, 1) = -1i*sin(Beta(l)) * q(l);
                        m(l, 2, 2) = cos(Beta(l));
                    end
                    M = [1 0; 0 1];
                    for l = 2 : height(AutofitLayers) - 1
                        M1(:, :) = m(l, :, :);
                        M = M * M1;
                    end
                    rp = ( (M(1, 1)+M(1, 2)*q(end))*q(1) - (M(2, 1)+M(2, 2)*q(end)) ) / ...
                        ( (M(1, 1)+M(1, 2)*q(end))*q(1) + (M(2, 1)+M(2, 2)*q(end)) );
                    tp = 2*q(1) / ( (M(1, 1)+M(1, 2)*q(end)) * q(1)+(M(2, 1)+M(2, 2)*q(end)) );
                    R(t, s) = rp * conj(rp); % Reflectance
                    T(t, s) = tp*conj(tp) / cos(Theta(t))*AutofitLayers(1, 1, s)*q(end); % Transmission
                end

                % Correlation values
                ThetaVecDeg = app.ThetaRange;
                Corr = corrcoef(app.ExperimentalData(:, 2), R(:, s));
                Corr2(s) = Corr(1, 2)^2;
                RMSE(s) = sqrt( sse(app.ExperimentalData(:, 2), R(:, s)) / (height(app.ExperimentalData) - 1) );

                % Plotting
                if RMSE(s) == min(RMSE)
                    SmoothThetaVec = ThetaVecDeg(1) : 0.1 : ThetaVecDeg(end);
                    SmoothR = spline(ThetaVecDeg, R(:, s), SmoothThetaVec);
                    if exist('SimHndl', 'var')
                        delete(SimHndl);
                        delete(ParamHndl);
                    end
                    hold(app.MainUIAxes, 'on');
                    SimHndl = plot(app.MainUIAxes, SmoothThetaVec, SmoothR, 'b', DisplayName = 'Prediction');
                    % ParamHndl = annotation('textbox', [0.14,0.12,0.27,0.12], String = composeParams(s, AutofitLayers, RMSE, Corr2),...
                    %     Interpreter = 'latex');
                    drawnow;
                    BestSet = s;
                end

                    SmoothThetaVec = ThetaVecDeg(1) : 0.1 : ThetaVecDeg(end);
                    SmoothR = spline(ThetaVecDeg, R(:, s), SmoothThetaVec);
                    SimHndl = plot(app.MainUIAxes, SmoothThetaVec, SmoothR, 'b', DisplayName = 'Prediction');

                Progress
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

        end

        % Value changed function: LambdaEditField
        function LambdaEditFieldValueChanged(app, event)
            app.Lambda = app.LambdaEditField.Value * 1e-9;
        end

        % Selection changed function: LayerParamUITable
        function LayerParamUITableSelectionChanged(app, event)
            app.SelectedCell = app.LayerParamUITable.Selection;
            app.LayerSelectionDropDown.Value = app.LayerSelectionDropDown.Items(app.SelectedCell(1));
           
            LayerSelectionDropDownValueChanged(app);
           
            if strcmp(app.FittingMode, 'Manual') && ~any(app.SelectedCell(2) == app.ColumnIdx)
                ShiftedIdx = deflectCellSelection;
                app.LayerParamUITable.Selection(2) = ShiftedIdx;
            end

            app.LayerSelectionDropDown.FontWeight = 'bold';
            ObjectHighlighted = app.LayerSelectionDropDown; 
            if any(app.SelectedCell(2) == app.ColumnIdx)
                SliderNames = app.ParamLetters + "Slider";
                ParamIdx = find(app.SelectedCell(2) == app.ColumnIdx);
                app.(SliderNames(ParamIdx)).FontWeight = 'bold';
                ObjectHighlighted(end + 1) = app.(SliderNames(ParamIdx)); 
            end

            HighlightSliderTimer = timer(StartDelay = 1, TimerFcn = @(~, ~) set(ObjectHighlighted, ...
                FontWeight = 'normal'));
            start(HighlightSliderTimer);

            function ShiftedIdx = deflectCellSelection
                if any(app.SelectedCell(2) == [1, 4, 7])
                    IdxShift = +1;
                elseif any(app.SelectedCell(2) == [3, 6, 9])
                    IdxShift = -1;
                end
                ShiftedIdx = app.SelectedCell(2) + IdxShift;
            end
        end

        % Button pushed function: ResetApp
        function ResetAppPushed(app, event)
            cla(app.MainUIAxes)
            app.LayerParamUITable.Data{:,:} = [];
            app.Layers{:,:} = [];
            startupFcn(app)
        end

        % Value changed function: AutofitSlider
        function AutofitSliderValueChanged(app, event)
            value = app.AutofitSlider.Value;
        end

        % Display data changed function: LayerParamUITable
        function LayerParamUITableDisplayDataChanged(app, event)
      
            
        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.UIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {742, 742};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {483, '1x'};
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [93 93 1238 742];
            app.UIFigure.Name = 'PutraSPR';
            app.UIFigure.Icon = fullfile(pathToMLAPP, 'AppLogo.png');
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {483, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create SetupPanel
            app.SetupPanel = uipanel(app.LeftPanel);
            app.SetupPanel.TitlePosition = 'centertop';
            app.SetupPanel.Title = 'Setup';
            app.SetupPanel.FontWeight = 'bold';
            app.SetupPanel.FontSize = 13;
            app.SetupPanel.Position = [11 534 465 132];

            % Create NooflayersSpinnerLabel
            app.NooflayersSpinnerLabel = uilabel(app.SetupPanel);
            app.NooflayersSpinnerLabel.HorizontalAlignment = 'center';
            app.NooflayersSpinnerLabel.VerticalAlignment = 'top';
            app.NooflayersSpinnerLabel.Position = [13 80 80 20];
            app.NooflayersSpinnerLabel.Text = 'No. of layers';

            % Create NumOfLayersSpinner
            app.NumOfLayersSpinner = uispinner(app.SetupPanel);
            app.NumOfLayersSpinner.Limits = [1 10];
            app.NumOfLayersSpinner.ValueChangedFcn = createCallbackFcn(app, @NumOfLayersSpinnerValueChanged, true);
            app.NumOfLayersSpinner.Position = [10 58 86 22];
            app.NumOfLayersSpinner.Value = 3;

            % Create LoadDataButton
            app.LoadDataButton = uibutton(app.SetupPanel, 'push');
            app.LoadDataButton.ButtonPushedFcn = createCallbackFcn(app, @LoadDataButtonPushed, true);
            app.LoadDataButton.IconAlignment = 'center';
            app.LoadDataButton.Position = [10 18 68 29];
            app.LoadDataButton.Text = 'Load data';

            % Create LoadDataTextArea
            app.LoadDataTextArea = uitextarea(app.SetupPanel);
            app.LoadDataTextArea.Editable = 'off';
            app.LoadDataTextArea.Position = [84 18 295 30];

            % Create PrismangleLabel
            app.PrismangleLabel = uilabel(app.SetupPanel);
            app.PrismangleLabel.HorizontalAlignment = 'center';
            app.PrismangleLabel.VerticalAlignment = 'top';
            app.PrismangleLabel.Position = [189 77 85 22];
            app.PrismangleLabel.Text = 'Prism angle (°)';

            % Create PrismAngleEditField
            app.PrismAngleEditField = uieditfield(app.SetupPanel, 'numeric');
            app.PrismAngleEditField.Position = [187 57 89 22];

            % Create nmLabel
            app.nmLabel = uilabel(app.SetupPanel);
            app.nmLabel.HorizontalAlignment = 'center';
            app.nmLabel.VerticalAlignment = 'top';
            app.nmLabel.Position = [118 77 46 22];
            app.nmLabel.Text = '𝝀 (nm)';

            % Create LambdaEditField
            app.LambdaEditField = uieditfield(app.SetupPanel, 'numeric');
            app.LambdaEditField.ValueChangedFcn = createCallbackFcn(app, @LambdaEditFieldValueChanged, true);
            app.LambdaEditField.Position = [103 57 76 22];

            % Create PrismtypeDropDownLabel
            app.PrismtypeDropDownLabel = uilabel(app.SetupPanel);
            app.PrismtypeDropDownLabel.HorizontalAlignment = 'right';
            app.PrismtypeDropDownLabel.Position = [343 81 62 22];
            app.PrismtypeDropDownLabel.Text = 'Prism type';

            % Create PrismTypeDropDown
            app.PrismTypeDropDown = uidropdown(app.SetupPanel);
            app.PrismTypeDropDown.Items = {'Reflection', 'Non-reflection'};
            app.PrismTypeDropDown.Position = [288 58 172 22];
            app.PrismTypeDropDown.Value = 'Reflection';

            % Create ResetApp
            app.ResetApp = uibutton(app.SetupPanel, 'push');
            app.ResetApp.ButtonPushedFcn = createCallbackFcn(app, @ResetAppPushed, true);
            app.ResetApp.BackgroundColor = [0.9608 0.9608 0.9608];
            app.ResetApp.FontSize = 10;
            app.ResetApp.Position = [390 22 62 22];
            app.ResetApp.Text = 'Reset';

            % Create StatusTextArea
            app.StatusTextArea = uitextarea(app.LeftPanel);
            app.StatusTextArea.Editable = 'off';
            app.StatusTextArea.Position = [11 671 465 60];

            % Create StatusLamp
            app.StatusLamp = uilamp(app.LeftPanel);
            app.StatusLamp.Position = [450 703 21 21];

            % Create SimulationPanel
            app.SimulationPanel = uipanel(app.LeftPanel);
            app.SimulationPanel.TitlePosition = 'centertop';
            app.SimulationPanel.Title = 'Simulation';
            app.SimulationPanel.FontWeight = 'bold';
            app.SimulationPanel.FontSize = 13;
            app.SimulationPanel.Position = [11 11 465 520];

            % Create LayerParamUITable
            app.LayerParamUITable = uitable(app.SimulationPanel);
            app.LayerParamUITable.ColumnName = {''};
            app.LayerParamUITable.RowName = {};
            app.LayerParamUITable.ColumnEditable = true;
            app.LayerParamUITable.RowStriping = 'off';
            app.LayerParamUITable.CellEditCallback = createCallbackFcn(app, @LayerParamUITableCellEdit, true);
            app.LayerParamUITable.DisplayDataChangedFcn = createCallbackFcn(app, @LayerParamUITableDisplayDataChanged, true);
            app.LayerParamUITable.SelectionChangedFcn = createCallbackFcn(app, @LayerParamUITableSelectionChanged, true);
            app.LayerParamUITable.Multiselect = 'off';
            app.LayerParamUITable.Position = [9 355 443 105];

            % Create nLeftButton
            app.nLeftButton = uibutton(app.SimulationPanel, 'push');
            app.nLeftButton.ButtonPushedFcn = createCallbackFcn(app, @TuningButtonPushed, true);
            app.nLeftButton.Tag = 'nl';
            app.nLeftButton.Position = [9 264 26 24];
            app.nLeftButton.Text = '◀';

            % Create nRightButton
            app.nRightButton = uibutton(app.SimulationPanel, 'push');
            app.nRightButton.ButtonPushedFcn = createCallbackFcn(app, @TuningButtonPushed, true);
            app.nRightButton.Tag = 'nr';
            app.nRightButton.Position = [426 265 26 24];
            app.nRightButton.Text = '▶';

            % Create AutofitLabel
            app.AutofitLabel = uilabel(app.SimulationPanel);
            app.AutofitLabel.HorizontalAlignment = 'center';
            app.AutofitLabel.WordWrap = 'on';
            app.AutofitLabel.FontWeight = 'bold';
            app.AutofitLabel.Position = [198 66 71 30];
            app.AutofitLabel.Text = 'Auto-fitting';

            % Create AutofitSlider
            app.AutofitSlider = uislider(app.SimulationPanel);
            app.AutofitSlider.Limits = [5 500];
            app.AutofitSlider.MajorTicks = [5 104 203 302 401 500];
            app.AutofitSlider.ValueChangedFcn = createCallbackFcn(app, @AutofitSliderValueChanged, true);
            app.AutofitSlider.ValueChangingFcn = createCallbackFcn(app, @AutofitSliderValueChanging, true);
            app.AutofitSlider.MinorTicks = [5 16 27 38 49 60 71 82 93 104 115 126 137 148 159 170 181 192 203 214 225 236 247 258 269 280 291 302 313 324 335 346 357 368 379 390 401 412 423 434 445 456 467 478 489 500];
            app.AutofitSlider.Tooltip = {'Coarser tuning is less precise, but faster, and vice versa.'};
            app.AutofitSlider.Position = [31 63 412 3];
            app.AutofitSlider.Value = 50;

            % Create ButtonTuningLabel
            app.ButtonTuningLabel = uilabel(app.SimulationPanel);
            app.ButtonTuningLabel.HorizontalAlignment = 'center';
            app.ButtonTuningLabel.WordWrap = 'on';
            app.ButtonTuningLabel.Position = [134 324 79 15];
            app.ButtonTuningLabel.Text = 'Button tuning';

            % Create ButtonTuningSlider
            app.ButtonTuningSlider = uislider(app.SimulationPanel);
            app.ButtonTuningSlider.Limits = [1 5];
            app.ButtonTuningSlider.MajorTicks = [1 2 3 4 5];
            app.ButtonTuningSlider.ValueChangedFcn = createCallbackFcn(app, @ButtonTuningSliderValueChanged, true);
            app.ButtonTuningSlider.MinorTicks = [];
            app.ButtonTuningSlider.Position = [227 331 219 3];
            app.ButtonTuningSlider.Value = 3;

            % Create LayerSelectionDropDown
            app.LayerSelectionDropDown = uidropdown(app.SimulationPanel);
            app.LayerSelectionDropDown.Items = {'Layer 1', 'Layer 2'};
            app.LayerSelectionDropDown.ValueChangedFcn = createCallbackFcn(app, @LayerSelectionDropDownValueChanged, true);
            app.LayerSelectionDropDown.Position = [12 317 115 22];
            app.LayerSelectionDropDown.Value = 'Layer 1';

            % Create SliderLabel
            app.SliderLabel = uilabel(app.SimulationPanel);
            app.SliderLabel.HorizontalAlignment = 'center';
            app.SliderLabel.FontWeight = 'bold';
            app.SliderLabel.Position = [226 284 25 22];
            app.SliderLabel.Text = '𝑛';

            % Create nSlider
            app.nSlider = uislider(app.SimulationPanel);
            app.nSlider.ValueChangedFcn = createCallbackFcn(app, @nSliderValueChanged, true);
            app.nSlider.ValueChangingFcn = createCallbackFcn(app, @nSliderValueChanging, true);
            app.nSlider.Position = [46 279 373 3];

            % Create kLeftButton
            app.kLeftButton = uibutton(app.SimulationPanel, 'push');
            app.kLeftButton.ButtonPushedFcn = createCallbackFcn(app, @TuningButtonPushed, true);
            app.kLeftButton.Tag = 'kl';
            app.kLeftButton.Position = [9 202 26 24];
            app.kLeftButton.Text = '◀';

            % Create kRightButton
            app.kRightButton = uibutton(app.SimulationPanel, 'push');
            app.kRightButton.ButtonPushedFcn = createCallbackFcn(app, @TuningButtonPushed, true);
            app.kRightButton.Tag = 'kr';
            app.kRightButton.Position = [426 203 26 24];
            app.kRightButton.Text = '▶';

            % Create kLabel
            app.kLabel = uilabel(app.SimulationPanel);
            app.kLabel.HorizontalAlignment = 'center';
            app.kLabel.FontWeight = 'bold';
            app.kLabel.Position = [221 218 25 22];
            app.kLabel.Text = 'k';

            % Create kSlider
            app.kSlider = uislider(app.SimulationPanel);
            app.kSlider.ValueChangedFcn = createCallbackFcn(app, @kSliderValueChanged, true);
            app.kSlider.ValueChangingFcn = createCallbackFcn(app, @kSliderValueChanging, true);
            app.kSlider.Position = [44 216 375 3];

            % Create dLeftButton
            app.dLeftButton = uibutton(app.SimulationPanel, 'push');
            app.dLeftButton.ButtonPushedFcn = createCallbackFcn(app, @TuningButtonPushed, true);
            app.dLeftButton.Tag = 'dl';
            app.dLeftButton.Position = [9 134 26 24];
            app.dLeftButton.Text = '◀';

            % Create dRightButton
            app.dRightButton = uibutton(app.SimulationPanel, 'push');
            app.dRightButton.ButtonPushedFcn = createCallbackFcn(app, @TuningButtonPushed, true);
            app.dRightButton.Tag = 'dr';
            app.dRightButton.Position = [426 135 26 24];
            app.dRightButton.Text = '▶';

            % Create nmSliderLabel
            app.nmSliderLabel = uilabel(app.SimulationPanel);
            app.nmSliderLabel.HorizontalAlignment = 'center';
            app.nmSliderLabel.FontWeight = 'bold';
            app.nmSliderLabel.Position = [213 151 46 22];
            app.nmSliderLabel.Text = '𝑑 (nm)';

            % Create dSlider
            app.dSlider = uislider(app.SimulationPanel);
            app.dSlider.ValueChangedFcn = createCallbackFcn(app, @dSliderValueChanged, true);
            app.dSlider.ValueChangingFcn = createCallbackFcn(app, @dSliderValueChanging, true);
            app.dSlider.Position = [45 149 373 3];

            % Create AutofitRunButton
            app.AutofitRunButton = uibutton(app.SimulationPanel, 'push');
            app.AutofitRunButton.ButtonPushedFcn = createCallbackFcn(app, @AutofitRunButtonPushed, true);
            app.AutofitRunButton.Position = [274 70 40 22];
            app.AutofitRunButton.Text = 'Run';

            % Create AutofitValueLabel
            app.AutofitValueLabel = uilabel(app.SimulationPanel);
            app.AutofitValueLabel.Position = [222 7 25 22];
            app.AutofitValueLabel.Text = '';

            % Create ResetRangesButton
            app.ResetRangesButton = uibutton(app.SimulationPanel, 'push');
            app.ResetRangesButton.ButtonPushedFcn = createCallbackFcn(app, @ResetRangesButtonPushed, true);
            app.ResetRangesButton.BackgroundColor = [0.9608 0.9608 0.9608];
            app.ResetRangesButton.FontSize = 10;
            app.ResetRangesButton.Position = [378 94 72 20];
            app.ResetRangesButton.Text = 'Reset ranges';

            % Create FittingModeButtonGroup
            app.FittingModeButtonGroup = uibuttongroup(app.SimulationPanel);
            app.FittingModeButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @FittingModeButtonGroupSelectionChanged, true);
            app.FittingModeButtonGroup.BorderType = 'none';
            app.FittingModeButtonGroup.BackgroundColor = [0.9412 0.9412 0.9412];
            app.FittingModeButtonGroup.Position = [147 463 201 30];

            % Create OffButton
            app.OffButton = uiradiobutton(app.FittingModeButtonGroup);
            app.OffButton.Text = 'Off';
            app.OffButton.Position = [11 4 36 22];

            % Create ManualButton
            app.ManualButton = uiradiobutton(app.FittingModeButtonGroup);
            app.ManualButton.Text = 'Manual';
            app.ManualButton.Position = [71 4 65 22];
            app.ManualButton.Value = true;

            % Create AutoButton
            app.AutoButton = uiradiobutton(app.FittingModeButtonGroup);
            app.AutoButton.Text = 'Auto';
            app.AutoButton.Position = [148 4 44 22];

            % Create FittingModeLabel
            app.FittingModeLabel = uilabel(app.SimulationPanel);
            app.FittingModeLabel.Position = [76 466 72 22];
            app.FittingModeLabel.Text = 'Fitting mode';

            % Create CoarserLabel
            app.CoarserLabel = uilabel(app.SimulationPanel);
            app.CoarserLabel.FontSize = 10;
            app.CoarserLabel.Position = [31 68 41 22];
            app.CoarserLabel.Text = 'Coarser';

            % Create FinerLabel
            app.FinerLabel = uilabel(app.SimulationPanel);
            app.FinerLabel.HorizontalAlignment = 'right';
            app.FinerLabel.FontSize = 10;
            app.FinerLabel.Position = [419 66 28 22];
            app.FinerLabel.Text = 'Finer';

            % Create CoarserLabel_2
            app.CoarserLabel_2 = uilabel(app.SimulationPanel);
            app.CoarserLabel_2.FontSize = 10;
            app.CoarserLabel_2.Position = [227 333 41 22];
            app.CoarserLabel_2.Text = 'Coarser';

            % Create FinerLabel_3
            app.FinerLabel_3 = uilabel(app.SimulationPanel);
            app.FinerLabel_3.HorizontalAlignment = 'right';
            app.FinerLabel_3.FontSize = 10;
            app.FinerLabel_3.Position = [418 333 28 22];
            app.FinerLabel_3.Text = 'Finer';

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;

            % Create RightPanelGridLayout
            app.RightPanelGridLayout = uigridlayout(app.RightPanel);
            app.RightPanelGridLayout.ColumnWidth = {'1x'};
            app.RightPanelGridLayout.RowHeight = {'1x'};
            app.RightPanelGridLayout.Padding = [0 0 0 0];

            % Create TabGroup
            app.TabGroup = uitabgroup(app.RightPanelGridLayout);
            app.TabGroup.Layout.Row = 1;
            app.TabGroup.Layout.Column = 1;

            % Create MainTab
            app.MainTab = uitab(app.TabGroup);
            app.MainTab.Title = 'Main';

            % Create MainTabGridLayout
            app.MainTabGridLayout = uigridlayout(app.MainTab);
            app.MainTabGridLayout.ColumnWidth = {'1x'};
            app.MainTabGridLayout.RowHeight = {'10x', '5x', '0.5x'};
            app.MainTabGridLayout.ColumnSpacing = 1.25;
            app.MainTabGridLayout.RowSpacing = 5;
            app.MainTabGridLayout.Padding = [8 8 8 8];

            % Create MainUIAxes
            app.MainUIAxes = uiaxes(app.MainTabGridLayout);
            xlabel(app.MainUIAxes, 'Angle (°)')
            ylabel(app.MainUIAxes, 'Reflectance')
            app.MainUIAxes.Layer = 'top';
            app.MainUIAxes.GridLineWidth = 0.1;
            app.MainUIAxes.MinorGridLineWidth = 0.1;
            app.MainUIAxes.MinorGridLineStyle = '-';
            app.MainUIAxes.XMinorTick = 'on';
            app.MainUIAxes.YMinorTick = 'on';
            app.MainUIAxes.GridAlpha = 0.05;
            app.MainUIAxes.XGrid = 'on';
            app.MainUIAxes.YGrid = 'on';
            app.MainUIAxes.Layout.Row = 1;
            app.MainUIAxes.Layout.Column = 1;

            % Create AppNameLabel
            app.AppNameLabel = uilabel(app.MainTabGridLayout);
            app.AppNameLabel.HorizontalAlignment = 'right';
            app.AppNameLabel.Layout.Row = 3;
            app.AppNameLabel.Layout.Column = 1;
            app.AppNameLabel.Text = '';

            % Create InfoPanel
            app.InfoPanel = uipanel(app.MainTabGridLayout);
            app.InfoPanel.Title = 'Info';
            app.InfoPanel.Layout.Row = 2;
            app.InfoPanel.Layout.Column = 1;

            % Create InfoTextArea
            app.InfoTextArea = uieditfield(app.InfoPanel, 'text');
            app.InfoTextArea.Position = [1 1 735 199];

            % Create SliderLabel_2
            app.SliderLabel_2 = uilabel(app.InfoPanel);
            app.SliderLabel_2.HorizontalAlignment = 'right';
            app.SliderLabel_2.Position = [41 89 36 22];
            app.SliderLabel_2.Text = 'Slider';

            % Create Slider
            app.Slider = uislider(app.InfoPanel, 'range');
            app.Slider.Position = [99 98 532 3];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = SPRSoftware_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end