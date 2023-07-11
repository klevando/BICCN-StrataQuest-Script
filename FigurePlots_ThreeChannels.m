% Program to plot expression of various genes across a brain slice based 
% on StrataQuest results. Written for tissue validation series expreiments 
% in Krienen et al. 'A marmoset brain cell census reveals influence of 
% developmental origin and functional class on neuronal identity.' 
% 2022-08-31 - Kirsten Levandowski

% Plot options include: 
% (1) plotting scatter plot of gene and dapi (plot_channels_dapi = 1),
% (2) plotting mediolateral bar graphs of gene normalized to dapi (plot_normalization = 1),
% (3) plotting downsampled scatter plots of gene and dapi (plot_downsample = 1), 
% (4)plotting histograms of gene normalized to dapi across the A/P and D/V 
% axes per slice, plotting histograms of dapi and gene, and plotting gene 
% histograms around scatter plot for easier interpretation of histograms 
% (plot_hist = 1), and
% (5) plotting density heatmaps of genes, dapi, and gene normalized to
% dapi. dscatter plot (density scatter plot) of gene all generated
% (plot_density = 1).

% Gene list: 'cck', 'cxcl14', 'gad1', 'lamp5', 'lamp5-gad1', 'pvalb', 
% 'slc5a7', 'sst', 'tac3', 'th', 'vip'

%% clear variables and close anything

% CLEAR VARIABLES
clear variables;

% DO NOT DISPLAY FIGURES WHEN 'off'
set(0,'DefaultFigureVisible', 'on');

% CLOSE EVERYTHING
close all force;
close all hidden;
status = close('all','hidden');
disp(strcat('close all status: ', num2str(status)));

%% input information

% PLOT FIGURES? 0 = NO, 1 = YES
aa = inputdlg({'Scatterplot, eg: 1 = yes, 0 = no','M/L Bar Plots', ...
    'Downsampled Scatterplots', 'Histograms', 'Density Heatmaps'}, ...
    'Select Plotting Types - 1 = plot, 0 = no plot');
plot_channels_dapi = str2num(aa{1});
plot_normalization = str2num(aa{2});
plot_downsample = str2num(aa{3});
plot_hist = str2num(aa{4});
plot_density = str2num(aa{5});

% SELECT BRAIN AREA
balist = {'ctx', 'str'};
[indxba] = listdlg('ListString', balist, 'SelectionMode', 'single');
brainarea = balist(indxba);

%% define constants

% MAKE OUTPUT FOLDER IN WORKING DIRECTORY TO SAVE CSV FILES SEPARATELY
path = pwd;
mkdir Output;
out_path = strcat(path, '/Output/');

% CALCULATE NUM OF CHANNELS USED BY DETERMINING IF PRESENT IN DIR (DAPI ALWAYS LAST SET) 
on_488 = length(dir('488*'))>0;
on_594 = length(dir('594*'))>0;
on_647 = length(dir('647*'))>0;
num_ch = on_488 + on_594 + on_647 + 1;

% CALCULATE NUM OF BRAIN SLICES PER CHANNEL 
num_s = length(dir('*.csv'))/num_ch;    % can also use num_s = size(dir('dapi*'));

% INPUT CHANNEL INFO FOR GENES OF INTEREST (SEE GENE LIST ^^^TOP^^^)
prompt = {'Channel 488 - e.g. pvalb or PVALB','Channel 594', 'Channel 647'};
dlgtitle = 'Genes';
dims = [1 50];
xx = inputdlg(prompt,dlgtitle,dims);
ch488 = xx{1};
ch594 = xx{2};
ch647 = xx{3};

% DETERMIN BRAIN SLICES (s) AND THE SLICE INTERVAL (sm) BASED ON DAPI SECTIONS IN DIR
a = dir('dapi*');
for z = 1:size(a)
    s(z) = str2num(cell2mat(regexp(a(z).name, '\d+', 'match'))); 
end

% IF THERE IS ONLY ONE SECTION sm = 0
if num_s > 1
    sm = s(2) - s(1);
else            %elseif s == 1
    sm = 0;
end

s1 = s(1);

% CALCULATE FIRST ENTRY IN LAST ROW (first dapi image) TO FIND DAPI OFFSET
dapi_set=((num_ch-1)*num_s);

% SET LABEL FOR DAPI CHANNEL
chdapi = 'dapi';

% TAKE BRAIN AREA FROM FILE NAME FOR GRAPH LABELING
b = dir('*.csv');
c = extractAfter(b(1).name,mat2str(s1));
d = extractBefore(c,'.');
a1 = extractAfter(d,'_');

% LOAD SPREADSHEET COLUMN HEADERS (Based on TissueFAX system)
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

% DAPI COLOR
mcdapi = [0.9 0.9 0.9];     % light grey

% SET COLORMAP FOR GENES OF INTEREST
% SST COLORMAP
if contains(ch488, 'sst', IgnoreCase=true)
    ch488 = 'SST';
    mc488 = [103/255 94/255 168/255]; % blue purple 675ea8
    sst1 = [231/255 219/255 255/255]; %e7dbff
    sst2 = [189/255 175/255 255/255]; %bdafe1
    sst3 = [147/255 133/255 196/255]; %9385c4
    sst4 = [75/255 68/255 117/255]; %4b4475
    sst5 = [47/255 43/255 70/255]; %2f2b46
    sst6 = [30/255 27/255 62/255]; %1e1b3e
    sst7 = [16/255 9/255 39/255]; %100927
    map488 = [sst1; sst2; sst3; mc488; sst4; sst5; sst6; sst7];
elseif contains(ch594, 'sst', IgnoreCase=true)
    ch594 = 'SST';
    mc594 = [103/255 94/255 168/255]; % blue purple 675ea8
    sst1 = [231/255 219/255 255/255]; %e7dbff
    sst2 = [189/255 175/255 255/255]; %bdafe1
    sst3 = [147/255 133/255 196/255]; %9385c4
    sst4 = [75/255 68/255 117/255]; %4b4475
    sst5 = [47/255 43/255 70/255]; %2f2b46
    sst6 = [30/255 27/255 62/255]; %1e1b3e
    sst7 = [16/255 9/255 39/255]; %100927
    map594 = [sst1; sst2; sst3; mc594; sst4; sst5; sst6; sst7];
elseif contains(ch647, 'sst', IgnoreCase=true)
    ch647 = 'SST';
    mc647 = [103/255 94/255 168/255]; % blue purple 675ea8
    sst1 = [231/255 219/255 255/255]; %e7dbff
    sst2 = [189/255 175/255 255/255]; %bdafe1
    sst3 = [147/255 133/255 196/255]; %9385c4
    sst4 = [75/255 68/255 117/255]; %4b4475
    sst5 = [47/255 43/255 70/255]; %2f2b46
    sst6 = [30/255 27/255 62/255]; %1e1b3e
    sst7 = [16/255 9/255 39/255]; %100927
    map647 = [sst1; sst2; sst3; mc647; sst4; sst5; sst6; sst7];
end
% TAC3 COLORMAP
if contains(ch488, 'tac3', IgnoreCase=true)
    ch488 = 'TAC3';
    mc488 = [211/255 160/255 200/255]; % lavender d3a0c8
    ta1 = [253/255 232/255 248/255]; %fde8f8
    ta2 = [239/255 208/255 232/255]; %efd0e8
    ta3 = [225/255 184/255 216/255]; %e1b8d8
    ta4 = [155/255 116/255 146/255]; %9b7492
    ta5 = [102/255 75/255 95/255]; %664b5f
    map488 = [ta1; ta2; ta3; mc488; ta4; ta5];
elseif contains(ch594, 'tac3', IgnoreCase=true)
    ch594 = 'TAC3';
    mc594 = [211/255 160/255 200/255]; % lavender d3a0c8
    ta1 = [253/255 232/255 248/255]; %fde8f8
    ta2 = [239/255 208/255 232/255]; %efd0e8
    ta3 = [225/255 184/255 216/255]; %e1b8d8
    ta4 = [155/255 116/255 146/255]; %9b7492
    ta5 = [102/255 75/255 95/255]; %664b5f
    map594 = [ta1; ta2; ta3; mc594; ta4; ta5];
elseif contains(ch647, 'tac3', IgnoreCase=true)
    ch647 = 'TAC3';
    mc647 = [211/255 160/255 200/255]; % lavender d3a0c8
    ta1 = [253/255 232/255 248/255]; %fde8f8
    ta2 = [239/255 208/255 232/255]; %efd0e8
    ta3 = [225/255 184/255 216/255]; %e1b8d8
    ta4 = [155/255 116/255 146/255]; %9b7492
    ta5 = [102/255 75/255 95/255]; %664b5f
    map647 = [ta1; ta2; ta3; mc647; ta4; ta5];
end
% CCK COLORMAP
if contains(ch488, 'cck', IgnoreCase=true)
    ch488 = 'CCK';
    mc488 = [76/255 133/255 197/255]; % blue 4c85c5
    cck1 = [225/255 239/255 255/255]; %e1efff
    cck2 = [176/255 203/255 236/255]; %b0cbec
    cck3 = [127/255 168/255 216/255]; %7fa8d8
    cck4 = [58/255 96/255 140/255]; %3a608c
    cck5 = [41/255 62/255 88/255]; %293e58
    map488 = [cck1; cck2; cck3; mc488; cck4; cck5];
elseif contains(ch594, 'cck', IgnoreCase=true)
    ch594 = 'CCK';
    mc594 = [76/255 133/255 197/255]; % blue 4c85c5
    cck1 = [225/255 239/255 255/255]; %e1efff
    cck2 = [176/255 203/255 236/255]; %b0cbec
    cck3 = [127/255 168/255 216/255]; %7fa8d8
    cck4 = [58/255 96/255 140/255]; %3a608c
    cck5 = [41/255 62/255 88/255]; %293e58
    map594 = [cck1; cck2; cck3; mc594; cck4; cck5];
elseif contains(ch647, 'cck', IgnoreCase=true)
    ch647 = 'CCK';
    mc647 = [76/255 133/255 197/255]; % blue 4c85c5
    cck1 = [225/255 239/255 255/255]; %e1efff
    cck2 = [176/255 203/255 236/255]; %b0cbec
    cck3 = [127/255 168/255 216/255]; %7fa8d8
    cck4 = [58/255 96/255 140/255]; %3a608c
    cck5 = [41/255 62/255 88/255]; %293e58
    map647 = [cck1; cck2; cck3; mc647; cck4; cck5];
end
% PVALB COLORMAP
if contains(ch488, 'pvalb', IgnoreCase=true)
    ch488 = 'PVALB';
    mc488 = [241/255 90/255 36/255]; % orange f15a25
    pv1 = [255/255 209/255 174/255]; %ffd1ae
    pv2 = [252/255 173/255 122/255]; %fcad7a
    pv3 = [247/255 135/255 77/255]; %f7874d
    pv4 = [182/255 55/255 31/255]; %b6371f
    pv5 = [124/255 24/255 21/255]; %7c1815
    pv6 = [88/255 27/255 14/255]; %581b0e
    pv7 = [55/255 14/255 0/255]; %370e00
    map488 = [pv1; pv2; pv3; mc588; pv4; pv5; pv6; pv7];
elseif contains(ch594, 'pvalb', IgnoreCase=true)
    ch594 = 'PVALB';
    mc594 = [241/255 90/255 36/255]; % orange f15a25
    pv1 = [255/255 209/255 174/255]; %ffd1ae
    pv2 = [252/255 173/255 122/255]; %fcad7a
    pv3 = [247/255 135/255 77/255]; %f7874d
    pv4 = [182/255 55/255 31/255]; %b6371f
    pv5 = [124/255 24/255 21/255]; %7c1815
    pv6 = [88/255 27/255 14/255]; %581b0e
    pv7 = [55/255 14/255 0/255]; %370e00
    map594 = [pv1; pv2; pv3; mc594; pv4; pv5; pv6; pv7];
elseif contains(ch647, 'pvalb', IgnoreCase=true)
    ch647 = 'PVALB';
    mc647 = [241/255 90/255 36/255]; % orange f15a25
    pv1 = [255/255 209/255 174/255]; %ffd1ae
    pv2 = [252/255 173/255 122/255]; %fcad7a
    pv3 = [247/255 135/255 77/255]; %f7874d
    pv4 = [182/255 55/255 31/255]; %b6371f
    pv5 = [124/255 24/255 21/255]; %7c1815
    pv6 = [88/255 27/255 14/255]; %581b0e
    pv7 = [55/255 14/255 0/255]; %370e00
    map647 = [pv1; pv2; pv3; mc647; pv4; pv5; pv6; pv7];
end
% TH COLORMAP
if contains(ch488, 'th', IgnoreCase=true)
    ch488 = 'TH';
    mc488 = [248/255 163/255 81/255]; % yellow f8a351
    th1 = [255/255 241/255 215/255]; %fff1d7
    th2 = [251/255 217/255 167/255]; %fbd9a7
    th3 = [249/255 191/255 122/255]; %f9bf7a
    th4 = [169/255 110/255 57/255]; %a96e39
    th5 = [95/255 62/255 33/255]; %5f3e21
    map488 = [th1; th2; th3; mc488; th4; th5];
elseif contains(ch594, 'th', IgnoreCase=true)
    ch594 = 'TH';
    mc594 = [248/255 163/255 81/255]; % yellow f8a351
    th1 = [255/255 241/255 215/255]; %fff1d7
    th2 = [251/255 217/255 167/255]; %fbd9a7
    th3 = [249/255 191/255 122/255]; %f9bf7a
    th4 = [169/255 110/255 57/255]; %a96e39
    th5 = [95/255 62/255 33/255]; %5f3e21
    map594 = [th1; th2; th3; mc594; th4; th5];
elseif contains(ch647, 'th', IgnoreCase=true)
    ch647 = 'TH';
    mc647 = [248/255 163/255 81/255]; % yellow f8a351
    th1 = [255/255 241/255 215/255]; %fff1d7
    th2 = [251/255 217/255 167/255]; %fbd9a7
    th3 = [249/255 191/255 122/255]; %f9bf7a
    th4 = [169/255 110/255 57/255]; %a96e39
    th5 = [95/255 62/255 33/255]; %5f3e21
    map647 = [th1; th2; th3; mc647; th4; th5];
end
% SLC5A7 COLORMAP
if contains(ch488, 'slc5a7', IgnoreCase=true)
    ch488 = 'SLC5A7';
    mc488 = [221/255 56/255 56/255]; % red dd3838
    sl1 = [255/255 226/255 218/255]; %ffe2da
    sl2 = [250/255 175/255 157/255]; %faaf9d
    sl3 = [238/255 121/255 103/255]; %ee7967
    sl4 = [162/255 33/255 41/255]; %a22129
    sl5 = [106/255 13/255 25/255]; %6a0d19
    map488 = [sl1; sl2; sl3; mc488; sl4; sl5];
elseif contains(ch594, 'slc5a7', IgnoreCase=true)
    ch594 = 'SLC5A7';
    mc594 = [221/255 56/255 56/255]; % red dd3838
    sl1 = [255/255 226/255 218/255]; %ffe2da
    sl2 = [250/255 175/255 157/255]; %faaf9d
    sl3 = [238/255 121/255 103/255]; %ee7967
    sl4 = [162/255 33/255 41/255]; %a22129
    sl5 = [106/255 13/255 25/255]; %6a0d19
    map594 = [sl1; sl2; sl3; mc594; sl4; sl5];
elseif contains(ch647, 'slc5a7', IgnoreCase=true)
    ch647 = 'SLC5A7';
    mc647 = [221/255 56/255 56/255]; % red dd3838
    sl1 = [255/255 226/255 218/255]; %ffe2da
    sl2 = [250/255 175/255 157/255]; %faaf9d
    sl3 = [238/255 121/255 103/255]; %ee7967
    sl4 = [162/255 33/255 41/255]; %a22129
    sl5 = [106/255 13/255 25/255]; %6a0d19
    map647 = [sl1; sl2; sl3; mc647; sl4; sl5];
end
% LAMP5 COLORMAP
if contains(ch488, 'lamp5', IgnoreCase=true)
    ch488 = 'LAMP5';
    mc488 = [168/255 213/255 157/255]; % celadon a8d59d
    lamp2 = [218/255 236/255 212/255]; %daecd4
    lamp3 = [193/255 225/255 184/255]; %c1e1b8
    lamp4 = [107/255 143/255 102/255]; %6b8f66
    lamp5 = [52/255 78/255 52/255]; %344e34
    lamp6 = [32/255 56/255 33/255]; %203821
    lamp7 = [0/255 24/255 0/255]; %001800
    map488 = [lamp2; lamp3; mc488; lamp4; lamp5; lamp6; lamp7];
elseif contains(ch594, 'lamp5', IgnoreCase=true)
    ch594 = 'LAMP5';
    mc594 = [168/255 213/255 157/255]; % celadon a8d59d
    lamp2 = [218/255 236/255 212/255]; %daecd4
    lamp3 = [193/255 225/255 184/255]; %c1e1b8
    lamp4 = [107/255 143/255 102/255]; %6b8f66
    lamp5 = [52/255 78/255 52/255]; %344e34
    lamp6 = [32/255 56/255 33/255]; %203821
    lamp7 = [0/255 24/255 0/255]; %001800
    map594 = [lamp2; lamp3; mc594; lamp4; lamp5; lamp6; lamp7];
elseif contains(ch647, 'lamp5', IgnoreCase=true)
    ch647 = 'LAMP5';
    mc647 = [168/255 213/255 157/255]; % celadon a8d59d
    lamp2 = [218/255 236/255 212/255]; %daecd4
    lamp3 = [193/255 225/255 184/255]; %c1e1b8
    lamp4 = [107/255 143/255 102/255]; %6b8f66
    lamp5 = [52/255 78/255 52/255]; %344e34
    lamp6 = [32/255 56/255 33/255]; %203821
    lamp7 = [0/255 24/255 0/255]; %001800
    map647 = [lamp2; lamp3; mc647; lamp4; lamp5; lamp6; lamp7];
end
% GAD1 COLORMAP
if contains(ch488, 'gad1', IgnoreCase=true)
    ch488 = 'GAD1';
    mc488 = [51/255 51/255 51/255]; % gad1 charcoal 333333
    ga1 = [187/255 187/255 187/255]; %bbbbbb
    ga2 = [138/255 138/255 138/255]; %8a8a8a
    ga3 = [93/255 93/255 93/255]; %5d5d5d
    ga4 = [36/255 36/255 36/255]; %242424
    ga5 = [0 0 0]; %000000
    map488 = [ga1; ga2; ga3; mc488; ga4; ga5];
elseif contains(ch594, 'gad1', IgnoreCase=true)
    ch594 = 'GAD1';
    mc594 = [51/255 51/255 51/255]; % gad1 charcoal 333333
    ga1 = [187/255 187/255 187/255]; %bbbbbb
    ga2 = [138/255 138/255 138/255]; %8a8a8a
    ga3 = [93/255 93/255 93/255]; %5d5d5d
    ga4 = [36/255 36/255 36/255]; %242424
    ga5 = [0 0 0]; %000000
    map594 = [ga1; ga2; ga3; mc594; ga4; ga5];
elseif contains(ch647, 'gad1', IgnoreCase=true)
    ch647 = 'GAD1';
    mc647 = [51/255 51/255 51/255]; % gad1 charcoal 333333
    ga1 = [187/255 187/255 187/255]; %bbbbbb
    ga2 = [138/255 138/255 138/255]; %8a8a8a
    ga3 = [93/255 93/255 93/255]; %5d5d5d
    ga4 = [36/255 36/255 36/255]; %242424
    ga5 = [0 0 0]; %000000
    map647 = [ga1; ga2; ga3; mc647; ga4; ga5];
end
% LAMP5-GAD1 COLORMAP
if contains(ch488, 'lamp5-gad1', IgnoreCase=true)
    ch488 = 'LAMP5-GAD1';
    mc488 = [168/255 213/255 157/255]; % celadon a8d59d
    lamp2 = [218/255 236/255 212/255]; %daecd4
    lamp3 = [193/255 225/255 184/255]; %c1e1b8
    lamp4 = [107/255 143/255 102/255]; %6b8f66
    lamp5 = [52/255 78/255 52/255]; %344e34
    lamp6 = [32/255 56/255 33/255]; %203821
    lamp7 = [0/255 24/255 0/255]; %001800
    map488 = [lamp2; lamp3; mc488; lamp4; lamp5; lamp6; lamp7];
end
% VIP COLORMAP
if contains(ch488, 'vip', IgnoreCase=true)
    ch488 = 'VIP';
    mc488 = [43/255 160/255 149/255]; % teal 2ba095
    vip1 = [216/255 233/255 230/255]; %d8e9e6
    vip2 = [165/255 209/255 202/255]; %a5d1ca
    vip3 = [112/255 184/255 175/255]; %70b8af
    vip4 = [35/255 107/255 99/255]; %236b63
    vip5 = [23/255 59/255 54/255]; %173b36
    vip6 = [9/255 52/255 43/255]; %09342b
    vip7 = [0/255 29/255 22/255]; %001d16
    map488 = [vip1; vip2; vip3; mc488; vip4; vip5; vip6; vip7];
elseif contains(ch594, 'vip', IgnoreCase=true)
    ch594 = 'VIP';
    mc594 = [43/255 160/255 149/255]; % teal 2ba095
    vip1 = [216/255 233/255 230/255]; %d8e9e6
    vip2 = [165/255 209/255 202/255]; %a5d1ca
    vip3 = [112/255 184/255 175/255]; %70b8af
    vip4 = [35/255 107/255 99/255]; %236b63
    vip5 = [23/255 59/255 54/255]; %173b36
    vip6 = [9/255 52/255 43/255]; %09342b
    vip7 = [0/255 29/255 22/255]; %001d16
    map594 = [vip1; vip2; vip3; mc594; vip4; vip5; vip6; vip7];
elseif contains(ch647, 'vip', IgnoreCase=true)
    ch647 = 'VIP';
    mc647 = [43/255 160/255 149/255]; % teal 2ba095
    vip1 = [216/255 233/255 230/255]; %d8e9e6
    vip2 = [165/255 209/255 202/255]; %a5d1ca
    vip3 = [112/255 184/255 175/255]; %70b8af
    vip4 = [35/255 107/255 99/255]; %236b63
    vip5 = [23/255 59/255 54/255]; %173b36
    vip6 = [9/255 52/255 43/255]; %09342b
    vip7 = [0/255 29/255 22/255]; %001d16
    map647 = [vip1; vip2; vip3; mc647; vip4; vip5; vip6; vip7];
end
% CXCL14 COLORMAP
if contains(ch488, 'cxcl14', IgnoreCase=true)
    ch488 = 'CXCL14';
    mc488 = [128/255 76/255 116/255]; % red purple 804c74
    cx1 = [235/255 223/255 231/255]; %ebdfe7
    cx2 = [199/255 172/255 191/255]; %c7acbf
    cx3 = [164/255 123/255 153/255]; %a47b99
    cx4 = [94/255 58/255 86/255]; %5e3a56
    cx5 = [62/255 41/255 57/255]; %3e2939
    cx6 = [41/255 19/255 34/255]; %291322
    cx7 = [24/255 0/255 16/255]; %180010
    map488 = [cx1; cx2; cx3; mc488; cx4; cx5; cx6; cx7];
elseif contains(ch594, 'cxcl14', IgnoreCase=true)
    ch594 = 'CXCL14';
    mc594 = [128/255 76/255 116/255]; % red purple 804c74
    cx1 = [235/255 223/255 231/255]; %ebdfe7
    cx2 = [199/255 172/255 191/255]; %c7acbf
    cx3 = [164/255 123/255 153/255]; %a47b99
    cx4 = [94/255 58/255 86/255]; %5e3a56
    cx5 = [62/255 41/255 57/255]; %3e2939
    cx6 = [41/255 19/255 34/255]; %291322
    cx7 = [24/255 0/255 16/255]; %180010
    map594 = [cx1; cx2; cx3; mc594; cx4; cx5; cx6; cx7];
elseif contains(ch647, 'cxcl14', IgnoreCase=true)
    ch647 = 'CXCL14';
    mc647 = [128/255 76/255 116/255]; % red purple 804c74
    cx1 = [235/255 223/255 231/255]; %ebdfe7
    cx2 = [199/255 172/255 191/255]; %c7acbf
    cx3 = [164/255 123/255 153/255]; %a47b99
    cx4 = [94/255 58/255 86/255]; %5e3a56
    cx5 = [62/255 41/255 57/255]; %3e2939
    cx6 = [41/255 19/255 34/255]; %291322
    cx7 = [24/255 0/255 16/255]; %180010
    map647 = [cx1; cx2; cx3; mc647; cx4; cx5; cx6; cx7];
end

% graphing marker shape
ms = 'o';

% graphing marker transparance
mt = '1';

% GRAPHING AXIS SIZING
if contains(brainarea, 'ctx', IgnoreCase=true)
    z = [-5000 200000 -5000 200000];
elseif contains(brainarea, 'str', IgnoreCase=true)
    z = [-5000 70000 -5000 70000];
else
    z = [-5000 200000 -5000 200000];
end

%% read in excel files and plot

% use tabulartext datastore to read in multiple csv files from working  
% directory (pwd), select variables of interest

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

% FIND TOTAL NUMBER OF FILES
num_files = length(ds.Files);

% READ IN FILES AND CREATE A TABLE W THE TOTAL NUMBER OF CELLS/EVENTS
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
end

%% scatterplot genes against dapi save normalization values
for k = 0:num_ch-1
    for j = 1:num_s
        b = dir('*.csv');
        f = b(num_s*k+j).name;
        slice = s(j);

        % PLOT CHANNELS AGAINST DAPI
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

        % CREAT NORMALIZED TABLES FOR NORMALIZATION PLOTS
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
        end        
    end
end

%% save output as csv file in output folder

% WRITE CSV FILES FOR EVENTS
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
        % PLOT GENE 488 NORMALIZED TO DAPI
        normalized_plot(s, N_488, mc488, ch488, a1, chdapi);
        if num_s > 1
            xticks(s(1):sm:s(num_s));
        elseif s == 1
            xticks([s(1)]);
        end
        
        % SAVE PNG 488
        saveas(gcf, strcat(out_path,'norm-dapi_', ch488, ...
            '_', a1, '.png'));

        % WRITE CSV 488
        filename = string(strcat('normalization-dapi_', ch488, '_', a1, '.csv'));
        file_path = strcat(out_path, filename);
        writematrix(N_488, file_path, 'WriteMode', 'overwrite');
    end
    if on_594 == 1
        % PLOT GENE 594 NORMALIZED TO DAPI
        normalized_plot(s, N_594, mc594, ch594, a1, chdapi);
        if num_s > 1
            xticks(s(1):sm:s(num_s));
        elseif s == 1
            xticks([s(1)]);
        end
        
        % SAVE PNG 594
        saveas(gcf, strcat(out_path,'norm-dapi_', ch594, ...
            '_', a1, '.png'));

        % WRITE CSV 594
        filename = string(strcat('normalization-dapi_', ch594, '_', a1, '.csv'));
        file_path = strcat(out_path, filename);
        writematrix(N_594, file_path, 'WriteMode', 'overwrite');
    end
    if on_647 == 1
        % PLOT GENE 647 NORMALIZED TO DAPI
        normalized_plot(s, N_647, mc647, ch647, a1, chdapi);
        if num_s > 1
            xticks(s(1):sm:s(num_s));
        elseif s == 1
            xticks([s(1)]);
        end
        
        % SAVE PNG 647
        saveas(gcf, strcat(out_path,'norm-dapi_', ch647, ...
            '_', a1, '.png'));

        % WRITE CSV 647
        filename = string(strcat('normalization-dapi_', ch647, '_', a1, '.csv'));
        file_path = strcat(out_path, filename);
        writematrix(N_647, file_path, 'WriteMode', 'overwrite');
    end
end

%% downsampling for vectorized images

% downsample scatterplots if needed for saving larger vector graphic files
% input input multiplier that is less than or equal to 1

if plot_downsample == 1
    % INPUT MULTIPLIER FOR DOWNSAMPLING
    dd = inputdlg({'Multiplier for Downsampling - Enter a decimal less than or = to 1'}, 'Multiplier for Downsampling');
    multiplier = str2num(dd{1});

    for p = 0:num_ch-1
        for pp = 1:num_s
            b = dir('*.csv');
            f = b(num_s * p + pp).name;
            slice = s(pp);

            if contains(f, '488')
                % GENE 488 ARRAY
                T1_488{pp} = table2array(T1{num_s * p + pp});
                height_T1_488{pp} = height(T1_488{pp});

                % INDEX WITH 'randsample'
                index_488{pp} = randsample(1:size(T1{num_s * p + pp}, 1), round(height_T1_488{pp}*multiplier));
                dsT1_488{pp} = T1_488{pp}(index_488{pp}, :);
                
                % PLOT 488 
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
                % GENE 594 ARRAY
                T1_594{pp} = table2array(T1{num_s * p + pp});
                height_T1_594{pp} = height(T1_594{pp});

                % INDEX WITH 'randsample'
                index_594{pp} = randsample(1:size(T1{num_s * p + pp}, 1), round(height_T1_594{pp}*multiplier));
                dsT1_594{pp} = T1_594{pp}(index_594{pp}, :);
                
                % PLOT 594
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
                % GENE 647 ARRAY
                T1_647{pp} = table2array(T1{num_s * p + pp});
                height_T1_647{pp} = height(T1_647{pp});

                % INDEX WITH 'randsample'
                index_647{pp} = randsample(1:size(T1{num_s * p + pp}, 1), round(height_T1_647{pp}*multiplier));
                dsT1_647{pp} = T1_647{pp}(index_647{pp}, :);
                
                % PLOT 647
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
                % DAPI ARRAY
                T1_dapi{pp} = table2array(T1{pp + dapi_set});
                heightT1dapi{pp} = height(T1_dapi{pp});

                % INDEX DAPI WITH 'randsample'
                indexdapi{pp} = randsample(1:size(T1_dapi{pp}, 1), round(heightT1dapi{pp}*multiplier));
                dsT1dapi{pp} = T1_dapi{pp}(indexdapi{pp}, :);

                % PLOT DAPI SEPARATELY
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
    % INPUT NUM BINS FOR FIRST SECTION
    bb = inputdlg({'Number of bins - eg. 100 for ctx'}, ['Number of bins for Histograms']);
    bin_num = str2num(bb{1});

    for q = 0:num_ch-1
        for qq = 1:num_s
            b = dir('*.csv');
            f = b(num_s * q + qq).name;
            slice = s(qq);

            % DAPI ARRAY
            T1_dapi{qq} = table2array(T1{qq + dapi_set});

            % DETERMINE SIZE BASED ON DAPI ARRAY
            xhistsize{qq} = max(T1_dapi{qq}(:, 2));
            yhistsize{qq} = max(T1_dapi{qq}(:, 3));

            % DETERMINE NUM BINS PER SLICE FOR SUBSEQUENT SLICES
            xhistratio{qq} = xhistsize{qq}/xhistsize{1};

            xhistbin{qq} = bin_num.*xhistratio{qq};
            yhistbin{qq} = (xhistbin{qq} * yhistsize{qq}) / xhistsize{qq};

            nxhistbins{qq} = [round(xhistbin{qq})];
            nyhistbins{qq} = [round(yhistbin{qq})];

            % FIND EDGES OF DAPI HISTOGRAM OVER (A/P) X AXIS
            [N_dapi{qq}, edges{qq}] = histcounts(T1_dapi{qq}(:,2), nxhistbins{qq});

            % FIND EDGES OF DAPI HISTOGRAM OVER (D/V) Y AXIS
            [N_dapiY{qq}, edgesY{qq}] = histcounts(T1_dapi{qq}(:,3), nyhistbins{qq});

            if contains(f, '488')
                % GENE 488 HISTOGRAM OVER (A/P) X AXIS, NORMALIZED HISTOGRAM
                T1_488{qq} = table2array(T1{num_s * q + qq});
                N_488array{qq} = histcounts(T1_488{qq}(:,2), edges{qq});
                N_488norm{qq} = N_488array{qq}./N_dapi{qq}.*100;
                N_488norm{qq}(isnan(N_488norm{qq})) = 0; % if there is a NaN value, replace NaN w 0

                % CALCULATE AVERAGE
                averageN488 = mean(N_488norm{qq});

                % PLOT NORMALIZED HISTOGRAM OF GENE 488 AGAINST DAPI FOR A/P AXIS,
                % (0,0) = MOST POSTERIOR
                figure;
                hold on
                bar((1:nxhistbins{qq}), N_488norm{qq}, 'FaceColor', mc488, 'EdgeColor','none', ...
                    'FaceAlpha', 1, 'BarWidth', 1);
                yline(averageN488, 'Color', [0 0 0], 'LineStyle', '--');
                title(strcat('Percentage-', ch488, ' to DAPI - A-P - ', num2str(slice)));
                xlabel('histogram bins');
                hold off;

                % GENE 488 HISTOGRAM OVER (D/V) Y AXIS, NORMALIZED HISTOGRAM
                N_488arrayY{qq} = histcounts(T1_488{qq}(:,3), edgesY{qq});
                N_488normY{qq} = N_488arrayY{qq}./N_dapiY{qq}.*100;
                N_488normY{qq}(isnan(N_488normY{qq})) = 0; % if there is a NaN, replace NaN w 0

                % CALCULATE AVERAGE
                averageNY488 = mean(N_488normY{qq});

                % PLOT NORMALIZED HISTOGRAM OF GENE 488 AGAINST DAPI FOR D/V AXIS,
                % (0,0) = MOST DORSAL
                figure;
                hold on
                bar((1:nyhistbins{qq}), N_488normY{qq},'FaceColor', mc488, 'EdgeColor','none', ...
                    'FaceAlpha',1, 'Horizontal','on', 'BarWidth',1);
                xline(averageNY488, 'Color', [0 0 0], 'LineStyle','--');
                title(strcat('Percentage-', ch488, ' to DAPI - D-V - ', num2str(slice)));
                xlabel('histogram bins');
                hold off;

                % PLOT A/P X HISTOGRAM FOR DAPI AND GENE 488
                figure;
                hold on
                xdapihist{qq} = histogram(T1_dapi{qq}(:,2), 'FaceColor',mcdapi, ...
                    'EdgeColor','none', 'Orientation','vertical', 'NumBins', nxhistbins{qq});
                x488hist{qq} = histogram(T1_488{qq}(:,2), 'FaceColor', mc488, 'EdgeColor','none', ...
                    'Orientation','vertical', 'BinEdges', xdapihist{qq}.BinEdges);
                title(strcat('Hist X -', ch488, '- (A-P) - ', num2str(slice)));
                xlabel('A-P');
                hold off

                % WRITE CSV FILES FOR DAPI, GENE 488, AND NORMALIZED HISTOGRAM
                % VALUES FOR A/P X DIRECTION
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

                % PLOT Y HISTOGRAM (D/V) FOR DAPI AND GENE 488
                figure;
                hold on
                ydapihist{qq} = histogram(T1_dapi{qq}(:,3), 'FaceColor',mcdapi, ...
                    'EdgeColor','none', 'Orientation','horizontal', 'NumBins', nyhistbins{qq});
                y488hist{qq} = histogram(T1_488{qq}(:,3), 'FaceColor',mc488, ...
                    'EdgeColor','none', 'Orientation','horizontal', 'BinEdges', ydapihist{qq}.BinEdges);
                title(strcat('Hist Y -', ch488, '- (D-V) - ', num2str(slice)));
                xlabel('D-V');
                hold off

                % WRITE CSV FILES FOR DAPI, GENE 488, AND NORMALIZED
                % HISTOGRAM VALUES FOR Y D/V DIRECTION
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

                % PLOT SCATTER HISTOGRAM GENE 488 FOR EASY ORIENTATION TO BRAIN SLICE
                % NUMBER OF BINS ARE FIXED ACROSS AXES AND SLICES
                figure;
                scatterhistogram(T1_488{qq}(:,2), T1_488{qq}(:,3), ...
                    'HistogramDisplayStyle','bar', 'Color', mc488, 'NumBins', bin_num);
                title(strcat('Scatter Histogram-', ch488, ' Slice ', num2str(slice)));
            end
            if contains(f, '594')
                % GENE 594 HISTOGRAM FOR A/P X AXIS, NORMALIZED HISTOGRAM
                T1_594{qq} = table2array(T1{num_s * q + qq});
                N_594array{qq} = histcounts(T1_594{qq}(:,2), edges{qq});
                N_594norm{qq} = N_594array{qq}./N_dapi{qq}.*100;
                N_594norm{qq}(isnan(N_594norm{qq})) = 0; % if there is a NaN value, replace NaN w 0

                % CALCULATE AVERAGE
                averageN594 = mean(N_594norm{qq});

                % PLOT NORMALIZED HISTOGRAM FOR GENE 594 AGAINST DAPI FOR
                % A/P X AXIS. (0,0) = MOST POSTERIOR
                figure;
                hold on
                bar((1:nxhistbins{qq}), N_594norm{qq}, 'FaceColor', mc594, 'EdgeColor','none', ...
                    'FaceAlpha', 1, 'BarWidth', 1);
                yline(averageN594, 'Color', [0 0 0], 'LineStyle', '--');
                title(strcat('Percentage-', ch594, ' to DAPI - A-P - ', num2str(slice)));
                xlabel('histogram bins');
                hold off;

                % GENE 594 HISTOGRAM OVER D/V Y AXIS, NORMALIZED HISTOGRAM
                N_594arrayY{qq} = histcounts(T1_594{qq}(:,3), edgesY{qq});
                N_594normY{qq} = N_594arrayY{qq}./N_dapiY{qq}.*100;
                N_594normY{qq}(isnan(N_594normY{qq})) = 0; % if there is a NaN, replace NaN w 0

                % CALCULATE AVERAGE
                averageNY594 = mean(N_594normY{qq});

                % PLOT NORMALIZED HISTOGRAM FOR GENE 594 AGAINST DAPI FOR
                % D/V Y AXIS. (0,0) = MOST DORSAL
                figure;
                hold on
                bar((1:nyhistbins{qq}), N_594normY{qq},'FaceColor', mc594, 'EdgeColor','none', ...
                    'FaceAlpha',1, 'Horizontal','on', 'BarWidth',1);
                xline(averageNY594, 'Color', [0 0 0], 'LineStyle','--');
                title(strcat('Percentage-', ch594, ' to DAPI - D-V - ', num2str(slice)));
                xlabel('histogram bins');
                hold off;

                % PLOT A/P X HISTOGRAM FOR GENE 594 AND DAPI
                figure;
                hold on
                xdapihist{qq} = histogram(T1_dapi{qq}(:,2), 'FaceColor',mcdapi, ...
                    'EdgeColor','none', 'Orientation','vertical', 'NumBins', nxhistbins{qq});
                x594hist{qq} = histogram(T1_594{qq}(:,2), 'FaceColor', mc594, 'EdgeColor','none', ...
                    'Orientation','vertical', 'BinEdges', xdapihist{qq}.BinEdges);
                title(strcat('Hist X -', ch594, '- (A-P) - ', num2str(slice)));
                xlabel('A-P');
                hold off

                % WRITE CSV FILES FOR DAPI, GENE 594, AND NORMALIZED
                % HISTOGRAM FOR X A/P DIRECTION
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

                % PLOT Y D/V HISTOGRAM FOR GENE 594 AND DAPI
                figure;
                hold on
                ydapihist{qq} = histogram(T1_dapi{qq}(:,3), 'FaceColor',mcdapi, ...
                    'EdgeColor','none', 'Orientation','horizontal', 'NumBins',nyhistbins{qq});
                y594hist{qq} = histogram(T1_594{qq}(:,3), 'FaceColor',mc594, ...
                    'EdgeColor','none', 'Orientation','horizontal', 'BinEdges',ydapihist{qq}.BinEdges);
                title(strcat('Hist Y -', ch594, '- (D-V) - ', num2str(slice)));
                xlabel('D-V');
                hold off

                % WRITE CSV FILE FOR DAPI, GENE 594, AND NORMALIZED
                % HISTOGRAM VALUES FOR D/V Y DIRECTION
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

                % PLOT SCATTER HISTOGRAM FOR GENE 594 FOR EASY ORIENTATION TO BRAIN SLICE
                % NUMBERS OF BINS ARE FIXED ACROSS AXES AND SLICES
                figure;
                scatterhistogram(T1_594{qq}(:,2), T1_594{qq}(:,3), ...
                    'HistogramDisplayStyle','bar', 'Color', mc594, 'NumBins', bin_num);
                title(strcat('Scatter Histogram-', ch594, ' Slice ', num2str(slice)));
            end
            if contains (f, '647')
                % GENE 647 HISTOGRAM OVER X A/P AXIS, NORMALIZED HISTOGRAM
                T1_647{qq} = table2array(T1{num_s * q + qq});
                N_647array{qq} = histcounts(T1_647{qq}(:,2), edges{qq});
                N_647norm{qq} = N_647array{qq}./N_dapi{qq}.*100;
                N_647norm{qq}(isnan(N_647norm{qq})) = 0; % if there is a NaN value, replace NaN w 0

                % CALCULATE AVERAGE
                averageN647 = mean(N_647norm{qq});

                % PLOT NORMALIZED HISTOGRAM OF GENE 647 AGAINST DAPI FOR A/P X AXIS,
                % (0,0) = MOST POSTERIOR
                figure;
                hold on
                bar((1:nxhistbins{qq}), N_647norm{qq}, 'FaceColor', mc647, 'EdgeColor','none', ...
                    'FaceAlpha', 1, 'BarWidth', 1);
                yline(averageN647, 'Color', [0 0 0], 'LineStyle', '--');
                title(strcat('Percentage-', ch647, ' to DAPI - A-P - ', num2str(slice)));
                xlabel('histogram bins');
                hold off;

                % GENE 647 HISTOGRAM OVER Y D/V AXIS, NORMALIZED HISTOGRAM
                N_647arrayY{qq} = histcounts(T1_647{qq}(:,3), edgesY{qq});
                N_647normY{qq} = N_647arrayY{qq}./N_dapiY{qq}.*100;
                N_647normY{qq}(isnan(N_647normY{qq})) = 0; % if there is a NaN, replace NaN w 0

                % CALCULATE AVERAGE
                averageNY647 = mean(N_647normY{qq});

                % PLOT NORMALIZED HISTOGRAM OF GENE 647 AGAINST DAPI FOR D/V AXIS,
                % (0,0) = MOST DORSAL
                figure;
                hold on
                bar((1:nyhistbins{qq}), N_647normY{qq},'FaceColor', mc647, 'EdgeColor','none', ...
                    'FaceAlpha',1, 'Horizontal','on', 'BarWidth',1);
                xline(averageNY647, 'Color', [0 0 0], 'LineStyle','--');
                title(strcat('Percentage-', ch647, ' to DAPI - D-V - ', num2str(slice)));
                xlabel('histogram bins');
                hold off;

                % PLOT X A/P HISTOGRAM FOR GENE 647 AND DAPI
                figure;
                hold on
                xdapihist{qq} = histogram(T1_dapi{qq}(:,2), 'FaceColor',mcdapi, ...
                    'EdgeColor','none', 'Orientation','vertical', 'NumBins', nxhistbins{qq});
                x647hist{qq} = histogram(T1_647{qq}(:,2), 'FaceColor', mc647, 'EdgeColor','none', ...
                    'Orientation','vertical', 'BinEdges', xdapihist{qq}.BinEdges);
                title(strcat('Hist X -', ch647, '- (A-P) - ', num2str(slice)));
                xlabel('A-P');
                hold off

                % WRITE CSV FILES FOR DAPI, GENE 647, AND NORMALIZED
                % HISTOGRAM VALUES FOR A/P X DIRECTION
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

                % PLOT Y HISTOGRAM D/V FOR GENE 647 AND DAPI
                figure;
                hold on
                ydapihist{qq} = histogram(T1_dapi{qq}(:,3), 'FaceColor',mcdapi, ...
                    'EdgeColor','none', 'Orientation','horizontal', 'NumBins',nyhistbins{qq});
                y647hist{qq} = histogram(T1_647{qq}(:,3), 'FaceColor',mc647, ...
                    'EdgeColor','none', 'Orientation','horizontal', 'BinEdges',ydapihist{qq}.BinEdges);
                title(strcat('Hist Y -', ch647, '- (D-V) - ', num2str(slice)));
                xlabel('D-V');
                hold off

                % WRITE CSV FILES FOR DAPI, GENE 647, AND NORMALIZED
                % HISTOGRAM VALUES FOR D/V DIRECTION (Y)
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

                % PLOT SCATTER HISTOGRAM FOR GENE 647 FOR EASY ORIENTATION
                % TO BRAIN SLICE. NUMBERS OF BINS FIXED ACROSS AXES AND
                % SLICE
                figure;
                scatterhistogram(T1_647{qq}(:,2), T1_647{qq}(:,3), ...
                    'HistogramDisplayStyle','bar', 'Color', mc647, 'NumBins', bin_num);
                title(strcat('Scatter Histogram-', ch647, ' Slice ', num2str(slice)));
            end
        end
    end
end

%% plot density

% create density/2-d histogram plots per slice; plots include
% heatmaps of dapi, heatmaps of gene, and heatmaps of gene normalized to dapi,
% dscatter also produces density scatter plot; csv files written for values
% in heatmap of gene and normalized heatmap

if plot_density == 1
    % INPUT NUMBER OF BINS FOR FIRST SLICE
    cc = inputdlg({'Number of bins - eg. 100 for ctx'}, ['Number of bins for Heatmaps']);
    bin_num = str2num(cc{1});

    for r = 0:num_ch-1
        for rr = 1:num_s
            b = dir('*.csv');
            f = b(num_s * r + rr).name;
            slice = s(rr);

            % SAVE DAPI ARRAY
            T1_dapi{rr} = table2array(T1{rr + dapi_set});

            % DETERMINE SIZE FROM DAPI ARRAYS
            xsize{rr} = max(T1_dapi{rr}(:, 2));
            ysize{rr} = max(T1_dapi{rr}(:, 3));

            % DETERMINE NUMBER OF BINS ACROSS SLICES BASED ON FIRST,
            % LARGEST AND MOST MEDIAL SLICE
            xratio{rr} = xsize{rr}/xsize{1};

            xbin{rr} = bin_num.*xratio{rr};
            ybin{rr} = (xbin{rr} * ysize{rr}) / xsize{rr};

            nbins{rr} = [round(xbin{rr}), round(ybin{rr})];
            
            % FIND X AND Y EDGED OF DAPI ARRAY
            [NDapi{rr}, Xedges{rr}, Yedges{rr}] = histcounts2(T1_dapi{rr}(:,2), T1_dapi{rr}(:,3), nbins{rr});

            if contains(f, '488')
                % GENE 488 ARRAY AND NORMALIZATION TO DAPI
                T1_array488{rr} = table2array(T1{num_s * r + rr});
                [NArray488{rr}] = histcounts2(T1_array488{rr}(:,2), T1_array488{rr}(:,3), Xedges{rr}, Yedges{rr});

                NNorm488{rr} = NArray488{rr}./NDapi{rr}.*100;
                NNorm488{rr}(isnan(NNorm488{rr})) = 0; % if there is NaN due to dividing by 0, replace NaN w 0

                % PLOT 488 DENSITY HEATMAP
                figure;
                histogram2('XBinEdges', Xedges{rr},'YBinEdges', Yedges{rr},'BinCounts', ...
                    NArray488{rr}, 'DisplayStyle','tile', 'EdgeColor','none', 'ShowEmptyBins','off');
                colormap(map488);
                axis(z);
                title(strcat('Heatmap-', ch488, '-', num2str(slice)));
                colorbar;
%                 if contains(MOI, 'sst')
%                     clim([0 15]);
%                 elseif contains(MOI, 'pvalb')
%                     clim([0 25]);
%                 elseif contains(MOI, 'vip')
%                     clim([0 10]);
%                 elseif contains(MOI, 'lamp5')
%                     clim([0 10]);
%                 elseif contains(MOI, 'cxcl14')
%                     clim([0 30]);
%                 end
                grid off;

                % WRITE 488 DENSITY HEATMAP ARRAY
                filename = string(strcat(ch488, '_', num2str(slice), '_DensityHeatmapArray.csv'));
                file_path = strcat(out_path, filename);
                writematrix(NArray488{rr}, file_path, 'WriteMode', 'overwrite');

                % PLOT NORMALIZED HEATMAP (488 GENE TO DAPI)
                figure;
                histogram2('XBinEdges', Xedges{rr},'YBinEdges',Yedges{rr},'BinCounts', ...
                    NNorm488{rr}, 'DisplayStyle','tile', 'EdgeColor','none', 'ShowEmptyBins','off');
                colormap(map488);
                axis(z);
                title(strcat(ch488, '-normalized to DAPI-', num2str(slice)));
                colorbar;
%                 if contains(MOI, 'sst')
%                     clim([0 9]);
%                 elseif contains(MOI, 'pvalb')
%                     clim([0 8]);
%                 elseif contains(MOI, 'vip')
%                     clim([0 5]);
%                 elseif contains(MOI, 'lamp5')
%                     clim([0 4]);
%                 elseif contains(MOI, 'cxcl14')
%                     clim([0 15]);
%                 end
                grid off;

                % WRITE 488 NORMALIZED DENSITY HEATMAP ARRAY
                filename = string(strcat(ch488, '_', num2str(slice), '_NormalizedDensityHeatmapArray.csv'));
                file_path = strcat(out_path, filename);
                writematrix(NNorm488{rr}, file_path, 'WriteMode', 'overwrite');

                % PLOT DENSITY SCATTER VERSION FOR 488 GENE
                figure;
                hold on;
                dscatter(T1_array488{rr}(:,2), T1_array488{rr}(:,3), 'BINS', nbins{rr});
                title(strcat('density scatter - ', ch488, ' slice - ', num2str(slice)));
                axis(z);
                colormap(map488);
                clim([0 1]);
                colorbar;
                hold off;
            end
            if contains(f, '594')
                % GENE 594 ARRAY AND NORMALIZATION TO DAPI
                T1_array594{rr} = table2array(T1{num_s * r + rr});
                [NArray594{rr}] = histcounts2(T1_array594{rr}(:,2), T1_array594{rr}(:,3), Xedges{rr}, Yedges{rr});

                NNorm594{rr} = NArray594{rr}./NDapi{rr}.*100;
                NNorm594{rr}(isnan(NNorm594{rr})) = 0; % if there is NaN due to dividing by 0, replace NaN w 0

                % PLOT 594 DENSITY HEATMAP
                figure;
                histogram2('XBinEdges', Xedges{rr},'YBinEdges', Yedges{rr},'BinCounts', ...
                    NArray594{rr}, 'DisplayStyle','tile', 'EdgeColor','none', 'ShowEmptyBins','off');
                colormap(map594);
                axis(z);
                title(strcat('Heatmap-', ch594, '-', num2str(slice)));
                grid off;

                % WRITE 594 DENSITY HEATMAP ARRAY
                filename = string(strcat(ch594, '_', num2str(slice), '_DensityHeatmapArray.csv'));
                file_path = strcat(out_path, filename);
                writematrix(NArray594{rr}, file_path, 'WriteMode', 'overwrite');

                % PLOT NORMALIZED HEATMAP (594 GENE TO DAPI)
                figure;
                histogram2('XBinEdges', Xedges{rr},'YBinEdges',Yedges{rr},'BinCounts', ...
                    NNorm594{rr}, 'DisplayStyle','tile', 'EdgeColor','none', 'ShowEmptyBins','off');
                colormap(map594);
                axis(z);
                title(strcat(ch594, '-normalized to DAPI-', num2str(slice)));
                colorbar;
                grid off;

                % WRITE 594 NORMALIZED DENSITY HEATMAP ARRAY
                filename = string(strcat(ch594, '_', num2str(slice), '_NormalizedDensityHeatmapArray.csv'));
                file_path = strcat(out_path, filename);
                writematrix(NNorm594{rr}, file_path, 'WriteMode', 'overwrite');

                % PLOT DENSITY SCATTER VERSION FOR 594 GENE
                figure;
                hold on;
                dscatter(T1_array594{rr}(:,2), T1_array594{rr}(:,3), 'BINS', nbins{rr});
                title(strcat('density scatter - ', ch594, ' slice - ', num2str(slice)));
                axis(z);
                colormap(map594);
                clim([0 1]);
                colorbar;
                hold off;
            end
            if contains(f, '647')
                % GENE 647 ARRAY AND NORMALIZATION TO DAPI
                T1_array647{rr} = table2array(T1{num_s * r + rr});
                [NArray647{rr}] = histcounts2(T1_array647{rr}(:,2), T1_array647{rr}(:,3), Xedges{rr}, Yedges{rr});

                NNorm647{rr} = NArray647{rr}./NDapi{rr}.*100;
                NNorm647{rr}(isnan(NNorm647{rr})) = 0; % if there is NaN due to dividing by 0, replace NaN w 0

                % PLOT 647 DENSITY HEATMAP
                figure;
                histogram2('XBinEdges', Xedges{rr},'YBinEdges', Yedges{rr},'BinCounts', ...
                    NArray647{rr}, 'DisplayStyle','tile', 'EdgeColor','none', 'ShowEmptyBins','off');
                colormap(map647);
                axis(z);
                title(strcat('Heatmap-', ch647, '-', num2str(slice)));
                grid off;

                % WRITE 647 DENSITY HEATMAP ARRAY
                filename = string(strcat(ch647, '_', num2str(slice), '_DensityHeatmapArray.csv'));
                file_path = strcat(out_path, filename);
                writematrix(NArray647{rr}, file_path, 'WriteMode', 'overwrite');

                % PLOT NORMALIZED HEATMAP (647 GENE TO DAPI)
                figure;
                histogram2('XBinEdges', Xedges{rr},'YBinEdges',Yedges{rr},'BinCounts', ...
                    NNorm647{rr}, 'DisplayStyle','tile', 'EdgeColor','none', 'ShowEmptyBins','off');
                colormap(map647);
                axis(z);
                title(strcat(ch647, '-normalized to DAPI-', num2str(slice)));
                colorbar;
                grid off;

                % WRITE 647 NORMALIZED DENSITY HEATMAP ARRAY
                filename = string(strcat(ch647, '_', num2str(slice), '_NormalizedDensityHeatmapArray.csv'));
                file_path = strcat(out_path, filename);
                writematrix(NNorm647{rr}, file_path, 'WriteMode', 'overwrite');

                % PLOT DENSITY SCATTER VERSION FOR 647 GENE
                figure;
                hold on;
                dscatter(T1_array647{rr}(:,2), T1_array647{rr}(:,3), 'BINS', nbins{rr});
                title(strcat('density scatter - ', ch647, ' slice - ', num2str(slice)));
                axis(z);
                colormap(map647);
                clim([0 1]);
                colorbar;
                hold off;
            end
            if contains(f, 'dapi')
                % PLOT DAPI DENSITY HEATMAP
                figure;
                histogram2('XBinEdges', Xedges{rr},'YBinEdges', Yedges{rr},'BinCounts', ...
                    NDapi{rr}, 'DisplayStyle','tile', 'EdgeColor','none', 'ShowEmptyBins','off');
                colormap('cool');
                axis(z);
                title(strcat('Heatmap DAPI-', num2str(slice)));
                colorbar;
%                 clim([0 600]);
                grid off;
            end
        end
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
