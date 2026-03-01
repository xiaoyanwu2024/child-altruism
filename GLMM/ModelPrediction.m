
clear; clc;

%% 1. 读入数据
load('dataArranged.mat');                 % 得到 data(s)
trials = readtable('/Users/wuxiaoyan/Desktop/otherModels/trials_with_prediction.csv');

%% 2. 给每个被试补 prediction
for s = 1:length(data)

    sid = data(s).subid;

    % 找该被试所有 trial（按 trial 排序，保证对齐）
    idx = trials.subject_id == sid;
    tmp = trials(idx, :);
    tmp = sortrows(tmp, 'trial');

    % 安全检查：trial 数量是否一致
    if height(tmp) ~= numel(data(s).action)
        error('Trial number mismatch for subject %d', sid);
    end

    % 写入 prediction
    data(s).prediction = tmp.prediction_bern;

end


%% 3. 保存新文件（不覆盖原始）
save('dataArranged_with_prediction.mat', 'data');

% %% 画所有条件的图
for s = 1:length(data)
    block = data(s).block;
    data(s).block = [];
    data(s).block(find(strcmp(block,'punish')),1) = 1;
    data(s).block(find(strcmp(block,'help')),1) = 2;
    data(s).inequality = strcat(num2str(data(s).violator),":",num2str(data(s).victim));
end

    FigurePlotPrediction(data); % data visualization
    sgtitle("SI+SCI+VCI+EC+RP+ID+lapse");

%% 画交互作用：postHocScenarioGenderRatio
clear;clc;
load('dataArranged_with_prediction.mat');

scenarios = {'help','punish'};
ratios    = [1, 3];

% 用 struct 存结果
subSummary = struct();
k = 1;

for s = 1:length(data)

    gender = data(s).Gender;   % 1=男, 2=女

    for sc = 1:length(scenarios)
        for r = 1:length(ratios)

            idx = strcmp(data(s).block, scenarios{sc}) & ...
                  data(s).ratio == ratios(r);

            if sum(idx) > 0
                subSummary(k).subid    = data(s).subid;
                subSummary(k).gender   = gender;
                subSummary(k).scenario = scenarios{sc};
                subSummary(k).ratio    = ratios(r);
                subSummary(k).p_action = nanmean(data(s).prediction(idx));  % ★这里
                k = k + 1;
            end
        end
    end
end

subSummary = struct2table(subSummary);

results = table();
row = 1;

for sc = 1:length(scenarios)
    for r = 1:length(ratios)

        idx = strcmp(subSummary.scenario, scenarios{sc}) & ...
            subSummary.ratio == ratios(r);

        tmp = subSummary(idx, :);

        y_male   = tmp.p_action(tmp.gender == 1);
        y_female = tmp.p_action(tmp.gender == 2);

        [~, p, ci, stats] = ttest2(y_male, y_female);

        results.scenario{row,1} = scenarios{sc};
        results.ratio(row,1)    = ratios(r);
        results.t(row,1)        = stats.tstat;
        results.df(row,1)       = stats.df;
        results.p(row,1)        = p;
        results.ci_low(row,1)   = ci(1);
        results.ci_high(row,1)  = ci(2);
        results.mean_male(row,1)   = mean(y_male);
        results.mean_female(row,1) = mean(y_female);

        row = row + 1;
    end
end

% 多重比较校正（Holm）
results.p_holm = holm_bonferroni(results.p);

% 只对不显著（按校正后）算 BF01
results.BF01 = NaN(height(results),1);

for i = 1:height(results)

    if results.p_holm(i) >= 0.05   % 只对不显著的算 BF

        idx = strcmp(subSummary.scenario, results.scenario{i}) & ...
            subSummary.ratio == results.ratio(i);

        tmp = subSummary(idx,:);

        y_male   = tmp.p_action(tmp.gender == 1);
        y_female = tmp.p_action(tmp.gender == 2);

        results.BF01(i) = bf01_ttest2(y_male, y_female);
    end
end

% 生成报告字符串（显著：t/CI/p_holm；不显著：再加 BF01）
results.report = strings(height(results),1);
for i = 1:height(results)
    base = sprintf("%s, ratio=%.1f: t(%d)=%.2f, 95%% CI [%.3f, %.3f], p_Holm=%.3f", ...
        results.scenario{i}, results.ratio(i), results.df(i), results.t(i), ...
        results.ci_low(i), results.ci_high(i), results.p_holm(i));

    if results.p_holm(i) >= 0.05
        results.report(i) = base + sprintf(", BF01=%.2f", results.BF01(i));
    else
        results.report(i) = base;
    end
end

disp(results(:,{'scenario','ratio','report'}));

% 画图

% -------- 全局可调参数（你只改这里）--------
fontName = 'Arial';
fontSize = 12;

lw = 2;          % 线宽
ms = 7;          % marker size
capSize = 10;    % errorbar cap

yLim = [0.2 0.45];

% -------- 基本设置 --------
scenarios = {'punish','help'};
xVals     = [2 3];     % 横坐标显示为 2 / 3
ratios    = [1 3];
genders   = [1 2];     % 1=男, 2=女
genderLabel = {'Boys','Girls'};

xOffset = [-0.05, +0.05];   % Boys 向左，Girls 向右

% 正确配色（男=蓝，女=橙）
colors = [[93 160 198]/255;    % Boys
          [231 113 160]/255];  % Girls

% -------- Step 1: 被试内均值 --------
subSummary = struct();
k = 1;

for s = 1:length(data)

    gender = data(s).Gender;

    for r = 1:length(ratios)
        for sc = 1:length(scenarios)

            idx = strcmp(data(s).block, scenarios{sc}) & ...
                  data(s).ratio == ratios(r);

            if any(idx)
                subSummary(k).gender   = gender;
                subSummary(k).ratio    = ratios(r);
                subSummary(k).scenario = scenarios{sc};
                subSummary(k).x        = xVals(sc);   % 2 / 3
                subSummary(k).p_action = mean(data(s).prediction(idx));  % ★这里
                k = k + 1;
            end
        end
    end
end

subSummary = struct2table(subSummary);

% -------- Step 2: 画图 --------
figure('Color','w','Position',[200 300 820 360])

for r = 1:length(ratios)

    subplot(1,2,r); hold on

    for g = 1:length(genders)

        m  = zeros(1,2);
        se = zeros(1,2);

        for sc = 1:2
            idx = subSummary.gender == genders(g) & ...
                  subSummary.ratio == ratios(r) & ...
                  strcmp(subSummary.scenario, scenarios{sc});

            y = subSummary.p_action(idx);
            m(sc)  = mean(y);
            se(sc) = std(y) / sqrt(numel(y));
        end

        errorbar(xVals+ xOffset(g), m, se, '-o', ...
            'Color', colors(g,:), ...
            'LineWidth', lw, ...
            'MarkerSize', ms, ...
            'MarkerFaceColor', colors(g,:), ...   % 实心点
            'MarkerEdgeColor', 'k', ...            % 黑色边框
            'CapSize', capSize);
    end

    set(gca, ...
        'FontName', fontName, ...
        'FontSize', fontSize, ...
        'XTick', xVals, ...
        'XTickLabel', {'punish','help'}, ...
        'YLim', yLim, ...
        'Xlim',[1.5, 3.5],...
        'LineWidth', 1)

    ylabel('p(yes)','FontName',fontName,'FontSize',fontSize)
    title(sprintf('ratio = %d', ratios(r)), ...
        'FontName',fontName,'FontSize',fontSize)

    box off

    if r == 1
        legend(genderLabel, ...
            'FontName',fontName, ...
            'FontSize',fontSize, ...
            'Location','best')
    end
end

%% 交互作用Cost Gender Ratio

% ===============================
% 设置维度
% ===============================
costLevels = 1:5;     % ★ 原来的 scenarios
ratios     = [1, 3];

% ===============================
% Step 1: 被试内条件均值
% ===============================
subSummary = struct();
k = 1;

for s = 1:length(data)

    gender = data(s).Gender;   % 1=男, 2=女

    for c = 1:length(costLevels)
        for r = 1:length(ratios)

            idx = data(s).cost  == costLevels(c) & ...
                  data(s).ratio == ratios(r);

            if any(idx)
                subSummary(k).subid    = data(s).subid;
                subSummary(k).gender   = gender;
                subSummary(k).cost     = costLevels(c);   % ★ cost
                subSummary(k).ratio    = ratios(r);
                subSummary(k).p_action = nanmean(data(s).prediction(idx));
                k = k + 1;
            end
        end
    end
end

subSummary = struct2table(subSummary);

% ===============================
% Step 2: 性别独立样本 t 检验（10 次）
% ===============================
results = table();
row = 1;

for c = 1:length(costLevels)
    for r = 1:length(ratios)

        idx = subSummary.cost  == costLevels(c) & ...
              subSummary.ratio == ratios(r);

        tmp = subSummary(idx, :);

        y_male   = tmp.p_action(tmp.gender == 1);
        y_female = tmp.p_action(tmp.gender == 2);

        [~, p, ci, stats] = ttest2(y_male, y_female);

        results.cost(row,1)      = costLevels(c);   % ★
        results.ratio(row,1)     = ratios(r);
        results.t(row,1)         = stats.tstat;
        results.df(row,1)        = stats.df;
        results.p(row,1)         = p;
        results.ci_low(row,1)    = ci(1);
        results.ci_high(row,1)   = ci(2);
        results.mean_male(row,1)   = mean(y_male);
        results.mean_female(row,1) = mean(y_female);

        row = row + 1;
    end
end

% ===============================
% Step 3: 多重比较校正（Holm，10 次）
% ===============================
results.p_holm = holm_bonferroni(results.p);

% ===============================
% Step 4: Bayesian t test（仅不显著）
% ===============================
results.BF01 = NaN(height(results),1);

for i = 1:height(results)

    if results.p_holm(i) >= 0.05

        idx = subSummary.cost  == results.cost(i) & ...
              subSummary.ratio == results.ratio(i);

        tmp = subSummary(idx,:);

        y_male   = tmp.p_action(tmp.gender == 1);
        y_female = tmp.p_action(tmp.gender == 2);

        results.BF01(i) = bf01_ttest2(y_male, y_female);
    end
end

% ===============================
% Step 5: 自动生成可写论文的 report
% ===============================
results.report = strings(height(results),1);

for i = 1:height(results)

    base = sprintf("cost=%d, ratio=%d: t(%d)=%.2f, 95%% CI [%.3f, %.3f], p_Holm=%.3f", ...
        results.cost(i), results.ratio(i), results.df(i), results.t(i), ...
        results.ci_low(i), results.ci_high(i), results.p_holm(i));

    if results.p_holm(i) >= 0.05
        results.report(i) = base + sprintf(", BF01=%.2f", results.BF01(i));
    else
        results.report(i) = base;
    end
end

disp(results(:,{'cost','ratio','report'}));

%% =========================================
%  Figure: cost × gender
%  Separate panels for ratio = 1 and ratio = 3
%  Mean ± SE across participants
% =========================================

%% -------- 全局可调参数（你只改这里）--------
fontName = 'Arial';
fontSize = 12;

lw = 2;          % 线宽
ms = 7;          % marker size
capSize = 10;    % errorbar cap

yLim = [0.15 0.5];

xOffset = [-0.05, +0.05];   % Boys 向左，Girls 向右

%% -------- 基本设置 --------
costLevels = 1:5;        % cost 水平
ratios     = [1 3];
genders    = [1 2];      % 1=男, 2=女
genderLabel = {'Boys','Girls'};

% 配色（和你之前一致）
colors = [[93 160 198]/255;    % Boys
          [231 113 160]/255];  % Girls

%% -------- Step 1: 被试内均值 --------
subSummary = struct();
k = 1;

for s = 1:length(data)

    gender = data(s).Gender;

    for r = 1:length(ratios)
        for c = 1:length(costLevels)

            idx = data(s).ratio == ratios(r) & ...
                  data(s).cost  == costLevels(c);

            if any(idx)
                subSummary(k).gender   = gender;
                subSummary(k).ratio    = ratios(r);
                subSummary(k).cost     = costLevels(c);
                subSummary(k).p_action = mean(data(s).prediction(idx));
                k = k + 1;
            end
        end
    end
end

subSummary = struct2table(subSummary);

% -------- Step 2: 画图 --------
figure('Color','w','Position',[200 300 820 360])

for r = 1:length(ratios)

    subplot(1,2,r); hold on

    for g = 1:length(genders)

        m  = nan(1, numel(costLevels));
        se = nan(1, numel(costLevels));

        for c = 1:length(costLevels)

            idx = subSummary.gender == genders(g) & ...
                  subSummary.ratio  == ratios(r) & ...
                  subSummary.cost   == costLevels(c);

            y = subSummary.p_action(idx);

            if ~isempty(y)
                m(c)  = mean(y);
                se(c) = std(y) / sqrt(numel(y));
            end
        end

        xPlot = costLevels + xOffset(g);
        errorbar(xPlot, m, se, '-o', ...
            'Color', colors(g,:), ...
            'LineWidth', lw, ...
            'MarkerSize', ms, ...
            'MarkerFaceColor', colors(g,:), ...   % 实心点
            'MarkerEdgeColor', 'k', ...            % 黑边
            'CapSize', capSize);
    end

    set(gca, ...
        'FontName', fontName, ...
        'FontSize', fontSize, ...
        'XTick', costLevels, ...
        'XLim', [0.5 5.5], ...
        'YLim', yLim, ...
        'LineWidth', 1)

    xlabel('Cost','FontName',fontName,'FontSize',fontSize)
    ylabel('p(yes)','FontName',fontName,'FontSize',fontSize)

    title(sprintf('ratio = %d', ratios(r)), ...
        'FontName',fontName,'FontSize',fontSize)

    box off

    if r == 1
        legend(genderLabel, ...
            'FontName',fontName, ...
            'FontSize',fontSize, ...
            'Location','best')
    end
end