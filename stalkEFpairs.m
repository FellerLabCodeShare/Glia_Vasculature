%%% Stalk - endfoot pairs script

%% Select CSV
[file, path] = uigetfile('*.csv','Select peak CSV');

if isequal(file,0)
    return
end

fullFile = fullfile(path,file);

opts = delimitedTextImportOptions;

opts.Delimiter = ',';
opts.VariableNamesLine = 1;
opts.DataLine = 2;
opts.VariableNamingRule = 'preserve';

T = readtable(fullFile, opts);

%% Convert ROICorrelated to numeric
T.ROICorrelated = str2double(string(T.ROICorrelated));

disp(T.Properties.VariableNames')


%% -----------------------------
% Standardize category labels
% Handles:
%   'EF' or 'Endfoot'
%   'Stalk'
%% -----------------------------
T.Category = string(T.Category);

T.Category(ismember(lower(T.Category), ["ef", "endfoot"])) = "EF";
T.Category(ismember(lower(T.Category), ["stalk"])) = "Stalk";

%% -----------------------------
% Unique experiments
%% -----------------------------
files = unique(T.FileName);

% Preallocate
EF_vals    = nan(length(files),1);
Stalk_vals = nan(length(files),1);

%% -----------------------------
% Compute % correlated per experiment
%% -----------------------------
for i = 1:length(files)

    idx_file = strcmp(T.FileName, files{i});
    subT = T(idx_file,:);

    % ----- Endfoot -----
    idx_ef = subT.Category == "EF";

    if any(idx_ef)
        EF_vals(i) = mean(subT.ROICorrelated(idx_ef), 'omitnan') * 100;
    end

    % ----- Stalk -----
    idx_stalk = subT.Category == "Stalk";

    if any(idx_stalk)
        Stalk_vals(i) = mean(subT.ROICorrelated(idx_stalk), 'omitnan') * 100;
    end

end

%% -----------------------------
% Plot
%% -----------------------------
figure
hold on

jitterWidth = 0.15;

xEF    = centeredConditionalJitter(1, EF_vals, jitterWidth);
xStalk = centeredConditionalJitter(2, Stalk_vals, jitterWidth);

scatter(xEF, EF_vals, 90, 'filled')
scatter(xStalk, Stalk_vals, 90, 'filled')

% Connect paired experiments
for i = 1:length(files)

    if ~isnan(EF_vals(i)) && ~isnan(Stalk_vals(i))
        plot([1 2], [EF_vals(i) Stalk_vals(i)], '-k')
    end

end

%% -----------------------------
% Formatting
%% -----------------------------
xlim([0.5 2.5])
ylim([0 100])

xticks([1 2])
xticklabels({'EF','Stalk'})

ylabel('Proportion of calcium transients correlated with paired compartment')
title('Correlation of Calcium Transients in Stalk-Endfoot Pairs')

box off
set(gca, 'FontSize', 12)

%% =========================================================
% Function for centered conditional jitter
%% =========================================================
function x_jittered = centeredConditionalJitter(x_base, y_vals, width)

x_jittered = x_base * ones(size(y_vals));

% Find unique Y values
uniqueVals = unique(y_vals(~isnan(y_vals)));

for k = 1:length(uniqueVals)

    idx = find(y_vals == uniqueVals(k));
    n = length(idx);

    if n > 1

        % Evenly spaced symmetric jitter
        offsets = linspace(-width/2, width/2, n);
        x_jittered(idx) = x_base + offsets;

    end

end

end
