%% load data
clear;clc;
load('dataArranged.mat');
ls = find(strcmp([data.gender],'女'));

df = averaged(data(ls)); % The dataset df contains information for all subjects, where each row corresponds to a single subject and their average intervention rates for 100 unique conditions in the Intervene-or-Watch task
for s = 1:length(df)
    action(s,:) = df(s).action;
end

clust = zeros(size(action,1),9);
for i=1:9
     clust(:,i) = kmeans(action,i,'Distance','hamming','replicate',10000);
%     clust(:,i) = kmeans(action,i,'Distance','hamming','emptyaction','singleton','replicate',1000);
end
eva = evalclusters(action,clust,'silhouette');
save('all_girls.mat','clust');
% Get the criterion value
criterionValue = eva.CriterionValues;

%% Plot figure for Clustering number and the criterion value, for Boys
clear;clc;
load('dataArranged.mat');
ls = find(strcmp([data.gender],'男'));

df = averaged(data(ls)); % The dataset df contains information for all subjects, where each row corresponds to a single subject and their average intervention rates for 100 unique conditions in the Intervene-or-Watch task
for s = 1:length(df)
    action(s,:) = df(s).action;
end

load('all_boys.mat');
eva = evalclusters(action,clust,'silhouette');
criterionValue = eva.CriterionValues;

figure;
plot(criterionValue, 'LineWidth', 4, 'Color', "#43a2ca"); % 调整主线颜色（蓝色）
hold on

% 找到最优点
optNum = find(criterionValue == max(criterionValue));

% 绘制最优点
scatter(optNum, criterionValue(optNum), 120, 'filled', 'MarkerFaceColor', '#0868ac', 'MarkerEdgeColor', 'k');
hold on

ls = find(strcmp([data.gender],'女'));
df = averaged(data(ls)); % The dataset df contains information for all subjects, where each row corresponds to a single subject and their average intervention rates for 100 unique conditions in the Intervene-or-Watch task
clear action
for s = 1:length(df)
    action(s,:) = df(s).action;
end
load('all_girls.mat');
eva = evalclusters(action,clust,'silhouette');
criterionValue = eva.CriterionValues;
plot(criterionValue, 'LineWidth', 4, 'Color', "#f768a1"); % 调整主线颜色（红色）
hold on
% 找到最优点
optNum = find(criterionValue == max(criterionValue));
% 绘制最优点
scatter(optNum, criterionValue(optNum), 120, 'filled', 'MarkerFaceColor', '#dd3497', 'MarkerEdgeColor', 'k');

% 设定轴标签和标题
xlabel('Number of clusters', 'FontSize', 24, 'FontName', 'Arial');
ylabel('Criterion value', 'FontSize', 24, 'FontName', 'Arial');
% title('All children', 'FontSize', 24, 'FontName', 'Arial');
xticks(2:9);
% 调整刻度字体
set(gca, 'FontSize', 20, 'FontName', 'Arial');
% 去除边框
box off;
xlim([2,9]);
saveas(gcf, 'Cluster_Gender.svg');  % SVG 格式


%% 热图
clear;clc;
load('dataArranged.mat')
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
    
% boys
load('all_boys.mat');
ls = find(strcmp([data.gender],'男'));
optNum = 2;
NumClust = unique(clust(:,optNum));
subdata = data(ls);

for numC = 1:length(NumClust)
    figure;
    idx= find(clust(:,optNum) == numC);
    BehaviorPatternFigurePlot_blue(subdata(idx), 'action');
end


% girls
load('all_girls.mat');
ls = find(strcmp([data.gender],'女'));
optNum = 3;
NumClust = unique(clust(:,optNum));
subdata = data(ls);

for numC = 1:length(NumClust)
    idx= find(clust(:,optNum) == numC);
    BehaviorPatternFigurePlot(subdata(idx), 'action');
end


% all subs
load('all_children.mat');
optNum = 2;
NumClust = unique(clust(:,optNum));

for numC = 1:length(NumClust)
    figure;
    idx= find(clust(:,optNum) == numC);
    BehaviorPatternFigurePlot(data(idx), 'action');
end
