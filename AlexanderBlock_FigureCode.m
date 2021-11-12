%% Code to process ABM output and plot figures
% First, use BehaviorSpace in NetLogo to run each scenario across
% all forecast precipitation timeseries and save aggregate information
% into one .csv file to import here and generate figures.
% Alexander and Block (2021), University of Wisconsin-Madison

%% Post-process raw ABM output
% Run this section separately with output from each ABM scenario,
% omitting variables below as necessary if they were not included
% in the ABM simulations.

numSeeds = 20;
numSims = 94;
output = ABM_output; %% CHANGE BASED ON ABM FILE NAME
outputYr = sortrows(output,4);
outputYrSim = sortrows(outputYr,3);

%reshape variables from different random seeds
use_fcst = reshape(mean(reshape(outputYrSim(:,5),numSeeds,[])),40,[])';
hear_peer = reshape(mean(reshape(outputYrSim(:,6),numSeeds,[])),40,[])';
hear_expert = reshape(mean(reshape(outputYrSim(:,7),numSeeds,[])),40,[])';
perc_EA = reshape(mean(reshape(outputYrSim(:,8),numSeeds,[])),40,[])';
perc_MA = reshape(mean(reshape(outputYrSim(:,9),numSeeds,[])),40,[])';
perc_LA = reshape(mean(reshape(outputYrSim(:,10),numSeeds,[])),40,[])';
meanTrust_EA = reshape(mean(reshape(outputYrSim(:,11),numSeeds,[])),40,[])';
meanTrust_MA = reshape(mean(reshape(outputYrSim(:,12),numSeeds,[])),40,[])';
meanTrust_LA = reshape(mean(reshape(outputYrSim(:,13),numSeeds,[])),40,[])';
food_store_EA = reshape(mean(reshape(outputYrSim(:,14),numSeeds,[])),40,[])';
food_store_MA = reshape(mean(reshape(outputYrSim(:,15),numSeeds,[])),40,[])';
food_store_LA = reshape(mean(reshape(outputYrSim(:,16),numSeeds,[])),40,[])';
strat_chge_EA = reshape(mean(reshape(outputYrSim(:,17),numSeeds,[])),40,[])';
strat_chge_MA = reshape(mean(reshape(outputYrSim(:,18),numSeeds,[])),40,[])';
strat_chge_LA = reshape(mean(reshape(outputYrSim(:,19),numSeeds,[])),40,[])';
heuristic_EA = reshape(mode(reshape(outputYrSim(:,20),numSeeds,[])),40,[])';
heuristic_MA = reshape(mode(reshape(outputYrSim(:,21),numSeeds,[])),40,[])';
heuristic_LA = reshape(mode(reshape(outputYrSim(:,22),numSeeds,[])),40,[])';

%summary - avgs over all climate series
one = mean(use_fcst)';
two = mean(hear_peer)';
three = mean(hear_expert)';
four = mean(perc_EA)';
five = mean(perc_MA)';
six = mean(perc_LA)';
seven = mean(meanTrust_EA)';
eight = mean(meanTrust_MA)';
nine = mean(meanTrust_LA)';
ten = mean(food_store_EA)';
eleven = mean(food_store_MA)';
twelve = mean(food_store_LA)';
thirteen = mean(strat_chge_EA)';
fourteen = mean(strat_chge_MA)';
fifteen = mean(strat_chge_LA)';
sixteen = mode(heuristic_EA)';
seventeen = mode(heuristic_MA)';
eighteen = mode(heuristic_LA)';

ABM_output = [one two three four five six seven eight...
    nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen];

% post-process to determine average benefit
output = ABM_output; %% CHANGE BASED ON FILE OUTPUT and SCENARIO
outputYr = sortrows(output,4);
outputYrSim = sortrows(outputYr,3);

food_store = reshape(mean(reshape(outputYrSim(:,5),numSeeds,[])),40,[])';
wet_ben = reshape(mean(reshape(outputYrSim(:,6),numSeeds,[])),40,[])';
dry_ben = reshape(mean(reshape(outputYrSim(:,7),numSeeds,[])),40,[])';

outputNorm = ABM_output_scenario1; %% CHANGE BASED ON FILE OUTPUT
outputYrNorm = sortrows(outputNorm,4);
outputYrSimNorm = sortrows(outputYrNorm,3);

food_store_norm = reshape(mean(reshape(outputYrSimNorm(:,5),numSeeds,[])),40,[])';
wet_ben_norm = reshape(mean(reshape(outputYrSimNorm(:,6),numSeeds,[])),40,[])';
dry_ben_norm = reshape(mean(reshape(outputYrSimNorm(:,7),numSeeds,[])),40,[])';

climSeries = ABMv4allClimInf3NoPTLseedEnd;
AddClimSeries = ABMv4allAddClimInf3NoPTLseedEnd; 

% post-process by forecast accuracy
FcstAccuracy = zeros(194,1);

for i = 1:194
    for j = 1:39
        if PrecipSKILLwObs(j,i) > 0 
            FcstAccuracy(i) = FcstAccuracy(i) + 1;
        end
    end
end
FcstAc = (FcstAccuracy./39).*100;
AccSort = sortrows(allAcc,1);

Accuracy(1,:) = mean(AccSort(1:27,:));
Accuracy(2,:) = mean(AccSort(28:52,:));
Accuracy(3,:) = mean(AccSort(53:101,:)); 
Accuracy(4,:) = mean(AccSort(102:135,:));
Accuracy(5,:) = mean(AccSort(136:165,:)); 
Accuracy(6,:) = mean(AccSort(166:194,:)); 

AccuracyStd(1,:) = std(AccSort(1:27,:)); 
AccuracyStd(2,:) = std(AccSort(28:52,:)); 
AccuracyStd(3,:) = std(AccSort(53:101,:)); 
AccuracyStd(4,:) = std(AccSort(102:135,:)); 
AccuracyStd(5,:) = std(AccSort(136:165,:)); 
AccuracyStd(6,:) = std(AccSort(166:194,:)); 

AccuracyNoInt = Accuracy;
Z = sortrows(output,2);
ZZ(:,1) = mean(reshape(Z(1:7760,11),40,[]))';
ZZ(:,2) = mean(reshape(Z(1:7760,12),40,[]))';
ZZ(:,3) = mean(reshape(Z(1:7760,13),40,[]))';
Diff = allRunsBen-ZZ;

MeanAnBen(:,1) = FcstAc;
MeanAnBen(:,2) = Diff(:,1);
MeanAnBen(:,3) = Diff(:,2);
MeanAnBen(:,4) = Diff(:,3);
AccSortBen = sortrows(MeanAnBen,1);

AccuracyBen(1,:) = mean(AccSortBen(1:27,:));
AccuracyBen(2,:) = mean(AccSortBen(28:52,:)); 
AccuracyBen(3,:) = mean(AccSortBen(53:101,:)); 
AccuracyBen(4,:) = mean(AccSortBen(102:135,:)); 
AccuracyBen(5,:) = mean(AccSortBen(136:165,:)); 
AccuracyBen(6,:) = mean(AccSortBen(166:194,:)); 

AccuracyBenStd(1,:) = std(AccSortBen(1:27,:)); 
AccuracyBenStd(2,:) = std(AccSortBen(28:52,:)); 
AccuracyBenStd(3,:) = std(AccSortBen(53:101,:)); 
AccuracyBenStd(4,:) = std(AccSortBen(102:135,:)); 
AccuracyBenStd(5,:) = std(AccSortBen(136:165,:)); 
AccuracyBenStd(6,:) = std(AccSortBen(166:194,:)); 


%% FIGURE 1 - Map created in GIS, not in Matlab

%% FIGURE 2 - Agricultural benefit trade-off between maize and teff

rainfall = [894.8068 1035.4149 1228.8484 1108.3 1188.3];
Mben = [27445.635 35525.06 42455.088 48450.246 53049.368];
Tben = [32631.573 38669.678 40628.621 39986.08 40199.151];

figure
plot(rainfall,Mben,'ko')
hold on
plot(rainfall,Tben,'k*')
hold on
patch([850 985 985 850], [5.5e+4 5.5e+4 2.5e+4 2.5e+4], [1 1 1])
patch([985 1118 1118 985], [5.5e+4 5.5e+4 2.5e+4 2.5e+4], [0.85 0.85 0.85])
patch([1118 1250 1250 1118], [5.5e+4 5.5e+4 2.5e+4 2.5e+4], [0.65 0.65 0.65])
plot(rainfall,Mben,'ko')
hold on
plot(rainfall,Tben,'k*')
hold on
mline = refline(63.471,-27871);
hold on
tline = refline(23.119,13197);
mline.Color = 'k';
tline.Color = 'k';
mline.LineStyle = '-';
tline.LineStyle = ':';
mline.LineWidth = 2;
tline.LineWidth = 2;

set(gca,'XTickLabels',{'850','900','950','1000','1050','1100','1150','1200','1250'},'fontsize',16);
xlabel('Total JJAS precipitation (mm)','fontsize',16)
ylabel('Household Benefit (Birr/ha)','fontsize',16)
set(legend('Maize','Teff'),'fontsize',16)

%% FIGURE 3 - Created in Adobe Illustrator, not Matlab

%% FIGURE 4 - Percent difference benefit compared to typical strategy
% LOAD DATA

%Determine percent difference
Ben = food_store(1,:); % CHANGE FILE NAME  
BenNorm = food_store_norm(1,:); % CHANGE FILE NAME

PercDiff = ((Ben-BenNorm)./BenNorm).*100;

%Percent Ben Difference across all series
figure
plot(PercDiff,'k-*','LineWidth',2)
hold on
hline = refline(0,0)
hline.Color = [0.50 0.50 0.50]

set(gca,'XTick',[1 5 10 15 20 25 30 35 40],'fontsize',16);
set(gca,'XTickLabels',{'1980','1985','1990','1995','2000','2005','2010','2015','2020'},'fontsize',16);
xlabel('Year','fontsize',16)
ylabel('Percent Difference (%)','fontsize',16)

%% FIGURE 5 - Difference in Mean Annual Expected Benefit (all, wet, dry)
%LOAD DATA 

MeanAnBenDiff = mean(food_store,2,'omitnan')-mean(food_store_norm,2,'omitnan'); % CHANGE FILE NAME
DryAnBenDiff = dry_ben(:,39)-dry_ben_norm(:,39); % CHANGE FILE NAME
WetAnBenDiff = wet_ben(:,39)-wet_ben_norm(:,39); % CHANGE FILE NAME

% Mean Annual Ben Difference across all series
figure
boxplot(MeanAnBenDiff) 
hold on
plot(MeanAnBenDiff(1,1)','k-*','LineWidth',2)
set(gca,'XTick',[1],'fontsize',16);
set(gca,'XTickLabels',{'All years'},'fontsize',16);
ylim([-500 3000])
ylabel('Difference in mean annual household benefit (birr/ha)','fontsize',16)
set(legend('Observed climate'),'fontsize',16)

figure
boxplot(WetAnBenDiff)
hold on
plot(WetAnBenDiff(1,1)','k-*','LineWidth',2)
set(gca,'XTick',[1],'fontsize',16);
set(gca,'XTickLabels',{'Wet years'},'fontsize',16);
ylim([-500 3000])
ylabel('Total household benefit (birr/ha)','fontsize',16)
set(legend('Observed climate'),'fontsize',16)

figure
boxplot(DryAnBenDiff)
hold on
plot(DryAnBenDiff(1,1)','k-*','LineWidth',2)
set(gca,'XTick',[1],'fontsize',16);
set(gca,'XTickLabels',{'Dry years'},'fontsize',16);
ylim([-500 3000])
ylabel('Total household benefit (birr/ha)','fontsize',16)
set(legend('Observed climate'),'fontsize',16)

%% FIGURE 6A - Forecast accuracy and adoption relationship
%LOAD DATA - file with precipitation prediction skill from ABM input

FcstAccuracy = zeros(100,1);

for i = 1:100
    for j = 1:39
        if PrecipSKILLwObs(j,i) > 0 
            FcstAccuracy(i) = FcstAccuracy(i) + 1;
        end
    end
end
FcstAc = (FcstAccuracy./39).*100;

TotalAdopt = sum(use_fcst,2);

figure
scatter(FcstAc,TotalAdopt,'ko')

set(gca,'XTick',[35:5:85],'fontsize',16);
set(gca,'XTickLabels',{'35','40','45','50','55','60','65','70','75','80','85'},'fontsize',16);
xlabel('Forecast accuracy (% correct)','fontsize',16)
ylabel('Total forecast use across all years','fontsize',16)

%% FIGURE 6B - Forecast accuracy and benefit relationship
% LOAD DATA

BenDiff = food_store - food_store_norm; % CHANGE FILE NAME
totalBenDiff = sum(BenDiff,2); % CHANGE FILE NAME
MeanAnBenDiff = mean(BenDiff,2); % CHANGE FILE NAME

FcstAccuracy = zeros(100,1);

for i = 1:100
    for j = 1:39
        if PrecipSKILLwObs(j,i) > 0 
            FcstAccuracy(i) = FcstAccuracy(i) + 1;
        end
    end
end
FcstAc = (FcstAccuracy./39).*100;

figure
scatter(FcstAc,MeanAnBenDiff,'ko')

set(gca,'XTick',[35:5:85],'fontsize',16);
set(gca,'XTickLabels',{'35','40','45','50','55','60','65','70','75','80','85'},'fontsize',16);
xlabel('Forecast accuracy (% correct)','fontsize',16)
ylabel('Difference in mean annual household benefit','fontsize',16)

%% FIGURE 7 - Boxplot of benefit based on adoption and accuracy

%Benefit for slowest/quickest adopted and low/high accuracy timeseries
slowAdoptBen = [-9.89530235528946e-10 1.29875843413174e-09 6718.52727783179 6445.83620143729 -1.91357685253024e-09];
quickAdoptBen = [12675.3975130659 17822.7058131195 840.416620918048 10174.5862538998 6180.75741305176];
lowAccBen = [-2.27373675443232e-09 -8.14907252788544e-10 -2.52839527092874e-09 -4.76575223729014e-10];
highAccBen = [14066.5935962341 16713.8826039756 21768.9095975718 8655.95753084256 16514.6652712955];

lowAccBen = [39547.4583370951 40138.3784069841 39377.9031973792 40573.7351788850];
highAccBen = [39279.0739811911 40486.2359650088 41175.3169694015 39683.7362978099 38950.9688216554];

x1 = lowAccBen';
x2 = highAccBen';
accuracyBen = [x1; x2];
g = [ones(size(x1)); 2*ones(size(x2))];

figure
boxplot(accuracyBen,g)
set(gca,'XTick',[1 2 3],'fontsize',16);
set(gca,'XTickLabels',{'Low','High'},'fontsize',16);
xlabel('Forecast Accuracy','fontsize',16)
ylabel('Difference in total household benefit (birr/ha)','fontsize',16)

y1 = slowAdoptBen';
y2 = quickAdoptBen';
adoptionBen = [y1; y2];
g2 = [ones(size(y1)); 2*ones(size(y2))];

figure
boxplot(adoptionBen,g2)
set(gca,'XTick',[1 2 3],'fontsize',16);
set(gca,'XTickLabels',{'Slow','Quick'},'fontsize',16);
ylim([-500 20000])
xlabel('Level of Adoption','fontsize',16)
ylabel('Difference in total household benefit (birr/ha)','fontsize',16)

%% FIGURE 8A and 8B - Percent categorical adoption (mean all climate series)

% LOAD DATA 
ABM_S1_percAdopt_early = X; % CHANGE FILE NAME
ABM_S1_percAdopt_mid = X; % CHANGE FILE NAME
ABM_S1_percAdopt_late = X; % CHANGE FILE NAME

% LOAD DATA 
ABM_S4_percAdopt_early = X; % CHANGE FILE NAME
ABM_S4_percAdopt_mid = X; % CHANGE FILE NAME
ABM_S4_percAdopt_late = X; % CHANGE FILE NAME

% PERCENT CAT ADOPTION OF FORECAST NO INTERACTION -- NO SOCIAL INTERACTION
figure
plot(ABM_S1_percAdopt_early,'k-','LineWidth',2)
hold on
plot(ABM_S1_percAdopt_mid,'k--','LineWidth',2)
hold on
plot(ABM_S1_percAdopt_late,'k:','LineWidth',2)

set(gca,'XTick',[1 5 10 15 20 25 30 35 40],'fontsize',16);
set(gca,'XTickLabels',{'1980','1985','1990','1995','2000','2005','2010','2015','2020'},'fontsize',16);
ylim([0 100])
xlabel('Year','fontsize',16)
ylabel('Total Percent Adopted','fontsize',16)
set(legend('Early','Middle','Late'),'fontsize',16)

% PERCENT CAT ADOPTION WITH INTERACTION & LEARNING
figure
plot(ABM_S4_percAdopt_early,'k-','LineWidth',2)
hold on
plot(ABM_S4_percAdopt_mid,'k--','LineWidth',2)
hold on
plot(ABM_S4_percAdopt_late,'k:','LineWidth',2)

set(gca,'XTick',[1 5 10 15 20 25 30 35 40],'fontsize',16);
set(gca,'XTickLabels',{'1980','1985','1990','1995','2000','2005','2010','2015','2020'},'fontsize',16);
ylim([0 100])
xlabel('Year','fontsize',16)
ylabel('Total Percent Adopted','fontsize',16)
set(legend('Early','Middle','Late'),'fontsize',16)


%% FIGURE 9 - Total number of strategy changes per adoption group

% LOAD DATA

nc = [early_NumChges,middle_NumChges,late_NumChges]; % CHANGE FILE NAMES

figure
B = bar(nc,'FaceColor','flat');
set(gca,'XTick',[1 2 3],'fontsize',16);
set(gca,'XTickLabels',{'Early','Middle','Late'},'fontsize',16);
xlabel('Adoption group','fontsize',16)
ylabel('Mean number of strategy changes','fontsize',16)
ylim([0 1.4])
B.CData(1,:) = [0.85 0.85 0.85];
B.CData(2,:) = [0.45 0.45 0.45];
B.CData(3,:) = [0 0 0];

%% FIGURE 10 - Adoption, Trust, and Mean Annual Benefit by accuracy with/without learning
% LOAD DATA

A = [Accuracy(1,5),Accuracy(1,6),Accuracy(1,7);
    Accuracy(2,5),Accuracy(2,6),Accuracy(2,7);
    Accuracy(3,5),Accuracy(3,6),Accuracy(3,7);
    Accuracy(4,5),Accuracy(4,6),Accuracy(4,7);
    Accuracy(5,5),Accuracy(5,6),Accuracy(5,7)];

AerrStd = [AccuracyStd(1,5),AccuracyStd(1,6),AccuracyStd(1,7);
    AccuracyStd(2,5),AccuracyStd(2,6),AccuracyStd(2,7);
    AccuracyStd(3,5),AccuracyStd(3,6),AccuracyStd(3,7);
    AccuracyStd(4,5),AccuracyStd(4,6),AccuracyStd(4,7);
    AccuracyStd(5,5),AccuracyStd(5,6),AccuracyStd(5,7)];

T = [Accuracy(1,8),Accuracy(1,9),Accuracy(1,10);
    Accuracy(2,8),Accuracy(2,9),Accuracy(2,10);
    Accuracy(3,8),Accuracy(3,9),Accuracy(3,10);
    Accuracy(4,8),Accuracy(4,9),Accuracy(4,10);
    Accuracy(5,8),Accuracy(5,9),Accuracy(5,10)];

TerrStd = [AccuracyStd(1,8),AccuracyStd(1,9),AccuracyStd(1,10);
    AccuracyStd(2,8),AccuracyStd(2,9),AccuracyStd(2,10);
    AccuracyStd(3,8),AccuracyStd(3,9),AccuracyStd(3,10);
    AccuracyStd(4,8),AccuracyStd(4,9),AccuracyStd(4,10);
    AccuracyStd(5,8),AccuracyStd(5,9),AccuracyStd(5,10)];

Ben = [AccuracyBen(1,2),AccuracyBen(1,3),AccuracyBen(1,4);
    AccuracyBen(2,2),AccuracyBen(2,3),AccuracyBen(2,4);
    AccuracyBen(3,2),AccuracyBen(3,3),AccuracyBen(3,4);
    AccuracyBen(4,2),AccuracyBen(4,3),AccuracyBen(4,4);
    AccuracyBen(5,2),AccuracyBen(5,3),AccuracyBen(5,4)];

BerrStd = [AccuracyBenStd(1,2),AccuracyBenStd(1,3),AccuracyBenStd(1,4);
    AccuracyBenStd(2,2),AccuracyBenStd(2,3),AccuracyBenStd(2,4);
    AccuracyBenStd(3,2),AccuracyBenStd(3,3),AccuracyBenStd(3,4);
    AccuracyBenStd(4,2),AccuracyBenStd(4,3),AccuracyBenStd(4,4);
    AccuracyBenStd(5,2),AccuracyBenStd(5,3),AccuracyBenStd(5,4)];

% ADOPTION
figure
model_series = A;
model_errlow = AerrStd;
model_errhigh = AerrStd;

B = bar(model_series);
hold on
% Find the number of groups and the number of bars in each group
ngroups = size(model_series, 1);
nbars = size(model_series, 2);
% Calculate the width for each bar group
groupwidth = min(0.8, nbars/(nbars + 1.5));
% Set the position of each error bar in the centre of the main bar
for i = 1:nbars
    % Calculate center of each bar
    x = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
    errorbar(x, model_series(:,i), model_errlow(:,i),model_errhigh(:,i), 'k', 'linestyle', 'none','LineWidth',1.5);
end
hold off

set(gca,'XTick',[1 2 3 4 5],'fontsize',16);
set(gca,'XTickLabels',{'35','45','55','65','75'},'fontsize',16);
xlabel('Mean Climate Forecast Accuracy (%)','fontsize',16)
ylabel('Total Percentage Adoption (%)','fontsize',16)
ylim([0 85])
set(legend('Early','Middle','Late'),'fontsize',16)
B(1).FaceColor = [0.95 0.95 0.95];
B(2).FaceColor = [0.7 0.7 0.7];
B(3).FaceColor = [0.45 0.45 0.45];

% TRUST
figure
model_series = T;
model_errlow = TerrStd;
model_errhigh = TerrStd; 

B= bar(model_series);
hold on
% Find the number of groups and the number of bars in each group
ngroups = size(model_series, 1);
nbars = size(model_series, 2);
% Calculate the width for each bar group
groupwidth = min(0.8, nbars/(nbars + 1.5));
% Set the position of each error bar in the centre of the main bar
for i = 1:nbars
    % Calculate center of each bar
    x = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
    errorbar(x, model_series(:,i), model_errlow(:,i),model_errhigh(:,i), 'k', 'linestyle', 'none','LineWidth',1.5);
end
hold off

set(gca,'XTick',[1 2 3 4 5],'fontsize',16);
set(gca,'XTickLabels',{'35','45','55','65','75'},'fontsize',16);
xlabel('Mean Climate Forecast Accuracy (%)','fontsize',16)
ylabel('End Trust Level (FTU)','fontsize',16)
ylim([-30 60])
set(legend('Early','Middle','Late'),'fontsize',16)
B(1).FaceColor = [0.95 0.95 0.95];
B(2).FaceColor = [0.7 0.7 0.7];
B(3).FaceColor = [0.45 0.45 0.45];

% BENEFIT
figure
model_series = Ben;
model_errlow = BerrStd; 
model_errhigh = BerrStd;

B= bar(model_series);
hold on
% Find the number of groups and the number of bars in each group
ngroups = size(model_series, 1);
nbars = size(model_series, 2);
% Calculate the width for each bar group
groupwidth = min(0.8, nbars/(nbars + 1.5));
% Set the position of each error bar in the centre of the main bar
for i = 1:nbars
    % Calculate center of each bar
    x = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
    errorbar(x, model_series(:,i), model_errlow(:,i),model_errhigh(:,i), 'k', 'linestyle', 'none','LineWidth',1.5);
end
hold off

set(gca,'XTick',[1 2 3 4 5],'fontsize',16);
set(gca,'XTickLabels',{'35','45','55','65','75'},'fontsize',16);
xlabel('Mean Climate Forecast Accuracy (%)','fontsize',16)
ylabel('Difference in Mean Annual Benefit (Birr/ha)','fontsize',16)
set(legend('Early','Middle','Late'),'fontsize',16)
B(1).FaceColor = [0.95 0.95 0.95];
B(2).FaceColor = [0.7 0.7 0.7];
B(3).FaceColor = [0.45 0.45 0.45];

%% FIGURE 11 - Trust throughout time by adoption group

% LOAD DATA

ABM_trustE = meanTrust_EA; % CHANGE FILE NAMES
ABM_trustM = meanTrust_MA; % CHANGE FILE NAMES
ABM_trustL = meanTrust_LA; % CHANGE FILE NAMES

earlyTr = zeros(100,1);
middleTr = zeros(100,1);
lateTr = zeros(100,1);

for j = 2:5:40
    earlyTr = cat(2,earlyTr,ABM_trustE(:,j));
    middleTr = cat(2,middleTr,ABM_trustM(:,j));
    lateTr = cat(2,lateTr,ABM_trustL(:,j));
end

%plot
figure
x = cell(3,1);
x{1,1} = earlyTr(:,2:9);
x{2,1} = middleTr(:,2:9);
x{3,1} = lateTr(:,2:9);
boxplot2(permute(cat(3, x{:}), [2 3 1]), 1:8)
set(gca,'XTick',[0:8],'fontsize',16);
set(gca,'XTickLabels',{'0','1','5','10','15','20','25','30','35','40'},'fontsize',16);
xlabel('Year','fontsize',16)
ylabel('Forecast trust units','fontsize',16)

%set colors
colors = [1,0,0;0,0,0;0,0,1;1,0,0;0,0,0;0,0,1;1,0,0;0,0,0;0,0,1;1,0,0;0,0,0;0,0,1;
    1,0,0;0,0,0;0,0,1;1,0,0;0,0,0;0,0,1;1,0,0;0,0,0;0,0,1;1,0,0;0,0,0;0,0,1];
    
h = findobj(gca,'Tag','Box');
for j=1:length(h)
    patch(get(h(j),'XData'),get(h(j),'YData'),colors(j,:),'FaceAlpha',.25);
end
