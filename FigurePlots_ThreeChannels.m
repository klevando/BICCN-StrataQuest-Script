% Program to plot expression of various genes across a brain slice based 
% on StrataQuest results. 
% 2022-08-31 - Kirsten Levandowski

% Plot options include: 
% (1) plotting scatter plot of gene (MOI) and dapi (plot_channels_dapi = 1),
% (2) plotting mediolateral bar graphs of gene normalized to dapi (plot_normalization = 1),
% (3) plotting downsampled scatter plots of gene and dapi (plot_downsample = 1), 
% (4)plotting histograms of gene normalized to dapi across the A/P and D/V 
% axes per slice, plotting histograms of dapi and gene, and plotting gene 
% histograms around scatter plot for easier interpretation of histograms 
% (plot_hist = 1), and
% (5) plotting density heatmaps of genes, dapi, and gene normalized to
% dapi. dscatter plot (density scatter plot) of gene all generated
% (plot_density = 1).

%% clear variables and close anything

% clear variables
clear variables;

% do not display figures when 'off'
set(0,'DefaultFigureVisible', 'on');

% close everything
close all force;
close all hidden;
status = close('all','hidden');
disp(strcat('close all status: ', num2str(status)));

%% input information

% plot figures - 0 = no, 1 = yes
aa = inputdlg({'Scatterplot, eg: 1 = yes, 0 = no','M/L Bar Plots', ...
    'Downsampled Scatterplots', 'Histograms', 'Density Heatmaps'}, ...
    'Select Plotting Types - 1 = plot, 0 = no plot');
plot_channels_dapi = str2num(aa{1});
plot_normalization = str2num(aa{2});
plot_downsample = str2num(aa{3});
plot_hist = str2num(aa{4});
plot_density = str2num(aa{5});

% select brain area
balist = {'ctx', 'str'};
[indxba] = listdlg('ListString', balist, 'SelectionMode', 'single');
brainarea = balist(indxba);

%% define constants

% make output folder in working directory to save csv files separately
path = pwd;
mkdir Output;
out_path = strcat(path, '/Output/');

% calculate number of channels used by determining if present in 
% directory (dapi always last set)
on_488 = length(dir('488*'))>0;
on_594 = length(dir('594*'))>0;
on_647 = length(dir('647*'))>0;
num_ch = on_488 + on_594 + on_647 + 1;

% calculate the number of brain slices per channel - 
% can also use num_s = size(dir('dapi*'));
num_s = length(dir('*.csv'))/num_ch;

% input channel information, marker of interest (MOI), and brain area
if num_ch >= 3
    % specify which channels correspond with given gene
    xx = inputdlg({'ch-488','ch-594','ch-647'}, 'Gene Names');
    ch488 = xx{1};
    ch594 = xx{2};
    ch647 = xx{3};
else
    % select gene for colormap
    genelist = {'cck', 'cxcl14', 'gad1', 'lamp5', 'lamp5-gad1', 'pvalb', ...
        'slc5a7', 'sst', 'tac3', 'th', 'vip'};
    [indxgene] = listdlg('ListString', genelist, 'SelectionMode', 'single');
    MOI = genelist(indxgene);
end

% determine the brain slices (s) and the section intervals (sm) based on 
% the dapi sections in the directory
a = dir('dapi*');
for z = 1:size(a)
    s(z) = str2num(cell2mat(regexp(a(z).name, '\d+', 'match'))); 
end

% if there is only one section, sm = 0
if num_s > 1
    sm = s(2) - s(1);
else            %elseif s == 1
    sm = 0;
end

s1 = s(1);

% calculate the first entry in the last row (first dapi image) in order
% to compare genes of interested against dapi
dapi_set=((num_ch-1)*num_s);

% set channel order for dual pos plots
if on_488 == 1 && on_594 == 1 && on_647 == 1
    ch1 = ch488;
    ch2 = ch594;
    ch3 = ch647;
elseif on_488 == 1 && on_594 == 1 && on_647 == 0
    ch1 = ch488;
    ch2 = ch594;
elseif on_488 == 1 && on_594 == 0 && on_647 == 1
    ch1 = ch488;
    ch2 = ch647;
elseif on_488 == 0 && on_594 == 1 && on_647 == 1
    ch1 = ch594;
    ch2 = ch647;
end

% dapi channel always last and fourth channel
chdapi='dapi';

% determine the brain area from the file name
b = dir('*.csv');
c = extractAfter(b(1).name,mat2str(s1));
d = extractBefore(c,'.');
a1 = extractAfter(d,'_');

% load spreadsheet column headers
if num_ch == 4
    load('selectedVariableNames_488_594_647.mat');
elseif on_488 == 1 && on_594 == 1 && on_647 == 0
    load('selectedVariableNames_488_594.mat');
elseif on_488 == 1 && on_594 == 0 && on_647 == 1
    load('selectedVariableNames_488_647.mat');
elseif on_488 == 0 && on_594 == 1 && on_647 == 1
    load('selectedVariableNames_594_647.mat');
elseif on_488 == 1 && on_594 == 0 && on_647 == 0
    load('selectedVariableNames_488.mat');
elseif on_488 == 0 && on_594 == 1 && on_647 == 0
    load('selectedVariableNames_594.mat');
elseif on_488 == 0 && on_594 == 0 && on_647 == 1
    load('selectedVariableNames_647.mat');
else
    disp('error with variable names - type \" ds.SelectedVariableNames\" into command window to see naming options');
end


%% define plotting constants

% spreadsheet columns for location of x, y
x = 2;
y = 3;

% graphing point size
ps = 500;

% graphing line width
lw = 50;

% graphing marker colors
mcdapi = [0.9 0.9 0.9];     %light grey [0.9 0.9 0.9]

% use colormap for given gene
if num_ch == 2
    if contains(MOI, 'sst', IgnoreCase=true)
        ch647 = 'SST';
        mc = [103/255 94/255 168/255]; % blue purple 675ea8
        mc647 = [103/255 94/255 168/255]; % blue purple 675ea8
        sst1 = [231/255 219/255 255/255]; %e7dbff
        sst2 = [189/255 175/255 255/255]; %bdafe1
        sst3 = [147/255 133/255 196/255]; %9385c4
        sst4 = [75/255 68/255 117/255]; %4b4475
        sst5 = [47/255 43/255 70/255]; %2f2b46
        sst6 = [30/255 27/255 62/255]; %1e1b3e
        sst7 = [16/255 9/255 39/255]; %100927
    
        map = [sst1; sst2; sst3; mc; sst4; sst5; sst6; sst7];
    end
    if contains(MOI, 'tac3', IgnoreCase=true)
        ch647 = 'TAC3';
        mc = [211/255 160/255 200/255]; % lavender d3a0c8
        mc647 = [211/255 160/255 200/255]; % lavender d3a0c8
        ta1 = [253/255 232/255 248/255]; %fde8f8
        ta2 = [239/255 208/255 232/255]; %efd0e8
        ta3 = [225/255 184/255 216/255]; %e1b8d8
        ta4 = [155/255 116/255 146/255]; %9b7492
        ta5 = [102/255 75/255 95/255]; %664b5f
    
        map = [ta1; ta2; ta3; mc; ta4; ta5];
    end
    if contains(MOI, 'cck', IgnoreCase=true)
        ch647 = 'CCK';
        mc = [76/255 133/255 197/255]; % blue 4c85c5
        mc647 = [76/255 133/255 197/255]; % blue 4c85c5
        cck1 = [225/255 239/255 255/255]; %e1efff
        cck2 = [176/255 203/255 236/255]; %b0cbec
        cck3 = [127/255 168/255 216/255]; %7fa8d8
        cck4 = [58/255 96/255 140/255]; %3a608c
        cck5 = [41/255 62/255 88/255]; %293e58
    
        map = [cck1; cck2; cck3; mc; cck4; cck5];
    end
    if contains(MOI, 'pvalb', IgnoreCase=true)
        ch488 = 'PVALB';
        mc = [241/255 90/255 36/255]; % orange f15a25
        mc488 = [241/255 90/255 36/255]; % orange f15a25
        pv1 = [255/255 209/255 174/255]; %ffd1ae
        pv2 = [252/255 173/255 122/255]; %fcad7a
        pv3 = [247/255 135/255 77/255]; %f7874d
        pv4 = [182/255 55/255 31/255]; %b6371f
        pv5 = [124/255 24/255 21/255]; %7c1815
        pv6 = [88/255 27/255 14/255]; %581b0e
        pv7 = [55/255 14/255 0/255]; %370e00
    
        map = [pv1; pv2; pv3; mc; pv4; pv5; pv6; pv7];
    end
    if contains(MOI, 'th', IgnoreCase=true)
        ch647 = 'TH';
        mc = [248/255 163/255 81/255]; % yellow f8a351
        mc647 = [248/255 163/255 81/255]; % yellow f8a351
        th1 = [255/255 241/255 215/255]; %fff1d7
        th2 = [251/255 217/255 167/255]; %fbd9a7
        th3 = [249/255 191/255 122/255]; %f9bf7a
        th4 = [169/255 110/255 57/255]; %a96e39
        th5 = [95/255 62/255 33/255]; %5f3e21
    
        map = [th1; th2; th3; mc; th4; th5];
    end
    % if contains(MOI, 'chat', IgnoreCase=true)
    %     ch488 = 'CHAT';
    %     mc = [154/255 28/255 30/255]; % dark red 9a1c1e
    %     mc488 = [154/255 28/255 30/255]; % dark red 9a1c1e
    %     chat1 = [220/255 192/255 188/255]; %dcc0bc
    %     chat2 = [204/255 140/255 132/255]; %cc8c84
    %     chat3 = [182/255 89/255 79/255]; %b6594f
    %     chat4 = [105/255 29/255 26/255]; %691d1a
    %     chat5 = [60/255 25/255 21/255]; %3c1915
    %
    %     map = [chat1; chat2; chat3; mc; chat4; chat5];
        % end
    
    if contains(MOI, 'slc5a7', IgnoreCase=true)
        ch647 = 'SLC5A7';
        mc = [221/255 56/255 56/255]; % red dd3838
        mc647 = [221/255 56/255 56/255]; % red dd3838
        sl1 = [255/255 226/255 218/255]; %ffe2da
        sl2 = [250/255 175/255 157/255]; %faaf9d
        sl3 = [238/255 121/255 103/255]; %ee7967
        sl4 = [162/255 33/255 41/255]; %a22129
        sl5 = [106/255 13/255 25/255]; %6a0d19
    
        map = [sl1; sl2; sl3; mc; sl4; sl5];
    end
    if contains(MOI, 'lamp5', IgnoreCase=true)
        ch647 = 'LAMP5';
        mc = [168/255 213/255 157/255]; % celadon a8d59d
        mc647 = [168/255 213/255 157/255]; % celadon a8d59d
        %     lamp1 = [242/255 248/255 240/255]; %f2f8f0
        lamp2 = [218/255 236/255 212/255]; %daecd4
        lamp3 = [193/255 225/255 184/255]; %c1e1b8
        lamp4 = [107/255 143/255 102/255]; %6b8f66
        lamp5 = [52/255 78/255 52/255]; %344e34
        lamp6 = [32/255 56/255 33/255]; %203821
        lamp7 = [0/255 24/255 0/255]; %001800
    
        map = [lamp2; lamp3; mc647; lamp4; lamp5; lamp6; lamp7];
    end
    if contains(MOI, 'gad1', IgnoreCase=true)
        ch488 = 'GAD1';
        mc = [51/255 51/255 51/255]; % gad1 charcoal 333333
        mc488 = [51/255 51/255 51/255]; % gad1 charcoal 333333
        ga1 = [187/255 187/255 187/255]; %bbbbbb
        ga2 = [138/255 138/255 138/255]; %8a8a8a
        ga3 = [93/255 93/255 93/255]; %5d5d5d
        ga4 = [36/255 36/255 36/255]; %242424
        ga5 = [0 0 0]; %000000
    
        map = [ga1; ga2; ga3; mc488; ga4; ga5];
    end
    if contains(MOI, 'lamp5-gad1', IgnoreCase=true)
        ch488 = 'LAMP5-GAD1';
        mc = [168/255 213/255 157/255]; % celadon a8d59d
        mc488 = [168/255 213/255 157/255]; % celadon a8d59d
        %     lamp1 = [242/255 248/255 240/255]; %f2f8f0
        lamp2 = [218/255 236/255 212/255]; %daecd4
        lamp3 = [193/255 225/255 184/255]; %c1e1b8
        lamp4 = [107/255 143/255 102/255]; %6b8f66
        lamp5 = [52/255 78/255 52/255]; %344e34
        lamp6 = [32/255 56/255 33/255]; %203821
        lamp7 = [0/255 24/255 0/255]; %001800
    
        map = [lamp2; lamp3; mc488; lamp4; lamp5; lamp6; lamp7];
    end
    if contains(MOI, 'vip', IgnoreCase=true)
        ch488 = 'VIP';
        mc = [43/255 160/255 149/255]; % teal 2ba095
        mc488 = [43/255 160/255 149/255]; % teal 2ba095
        vip1 = [216/255 233/255 230/255]; %d8e9e6
        vip2 = [165/255 209/255 202/255]; %a5d1ca
        vip3 = [112/255 184/255 175/255]; %70b8af
        vip4 = [35/255 107/255 99/255]; %236b63
        vip5 = [23/255 59/255 54/255]; %173b36
        vip6 = [9/255 52/255 43/255]; %09342b
        vip7 = [0/255 29/255 22/255]; %001d16
    
        map = [vip1; vip2; vip3; mc; vip4; vip5; vip6; vip7];
    end
    if contains(MOI, 'cxcl14', IgnoreCase=true)
        ch647 = 'CXCL14';
        mc = [128/255 76/255 116/255]; % red purple 804c74
        mc647 = [128/255 76/255 116/255]; % red purple 804c74
        cx1 = [235/255 223/255 231/255]; %ebdfe7
        cx2 = [199/255 172/255 191/255]; %c7acbf
        cx3 = [164/255 123/255 153/255]; %a47b99
        cx4 = [94/255 58/255 86/255]; %5e3a56
        cx5 = [62/255 41/255 57/255]; %3e2939
        cx6 = [41/255 19/255 34/255]; %291322
        cx7 = [24/255 0/255 16/255]; %180010
    
        map = [cx1; cx2; cx3; mc; cx4; cx5; cx6; cx7];
    end
    % if contains(MOI, 'drd1', IgnoreCase=true)
    %     ch594 = 'DRD1';
    %     mc = [10/255 0/255 89/255]; %0a0059 drd1
    %     mc594 = [10/255 0/255 89/255]; %0a0059 drd1
    %     mc647 = [211/255 160/255 200/255]; % tac3 d3a0c8
%         end
    % elseif contains(MOI, 'drd2', IgnoreCase=true)
    %     ch594 = 'DRD2';
    %     mc = [10/255 51/255 49/255]; %0a3331 drd2
    %     mc594 = [10/255 51/255 49/255]; %0a3331 drd2
    %     mc647 = [211/255 160/255 200/255]; % tac3 d3a0c8
%       end
    if (MOI == "")
        mc = [1 1 1];
        mc488 = [0 1 0];
        mc594 = [1 0 1];
        mc647 = [0 0 1];
        map = 'turbo';
    end
elseif num_ch >= 3
    if contains(ch488, 'sst', 'IgnoreCase', true)
        mc = [103/255 94/255 168/255]; % blue purple 675ea8
        mc488 = [103/255 94/255 168/255]; % blue purple 675ea8)
        map = 'turbo';
        MOI = 'SST';
    end
    if contains(ch594, 'sst', 'IgnoreCase', true)
        mc = [103/255 94/255 168/255]; % blue purple 675ea8
        mc594 = [103/255 94/255 168/255]; % blue purple 675ea8)
        map = 'turbo';
        MOI = 'SST';
    end
    if contains(ch647, 'sst', 'IgnoreCase', true)
        mc = [103/255 94/255 168/255]; % blue purple 675ea8
        mc647 = [103/255 94/255 168/255]; % blue purple 675ea8)
        map = 'turbo';
        MOI = 'SST';
    end
    if contains(ch647, 'th', 'IgnoreCase', true)
        mc = [248/255 163/255 81/255]; % yellow f8a351
        mc647 = [248/255 163/255 81/255]; % yellow f8a351
        map = 'turbo';
        MOI = 'TH';
    end
    if contains(ch488, 'pvalb', 'IgnoreCase', true)
        mc = [241/255 90/255 36/255]; % orange f15a25
        mc488 = [241/255 90/255 36/255]; % orange f15a25
        map = 'turbo';
        MOI = 'PVALB';
    end
end



% graphing marker shape
ms = 'o';

% graphing marker transparance
mt = '1';

% graph axis sizing
if contains(brainarea, 'ctx', IgnoreCase=true)
    z = [-5000 200000 -5000 200000];
elseif contains(brainarea, 'str', IgnoreCase=true)
    z = [-5000 70000 -5000 70000];
else
    z = [-5000 200000 -5000 200000];
end


%% read in excel files and plot

% use tabulartext datastore to read in multiple CSV files from 
% working directory (pwd), select the variables of interest
ds = tabularTextDatastore(pwd,'FileExtensions', ['.csv']);
if num_ch == 4
    ds.SelectedVariableNames = {eventlabel, x_pos_488, y_pos_488, ...
        mean_int_488, mean_int_594, mean_int_647}; 
elseif on_488 == 1 && on_594 == 1 && on_647 == 0
    ds.SelectedVariableNames = {eventlabel, x_pos_488, y_pos_488, ...
        mean_int_488, mean_int_594};
elseif on_488 == 1 && on_594 == 0 && on_647 == 1
    ds.SelectedVariableNames = {eventlabel, x_pos_488, y_pos_488, ...
        mean_int_488, mean_int_647};
elseif on_488 == 0 && on_594 == 1 && on_647 == 1 
    ds.SelectedVariableNames = {eventlabel, x_pos_594, y_pos_594, ...
        mean_int_594, mean_int_647};
elseif on_488 == 1 && on_594 == 0 && on_647 == 0
    ds.SelectedVariableNames = {eventlabel, x_pos_488, y_pos_488, ...
        mean_int_488};
elseif on_488 == 0 && on_594 == 1 && on_647 == 0
    ds.SelectedVariableNames = {eventlabel, x_pos_594, y_pos_594, ...
        mean_int_594};
elseif on_488 == 0 && on_594 == 0 && on_647 == 1
    ds.SelectedVariableNames = {eventlabel, x_pos_647, y_pos_647, ...
        mean_int_647};
end

num_files = length(ds.Files);

% read in files and create a table the total number of cells
for i = 1:num_files
    subds = partition(ds,'Files',i);
    subds.ReadSize = 'file';
    subds.TreatAsMissing = 'AVG=';    % remove from csv
    subds.MissingValue = 0;

    T{i} = read(subds);               % read in data into table T
%     T1{i} = T{i}(1:end-1,:);          % table T minus the last row if not using TreatAsMissing
    T1{i} = T{i}(1:end-2,:);          % table T minus the last two rows if using TreatAsMissing
    T1sort{i} = sortrows(T1{i}, 2);     %sort T1 based on x value (column 2)    
    E{i} = height(T1{i});
    E_array(i) = cell2mat(E(i));
%     E{i} = T{i}(end,1);               % number of event labels in a given file (last cell in Event label column)
%     E_array(i) = table2array(E{i});   % created numerical table of event table E
    size(T1{i})
end

% read in intersection event labels into cell array I
if num_ch > 2   % must have more than one channel and dapi in order to run loop
    for u = 1:num_s
        % find any dual pos (potentially pos for third gene)
        Total_Dual{u} = intersect(T1{u}, T1{u+num_s});                          % intersection of first and second gene
        num_Total_Dual{u} = height(Total_Dual{u});
    end
end

% save numerical arrays of triple and dual positives
if num_ch > 2
    num_Total_Dual = cell2mat(num_Total_Dual);      % save Total_Dual as normal array
end

%% plot genes against dapi and separately and intensity

for k = 0:num_ch-1
    for j = 1:num_s
        b = dir('*.csv');
        f = b(num_s*k+j).name;
        slice = s(j);

        % plot channels against dapi
        if plot_channels_dapi == 1
            if contains(f,'488')
                scatter_dapi(T1{j+dapi_set}, mcdapi, T1{num_s*k+j}, mc488, chdapi, ...
                    ch488, num2str(slice), a1, z);
                saveas(gcf, strcat(out_path,'scatter-dapi_', ch488, ...
                    '_slice', num2str(slice) ,'_', a1, '.png'));
            end
            if contains(f,'594')
                scatter_dapi(T1{j+dapi_set}, mcdapi, T1{num_s*k+j}, mc594, chdapi, ...
                    ch594, num2str(slice), a1, z);
                saveas(gcf, strcat(out_path,'scatter-dapi_', ch594, ...
                    '_slice', num2str(slice) ,'_', a1, '.png'));
            end
            if contains(f,'647')
                scatter_dapi(T1{j+dapi_set}, mcdapi, T1{num_s*k+j}, mc647, chdapi, ...
                    ch647, num2str(slice), a1, z);
                saveas(gcf, strcat(out_path,'scatter-dapi_', ch647, ...
                    '_slice', num2str(slice) ,'_', a1, '.png'));
            end
        end

        % create normalized tables
        if plot_normalization == 1
            if contains(f, '488')
                N_488(j) = (E_array(num_s*k+j)/E_array(j+dapi_set)*100);
            end
            if contains(f, '594')
                N_594(j) = (E_array(num_s*k+j)/E_array(j+dapi_set)*100);
            end
            if contains(f, '647')
                N_647(j) = (E_array(num_s*k+j)/E_array(j+dapi_set)*100);
            end

            % create normalized tables for dual pos normalized to dapi
            if num_ch > 2
                N_Total_Dual_dapi(j) = (num_Total_Dual(j)/E_array(j+dapi_set)*100);
            end

        end        
    end
end

%% save output as csv file in output folder

% write csv files for events
if num_ch == 4
    filename = string(strcat(ch488,'_', ch594, '_', ch647, '_', ...
        num2str(slice), '_', a1, '_EventLabels.csv'));
    file_path = strcat(out_path, filename);
    writematrix(E_array, file_path, 'WriteMode', 'overwrite');
end
if on_488 == 1 && on_594 == 1 && on_647 == 0
    filename = string(strcat(ch488, '_', ch594, '_', num2str(slice), ...
        '_', a1, '_EventLabels.csv'));
    file_path = strcat(out_path, filename);
    writematrix(E_array, file_path, 'WriteMode', 'overwrite');
elseif on_488 == 1 && on_594 == 0 && on_647 == 1
    filename = string(strcat(ch488, '_', ch647, '_', num2str(slice), ...
        '_', a1, '_EventLabels.csv'));
    file_path = strcat(out_path, filename);
    writematrix(E_array, file_path, 'WriteMode', 'overwrite');
elseif on_488 == 0 && on_594 == 1 && on_647 == 1
    filename = string(strcat(ch594, '_', ch647, '_', num2str(slice), ...
        '_', a1, '_EventLabels.csv'));
    file_path = strcat(out_path, filename);
    writematrix(E_array, file_path, 'WriteMode', 'overwrite');
elseif on_488 == 1 && on_594 == 0 && on_647 == 0
    filename = string(strcat(ch488, '_', num2str(slice), '_', ...
        a1, '_EventLabels.csv'));
    file_path = strcat(out_path, filename);
    writematrix(E_array, file_path, 'WriteMode', 'overwrite');
elseif on_488 == 0 && on_594 == 1 && on_647 == 0
    filename = string(strcat(ch594, '_', num2str(slice), '_', ...
        a1, '_EventLabels.csv'));
    file_path = strcat(out_path, filename);
    writematrix(E_array, file_path, 'WriteMode', 'overwrite');
elseif on_488 == 0 && on_594 == 0 && on_647 == 1
    filename = string(strcat(ch647, '_', num2str(slice), '_', ...
        a1, '_EventLabels.csv'));
    file_path = strcat(out_path, filename);
    writematrix(E_array, file_path, 'WriteMode', 'overwrite');
end

%% plot normalized counts against dapi

% plot medio-lateral bar plots of genes normalized to dapi
if plot_normalization == 1
    if on_488 == 1
        % plot gene 488 normalized to dapi
        normalized_plot(s, N_488, mc488, ch488, a1, chdapi);
        if num_s > 1
            xticks(s(1):sm:s(num_s));
        elseif s == 1
            xticks([s(1)]);
        end

        saveas(gcf, strcat(out_path,'norm-dapi_', ch488, ...
            '_', a1, '.png'));
        filename = string(strcat('normalization-dapi_', ch488, '_', a1, '.csv'));
        file_path = strcat(out_path, filename);
        writematrix(N_488, file_path, 'WriteMode', 'overwrite');
    end
    if on_594 == 1
        % plot gene 594 normalized to dapi
        normalized_plot(s, N_594, mc594, ch594, a1, chdapi);
        if num_s > 1
            xticks(s(1):sm:s(num_s));
        elseif s == 1
            xticks([s(1)]);
        end

        saveas(gcf, strcat(out_path,'norm-dapi_', ch594, ...
            '_', a1, '.png'));
        filename = string(strcat('normalization-dapi_', ch594, '_', a1, '.csv'));
        file_path = strcat(out_path, filename);
        writematrix(N_594, file_path, 'WriteMode', 'overwrite');
    end
    if on_647 == 1
        % plot gene 647 normalized to dapi
        normalized_plot(s, N_647, mc647, ch647, a1, chdapi);
        if num_s > 1
            xticks(s(1):sm:s(num_s));
        elseif s == 1
            xticks([s(1)]);
        end

        saveas(gcf, strcat(out_path,'norm-dapi_', ch647, ...
            '_', a1, '.png'));
        filename = string(strcat('normalization-dapi_', ch647, '_', a1, '.csv'));
        file_path = strcat(out_path, filename);
        writematrix(N_647, file_path, 'WriteMode', 'overwrite');
    end
end

%% downsampling for vectorized images

% downsample scatter plots if needed for saving large vector graphic files
if plot_downsample == 1
    % how many bins you want for the first slice
    dd = inputdlg({'Multiplier for Downsampling - Enter a decimal less than 1'}, 'Multiplier for Downsampling');
    multiplier = str2num(dd{1});

    for p = 0:num_ch-1
        for pp = 1:num_s
            % dapi and gene array
            b = dir('*.csv');
            f = b(num_s * p + pp).name;
            slice = s(pp);

            if contains(f, '488')
                T1_488{pp} = table2array(T1{num_s * p + pp});
                height_T1_488{pp} = height(T1_488{pp});

                % index with randsample
                index_488{pp} = randsample(1:size(T1{num_s * p + pp}, 1), round(height_T1_488{pp}*multiplier));
                dsT1_488{pp} = T1_488{pp}(index_488{pp}, :);
                
                % plot 
                figure;
                hold on;
                scatter(dsT1_488{pp}(:,2), dsT1_488{pp}(:,3), 'filled', 'MarkerFaceColor', mc488,'Marker', 'o', ...
                    'SizeData', 5, 'MarkerFaceAlpha',1);
                title(strcat('Downsampled Scatter - ', ch488, ' Slice - ', num2str(slice)));
                xlabel('x position');
                ylabel('y position');
                legend(ch488, 'Location', 'best');
                axis(z);
                hold off;
            end
            if contains(f, '594')
                T1_594{pp} = table2array(T1{num_s * p + pp});
                height_T1_594{pp} = height(T1_594{pp});

                % index with randsample
                index_594{pp} = randsample(1:size(T1{num_s * p + pp}, 1), round(height_T1_594{pp}*multiplier));
                dsT1_594{pp} = T1_594{pp}(index_594{pp}, :);

                figure;
                hold on;
                scatter(dsT1_594{pp}(:,2), dsT1_594{pp}(:,3), 'filled', 'MarkerFaceColor', mc594,'Marker', 'o', ...
                    'SizeData', 5, 'MarkerFaceAlpha',1);
                title(strcat('Downsampled Scatter - ', ch594, ' Slice - ', num2str(slice)));
                xlabel('x position');
                ylabel('y position');
                legend(ch594, 'Location', 'best');
                axis(z);
                hold off;
            end
            if contains(f, '647')
                T1_647{pp} = table2array(T1{num_s * p + pp});
                height_T1_647{pp} = height(T1_647{pp});

                % index with randsample
                index_647{pp} = randsample(1:size(T1{num_s * p + pp}, 1), round(height_T1_647{pp}*multiplier));
                dsT1_647{pp} = T1_647{pp}(index_647{pp}, :);

                figure;
                hold on;
                scatter(dsT1_647{pp}(:,2), dsT1_647{pp}(:,3), 'filled', 'MarkerFaceColor', mc647,'Marker', 'o', ...
                    'SizeData', 5, 'MarkerFaceAlpha',1);
                title(strcat('Downsampled Scatter - ', ch647, ' Slice - ', num2str(slice)));
                xlabel('x position');
                ylabel('y position');
                legend(ch647, 'Location', 'best');
                axis(z);
                hold off;
            end
            if contains(f, 'dapi')
                T1_dapi{pp} = table2array(T1{pp + dapi_set});
                heightT1dapi{pp} = height(T1_dapi{pp});

                % index dapi with randsample
                indexdapi{pp} = randsample(1:size(T1_dapi{pp}, 1), round(heightT1dapi{pp}*multiplier));
                dsT1dapi{pp} = T1_dapi{pp}(indexdapi{pp}, :);

                % plot dapi downsampled scatter separately
                figure;
                hold on;
                scatter(dsT1dapi{pp}(:,2), dsT1dapi{pp}(:,3), 'filled', ...
                    'MarkerFaceColor', mcdapi,'Marker', 'o', ...
                    'SizeData', 5, 'MarkerFaceAlpha',1);
                title(strcat('Downsampled Scatter DAPI - Slice - ', num2str(slice)));
                xlabel('x position');
                ylabel('y position');
                legend(chdapi, 'Location', 'best');
                axis(z);
                hold off;
            end
        end
    end
end

%% plot histogram

% create histogram plots for A/P and D/V axes per slice; plots include bar
% plots of genes normalized to dapi, histograms of dapi and the gene,
% histograms with the scatter plot for easier orientation; csv files
% written for values in histogram and bar plots

if plot_hist == 1
    % how many bins you want for the first slice
    bb = inputdlg({'Number of bins - eg. 100 for ctx'}, ['Number of bins for Histograms']);
    bin_num = str2num(bb{1});

    for q = 0:num_ch-1
        for qq = 1:num_s
            % dapi and gene array
            b = dir('*.csv');
            f = b(num_s * q + qq).name;
            slice = s(qq);

            % save dapi array
            T1_dapi{qq} = table2array(T1{qq + dapi_set});

            %             T1_array{qq} = table2array(T1{qq});  % separate based on channels
            %             T1_dapi{qq} = table2array(T1{qq+dapi_set});

            % determine size from dapi arrays
            xhistsize{qq} = max(T1_dapi{qq}(:, 2));
            yhistsize{qq} = max(T1_dapi{qq}(:, 3));

            % determine number of bins per slice as slice size changes based on
            % first most medial slice
            xhistratio{qq} = xhistsize{qq}/xhistsize{1};

            xhistbin{qq} = bin_num.*xhistratio{qq};
            yhistbin{qq} = (xhistbin{qq} * yhistsize{qq}) / xhistsize{qq};

            nxhistbins{qq} = [round(xhistbin{qq})];
            nyhistbins{qq} = [round(yhistbin{qq})];

            % over x axis (A/P) - dapi histogram
            [N_dapi{qq}, edges{qq}] = histcounts(T1_dapi{qq}(:,2), nxhistbins{qq});

            % over y axis (D/V) - dapi histogram
            [N_dapiY{qq}, edgesY{qq}] = histcounts(T1_dapi{qq}(:,3), nyhistbins{qq});

            if contains(f, '488')
                % over x axis (A/P) - gene histogram, normalized histogram
                T1_488{qq} = table2array(T1{num_s * q + qq});
                N_488array{qq} = histcounts(T1_488{qq}(:,2), edges{qq});
                N_488norm{qq} = N_488array{qq}./N_dapi{qq}.*100;
                N_488norm{qq}(isnan(N_488norm{qq})) = 0; % if there is a NaN value, replace NaN w 0

                % calculate the average
                averageN488 = mean(N_488norm{qq});

                % plot normalized histogram of gene against dapi for A/P axis,
                % (0,0) = most posterior
                figure;
                hold on
                bar((1:nxhistbins{qq}), N_488norm{qq}, 'FaceColor', mc488, 'EdgeColor','none', ...
                    'FaceAlpha', 1, 'BarWidth', 1);
                yline(averageN488, 'Color', [0 0 0], 'LineStyle', '--');
                title(strcat('Percentage-', ch488, ' to DAPI - A-P - ', num2str(slice)));
                xlabel('histogram bins');
                hold off;

                % over y axis (D/V) - gene histogram, normalized histogram
                N_488arrayY{qq} = histcounts(T1_488{qq}(:,3), edgesY{qq});
                N_488normY{qq} = N_488arrayY{qq}./N_dapiY{qq}.*100;
                N_488normY{qq}(isnan(N_488normY{qq})) = 0; % if there is a NaN, replace NaN w 0

                % calculate average
                averageNY488 = mean(N_488normY{qq});

                % plot normalized histogram of gene against dapi for D/V axis,
                % (0,0) = most dorsal
                figure;
                hold on
                bar((1:nyhistbins{qq}), N_488normY{qq},'FaceColor', mc488, 'EdgeColor','none', ...
                    'FaceAlpha',1, 'Horizontal','on', 'BarWidth',1);
                xline(averageNY488, 'Color', [0 0 0], 'LineStyle','--');
                title(strcat('Percentage-', ch488, ' to DAPI - D-V - ', num2str(slice)));
                xlabel('histogram bins');
                hold off;

                % plot x histogram (A/P) for dapi and gene
                figure;
                hold on
                xdapihist{qq} = histogram(T1_dapi{qq}(:,2), 'FaceColor',mcdapi, ...
                    'EdgeColor','none', 'Orientation','vertical', 'NumBins', nxhistbins{qq});
                x488hist{qq} = histogram(T1_488{qq}(:,2), 'FaceColor', mc488, 'EdgeColor','none', ...
                    'Orientation','vertical', 'BinEdges', xdapihist{qq}.BinEdges);
                title(strcat('Hist X -', ch488, '- (A-P) - ', num2str(slice)));
                xlabel('A-P');
                hold off

                % write csv file with dapi, gene, and normalized histogram values
                % for A/P direction (X)
                filename = string(strcat('X_HistValues_DAPI_', ch488, ...
                    '_slide', num2str(s(qq)), '_fullctx.csv'));
                file_path = strcat(out_path, filename);
                writematrix(xdapihist{qq}.Values, file_path, 'WriteMode', 'overwrite');

                filename = string(strcat('X_HistValues_', ch488, ...
                    '_slide', num2str(s(qq)), '_fullctx.csv'));
                file_path = strcat(out_path, filename);
                writematrix(x488hist{qq}.Values, file_path, 'WriteMode', 'overwrite');

                filename = string(strcat('X_HistNormalizedValues_', ch488, ...
                    '_slide', num2str(s(qq)), '_fullctx.csv'));
                file_path = strcat(out_path, filename);
                writematrix(N_488norm{qq}, file_path, 'WriteMode', 'overwrite');

                %plot y histogram (D/V) for dapi and gene
                figure;
                hold on
                ydapihist{qq} = histogram(T1_dapi{qq}(:,3), 'FaceColor',mcdapi, ...
                    'EdgeColor','none', 'Orientation','horizontal', 'NumBins', nyhistbins{qq});
                y488hist{qq} = histogram(T1_488{qq}(:,3), 'FaceColor',mc488, ...
                    'EdgeColor','none', 'Orientation','horizontal', 'BinEdges', ydapihist{qq}.BinEdges);
                title(strcat('Hist Y -', ch488, '- (D-V) - ', num2str(slice)));
                xlabel('D-V');
                hold off

                % write csv file with dapi, gene, and normalized histogram values
                % for D/V direction (Y)
                filename = string(strcat('Y_HistValues_DAPI_', ...
                    ch488,'_slide', num2str(s(qq)), '_fullctx.csv'));
                file_path = strcat(out_path, filename);
                writematrix(ydapihist{qq}.Values, file_path, 'WriteMode', 'overwrite');

                filename = string(strcat('Y_HistValues_', ch488, ...
                    '_slide', num2str(s(qq)), '_fullctx.csv'));
                file_path = strcat(out_path, filename);
                writematrix(y488hist{qq}.Values, file_path, 'WriteMode', 'overwrite');

                filename = string(strcat('Y_HistNormalizedValues_', ch488, ...
                    '_slide', num2str(s(qq)), '_fullctx.csv'));
                file_path = strcat(out_path, filename);
                writematrix(N_488normY{qq}, file_path, 'WriteMode', 'overwrite');

                % scatter histogram for easy orientation to brain slice -
                % numbers of bins are the same across axes and slices
                figure;
                scatterhistogram(T1_488{qq}(:,2), T1_488{qq}(:,3), ...
                    'HistogramDisplayStyle','bar', 'Color', mc488, 'NumBins', bin_num);
                title(strcat('Scatter Histogram-', ch488, ' Slice ', num2str(slice)));
            end
            if contains(f, '594')
                % over x axis (A/P) - gene histogram, normalized histogram
                T1_594{qq} = table2array(T1{num_s * q + qq});
                N_594array{qq} = histcounts(T1_594{qq}(:,2), edges{qq});
                N_594norm{qq} = N_594array{qq}./N_dapi{qq}.*100;
                N_594norm{qq}(isnan(N_594norm{qq})) = 0; % if there is a NaN value, replace NaN w 0

                % calculate the average
                averageN594 = mean(N_594norm{qq});

                % plot normalized histogram of gene against dapi for A/P axis,
                % (0,0) = most posterior
                figure;
                hold on
                bar((1:nxhistbins{qq}), N_594norm{qq}, 'FaceColor', mc594, 'EdgeColor','none', ...
                    'FaceAlpha', 1, 'BarWidth', 1);
                yline(averageN594, 'Color', [0 0 0], 'LineStyle', '--');
                title(strcat('Percentage-', ch594, ' to DAPI - A-P - ', num2str(slice)));
                xlabel('histogram bins');
                hold off;

                % over y axis (D/V) - gene histogram, normalized histogram
                N_594arrayY{qq} = histcounts(T1_594{qq}(:,3), edgesY{qq});
                N_594normY{qq} = N_594arrayY{qq}./N_dapiY{qq}.*100;
                N_594normY{qq}(isnan(N_594normY{qq})) = 0; % if there is a NaN, replace NaN w 0

                % calculate average
                averageNY594 = mean(N_594normY{qq});

                % plot normalized histogram of gene against dapi for D/V axis,
                % (0,0) = most dorsal
                figure;
                hold on
                bar((1:nyhistbins{qq}), N_594normY{qq},'FaceColor', mc594, 'EdgeColor','none', ...
                    'FaceAlpha',1, 'Horizontal','on', 'BarWidth',1);
                xline(averageNY594, 'Color', [0 0 0], 'LineStyle','--');
                title(strcat('Percentage-', ch594, ' to DAPI - D-V - ', num2str(slice)));
                xlabel('histogram bins');
                hold off;

                % plot x histogram (A/P)for dapi and gene
                figure;
                hold on
                xdapihist{qq} = histogram(T1_dapi{qq}(:,2), 'FaceColor',mcdapi, ...
                    'EdgeColor','none', 'Orientation','vertical', 'NumBins', nxhistbins{qq});
                x594hist{qq} = histogram(T1_594{qq}(:,2), 'FaceColor', mc594, 'EdgeColor','none', ...
                    'Orientation','vertical', 'BinEdges', xdapihist{qq}.BinEdges);
                title(strcat('Hist X -', ch594, '- (A-P) - ', num2str(slice)));
                xlabel('A-P');
                hold off

                % write csv file with dapi, gene, and normalized histogram values
                % for A/P direction (X)
                filename = string(strcat('X_HistValues_DAPI_', ch594, ...
                    '_slide', num2str(s(qq)), '_fullctx.csv'));
                file_path = strcat(out_path, filename);
                writematrix(xdapihist{qq}.Values, file_path, 'WriteMode', 'overwrite');

                filename = string(strcat('X_HistValues_', ch594, ...
                    '_slide', num2str(s(qq)), '_fullctx.csv'));
                file_path = strcat(out_path, filename);
                writematrix(x594hist{qq}.Values, file_path, 'WriteMode', 'overwrite');

                filename = string(strcat('X_HistNormalizedValues_', ch594, ...
                    '_slide', num2str(s(qq)), '_fullctx.csv'));
                file_path = strcat(out_path, filename);
                writematrix(N_594norm{qq}, file_path, 'WriteMode', 'overwrite');

                %plot y histogram (D/V) for dapi and gene
                figure;
                hold on
                ydapihist{qq} = histogram(T1_dapi{qq}(:,3), 'FaceColor',mcdapi, ...
                    'EdgeColor','none', 'Orientation','horizontal', 'NumBins',nyhistbins{qq});
                y594hist{qq} = histogram(T1_594{qq}(:,3), 'FaceColor',mc594, ...
                    'EdgeColor','none', 'Orientation','horizontal', 'BinEdges',ydapihist{qq}.BinEdges);
                title(strcat('Hist Y -', ch594, '- (D-V) - ', num2str(slice)));
                xlabel('D-V');
                hold off

                % write csv file with dapi, gene, and normalized histogram values
                % for D/V direction (Y)
                filename = string(strcat('Y_HistValues_DAPI_', ...
                    ch594,'_slide', num2str(s(qq)), '_fullctx.csv'));
                file_path = strcat(out_path, filename);
                writematrix(ydapihist{qq}.Values, file_path, 'WriteMode', 'overwrite');

                filename = string(strcat('Y_HistValues_', ch594, ...
                    '_slide', num2str(s(qq)), '_fullctx.csv'));
                file_path = strcat(out_path, filename);
                writematrix(y594hist{qq}.Values, file_path, 'WriteMode', 'overwrite');

                filename = string(strcat('Y_HistNormalizedValues_', ch594, ...
                    '_slide', num2str(s(qq)), '_fullctx.csv'));
                file_path = strcat(out_path, filename);
                writematrix(N_594normY{qq}, file_path, 'WriteMode', 'overwrite');

                % scatter histogram for easy orientation to brain slice -
                % number of bins are the same across axes and slices
                figure;
                scatterhistogram(T1_594{qq}(:,2), T1_594{qq}(:,3), ...
                    'HistogramDisplayStyle','bar', 'Color', mc594, 'NumBins', bin_num);
                title(strcat('Scatter Histogram-', ch594, ' Slice ', num2str(slice)));
            end
            if contains (f, '647')
                % over x axis (A/P) - gene histogram, normalized histogram
                T1_647{qq} = table2array(T1{num_s * q + qq});
                N_647array{qq} = histcounts(T1_647{qq}(:,2), edges{qq});
                N_647norm{qq} = N_647array{qq}./N_dapi{qq}.*100;
                N_647norm{qq}(isnan(N_647norm{qq})) = 0; % if there is a NaN value, replace NaN w 0

                % calculate the average
                averageN647 = mean(N_647norm{qq});

                % plot normalized histogram of gene against dapi for A/P axis,
                % (0,0) = most posterior
                figure;
                hold on
                bar((1:nxhistbins{qq}), N_647norm{qq}, 'FaceColor', mc647, 'EdgeColor','none', ...
                    'FaceAlpha', 1, 'BarWidth', 1);
                yline(averageN647, 'Color', [0 0 0], 'LineStyle', '--');
                title(strcat('Percentage-', ch647, ' to DAPI - A-P - ', num2str(slice)));
                xlabel('histogram bins');
                hold off;

                % over y axis (D/V) - gene histogram, normalized histogram
                N_647arrayY{qq} = histcounts(T1_647{qq}(:,3), edgesY{qq});
                N_647normY{qq} = N_647arrayY{qq}./N_dapiY{qq}.*100;
                N_647normY{qq}(isnan(N_647normY{qq})) = 0; % if there is a NaN, replace NaN w 0

                % calculate average
                averageNY647 = mean(N_647normY{qq});

                % plot normalized histogram of gene against dapi for D/V axis,
                % (0,0) = most dorsal
                figure;
                hold on
                bar((1:nyhistbins{qq}), N_647normY{qq},'FaceColor', mc647, 'EdgeColor','none', ...
                    'FaceAlpha',1, 'Horizontal','on', 'BarWidth',1);
                xline(averageNY647, 'Color', [0 0 0], 'LineStyle','--');
                title(strcat('Percentage-', ch647, ' to DAPI - D-V - ', num2str(slice)));
                xlabel('histogram bins');
                hold off;

                % plot x histogram (A/P)for dapi and gene
                figure;
                hold on
                xdapihist{qq} = histogram(T1_dapi{qq}(:,2), 'FaceColor',mcdapi, ...
                    'EdgeColor','none', 'Orientation','vertical', 'NumBins', nxhistbins{qq});
                x647hist{qq} = histogram(T1_647{qq}(:,2), 'FaceColor', mc647, 'EdgeColor','none', ...
                    'Orientation','vertical', 'BinEdges', xdapihist{qq}.BinEdges);
                title(strcat('Hist X -', ch647, '- (A-P) - ', num2str(slice)));
                xlabel('A-P');
                hold off

                % write csv file with dapi, gene, and normalized histogram values
                % for A/P direction (X)
                filename = string(strcat('X_HistValues_DAPI_', ch647, ...
                    '_slide', num2str(s(qq)), '_fullctx.csv'));
                file_path = strcat(out_path, filename);
                writematrix(xdapihist{qq}.Values, file_path, 'WriteMode', 'overwrite');

                filename = string(strcat('X_HistValues_', ch647, ...
                    '_slide', num2str(s(qq)), '_fullctx.csv'));
                file_path = strcat(out_path, filename);
                writematrix(x647hist{qq}.Values, file_path, 'WriteMode', 'overwrite');

                filename = string(strcat('X_HistNormalizedValues_', ch647, ...
                    '_slide', num2str(s(qq)), '_fullctx.csv'));
                file_path = strcat(out_path, filename);
                writematrix(N_647norm{qq}, file_path, 'WriteMode', 'overwrite');

                %plot y histogram (D/V) for dapi and gene
                figure;
                hold on
                ydapihist{qq} = histogram(T1_dapi{qq}(:,3), 'FaceColor',mcdapi, ...
                    'EdgeColor','none', 'Orientation','horizontal', 'NumBins',nyhistbins{qq});
                y647hist{qq} = histogram(T1_647{qq}(:,3), 'FaceColor',mc647, ...
                    'EdgeColor','none', 'Orientation','horizontal', 'BinEdges',ydapihist{qq}.BinEdges);
                title(strcat('Hist Y -', ch647, '- (D-V) - ', num2str(slice)));
                xlabel('D-V');
                hold off

                % write csv file with dapi, gene, and normalized histogram values
                % for D/V direction (Y)
                filename = string(strcat('Y_HistValues_DAPI_', ...
                    ch647,'_slide', num2str(s(qq)), '_fullctx.csv'));
                file_path = strcat(out_path, filename);
                writematrix(ydapihist{qq}.Values, file_path, 'WriteMode', 'overwrite');

                filename = string(strcat('Y_HistValues_', ch647, ...
                    '_slide', num2str(s(qq)), '_fullctx.csv'));
                file_path = strcat(out_path, filename);
                writematrix(y647hist{qq}.Values, file_path, 'WriteMode', 'overwrite');

                filename = string(strcat('Y_HistNormalizedValues_', ch647, ...
                    '_slide', num2str(s(qq)), '_fullctx.csv'));
                file_path = strcat(out_path, filename);
                writematrix(N_647normY{qq}, file_path, 'WriteMode', 'overwrite');

                % scatter histogram for easy orientation to brain slice -
                % numbers of bins is the same across axes and slices
                figure;
                scatterhistogram(T1_647{qq}(:,2), T1_647{qq}(:,3), ...
                    'HistogramDisplayStyle','bar', 'Color', mc647, 'NumBins', bin_num);
                title(strcat('Scatter Histogram-', ch647, ' Slice ', num2str(slice)));
            end

%             N_array{q} = histcounts(T1_array{q}(:,2), nxhistbins{q});
%             N_norm{q} = N_array{q}./N_dapi{q}.*100;
%             N_norm{q}(isnan(N_norm{q})) = 0; % if there is a NaN value, replace NaN w 0
            
%             % calculate the average
%             averageN = mean(N_norm{q});
%             % disp(averageN);
            
%             % plot normalized histogram of gene against dapi for A/P axis,
%             % (0,0) = most posterior
%             figure;
%             hold on
%             bar((1:nxhistbins{q}), N_norm{q}, 'FaceColor', mc, 'EdgeColor','none', ...
%                 'FaceAlpha', 1, 'BarWidth', 1);
%             yline(averageN, 'Color', [0 0 0], 'LineStyle', '--');
%             title(strcat('Percentage-', MOI, ' to DAPI - A-P - ', num2str(slice)));
%             xlabel('histogram bins');
%             hold off;
    
%             % over y axis (D/V) - dapi histogram, gene histogram, normalized histogram
%             N_dapiY{q} = histcounts(T1_dapi{q}(:,3), nyhistbins{q});
%             N_arrayY{q} = histcounts(T1_array{q}(:,3), nyhistbins{q});
%             N_normY{q} = N_arrayY{q}./N_dapiY{q}.*100;
%             N_normY{q}(isnan(N_normY{q})) = 0; % if there is a NaN, replace NaN w 0
            
%             % calculate average
%             averageNY = mean(N_normY{q});
%             % disp(averageNY);
            
%             % plot normalized histogram of gene against dapi for D/V axis,
%             % (0,0) = most dorsal
%             figure;
%             hold on
%             bar((1:nyhistbins{q}), N_normY{q},'FaceColor', mc, 'EdgeColor','none', ... 
%                 'FaceAlpha',1, 'Horizontal','on', 'BarWidth',1);
%             xline(averageNY, 'Color', [0 0 0], 'LineStyle','--');
%             title(strcat('Percentage-', MOI, ' to DAPI - D-V - ', num2str(slice)));
%             xlabel('histogram bins');
%             hold off;
    
%             % plot x histogram (A/P)for dapi and gene
%             figure;
%             hold on
%             xdapihist{q} = histogram(T1_dapi{q}(:,2), 'FaceColor',mcdapi, ...
%                 'EdgeColor','none', 'Orientation','vertical', 'NumBins', nxhistbins{q});
%             xhist{q} = histogram(T1_array{q}(:,2), 'FaceColor', mc, 'EdgeColor','none', ...
%                 'Orientation','vertical', 'NumBins', nxhistbins{q});
%             title(strcat('Hist X -', MOI, '- (A-P) - ', num2str(slice)));
%             xlabel('A-P');
%     %         xlim([0 210000]); %HCR
%     %         ylim([0 15000]);
%     %         xlim([0 110000]); %ACD
%     %         ylim([0 15000]);
%             hold off
%             
%             % write csv file with dapi, gene, and normalized histogram values
%             % for A/P direction (X)
%             filename = string(strcat('X_HistValues_DAPI_', MOI, ...
%                 '_slide', num2str(s(q)), '_fullctx.csv'));
%             file_path = strcat(out_path, filename);
%             writematrix(xdapihist{q}.Values, file_path, 'WriteMode', 'overwrite');
%     
%             filename = string(strcat('X_HistValues_', MOI, ...
%                 '_slide', num2str(s(q)), '_fullctx.csv'));
%             file_path = strcat(out_path, filename);
%             writematrix(xhist{q}.Values, file_path, 'WriteMode', 'overwrite');
%     
%             filename = string(strcat('X_HistNormalizedValues_', MOI, ...
%                 '_slide', num2str(s(q)), '_fullctx.csv'));
%             file_path = strcat(out_path, filename);
%             writematrix(N_norm{q}, file_path, 'WriteMode', 'overwrite');
    
%             %plot y histogram
%             figure;
%             hold on
%             ydapihist{q} = histogram(T1_dapi{q}(:,3), 'FaceColor',mcdapi, ...
%                 'EdgeColor','none', 'Orientation','horizontal', 'NumBins',nyhistbins{q});
%             yhist{q} = histogram(T1_array{q}(:,3), 'FaceColor',mc, ...
%                 'EdgeColor','none', 'Orientation','horizontal', 'NumBins',nyhistbins{q});
%             title(strcat('Hist Y -', MOI, '- (D-V) - ', num2str(slice)));
%             xlabel('D-V');
%     %         xlim([0 40000]); %HCR
%     %         ylim([0 120000]);
%     %         xlim([0 40000]); %ACD
%     %         ylim([0 60000]);
%             hold off
%     
%             % write csv file with dapi, gene, and normalized histogram values
%             % for D/V direction (Y)
%             filename = string(strcat('Y_HistValues_DAPI_', ...
%                 MOI,'_slide', num2str(s(q)), '_fullctx.csv'));
%             file_path = strcat(out_path, filename);
%             writematrix(ydapihist{q}.Values, file_path, 'WriteMode', 'overwrite');
%     
%             filename = string(strcat('Y_HistValues_', MOI, ...
%                 '_slide', num2str(s(q)), '_fullctx.csv'));
%             file_path = strcat(out_path, filename);
%             writematrix(yhist{q}.Values, file_path, 'WriteMode', 'overwrite');
%     
%             filename = string(strcat('Y_HistNormalizedValues_', MOI, ...
%                 '_slide', num2str(s(q)), '_fullctx.csv'));
%             file_path = strcat(out_path, filename);
%             writematrix(N_normY{q}, file_path, 'WriteMode', 'overwrite');
    
%             % scatter histogram for easy orientation to brain slice
%             figure;
%             scatterhistogram(T1_array{q}(:,2), T1_array{q}(:,3), ...
%                 'HistogramDisplayStyle','bar', 'Color', mc);
%             title(strcat('Scatter Histogram-', MOI, ' Slice ', num2str(slice)));
        end
    end
end

%% plot density

% create density/2-d histogram plots per slice; plots include
% heatmaps of dapi, heatmaps of gene, and heatmaps of gene normalized to dapi,
% dscatter also produces density scatter plot; csv files written for values
% in heatmap of gene and normalized heatmap

if plot_density == 1
    % how many bins you want for the first slice
    cc = inputdlg({'Number of bins - eg. 100 for ctx'}, ['Number of bins for Heatmaps']);
    bin_num = str2num(cc{1});

    for r = 1:num_s
        slice = s(r);
        T1_array{r} = table2array(T1{r});
        T1_dapi{r} = table2array(T1{r+dapi_set});
        xsize{r} = max(T1_dapi{r}(:, 2));
        ysize{r} = max(T1_dapi{r}(:, 3));

        % determine number of bins per slice as slice size changes based on
        % first most medial slice
        xratio{r} = xsize{r}/xsize{1};

        % how many bins you want for the first slice
%         bin_num = 100; % used 30 or 100 for ctx

        xbin{r} = bin_num.*xratio{r};
        ybin{r} = (xbin{r} * ysize{r}) / xsize{r};
        
        nbins{r} = [round(xbin{r}), round(ybin{r})];

        [NDapi{r}, Xedges{r}, Yedges{r}] = histcounts2(T1_dapi{r}(:,2), T1_dapi{r}(:,3), nbins{r});
        [NArray{r}] = histcounts2(T1_array{r}(:,2), T1_array{r}(:,3), Xedges{r}, Yedges{r});

        NNorm{r} = NArray{r}./NDapi{r}.*100;
        NNorm{r}(isnan(NNorm{r})) = 0; % if there is NaN due to dividing by 0, replace NaN w 0
        
        % PLOT DAPI DENSITY HEATMAP
        figure;
        histogram2('XBinEdges', Xedges{r},'YBinEdges', Yedges{r},'BinCounts', ...
            NDapi{r}, 'DisplayStyle','tile', 'EdgeColor','none', 'ShowEmptyBins','off');
        colormap('cool');
        axis(z);
        title(strcat('Heatmap DAPI-', num2str(slice)));
        colorbar;
        clim([0 600]);
        grid off;
        
        % PLOT MOI DENSITY HEATMAP
        figure;
        histogram2('XBinEdges', Xedges{r},'YBinEdges', Yedges{r},'BinCounts', ...
            NArray{r}, 'DisplayStyle','tile', 'EdgeColor','none', 'ShowEmptyBins','off');
        colormap(map);
        axis(z);
        title(strcat('Heatmap-', MOI, '-', num2str(slice)));
        colorbar;
        if contains(MOI, 'sst') 
            clim([0 15]); 
        elseif contains(MOI, 'pvalb')
            clim([0 25]);
        elseif contains(MOI, 'vip')
            clim([0 10]);
        elseif contains(MOI, 'lamp5')
            clim([0 10]);
        elseif contains(MOI, 'cxcl14')
            clim([0 30]);
        end
        grid off;
        
        % WRITE MOI DENSITY HEATMAP ARRAY
        filename = string(strcat(MOI, '_', num2str(slice), '_DensityHeatmapArray.csv'));
        file_path = strcat(out_path, filename);
        writematrix(NArray{r}, file_path, 'WriteMode', 'overwrite');
        
        % PLOT NORMALIZED HEATMAP (GENE TO DAPI)
        figure;
        histogram2('XBinEdges', Xedges{r},'YBinEdges',Yedges{r},'BinCounts', ...
            NNorm{r}, 'DisplayStyle','tile', 'EdgeColor','none', 'ShowEmptyBins','off');
        colormap(map);
        axis(z);
        title(strcat(MOI, '-normalized to DAPI-', num2str(slice)));
        colorbar;
        if contains(MOI, 'sst') 
            clim([0 9]); 
        elseif contains(MOI, 'pvalb')
            clim([0 8]);
        elseif contains(MOI, 'vip')
            clim([0 5]);
        elseif contains(MOI, 'lamp5')
            clim([0 4]);
        elseif contains(MOI, 'cxcl14')
            clim([0 15]);
        end
        grid off;

        % WRITE MOI NORMALIZED DENSITY HEATMAP ARRAY
        filename = string(strcat(MOI, '_', num2str(slice), '_NormalizedDensityHeatmapArray.csv'));
        file_path = strcat(out_path, filename);
        writematrix(NNorm{r}, file_path, 'WriteMode', 'overwrite');
        
        % PLOT DENSITY SCATTER VERSION FOR GENE
        figure;
        hold on;
        dd = dscatter(T1_array{r}(:,2), T1_array{r}(:,3), 'BINS', nbins{r});
        title(strcat('density scatter - ', MOI, ' slice - ', num2str(slice)));
        axis(z);
        colormap(map);
        clim([0 1]);
        colorbar;
        hold off;
    end
end

%% functions

% function to plot channels against dapi

function scatter_dapi_out = scatter_dapi(f_in1, f_in2, ...
     f_in3, f_in4, f_in5, f_in6, f_in7, f_in8, f_in9)

figure;
hold on;
scatter(f_in1, 2, 3, 'filled', 'MarkerFaceColor', f_in2,'Marker', 'o', ...
    'SizeData', 5, 'MarkerFaceAlpha',1);
scatter(f_in3, 2, 3, 'filled', 'MarkerFaceColor', f_in4,'Marker', 'o', ...
    'SizeData', 5, 'MarkerFaceAlpha',1);
title(strcat(f_in5, '&', f_in6,' - slice ',f_in7,'-',f_in8));
xlabel('x position');
ylabel('y position');
legend(f_in5, f_in6,'Location','best');
axis(f_in9);
hold off;

end

% function for medio-lateral bar plots

function normalized_plot_out = normalized_plot(f_in1, f_in2, f_in3, ...
    f_in4, f_in5, f_in6)

figure;
hold on;
bar(f_in1, f_in2, 'FaceColor',f_in3, 'EdgeColor','none');
title(strcat(f_in4, ' - normalized counts - ', f_in5));
xlabel('sections m --> l');
ylabel(strcat('% of ', f_in4, '+ cells/', f_in6));
hold off;

end