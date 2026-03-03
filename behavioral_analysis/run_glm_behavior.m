%% Behavioral Data Analysis using GLMM and LMM
% -------------------------------------------------------------------------
% This script preprocesses behavioral data and runs mixed-effects models
% to analyze intervention decisions and decision time.
%
% Author: Xiaoyan Wu 
% Email: xiaoyan.psych@gmail.com
%
% Description:
% The script loads behavioral data from "data.mat", restructures the data
% into a trial-level table, standardizes selected predictors, and fits
% mixed-effects models to examine factors influencing:
%   1. Intervention decisions (binary outcome)
%   2. Decision time (reaction time)
%
% Models:
%   - Generalized Linear Mixed Model (GLMM) for intervention decisions
%   - Linear Mixed Model (LMM) for decision time
%
% Random effects:
%   Random intercepts and slopes for each subject.
% -------------------------------------------------------------------------

clear; clc;

%% Load data
% The file "data.mat" contains a structure array "data", where each element
% represents one participant. Each participant includes behavioral data
% across 100 trials.

load('data.mat');

%% Initialize variables for constructing trial-level dataset

subid = [];        % Subject ID
scenario = {};     % Scenario type (punish and help)
violator = [];     % Payoff of the violator
victim = [];       % Payoff of the victim
cost = [];         % Cost required for intervention
ratio = [];        % Cost-benefit ratio of intervention
rt = [];           % Reaction time (decision time)
action = [];       % Intervention decision (0 = no intervention, 1 = intervention)
inequality = [];   % Payoff difference between violator and victim
trialN = [];       % Trial number
age = [];          % Participant age
gender = [];       % Participant gender


%% Convert subject-level data to trial-level data

for s = 1:length(data)
    
    % Subject ID repeated for each trial
    subid = [subid; data(s).subid * ones(100,1)];
    
    % Experimental scenario
    scenario = [scenario; data(s).scenario];
    
    % Payoff variables
    violator = [violator; data(s).violator];
    victim = [victim; data(s).victim];
    
    % Cost of intervention
    cost = [cost; data(s).cost];
    
    % Cost-benefit ratio
    ratio = [ratio; data(s).ratio];
    
    % Reaction time
    rt = [rt; data(s).rt];
    
    % Behavioral choice
    action = [action; data(s).action];
    
    % Inequality between violator and victim
    inequality = [inequality; data(s).violator - data(s).victim];
    
    % Trial index (1–100 for each participant)
    trialN = [trialN; [1:100]'];
    
    % Participant demographics
    age = [age; repmat(data(s).age,100,1)];
    gender = [gender; repmat(data(s).gender,100,1)];
    
end


%% Construct MATLAB table for statistical modeling

tab = table(subid, scenario, violator, victim, cost, ratio, rt, action, inequality, trialN, age, gender);


%% Data preprocessing

% Convert categorical variables
tab.scenario = categorical(tab.scenario);
tab.gender = categorical(tab.gender);

% Standardize continuous predictors (z-scoring)
tab.cost = zscore(tab.cost);
tab.ratio = zscore(tab.ratio);
tab.inequality = zscore(tab.inequality);
tab.trialN = zscore(tab.trialN);
tab.age = zscore(tab.age);


%% Model 1: Intervention Decision (GLMM)

% This model examines factors influencing the probability of intervention.
% The dependent variable "action" is binary (0 = no intervention, 1 = intervention).

% Fixed effects:
%   scenario
%   inequality
%   cost
%   ratio
%   gender
%   and their interactions

% Random effects:
%   Random intercepts and slopes for each subject.

md1 = fitglme(tab, ...
    'action ~ scenario * inequality * cost * ratio * gender + (1 + scenario + inequality + cost + ratio + gender | subid)', ...
    'Distribution','Binomial');


% Save model results
save(fullfile(pwd, 'GLMM_interventionDecision.mat'), 'md1');


%% Model 2: Decision Time (LMM)

% This model examines factors influencing reaction time (decision time).

% Dependent variable:
%   rt (reaction time)

% Same fixed and random effects structure as the GLMM above.

md2 = fitglme(tab, ...
    'rt ~ scenario * inequality * cost * ratio * gender + (1 + scenario + inequality + cost + ratio + gender | subid)', ...
    'Distribution','Normal');


% Save model results
save(fullfile(pwd, 'LMM_decisionTime.mat'), 'md2');