%--------------------------------------------------------------------------
% Function Name: CodeForClustering
% Author: Xiaoyan Wu (xiaoyan.psych@gmail.com)
% Date: February 12, 2024
% Usage: This is the code for Clustering subjects based on their behaviors,
% and visualizating the decisions for each cluster of subjetcs (figure 4i-l figure 5b)
%--------------------------------------------------------------------------
%% load data
clear;clc;
load('dataArranged.mat');

df = averaged(data); % The dataset df contains information for all subjects, where each row corresponds to a single subject and their average intervention rates for 100 unique conditions in the Intervene-or-Watch task
for s = 1:length(df)
    action(s,:) = df(s).action;
end

clust = zeros(size(action,1),9);
for i=1:9
     clust(:,i) = kmeans(action,i,'Distance','hamming','replicate',10000);
%     clust(:,i) = kmeans(action,i,'Distance','hamming','emptyaction','singleton','replicate',1000);
end
eva = evalclusters(action,clust,'silhouette');
save('all_children.mat','clust');
% Get the criterion value
criterionValue = eva.CriterionValues;

%% Plot figure for Clustering number and the criterion value, for experiment
figure;
plot(criterionValue, 'LineWidth', 4, 'Color', "#8c6bb1"); % 调整主线颜色（蓝色）
hold on

% 找到最优点
optNum = find(criterionValue == max(criterionValue));

% 绘制最优点
scatter(optNum, criterionValue(optNum), 120, 'filled', 'MarkerFaceColor', '#810f7c', 'MarkerEdgeColor', 'k');

% 设定轴标签和标题
xlabel('Number of Clusters', 'FontSize', 24, 'FontName', 'Arial');
ylabel('Criterion Value', 'FontSize', 24, 'FontName', 'Arial');
title('All children', 'FontSize', 24, 'FontName', 'Arial');

% 调整刻度字体
set(gca, 'FontSize', 24, 'FontName', 'Arial');
% 去除边框
box off;


%%

% print(gcf, '/Users/wuxiaoyan/Desktop/Clustering.png', '-dpng', '-r300');

for s = 1:length(data)
    data(s).group = clust(s,2);
end

save('dataArranged.mat','data');

%% 热图
clear;clc;
load('dataArranged.mat');

% plot behavioral patterns for each sub-group
% 增加inequality这一行
for s = 1:length(data)
    for t = 1:100
        if data(s).violator(t) == 5
            data(s).inequality{t,1} = '5:5';
        elseif data(s).violator(t) == 6
            data(s).inequality{t,1} = '6:4';
        elseif data(s).violator(t) == 7
            data(s).inequality{t,1} = '7:3';
        elseif data(s).violator(t) == 8
            data(s).inequality{t,1} = '8:2';
        elseif data(s).violator(t) == 9
            data(s).inequality{t,1} = '9:1';
        end
    end
end
    
figure;
idx_1= find([data.group] == 2);
subdata = data(idx_1);
BehaviorPatternFigurePlot(subdata, 'action');
sgtitle('');

% figure;
% idx_ph= find(ismember([data_exp1.Class3],{'Pragmatic helpers'}));
% subdata = data_exp1(idx_ph);
% BehaviorPatternFigurePlot(subdata, 'action');
% sgtitle('Pragmatic helpers');
% 
% figure;
% idx_rm = find(ismember([data_exp1.Class3],{'Rational moralists'}));
% subdata = data_exp1(idx_rm);
% BehaviorPatternFigurePlot(subdata, 'action');
% sgtitle('Rational moralists');



%% 需要输出(data,'Block,fairness,cost,ratio')
clear;clc;
load('dataArranged.mat');
for s = 1:length(data)
    for t = 1:100
        if data(s).violator(t) == 5
            data(s).inequality{t,1} = '5:5';
        elseif data(s).violator(t) == 6
            data(s).inequality{t,1} = '6:4';
        elseif data(s).violator(t) == 7
            data(s).inequality{t,1} = '7:3';
        elseif data(s).violator(t) == 8
            data(s).inequality{t,1} = '8:2';
        elseif data(s).violator(t) == 9
            data(s).inequality{t,1} = '9:1';
        end
    end
end

idx = find([data.group] == 1);
subdata = data(idx);

Block = {};
fairness = {};
cost = [];
ratio = [];
subid = [];
action = [];
for s = 1:length(subdata)
    subid = [subid;ones(100,1)*subdata(s).subid(1)];
    Block = [Block; subdata(s).block];
    fairness = [fairness; subdata(s).inequality];
    cost = [cost; subdata(s).cost];
    ratio = [ratio; subdata(s).ratio];
    action = [action; subdata(s).action];
end

tab = table(subid,Block,fairness,cost,ratio,action);
writetable(tab,'group1.xlsx');


%% SVO 比较这两组被试
clear;clc;
load('dataArranged.mat');
group = [data.group];
idx_1 = find([data.group] == 1);
idx_2 = find([data.group] == 2);
svo = [data.svo];
age = [data.age];
gender = [data.gender];


[h,p,ci,stats] = ttest2(svo(idx_1), svo(idx_2));

[h,p,ci,stats] = ttest2(age(idx_1), age(idx_2))


% 计算卡方检验
[tbl, chi2stat, p, label] = crosstab(group,gender);

% 输出结果
fprintf('卡方统计量：%f\n', chi2stat);
fprintf('p值：%f\n', p);
if p < 0.05
    fprintf('两个变量不独立。\n');
else
    fprintf('没有足够证据表明两个变量不独立。\n');
end






    