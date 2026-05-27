%% ==========================
% ROI-based Boxplot by Category and Drug
% Separate plots for developmental stage
%% ==========================

clear; clc;

%% ---- Load CSV ----
filename = 'Figure_5E_S1_data.csv';

opts = delimitedTextImportOptions;

opts.Delimiter = ',';
opts.VariableNamesLine = 1;
opts.DataLine = 2;
opts.VariableNamingRule = 'preserve';

tbl = readtable(filename, opts);

%% ---- Convert string variables ----
tbl.Category   = string(tbl.Category);
tbl.Drug       = string(tbl.Drug);
tbl.Experiment = string(tbl.Experiment);
tbl.Stage      = string(tbl.Stage);

%% ---- Numeric variable ----
tbl.Pct_Correlated = str2double(string(tbl.Pct_Correlated));
tbl.Num_Peaks          = str2double(string(tbl.Num_Peaks));
tbl.Num_Correlated     = str2double(string(tbl.Num_Correlated));
tbl.Num_NotCorrelated  = str2double(string(tbl.Num_NotCorrelated));
tbl.Pct_Correlated     = str2double(string(tbl.Pct_Correlated));
tbl.RecordingLength_sec = str2double(string(tbl.RecordingLength_sec));
tbl.PeaksPerMin        = str2double(string(tbl.PeaksPerMin));

%% ---- Stage list ----
stageList = ["P9-10", "P11-12"];


%% ---- Define group order explicitly ----
groupLabels = {
    'NVS CTRL'
    'NVS GBZ'
    'NVP CTRL'
    'NVP GBZ'
    'VP CTRL'
    'VP GBZ'
};

numGroups = numel(groupLabels);

%% =========================================================
% LOOP THROUGH STAGES
%% =========================================================

for s = 1:length(stageList)

    currentStage = stageList(s);

    %% ---- Filter stage ----
    stageIdx = tbl.Stage == currentStage;

    subTbl = tbl(stageIdx,:);

    %% ---- Extract relevant columns ----
    Category   = subTbl.Category;
    Drug       = subTbl.Drug;
    PeaksPerMin = subTbl.PeaksPerMin;
    Experiment = subTbl.Experiment;

    %% ---- Assign each ROI to a group ----
    groupIdx = NaN(height(subTbl),1);

    for i = 1:height(subTbl)

        if Category(i) == "NVS" && Drug(i) == "CTRL"
            groupIdx(i) = 1;

        elseif Category(i) == "NVS" && Drug(i) == "GBZ"
            groupIdx(i) = 2;

        elseif Category(i) == "NVP" && Drug(i) == "CTRL"
            groupIdx(i) = 3;

        elseif Category(i) == "NVP" && Drug(i) == "GBZ"
            groupIdx(i) = 4;

        elseif Category(i) == "VP" && Drug(i) == "CTRL"
            groupIdx(i) = 5;

        elseif Category(i) == "VP" && Drug(i) == "GBZ"
            groupIdx(i) = 6;

        end
    end

    %% ---- Remove invalid rows ----
    valid = ~isnan(groupIdx) & ~isnan(PeaksPerMin);

    groupIdx   = groupIdx(valid);
    PeaksPerMin    = PeaksPerMin(valid);
    Experiment = Experiment(valid);

    %% ---- Experiment colors ----
    expList = unique(Experiment);
    numExp  = numel(expList);

    expColors = lines(numExp);

    pointColorMap = containers.Map;

    for i = 1:numExp
        pointColorMap(expList(i)) = expColors(i,:);
    end

    %% =====================================================
    % CREATE FIGURE
    %% =====================================================

    figure;
    hold on;
    disp(currentStage)

    for g = 1:numGroups
        fprintf('Group %d count = %d\\n', g, sum(groupIdx == g))
    end

    %% ---- Boxplot ----
    boxplot(PeaksPerMin, groupIdx, ...
        'Labels', groupLabels, ...
        'Symbol', '', ...
        'Whisker', 1.5);

    %% ---- Colors for boxes ----
    ctrlColor = [0.2 0.6 0.8];
    gbzColor  = [0.8 0.4 0.4];

    boxHandles = findobj(gca,'Tag','Box');
    boxHandles = flipud(boxHandles);

    numBoxes = length(boxHandles);

    for i = 1:numBoxes

        if ismember(i,[1 3 5])
            c = ctrlColor;
        else
            c = gbzColor;
        end

        patch(get(boxHandles(i),'XData'), ...
            get(boxHandles(i),'YData'), ...
            c, ...
            'FaceAlpha',0.4, ...
            'EdgeColor',c);

    end
    %% ---- Deterministic jittered ROI points ----
    jitterWidth = 0.1;

    for g = 1:numGroups

        idx = groupIdx == g;

        y   = PeaksPerMin(idx);
        exp = Experiment(idx);

        x = centerStackJitter(g, y, jitterWidth);

        for j = 1:numel(y)

            scatter(x(j), y(j), ...
                50, ...
                'MarkerFaceColor','none', ...
                'MarkerEdgeColor', pointColorMap(exp(j)), ...
                'LineWidth',1.5);

        end
    end

    %% ---- Legend ----
    figureHandles = gobjects(numExp,1);

    for i = 1:numExp

        figureHandles(i) = scatter(nan, nan, 30, ...
            'MarkerFaceColor','none', ...
            'MarkerEdgeColor',expColors(i,:), ...
            'LineWidth',1.2);

    end

    legend(figureHandles, expList, ...
        'Location','eastoutside', ...
        'Interpreter','none');

    %% ---- Formatting ----
    ylabel('Events / minute');

    title(currentStage)

    ylim([0 3.5]);

    set(gca,'FontSize',12,'LineWidth',1);

    box off;
    hold off;

end

%% =========================================================
% Helper function
%% =========================================================

function x = centerStackJitter(xCenter, y, width)

    x = xCenter * ones(size(y));

    [ySorted, order] = sort(y);

    xTemp = x;

    i = 1;

    while i <= numel(ySorted)

        j = i;

        while j <= numel(ySorted) && ...
                abs(ySorted(j) - ySorted(i)) < 1e-6

            j = j + 1;

        end

        n = j - i;

        if n > 1

            offsets = linspace(-width, width, n);

            xTemp(order(i:j-1)) = xCenter + offsets;

        end

        i = j;

    end

    x = xTemp;

end