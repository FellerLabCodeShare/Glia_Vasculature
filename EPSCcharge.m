%% ==========================
% EPSC Charge by Drug (Paired), Stage-Coded
% RAW DATA VERSION → SUMMARY COLLAPSE
% ==========================

filename = 'Figure_5C_data.csv';
tbl = readtable(filename);

% ---- RAW VARIABLES ----
Drug     = string(tbl.Condition);   % CTRL / Gabazine (rename mapping below if needed)
File     = string(tbl.File);
Age      = string(tbl.Age);
Charge   = tbl.Charge_pC;

% ---- STANDARDIZE LABELS (IMPORTANT) ----
Drug(Drug == "Gabazine") = "GBZ";   % match your original script
Drug(Drug == "Control")  = "CTRL";

% ---- REMOVE BAD VALUES ----
valid = ~isnan(Charge) & Drug ~= "";
tbl = tbl(valid,:);

Drug   = Drug(valid);
File   = File(valid);
Age    = Age(valid);
Charge = Charge(valid);

%% =========================================================
% 1. COLLAPSE RAW EPSC EVENTS → MEAN CHARGE PER FILE
% =========================================================

[G, fileID, drugID, ageID] = findgroups(File, Drug, Age);

meanCharge = splitapply(@(x) mean(abs(x),'omitnan'), Charge, G);

summaryTbl = table(fileID, drugID, ageID, meanCharge, ...
    'VariableNames', {'File','Drug','Age','MeanCharge_pC'});

%% ---- Extract for plotting ----
Drug       = summaryTbl.Drug;
Age        = summaryTbl.Age;
ChargeAvg  = summaryTbl.MeanCharge_pC;
File       = summaryTbl.File;

%% ---- Conditions ----
drugs  = ["CTRL","GBZ"];
ages   = unique(Age);

labels = ["CTRL","GBZ"];
numGroups = numel(drugs);

%% ---- Colors ----
drugColors.CTRL = [0.2 0.6 0.8];
drugColors.GBZ  = [0.8 0.4 0.4];

ageColors = lines(numel(ages));

%% ---- Formatting ----
jitter  = 0.18;
yLimits = [0 max(ChargeAvg,[],'omitnan')*1.1];

%% ---- Build boxplot data ----
Y = [];
groupIdx = [];

for d = 1:numel(drugs)
    idx = Drug == drugs(d) & ~isnan(ChargeAvg);
    Y = [Y; ChargeAvg(idx)];
    groupIdx = [groupIdx; repmat(d, sum(idx), 1)];
end

%% ---- Figure ----
figure; hold on;

%% ---- Boxplot ----
boxplot(Y, groupIdx, ...
    'Labels', labels, ...
    'Symbol','', ...
    'Whisker',1.5);

% ---- Color boxes ----
boxHandles = flipud(findobj(gca,'Tag','Box'));

for d = 1:numGroups
    c = drugColors.(drugs(d));
    patch(get(boxHandles(d),'XData'), ...
          get(boxHandles(d),'YData'), ...
          c, ...
          'FaceAlpha',0.30, ...
          'EdgeColor',c);
end

%% ---- Jittered points (colored by Age) ----
for d = 1:numel(drugs)
    for a = 1:numel(ages)

        idx = Drug == drugs(d) & Age == ages(a);

        if ~any(idx), continue; end

        x = d;  % keep structure like your original
        y = ChargeAvg(idx);

        c = ageColors(a,:);

        scatter(x, y, ...
            45, 'filled', ...
            'MarkerFaceColor', c, ...
            'MarkerEdgeColor','k', ...
            'MarkerFaceAlpha',0.9);
    end
end

%% ---- Paired lines: CTRL → GBZ per File ----
files = unique(File);

for f = 1:numel(files)

    idxCTRL = File == files(f) & Drug == "CTRL";
    idxGBZ  = File == files(f) & Drug == "GBZ";

    if any(idxCTRL) && any(idxGBZ)

        y1 = ChargeAvg(find(idxCTRL,1));
        y2 = ChargeAvg(find(idxGBZ,1));

        plot([1 2], [y1 y2], ...
            '-', 'Color',[0.4 0.4 0.4 0.45], ...
            'LineWidth',2);
    end
end

%% ---- Legend (Age) ----
h = gobjects(numel(ages),1);
for a = 1:numel(ages)
    h(a) = scatter(nan,nan,45,'filled', ...
        'MarkerFaceColor',ageColors(a,:), ...
        'MarkerEdgeColor','k');
end

legend(h, ages, 'Location','best');

%% ---- Formatting ----
ylabel('Mean EPSC Charge (pC)');
ylim(yLimits);
set(gca,'FontSize',12,'LineWidth',1);
xlim([0.5 2.5]);
box off;
hold off;