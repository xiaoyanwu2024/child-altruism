function BehaviorPatternFigurePlot(data, var)

%--------------------------------------------------------------------------
% Function Name: BehaviorPatternFigurePlot
% Author: Xiaoyan Wu
% Date: February 12, 2024
%
% Usage: This function generates a heatmap representing the mean value of a
%        measured variable for 100 unique experimental conditions.
%
% Input:
%   data - Dataset containing all experimental conditions and decisions for all subjects, with each row represents one subject.
%   var - The name of the measured variable.
%
% Output:
%   The heatmap figure represents the mean value of the measured variable across all subjects for 100 unique conditions.
%--------------------------------------------------------------------------

cond(1).scenario = 'punish';
cond(1).ratio = 1;

cond(2).scenario = 'punish';
cond(2).ratio = 3;

cond(3).scenario = 'help';
cond(3).ratio = 1;

cond(4).scenario = 'help';
cond(4).ratio = 3;

i = 1;
for num_con = 1:4
    block = cond(num_con).scenario;
    ratio = cond(num_con).ratio;
    Inequality = {'5:5','6:4','7:3','8:2','9:1'};
    Cost = [5,4,3,2,1];
    for num_fair = 1:length(Inequality)
        inequality = Inequality(num_fair);
        for num_cost = 1:5
            cost = Cost(num_cost);
            for s = 1:length(data)
                subdata = data(s);
                idx = (ismember(subdata.block, block) & ismember(subdata.ratio, ratio) & ismember(subdata.inequality, inequality) & ismember(subdata.cost, cost));
                con_subdata(s,1) = nanmean(subdata.(var)(idx));
            end
            % save mean value of all subjects for each condition
            cond(num_con).data(num_cost,num_fair) = mean(con_subdata);
            clear con_subdata
            i = i+1;
        end
    end
end

% for figure
figure;

yname = {'5','4','3','2','1'};
xname = {'5:5','6:4','7:3','8:2','9:1'};

subplot(223);
h = heatmap(xname,yname,(cond(1).data),'CellLabelColor', 'None');
h.title(append('punish',' &',' ratio = 1'));
h.xlabel('inequality');
h.ylabel('cost');
h.ColorbarVisible = 'off';
h.FontName = 'Arial';
h.FontSize = 14;
% 自定义颜色映射：从白色到 #e7298a
%cmap = [linspace(1, 227/255, 100)', linspace(1, 26/255, 100)', linspace(1, 28/255, 100)'];
cmap = [linspace(1, 231/255, 100)', linspace(1, 41/255, 100)', linspace(1, 138/255, 100)'];
% 应用自定义 colormap
colormap(gca, cmap);
caxis([0.1, 0.9]);

subplot(221);
h = heatmap(xname,yname,(cond(2).data),'CellLabelColor', 'None');
h.title(append('punish',' &',' ratio = 3'));
h.xlabel('inequality');
h.ylabel('cost');
h.ColorbarVisible = 'off';
h.FontName = 'Arial';
h.FontSize = 14;
% 自定义颜色映射：从白色到 #e7298a
cmap = [linspace(1, 231/255, 100)', linspace(1, 41/255, 100)', linspace(1, 138/255, 100)'];
% 应用自定义 colormap
colormap(gca, cmap);
caxis([0.1, 0.9]);

subplot(224);
h = heatmap(xname,yname,(cond(3).data),'CellLabelColor', 'None');
h.title(append('help',' &',' ratio = 1'));
h.xlabel('inequality');
h.ylabel('cost');
h.ColorbarVisible = 'off';
h.FontName = 'Arial';
h.FontSize = 14;
% 自定义颜色映射：从白色到 #e7298a
cmap = [linspace(1, 231/255, 100)', linspace(1, 41/255, 100)', linspace(1, 138/255, 100)'];
% 应用自定义 colormap
colormap(gca, cmap);
caxis([0.1, 0.9]);

subplot(222);
h = heatmap(xname,yname,(cond(4).data),'CellLabelColor', 'None');
h.title(append('help',' &',' ratio = 3'));
h.xlabel('inequality');
h.ylabel('cost');
h.ColorbarVisible = 'on';
h.FontName = 'Arial';
h.FontSize = 14;
% 自定义颜色映射：从白色到 #e7298a
cmap = [linspace(1, 231/255, 100)', linspace(1, 41/255, 100)', linspace(1, 138/255, 100)'];
% 应用自定义 colormap
colormap(gca, cmap);
caxis([0.1, 0.9]);
set(gcf,'Position',[0,0,800,800]);

numSub = length(data);
titleName = ['N = ',num2str(numSub)];
sgt = sgtitle(titleName, 'FontSize', 20, 'FontName', 'Arial');


    
    
    
    
    
    




