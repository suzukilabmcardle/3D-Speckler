%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   3D-Speckler                                                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      
%   Written By: Jonathan Loi
%   For: Laboratory of Dr. Aussie Suzuki
%
%   Description: This code was meant to take images of punctate structures
%                and fit 2D and 3D Gaussians for particle locations,
%                rotations, and sizes.  Distance matrices and particle 
%                pairing is also performed.  Chromatic Aberrations can be
%                calibrated and performed by user.
%
%   Last Edited:        August 23rd, 2022
%   Last Edited By:     Jonathan Loi
%   Version:            1.0.0
%
%   Version Notes:      Finalized version for resubmission to JCB.
%
%   Version History:  
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Clear All %
close all; clear all; clc;

global  fullPath nChannels nPlanes imgSize zSlice xyRes zRes chOptions...
        channel1 channel2 channel3 channel4 fit2Dg fit3Dg filtInterval...
        countThreshold sizeCentroids trueCentroids pxlCentroids...
        bufferPercXY bufferPercZ thTrue caCalTrue currentChN...
        currentChannel bbCentroids currentPts bgPixel excludePts...
        boxLimits finalFitParams currentMaxIMG zoomObj mainFig...
        modeChoice g2DOpt g3DOpt bgOpt caOpt finalFit488...
        finalPts488 finalBB488 finalFit594 finalPts594 finalBB594...
        finalFit640 finalPts640 finalBB640 finalFit405 finalPts405...
        finalBB405 excludeOverlap overlapThreshold overlapOpt nOptions...
        exportPath currentBB excludeSize sizeOpt sizeL sizeU sizeLower...
        sizeUpper viewFigSize startThreshold matchVec...
        anaParams488 anaParams594 anaParams640 anaParams405 distChoiceVec...
        distMatrix488 distMatrix594 distMatrix640 distMatrix405...
        distMatrix488_594 distMatrix488_640 distMatrix488_405...
        distMatrix594_640 distMatrix594_405 distMatrix640_405...
        aberrationsVec ab488_594 ab488_640 ab488_405 ab594_640 ab594_405...
        ab640_405 multiThresholds multiSizeCentroids multiBBCentroids...
        multiPxlCentroids multiTrueCentroids multi488 multi594 multi640...
        multi405 importFile saveCheck gaussFitted msgbx fwhmDiv...
        figWidthFactor Ochannel1 Ochannel2 Ochannel3 Ochannel4 cropROI...
        currentCentroids finalCentroids488 finalCentroids594...
        finalCentroids640 finalCentroids405 nnThreshold oFit488 oBB488...
        oCen488 oFit594 oBB594 oCen594 oFit640 oBB640 oCen640 oFit405...
        oBB405 oCen405 matchNtimes sizeTransfer fromBB fromCentroids...
        currentIMG fromChoice toChoice fromFit transferBuffer gauss3DN...
        gauss2DN caSurfaceOpt caAffineOpt affineRG affineFRG affineBG...
        affineFRR affineBR affineBFR surfX_GR surfY_GR surfZ_GR...
        surfX_GFR surfY_GFR surfZ_GFR surfX_GB surfY_GB surfZ_GB...
        surfX_RFR surfY_RFR surfZ_RFR surfX_RB surfY_RB surfZ_RB...
        surfX_FRB surfY_FRB surfZ_FRB caPlot redSurfCalTrue...
        redAffineCalTrue farRedSurfCalTrue farRedAffineCalTrue...
        blueSurfCalTrue blueAffineCalTrue abOptExport...
        
% Add Current Script Location and Subfolders to Path %
folderPath = matlab.desktop.editor.getActiveFilename;
[filepath,name,ext] = fileparts(folderPath);
addpath(genpath(filepath));  
 
gaussFitted = false;
caCalTrue = false;
saveCheck = 0;
fwhmDiv = 1.5;
gauss3DN = 23;
gauss2DN = 16;
figWidthFactor = 800;
finalFit488 = []; finalBB488 = []; finalFit594 = [];
finalBB594 = []; finalFit640 = []; finalBB640 = [];
finalFit405 = []; finalBB405 = []; cropROI = [];
finalCentroids488 = []; finalCentroids594 = [];
finalCentroids640 = []; finalCentroids405 = [];

anaParams488 = []; anaParams594  = []; anaParams640  = [];
anaParams405 = []; distMatrix488  = []; distMatrix594  = [];
distMatrix640  = []; distMatrix405  = []; distMatrix488_594  = [];
distMatrix488_640  = []; distMatrix488_405 = []; distMatrix594_640  = [];
distMatrix594_405  = []; distMatrix640_405 = []; ab488_594  = [];
ab488_640  = []; ab488_405  = []; ab594_640  = []; ab594_405 = [];
ab640_405  = []; multiThresholds  = []; multi488  = []; multi594  = [];
multi640  = []; multi405 = []; matchNtimes = 0; fromBB = []; fromCentroids = [];

caSurfaceOpt = 0; caAffineOpt = 0; affineRG = []; affineFRG = []; 
affineBG = []; affineFRR = []; affineBR = []; affineBFR = []; 
surfX_GR  = []; surfY_GR = []; surfZ_GR = [];
surfX_GFR = []; surfY_GFR = []; surfZ_GFR = []; 
surfX_GB = []; surfY_GB = []; surfZ_GB = [];
surfX_RFR = []; surfY_RFR = []; surfZ_RFR = []; 
surfX_RB = []; surfY_RB = []; surfZ_RB = [];
surfX_FRB = []; surfY_FRB = []; surfZ_FRB = []; caPlot = 0;

redSurfCalTrue = false; redAffineCalTrue = false; farRedSurfCalTrue = false;
farRedAffineCalTrue = false; blueSurfCalTrue = false; blueAffineCalTrue = false;
abOptExport = [];
       
Open3DSpeckler();

%% Functions

function Open3DSpeckler()

global fullPath

% User Chooses File %
fullPath = importNewData();

% Import Data %
importAllData(fullPath);

% Choose Channels and Scaling %
openSelection()

end

%%

function fullPath = importNewData()
    
    [file,path] = uigetfile({'*.jpg;*.png;*.tif;*.nd2;*.stk;*.dv'});
    if file == 0
      % User clicked the Cancel button.
      return;
    else
        disp('File Selected:');
        fullPath = strcat(path, file);
        disp(fullPath);
    end

end

%%
function importAllData(fullPath)

    global nChannels nPlanes imgSize channel1 channel2 channel3 channel4...
            xyRes zRes Ochannel1 Ochannel2 Ochannel3 Ochannel4

    disp('Importing Data...')
    
    try
        data = bfopen(fullPath);
    catch
        warndlg('Import Error.  Please close MATLAB and try again.');
        pause(1.5);
        exit
    end
    
    
    series1 = data{1, 1};
    seriesSize = size(series1);
    C = textscan(series1{1,2}, '%s','Delimiter',';');
    sizeC = size(C{1,1});
    imgSize = size(series1{1,1});
    
    % Attempt To AutoDetect Scaling %
    try
        D = textscan(char(data{1,2}), '%s','Delimiter',',');
        strArray = D{1,1};
        
        % GET Z RESOLUTION %
        % ND2 MetaData Format %
        zInd = find(contains(strArray,'Global dZStep'));
        % DV MetaData Format %
        if isempty(zInd)
            zInd = find(contains(strArray,'Z element length'));
        end
        parseZ = textscan(strArray{zInd}, '%s','Delimiter','=');
        zRes = str2num(parseZ{1,1}{2,1});
        
        % GET XY RESOLUTION %
        % ND2 MetaData Format %
        xyInd = find(contains(strArray,'Global dCalibration'));
        % DV MetaData Format %
        if isempty(xyInd)
            xyInd = find(contains(strArray,'X element length'));
        end
        parseXY = textscan(strArray{xyInd}, '%s','Delimiter','=');
        xyRes = str2num(parseXY{1,1}{2,1});
        
        
        if xyRes == 0
            xyRes = [];
        end
        if zRes == 0
            zRes = [];
        end
    catch
        xyRes = [];
        zRes = [];
    end
    
    chanInd = find(contains(C{1,1},'C='));
    if ~isempty(chanInd)
        cN3 = textscan(C{1,1}{chanInd}, '%s','Delimiter','/');
        nChannels = str2double(cN3{1,1}{max(size(cN3{1,1}))});
    elseif isempty(chanInd)
        nChannels = 1;
    end
    
    zInd = find(contains(C{1,1},'Z='));
    if ~isempty(zInd)
        cN2 = textscan(C{1,1}{zInd}, '%s','Delimiter','/');
        nPlanes = str2double(cN2{1,1}{max(size(cN2{1,1}))});
    elseif isempty(zInd)
        nPlanes = 1;
    end
    
    disp(strcat('Channels Read:  ', num2str(nChannels)));
    disp(strcat('Planes Per Channel:  ', num2str(nPlanes)));
    
    % If Z Stack Detected %
    if nChannels > 1
        
        % Sort Data into Channels
        disp('.');
        disp('.');
        disp('Sorting Channels..........');

        for i = 1:nChannels
            
            tempName = strcat('channel', num2str(i));
            tempName2 = strcat('Ochannel', num2str(i));
            eval([tempName, '= zeros(', num2str(imgSize(1)), ',', num2str(imgSize(2)), ',', num2str(nPlanes), ');']);
            eval([tempName2, '= zeros(', num2str(imgSize(1)), ',', num2str(imgSize(2)), ',', num2str(nPlanes), ');']);
            
            for j = 1:size(series1,1)
                
                sortSTR = textscan(series1{j,2}, '%s','Delimiter',';');
                chanInd = find(contains(C{1,1},'C='));
                zInd = find(contains(C{1,1},'Z='));
                
                if ~isempty(chanInd)
                    sortSTR2 = textscan(sortSTR{1,1}{chanInd,1}, '%s','Delimiter','/');
                    sortSTR3 = textscan(sortSTR2{1,1}{1,1}, '%s','Delimiter','=');
                    tempChannelN = str2num(sortSTR3{1,1}{2,1});
                else
                    tempChannelN = 1;
                end
                
                if ~isempty(zInd)
                    sortSTR2 = textscan(sortSTR{1,1}{zInd,1}, '%s','Delimiter','/');
                    sortSTR3 = textscan(sortSTR2{1,1}{1,1}, '%s','Delimiter','=');
                    tempChannelZ = str2num(sortSTR3{1,1}{2,1});
                else
                    tempChannelZ = 1;
                end
                
                if tempChannelN == i
                    eval([tempName, '(:,:,', num2str(tempChannelZ),') = series1{', num2str(j), ', 1};']);
                    eval([tempName2, '(:,:,', num2str(tempChannelZ),') = series1{', num2str(j), ', 1};']);
                end
            end
            
        end
        
        disp('COMPLETE: Channels Successfully Sorted.');
        disp('*********************************************************************');
    end
    
    % Ask If User Has Multiple Channels To Import
    if nChannels == 1
        chCount = 1;
        nChoose = true;
        
        tempName = strcat('channel', num2str(1));
        tempName2 = strcat('Ochannel', num2str(1));
        eval([tempName, '= zeros(', num2str(imgSize(1)), ',', num2str(imgSize(2)), ',', num2str(nPlanes), ');']);
        eval([tempName2, '= zeros(', num2str(imgSize(1)), ',', num2str(imgSize(2)), ',', num2str(nPlanes), ');']);
        
        for j = 1:size(series1,1)
            
            sortSTR = textscan(series1{j,2}, '%s','Delimiter',';');
            chanInd = find(contains(C{1,1},'C='));
            zInd = find(contains(C{1,1},'Z='));
            
            if ~isempty(chanInd)
                sortSTR2 = textscan(sortSTR{1,1}{chanInd,1}, '%s','Delimiter','/');
                sortSTR3 = textscan(sortSTR2{1,1}{1,1}, '%s','Delimiter','=');
                tempChannelN = str2num(sortSTR3{1,1}{2,1});
            else
                tempChannelN = 1;
            end
            
            if ~isempty(zInd)
                sortSTR2 = textscan(sortSTR{1,1}{zInd,1}, '%s','Delimiter','/');
                sortSTR3 = textscan(sortSTR2{1,1}{1,1}, '%s','Delimiter','=');
                tempChannelZ = str2num(sortSTR3{1,1}{2,1});
            else
                tempChannelZ = 1;
            end
            
            if tempChannelN == 1
                eval([tempName, '(:,:,', num2str(tempChannelZ),') = series1{', num2str(j), ', 1};']);
                eval([tempName2, '(:,:,', num2str(tempChannelZ),') = series1{', num2str(j), ', 1};']);
            end
        end
        
        while nChoose == true
            
            % Test If Channel Limit Reached %
            if chCount >= 4
                warndlg('Maximum Channels Reached!');
                disp('Maximum Channels Reached!');
                disp('Import Complete.');
                disp('*********************************************************************');
                return;
            end
            
            answer = questdlg('Would you like to import data for additional channels?', ...
                'Single Channel Detected!', ...
                'Yes','No','Yes');
            % Handle response
            switch answer
                case 'Yes'
                    newFile = importNewData();
                    try
                        data = bfopen(newFile);
                    catch
                        warndlg('Import Error.  Please close MATLAB and try again.');
                        exit
                    end
                    series2 = data{1,1};
                    seriesSize2 = size(series2);
                    imgSize2 = size(series2{1,1});
                    
                    if (seriesSize2(1) == seriesSize(1)) && (imgSize2(1) == imgSize(1)) && (imgSize2(2) == imgSize(2))
                        chCount = chCount + 1;
                        tempName = strcat('channel', num2str(chCount));
                        eval([tempName, '= zeros(', num2str(imgSize2(1)), ',', num2str(imgSize2(2)), ',', num2str(nPlanes), ');']);
                        tempName2 = strcat('Ochannel', num2str(chCount));
                        eval([tempName2, '= zeros(', num2str(imgSize2(1)), ',', num2str(imgSize2(2)), ',', num2str(nPlanes), ');']);
                        
                        for t = 1:size(series2,1)
                            sortSTR = textscan(series1{t,2}, '%s','Delimiter',';');
                            chanInd = find(contains(C{1,1},'C='));
                            zInd = find(contains(C{1,1},'Z='));
                            
                            if ~isempty(chanInd)
                                sortSTR2 = textscan(sortSTR{1,1}{chanInd,1}, '%s','Delimiter','/');
                                sortSTR3 = textscan(sortSTR2{1,1}{1,1}, '%s','Delimiter','=');
                                tempChannelN = str2num(sortSTR3{1,1}{2,1});
                            else
                                tempChannelN = 1;
                            end
                            
                            if ~isempty(zInd)
                                sortSTR2 = textscan(sortSTR{1,1}{zInd,1}, '%s','Delimiter','/');
                                sortSTR3 = textscan(sortSTR2{1,1}{1,1}, '%s','Delimiter','=');
                                tempChannelZ = str2num(sortSTR3{1,1}{2,1});
                            else
                                tempChannelZ = 1;
                            end
                            
                            if tempChannelN == chCount
                                eval([tempName, '(:,:,', num2str(tempChannelZ),') = series1{', num2str(t), ', 1};']);
                                eval([tempName2, '(:,:,', num2str(tempChannelZ),') = series1{', num2str(t), ', 1};']);
                            end
                        end
                        
                        nChannels = nChannels + 1;
                        disp(strcat('Channel', num2str(chCount)));
                        disp(strcat('Channels Read:  ', num2str(nChannels)));
                        disp(strcat('Planes Per Channel:  ', num2str(nPlanes)));
                        disp('*********************************************************************');
                    else
                        warndlg('Error! Data Dimensionality does not match!  Please choose again.');
                        pause(2.0);
                    end
                    
                case 'No'
                    nChoose = false;
                    disp('Import Complete.');
                    disp('*********************************************************************');
            end
            
        end
        
    end

end

%%
function openSelection()

    global nChannels zSlice chOptions xyRes zRes nOptions nPlanes
    
    
    zSlice = 1;
    chOptions = [];
    
    openFig = figure(1);
    set(gcf,'NumberTitle','off')
    set(gcf,'Name','CHANNEL SETUP')
    clf;
    set(gcf, 'Position',  [100, 100, 800, 400]);
    set(gcf, 'Resize', 'off');
    annotation('textbox', [0.05, 0.85, 0.6, 0.08], 'string', 'CHOOSE CORRECT CHANNELS',...
                'FontSize',20, 'FontWeight', 'bold',  'EdgeColor', 'none');
    pan1 = uibuttongroup('Title','Green Channel','FontSize',14,...
                 'BackgroundColor',[0.6,1,0.6],'FontWeight', 'bold',...
                 'Position',[0.04 0.3 .22 .5]);
    pan2 = uibuttongroup('Title','Red Channel','FontSize',14,...
                 'BackgroundColor',[1,0.5,0.5],'FontWeight', 'bold',...
                 'Position',[0.275 0.3 .22 .5]);
    pan3 = uibuttongroup('Title','Far Red Channel','FontSize',14,...
                 'BackgroundColor',[0.8,0.3,0.8],'FontWeight', 'bold',...
                 'Position',[0.51 0.3 .22 .5]);
    pan4 = uibuttongroup('Title','Blue Channel','FontSize',14,...
                 'BackgroundColor',[0.6,0.6,1],'FontWeight', 'bold',...
                 'Position',[0.745 0.3 .22 .5]);
    uicontrol('Parent', openFig, 'Style', 'pushbutton', 'Position', [600,30,150, 50],...
                      'FontSize',16, 'String', 'CHOOSE', 'Callback', {@setScaling});
                  
    % Green Channel Button Group %
    if nChannels ~= 4
        uicontrol(pan1,'Style','Radio','String','None','FontSize',12,...
            'pos',[10 140 100 30], 'BackgroundColor',[0.6,1,0.6]);
    end
    if (nChannels >= 1) 
        uicontrol(pan1,'Style','Radio','String','Channel 1','FontSize',12,...
            'pos',[10 110 100 30], 'BackgroundColor',[0.6,1,0.6]);
    end

    if (nChannels >= 2) 
        uicontrol(pan1,'Style','Radio','String','Channel 2','FontSize',12,...
            'pos',[10 80 100 30], 'BackgroundColor',[0.6,1,0.6]);
    end
    if (nChannels >= 3) 
        uicontrol(pan1,'Style','Radio','String','Channel 3','FontSize',12,...
            'pos',[10 50 100 30], 'BackgroundColor',[0.6,1,0.6]);
    end
    if (nChannels >= 4) 
        uicontrol(pan1,'Style','Radio','String','Channel 4','FontSize',12,...
            'pos',[10 20 100 30], 'BackgroundColor',[0.6,1,0.6]);
    end

    % Red Channel Button Group %
    if nChannels ~= 4
        uicontrol(pan2,'Style','Radio','String','None','FontSize',12,...
            'pos',[10 140 100 30], 'BackgroundColor',[1,0.5,0.5]);
    end
    if (nChannels >= 1) 
        uicontrol(pan2,'Style','Radio','String','Channel 1','FontSize',12,...
            'pos',[10 110 100 30], 'BackgroundColor',[1,0.5,0.5]);
    end

    if (nChannels >= 2) 
        uicontrol(pan2,'Style','Radio','String','Channel 2','FontSize',12,...
            'pos',[10 80 100 30], 'BackgroundColor',[1,0.5,0.5]);
    end
    if (nChannels >= 3) 
        uicontrol(pan2,'Style','Radio','String','Channel 3','FontSize',12,...
            'pos',[10 50 100 30], 'BackgroundColor',[1,0.5,0.5]);
    end
    if (nChannels >= 4) 
        uicontrol(pan2,'Style','Radio','String','Channel 4','FontSize',12,...
            'pos',[10 20 100 30], 'BackgroundColor',[1,0.5,0.5]);
    end

    % Far Red Channel Button Group %
    if nChannels ~= 4
        uicontrol(pan3,'Style','Radio','String','None','FontSize',12,...
            'pos',[10 140 100 30], 'BackgroundColor',[0.8,0.3,0.8]);
    end
    if (nChannels >= 1) 
        uicontrol(pan3,'Style','Radio','String','Channel 1','FontSize',12,...
            'pos',[10 110 100 30], 'BackgroundColor',[0.8,0.3,0.8]);
    end

    if (nChannels >= 2) 
        uicontrol(pan3,'Style','Radio','String','Channel 2','FontSize',12,...
            'pos',[10 80 100 30], 'BackgroundColor',[0.8,0.3,0.8]);
    end
    if (nChannels >= 3) 
        uicontrol(pan3,'Style','Radio','String','Channel 3','FontSize',12,...
            'pos',[10 50 100 30], 'BackgroundColor',[0.8,0.3,0.8]);
    end
    if (nChannels >= 4) 
        uicontrol(pan3,'Style','Radio','String','Channel 4','FontSize',12,...
            'pos',[10 20 100 30], 'BackgroundColor',[0.8,0.3,0.8]);
    end

    % Blue Channel Button Group %
    if nChannels ~= 4
        uicontrol(pan4,'Style','Radio','String','None','FontSize',12,...
            'pos',[10 140 100 30], 'BackgroundColor',[0.6,0.6,1]);
    end
    if (nChannels >= 1)
        uicontrol(pan4,'Style','Radio','String','Channel 1','FontSize',12,...
            'pos',[10 110 100 30], 'BackgroundColor',[0.6,0.6,1]);
    end

    if (nChannels >= 2) 
        uicontrol(pan4,'Style','Radio','String','Channel 2','FontSize',12,...
            'pos',[10 80 100 30], 'BackgroundColor',[0.6,0.6,1]);
    end
    if (nChannels >= 3) 
        uicontrol(pan4,'Style','Radio','String','Channel 3','FontSize',12,...
            'pos',[10 50 100 30], 'BackgroundColor',[0.6,0.6,1]);
    end
    if (nChannels >= 4) 
        uicontrol(pan4,'Style','Radio','String','Channel 4','FontSize',12,...
            'pos',[10 20 100 30], 'BackgroundColor',[0.6,0.6,1]);
    end

    annotation('textbox', [0.06, 0.22, 0.4, 0.02], 'string', 'XY Scale', 'FontSize', 14, 'fontweight', 'bold', 'EdgeColor', 'none');
    annotation('textbox', [0.22, 0.13, 0.4, 0.02], 'string', 'um/pxl', 'FontSize', 12,  'EdgeColor', 'none');
    xyField = uicontrol(openFig,'Style','edit','String',num2str(xyRes),'FontSize',14,...
            'pos',[50 40 120 30], 'BackgroundColor',[1,1,1]);

    annotation('textbox', [0.38, 0.22, 0.4, 0.02], 'string', 'Z Scale', 'FontSize', 14, 'fontweight', 'bold', 'EdgeColor', 'none');
    annotation('textbox', [0.55, 0.13, 0.4, 0.02], 'string', 'um/pxl', 'FontSize', 12,  'EdgeColor', 'none');
    
    if nPlanes > 1
        zField = uicontrol(openFig,'Style','edit','String',num2str(zRes),'FontSize',14,...
                'pos',[300 40 120 30], 'BackgroundColor',[1,1,1]);
    else
        zField = uicontrol(openFig,'Style','edit','String',num2str(zRes),'FontSize',14,...
                'pos',[300 40 120 30], 'BackgroundColor',[1,1,1], 'enable', 'off');
    end        

    function setScaling(~,~)     
        
        gOpt = get(get(pan1,'SelectedObject'), 'String');
        rOpt = get(get(pan2,'SelectedObject'), 'String');
        frOpt = get(get(pan3,'SelectedObject'), 'String');
        bOpt = get(get(pan4,'SelectedObject'), 'String');
        xyText = get(xyField, 'String');
        zText = get(zField, 'String');
        
        chOptions = {gOpt rOpt frOpt bOpt};

        for c = 1:4
            testChannel = regexp(chOptions{c}, '\d*', 'Match');
            try
                nOptions(c) = str2num(testChannel{1});
            catch
                nOptions(c) = 0;
            end
        end
        
        if ((length(chOptions) - sum(ismember(chOptions, 'None'))) ~= nChannels) && (nChannels < 4)
            warndlg('Error: Choose proper channels.');
            return;
        elseif (length(chOptions) ~= length(unique(chOptions))) && (nChannels == 4)
            warndlg('Error: Choose proper channels.');
            return;
        end
        if isempty(str2double(xyText)) || isnan(str2double(xyText)) || isempty(str2double(zText)) || isnan(str2double(zText)) && (nPlanes > 1)
            warndlg('Error: Please enter proper scaling values!');
            set(xyField,'string','0.064');
            if nPlanes > 1
                set(zField,'string','0.2');
            else
                set(zField, 'string', 'N/A');
            end
            return;
        end
        if ~isempty(str2double(xyText)) && ~isempty(str2double(zText)) && ((length(chOptions) - sum(ismember(chOptions, 'None'))) == nChannels)
            xyRes = str2double(xyText);
            if nPlanes > 1
                zRes = str2double(zText);
            else
                zRes = 0.2;
            end
            disp(strcat('XY Scaling Set: ', num2str(xyRes)));
            disp(strcat('Z Scaling Set: ', num2str(zRes)));
            disp('.');
            disp(strcat('Green Channel: **', gOpt));
            disp(strcat('Red Channel: **', rOpt));
            disp(strcat('Far Red Channel: **', frOpt));
            disp(strcat('Blue Channel: **', bOpt));
            disp('........................................');
            close all;
            openMainUI();
        end
        
    end
    
end

%%
function openMainUI()

    global  currentChannel channel1 channel2 channel3 channel4 mainFig...
            currentChN zSlice nPlanes nChannels imgSize currentIMG...
            zoomObj viewFigSize thTrue caCalTrue bgPixel modeChoice...
            g2DOpt g3DOpt bgOpt caOpt chOptions excludeOverlap overlapOpt...
            overlapThreshold finalFitParams excludeSize sizeOpt sizeLower...
            sizeUpper sizeL sizeU currentBB nOptions finalFit488...
            finalBB488 finalFit594 finalBB594 finalFit640 finalBB640...
            finalFit405 finalBB405 currentPts multiThresholds...
            multiSizeCentroids multiBBCentroids multiPxlCentroids...
            multiTrueCentroids saveCheck gaussFitted msgbx...
            figWidthFactor finalCentroids488 finalCentroids594...
            finalCentroids640 finalCentroids405 h anno...
            caSurfaceOpt caAffineOpt affineRG affineFRG affineBG...
            affineFRR affineBR affineBFR surfX_GR surfY_GR surfZ_GR...
            surfX_GFR surfY_GFR surfZ_GFR surfX_GB surfY_GB surfZ_GB...
            surfX_RFR surfY_RFR surfZ_RFR surfX_RB surfY_RB surfZ_RB...
            surfX_FRB surfY_FRB surfZ_FRB caPlot redSurfCalTrue...
            redAffineCalTrue farRedSurfCalTrue farRedAffineCalTrue...
            blueSurfCalTrue blueAffineCalTrue
        
    currentChN = 1;
    currentChannel = channel1;

    redSurfCalTrue = false;
    redAffineCalTrue = false;
    farRedSurfCalTrue = false;
    farRedAffineCalTrue = false;
    blueSurfCalTrue = false;
    blueAffineCalTrue = false;
    
    channel1 = double(channel1);
    channel2 = double(channel2);
    channel3 = double(channel3);
    channel4 = double(channel4);
    
    % Set Current Z Slice %
    if length(size(currentChannel)) == 3
        zSlice = floor(nPlanes/2);
    elseif length(size(currentChannel)) == 2
        zSlice = 1;
    end

    thTrue = false;
    caCalTrue = false;
    modeChoice = [];
    
    if isempty(chOptions)
        warndlg('Please Set Proper Channels!');
        close all;
        pause(1.5);
        openSelection();
        return;
    end
    
    mainFig = figure(1);
    viewFigSize = [1.5*(imgSize(2)/imgSize(1))*figWidthFactor, 800];
    set(gcf,'NumberTitle','off'); set(gcf,'Name','MAIN UI');
    clf;
    set(gcf, 'Position',  [100, 100, 1.5*(imgSize(2)/imgSize(1))*figWidthFactor, 800]);
    set(gcf, 'Resize', 'off');
    ax = axes('Parent', mainFig, 'Position', [0.1 0.1 0.8 0.8]);
    currentIMG = imshow(currentChannel(:,:,zSlice), [], 'InitialMagnification', 450);
    addToolbarExplorationButtons(mainFig);
    hold on;
    
    modeOptions = uicontrol('Parent', mainFig,'Style','popupmenu','Position',[viewFigSize(1)*0.81, viewFigSize(2)*0.94,200,20],...
            'String', {'Choose Option', 'Particle Analysis', 'Protein Quantification'...
            , 'Chromatic Aberration Calibration'
            },'FontSize',14,'Callback', {@modeChosen});
    
    % Slider Section
    if nPlanes > 1
        h = uicontrol('Parent', mainFig,'Style','slider','Position',[viewFigSize(1)*0.775, viewFigSize(2)*0.11,20,600],...
            'SliderStep', [1/(nPlanes-1) , 10/(nPlanes-1) ],...
            'value',zSlice, 'min', 1, 'max',nPlanes, 'Callback', {@updateMainIMG});
        anno = annotation('textbox', [0.77, 0.875, 0.025, 0.025], 'string', num2str(zSlice),'FontSize',7.5);
    end

    
    
    % Switching Channels Buttons %
    if (nChannels >= 1) && (~isempty(channel1))
        a = uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.24, viewFigSize(2)*0.905, 100, 30],...
            'String', 'CHANNEL 1', 'FontSize', 12, 'Callback', {@chooseCh1});
    end
    if (nChannels >= 2) && (~isempty(channel2))
        b = uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.33, viewFigSize(2)*0.905, 100, 30],...
            'String', 'CHANNEL 2', 'FontSize', 12, 'Callback', {@chooseCh2});
    end
    if (nChannels >= 3) && (~isempty(channel3))
        c = uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.42, viewFigSize(2)*0.905, 100, 30],...
            'String', 'CHANNEL 3', 'FontSize', 12, 'Callback', {@chooseCh3});
    end
    if (nChannels >= 4) && (~isempty(channel4))
        d = uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.51, viewFigSize(2)*0.905, 100, 30],...
            'String', 'CHANNEL 4', 'FontSize', 12, 'Callback', {@chooseCh4});
    end
    
    % Reset View Button
    uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.74, viewFigSize(2)*0.07, 65, 20],...
            'String', 'RESET VIEW', 'FontSize', 7, 'BackgroundColor',[1,0.6,0.6], 'Callback', {@resetZoom});
    % Contrast Button
    uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.205, viewFigSize(2)*0.07, 65, 20],...
            'String', 'CONTRAST', 'FontSize', 7, 'BackgroundColor',[0.7,0.7,1], 'Callback', {@adjustContrast});
    
    % Left Side Buttons
    uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.03, viewFigSize(2)*0.93,140, 35],...
        'String', 'Open File', 'BackgroundColor',[0.8,1,0.8],'FontSize', 12, 'Callback', {@chooseNewFile});
    uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.03, viewFigSize(2)*0.87,140, 35],...
        'String', 'Import Data', 'BackgroundColor',[0.8,0.8,1], 'FontSize', 12, 'Callback', {@importData});
    uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.03, viewFigSize(2)*0.81,140, 35],...
        'String', 'Import CA Calibration', 'BackgroundColor',[1,0.7,0.7], 'FontSize', 10, 'Callback', {@importCAcal});
    
    
    function modeChosen(modeOptions, ~)
        
        modeChoice = get(modeOptions, 'Value');
        if modeChoice == 1
            mainModeSetup();
            warndlg('Please Choose Mode of Analysis!');
        end
        if modeChoice == 2
            mainModeSetup();
            particleAnalysisSetup();
        end
        if modeChoice == 3
            mainModeSetup();
            warndlg('Error: Currently unavailable.  Please choose another option.');
%             particleAnalysisSetup();
        end
        if modeChoice == 4
            mainModeSetup();
            caCalibrationSetup();
        end
        
    end

    function caCalibrationSetup()
        
        uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.825, viewFigSize(2)*0.83,150, 35],...
            'String', 'Generate Calibration', 'BackgroundColor',[1,0.7,0.4], 'FontSize', 11, 'Callback', {@generateCACalibration});
        uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.825, viewFigSize(2)*0.1,150, 35],...
            'String', 'Save Calibration', 'BackgroundColor',[0.8,1,0.8], 'FontSize', 11, 'Callback', {@exportCACalibration});
        
        % Right Side Panel %
        caPan = uibuttongroup('Title','Calibration Options','FontSize',8,...
                     'BackgroundColor',[1,1,1],'FontWeight', 'bold',...
                     'Position',[0.815 0.64 .15 .15]);
        surfaceOpt = uicontrol(caPan,'Style','Checkbox','String','  Polynomial Surface','FontSize',9,...
                'pos',[15 72 200 30],'BackgroundColor', [1,1,1]);    
        affineOpt = uicontrol(caPan,'Style','Checkbox','String','  Affine Transform','FontSize',9,...
                'pos',[15 50 200 30],'BackgroundColor',[1,1,1]);
            
        % Left Side Instructions %
        annotation('textbox', [0.015, 0.65, 0.1, 0.1], 'string', 'Chromatic Aberration Calibration', 'FontSize', 11, 'fontweight', 'bold', 'EdgeColor', 'none', 'Color', [0, 0, 0]);
        
        annotation('textbox', [0.025, 0.64, 0.25, 0.05], 'string', '- Choose folder of analyzed bead', 'FontSize', 10, 'fontweight', 'bold', 'EdgeColor', 'none');
        annotation('textbox', [0.025, 0.62, 0.25, 0.05], 'string', '  3D-Speckler output excel files.', 'FontSize', 10, 'fontweight', 'bold', 'EdgeColor', 'none');
        
        annotation('textbox', [0.025, 0.57, 0.25, 0.05], 'string', '- Use 100 nm or 200 nm beads for', 'FontSize', 10, 'fontweight', 'bold', 'EdgeColor', 'none');
        annotation('textbox', [0.025, 0.55, 0.25, 0.05], 'string', '  most optimal results.', 'FontSize', 10, 'fontweight', 'bold', 'EdgeColor', 'none');
        
        annotation('textbox', [0.025, 0.50, 0.25, 0.05], 'string', '- Ensure a minimum of 200 beads', 'FontSize', 10, 'fontweight', 'bold', 'EdgeColor', 'none');
        annotation('textbox', [0.025, 0.48, 0.25, 0.05], 'string', '  across field of view for most', 'FontSize', 10, 'fontweight', 'bold', 'EdgeColor', 'none');
        annotation('textbox', [0.025, 0.46, 0.25, 0.05], 'string', '  optimal results.', 'FontSize', 10, 'fontweight', 'bold', 'EdgeColor', 'none');
        
        annotation('textbox', [0.025, 0.41, 0.25, 0.05], 'string', '- Please import CA calibration', 'FontSize', 10, 'fontweight', 'bold', 'EdgeColor', 'none');
        annotation('textbox', [0.025, 0.39, 0.25, 0.05], 'string', '  first before any analysis when', 'FontSize', 10, 'fontweight', 'bold', 'EdgeColor', 'none');
        annotation('textbox', [0.025, 0.37, 0.25, 0.05], 'string', '  using CA calibration.', 'FontSize', 10, 'fontweight', 'bold', 'EdgeColor', 'none'); 
        
        function generateCACalibration(~,~)
            
            caSurfaceOpt = get(surfaceOpt, 'Value');
            caAffineOpt = get(affineOpt, 'Value');
            
            % If No Fitting Options Chosen
            if (caSurfaceOpt == 0) && (caAffineOpt == 0)
                warndlg('Error: No Calibration Options Chosen!');
                return;
            end
            
            % Import All Data %
            dirPath = uigetdir();
            fileList = dir(fullfile(dirPath,'*.xlsx'));
            
            disp('Folder Selected:');
            disp(dirPath);
            
            disp(strcat('Number of Files Detected: ', num2str(size(fileList,1))));
            if size(fileList,1) == 0
                disp('No files detected.  No data imported.')
                disp('.');
                disp('*********************************************************************');
                return;
            end
            disp('.');
            disp('*********************************************************************');

            if caSurfaceOpt == 1
                answer = questdlg('Would you like to view fitted polynomial calibration surfaces?', ...
                    'Visualize Surface Fits', ...
                    'Yes','No','Cancel','Yes');
                % Handle response
                switch answer
                    case 'Yes'
                        caPlot = 1;
                    case 'No'
                        caPlot = 0;
                    case 'Cancel'
                        disp('Calibration Data Import Discontinued.')
                        return;
                end
            end

            gPos = [];
            rPos = [];
            frPos = [];
            bPos = [];
            abbGR = [];
            abbGFR = [];
            abbGB = [];
            abbRFR = [];
            abbRB =[];
            abbFRB =[];
            
            disp('Importing Data for Calibration.');
            disp('... ... ... ...');
            for j = 1:size(fileList,1)
                file = fullfile(dirPath, fileList(j).name);
                workSheets = sheetnames(file);
                
                green = [];
                red = [];
                farRed = [];
                blue = [];
                abbGreenRed = [];
                abbGreenFarRed = [];
                abbGreenBlue = [];
                abbRedFarRed = [];
                abbRedBlue = [];
                abbFarRedBlue = [];
                
                for i = 1:size(workSheets,1)
                    if  strcmp("3D_Green",workSheets(i,1))
                        green = readtable(file,'Sheet',i,'Range','A:C');
                    elseif  strcmp("2D_Green",workSheets(i,1))
                        green = readtable(file,'Sheet',i,'Range','A:B');
                    end
                end
                
                for i = 1:size(workSheets,1)
                    if  strcmp("3D_Red",workSheets(i,1))
                        red = readtable(file,'Sheet',i,'Range','A:C');
                    elseif  strcmp("2D_Red",workSheets(i,1))
                        red = readtable(file,'Sheet',i,'Range','A:B');
                    end
                end
                
                for i = 1:size(workSheets,1)
                    if  strcmp("3D_FarRed",workSheets(i,1))
                        farRed = readtable(file,'Sheet',i,'Range','A:C');
                    elseif  strcmp("2D_FarRed",workSheets(i,1))
                        farRed = readtable(file,'Sheet',i,'Range','A:B');
                    end
                end
                
                for i = 1:size(workSheets,1)
                    if  strcmp("3D_Blue",workSheets(i,1))
                        blue = readtable(file,'Sheet',i,'Range','A:C');
                    elseif  strcmp("2D_Blue",workSheets(i,1))
                        blue = readtable(file,'Sheet',i,'Range','A:B');
                    end
                end
                
                for i = 1:size(workSheets,1)
                    if  strcmp("aberration_Green_Red",workSheets(i,1)) && (size(green,2) == 3) && (size(red,2) == 3)
                        abbGreenRed = readtable(file,'Sheet',i,'Range','A:C');
                    elseif  strcmp("aberration_Green_Red",workSheets(i,1)) && (size(green,2) == 2) && (size(red,2) == 2)
                        abbGreenRed = readtable(file,'Sheet',i,'Range','A:B');
                    end
                end
                
                for i = 1:size(workSheets,1)
                    if  strcmp("aberration_Green_FarRed",workSheets(i,1)) && (size(green,2) == 3) && (size(farRed,2) == 3)
                        abbGreenFarRed = readtable(file,'Sheet',i,'Range','A:C');
                    elseif  strcmp("aberration_Green_FarRed",workSheets(i,1)) && (size(green,2) == 2) && (size(farRed,2) == 2)
                        abbGreenFarRed = readtable(file,'Sheet',i,'Range','A:B');
                    end
                end
                
                for i = 1:size(workSheets,1)
                    if  strcmp("aberration_Green_Blue",workSheets(i,1)) && (size(green,2) == 3) && (size(blue,2) == 3)
                        abbGreenBlue = readtable(file,'Sheet',i,'Range','A:C');
                    elseif  strcmp("aberration_Green_Blue",workSheets(i,1)) && (size(green,2) == 2) && (size(blue,2) == 2)
                        abbGreenBlue = readtable(file,'Sheet',i,'Range','A:B');
                    end
                end
                
                for i = 1:size(workSheets,1)
                    if  strcmp("aberration_Red_FarRed",workSheets(i,1)) && (size(red,2) == 3) && (size(farRed,2) == 3)
                        abbRedFarRed = readtable(file,'Sheet',i,'Range','A:C');
                    elseif  strcmp("aberration_Red_FarRed",workSheets(i,1)) && (size(red,2) == 2) && (size(farRed,2) == 2)
                        abbRedFarRed = readtable(file,'Sheet',i,'Range','A:B');
                    end
                end
                
                for i = 1:size(workSheets,1)
                    if  strcmp("aberration_Red_Blue",workSheets(i,1)) && (size(red,2) == 3) && (size(blue,2) == 3)
                        abbRedBlue = readtable(file,'Sheet',i,'Range','A:C');
                    elseif  strcmp("aberration_Red_Blue",workSheets(i,1)) && (size(red,2) == 2) && (size(blue,2) == 2)
                        abbRedBlue = readtable(file,'Sheet',i,'Range','A:B');
                    end
                end
                
                for i = 1:size(workSheets,1)
                    if  strcmp("aberration_FarRed_Blue",workSheets(i,1)) && (size(farRed,2) == 3) && (size(blue,2) == 3)
                        abbFarRedBlue = readtable(file,'Sheet',i,'Range','A:C');
                    elseif  strcmp("aberration_FarRed_Blue",workSheets(i,1)) && (size(farRed,2) == 2) && (size(blue,2) == 2)
                        abbFarRedBlue = readtable(file,'Sheet',i,'Range','A:B');
                    end
                end
                
                if ~isempty(green)
                    gPos = [gPos; green];
                end
                if ~isempty(red)
                    rPos = [rPos; red];
                end
                if ~isempty(farRed)
                    frPos = [frPos; farRed];
                end
                if ~isempty(blue)
                    bPos = [bPos; blue];
                end
                if ~isempty(abbGreenRed)
                    abbGR = [abbGR; abbGreenRed];
                end
                if ~isempty(abbGreenFarRed)
                    abbGFR = [abbGFR; abbGreenFarRed];
                end
                if ~isempty(abbGreenBlue)
                    abbGB = [abbGB; abbGreenBlue];
                end
                if ~isempty(abbRedFarRed)
                    abbRFR = [abbRFR; abbRedFarRed];
                end
                if ~isempty(abbRedBlue)
                    abbRB = [abbRB; abbRedBlue];
                end
                if ~isempty(abbFarRedBlue)
                    abbFRB = [abbFRB; abbFarRedBlue];
                end
                
            end
            
            
            vecCheck = [~isempty(gPos) ~isempty(rPos) ~isempty(frPos) ~isempty(bPos)];
            disp('Data Import Complete.');
            disp(strcat('Number of Channels Detected:', num2str(sum(vecCheck))));
            disp('***********************************************');
            
            % Generate CA Calibrations %
                
            if sum(vecCheck) == 4
                
                if caSurfaceOpt == 1
                    if (size(gPos,2) == 3) && (size(rPos,2) == 3) && (size(frPos,2) == 3) && (size(bPos,2) == 3)
                        disp('Generating XYZ Surface Calibration for:');
                        disp('- Green to Red');
                        disp('- Green to Far Red');
                        disp('- Green to Blue');
                        [surfX_GR, surfY_GR, surfZ_GR] = getCASurface3D(rPos,abbGR,caPlot);
                        [surfX_GFR, surfY_GFR, surfZ_GFR] = getCASurface3D(frPos,abbGFR,caPlot);
                        [surfX_GB, surfY_GB, surfZ_GB] = getCASurface3D(bPos,abbGB,caPlot);
                    elseif (size(gPos,2) == 2) && (size(rPos,2) == 2) && (size(frPos,2) == 2) && (size(bPos,2) == 2)
                        disp('Generating XY Surface Calibration for:');
                        disp('- Green to Red');
                        disp('- Green to Far Red');
                        disp('- Green to Blue');
                        [surfX_GR, surfY_GR] = getCASurface2D(rPos,abbGR,caPlot);
                        [surfX_GFR, surfY_GFR] = getCASurface2D(frPos,abbGFR,caPlot);
                        [surfX_GB, surfY_GB] = getCASurface2D(bPos,abbGB,caPlot);
                    end
                    disp('.');
                    disp('Calibration Surfaces Successfully Generated.');
                    disp('***********************************************');
                end
                if caAffineOpt == 1
                    disp('Generating Geometric Affine Transform for:');
                    disp('- Green to Red');
                    disp('- Green to Far Red');
                    disp('- Green to Blue');
                    [affineRG] = getAffineTransform(rPos, gPos);
                    [affineFRG] = getAffineTransform(frPos, gPos);
                    [affineBG] = getAffineTransform(bPos, gPos);
                    disp('.');
                    disp('Affine Transform Calibration Successfully Generated.');
                    disp('***********************************************');
                end
                
            elseif sum(vecCheck) == 3
                
                if (vecCheck(1) == 1) && (vecCheck(2) == 1) && (vecCheck(3) == 1)
                    if caSurfaceOpt == 1
                        if (size(gPos,2) == 3) && (size(rPos,2) == 3) && (size(frPos,2) == 3)
                            disp('Generating XYZ Surface Calibration for:');
                            disp('- Green to Red');
                            disp('- Green to Far Red');
                            [surfX_GR, surfY_GR, surfZ_GR] = getCASurface3D(rPos,abbGR,caPlot);
                            [surfX_GFR, surfY_GFR, surfZ_GFR] = getCASurface3D(frPos,abbGFR,caPlot);
                        elseif (size(gPos,2) == 2) && (size(rPos,2) == 2) && (size(frPos,2) == 2)
                            disp('Generating XY Surface Calibration for:');
                            disp('- Green to Red');
                            disp('- Green to Far Red');
                            [surfX_GR, surfY_GR] = getCASurface2D(rPos,abbGR,caPlot);
                            [surfX_GFR, surfY_GFR] = getCASurface2D(frPos,abbGFR,caPlot);
                        end
                        disp('.');
                        disp('Calibration Surfaces Successfully Generated.');
                        disp('***********************************************');
                    end
                    if caAffineOpt == 1
                        disp('Generating Geometric Affine Transform for:');
                        disp('- Green to Red');
                        disp('- Green to Far Red');
                        [affineRG] = getAffineTransform(rPos, gPos);
                        [affineFRG] = getAffineTransform(frPos, gPos);
                        disp('.');
                        disp('Affine Transform Calibration Successfully Generated.');
                        disp('***********************************************');
                    end
                elseif (vecCheck(2) == 1) && (vecCheck(3) == 1) && (vecCheck(4) == 1)
                    if caSurfaceOpt == 1
                        if (size(rPos,2) == 3) && (size(frPos,2) == 3) && (size(bPos,2) == 3)
                            disp('Generating XYZ Surface Calibration for:');
                            disp('- Red to Far Red');
                            disp('- Red to Blue');
                            [surfX_RFR, surfY_RFR, surfZ_RFR] = getCASurface3D(frPos,abbRFR,caPlot);
                            [surfX_RB, surfY_RB, surfZ_RB] = getCASurface3D(bPos,abbRB,caPlot);
                        elseif (size(rPos,2) == 2) && (size(frPos,2) == 2) && (size(bPos,2) == 2)
                            disp('Generating XY Surface Calibration for:');
                            disp('- Red to Far Red');
                            disp('- Red to Blue');
                            [surfX_RFR, surfY_RFR] = getCASurface2D(frPos,abbRFR,caPlot);
                            [surfX_RB, surfY_RB] = getCASurface2D(bPos,abbRB,caPlot);
                        end
                        disp('.');
                        disp('Calibration Surfaces Successfully Generated.');
                        disp('***********************************************');
                    end
                    if caAffineOpt == 1
                        disp('Generating Geometric Affine Transform for:');
                        disp('- Red To Far Red');
                        disp('- Red To Blue');
                        [affineFRR] = getAffineTransform(frPos, rPos);
                        [affineBR] = getAffineTransform(bPos, rPos);
                        disp('.');
                        disp('Affine Transform Calibration Successfully Generated.');
                        disp('***********************************************');
                    end
                elseif (vecCheck(1) == 1) && (vecCheck(3) == 1) && (vecCheck(4) == 1)
                    if caSurfaceOpt == 1
                        if (size(gPos,2) == 3) && (size(frPos,2) == 3) && (size(bPos,2) == 3)
                            disp('Generating XYZ Surface Calibration for:');
                            disp('- Green to Far Red');
                            disp('- Green to Blue');
                            [surfX_GFR, surfY_GFR, surfZ_GFR] = getCASurface3D(frPos,abbGFR,caPlot);
                            [surfX_GB, surfY_GB, surfZ_GB] = getCASurface3D(bPos,abbGB,caPlot);
                        elseif (size(gPos,2) == 2) && (size(frPos,2) == 2) && (size(bPos,2) == 2)
                            disp('Generating XY Surface Calibration for:');
                            disp('- Green to Far Red');
                            disp('- Green to Blue');
                            [surfX_GFR, surfY_GFR] = getCASurface2D(frPos,abbGFR,caPlot);
                            [surfX_GB, surfY_GB] = getCASurface2D(bPos,abbGB,caPlot);
                        end
                        disp('.');
                        disp('Calibration Surfaces Successfully Generated.');
                        disp('***********************************************');
                    end
                    if caAffineOpt == 1
                        disp('Generating Geometric Affine Transform for:');
                        disp('- Green to Far Red');
                        disp('- Green to Blue');
                        [affineFRG] = getAffineTransform(frPos, gPos);
                        [affineBG] = getAffineTransform(bPos, gPos);
                        disp('.');
                        disp('Affine Transform Calibration Successfully Generated.');
                        disp('***********************************************');
                    end
                elseif (vecCheck(1) == 1) && (vecCheck(2) == 1) && (vecCheck(4) == 1)
                    if caSurfaceOpt == 1
                        if (size(gPos,2) == 3) && (size(rPos,2) == 3) && (size(bPos,2) == 3)
                            disp('Generating XYZ Surface Calibration for:');
                            disp('- Green to Red');
                            disp('- Green to Blue');
                            [surfX_GR, surfY_GR, surfZ_GR] = getCASurface3D(rPos,abbGR,caPlot);
                            [surfX_GB, surfY_GB, surfZ_GB] = getCASurface3D(bPos,abbGB,caPlot);
                        elseif (size(gPos,2) == 2) && (size(rPos,2) == 2) && (size(bPos,2) == 2)
                            disp('Generating XY Surface Calibration for:');
                            disp('- Green to Red');
                            disp('- Green to Blue');
                            [surfX_GR, surfY_GR] = getCASurface2D(rPos,abbGR,caPlot);
                            [surfX_GB, surfY_GB] = getCASurface2D(bPos,abbGB,caPlot);
                        end
                        disp('.');
                        disp('Calibration Surfaces Successfully Generated.');
                        disp('***********************************************');
                    end
                    if caAffineOpt == 1
                        disp('Generating Geometric Affine Transform for:');
                        disp('- Green to Red');
                        disp('- Green to Blue');
                        [affineRG] = getAffineTransform(rPos, gPos);
                        [affineBG] = getAffineTransform(bPos, gPos);
                        disp('.');
                        disp('Affine Transform Calibration Successfully Generated.');
                        disp('***********************************************');
                    end
                end
                
            elseif sum(vecCheck) == 2
                
                if (vecCheck(1) == 1) && (vecCheck(2) == 1)
                    if caSurfaceOpt == 1
                        if (size(gPos,2) == 3) && (size(rPos,2) == 3) 
                            disp('Generating XYZ Surface Calibration for:');
                            disp('- Green to Red');
                            [surfX_GR, surfY_GR, surfZ_GR] = getCASurface3D(rPos,abbGR,caPlot);
                        elseif (size(gPos,2) == 2) && (size(rPos,2) == 2) 
                            disp('Generating XY Surface Calibration for:');
                            disp('- Green to Red');
                            [surfX_GR, surfY_GR] = getCASurface2D(rPos,abbGR,caPlot);
                        end
                        disp('.');
                        disp('Calibration Surfaces Successfully Generated.');
                        disp('***********************************************');
                    end
                    if caAffineOpt == 1
                        disp('Generating Geometric Affine Transform for:');
                        disp('- Green to Red');
                        [affineRG] = getAffineTransform(rPos, gPos);
                        disp('.');
                        disp('Affine Transform Calibration Successfully Generated.');
                        disp('***********************************************');
                    end
                elseif (vecCheck(1) == 1) && (vecCheck(3) == 1)
                    if caSurfaceOpt == 1
                        if (size(gPos,2) == 3) && (size(frPos,2) == 3) 
                            disp('Generating XYZ Surface Calibration for:');
                            disp('- Green to Far Red');
                            [surfX_GFR, surfY_GFR, surfZ_GFR] = getCASurface3D(frPos,abbGFR,caPlot);
                        elseif (size(gPos,2) == 2) && (size(frPos,2) == 2)
                            disp('Generating XY Surface Calibration for:');
                            disp('- Green to Far Red');
                            [surfX_GFR, surfY_GFR] = getCASurface2D(frPos,abbGFR,caPlot);
                        end
                        disp('.');
                        disp('Calibration Surfaces Successfully Generated.');
                        disp('***********************************************');
                    end
                    if caAffineOpt == 1
                        disp('Generating Geometric Affine Transform for:');
                        disp('- Green to Far Red');
                        [affineFRG] = getAffineTransform(frPos, gPos);
                        disp('.');
                        disp('Affine Transform Calibration Successfully Generated.');
                        disp('***********************************************');
                    end
                elseif (vecCheck(1) == 1) && (vecCheck(4) == 1)
                    if caSurfaceOpt == 1
                        if (size(gPos,2) == 3) && (size(bPos,2) == 3)
                            disp('Generating XYZ Surface Calibration for:');
                            disp('- Green to Blue');
                            [surfX_GB, surfY_GB, surfZ_GB] = getCASurface3D(bPos,abbGB,caPlot);
                        elseif (size(gPos,2) == 2) && (size(bPos,2) == 2)
                            disp('Generating XY Surface Calibration for:');
                            disp('- Green to Blue');
                            [surfX_GB, surfY_GB] = getCASurface2D(bPos,abbGB,caPlot);
                        end
                        disp('.');
                        disp('Calibration Surfaces Successfully Generated.');
                        disp('***********************************************');
                    end
                    if caAffineOpt == 1
                        disp('Generating Geometric Affine Transform for:');
                        disp('- Green to Blue');
                        [affineBG] = getAffineTransform(bPos, gPos);
                        disp('.');
                        disp('Affine Transform Calibration Successfully Generated.');
                        disp('***********************************************');
                    end
                elseif (vecCheck(2) == 1) && (vecCheck(3) == 1)
                    if caSurfaceOpt == 1
                        if (size(rPos,2) == 3) && (size(frPos,2) == 3)
                            disp('Generating XYZ Surface Calibration for:');
                            disp('- Red to Far Red');
                            [surfX_RFR, surfY_RFR, surfZ_RFR] = getCASurface3D(frPos,abbRFR,caPlot);
                        elseif (size(rPos,2) == 2) && (size(frPos,2) == 2) 
                            disp('Generating XY Surface Calibration for:');
                            disp('- Red to Far Red');
                            [surfX_RFR, surfY_RFR] = getCASurface2D(frPos,abbRFR,caPlot);
                        end
                        disp('.');
                        disp('Calibration Surfaces Successfully Generated.');
                        disp('***********************************************');
                    end
                    if caAffineOpt == 1
                        disp('Generating Geometric Affine Transform for:');
                        disp('- Red to Far Red');
                        [affineFRR] = getAffineTransform(frPos, rPos);
                        disp('.');
                        disp('Affine Transform Calibration Successfully Generated.');
                        disp('***********************************************');
                    end
                elseif (vecCheck(2) == 1) && (vecCheck(4) == 1)
                    if caSurfaceOpt == 1
                        if (size(rPos,2) == 3) && (size(bPos,2) == 3)
                            disp('Generating XYZ Surface Calibration for:');
                            disp('- Red to Blue');
                            [surfX_RB, surfY_RB, surfZ_RB] = getCASurface3D(bPos,abbRB,caPlot);
                        elseif (size(rPos,2) == 2) && (size(bPos,2) == 2)
                            disp('Generating XY Surface Calibration for:');
                            disp('- Red to Blue');
                            [surfX_RB, surfY_RB] = getCASurface2D(bPos,abbRB,caPlot);
                        end
                        disp('.');
                        disp('Calibration Surfaces Successfully Generated.');
                        disp('***********************************************');
                    end
                    if caAffineOpt == 1
                        disp('Generating Geometric Affine Transform for:');
                        disp('- Red to Blue');
                        [affineBR] = getAffineTransform(bPos, rPos);
                        disp('.');
                        disp('Affine Transform Calibration Successfully Generated.');
                        disp('***********************************************');
                    end
                elseif (vecCheck(3) == 1) && (vecCheck(4) == 1)
                    if caSurfaceOpt == 1
                        if (size(frPos,2) == 3) && (size(bPos,2) == 3)
                            disp('Generating XYZ Surface Calibration for:');
                            disp('- Far Red to Blue');
                            [surfX_FRB, surfY_FRB, surfZ_FRB] = getCASurface3D(bPos,abbFRB,caPlot);
                        elseif (size(frPos,2) == 2) && (size(bPos,2) == 2)
                            disp('Generating XY Surface Calibration for:');
                            disp('- Far Red to Blue');
                            [surfX_FRB, surfY_FRB] = getCASurface2D(bPos,abbFRB,caPlot);
                        end
                        disp('.');
                        disp('Calibration Surfaces Successfully Generated.');
                        disp('***********************************************');
                    end
                    if caAffineOpt == 1
                        disp('Generating Geometric Affine Transform for:');
                        disp('- Far Red to Blue');
                        [affineBFR] = getAffineTransform(bPos, frPos);
                        disp('.');
                        disp('Affine Transform Calibration Successfully Generated.');
                        disp('***********************************************');
                    end
                end
                
            end
            
            function [transform] = getAffineTransform(pos2, pos1)
                
                newGPOS = table2array(pos1);
                newRPOS = table2array(pos2);
                
                if (size(newRPOS,2) == size(newGPOS,2)) && (size(newRPOS,2) == 3) && (size(newGPOS,2) == 3)
                    transform = estimateGeometricTransform3D(newRPOS,newGPOS,'similarity');
                elseif (size(newRPOS,2) == size(newGPOS,2)) && (size(newRPOS,2) == 2) && (size(newGPOS,2) == 2)
                    transform = estimateGeometricTransform2D(newRPOS,newGPOS,'similarity');
                end
                
            end
            
            function [fitSurfaceX, fitSurfaceY] = getCASurface2D(gPos,abbGR,plotTrue)
                
                xPositionGreen = table2array(gPos(:,"Gauss_X"));
                yPositionGreen = table2array(gPos(:,"Gauss_Y"));
                
                xAbbGreenRed = table2array(abbGR(:,"X_Aberration"));
                yAbbGreenRed = table2array(abbGR(:,"Y_Aberration"));
                
                % x y x-abb
                [fitSurfaceX,gofX] = fit([xPositionGreen,yPositionGreen],xAbbGreenRed, 'poly11');
                if plotTrue == 1
                    figure;
                    plot(fitSurfaceX,[xPositionGreen,yPositionGreen], xAbbGreenRed)
                    set(gca,'FontSize',20);
                    colormap("spring")
                    xlabel('X Position')
                    ylabel('Y Position')
                    zlabel('X abberation')
                    alpha(0.2)
                    gofX
                end
                
                % x y y-abb
                [fitSurfaceY,gofY] = fit([xPositionGreen,yPositionGreen],yAbbGreenRed, 'poly11');
                if plotTrue == 1
                    figure;
                    plot(fitSurfaceY,[xPositionGreen,yPositionGreen], yAbbGreenRed)
                    set(gca,'FontSize',20);
                    colormap("spring")
                    xlabel('X Position')
                    ylabel('Y Position')
                    zlabel('Y abberation')
                    alpha(0.2)
                    gofY
                end   
            end
            
            function [fitSurfaceX, fitSurfaceY, fitSurfaceZ] = getCASurface3D(gPos,abbGR,plotTrue)
                
                xPositionGreen = table2array(gPos(:,"Gauss_X"));
                yPositionGreen = table2array(gPos(:,"Gauss_Y"));
                zPositionGreen = table2array(gPos(:,"Gauss_Z"));
                
                xAbbGreenRed = table2array(abbGR(:,"X_Aberration"));
                yAbbGreenRed = table2array(abbGR(:,"Y_Aberration"));
                zAbbGreenRed = table2array(abbGR(:,"Z_Aberration"));
                
                % X Abb Surface
                [fitSurfaceX,gofX] = fit([xPositionGreen,yPositionGreen],xAbbGreenRed, 'poly11');
                if plotTrue == 1
                    figure;
                    plot(fitSurfaceX,[xPositionGreen,yPositionGreen], xAbbGreenRed)
                    set(gca,'FontSize',20);
                    colormap("spring")
                    xlabel('X Position')
                    ylabel('Y Position')
                    zlabel('X abberation')
                    alpha(0.2)
                    gofX
                end
                
                % Y Abb Surface
                [fitSurfaceY,gofY] = fit([xPositionGreen,yPositionGreen],yAbbGreenRed, 'poly11');
                if plotTrue == 1
                    figure;
                    plot(fitSurfaceY,[xPositionGreen,yPositionGreen], yAbbGreenRed)
                    set(gca,'FontSize',20);
                    colormap("spring")
                    xlabel('X Position')
                    ylabel('Y Position')
                    zlabel('Y abberation')
                    alpha(0.2)
                    gofY
                end   
                
                % Z Abb Surface
                [fitSurfaceZ,gofZ] = fit([xPositionGreen,yPositionGreen],zAbbGreenRed, 'poly22');
                if plotTrue == 1
                    figure;
                    plot(fitSurfaceZ,[xPositionGreen,yPositionGreen], zAbbGreenRed)
                    set(gca,'FontSize',20);
                    colormap("spring")
                    xlabel('X Position')
                    ylabel('Y Position')
                    zlabel('Z abberation')
                    alpha(0.2)
                    gofZ
                end
                 
            end

        end
        
        function exportCACalibration(~,~)
            
            exportCAPath = uigetdir();

            d1 = datetime(floor(now),'ConvertFrom','datenum');
            newDir = fullfile(exportCAPath, strcat(datestr(d1), '_3D-Speckler_Calibration_Files'));
            disp('Saving Calibration to path:');
            disp(newDir);
            mkdir(newDir);

            if ~isempty(affineRG) || ~isempty(affineFRG) || ~isempty(affineBG) || ~isempty(affineFRR) || ~isempty(affineBR) || ~isempty(affineBFR)
                disp('.');
                disp('Saving Geometric Affine Transform Calibrations...');
                if ~isempty(affineRG)
                    save(fullfile(newDir,'affineRG.mat'),'affineRG');
                end
                if ~isempty(affineFRG)
                    save(fullfile(newDir,'affineFRG.mat'),'affineFRG');
                end
                if ~isempty(affineBG)
                    save(fullfile(newDir,'affineBG.mat'),'affineBG');
                end
                if ~isempty(affineFRR)
                    save(fullfile(newDir,'affineFRR.mat'),'affineFRR');
                end
                if ~isempty(affineBR)
                    save(fullfile(newDir,'affineBR.mat'),'affineBR');
                end
                if ~isempty(affineBFR)
                    save(fullfile(newDir,'affineBFR.mat'),'affineBFR');
                end
                disp('Geometric Affine Transform(s) Saved.');
                disp('******************************************************');
            end

            if ~isempty(surfX_GR) || ~isempty(surfY_GR) || ~isempty(surfZ_GR)...
                    || ~isempty(surfX_GFR) || ~isempty(surfY_GFR) || ~isempty(surfZ_GFR)...
                    || ~isempty(surfX_GB) || ~isempty(surfY_GB) || ~isempty(surfZ_GB)...
                    || ~isempty(surfX_RFR) || ~isempty(surfY_RFR) || ~isempty(surfZ_RFR)...
                    || ~isempty(surfX_RB) || ~isempty(surfY_RB) || ~isempty(surfZ_RB)...
                    || ~isempty(surfX_FRB) || ~isempty(surfY_FRB) || ~isempty(surfZ_FRB)


                disp('.');
                disp('Saving Polynomial Surface Calibration(s)...');

                if ~isempty(surfX_GR)
                    save(fullfile(newDir,'surfX_GR.mat'),'surfX_GR');
                end
                if ~isempty(surfY_GR)
                    save(fullfile(newDir,'surfY_GR.mat'),'surfY_GR');
                end
                if ~isempty(surfZ_GR)
                    save(fullfile(newDir,'surfZ_GR.mat'),'surfZ_GR');
                end

                if ~isempty(surfX_GFR)
                    save(fullfile(newDir,'surfX_GFR.mat'),'surfX_GFR');
                end
                if ~isempty(surfY_GFR)
                    save(fullfile(newDir,'surfY_GFR.mat'),'surfY_GFR');
                end
                if ~isempty(surfZ_GFR)
                    save(fullfile(newDir,'surfZ_GFR.mat'),'surfZ_GFR');
                end

                if ~isempty(surfX_GB)
                    save(fullfile(newDir,'surfX_GB.mat'),'surfX_GB');
                end
                if ~isempty(surfY_GB)
                    save(fullfile(newDir,'surfY_GB.mat'),'surfY_GB');
                end
                if ~isempty(surfZ_GB)
                    save(fullfile(newDir,'surfZ_GB.mat'),'surfZ_GB');
                end

                if ~isempty(surfX_RFR)
                    save(fullfile(newDir,'surfX_RFR.mat'),'surfX_RFR');
                end
                if ~isempty(surfY_RFR)
                    save(fullfile(newDir,'surfY_RFR.mat'),'surfY_RFR');
                end
                if ~isempty(surfZ_RFR)
                    save(fullfile(newDir,'surfZ_RFR.mat'),'surfZ_RFR');
                end

                if ~isempty(surfX_RB)
                    save(fullfile(newDir,'surfX_RB.mat'),'surfX_RB');
                end
                if ~isempty(surfY_RB)
                    save(fullfile(newDir,'surfY_RB.mat'),'surfY_RB');
                end
                if ~isempty(surfZ_RB)
                    save(fullfile(newDir,'surfZ_RB.mat'),'surfZ_RB');
                end

                if ~isempty(surfX_FRB)
                    save(fullfile(newDir,'surfX_FRB.mat'),'surfX_FRB');
                end
                if ~isempty(surfY_FRB)
                    save(fullfile(newDir,'surfY_FRB.mat'),'surfY_FRB');
                end
                if ~isempty(surfZ_FRB)
                    save(fullfile(newDir,'surfZ_FRB.mat'),'surfZ_FRB');
                end
                disp('Polynomial Surface Calibration(s) Saved.');
                disp('******************************************************');

            end
        end
        
    end


    function updateMainIMG(h, ~)
        
        zoomObj = get(gca, {'xlim','ylim'});
        zSlice = round(get(h, 'Value'));
        clearFigure(mainFig);
        ax = axes('Parent', mainFig, 'Position', [0.1 0.1 0.8 0.8]);
        imshow(currentChannel(:,:,zSlice), [], 'InitialMagnification', 450);
        set(gca, {'xlim','ylim'}, zoomObj);
        anno = annotation('textbox', [0.77, 0.875, 0.025, 0.025], 'string', num2str(zSlice),'FontSize',7.5);
        
        if (modeChoice == 2) | (modeChoice == 3)
            annotateFigure();
        end
        
    end

    function mainModeSetup()
        
        val = get(modeOptions, 'Value');
        mainFig;
        viewFigSize = [1.5*(imgSize(2)/imgSize(1))*figWidthFactor, 800];
        set(gcf,'NumberTitle','off'); set(gcf,'Name','MAIN UI');
        clf;
        set(gcf, 'Resize', 'off');
        ax = axes('Parent', mainFig, 'Position', [0.1 0.1 0.8 0.8]);
        currentIMG = imshow(currentChannel(:,:,zSlice), [], 'InitialMagnification', 450);
        hold on;
        
        % Slider Section
        if nPlanes > 1
            h = uicontrol('Parent', mainFig,'Style','slider','Position',[viewFigSize(1)*0.775, viewFigSize(2)*0.11,20,600],...
                'SliderStep', [1/(nPlanes-1) , 10/(nPlanes-1) ],...
                'value',zSlice, 'min', 1, 'max',nPlanes, 'Callback', {@updateMainIMG});
            anno = annotation('textbox', [0.77, 0.875, 0.025, 0.025], 'string', num2str(zSlice),'FontSize',7.5);
        end
        
        % Switching Channels Buttons %
        if (nChannels >= 1) && (~isempty(channel1))
            a = uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.24, viewFigSize(2)*0.905, 100, 30],...
                'String', 'CHANNEL 1', 'FontSize', 12, 'Callback', {@chooseCh1});
        end
        if (nChannels >= 2) && (~isempty(channel2))
            b = uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.33, viewFigSize(2)*0.905, 100, 30],...
                'String', 'CHANNEL 2', 'FontSize', 12, 'Callback', {@chooseCh2});
        end
        if (nChannels >= 3) && (~isempty(channel3))
            c = uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.42, viewFigSize(2)*0.905, 100, 30],...
                'String', 'CHANNEL 3', 'FontSize', 12, 'Callback', {@chooseCh3});
        end
        if (nChannels >= 4) && (~isempty(channel4))
            d = uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.51, viewFigSize(2)*0.905, 100, 30],...
                'String', 'CHANNEL 4', 'FontSize', 12, 'Callback', {@chooseCh4});
        end
        
        % Reset View Button
        uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.74, viewFigSize(2)*0.07, 65, 20],...
            'String', 'RESET VIEW', 'FontSize', 7, 'BackgroundColor',[1,0.7,0.7], 'Callback', {@resetZoom});
        % Contrast Button
        uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.205, viewFigSize(2)*0.07, 65, 20],...
            'String', 'CONTRAST', 'FontSize', 7, 'BackgroundColor',[0.7,0.7,1], 'Callback', {@adjustContrast});
        
        modeOptions = uicontrol('Parent', mainFig,'Style','popupmenu','Position',[viewFigSize(1)*0.81, viewFigSize(2)*0.94,200,20],...
            'String', {'Choose Option', 'Particle Analysis', 'Protein Quantification'...
            'Chromatic Aberration Calibration'
            },'FontSize',14,'Value', val, 'Callback', {@modeChosen});
        
        % Left Side Buttons
        uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.03, viewFigSize(2)*0.93,140, 35],...
            'String', 'Open File', 'BackgroundColor',[0.8,1,0.8],'FontSize', 12, 'Callback', {@chooseNewFile});
        uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.03, viewFigSize(2)*0.87,140, 35],...
            'String', 'Import Data', 'BackgroundColor',[0.8,0.8,1], 'FontSize', 12, 'Callback', {@importData});
        uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.03, viewFigSize(2)*0.81,140, 35],...
            'String', 'Import CA Calibration', 'BackgroundColor',[1,0.7,0.7], 'FontSize', 10, 'Callback', {@importCAcal});
        
        % ROI Button %
        uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.04, viewFigSize(2)*0.07,130, 25],...
            'String', 'Commit Current ROI', 'BackgroundColor',[0.6,1,0.65], 'FontSize', 9, 'Callback', {@commitROI});
        uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.052, viewFigSize(2)*0.04,100, 20],...
            'String', 'Reset ROI', 'BackgroundColor',[[1,0.6,0.6]], 'FontSize', 8, 'Callback', {@resetROI});    

        
        function commitROI(~,~)
            
            global Ochannel1 Ochannel2 Ochannel3 Ochannel4 cropROI
            
            answer = questdlg('Would you like to commit current ROI?', ...
                'CHOOSE ROI', ...
                'Yes','No','Yes');
            % Handle response
            switch answer
                case 'Yes'
                    lims = get(gca,{'xlim','ylim'});
                    xlims = lims(1); ylims = lims(2);
                    if xlims{1}(1) < 1
                        xlims{1}(1) = 1;
                    end
                    if xlims{1}(2) > imgSize(2)
                        xlims{1}(2) = imgSize(2);
                    end
                    if ylims{1}(1) < 1
                        ylims{1}(1) = 1;
                    end
                    if ylims{1}(2) > imgSize(1)
                        ylims{1}(2) = imgSize(1);
                    end
                    
                    if ~isempty(Ochannel1)
                        channel1 = channel1(floor(ylims{1}(1)):ceil(ylims{1}(2)),floor(xlims{1}(1)):ceil(xlims{1}(2)),:);
                        imgSize = size(channel1);
                    end
                    if ~isempty(Ochannel2)
                        channel2 = channel2(floor(ylims{1}(1)):ceil(ylims{1}(2)),floor(xlims{1}(1)):ceil(xlims{1}(2)),:);
                        imgSize = size(channel2);
                    end
                    if ~isempty(Ochannel3)
                        channel3 = channel3(floor(ylims{1}(1)):ceil(ylims{1}(2)),floor(xlims{1}(1)):ceil(xlims{1}(2)),:);
                        imgSize = size(channel3);
                    end
                    if ~isempty(Ochannel4)
                        channel4 = channel4(floor(ylims{1}(1)):ceil(ylims{1}(2)),floor(xlims{1}(1)):ceil(xlims{1}(2)),:);
                        imgSize = size(channel4);
                    end
                    
                    disp('ROI Chosen:');
                    disp('.');
                    disp(strcat('X ROI Range: ', '[', num2str(floor(ylims{1}(1))), ':', num2str(ceil(ylims{1}(2))), ']'));
                    disp(strcat('Y ROI Range: ', '[', num2str(floor(xlims{1}(1))), ':', num2str(ceil(xlims{1}(2))), ']'));
                    disp('..........................................');
                    
                    cropROI = [floor(ylims{1}(1)) ceil(ylims{1}(2)); floor(xlims{1}(1)) ceil(xlims{1}(2))];
                    updateMainIMG2();
                    if nPlanes > 1
                        try
                            delete(h);
                            delete(anno);
                        end
                        h = uicontrol('Parent', mainFig,'Style','slider','Position',[viewFigSize(1)*0.775, viewFigSize(2)*0.11,20,600],...
                            'SliderStep', [1/(nPlanes-1) , 10/(nPlanes-1) ],...
                            'value',zSlice, 'min', 1, 'max',nPlanes, 'Callback', {@updateMainIMG});
                        anno = annotation('textbox', [0.77, 0.875, 0.025, 0.025], 'string', num2str(zSlice),'FontSize',7.5);
                    end
                    
                case 'No'
                    return;
            end
        end
        
        function resetROI(~,~)
            
            global Ochannel1 Ochannel2 Ochannel3 Ochannel4 cropROI ...
                anaParams488 anaParams594 anaParams640 anaParams405
            
            answer = questdlg('Would you like to reset ROI?', ...
                'CHOOSE ROI', ...
                'Yes','No','Yes');
            % Handle response
            switch answer
                case 'Yes'
                    if ~isempty(Ochannel1)
                        channel1 = Ochannel1;
                        imgSize = size(channel1);
                    end
                    if ~isempty(Ochannel2)
                        channel2 = Ochannel2;
                        imgSize = size(channel2);
                    end
                    if ~isempty(Ochannel3)
                        channel3 = Ochannel3;
                        imgSize = size(channel3);
                    end
                    if ~isempty(Ochannel4)
                        channel4 = Ochannel4;
                        imgSize = size(channel4);
                    end
                    
                    disp('ROI Reset!');
                    disp('..........................................');
                    
                    finalFit488 = []; finalBB488 = []; finalFit594 = [];
                    finalBB594 = []; finalFit640 = []; finalBB640 = [];
                    finalFit405 = []; finalBB405 = []; cropROI = [];
                    
                    anaParams488 = []; anaParams594  = []; anaParams640  = [];
                    anaParams405 = [];
                    updateMainIMG2();
                    if nPlanes > 1
                        try
                            delete(h);
                            delete(anno);
                        end
                        h = uicontrol('Parent', mainFig,'Style','slider','Position',[viewFigSize(1)*0.775, viewFigSize(2)*0.11,20,600],...
                            'SliderStep', [1/(nPlanes-1) , 10/(nPlanes-1) ],...
                            'value',zSlice, 'min', 1, 'max',nPlanes, 'Callback', {@updateMainIMG});
                        anno = annotation('textbox', [0.77, 0.875, 0.025, 0.025], 'string', num2str(zSlice),'FontSize',7.5);
                    end
                    
                case 'No'
                    return;
            end
        end
        
        function updateMainIMG2()
            
            clearFigure(mainFig);
            ax = axes('Parent', mainFig, 'Position', [0.1 0.1 0.8 0.8]);
            eval(['currentChannel = channel', num2str(currentChN),';'])
            imshow(currentChannel(:,:,zSlice), [], 'InitialMagnification', 450);
            zoomObj = get(gca, {'xlim','ylim'});
            anno = annotation('textbox', [0.77, 0.875, 0.025, 0.025], 'string', num2str(zSlice),'FontSize',7.5);
            
            if (modeChoice == 2) || (modeChoice == 3)
                annotateFigure();
            end
            
            set(gca, {'xlim','ylim'}, zoomObj);
            
        end
        
    end

    % Import Chromatic Aberration Calibrations
    function importCAcal(~,~)

        % Import All Data %
        dirPath = uigetdir();
        fileList = dir(fullfile(dirPath,'*.mat'));

        disp('Folder Selected:');
        disp(dirPath);

        disp(strcat('Number of Files Detected: ', num2str(size(fileList,1))));
        if size(fileList,1) == 0
            disp('No files detected.  No data imported.')
            disp('.');
            disp('*********************************************************************');
            return;
        end
        disp('.');
        disp('*********************************************************************');

        disp('Importing existing aberration calibration files:');
        for j = 1:size(fileList,1)
            file = fullfile(dirPath, fileList(j).name);
            load(file);
            disp(strcat('Imported: ', file));
        end
        disp('.');
        disp('Import of calibration file(s) complete.');
        disp('*********************************************************************');
        caCalTrue = true;

    end

    function particleAnalysisSetup()
        
        global bufferPercXY bufferPercZ
        
        if isempty(bufferPercXY) || isempty(bufferPercZ)
            bufferPercXY = 0.3;
            bufferPercZ = 0.4;
        end
        if isempty(sizeL) || isempty(sizeU)
            sizeL = 2;
            sizeU = 15;
        end

        % Right Side Buttons
        uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.825, viewFigSize(2)*0.83,150, 35],...
            'String', 'Start Analysis', 'BackgroundColor',[1,0.7,0.4], 'FontSize', 12, 'Callback', {@startAnalysis});
        uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.825, viewFigSize(2)*0.755,150, 35],...
            'String', 'Fit Gaussians', 'BackgroundColor',[0.8,0.6,1], 'FontSize', 12, 'Callback', {@gaussButton});
        
        if modeChoice == 2
            uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.825, viewFigSize(2)*0.48,150, 35],...
                'String', 'Match & Align Pts', 'BackgroundColor',[1,1,0.5], 'FontSize', 11.5, 'Callback', {@chooseMatch});
            uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.825, viewFigSize(2)*0.405,150, 35],...
                'String', 'Distance Matrices', 'BackgroundColor',[1,0.45,0.55], 'FontSize', 11.5, 'Callback', {@chooseDistanceMatrices});
            uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.825, viewFigSize(2)*0.33,150, 35],...
                'String', 'Aberrations', 'BackgroundColor',[1,0.8,1], 'FontSize', 11.5, 'Callback', {@chooseAberrations});
        end
        
        if modeChoice == 3
            uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.825, viewFigSize(2)*0.48,150, 35],...
                'String', 'Match & Align Pts', 'BackgroundColor',[1,1,0.5], 'FontSize', 11.5, 'Callback', {@chooseMatch});
            uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.825, viewFigSize(2)*0.405,150, 35],...
                'String', 'Distance Matrices', 'BackgroundColor',[1,0.45,0.55], 'FontSize', 11.5, 'Callback', {@chooseDistanceMatrices});
            uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.825, viewFigSize(2)*0.33,150, 35],...
                'String', 'Transfer ROIs', 'BackgroundColor',[1,0.8,1], 'FontSize', 11.5, 'Callback', {@transferROIs});
        end
        
        % Save Channel Data and Export %
        uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.825, viewFigSize(2)*0.1,150, 35],...
            'String', 'Save Channel Results', 'BackgroundColor',[0.8,1,0.8], 'FontSize', 10, 'Callback', {@saveData});
        uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.825, viewFigSize(2)*0.04,150, 35],...
            'String', 'Export Results', 'BackgroundColor',[0.75,0.75,0.75], 'FontSize', 10, 'Callback', {@exportData});
        
        % Option for Clear Channel Results Button %
%         uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.825, viewFigSize(2)*0.105,150, 35],...
%             'String', 'Save Channel Results', 'BackgroundColor',[0.8,1,0.8], 'FontSize', 10, 'Callback', {@saveData});
%         uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.825, viewFigSize(2)*0.035,150, 35],...
%             'String', 'Export Results', 'BackgroundColor',[0.75,0.75,0.75], 'FontSize', 10, 'Callback', {@exportData});
%         
%         uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.85, viewFigSize(2)*0.085, 120, 15],...
%             'String', 'CLEAR CHANNEL DATA', 'FontSize', 7, 'BackgroundColor',[1,0.75,0.75], 'Callback', {@clearCurrentChannel});

        % Panel For Gaussian Analysis Options
        gaussPan = uibuttongroup('Title','Fitting Options','FontSize',8,...
                     'BackgroundColor',[1,1,1],'FontWeight', 'bold',...
                     'Position',[0.825 0.56 .125 .15]);
        gauss2DOpt = uicontrol(gaussPan,'Style','Checkbox','String','  2D Gauss Fit','FontSize',9,...
                'pos',[15 72 200 30],'BackgroundColor', [1,1,1]);    
        if nPlanes > 1
            gauss3DOpt = uicontrol(gaussPan,'Style','Checkbox','String','  3D Gauss Fit','FontSize',9,...
                'pos',[15 50 200 30],'BackgroundColor',[1,1,1]);
        end

        % Panel For Analysis Options
        analysisOptPan = uibuttongroup('Title','Analysis Options','FontSize',8,...
                     'BackgroundColor',[1,1,1],'FontWeight', 'bold',...
                     'Position',[0.03 0.58 .16 .17]);
        bgCorr = uicontrol(analysisOptPan,'Style','Checkbox','String','  Local Background Correction','FontSize',7,...
                'pos',[15 85 200 30],'BackgroundColor',[1,1,1],...
                'Callback', {});    
        excludeOverlap = uicontrol(analysisOptPan,'Style','Checkbox','String','  Exclude Overlapping Particles','FontSize',7,...
                'pos',[15 63 200 30],'BackgroundColor',[1,1,1],...
                'Callback', {});
        excludeSize = uicontrol(analysisOptPan,'Style','Checkbox','String','  Filter Particles By Size','FontSize',7,...
                'pos',[15 41 200 30],'BackgroundColor',[1,1,1],...
                'Callback', {});
        if caCalTrue == true
            caCorr = uicontrol(analysisOptPan,'Style','Checkbox','String','  Chromatic Aberration Correction','FontSize',7,...
                'pos',[15 19 200 30],'BackgroundColor',[1,1,1],...
                'Callback', {});
        end
        
        % Box Buffer Section %
        annotation('textbox', [0.041, 0.43, 0.1, 0.1], 'string', 'BOUNDING BOX BUFFER', 'FontSize', 9, 'fontweight', 'bold', 'EdgeColor', 'none', 'Color', [0, 0, 0.8]);
        annotation('textbox', [0.025, 0.45, 0.1, 0.05], 'string', 'XY Box Buffer (0-1)', 'FontSize', 7, 'fontweight', 'bold', 'EdgeColor', 'none');
        xyBBPerc = uicontrol(mainFig,'Style','edit','String','0.3','FontSize',8,...
                'pos',[viewFigSize(1)*0.034, viewFigSize(2)*0.45 80 20], 'BackgroundColor',[1,1,1]);
        
        if length(size(currentChannel)) == 3
            annotation('textbox', [0.115, 0.45, 0.1, 0.05], 'string', 'Z Box Buffer (0-1)', 'FontSize', 7, 'fontweight', 'bold', 'EdgeColor', 'none');
            zBBPerc = uicontrol(mainFig,'Style','edit','String','0.3','FontSize',8,...
                    'pos',[viewFigSize(1)*0.118, viewFigSize(2)*0.45 80 20], 'BackgroundColor',[1,1,1]);
        elseif length(size(currentChannel)) == 2
            annotation('textbox', [0.115, 0.45, 0.1, 0.05], 'string', 'Z Box Buffer (0-1)', 'FontSize', 7, 'fontweight', 'bold', 'EdgeColor', 'none');
            zBBPerc = uicontrol(mainFig,'Style','edit','String','N/A','FontSize',8,...
                    'pos',[viewFigSize(1)*0.118, viewFigSize(2)*0.45 80 20], 'BackgroundColor',[1,1,1], 'enable', 'off');
        end
            
        uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.045, viewFigSize(2)*0.41, 150, 20],...
            'String', 'Update Bounding Box Buffer', 'BackgroundColor',[0.7,0.7,0.7], 'FontSize', 8, 'Callback', {@updateBBSize});
        
        
       % Size Filter Section %
       annotation('textbox', [0.044, 0.28, 0.1, 0.1], 'string', 'PARTICLE SIZE FILTER', 'FontSize', 9, 'fontweight', 'bold', 'EdgeColor', 'none', 'Color', [0.8, 0.4, 0]);
       annotation('textbox', [0.027, 0.3, 0.1, 0.05], 'string', 'Lower Limit (pxls)', 'FontSize', 7, 'fontweight', 'bold', 'EdgeColor', 'none');
       annotation('textbox', [0.112, 0.3, 0.1, 0.05], 'string', 'Upper Limit (pxls)', 'FontSize', 7, 'fontweight', 'bold', 'EdgeColor', 'none');
       sizeLower = uicontrol(mainFig,'Style','edit','String','2','FontSize',8,...
                'pos',[viewFigSize(1)*0.034, viewFigSize(2)*0.3 80 20], 'BackgroundColor',[1,1,1]);
       sizeUpper = uicontrol(mainFig,'Style','edit','String','15','FontSize',8,...
                    'pos',[viewFigSize(1)*0.118, viewFigSize(2)*0.3 80 20], 'BackgroundColor',[1,1,1]);
       uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.045, viewFigSize(2)*0.26, 150, 20],...
            'String', 'Update Size Filter Limits', 'BackgroundColor',[0.7,0.7,0.7], 'FontSize', 8, 'Callback', {@updateSizeFilter});
        
        
        
        function startAnalysis(~,~)
            
            global countThreshold matchNtimes
            warning off;
            
            gaussFitted = false;
            matchNtimes = 0;
            
            multiThresholds = [];
            multiSizeCentroids = [];
            multiBBCentroids = [];
            multiPxlCentroids = [];
            multiTrueCentroids = [];
            
            countThreshold = 1.2;   % STD >= countThreshold * MEAN
            thTrue = false;
            if currentChN == 1
                currentChannel = channel1;
            elseif currentChN == 2
                currentChannel = channel2;
            elseif currentChN == 3
                currentChannel = channel3;
            elseif currentChN == 4
                currentChannel = channel4;
            end
                
            if nPlanes > 1
                delete(h);
                delete(anno);
            end
            
            clearFigure(mainFig);
            annotateFigure()
            %findStartThreshold();
            extractTotalCentroids();
            chooseThresholdUI();      
        end
        
        
        % GAUSS ANALYSIS BUTTON %
        function gaussButton(~,~)
            
            if thTrue ~= true
                warndlg('Error: Threshold Not Set!');
                return;
            end
            
            g2DOpt = get(gauss2DOpt, 'Value');
            if nPlanes > 1
                g3DOpt = get(gauss3DOpt, 'Value');
            end
            bgOpt = get(bgCorr, 'Value');
            overlapOpt = get(excludeOverlap, 'Value');
            sizeOpt = get(excludeSize, 'Value');
            
            % If No Fitting Options Chosen
            if (nPlanes > 1) && (g2DOpt == 0) && (g3DOpt == 0)
                warndlg('Error: No Fitting Options Chosen!');
                return;
            elseif (nPlanes > 1) && (g2DOpt == 1) && (g3DOpt == 1)
                warndlg('Error: Please Choose One Fit Option At A Time!');
                return;
            elseif (nPlanes == 1) && (g2DOpt == 0)
                warndlg('Error: No Fitting Options Chosen!');
                return;
            end
            
%             % If No Calibration was Imported %
%             if (caOpt == 1) && (caCalTrue == false)
%                 warndlg('Error: Please Import Chromatic Aberration Calibration!');
%                 return;
%             end
            
            % Ask for Background Correction Value %
            if bgOpt == 1
                prompt = {'Choose Background Correction Box Buffer (0-1)'};
                dlgtitle = 'Background Correction';
                dims = [1 35];
                definput = {'0.15'};
                answer = inputdlg(prompt,dlgtitle,dims,definput);
                if isempty(answer)
                    return;
                end
                disp(strcat('Background Correction Box Buffer: *', answer));
                bgPixel = str2double(answer);
            end
            
            % Ask for Overlap Threshold Value %
            if overlapOpt == 1
                prompt = {'Choose Overlap Threshold (0-1)'};
                dlgtitle = 'Particle Overlap Filter';
                dims = [1 35];
                definput = {'0.5'};
                answer = inputdlg(prompt,dlgtitle,dims,definput);
                if isempty(answer)
                    return;
                end
                disp(strcat('Particle Overlap Threshold: *', answer));
                overlapThreshold = str2double(answer);
            end

            % If Gaussian Option Chosen %
            if (g2DOpt == 1) || (g3DOpt == 1)
              
                % If 3D Gauss Option Chosen %
                if (nPlanes > 1) && (g2DOpt == 0) && (g3DOpt == 1)
                    disp('3D Gauss Fit for 3D Data Selected.');
                    % Execute 3D Gauss Fit for 3D Data %
                    extractAll3DGauss();
                end
                
                % If 2D Gauss Option Chosen %
                if (nPlanes > 1) && (g2DOpt == 1) && (g3DOpt == 0)
                    disp('2D Gauss Fit for 3D Data Selected.');
                    % Execute 2D Gauss Fit for 3D Data %
                    extractAll2DGauss3DOpt();
                    
                elseif (nPlanes == 1) && (g2DOpt == 1)
                    disp('2D Gauss Fit for 2D Data Selected.');
                    % Execute 2D Gauss Fit for 2D Data %
                    extractAll2DGauss();             
                end

            end
                    
        end
        
        function saveData(~,~)
            
            global finalPts488 finalPts594...
                finalPts640 finalPts405 anaParams488 anaParams594...
                anaParams640 anaParams405 countThreshold multi488...
                multi594 multi640 multi405 currentCentroids
            
            result = find(nOptions == currentChN);
            channelCheck = [nOptions(1) ~= 0 nOptions(2) ~= 0 nOptions(3) ~= 0 nOptions(4) ~= 0];
            affineOpt = []; surfaceOpt = [];
            if caCalTrue == true
                try
                    caOpt = get(caCorr, 'Value');
                catch
                    caOpt = 0;
                end
                if (caOpt == 1) && ...
                        (((channelCheck(1) == 1) && (result ~= 1)) ||...
                        ((channelCheck(1) == 0) && (channelCheck(2) == 1) && (result ~= 2)) ||...
                        ((channelCheck(1) == 0) && (channelCheck(2) == 1) && (channelCheck(3) == 1) && (result ~= 3)))
                    
                    answer = questdlg('Which method of aberration correction will be performed?', ...
                        'Aberration Correction', ...
                        'Affine Transform','Polynomial Surface','Cancel','Affine Transform');
                    % Handle response
                    switch answer
                        case 'Affine Transform'
                            affineOpt = 1;
                            surfaceOpt = 0;
                        case 'Polynomial Surface'
                            affineOpt = 0;
                            surfaceOpt = 1;
                        case 'Cancel'
                            disp('Aberration Correction cancelled.')
                            return;
                    end
                else
                    affineOpt = 0;
                    surfaceOpt = 0;
                end
            
            end
            
            
            if result == 1
                if g2DOpt == 1
                    finalFit488 = currentPts;
                    finalPts488 = currentPts(:,1:2);
                    finalBB488 = currentBB;
                    anaParams488 = [];
                    anaParams488 = [anaParams488; bufferPercXY];
                    % Save Parameters %
                    if bgOpt == 1
                        anaParams488 = [anaParams488; bgPixel];
                    else
                        anaParams488 = [anaParams488; NaN];
                    end
                    if overlapOpt == 1
                        anaParams488 = [anaParams488; overlapThreshold];
                    else
                        anaParams488 = [anaParams488; NaN];
                    end
                    if sizeOpt == 1
                        anaParams488 = [anaParams488; sizeL; sizeU];
                    else
                        anaParams488 = [anaParams488; NaN; NaN];
                    end
                    if isempty(multiThresholds)
                        anaParams488 = [anaParams488; countThreshold];
                    elseif ~isempty(multiThresholds)
                        anaParams488 = [anaParams488; NaN];
                        multi488 = multiThresholds;
                    end
                    msgbx = msgbox('Green Channel 2D Fit Results Stored.');
                    saveCheck = 1;
                elseif g3DOpt == 1
                    finalFit488 = currentPts;
                    finalPts488 = currentPts(:,1:3);
                    finalBB488 = currentBB;
                    anaParams488 = [];
                    anaParams488 = [anaParams488; bufferPercXY; bufferPercZ];
                    % Save Parameters %
                    if bgOpt == 1
                        anaParams488 = [anaParams488; bgPixel];
                    else
                        anaParams488 = [anaParams488; NaN];
                    end
                    if overlapOpt == 1
                        anaParams488 = [anaParams488; overlapThreshold];
                    else
                        anaParams488 = [anaParams488; NaN];
                    end
                    if sizeOpt == 1
                        anaParams488 = [anaParams488; sizeL; sizeU];
                    else
                        anaParams488 = [anaParams488; NaN; NaN];
                    end
                    if isempty(multiThresholds)
                        anaParams488 = [anaParams488; countThreshold];
                    elseif ~isempty(multiThresholds)
                        anaParams488 = [anaParams488; NaN];
                        multi488 = multiThresholds;
                    end
                    msgbx = msgbox('Green Channel 3D Fit Results Stored.');
                    saveCheck = 1;
                end
                finalCentroids488 = currentCentroids;
            end
            if result == 2
                if g2DOpt == 1
                    % Perform 2D Surface Calibration
                    if ~isempty(surfaceOpt) && ~isempty(affineOpt) && (surfaceOpt == 1) && (affineOpt == 0)
                        if (channelCheck(1) == 1) && (channelCheck(2) == 1) && ~isempty(surfX_GR) && ~isempty(surfY_GR)
                            for i = 1:size(currentPts,1)
                                currentPts(i,1) = currentPts(i,1) - surfX_GR(currentPts(i,1),currentPts(i,2));
                                currentPts(i,2) = currentPts(i,2) - surfY_GR(currentPts(i,1),currentPts(i,2));
                            end
                            redSurfCalTrue = true;
                            disp('2D Red to Green polynomial surface correction successful.')
                        else
                            warndlg('Error: Red Channel 2D polynomial surface correction could not be performed.');
                        end
                    % Perform 2D Affine Transform Calibration
                    elseif ~isempty(surfaceOpt) && ~isempty(affineOpt) && (surfaceOpt == 0) && (affineOpt == 1)
                        if (channelCheck(1) == 1) && (channelCheck(2) == 1) && ~isempty(affineRG) && (affineRG.Dimensionality == 2)
                            currentPts(:,1:2) = transformPointsForward(affineRG,currentPts(:,1:2));
                            redAffineCalTrue = true;
                            disp('2D Red to Green affine transform correction successful.')
                        else
                            warndlg('Error: Red Channel 2D affine transform correction could not be performed.');
                        end
                    end
                    finalFit594 = currentPts;
                    finalPts594 = currentPts(:,1:2);
                    finalBB594 = currentBB;
                    anaParams594 = [];
                    anaParams594 = [anaParams594; bufferPercXY];
                    % Save Parameters %
                    if bgOpt == 1
                        anaParams594 = [anaParams594; bgPixel];
                    else
                        anaParams594 = [anaParams594; NaN];
                    end
                    if overlapOpt == 1
                        anaParams594 = [anaParams594; overlapThreshold];
                    else
                        anaParams594 = [anaParams594; NaN];
                    end
                    if sizeOpt == 1
                        anaParams594 = [anaParams594; sizeL; sizeU];
                    else
                        anaParams594 = [anaParams594; NaN; NaN];
                    end
                    if isempty(multiThresholds)
                        anaParams594 = [anaParams594; countThreshold];
                    elseif ~isempty(multiThresholds)
                        anaParams594 = [anaParams594; NaN];
                        multi594 = multiThresholds;
                    end
                    msgbx = msgbox('Red Channel 2D Fit Results Stored.');
                    saveCheck = 1;
                elseif g3DOpt == 1
                    % Perform 3D Surface Calibration
                    if ~isempty(surfaceOpt) && ~isempty(affineOpt) && (surfaceOpt == 1) && (affineOpt == 0)
                        if (channelCheck(1) == 1) && (channelCheck(2) == 1) && ~isempty(surfX_GR) && ~isempty(surfY_GR) && ~isempty(surfZ_GR)
                            for i = 1:size(currentPts,1)
                                currentPts(i,1) = currentPts(i,1) - surfX_GR(currentPts(i,1),currentPts(i,2));
                                currentPts(i,2) = currentPts(i,2) - surfY_GR(currentPts(i,1),currentPts(i,2));
                                currentPts(i,3) = currentPts(i,3) - surfZ_GR(currentPts(i,1),currentPts(i,2));
                            end
                            redSurfCalTrue = true;
                            disp('3D Red to Green polynomial surface correction successful.')
                        else
                            warndlg('Error: Red Channel 3D polynomial surface calibrations could not be performed.');
                        end
                    % Perform 3D Affine Transform Calibration
                    elseif ~isempty(surfaceOpt) && ~isempty(affineOpt) && (surfaceOpt == 0) && (affineOpt == 1)
                        if (channelCheck(1) == 1) && (channelCheck(2) == 1) && ~isempty(affineRG) && (affineRG.Dimensionality == 3)
                            currentPts(:,1:3) = transformPointsForward(affineRG,currentPts(:,1:3));
                            redAffineCalTrue = true;
                            disp('3D Red to Green affine transform correction successful.')
                        else
                            warndlg('Error: Red Channel 3D affine transform calibrations could not be performed.');
                        end
                    end
                    finalFit594 = currentPts;
                    finalPts594 = currentPts(:,1:3);
                    finalBB594 = currentBB;
                    anaParams594 = [];
                    anaParams594 = [anaParams594; bufferPercXY; bufferPercZ];
                    % Save Parameters %
                    if bgOpt == 1
                        anaParams594 = [anaParams594; bgPixel];
                    else
                        anaParams594 = [anaParams594; NaN];
                    end
                    if overlapOpt == 1
                        anaParams594 = [anaParams594; overlapThreshold];
                    else
                        anaParams594 = [anaParams594; NaN];
                    end
                    if sizeOpt == 1
                        anaParams594 = [anaParams594; sizeL; sizeU];
                    else
                        anaParams594 = [anaParams594; NaN; NaN];
                    end
                    if isempty(multiThresholds)
                        anaParams594 = [anaParams594; countThreshold];
                    elseif ~isempty(multiThresholds)
                        anaParams594 = [anaParams594; NaN];
                        multi594 = multiThresholds;
                    end
                    msgbx = msgbox('Red Channel 3D Fit Results Stored.');
                    saveCheck = 1;
                end
                finalCentroids594 = currentCentroids;
            end
            if result == 3
                if g2DOpt == 1
                    % Perform 2D Surface Calibration
                    if ~isempty(surfaceOpt) && ~isempty(affineOpt) && (surfaceOpt == 1) && (affineOpt == 0)
                        if (channelCheck(1) == 1) && (channelCheck(3) == 1) && ~isempty(surfX_GFR) && ~isempty(surfY_GFR)
                            for i = 1:size(currentPts,1)
                                currentPts(i,1) = currentPts(i,1) - surfX_GFR(currentPts(i,1),currentPts(i,2));
                                currentPts(i,2) = currentPts(i,2) - surfY_GFR(currentPts(i,1),currentPts(i,2));
                            end
                            farRedSurfCalTrue = true;
                            disp('2D Far Red to Green polynomial surface correction successful.')
                        elseif (channelCheck(1) == 0) && (channelCheck(2) == 1) && (channelCheck(3) == 1) && ~isempty(surfX_RFR) && ~isempty(surfY_RFR)
                            for i = 1:size(currentPts,1)
                                currentPts(i,1) = currentPts(i,1) - surfX_RFR(currentPts(i,1),currentPts(i,2));
                                currentPts(i,2) = currentPts(i,2) - surfY_RFR(currentPts(i,1),currentPts(i,2));
                            end
                            farRedSurfCalTrue = true;
                            disp('2D Far Red to Red polynomial surface correction successful.')
                        else
                            warndlg('Error: Far Red Channel 2D polynomial surface calibrations could not be performed.');
                        end
                    % Perform 2D Affine Transform Calibration
                    elseif ~isempty(surfaceOpt) && ~isempty(affineOpt) && (surfaceOpt == 0) && (affineOpt == 1)
                        if (channelCheck(1) == 1) && (channelCheck(3) == 1) && ~isempty(affineFRG) && (affineFRG.Dimensionality == 2)
                            currentPts(:,1:2) = transformPointsForward(affineFRG,currentPts(:,1:2));
                            farRedAffineCalTrue = true;
                            disp('2D Far Red to Green affine transform correction successful.')
                        elseif (channelCheck(1) == 0) && (channelCheck(2) == 1) && (channelCheck(3) == 1) && ~isempty(affineFRR) && (affineFRR.Dimensionality == 2)
                            currentPts(:,1:2) = transformPointsForward(affineFRR,currentPts(:,1:2));
                            farRedAffineCalTrue = true;
                            disp('2D Far Red to Red affine transform correction successful.')
                        else
                            warndlg('Error: Far Red Channel 2D affine transform calibrations could not be performed.');
                        end
                    end
                    finalFit640 = currentPts;
                    finalPts640 = currentPts(:,1:2);
                    finalBB640 = currentBB;
                    anaParams640 = [];
                    anaParams640 = [anaParams640; bufferPercXY];
                    % Save Parameters %
                    if bgOpt == 1
                        anaParams640 = [anaParams640; bgPixel];
                    else
                        anaParams640 = [anaParams640; NaN];
                    end
                    if overlapOpt == 1
                        anaParams640 = [anaParams640; overlapThreshold];
                    else
                        anaParams640 = [anaParams640; NaN];
                    end
                    if sizeOpt == 1
                        anaParams640 = [anaParams640; sizeL; sizeU];
                    else
                        anaParams640 = [anaParams640; NaN; NaN];
                    end
                    if isempty(multiThresholds)
                        anaParams640 = [anaParams640; countThreshold];
                    elseif ~isempty(multiThresholds)
                        anaParams640 = [anaParams640; NaN];
                        multi640 = multiThresholds;
                    end
                    msgbx = msgbox('Far Red Channel 2D Fit Results Stored.');
                    saveCheck = 1;
                elseif g3DOpt == 1
                    % Perform 3D Surface Calibration
                    if ~isempty(surfaceOpt) && ~isempty(affineOpt) && (surfaceOpt == 1) && (affineOpt == 0)
                        if (channelCheck(1) == 1) && (channelCheck(3) == 1) && ~isempty(surfX_GFR) && ~isempty(surfY_GFR) && ~isempty(surfZ_GFR)
                            for i = 1:size(currentPts,1)
                                currentPts(i,1) = currentPts(i,1) - surfX_GFR(currentPts(i,1),currentPts(i,2));
                                currentPts(i,2) = currentPts(i,2) - surfY_GFR(currentPts(i,1),currentPts(i,2));
                                currentPts(i,3) = currentPts(i,3) - surfZ_GFR(currentPts(i,1),currentPts(i,2));
                            end
                            farRedSurfCalTrue = true;
                            disp('3D Far Red to Green polynomial surface correction successful.')
                        elseif (channelCheck(1) == 0) && (channelCheck(2) == 1) && (channelCheck(3) == 1) && ~isempty(surfX_RFR) && ~isempty(surfY_RFR) && ~isempty(surfZ_RFR)
                            for i = 1:size(currentPts,1)
                                currentPts(i,1) = currentPts(i,1) - surfX_RFR(currentPts(i,1),currentPts(i,2));
                                currentPts(i,2) = currentPts(i,2) - surfY_RFR(currentPts(i,1),currentPts(i,2));
                                currentPts(i,3) = currentPts(i,3) - surfZ_RFR(currentPts(i,1),currentPts(i,2));
                            end
                            farRedSurfCalTrue = true;
                            disp('3D Far Red to Red polynomial surface correction successful.')
                        else
                            warndlg('Error: Far Red Channel 3D polynomial surface calibrations could not be performed.');
                        end
                    % Perform 3D Affine Transform Calibration
                    elseif ~isempty(surfaceOpt) && ~isempty(affineOpt) && (surfaceOpt == 0) && (affineOpt == 1)
                        if (channelCheck(1) == 1) && (channelCheck(3) == 1) && ~isempty(affineFRG) && (affineFRG.Dimensionality == 3)
                            currentPts(:,1:3) = transformPointsForward(affineFRG,currentPts(:,1:3));
                            farRedAffineCalTrue = true;
                            disp('3D Far Red to Green affine transform correction successful.')
                        elseif (channelCheck(1) == 0) && (channelCheck(2) == 1) && (channelCheck(3) == 1) && ~isempty(affineFRR) && (affineFRR.Dimensionality == 3)
                            currentPts(:,1:3) = transformPointsForward(affineFRR,currentPts(:,1:3));
                            farRedAffineCalTrue = true;
                            disp('3D Far Red to Red affine transform correction successful.')
                        else
                            warndlg('Error: Far Red Channel 3D affine transform calibrations could not be performed.');
                        end
                    end
                    finalFit640 = currentPts;
                    finalPts640 = currentPts(:,1:3);
                    finalBB640 = currentBB;
                    anaParams640 = [];
                    anaParams640 = [anaParams640; bufferPercXY; bufferPercZ];
                    % Save Parameters %
                    if bgOpt == 1
                        anaParams640 = [anaParams640; bgPixel];
                    else
                        anaParams640 = [anaParams640; NaN];
                    end
                    if overlapOpt == 1
                        anaParams640 = [anaParams640; overlapThreshold];
                    else
                        anaParams640 = [anaParams640; NaN];
                    end
                    if sizeOpt == 1
                        anaParams640 = [anaParams640; sizeL; sizeU];
                    else
                        anaParams640 = [anaParams640; NaN; NaN];
                    end
                    if isempty(multiThresholds)
                        anaParams640 = [anaParams640; countThreshold];
                    elseif ~isempty(multiThresholds)
                        anaParams640 = [anaParams640; NaN];
                        multi640 = multiThresholds;
                    end
                    msgbx = msgbox('Far Red Channel 3D Fit Results Stored.');
                    saveCheck = 1;
                end
                finalCentroids640 = currentCentroids;
            end
            if result == 4
                if g2DOpt == 1

                    % Perform 2D Surface Calibration
                    if ~isempty(surfaceOpt) && ~isempty(affineOpt) && (surfaceOpt == 1) && (affineOpt == 0)
                        if (channelCheck(1) == 1) && (channelCheck(4) == 1) && ~isempty(surfX_GB) && ~isempty(surfY_GB)
                            for i = 1:size(currentPts,1)
                                currentPts(i,1) = currentPts(i,1) - surfX_GB(currentPts(i,1),currentPts(i,2));
                                currentPts(i,2) = currentPts(i,2) - surfY_GB(currentPts(i,1),currentPts(i,2));
                            end
                            blueSurfCalTrue = true;
                            disp('2D Blue to Green polynomial surface correction successful.')
                        elseif (channelCheck(1) == 0) && (channelCheck(2) == 1) && (channelCheck(4) == 1) && ~isempty(surfX_RB) && ~isempty(surfY_RB)
                            for i = 1:size(currentPts,1)
                                currentPts(i,1) = currentPts(i,1) - surfX_RB(currentPts(i,1),currentPts(i,2));
                                currentPts(i,2) = currentPts(i,2) - surfY_RB(currentPts(i,1),currentPts(i,2));
                            end
                            blueSurfCalTrue = true;
                            disp('2D Blue to Red polynomial surface correction successful.')
                        elseif (channelCheck(1) == 0) && (channelCheck(2) == 0) && (channelCheck(3) == 1) && (channelCheck(4) == 1) && ~isempty(surfX_FRB) && ~isempty(surfY_FRB)
                            for i = 1:size(currentPts,1)
                                currentPts(i,1) = currentPts(i,1) - surfX_FRB(currentPts(i,1),currentPts(i,2));
                                currentPts(i,2) = currentPts(i,2) - surfY_FRB(currentPts(i,1),currentPts(i,2));
                            end
                            blueSurfCalTrue = true;
                            disp('2D Blue to Far Red polynomial surface correction successful.')
                        else
                            warndlg('Error: Blue Channel 2D polynomial surface calibrations could not be performed.');
                        end
                    % Perform 2D Affine Transform Calibration
                    elseif ~isempty(surfaceOpt) && ~isempty(affineOpt) && (surfaceOpt == 0) && (affineOpt == 1)
                        if (channelCheck(1) == 1) && (channelCheck(4) == 1) && ~isempty(affineBG) && (affineBG.Dimensionality == 2)
                            currentPts(:,1:2) = transformPointsForward(affineBG,currentPts(:,1:2));
                            blueAffineCalTrue = true;
                            disp('2D Blue to Green affine transform correction successful.')
                        elseif (channelCheck(1) == 0) && (channelCheck(2) == 1) && (channelCheck(4) == 1) && ~isempty(affineBR) && (affineBR.Dimensionality == 2)
                            currentPts(:,1:2) = transformPointsForward(affineBR,currentPts(:,1:2));
                            blueAffineCalTrue = true;
                            disp('2D Blue to Red affine transform correction successful.')
                        elseif (channelCheck(1) == 0) && (channelCheck(2) == 0) && (channelCheck(3) == 1) && (channelCheck(4) == 1) && ~isempty(affineBFR) && (affineBFR.Dimensionality == 2)
                            currentPts(:,1:2) = transformPointsForward(affineBFR,currentPts(:,1:2));
                            blueAffineCalTrue = true;
                            disp('2D Blue to Far Red affine transform correction successful.')
                        else
                            warndlg('Error: Blue Channel 2D affine transform calibrations could not be performed.');
                        end
                    end

                    finalFit405 = currentPts;
                    finalPts405 = currentPts(:,1:2);
                    finalBB405 = currentBB;
                    anaParams405 = [];
                    anaParams405 = [anaParams405; bufferPercXY];
                    % Save Parameters %
                    if bgOpt == 1
                        anaParams405 = [anaParams405; bgPixel];
                    else
                        anaParams405 = [anaParams405; NaN];
                    end
                    if overlapOpt == 1
                        anaParams405 = [anaParams405; overlapThreshold];
                    else
                        anaParams405 = [anaParams405; NaN];
                    end
                    if sizeOpt == 1
                        anaParams405 = [anaParams405; sizeL; sizeU];
                    else
                        anaParams405 = [anaParams405; NaN; NaN];
                    end
                    if isempty(multiThresholds)
                        anaParams405 = [anaParams405; countThreshold];
                    elseif ~isempty(multiThresholds)
                        anaParams405 = [anaParams405; NaN];
                        multi405 = multiThresholds;
                    end
                    msgbx = msgbox('Blue Channel 2D Fit Results Stored.');
                    saveCheck = 1;
                elseif g3DOpt == 1

                    % Perform 3D Surface Calibration
                    if ~isempty(surfaceOpt) && ~isempty(affineOpt) && (surfaceOpt == 1) && (affineOpt == 0)
                        if (channelCheck(1) == 1) && (channelCheck(4) == 1) && ~isempty(surfX_GB) && ~isempty(surfY_GB) && ~isempty(surfZ_GB)
                            for i = 1:size(currentPts,1)
                                currentPts(i,1) = currentPts(i,1) - surfX_GB(currentPts(i,1),currentPts(i,2));
                                currentPts(i,2) = currentPts(i,2) - surfY_GB(currentPts(i,1),currentPts(i,2));
                                currentPts(i,3) = currentPts(i,3) - surfZ_GB(currentPts(i,1),currentPts(i,2));
                            end
                            blueSurfCalTrue = true;
                            disp('3D Blue to Green polynomial surface correction successful.')
                        elseif (channelCheck(1) == 0) && (channelCheck(2) == 1) && (channelCheck(4) == 1) && ~isempty(surfX_RB) && ~isempty(surfY_RB) && ~isempty(surfZ_RB)
                            for i = 1:size(currentPts,1)
                                currentPts(i,1) = currentPts(i,1) - surfX_RB(currentPts(i,1),currentPts(i,2));
                                currentPts(i,2) = currentPts(i,2) - surfY_RB(currentPts(i,1),currentPts(i,2));
                                currentPts(i,3) = currentPts(i,3) - surfZ_RB(currentPts(i,1),currentPts(i,2));
                            end
                            blueSurfCalTrue = true;
                            disp('3D Blue to Red polynomial surface correction successful.')
                        elseif (channelCheck(1) == 0) && (channelCheck(2) == 0) && (channelCheck(3) == 1) && (channelCheck(4) == 1) && ~isempty(surfX_FRB) && ~isempty(surfY_FRB) && ~isempty(surfZ_FRB)
                            for i = 1:size(currentPts,1)
                                currentPts(i,1) = currentPts(i,1) - surfX_FRB(currentPts(i,1),currentPts(i,2));
                                currentPts(i,2) = currentPts(i,2) - surfY_FRB(currentPts(i,1),currentPts(i,2));
                                currentPts(i,3) = currentPts(i,3) - surfY_FRB(currentPts(i,1),currentPts(i,2));
                            end
                            blueSurfCalTrue = true;
                            disp('3D Blue to Far Red polynomial surface correction successful.')
                        else
                            warndlg('Error: Blue Channel 3D polynomial surface calibrations could not be performed.');
                        end
                    % Perform 3D Affine Transform Calibration
                    elseif ~isempty(surfaceOpt) && ~isempty(affineOpt) && (surfaceOpt == 0) && (affineOpt == 1)
                        if (channelCheck(1) == 1) && (channelCheck(4) == 1) && ~isempty(affineBG) && (affineBG.Dimensionality == 3)
                            currentPts(:,1:3) = transformPointsForward(affineBG,currentPts(:,1:3));
                            blueAffineCalTrue = true;
                            disp('3D Blue to Green affine transform correction successful.')
                        elseif (channelCheck(1) == 0) && (channelCheck(2) == 1) && (channelCheck(4) == 1) && ~isempty(affineBR) && (affineBR.Dimensionality == 3)
                            currentPts(:,1:3) = transformPointsForward(affineBR,currentPts(:,1:3));
                            blueAffineCalTrue = true;
                            disp('3D Blue to Red affine transform correction successful.')
                        elseif (channelCheck(1) == 0) && (channelCheck(2) == 0) && (channelCheck(3) == 1) && (channelCheck(4) == 1) && ~isempty(affineBFR) && (affineBFR.Dimensionality == 3)
                            currentPts(:,1:3) = transformPointsForward(affineBFR,currentPts(:,1:3));
                            blueAffineCalTrue = true;
                            disp('3D Blue to Far Red affine transform correction successful.')
                        else
                            warndlg('Error: Blue Channel 3D affine transform calibrations could not be performed.');
                        end
                    end

                    finalFit405 = currentPts;
                    finalPts405 = currentPts(:,1:3);
                    finalBB405 = currentBB;
                    anaParams405 = [];
                    anaParams405 = [anaParams405; bufferPercXY; bufferPercZ];
                    % Save Parameters %
                    if bgOpt == 1
                        anaParams405 = [anaParams405; bgPixel];
                    else
                        anaParams405 = [anaParams405; NaN];
                    end
                    if overlapOpt == 1
                        anaParams405 = [anaParams405; overlapThreshold];
                    else
                        anaParams405 = [anaParams405; NaN];
                    end
                    if sizeOpt == 1
                        anaParams405 = [anaParams405; sizeL; sizeU];
                    else
                        anaParams405 = [anaParams405; NaN; NaN];
                    end
                    if isempty(multiThresholds)
                        anaParams405 = [anaParams405; countThreshold];
                    elseif ~isempty(multiThresholds)
                        anaParams405 = [anaParams405; NaN];
                        multi405 = multiThresholds;
                    end
                    msgbx = msgbox('Blue Channel 3D Fit Results Stored.');
                    saveCheck = 1;
                end                
                finalCentroids405 = currentCentroids;
            end
            bxSettings = findall(msgbx, 'Type','Text');
            set(bxSettings, 'FontSize', 8);
            
        end
        
        function clearCurrentChannel(~,~)
            
            global finalPts488 finalPts594 finalPts640 finalPts405...
                anaParams488 anaParams594 anaParams640 anaParams405... 
                multi488 multi594 multi640 multi405
            
            result = find(nOptions == currentChN);
            
            if result == 1
                finalFit488 = [];
                finalPts488 = [];
                finalBB488 = [];
                anaParams488 = [];
                multi488 = [];
                msgbox('Green Channel Data Cleared.');
            end
            if result == 2
                finalFit594 = [];
                finalPts594 = [];
                finalBB594 = [];
                anaParams594 = [];
                multi594 = [];
                msgbox('Red Channel Data Cleared.');
            end
            if result == 3
                finalFit640 = [];
                finalPts640 = [];
                finalBB640 = [];
                anaParams640 = [];
                multi640 = [];
                msgbox('Far Red Channel Data Cleared.');
            end
            if result == 4
                finalFit405 = [];
                finalPts405 = [];
                finalBB405 = [];
                anaParams405 = [];
                multi405 = [];
                msgbox('Blue Channel Data Cleared.');
            end  
        end
        
        function updateBBSize(~,~)
            
            bufferPercXY = str2double(get(xyBBPerc, 'String'));
            bufferPercZ = str2double(get(zBBPerc, 'String'));
            disp('New Bounding Box Buffers Set');
            disp('.');
            disp(strcat('XY Bounding Box Buffer: ', num2str(bufferPercXY)));
            disp(strcat('Z Bounding Box Buffer: ', num2str(bufferPercZ)));
            disp('.....................................');
        end
        
        function updateSizeFilter(~,~)
            
            sizeL = str2double(get(sizeLower, 'String'));
            sizeU = str2double(get(sizeUpper, 'String'));
            disp('New Size Filter Limits Set');
            disp('.');
            disp(strcat('Upper Size Limit: ', num2str(sizeL)));
            disp(strcat('Lower Size Limit: ', num2str(sizeU)));
            disp('.....................................');
        end
        
        function transferROIs(~,~)
            
            global Ochannel1 Ochannel2 Ochannel3 Ochannel4 fromChoice...
                    toChoice fromFit fromBB fromCentroids transferBuffer...
            
            fromList = {};
            if ~isempty(finalFit488)
                fromList{end+1} = 'Green';
            end
            if ~isempty(finalFit594)
                fromList{end+1} = 'Red';
            end
            if ~isempty(finalFit640)
                fromList{end+1} = 'Far Red';
            end
            if ~isempty(finalFit405)
                fromList{end+1} = 'Blue';
            end
            
            toList = {};
            if isempty(finalFit488) && ~isempty(Ochannel1)
                toList{end+1} = 'Green';
            end
            if isempty(finalFit594) && ~isempty(Ochannel2)
                toList{end+1} = 'Red';
            end
            if isempty(finalFit640) && ~isempty(Ochannel3)
                toList{end+1} = 'Far Red';
            end
            if isempty(finalFit405) && ~isempty(Ochannel4)
                toList{end+1} = 'Blue';
            end
            
            
            if isempty(fromList)
                warndlg('Error: No ROIs to transfer. Please perform analysis and try again.');
                return;
            end
            
            transferFig = figure();
            set(gcf,'NumberTitle','off')
            set(gcf,'Name','ROI Transfer')
            clf;
            set(gcf, 'Position',  [100, 100, 350, 350]);
            set(gcf, 'Resize', 'off');
            transferPan = uibuttongroup('Title','ROI Transfer','FontSize',16,...
                'BackgroundColor',[1,1,1],'FontWeight', 'bold',...
                'Position',[0.05 0.2 .9 .7]);
            
            uicontrol(transferPan,'Style','Text','String','Transfer from:','FontSize',14,...
                'pos',[20 160, 150 30],'BackgroundColor',[1,1,1]);
            uicontrol(transferPan,'Style','Text','String','Transfer to:','FontSize',14,...
                'pos',[7 70, 150 30],'BackgroundColor',[1,1,1]);
            
            fromOptions = uicontrol('Parent', transferPan,'Style','popupmenu','Position',[50,130,200,20],...
                'String', fromList,'FontSize',14,'Callback', {});
            toOptions = uicontrol('Parent', transferPan,'Style','popupmenu','Position',[50,40,200,20],...
                'String', toList,'FontSize',14,'Callback', {});
            
            uicontrol('Parent', transferFig, 'Style', 'pushbutton', 'Position', [200,20,120, 35],...
                'FontSize',12, 'String', 'TRANSFER', 'Callback', {@executeTransfer});
            
            uicontrol('Parent', transferFig,'Style','Text','String','Transfer Buffer:','FontSize',10,...
                'pos',[28,37,120, 25]);
            transferBufferField = uicontrol('Parent', transferFig,'Style','edit','String','0.1','FontSize',13,...
                'pos',[30,21,120, 25], 'BackgroundColor',[1,1,1]);
            
            function executeTransfer(~,~)
                
                fC = fromList(get(fromOptions,'Value'));
                fromChoice = convertCharsToStrings(fC{1});
                tC = toList(get(toOptions,'Value'));
                toChoice = convertCharsToStrings(tC{1});
                
                tempTransf = get(transferBufferField, 'String');
                transferBuffer = str2double(tempTransf);
                
                close(transferFig);
                
                %bgOpt = get(bgCorr, 'Value');
                %bgOpt = 1;
                
                % Storing 'From' Data to Transfer to 'To' Data %
                if fromChoice == 'Green'
                    fromFit = finalFit488;
                    fromBB = finalBB488;
                    fromCentroids = finalCentroids488;
                elseif fromChoice == 'Red'
                    fromFit = finalFit594;
                    fromBB = finalBB594;
                    fromCentroids = finalCentroids594;
                elseif fromChoice == 'Far Red'
                    fromFit = finalFit640;
                    fromBB = finalBB640;
                    fromCentroids = finalCentroids640;
                elseif fromChoice == 'Blue'
                    fromFit = finalFit405;
                    fromBB = finalBB405;
                    fromCentroids = finalCentroids405;
                end
                
                if toChoice == 'Green'
                    trueToChannel = chOptions{1};
                    finalBB488 = fromBB;
                    finalCentroids488 = fromCentroids;
                elseif toChoice == 'Red'
                    trueToChannel = chOptions{2};
                    finalBB594 = fromBB;
                    finalCentroids594 = fromCentroids;
                elseif toChoice == 'Far Red'
                    trueToChannel = chOptions{3};
                    finalBB640 = fromBB;
                    finalCentroids640 = fromCentroids;
                elseif toChoice == 'Blue'
                    trueToChannel = chOptions{4};
                    finalBB405 = fromBB;
                    finalCentroids405 = fromCentroids;
                end
                
                if trueToChannel == 'Channel 1'
                    currentChannel = channel1;
                    currentChN = 1;
                elseif trueToChannel == 'Channel 2'
                    currentChannel = channel2;
                    currentChN = 2;
                elseif trueToChannel == 'Channel 3'
                    currentChannel = channel3;
                    currentChN = 3;
                elseif trueToChannel == 'Channel 4'
                    currentChannel = channel4;
                    currentChN = 4;
                end
                
                if (g2DOpt == 1) || (g3DOpt == 1)
                    
                    % If 3D Gauss Option Chosen %
                    if (nPlanes > 1) && (g2DOpt == 0) && (g3DOpt == 1)
                        disp('3D Gauss Fit for 3D Data Selected.');
                        % Execute 3D Gauss Fit for 3D Data %
                        extractAll3DGaussTransfer();
                    end
                    
                    % If 2D Gauss Option Chosen %
                    if (nPlanes > 1) && (g2DOpt == 1) && (g3DOpt == 0)
                        disp('2D Gauss Fit for 3D Data Selected.');
                        % Execute 2D Gauss Fit for 3D Data %
                        %extractAll2DGauss3DOpt();
                        
                    elseif (nPlanes == 1) && (g2DOpt == 1)
                        disp('2D Gauss Fit for 2D Data Selected.');
                        % Execute 2D Gauss Fit for 2D Data %
                        %extractAll2DGauss();
                    end
                    
                end
                
            end
        end
            
    end

    function chooseNewFile(~,~)

        global fullPath xyRes zRes...
            anaParams488 anaParams594 anaParams640 anaParams405...
        distMatrix488 distMatrix594 distMatrix640 distMatrix405...
        distMatrix488_594 distMatrix488_640 distMatrix488_405...
        distMatrix594_640 distMatrix594_405 distMatrix640_405...
        ab488_594 ab488_640 ab488_405 ab594_640 ab594_405...
        ab640_405 multi488 multi594 multi640 multi405
        
        redSurfCalTrue = false; redAffineCalTrue = false; farRedSurfCalTrue = false;
        farRedAffineCalTrue = false; blueSurfCalTrue = false; blueAffineCalTrue = false;
        
        % User Chooses File %
        clc;
        clearFigure(mainFig);
        if ~isempty(modeChoice) && ((modeChoice == 2) || (modeChoice == 3))
            annotateFigure();
        end
        
        if length(size(currentChannel)) == 3
            delete(h);
        end
        
        xyRes = [];
        zRes = [];
        chOptions = [];
        if exist('a') == 1
            delete(a);
        end
        if exist('b') == 1
            delete(b);
        end
        if exist('c') == 1
            delete(c);
        end
        if exist('d') == 1
            delete(d);
        end

        annotation('textbox', [0.3, 0.3, 0.4, 0.4], 'string', '    NO DATA TO SHOW. CHECK COMMAND WINDOW.','FontSize',22);
        try
            fullPath = importNewData();
        catch
            disp('Error Importing Data.');
            return;
        end

        importAllData(fullPath);
        saveCheck = 0;
        finalFit488 = []; finalBB488 = []; finalFit594 = [];
        finalBB594 = []; finalFit640 = []; finalBB640 = [];
        finalFit405 = []; finalBB405 = [];

        anaParams488 = []; anaParams594  = []; anaParams640  = [];
        anaParams405 = []; distMatrix488  = []; distMatrix594  = [];
        distMatrix640  = []; distMatrix405  = []; distMatrix488_594  = [];
        distMatrix488_640  = []; distMatrix488_405 = []; distMatrix594_640  = [];
        distMatrix594_405  = []; distMatrix640_405 = []; ab488_594  = [];
        ab488_640  = []; ab488_405  = []; ab594_640  = []; ab594_405 = [];
        ab640_405  = []; multiThresholds  = []; multi488  = []; multi594  = [];
        multi640  = []; multi405 = [];

        % Choose Channels and Scaling %
        openSelection();

    end

    function chooseCh1(~,~)
        
        saveCurrentData();
        figure(mainFig);
        zoomObj = get(gca, {'xlim','ylim'});
        thTrue = false;
        gaussFitted = false;
        currentChannel = channel1;
        currentChN = 1;
        saveCheck = 0;
        finalFitParams = [];
        clearFigure(mainFig);
        ax = axes('Parent', mainFig, 'Position', [0.1 0.1 0.8 0.8]);
        imshow(currentChannel(:,:,zSlice), [], 'InitialMagnification', 450);
        set(gca, {'xlim','ylim'}, zoomObj);
        
        % Filter Interval Conditions %
        
        
        ind = find(nOptions == currentChN);
        if (ind == 1) && ~isempty(finalFit488) && ~isempty(finalBB488)
            plotChannelPts(finalFit488, finalBB488);
            currentPts = finalFit488;
            currentBB = finalBB488;
        elseif (ind == 2) && ~isempty(finalFit594) && ~isempty(finalBB594)
            plotChannelPts(finalFit594, finalBB594);
            currentPts = finalFit594;
            currentBB = finalBB594;
        elseif (ind == 3) && ~isempty(finalFit640) && ~isempty(finalBB640)
            plotChannelPts(finalFit640, finalBB640);
            currentPts = finalFit640;
            currentBB = finalBB640;
        elseif (ind == 4) && ~isempty(finalFit405) && ~isempty(finalBB405)
            plotChannelPts(finalFit405, finalBB405);
            currentPts = finalFit405;
            currentBB = finalBB405;
        else
            % Slider Section
            if nPlanes > 1
                try
                    delete(h);
                    delete(anno);
                end
                h = uicontrol('Parent', mainFig,'Style','slider','Position',[viewFigSize(1)*0.775, viewFigSize(2)*0.11,20,600],...
                    'SliderStep', [1/(nPlanes-1) , 10/(nPlanes-1) ],...
                    'value',zSlice, 'min', 1, 'max',nPlanes, 'Callback', {@updateMainIMG});
            end
            anno = annotation('textbox', [0.77, 0.875, 0.025, 0.025], 'string', num2str(zSlice),'FontSize',7.5);
        end
        if ~isempty(modeChoice) && ((modeChoice == 2) || (modeChoice == 3))
            annotateFigure();
        end
        try
            figure(msgbx);
        end
    end

    function chooseCh2(~,~)

        saveCurrentData();
        figure(mainFig);
        zoomObj = get(gca, {'xlim','ylim'});
        thTrue = false;
        gaussFitted = false;
        currentChannel = channel2;
        currentChN = 2;
        saveCheck = 0;
        finalFitParams = [];
        clearFigure(mainFig);
        ax = axes('Parent', mainFig, 'Position', [0.1 0.1 0.8 0.8]);
        imshow(currentChannel(:,:,zSlice), [], 'InitialMagnification', 450);
        set(gca, {'xlim','ylim'}, zoomObj);

        ind = find(nOptions == currentChN);
        if (ind == 1) && ~isempty(finalFit488) && ~isempty(finalBB488)
            plotChannelPts(finalFit488, finalBB488);
            currentPts = finalFit488;
            currentBB = finalBB488;
        elseif (ind == 2) && ~isempty(finalFit594) && ~isempty(finalBB594)
            plotChannelPts(finalFit594, finalBB594);
            currentPts = finalFit594;
            currentBB = finalBB594;
        elseif (ind == 3) && ~isempty(finalFit640) && ~isempty(finalBB640)
            plotChannelPts(finalFit640, finalBB640);
            currentPts = finalFit640;
            currentBB = finalBB640;
        elseif (ind == 4) && ~isempty(finalFit405) && ~isempty(finalBB405)
            plotChannelPts(finalFit405, finalBB405);
            currentPts = finalFit405;
            currentBB = finalBB405;
        else
            % Slider Section
            if nPlanes > 1
                try
                    delete(h);
                    delete(anno);
                end
                h = uicontrol('Parent', mainFig,'Style','slider','Position',[viewFigSize(1)*0.775, viewFigSize(2)*0.11,20,600],...
                    'SliderStep', [1/(nPlanes-1) , 10/(nPlanes-1) ],...
                    'value',zSlice, 'min', 1, 'max',nPlanes, 'Callback', {@updateMainIMG});
            end
            anno = annotation('textbox', [0.77, 0.875, 0.025, 0.025], 'string', num2str(zSlice),'FontSize',7.5); 
        end
        if ~isempty(modeChoice) && ((modeChoice == 2) || (modeChoice == 3))
            annotateFigure();
        end
        try
            figure(msgbx);
        end
    end

    function chooseCh3(~,~)
        
        saveCurrentData();
        figure(mainFig);
        zoomObj = get(gca, {'xlim','ylim'});
        thTrue = false;
        gaussFitted = false;
        currentChannel = channel3;
        currentChN = 3;
        saveCheck = 0;
        finalFitParams = [];
        clearFigure(mainFig);
        ax = axes('Parent', mainFig, 'Position', [0.1 0.1 0.8 0.8]);
        imshow(currentChannel(:,:,zSlice), [], 'InitialMagnification', 450);
        set(gca, {'xlim','ylim'}, zoomObj);
        
        ind = find(nOptions == currentChN);
        if (ind == 1) && ~isempty(finalFit488) && ~isempty(finalBB488)
            plotChannelPts(finalFit488, finalBB488);
            currentPts = finalFit488;
            currentBB = finalBB488;
        elseif (ind == 2) && ~isempty(finalFit594) && ~isempty(finalBB594)
            plotChannelPts(finalFit594, finalBB594);
            currentPts = finalFit594;
            currentBB = finalBB594;
        elseif (ind == 3) && ~isempty(finalFit640) && ~isempty(finalBB640)
            plotChannelPts(finalFit640, finalBB640);
            currentPts = finalFit640;
            currentBB = finalBB640;
        elseif (ind == 4) && ~isempty(finalFit405) && ~isempty(finalBB405)
            plotChannelPts(finalFit405, finalBB405);
            currentPts = finalFit405;
            currentBB = finalBB405;
        else
            % Slider Section
            if nPlanes > 1
                try
                    delete(h);
                    delete(anno);
                end
                h = uicontrol('Parent', mainFig,'Style','slider','Position',[viewFigSize(1)*0.775, viewFigSize(2)*0.11,20,600],...
                    'SliderStep', [1/(nPlanes-1) , 10/(nPlanes-1) ],...
                    'value',zSlice, 'min', 1, 'max',nPlanes, 'Callback', {@updateMainIMG});
            end
            anno = annotation('textbox', [0.77, 0.875, 0.025, 0.025], 'string', num2str(zSlice),'FontSize',7.5);
        end
        if ~isempty(modeChoice) && ((modeChoice == 2) || (modeChoice == 3))
            annotateFigure();
        end
        try
            figure(msgbx);
        end
    end

    function chooseCh4(~,~)
        
        saveCurrentData();
        figure(mainFig);
        zoomObj = get(gca, {'xlim','ylim'});
        thTrue = false;
        gaussFitted = false;
        currentChannel = channel4;
        currentChN = 4;
        saveCheck = 0;
        finalFitParams = [];
        clearFigure(mainFig);
        ax = axes('Parent', mainFig, 'Position', [0.1 0.1 0.8 0.8]);
        imshow(currentChannel(:,:,zSlice), [], 'InitialMagnification', 450);
        set(gca, {'xlim','ylim'}, zoomObj);
        
        ind = find(nOptions == currentChN);
        if (ind == 1) && ~isempty(finalFit488) && ~isempty(finalBB488)
            plotChannelPts(finalFit488, finalBB488);
            currentPts = finalFit488;
            currentBB = finalBB488;
        elseif (ind == 2) && ~isempty(finalFit594) && ~isempty(finalBB594)
            plotChannelPts(finalFit594, finalBB594);
            currentPts = finalFit594;
            currentBB = finalBB594;
        elseif (ind == 3) && ~isempty(finalFit640) && ~isempty(finalBB640)
            plotChannelPts(finalFit640, finalBB640);
            currentPts = finalFit640;
            currentBB = finalBB640;
        elseif (ind == 4) && ~isempty(finalFit405) && ~isempty(finalBB405)
            plotChannelPts(finalFit405, finalBB405);
            currentPts = finalFit405;
            currentBB = finalBB405;
        else
            % Slider Section
            if nPlanes > 1
                try
                    delete(h);
                    delete(anno);
                end
                h = uicontrol('Parent', mainFig,'Style','slider','Position',[viewFigSize(1)*0.775, viewFigSize(2)*0.11,20,600],...
                    'SliderStep', [1/(nPlanes-1) , 10/(nPlanes-1) ],...
                    'value',zSlice, 'min', 1, 'max',nPlanes, 'Callback', {@updateMainIMG});
            end
            anno = annotation('textbox', [0.77, 0.875, 0.025, 0.025], 'string', num2str(zSlice),'FontSize',7.5); 
        end
        if ~isempty(modeChoice) && ((modeChoice == 2) || (modeChoice == 3))
            annotateFigure();
        end
        try
            figure(msgbx);
        end
    end

    function resetZoom(~,~)
    
        mainFig;
        zoomObj = {[0.5 size(currentChannel,2)+0.5] [0.5 size(currentChannel,1)+0.5]};
        set(gca, {'xlim','ylim'}, zoomObj);

    end

    function adjustContrast(~,~)
        
        mainFig;
        imcontrast(mainFig);
        
    end

    function saveCurrentData()
        
        if (saveCheck == 0) && (gaussFitted == true)
            answer = questdlg('Would you like to save results for current channel?', ...
                'Save Channel Data', ...
                'Yes','No','Yes');
            % Handle response
            switch answer
                case 'Yes'
                    saveData2();
                    saveCheck = 1;
                case 'No'
            end
        end
    end

    function saveData2()
            
            global finalPts488 finalPts594...
                finalPts640 finalPts405 anaParams488 anaParams594...
                anaParams640 anaParams405 countThreshold multi488...
                multi594 multi640 multi405 bufferPercXY bufferPercZ
            
            result = find(nOptions == currentChN);
            
            if result == 1
                if g2DOpt == 1
                    finalFit488 = currentPts;
                    finalPts488 = currentPts(:,1:2);
                    finalBB488 = currentBB;
                    anaParams488 = [];
                    anaParams488 = [anaParams488; bufferPercXY];
                    % Save Parameters %
                    if bgOpt == 1
                        anaParams488 = [anaParams488; bgPixel];
                    else
                        anaParams488 = [anaParams488; NaN];
                    end
                    if overlapOpt == 1
                        anaParams488 = [anaParams488; overlapThreshold];
                    else
                        anaParams488 = [anaParams488; NaN];
                    end
                    if sizeOpt == 1
                        anaParams488 = [anaParams488; sizeL; sizeU];
                    else
                        anaParams488 = [anaParams488; NaN; NaN];
                    end
                    if isempty(multiThresholds)
                        anaParams488 = [anaParams488; countThreshold];
                    elseif ~isempty(multiThresholds)
                        anaParams488 = [anaParams488; NaN];
                        multi488 = multiThresholds;
                    end
                    msgbx = msgbox('Green Channel 2D Fit Results Stored.');
                elseif g3DOpt == 1
                    finalFit488 = currentPts;
                    finalPts488 = currentPts(:,1:3);
                    finalBB488 = currentBB;
                    anaParams488 = [];
                    anaParams488 = [anaParams488; bufferPercXY; bufferPercZ];
                    % Save Parameters %
                    if bgOpt == 1
                        anaParams488 = [anaParams488; bgPixel];
                    else
                        anaParams488 = [anaParams488; NaN];
                    end
                    if overlapOpt == 1
                        anaParams488 = [anaParams488; overlapThreshold];
                    else
                        anaParams488 = [anaParams488; NaN];
                    end
                    if sizeOpt == 1
                        anaParams488 = [anaParams488; sizeL; sizeU];
                    else
                        anaParams488 = [anaParams488; NaN; NaN];
                    end
                    if isempty(multiThresholds)
                        anaParams488 = [anaParams488; countThreshold];
                    elseif ~isempty(multiThresholds)
                        anaParams488 = [anaParams488; NaN];
                        multi488 = multiThresholds;
                    end
                    msgbx = msgbox('Green Channel 3D Fit Results Stored.');
                end
            end
            if result == 2
                if g2DOpt == 1
                    finalFit594 = currentPts;
                    finalPts594 = currentPts(:,1:2);
                    finalBB594 = currentBB;
                    anaParams594 = [];
                    anaParams594 = [anaParams594; bufferPercXY];
                    % Save Parameters %
                    if bgOpt == 1
                        anaParams594 = [anaParams594; bgPixel];
                    else
                        anaParams594 = [anaParams594; NaN];
                    end
                    if overlapOpt == 1
                        anaParams594 = [anaParams594; overlapThreshold];
                    else
                        anaParams594 = [anaParams594; NaN];
                    end
                    if sizeOpt == 1
                        anaParams594 = [anaParams594; sizeL; sizeU];
                    else
                        anaParams594 = [anaParams594; NaN; NaN];
                    end
                    if isempty(multiThresholds)
                        anaParams594 = [anaParams594; countThreshold];
                    elseif ~isempty(multiThresholds)
                        anaParams594 = [anaParams594; NaN];
                        multi594 = multiThresholds;
                    end
                    msgbx = msgbox('Red Channel 2D Fit Results Stored.');
                elseif g3DOpt == 1
                    finalFit594 = currentPts;
                    finalPts594 = currentPts(:,1:3);
                    finalBB594 = currentBB;
                    anaParams594 = [];
                    anaParams594 = [anaParams594; bufferPercXY; bufferPercZ];
                    % Save Parameters %
                    if bgOpt == 1
                        anaParams594 = [anaParams594; bgPixel];
                    else
                        anaParams594 = [anaParams594; NaN];
                    end
                    if overlapOpt == 1
                        anaParams594 = [anaParams594; overlapThreshold];
                    else
                        anaParams594 = [anaParams594; NaN];
                    end
                    if sizeOpt == 1
                        anaParams594 = [anaParams594; sizeL; sizeU];
                    else
                        anaParams594 = [anaParams594; NaN; NaN];
                    end
                    if isempty(multiThresholds)
                        anaParams594 = [anaParams594; countThreshold];
                    elseif ~isempty(multiThresholds)
                        anaParams594 = [anaParams594; NaN];
                        multi594 = multiThresholds;
                    end
                    msgbx = msgbox('Red Channel 3D Fit Results Stored.');
                end
            end
            if result == 3
                if g2DOpt == 1
                    finalFit640 = currentPts;
                    finalPts640 = currentPts(:,1:2);
                    finalBB640 = currentBB;
                    anaParams640 = [];
                    anaParams640 = [anaParams640; bufferPercXY];
                    % Save Parameters %
                    if bgOpt == 1
                        anaParams640 = [anaParams640; bgPixel];
                    else
                        anaParams640 = [anaParams640; NaN];
                    end
                    if overlapOpt == 1
                        anaParams640 = [anaParams640; overlapThreshold];
                    else
                        anaParams640 = [anaParams640; NaN];
                    end
                    if sizeOpt == 1
                        anaParams640 = [anaParams640; sizeL; sizeU];
                    else
                        anaParams640 = [anaParams640; NaN; NaN];
                    end
                    if isempty(multiThresholds)
                        anaParams640 = [anaParams640; countThreshold];
                    elseif ~isempty(multiThresholds)
                        anaParams640 = [anaParams640; NaN];
                        multi640 = multiThresholds;
                    end
                    msgbx = msgbox('Far Red Channel 2D Fit Results Stored.');
                elseif g3DOpt == 1
                    finalFit640 = currentPts;
                    finalPts640 = currentPts(:,1:3);
                    finalBB640 = currentBB;
                    anaParams640 = [];
                    anaParams640 = [anaParams640; bufferPercXY; bufferPercZ];
                    % Save Parameters %
                    if bgOpt == 1
                        anaParams640 = [anaParams640; bgPixel];
                    else
                        anaParams640 = [anaParams640; NaN];
                    end
                    if overlapOpt == 1
                        anaParams640 = [anaParams640; overlapThreshold];
                    else
                        anaParams640 = [anaParams640; NaN];
                    end
                    if sizeOpt == 1
                        anaParams640 = [anaParams640; sizeL; sizeU];
                    else
                        anaParams640 = [anaParams640; NaN; NaN];
                    end
                    if isempty(multiThresholds)
                        anaParams640 = [anaParams640; countThreshold];
                    elseif ~isempty(multiThresholds)
                        anaParams640 = [anaParams640; NaN];
                        multi640 = multiThresholds;
                    end
                    msgbx = msgbox('Far Red Channel 3D Fit Results Stored.');
                end
            end
            if result == 4
                if g2DOpt == 1
                    finalFit405 = currentPts;
                    finalPts405 = currentPts(:,1:2);
                    finalBB405 = currentBB;
                    anaParams405 = [];
                    anaParams405 = [anaParams405; bufferPercXY];
                    % Save Parameters %
                    if bgOpt == 1
                        anaParams405 = [anaParams405; bgPixel];
                    else
                        anaParams405 = [anaParams405; NaN];
                    end
                    if overlapOpt == 1
                        anaParams405 = [anaParams405; overlapThreshold];
                    else
                        anaParams405 = [anaParams405; NaN];
                    end
                    if sizeOpt == 1
                        anaParams405 = [anaParams405; sizeL; sizeU];
                    else
                        anaParams405 = [anaParams405; NaN; NaN];
                    end
                    if isempty(multiThresholds)
                        anaParams405 = [anaParams405; countThreshold];
                    elseif ~isempty(multiThresholds)
                        anaParams405 = [anaParams405; NaN];
                        multi405 = multiThresholds;
                    end
                    msgbx = msgbox('Blue Channel 2D Fit Results Stored.');
                elseif g3DOpt == 1
                    finalFit405 = currentPts;
                    finalPts405 = currentPts(:,1:3);
                    finalBB405 = currentBB;
                    anaParams405 = [];
                    anaParams405 = [anaParams405; bufferPercXY; bufferPercZ];
                    % Save Parameters %
                    if bgOpt == 1
                        anaParams405 = [anaParams405; bgPixel];
                    else
                        anaParams405 = [anaParams405; NaN];
                    end
                    if overlapOpt == 1
                        anaParams405 = [anaParams405; overlapThreshold];
                    else
                        anaParams405 = [anaParams405; NaN];
                    end
                    if sizeOpt == 1
                        anaParams405 = [anaParams405; sizeL; sizeU];
                    else
                        anaParams405 = [anaParams405; NaN; NaN];
                    end
                    if isempty(multiThresholds)
                        anaParams405 = [anaParams405; countThreshold];
                    elseif ~isempty(multiThresholds)
                        anaParams405 = [anaParams405; NaN];
                        multi405 = multiThresholds;
                    end
                    msgbx = msgbox('Blue Channel 3D Fit Results Stored.');
                end
            end
            bxSettings = findall(msgbx, 'Type','Text');
            set(bxSettings, 'FontSize', 8);
        end

end

%%
function updateFittedIMG()

    global mainFig currentChannel zSlice zoomObj modeChoice nPlanes...
        viewFigSize h anno

    clearFigure(mainFig);
    ax = axes('Parent', mainFig, 'Position', [0.1 0.1 0.8 0.8]);
    imshow(currentChannel(:,:,zSlice), [], 'InitialMagnification', 450);
    set(gca, {'xlim','ylim'}, zoomObj);

    if ~isempty(modeChoice) && ((modeChoice == 2) || (modeChoice == 3))
        annotateFigure();
    end

    % Slider Section
    if nPlanes > 1
        try
            delete(h);
            delete(anno);
        end
        h = uicontrol('Parent', mainFig,'Style','slider','Position',[viewFigSize(1)*0.775, viewFigSize(2)*0.11,20,600],...
            'SliderStep', [1/(nPlanes-1) , 10/(nPlanes-1) ],...
            'value',zSlice, 'min', 1, 'max',nPlanes, 'Callback', {@updateFittedIMG2});
    end
    anno = annotation('textbox', [0.77, 0.875, 0.025, 0.025], 'string', num2str(zSlice),'FontSize',7.5);

end

function updateFittedIMG2(~,~)

    global mainFig currentChannel zSlice zoomObj modeChoice nPlanes...
         h anno

    mainFig;
    zoomObj = get(gca, {'xlim','ylim'});
    zSlice = round(get(h, 'Value'));
    clearFigure(mainFig);
    ax = axes('Parent', mainFig, 'Position', [0.1 0.1 0.8 0.8]);
    imshow(currentChannel(:,:,zSlice), [], 'InitialMagnification', 450);
    set(gca, {'xlim','ylim'}, zoomObj);
    if ~isempty(modeChoice) && ((modeChoice == 2) || (modeChoice == 3))
        annotateFigure();
    end
    anno = annotation('textbox', [0.77, 0.875, 0.025, 0.025], 'string', num2str(zSlice),'FontSize',7.5);
    hold on;

    sizeCurrent = size(currentPts);
    sizeFinalFit = size(finalFitParams);

    % Plot Bounding Boxes of Current Points %
    for m = 1:sizeFinalFit(1)

        if ~ismember(m,excludePts)
            boxPlot(1,:) = [boxLimits(m,1), boxLimits(m,3)];
            boxPlot(4,:) = [boxLimits(m,2), boxLimits(m,3)];
            boxPlot(2,:) = [boxLimits(m,1), boxLimits(m,4)];
            boxPlot(3,:) = [boxLimits(m,2), boxLimits(m,4)];
            boxPlot(5,:) = [boxLimits(m,1), boxLimits(m,3)];
            mainFig;
            hold on;
            if (g3DOpt == 1) && (zSlice >= boxLimits(m,5)+0.5) && (zSlice <= boxLimits(m,6)-0.5)
                plot(boxPlot(:,1), boxPlot(:,2), '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 0.6 1], 'LineWidth', 1.0, 'Clipping', 'on');
                plot(currentPts(m,1)/xyRes + 0.5, currentPts(m,2)/xyRes + 0.5, '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 1 0.6], 'LineWidth', 1.0, 'Clipping', 'on');
                text(currentPts(m,1)/xyRes + 0.5 + 2.5, currentPts(m,2)/xyRes + 0.5 + 2, num2str(m), 'Fontsize', 8, 'Color', 'r', 'fontweight', 'bold', 'Clipping', 'on');
            elseif (g2DOpt == 1) && (nPlanes > 1) && (currentCentroids(m,3) == zSlice)
                plot(boxPlot(:,1), boxPlot(:,2), '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 0.6 1], 'LineWidth', 1.0, 'Clipping', 'on');
                plot(currentPts(m,1)/xyRes + 0.5, currentPts(m,2)/xyRes + 0.5, '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 1 0.6], 'LineWidth', 1.0, 'Clipping', 'on');
                text(currentPts(m,1)/xyRes + 0.5 + 2.5, currentPts(m,2)/xyRes + 0.5 + 2, num2str(m), 'Fontsize', 8, 'Color', 'r', 'fontweight', 'bold', 'Clipping', 'on');
            elseif (g2DOpt == 1) && (nPlanes == 1)
                plot(boxPlot(:,1), boxPlot(:,2), '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 0.6 1], 'LineWidth', 1.0, 'Clipping', 'on');
                plot(currentPts(m,1)/xyRes + 0.5, currentPts(m,2)/xyRes + 0.5, '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 1 0.6], 'LineWidth', 1.0, 'Clipping', 'on');
                text(currentPts(m,1)/xyRes + 0.5 + 2.5, currentPts(m,2)/xyRes + 0.5 + 2, num2str(m), 'Fontsize', 8, 'Color', 'r', 'fontweight', 'bold', 'Clipping', 'on');
            end
        end
    end

end

function clearFigure(clearFig)

    delTags = {'Line','Text','Image', 'Axes'};
    for j = 1:length(delTags)
        delete(findobj(clearFig, 'Type', delTags{j}));
    end
    delete(findall(gcf,'type','annotation'))

end

function clearParticleN(clearFig)

    delTags = {'Line','Text'};
    for j = 1:length(delTags)
        delete(findobj(clearFig, 'Type', delTags{j}));
    end
    delete(findall(gcf,'type','annotation'))

end

%%

function [Ibw] = binarizeIMG(channel1, filtInterval, countThreshold, val)

    if val == 1
        disp(strcat('Threshold Value: ', num2str(round(countThreshold,2,'decimals'))));
    end
    % Histogram-Based Thresholding
    histEdges = [0:filtInterval:max(max(max(channel1)))];
    [counts] = histcounts(channel1, histEdges);
    meanCounts = mean(counts);
    stdCounts = std(counts);
    tick = 1;
    
    while stdCounts >= countThreshold*meanCounts
        if tick < size(histEdges,2)
            tick = tick + 1;
            meanCounts = mean(counts(tick:length(counts)));
            stdCounts = std(counts(tick:length(counts)));
        elseif tick > size(histEdges,2)
            disp('Error. Choose another threshold value!');
            return;
        end
    end

    if isempty(stdCounts) || isempty(meanCounts)
        disp('Error. Choose another threshold value!');
        return;
    else
        finalEdge = histEdges(tick);
        Ibw = imbinarize(channel1, finalEdge);
    end
    
end

%%

function getCentroids(Ibw, val)

    global  sizeCentroids bbCentroids pxlCentroids trueCentroids imgSize...
        
    
    sizeL = 1;
    sizeU = max(imgSize);
    if val == 1
        disp('.');
        disp('Detecting Particle(s)...');
    end
    
    if max(size(size(Ibw))) == 3
        totalSize = size(Ibw,1)*size(Ibw,2)*size(Ibw,3);
    elseif max(size(size(Ibw))) == 2
        totalSize = size(Ibw,1)*size(Ibw,2);
    end
    
    sumVals = sum(sum(sum(Ibw)));
    
    % Identify Clusters with Coordinates
    if (sumVals/totalSize) >= 0.7
        warndlg('Error: Image Too Saturated!  Please Choose Another Threshold.');
        disp('Error: Saturation Limit at Current Threshold');
        disp('***************************************************************');
        error('Saturation Limit at Current Threshold!')
    else
        centroids = regionprops(Ibw, 'centroid');
    end
    
    
    sizeCentroids = size(centroids);
    bbSizes = regionprops(Ibw, 'BoundingBox');
    
    if sizeCentroids(1) == 0
        
        if val == 1
            disp('No Particles Detected.');
            disp('*********************************************************************');
            return;
        end
        
    elseif sizeCentroids(1) >= 1
        
        % If 3D Data %
        if length(size(Ibw)) == 3
            trueCentroids = zeros(sizeCentroids(1),3);
            pxlCentroids = zeros(sizeCentroids(1),3);
            bbCentroids = zeros(sizeCentroids(1),6);
            
            for i = 1:sizeCentroids(1)
                trueCentroids(i,1) = centroids(i).Centroid(1);
                trueCentroids(i,2) = centroids(i).Centroid(2);
                trueCentroids(i,3) = centroids(i).Centroid(3);
                
                pxlCentroids(i,1) = round(centroids(i).Centroid(1));
                pxlCentroids(i,2) = round(centroids(i).Centroid(2));
                pxlCentroids(i,3) = round(centroids(i).Centroid(3));
                
                bbCentroids(i,1) = floor(bbSizes(i).BoundingBox(1));
                if bbCentroids(i,1) == 0
                    bbCentroids(i,1) = 1;
                end
                bbCentroids(i,2) = floor(bbSizes(i).BoundingBox(2));
                if bbCentroids(i,2) == 0
                    bbCentroids(i,2) = 1;
                end
                bbCentroids(i,3) = floor(bbSizes(i).BoundingBox(3));
                if bbCentroids(i,3) == 0
                    bbCentroids(i,3) = 1;
                end
                bbCentroids(i,4) = bbSizes(i).BoundingBox(4);
                bbCentroids(i,5) = bbSizes(i).BoundingBox(5);
                bbCentroids(i,6) = bbSizes(i).BoundingBox(6);
            end
            
            rows = find((bbCentroids(:,4) > sizeL) & (bbCentroids(:,5) > sizeL) & (bbCentroids(:,6) > sizeL) &...
                    (bbCentroids(:,4) < sizeU) & (bbCentroids(:,5) < sizeU));
            trueCentroids = trueCentroids(rows,:);    
            pxlCentroids = pxlCentroids(rows,:);  
            bbCentroids = bbCentroids(rows,:);  

        % If 2D Data %
        elseif length(size(Ibw)) == 2
            
            trueCentroids = zeros(sizeCentroids(1),2);
            pxlCentroids = zeros(sizeCentroids(1),2);
            bbCentroids = zeros(sizeCentroids(1),4);
            
            for i = 1:sizeCentroids(1)
                trueCentroids(i,1) = centroids(i).Centroid(1);
                trueCentroids(i,2) = centroids(i).Centroid(2);
                
                pxlCentroids(i,1) = round(centroids(i).Centroid(1));
                pxlCentroids(i,2) = round(centroids(i).Centroid(2));
                
                bbCentroids(i,1) = floor(bbSizes(i).BoundingBox(1));
                if bbCentroids(i,1) == 0
                    bbCentroids(i,1) = 1;
                end
                bbCentroids(i,2) = floor(bbSizes(i).BoundingBox(2));
                if bbCentroids(i,2) == 0
                    bbCentroids(i,2) = 1;
                end
                bbCentroids(i,3) = bbSizes(i).BoundingBox(3);
                bbCentroids(i,4) = bbSizes(i).BoundingBox(4);
            end
            
            rows = find((bbCentroids(:,3) > sizeL) & (bbCentroids(:,4) & sizeL) &...
                    (bbCentroids(:,3) < sizeU) & (bbCentroids(:,4) < sizeU) );
            trueCentroids = trueCentroids(rows,:);    
            pxlCentroids = pxlCentroids(rows,:);  
            bbCentroids = bbCentroids(rows,:);  
            
        end
        
        sizeCentroids = size(trueCentroids,1);
        if val == 1
            disp('Particles Successfully Detected.');
            disp('.');
            disp(strcat('Number of Particles Detected: ', num2str(sizeCentroids(1))));
            disp('........................');
        end
    end

end

%%


function extractTotalCentroids()

    global  currentChannel filtInterval countThreshold currentMaxIMG...
            viewCentroids sizeCentroids centroidFig trueCentroids...
            nPlanes pxlCentroids
        
    if isempty(countThreshold)
        disp('Error: No Threshold Value Chosen!');
        return;
    end
    tic
    
    powerN = max(ceil(log10(abs(max(max(max(currentChannel)))))),1);
    if ((powerN-4) <= 0) || ((powerN-4) == 1) 
        filtInterval = 10;
    else
        filtInterval = 10^(powerN-4);
    end
    
    [Ibw] = binarizeIMG(currentChannel, filtInterval, countThreshold, 1);
     getCentroids(Ibw,1);
    
    currentMaxIMG = max(currentChannel, [], 3);

    if sizeCentroids(1) >= 1
        if viewCentroids == true
            centroidFig = figure();
            clf;
            set(gcf, 'Position',  [100, 100, 1300, 700])   % Set larger viewing size
            hold on;
            subplot(1,2,1);
            imshow(currentMaxIMG, [], 'InitialMagnification', 400);
            title('Max Z Projection', 'FontSize', 14);
            xlabel('Calculated Centroids')
            hold on;
            for i = 1:sizeCentroids(1)
                plot(trueCentroids(i,1), trueCentroids(i,2), '-s', 'MarkerSize', 6, 'MarkerEdgeColor', 'red', 'MarkerFaceColor', [1 0.6 0.6]);
            end

            % View Calculated Centroids by Z Slice %

            disp('Displaying Detected Particles....');
            disp('.');
            disp('.');
            for i = 1:nPlanes

                centroidFig;
                subplot(1,2,2);
                imshow(currentChannel(:,:,i), [], 'InitialMagnification', 400);
                title('Z Slice Display', 'FontSize', 14);
                xlabel(strcat('Z Slice = ', num2str(i)));
                hold on;

                if sum(pxlCentroids(:,3) == i) >= 1
                    tempZ = find(pxlCentroids(:,3) == i);
                    nZ = length(tempZ);
                    for j = 1:nZ
                        % Light Up Red - Z Stack %
                        subplot(1,2,2);
                        plot(trueCentroids(tempZ(j),1), trueCentroids(tempZ(j),2), '-s', 'MarkerSize', 8, 'MarkerEdgeColor', 'red', 'MarkerFaceColor', [1 0.6 0.6]);
                        % Light Up Green - Max Z %
                        subplot(1,2,1);
                        plot(trueCentroids(tempZ(j),1), trueCentroids(tempZ(j),2), '-s', 'MarkerSize', 7, 'MarkerEdgeColor', 'green', 'MarkerFaceColor', [0.6 1 0.6]);
                        hold on;
                        % Numbering Particles
                        text(trueCentroids(tempZ(j),1)+2, trueCentroids(tempZ(j),2)+1.5, num2str(tempZ(j)), 'Fontsize', 8, 'Color', 'r', 'fontweight', 'bold');
                    end
                end
                pause(0.05)
            end
            disp('DISPLAY COMPLETE.');
            disp('*********************************************************************');
        end
    end
    toc
end

%%
function chooseThresholdUI()

    global  sizeCentroids trueCentroids countThreshold...
            currentMaxIMG currentIMG mainFig thTrue viewFigSize...
            startThreshold currentChannel m1 m2 channel1 channel2...
            channel3 channel4 currentChN zSlice nPlanes h4
    
    thTrue = false;
    
    disp('.');
    disp('PARTICLE THRESHOLDING');
    disp('Tips:');
    disp('	- Drag slider at bottom of figure to adjust threshold.');
    disp('	- (or) enter threshold value in *Manual Threshold* field.');
    disp('	- Particles will be automatically detected and updated.');
    disp('	- Use the (+) & (-) buttons on the top right of figure and mouse scroller to zoom.');
    disp('	- After deciding on threshold, choose "SET THRESHOLD" ');
    disp('...............................................................................');
        
    mainFig;
    
    set(gcf, 'Resize', 'off');
    ax = axes('Parent', mainFig, 'Position', [0.1 0.1 0.8 0.8]);
    currentIMG = imshow(currentChannel(:,:,zSlice), [], 'InitialMagnification', 450);
    hold on;
    for i = 1:sizeCentroids(1)
        [bb, bbPts, boxPlot] = extractBoundBox2(i, currentChannel);
        % For Visualization %
        if (zSlice >= bbPts(3,1)) && (zSlice <= bbPts(3,2))
            plot(boxPlot(:,1), boxPlot(:,2), '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 0.6 1], 'LineWidth', 1.0, 'Clipping', 'on');
            plot(trueCentroids(i,1), trueCentroids(i,2), '-s', 'MarkerSize', 4, 'MarkerEdgeColor', 'green', 'MarkerFaceColor', [0.6 1 0.6], 'Clipping', 'on');
            text(trueCentroids(i,1)+2, trueCentroids(i,2)+1.5, num2str(i), 'Fontsize', 8, 'Color', 'r', 'fontweight', 'bold', 'Clipping', 'on');
        end
    end
    
    h2 = uicontrol('Parent', mainFig,'Style','slider','Position',[viewFigSize(1)*0.275, viewFigSize(2)*0.06,viewFigSize(1)*0.45,20],...
                  'value',countThreshold, 'min',0.2, 'max',7.5, 'Callback', {@getThreshold});
    b2 = uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.453, viewFigSize(2)*0.015,viewFigSize(1)*0.1, 30],...
                  'String', 'SET THRESHOLD', 'BackgroundColor',[0.7,1,0.7], 'Callback', {@setThreshold});
    anno3 = annotation('textbox', [0.28, 0.89, 0.1, 0.1], 'string', 'CHOOSE THRESHOLD FOR PARTICLE DETECTION',...
                  'fontweight', 'bold', 'FontSize', 16, 'EdgeColor', 'none');
              
              if nPlanes > 1
                  try
                      delete(h);
                      delete(anno4);
                  end
                  h4 = uicontrol('Parent', mainFig,'Style','slider','Position',[viewFigSize(1)*0.775, viewFigSize(2)*0.11,20,600],...
                      'SliderStep', [1/(nPlanes-1) , 10/(nPlanes-1) ],...
                      'value',zSlice, 'min', 1, 'max',nPlanes, 'Callback', {@updateThresholdUI2});
              end
              anno4 = annotation('textbox', [0.77, 0.875, 0.025, 0.025], 'string', num2str(zSlice),'FontSize',7.5);
    
    % Manual Threshold Field %
    threshField = uicontrol(mainFig,'Style','edit','String',num2str(countThreshold),'FontSize',8,...
                    'pos', [viewFigSize(1)*0.64, viewFigSize(2)*0.018,viewFigSize(1)*0.055, 20], 'BackgroundColor',[1,1,1]);    
    b3 = uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.705, viewFigSize(2)*0.02,viewFigSize(1)*0.09, 20],...
                  'String', 'Manual Threshold', 'BackgroundColor',[0.8,0.8,0.8], 'Callback', {@manualThreshold});  
          
    % Multi Thresholding 
    b4 = uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.205, viewFigSize(2)*0.02,viewFigSize(1)*0.09, 20],...
                  'String', 'Multi-Thresholding', 'BackgroundColor',[0.7,1,1], 'Callback', {@multiThreshold});  

    function multiThreshold(~,~)
        
        global  multiThresholds multiSizeCentroids multiBBCentroids...
                multiPxlCentroids multiTrueCentroids...
                bbCentroids pxlCentroids zoomObj
            
        multiThresholds = [];
        multiSizeCentroids = [];
        multiBBCentroids = [];
        multiPxlCentroids = [];
        multiTrueCentroids = [];
        delete(b2);
        delete(b4);
        % Multi Thresholding Function Chosen
        b5 = uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.205, viewFigSize(2)*0.02,viewFigSize(1)*0.09, 20],...
            'String', 'Finish Thresholding', 'BackgroundColor',[1,0.4,0.7], 'Callback', {@finishThreshold});
        
        m1 = uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.445, viewFigSize(2)*0.015,viewFigSize(1)*0.11, 30],...
            'String', 'COMMIT THRESHOLD', 'BackgroundColor',[0.7,1,0.7], 'Callback', {@commitThreshold});
        m2 = uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.3, viewFigSize(2)*0.02,viewFigSize(1)*0.06, 20],...
            'String', 'Multi-Preset', 'BackgroundColor',[0.8,0.8,0.8], 'Callback', {});
        
        disp('.');
        disp('MULTI-THRESHOLDING');
        disp('Tips:');
        disp('	- Drag slider at bottom of figure to adjust threshold.');
        disp('	- (or) enter threshold value in *Manual Threshold* field.');
        disp('	- Particles will be automatically detected and updated.');
        disp('	- Use the (+) & (-) buttons on the top right of figure and mouse scroller to zoom.');
        disp('	- After deciding on threshold, choose "COMMIT THRESHOLD" for further thresholding.');
        disp('	- After committing desired multi-thresholds, choose *Finish Thresholding* for fitting.');
        disp('...............................................................................');
        
        function commitThreshold(~,~)
            
            multiSizeCentroids = [multiSizeCentroids; sizeCentroids];
            multiBBCentroids = [multiBBCentroids; bbCentroids];
            multiPxlCentroids = [multiPxlCentroids; pxlCentroids];
            multiTrueCentroids = [multiTrueCentroids; trueCentroids];
            multiThresholds = [multiThresholds; countThreshold];
            
            disp('Committing currently detected points...');
            for i = 1:size(bbCentroids,1)  
                [bb, bbPts, boxPlot] = extractBoundBox2(i, currentChannel);
                if size(bbPts,1) == 2
                    currentChannel(bbPts(2,1):bbPts(2,2), bbPts(1,1):bbPts(1,2)) = 0;
                elseif size(bbPts,1) == 3
                    currentChannel(bbPts(2,1):bbPts(2,2), bbPts(1,1):bbPts(1,2), bbPts(3,1):bbPts(3,2)) = 0;
                end
                if mod(i,5) == 0
                    perc = 100*i/size(bbCentroids,1);
                    str1 = strcat(num2str(round(perc,1,'decimals')),'%');
                    disp(strcat('Current Progress:',str1));
                end
            end
            disp('Point Commitment Complete.');
            
            disp('Updating Visual Figure...');
            zoomObj = get(gca, {'xlim','ylim'});
            mainFig;
            clearFigure(mainFig);
            annotateFigure();
            axes('Parent', mainFig, 'Position', [0.1 0.1 0.8 0.8]);
            currentIMG = imshow(currentChannel(:,:,zSlice), [], 'InitialMagnification', 450);
            set(gca, {'xlim','ylim'}, zoomObj);
            disp('Visual Figure Updated.');
            disp('..................................');
            
        end
        
        function finishThreshold(~,~)
        
            delete(h2);
            delete(b5);
            delete(m1);
            delete(m2);
            delete(threshField);
            delete(b3);
            disp('Compiling Committed Points...');
            sizeCentroids = sum(multiSizeCentroids);
            bbCentroids = multiBBCentroids;
            pxlCentroids = multiPxlCentroids;
            trueCentroids = multiTrueCentroids;
            if currentChN == 1
                currentChannel = channel1;
            elseif currentChN == 2
                currentChannel = channel2;
            elseif currentChN == 3
                currentChannel = channel3;
            elseif currentChN == 4
                currentChannel = channel4;
            end
            zoomObj = get(gca, {'xlim','ylim'});
            mainFig;
            clearFigure(mainFig);
            annotateFigure();
            axes('Parent', mainFig, 'Position', [0.1 0.1 0.8 0.8]);
            set(gca, {'xlim','ylim'}, zoomObj);
            hold on;
            disp('Updating Visual Figure...');
            
            anno4 = annotation('textbox', [0.77, 0.875, 0.025, 0.025], 'string', num2str(zSlice),'FontSize',7.5);
            
            currentIMG = imshow(currentChannel(:,:,zSlice), [], 'InitialMagnification', 450);
            
            if nPlanes > 1
                try
                    delete(h);
                    delete(anno4);
                end
                h4 = uicontrol('Parent', mainFig,'Style','slider','Position',[viewFigSize(1)*0.775, viewFigSize(2)*0.11,20,600],...
                    'SliderStep', [1/(nPlanes-1) , 10/(nPlanes-1) ],...
                    'value',zSlice, 'min', 1, 'max',nPlanes, 'Callback', {@updateThresholdUI3});
            end
            anno4 = annotation('textbox', [0.77, 0.875, 0.025, 0.025], 'string', num2str(zSlice),'FontSize',7.5);
            for i = 1:sizeCentroids(1)
                [bb, bbPts, boxPlot] = extractBoundBox3(i, currentChannel);
                % For Visualization %
                if (zSlice >= bbPts(3,1)) && (zSlice <= bbPts(3,2))
                    plot(boxPlot(:,1), boxPlot(:,2), '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 0.6 1], 'LineWidth', 1.0, 'Clipping', 'on');
                    plot(trueCentroids(i,1), trueCentroids(i,2), '-s', 'MarkerSize', 4, 'MarkerEdgeColor', 'green', 'MarkerFaceColor', [0.6 1 0.6], 'Clipping', 'on');
                    text(trueCentroids(i,1)+2, trueCentroids(i,2)+1.5, num2str(i), 'Fontsize', 8, 'Color', 'r', 'fontweight', 'bold', 'Clipping', 'on'); 
                end
                if mod(i,5) == 0
                    perc = 100*i/sizeCentroids(1);
                    str1 = strcat(num2str(round(perc,1,'decimals')),'%');
                    disp(strcat('Current Progress:',str1));
                end
            end
            
            thTrue = true;
            disp('Visual Figure Updated.');
            disp('..................................');
        end
        
    end

    function manualThreshold(~,~)
        global zoomObj
        zoomObj = get(gca, {'xlim','ylim'});
        newThreshold = str2double(get(threshField, 'String'));
        if isnumeric(newThreshold) && ~isnan(newThreshold)
            if newThreshold >= 10
                warndlg('Error.  Threshold Value Too High!');
                return;
            end
            countThreshold = newThreshold;
            delete(h2);
            h2 = uicontrol('Parent', mainFig,'Style','slider','Position',[viewFigSize(1)*0.275, viewFigSize(2)*0.06,viewFigSize(1)*0.45,20],...
                  'value',countThreshold, 'min',0.2, 'max',5, 'Callback', {@getThreshold});
            clearParticleN(mainFig);
            updateThresholdUI();
        else
            warndlg('Error.  Please enter numeric value.');
            return;
        end
    end

    function setThreshold(~,~)
        
        delete(h2);
        delete(b2);
        delete(anno3);
        delete(threshField);
        delete(b3);
        delete(b4)
        thTrue = true;
        disp(strcat('Final Threshold Set: ', num2str(countThreshold)));
        try
            delete(h2);
        end
        try
            delete(b2);
        end
        try
            delete(anno3);
        end
        try
            delete(threshField);
        end
        try
            delete(b3);
        end
        try
            delete(b4);
        end
        try
            delete(m1);
        end
        try
            delete(m2);
        end
    end

    function getThreshold(~,~)

        global zoomObj
        zoomObj = get(gca, {'xlim','ylim'});
        countThreshold = get(h2, 'Value');
        set(threshField,'string',num2str(countThreshold));
        clearParticleN(mainFig);
        updateThresholdUI();

    end


    function updateThresholdUI()
        
        global zoomObj
        
        mainFig;
        try
            extractTotalCentroids();
        catch
            return;
        end
        set(gca, {'xlim','ylim'}, zoomObj);
        hold on
        disp('Updating Figure...')
        currentIMG = imshow(currentChannel(:,:,zSlice), [], 'InitialMagnification', 450);
        for i = 1:sizeCentroids(1)
            [bb, bbPts, boxPlot] = extractBoundBox3(i, currentChannel);
            % For Visualization %
            if (zSlice >= bbPts(3,1)) && (zSlice <= bbPts(3,2))
                plot(boxPlot(:,1), boxPlot(:,2), '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 0.6 1], 'LineWidth', 1.0, 'Clipping', 'on');
                plot(trueCentroids(i,1), trueCentroids(i,2), '-s', 'MarkerSize', 4, 'MarkerEdgeColor', 'green', 'MarkerFaceColor', [0.6 1 0.6], 'Clipping', 'on');
                text(trueCentroids(i,1)+2, trueCentroids(i,2)+1.5, num2str(i), 'Fontsize', 8, 'Color', 'r', 'fontweight', 'bold', 'Clipping', 'on');
            end
            if mod(i,10) == 0
                disp( strcat('Progress: ', strcat(num2str( round(100*(i/sizeCentroids(1)), 1, 'decimals')), '%')));
            end
        end
        
        anno3 = annotation('textbox', [0.28, 0.89, 0.1, 0.1], 'string', 'CHOOSE THRESHOLD FOR PARTICLE DETECTION',...
            'fontweight', 'bold', 'FontSize', 16, 'EdgeColor', 'none');
        annotateFigure();
        
        disp('Figure Updated.')
        disp('*********************************************************************');
    end

    function updateThresholdUI2(~,~)

        global zoomObj
        
        mainFig;
        try
            extractTotalCentroids();
        catch
            return;
        end
        
        zoomObj = get(gca, {'xlim','ylim'});
        zSlice = round(get(h4, 'Value'));
        clearParticleN(mainFig);
        
        set(gca, {'xlim','ylim'}, zoomObj);
        hold on
        disp('Updating Figure...')
        currentIMG = imshow(currentChannel(:,:,zSlice), [], 'InitialMagnification', 450);
        for i = 1:sizeCentroids(1)
            [bb, bbPts, boxPlot] = extractBoundBox3(i, currentChannel);
            % For Visualization %
            if (zSlice >= bbPts(3,1)) && (zSlice <= bbPts(3,2))
                plot(boxPlot(:,1), boxPlot(:,2), '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 0.6 1], 'LineWidth', 1.0, 'Clipping', 'on');
                plot(trueCentroids(i,1), trueCentroids(i,2), '-s', 'MarkerSize', 4, 'MarkerEdgeColor', 'green', 'MarkerFaceColor', [0.6 1 0.6], 'Clipping', 'on');
                text(trueCentroids(i,1)+2, trueCentroids(i,2)+1.5, num2str(i), 'Fontsize', 8, 'Color', 'r', 'fontweight', 'bold', 'Clipping', 'on');
            end
            if mod(i,10) == 0
                disp( strcat('Progress: ', strcat(num2str( round(100*(i/sizeCentroids(1)), 1, 'decimals')), '%')));
            end
        end

        try
           delete(anno4) 
        end
        anno4 = annotation('textbox', [0.77, 0.875, 0.025, 0.025], 'string', num2str(zSlice),'FontSize',7.5);
        
        anno3 = annotation('textbox', [0.28, 0.89, 0.1, 0.1], 'string', 'CHOOSE THRESHOLD FOR PARTICLE DETECTION',...
            'fontweight', 'bold', 'FontSize', 16, 'EdgeColor', 'none');
        annotateFigure();
        
        disp('Figure Updated.')
        disp('*********************************************************************');
    end


    function updateThresholdUI3(~,~)

        global zoomObj
        
        mainFig;   
        zoomObj = get(gca, {'xlim','ylim'});
        zSlice = round(get(h4, 'Value'));
        clearParticleN(mainFig);
        
        set(gca, {'xlim','ylim'}, zoomObj);
        hold on
        disp('Updating Figure...')
        currentIMG = imshow(currentChannel(:,:,zSlice), [], 'InitialMagnification', 450);
        for i = 1:sizeCentroids(1)
            [bb, bbPts, boxPlot] = extractBoundBox3(i, currentChannel);
            % For Visualization %
            if (zSlice >= bbPts(3,1)) && (zSlice <= bbPts(3,2))
                plot(boxPlot(:,1), boxPlot(:,2), '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 0.6 1], 'LineWidth', 1.0, 'Clipping', 'on');
                plot(trueCentroids(i,1), trueCentroids(i,2), '-s', 'MarkerSize', 4, 'MarkerEdgeColor', 'green', 'MarkerFaceColor', [0.6 1 0.6], 'Clipping', 'on');
                text(trueCentroids(i,1)+2, trueCentroids(i,2)+1.5, num2str(i), 'Fontsize', 8, 'Color', 'r', 'fontweight', 'bold', 'Clipping', 'on');
            end
            if mod(i,10) == 0
                disp( strcat('Progress: ', strcat(num2str( round(100*(i/sizeCentroids(1)), 1, 'decimals')), '%')));
            end
        end

        try
           delete(anno4) 
        end
        anno4 = annotation('textbox', [0.77, 0.875, 0.025, 0.025], 'string', num2str(zSlice),'FontSize',7.5);
        annotateFigure();
        
        disp('Figure Updated.')
        disp('*********************************************************************');
    end

end

%%

function [particleBB, bbPts, boxPlot] = extractBoundBox(pN, currentChannel)

    global  imgSize nPlanes bufferPercXY bufferPercZ bbCentroids...
            g2DOpt g3DOpt pxlCentroids
    
    % Error Check
    if (bufferPercXY == 0)
        disp('Please Enter a Nonzero Value for XY Box Buffer');
        return;
    end
    if (bufferPercZ == 0)
        disp('Please Enter a Nonzero Value for Z Box Buffer');
        return;
    end
    
    % If 3D Gaussian Chosen for 3D Data %
    if (length(size(currentChannel)) == 3) && (g3DOpt == 1)
        bufferX = ceil(bufferPercXY*bbCentroids(pN,4));
        bufferY = ceil(bufferPercXY*bbCentroids(pN,5));
        bufferZ = ceil(bufferPercZ*bbCentroids(pN,6));

        startX = bbCentroids(pN,1)- bufferX;
        if startX < 1
            startX = 1;
        end
        endX = bbCentroids(pN,1) + bbCentroids(pN,4) + bufferX;
        if endX > imgSize(2)
            endX = imgSize(2);
        end

        startY = (bbCentroids(pN,2)- bufferY);
        if startY < 1
            startY = 1;
        end
        endY = (bbCentroids(pN,2) + bbCentroids(pN,5) + bufferY);
        if endY > imgSize(1)
            endY = imgSize(1);
        end

        startZ = bbCentroids(pN,3)- bufferZ;
        if startZ < 1
            startZ = 1;
        end
        endZ = bbCentroids(pN,3) + bbCentroids(pN,6) + bufferZ;
        if endZ > nPlanes
            endZ = nPlanes;
        end

        particleBB = currentChannel(startY:endY, startX:endX, startZ:endZ);
        bbPts = horzcat([startX; startY; startZ], [endX; endY; endZ]);

        boxPlot(1,:) = [bbPts(1,1)-0.5, bbPts(2,1)-0.5];
        boxPlot(4,:) = [bbPts(1,2)+0.5, bbPts(2,1)-0.5];
        boxPlot(2,:) = [bbPts(1,1)-0.5, bbPts(2,2)+0.5];
        boxPlot(3,:) = [bbPts(1,2)+0.5, bbPts(2,2)+0.5];
        boxPlot(5,:) = [bbPts(1,1)-0.5, bbPts(2,1)-0.5];
    
    % If 2D Gaussian Chosen for 3D Data %    
    elseif (length(size(currentChannel)) == 3) && (g2DOpt == 1)
        
        bufferX = ceil(bufferPercXY*bbCentroids(pN,4));
        bufferY = ceil(bufferPercXY*bbCentroids(pN,5));

        startX = bbCentroids(pN,1)- bufferX;
        if startX < 1
            startX = 1;
        end
        endX = bbCentroids(pN,1) + bbCentroids(pN,4) + bufferX;
        if endX > imgSize(2)
            endX = imgSize(2);
        end

        startY = (bbCentroids(pN,2)- bufferY);
        if startY < 1
            startY = 1;
        end
        endY = (bbCentroids(pN,2) + bbCentroids(pN,5) + bufferY);
        if endY > imgSize(1)
            endY = imgSize(1);
        end


        particleBB = currentChannel(startY:endY, startX:endX, pxlCentroids(pN,3));
        bbPts = horzcat([startX; startY], [endX; endY]);

        boxPlot(1,:) = [bbPts(1,1)-0.5, bbPts(2,1)-0.5];
        boxPlot(4,:) = [bbPts(1,2)+0.5, bbPts(2,1)-0.5];
        boxPlot(2,:) = [bbPts(1,1)-0.5, bbPts(2,2)+0.5];
        boxPlot(3,:) = [bbPts(1,2)+0.5, bbPts(2,2)+0.5];
        boxPlot(5,:) = [bbPts(1,1)-0.5, bbPts(2,1)-0.5];
    
    % If 2D Gaussian Chosen for 2D Data %    
    elseif (length(size(currentChannel)) == 2) && (g2DOpt == 1)
        
        bufferX = ceil(bufferPercXY*bbCentroids(pN,3));
        bufferY = ceil(bufferPercXY*bbCentroids(pN,4));

        startX = bbCentroids(pN,1)- bufferX;
        if startX < 1
            startX = 1;
        end
        endX = bbCentroids(pN,1) + bbCentroids(pN,3) + bufferX;
        if endX > imgSize(2)
            endX = imgSize(2);
        end

        startY = (bbCentroids(pN,2)- bufferY);
        if startY < 1
            startY = 1;
        end
        endY = (bbCentroids(pN,2) + bbCentroids(pN,4) + bufferY);
        if endY > imgSize(1)
            endY = imgSize(1);
        end


        particleBB = currentChannel(startY:endY, startX:endX);
        bbPts = horzcat([startX; startY], [endX; endY]);

        boxPlot(1,:) = [bbPts(1,1)-0.5, bbPts(2,1)-0.5];
        boxPlot(4,:) = [bbPts(1,2)+0.5, bbPts(2,1)-0.5];
        boxPlot(2,:) = [bbPts(1,1)-0.5, bbPts(2,2)+0.5];
        boxPlot(3,:) = [bbPts(1,2)+0.5, bbPts(2,2)+0.5];
        boxPlot(5,:) = [bbPts(1,1)-0.5, bbPts(2,1)-0.5];
        
    end
end
%%
function [particleBB, bbPts, boxPlot] = extractBoundBox2(pN, currentChannel)

    global  imgSize nPlanes bufferPercXY bufferPercZ bbCentroids...
            g2DOpt g3DOpt pxlCentroids
    
    % Error Check
    if (bufferPercXY == 0)
        disp('Please Enter a Nonzero Value for XY Box Buffer');
        return;
    end
    if (bufferPercZ == 0)
        disp('Please Enter a Nonzero Value for Z Box Buffer');
        return;
    end
    
    % If 3D Gaussian Chosen for 3D Data %
    if (length(size(currentChannel)) == 3)
        bufferX = 1.5*ceil(bufferPercXY*bbCentroids(pN,4));
        bufferY = 1.5*ceil(bufferPercXY*bbCentroids(pN,5));
        bufferZ = 3*ceil(bufferPercZ*bbCentroids(pN,6));

        startX = bbCentroids(pN,1)- bufferX;
        if startX < 1
            startX = 1;
        end
        endX = bbCentroids(pN,1) + bbCentroids(pN,4) + bufferX;
        if endX > imgSize(2)
            endX = imgSize(2);
        end

        startY = (bbCentroids(pN,2)- bufferY);
        if startY < 1
            startY = 1;
        end
        endY = (bbCentroids(pN,2) + bbCentroids(pN,5) + bufferY);
        if endY > imgSize(1)
            endY = imgSize(1);
        end

        startZ = bbCentroids(pN,3)- bufferZ;
        if startZ < 1
            startZ = 1;
        end
        endZ = bbCentroids(pN,3) + bbCentroids(pN,6) + bufferZ;
        if endZ > nPlanes
            endZ = nPlanes;
        end

        particleBB = currentChannel(startY:endY, startX:endX, startZ:endZ);
        bbPts = horzcat([startX; startY; startZ], [endX; endY; endZ]);

        boxPlot(1,:) = [bbPts(1,1)-0.5, bbPts(2,1)-0.5];
        boxPlot(4,:) = [bbPts(1,2)+0.5, bbPts(2,1)-0.5];
        boxPlot(2,:) = [bbPts(1,1)-0.5, bbPts(2,2)+0.5];
        boxPlot(3,:) = [bbPts(1,2)+0.5, bbPts(2,2)+0.5];
        boxPlot(5,:) = [bbPts(1,1)-0.5, bbPts(2,1)-0.5];
    
    
    % If 2D Gaussian Chosen for 2D Data %    
    elseif (length(size(currentChannel)) == 2)
        
        bufferX = ceil(bufferPercXY*bbCentroids(pN,3));
        bufferY = ceil(bufferPercXY*bbCentroids(pN,4));

        startX = bbCentroids(pN,1)- bufferX;
        if startX < 1
            startX = 1;
        end
        endX = bbCentroids(pN,1) + bbCentroids(pN,3) + bufferX;
        if endX > imgSize(2)
            endX = imgSize(2);
        end

        startY = (bbCentroids(pN,2)- bufferY);
        if startY < 1
            startY = 1;
        end
        endY = (bbCentroids(pN,2) + bbCentroids(pN,4) + bufferY);
        if endY > imgSize(1)
            endY = imgSize(1);
        end


        particleBB = currentChannel(startY:endY, startX:endX);
        bbPts = horzcat([startX; startY], [endX; endY]);

        boxPlot(1,:) = [bbPts(1,1)-0.5, bbPts(2,1)-0.5];
        boxPlot(4,:) = [bbPts(1,2)+0.5, bbPts(2,1)-0.5];
        boxPlot(2,:) = [bbPts(1,1)-0.5, bbPts(2,2)+0.5];
        boxPlot(3,:) = [bbPts(1,2)+0.5, bbPts(2,2)+0.5];
        boxPlot(5,:) = [bbPts(1,1)-0.5, bbPts(2,1)-0.5];
        
    end
end

%%
function [particleBB, bbPts, boxPlot] = extractBoundBox3(pN, currentChannel)

    global  imgSize nPlanes bufferPercXY bufferPercZ bbCentroids...
            g2DOpt g3DOpt pxlCentroids bbPts
    
    % Error Check
    if (bufferPercXY == 0)
        disp('Please Enter a Nonzero Value for XY Box Buffer');
        return;
    end
    if (bufferPercZ == 0)
        disp('Please Enter a Nonzero Value for Z Box Buffer');
        return;
    end
    
    % If 3D Gaussian Chosen for 3D Data %
    if (length(size(currentChannel)) == 3)
        bufferX = ceil(bufferPercXY*bbCentroids(pN,4));
        bufferY = ceil(bufferPercXY*bbCentroids(pN,5));
        bufferZ = ceil(bufferPercZ*bbCentroids(pN,6));

        startX = bbCentroids(pN,1)- bufferX;
        if startX < 1
            startX = 1;
        end
        endX = bbCentroids(pN,1) + bbCentroids(pN,4) + bufferX;
        if endX > imgSize(2)
            endX = imgSize(2);
        end

        startY = (bbCentroids(pN,2)- bufferY);
        if startY < 1
            startY = 1;
        end
        endY = (bbCentroids(pN,2) + bbCentroids(pN,5) + bufferY);
        if endY > imgSize(1)
            endY = imgSize(1);
        end

        startZ = bbCentroids(pN,3)- bufferZ;
        if startZ < 1
            startZ = 1;
        end
        endZ = bbCentroids(pN,3) + bbCentroids(pN,6) + bufferZ;
        if endZ > nPlanes
            endZ = nPlanes;
        end

        particleBB = currentChannel(startY:endY, startX:endX, startZ:endZ);
        bbPts = horzcat([startX; startY; startZ], [endX; endY; endZ]);

        boxPlot(1,:) = [bbPts(1,1)-0.5, bbPts(2,1)-0.5];
        boxPlot(4,:) = [bbPts(1,2)+0.5, bbPts(2,1)-0.5];
        boxPlot(2,:) = [bbPts(1,1)-0.5, bbPts(2,2)+0.5];
        boxPlot(3,:) = [bbPts(1,2)+0.5, bbPts(2,2)+0.5];
        boxPlot(5,:) = [bbPts(1,1)-0.5, bbPts(2,1)-0.5];
    
    
    % If 2D Gaussian Chosen for 2D Data %    
    elseif (length(size(currentChannel)) == 2)
        
        bufferX = ceil(bufferPercXY*bbCentroids(pN,3));
        bufferY = ceil(bufferPercXY*bbCentroids(pN,4));

        startX = bbCentroids(pN,1)- bufferX;
        if startX < 1
            startX = 1;
        end
        endX = bbCentroids(pN,1) + bbCentroids(pN,3) + bufferX;
        if endX > imgSize(2)
            endX = imgSize(2);
        end

        startY = (bbCentroids(pN,2)- bufferY);
        if startY < 1
            startY = 1;
        end
        endY = (bbCentroids(pN,2) + bbCentroids(pN,4) + bufferY);
        if endY > imgSize(1)
            endY = imgSize(1);
        end


        particleBB = currentChannel(startY:endY, startX:endX);
        bbPts = horzcat([startX; startY], [endX; endY]);

        boxPlot(1,:) = [bbPts(1,1)-0.5, bbPts(2,1)-0.5];
        boxPlot(4,:) = [bbPts(1,2)+0.5, bbPts(2,1)-0.5];
        boxPlot(2,:) = [bbPts(1,1)-0.5, bbPts(2,2)+0.5];
        boxPlot(3,:) = [bbPts(1,2)+0.5, bbPts(2,2)+0.5];
        boxPlot(5,:) = [bbPts(1,1)-0.5, bbPts(2,1)-0.5];
        
    end
end

%%

function [particleBB, bbPts, boxPlot, percBG] = extractBoundBoxBG(pN, currentChannel)

    global  imgSize nPlanes bbCentroids bgPixel pxlCentroids

        
    [particleBB, bbPts, boxPlot] = extractBoundBox(pN, currentChannel);

    % Background Correction if 3D %
    if size(bbPts, 1) == 3
        startXfail = false;
        endXfail = false;
        startYfail = false;
        endYfail = false;
        startZfail = false;
        endZfail = false;

        bgX = ceil(bgPixel*(bbPts(1,2)-bbPts(1,1)));
        bgY = ceil(bgPixel*(bbPts(2,2)-bbPts(2,1)));
        bgZ = ceil(bgPixel*(bbPts(3,2)-bbPts(3,1)));

        % Finding Limits for XYZ and Correct for Problems %
        startX = bbPts(1,1)-bgX;
        if startX < 1
            startX = 1;
            startXfail = true;
        end
        endX = bbPts(1,2)+bgX;
        if endX > imgSize(2)
            endX = imgSize(2);
            endXfail = true;
        end

        startY = bbPts(2,1)-bgY;
        if startY < 1
            startY = 1;
            startYfail = true;
        end
        endY = bbPts(2,2)+bgY;
        if endY > imgSize(1)
            endY = imgSize(1);
            endYfail = true;
        end

        startZ = bbPts(3,1)-bgZ;
        if startZ < 1
            startZ = 1;
            startZfail = true;
        end
        endZ = bbPts(3,2)+bgZ;
        if endZ > nPlanes
            endZ = nPlanes;
            endZfail = true;
        end

        % Testing If Limits are Within Other Bounding Boxes

        for i = 1:size(bbCentroids,1)

            if i ~= pN

                [tempBB, tempBBPts, tempBoxPlot] = extractBoundBox(i, currentChannel);

                % Check for X Overlap Fail %
                if (startX > tempBBPts(1,1)) && (startX < tempBBPts(1,2)) &&...
                        ( ((startY > tempBBPts(2,1)) && (startY < tempBBPts(2,2))) || ((endY > tempBBPts(2,1)) && (endY < tempBBPts(2,2))) ) &&...
                        ( ((startZ >= tempBBPts(3,1)) && (startZ <= tempBBPts(3,2))) || ((endZ >= tempBBPts(3,1)) && (endZ <= tempBBPts(3,2))) )
                    startXfail = true;
                end
                if (endX > tempBBPts(1,1)) && (endX < tempBBPts(1,2)) &&...
                        ( ((startY > tempBBPts(2,1)) && (startY < tempBBPts(2,2))) || ((endY > tempBBPts(2,1)) && (endY < tempBBPts(2,2))) ) &&...
                        ( ((startZ >= tempBBPts(3,1)) && (startZ <= tempBBPts(3,2))) || ((endZ >= tempBBPts(3,1)) && (endZ <= tempBBPts(3,2))) )
                    endXfail = true;
                end

                % Check for Y Overlap Fail %
                if (startY > tempBBPts(2,1)) && (startY < tempBBPts(2,2)) &&...
                        ( ((startX > tempBBPts(1,1)) && (startX < tempBBPts(1,2))) || ((endX > tempBBPts(1,1)) && (endX < tempBBPts(1,2))) ) &&...
                        ( ((startZ >= tempBBPts(3,1)) && (startZ <= tempBBPts(3,2))) || ((endZ >= tempBBPts(3,1)) && (endZ <= tempBBPts(3,2))) )
                    startYfail = true;
                end
                if (endY > tempBBPts(2,1)) && (endY < tempBBPts(2,2)) &&...
                        ( ((startX > tempBBPts(1,1)) && (startX < tempBBPts(1,2))) || ((endX > tempBBPts(1,1)) && (endX < tempBBPts(1,2))) ) &&...
                        ( ((startZ >= tempBBPts(3,1)) && (startZ <= tempBBPts(3,2))) || ((endZ >= tempBBPts(3,1)) && (endZ <= tempBBPts(3,2))) )
                    endYfail = true;
                end

                % Check for Z Overlap Fail %
                if (startZ >= tempBBPts(3,1)) && (startZ <= tempBBPts(3,2)) &&...
                        ( ((startY > tempBBPts(2,1)) && (startY < tempBBPts(2,2))) || ((endY > tempBBPts(2,1)) && (endY < tempBBPts(2,2))) ) &&...
                        ( ((startX > tempBBPts(1,1)) && (startX < tempBBPts(1,2))) || ((endX > tempBBPts(1,1)) && (endX < tempBBPts(1,2))) )
                    startZfail = true;
                end
                if (endZ >= tempBBPts(3,1)) && (endZ <= tempBBPts(3,2)) &&...
                        ( ((startY > tempBBPts(2,1)) && (startY < tempBBPts(2,2))) || ((endY > tempBBPts(2,1)) && (endY < tempBBPts(2,2))) ) &&...
                        ( ((startX > tempBBPts(1,1)) && (startX < tempBBPts(1,2))) || ((endX > tempBBPts(1,1)) && (endX < tempBBPts(1,2))) )
                    endZfail = true;
                end

            end

        end

        bgBox = currentChannel(startY:endY, startX:endX, startZ:endZ);

        % Determine Boundaries to Set 0's %
        if startXfail
            bgStartX = 1;
        else
            bgStartX = bgX+1;
        end

        if endXfail
            bgEndX = size(bgBox,2);
        else
            bgEndX = size(bgBox,2)-bgX;
        end

        if startYfail
            bgStartY = 1;
        else
            bgStartY = bgY+1;
        end

        if endYfail
            bgEndY = size(bgBox,1);
        else
            bgEndY = size(bgBox,1)-bgY;
        end

        if startZfail
            bgStartZ = 1;
        else
            bgStartZ = bgZ+1;
        end

        if endZfail
            bgEndZ = size(bgBox,3);
        else
            bgEndZ = size(bgBox,3)-bgZ;
        end

        bgBox(bgStartY:bgEndY, bgStartX:bgEndX, bgStartZ:bgEndZ) = 0;

        bgMean = median(nonzeros(bgBox));

        bgN = length(nonzeros(bgBox));
        bbN = size(particleBB,1)*size(particleBB,2)*size(particleBB,3);

        % Calculate Percentage of Background Pixels/BB Pixels %
        percBG = 100*bgN/bbN;

        particleBB = particleBB - bgMean;

        % Set Negative Elements to 0 %
        particleBB(particleBB < 0) = 0;
        
    elseif size(bbPts, 1) == 2
        
        startXfail = false;
        endXfail = false;
        startYfail = false;
        endYfail = false;

        bgX = ceil(bgPixel*(bbPts(1,2)-bbPts(1,1)));
        bgY = ceil(bgPixel*(bbPts(2,2)-bbPts(2,1)));

        % Finding Limits for XYZ and Correct for Problems %
        startX = bbPts(1,1)-bgX;
        if startX < 1
            startX = 1;
            startXfail = true;
        end
        endX = bbPts(1,2)+bgX;
        if endX > imgSize(2)
            endX = imgSize(2);
            endXfail = true;
        end

        startY = bbPts(2,1)-bgY;
        if startY < 1
            startY = 1;
            startYfail = true;
        end
        endY = bbPts(2,2)+bgY;
        if endY > imgSize(1)
            endY = imgSize(1);
            endYfail = true;
        end

        % Testing If Limits are Within Other Bounding Boxes

        for i = 1:size(bbCentroids,1)

            if i ~= pN

                [tempBB, tempBBPts, tempBoxPlot] = extractBoundBox(i, currentChannel);

                % Check for X Overlap Fail %
                if (startX > tempBBPts(1,1)) && (startX < tempBBPts(1,2)) &&...
                        ( ((startY > tempBBPts(2,1)) && (startY < tempBBPts(2,2))) || ((endY > tempBBPts(2,1)) && (endY < tempBBPts(2,2))) )
                    startXfail = true;
                end
                if (endX > tempBBPts(1,1)) && (endX < tempBBPts(1,2)) &&...
                        ( ((startY > tempBBPts(2,1)) && (startY < tempBBPts(2,2))) || ((endY > tempBBPts(2,1)) && (endY < tempBBPts(2,2))) )
                    endXfail = true;
                end

                % Check for Y Overlap Fail %
                if (startY > tempBBPts(2,1)) && (startY < tempBBPts(2,2)) &&...
                        ( ((startX > tempBBPts(1,1)) && (startX < tempBBPts(1,2))) || ((endX > tempBBPts(1,1)) && (endX < tempBBPts(1,2))) )
                    startYfail = true;
                end
                if (endY > tempBBPts(2,1)) && (endY < tempBBPts(2,2)) &&...
                        ( ((startX > tempBBPts(1,1)) && (startX < tempBBPts(1,2))) || ((endX > tempBBPts(1,1)) && (endX < tempBBPts(1,2))) )
                    endYfail = true;
                end

            end

        end

        if nPlanes > 1
            bgBox = currentChannel(startY:endY, startX:endX, pxlCentroids(pN,3));
        elseif nPlanes == 1
            bgBox = currentChannel(startY:endY, startX:endX);
        end

        % Determine Boundaries to Set 0's %
        if startXfail
            bgStartX = 1;
        else
            bgStartX = bgX+1;
        end

        if endXfail
            bgEndX = size(bgBox,2);
        else
            bgEndX = size(bgBox,2)-bgX;
        end

        if startYfail
            bgStartY = 1;
        else
            bgStartY = bgY+1;
        end

        if endYfail
            bgEndY = size(bgBox,1);
        else
            bgEndY = size(bgBox,1)-bgY;
        end


        bgBox(bgStartY:bgEndY, bgStartX:bgEndX) = 0;

        bgMean = median(nonzeros(bgBox));

        bgN = length(nonzeros(bgBox));
        bbN = size(particleBB,1)*size(particleBB,2);

        % Calculate Percentage of Background Pixels/BB Pixels %
        percBG = 100*bgN/bbN;

        particleBB = particleBB - bgMean;

        % Set Negative Elements to 0 %
        particleBB(particleBB < 0) = 0;
        
    end

end

%%

function [bbCoords] = extractBBCoords(particleBB)
    
    if length(size(particleBB)) == 3
        
        bbSize = size(particleBB);
        bbCoords = zeros(bbSize(1)*bbSize(2)*bbSize(3),4);

        for z = 1:bbSize(3)

            for y = 1:bbSize(1)

                for x = 1:bbSize(2)

                    bbCoords((z-1)*bbSize(1)*bbSize(2)+(y-1)*bbSize(2)+x,1) = x;
                    bbCoords((z-1)*bbSize(1)*bbSize(2)+(y-1)*bbSize(2)+x,2) = y;
                    bbCoords((z-1)*bbSize(1)*bbSize(2)+(y-1)*bbSize(2)+x,3) = z;
                    bbCoords((z-1)*bbSize(1)*bbSize(2)+(y-1)*bbSize(2)+x,4) = particleBB(y,x,z);
                end

            end

        end
        bbCoords = bbCoords';
        
    elseif length(size(particleBB)) == 2
        
        % Need to finish for 2D Condition %
        bbSize = size(particleBB);
        bbCoords = zeros(bbSize(1)*bbSize(2),3);


            for y = 1:bbSize(1)

                for x = 1:bbSize(2)

                    bbCoords((y-1)*bbSize(2)+x,1) = x;
                    bbCoords((y-1)*bbSize(2)+x,2) = y;
                    bbCoords((y-1)*bbSize(2)+x,3) = particleBB(y,x);
                end

            end

        bbCoords = bbCoords';
        
    end
    
end

%%

function f = gauss3D(params, bbCoords)

    % Coordinates %
    xi = bbCoords(1,:);
    yi = bbCoords(2,:);
    zi = bbCoords(3,:);
    
    % Parameters %
    meanX = params(1);
    meanY = params(2);
    meanZ = params(3);
    
    thetaX = params(4);
    thetaY = params(5);
    thetaZ = params(6);
    
    sigmaX = params(7);
    sigmaY = params(8);
    sigmaZ = params(9);
    
    gaussBase = params(10);
    coeffA0 = params(11);
    
    % Translation Matrix %
    
    transMat = [ 1 0 0 -meanX;
                 0 1 0 -meanY;
                 0 0 1 -meanZ;
                 0 0 0 1];
             
    xRotMat = [1 0 0 0;
               0 cos(-thetaX) sin(-thetaX) 0;
               0 -sin(-thetaX) cos(-thetaX) 0;
               0 0 0 1];
           
    yRotMat = [cos(-thetaY) 0 sin(-thetaY) 0;
               0 1 0 0;
               -sin(-thetaY) 0 cos(-thetaY) 0;
               0 0 0 1];
    
    zRotMat = [cos(-thetaZ) -sin(-thetaZ) 0 0;
               sin(-thetaZ) cos(-thetaZ) 0 0;
               0 0 1 0;
               0 0 0 1];
    
    newCoords = zRotMat*yRotMat*xRotMat*transMat*[bbCoords(1:3,:); ones(1,size(bbCoords,2))];
    
    x = newCoords(1,:);
    y = newCoords(2,:);
    z = newCoords(3,:);
    
    expX = exp(-0.5*x.*x/(sigmaX*sigmaX));
    expY = exp(-0.5*y.*y/(sigmaY*sigmaY));
    expZ = exp(-0.5*z.*z/(sigmaZ*sigmaZ));
    
    f = gaussBase + coeffA0*expX.*expY.*expZ;

end

%%

function [fitParams] = fit3DGauss(particleBB, bbCoords, boxPts)

    global xyRes zRes fwhmDiv
    
    if isempty(xyRes) || isempty(zRes)
        disp('ERROR: Pixel scaling is not properly set!')
        return;
    end
    
    bbSize = size(particleBB);
    bbSize(1) = bbSize(1)*xyRes;
    bbSize(2) = bbSize(2)*xyRes;
    bbSize(3) = bbSize(3)*zRes;
    
    scaledCoords = bbCoords(1:3,:);
    scaledCoords(1:2,:) = (bbCoords(1:2,:)-0.5)*xyRes;
    scaledCoords(3,:) = (bbCoords(3,:)-0.5)*zRes;
    
    intensityVals = bbCoords(4,:);

    baseGuess = min(min(min(particleBB)));
    ampGuess = max(max(max(particleBB)))-baseGuess;

    sigmaX = bbSize(2)/2;
    sigmaY = bbSize(1)/2;
    sigmaZ = bbSize(3)/2;

    params = [0 0 0 0 0 0 sigmaX sigmaY sigmaZ baseGuess ampGuess];

    lb = [min(scaledCoords(1,:)), min(scaledCoords(2,:)), min(scaledCoords(3,:)), -pi, -pi, -pi, sigmaX/10, sigmaY/10, sigmaZ/10, baseGuess/2, 1];
    ub = [bbSize(2), bbSize(1), bbSize(3), pi, pi, pi, sigmaX*2, sigmaY*2, sigmaZ*2, baseGuess*3, ampGuess*2-baseGuess];

    [fitParams, resnorm] = lsqcurvefit(@gauss3D, params, scaledCoords, intensityVals, lb, ub, optimset('Display','off'));

    % Correct for Frame of Reference %
    trueX = fitParams(1)+ (boxPts(1,1)-1)*xyRes;
    trueY = fitParams(2)+ (boxPts(2,1)-1)*xyRes;
    trueZ = fitParams(3)+ (boxPts(3,1)-1)*zRes;
    
    fitX = fitParams(1);
    fitY = fitParams(2);
    fitZ = fitParams(3);
       
    fitParams(1) = trueX;
    fitParams(2) = trueY;
    fitParams(3) = trueZ;
    
    FWHM_X = 2*sqrt(2*log(2))*fitParams(7);
    FWHM_Y = 2*sqrt(2*log(2))*fitParams(8);
    FWHM_Z = 2*sqrt(2*log(2))*fitParams(9);
    
    xRotMat = [1 0 0 0;
               0 cos(fitParams(4)) sin(fitParams(4)) 0;
               0 -sin(fitParams(4)) cos(fitParams(4)) 0;
               0 0 0 1];
           
    yRotMat = [cos(fitParams(5)) 0 sin(fitParams(5)) 0;
               0 1 0 0;
               -sin(fitParams(5)) 0 cos(fitParams(5)) 0;
               0 0 0 1];
    
    zRotMat = [cos(fitParams(6)) -sin(fitParams(6)) 0 0;
               sin(fitParams(6)) cos(fitParams(6)) 0 0;
               0 0 1 0;
               0 0 0 1];
    
    newCoords = zRotMat*yRotMat*xRotMat*[scaledCoords(1:3,:); ones(1,size(scaledCoords,2))];
    centerPt = zRotMat*yRotMat*xRotMat*[fitX; fitY; fitZ; 1];
    
    % Determine True FWHM %
    
    closeX = (  (newCoords(1,:) <= (centerPt(1) + xyRes/fwhmDiv)) & (newCoords(1,:) >= (centerPt(1) - xyRes/fwhmDiv)) & (newCoords(3,:) <= (centerPt(3) + zRes/fwhmDiv)) & (newCoords(3,:) >= (centerPt(3) - zRes/fwhmDiv))  );
    closeY = (  (newCoords(2,:) <= (centerPt(2) + xyRes/fwhmDiv)) & (newCoords(2,:) >= (centerPt(2) - xyRes/fwhmDiv)) & (newCoords(3,:) <= (centerPt(3) + zRes/fwhmDiv)) & (newCoords(3,:) >= (centerPt(3) - zRes/fwhmDiv))  );
    closeZ = (  (newCoords(1,:) <= (centerPt(1) + xyRes/fwhmDiv)) & (newCoords(1,:) >= (centerPt(1) - xyRes/fwhmDiv)) & (newCoords(2,:) <= (centerPt(2) + xyRes/fwhmDiv)) & (newCoords(2,:) >= (centerPt(2) - xyRes/fwhmDiv)) );
    
    dataX = zeros(2, sum(closeY));
    dataX(1,:) = newCoords(1, closeY == 1);
    dataX(2,:) = intensityVals(1, closeY == 1);
    
    dataY = zeros(2, sum(closeX));
    dataY(1,:) = newCoords(2, closeX == 1);
    dataY(2,:) = intensityVals(1, closeX == 1);
    
    dataZ = zeros(2, sum(closeZ));
    dataZ(1,:) = newCoords(3, closeZ == 1);
    dataZ(2,:) = intensityVals(1, closeZ == 1);
    
    try
        sizeX = fitHalfHeight(dataX, fitParams(6));
        if isempty(sizeX)
            sizeX = NaN;
        end
    catch
        sizeX = NaN;
    end
    try
        sizeY = fitHalfHeight(dataY, fitParams(6));
        if isempty(sizeY)
            sizeY = NaN;
        end
    catch
        sizeY = NaN;
    end
    try
        sizeZ = fitHalfHeight(dataZ, fitParams(6));
        if isempty(sizeZ)
            sizeZ = NaN;
        end
    catch
        sizeZ = NaN;
    end
    
    if isempty(resnorm)
        resnorm = NaN;
    end
    
    % Determine Interpolated FWHM %
    
    InterpFunction = scatteredInterpolant(newCoords(1,:)',newCoords(2,:)',newCoords(3,:)',intensityVals(1,:)','natural','nearest');
    
    xRange = bbSize(2);
    yRange = bbSize(1);
    zRange = bbSize(3);  
    
    nSampleX = xRange/xyRes;
    nSampleY = yRange/xyRes;
    nSampleZ = zRange/zRes;
    
    newX = centerPt(1,1)-(xRange/2):xRange/(nSampleX-1):centerPt(1,1)+(xRange/2);
    newX_I = InterpFunction(newX,centerPt(2)+zeros(1,size(newX,2)),centerPt(3)+zeros(1,size(newX,2)));
    
    newY = centerPt(2,1)-(yRange/2):yRange/(nSampleY-1):centerPt(2,1)+(yRange/2);
    newY_I = InterpFunction(centerPt(1)+zeros(1,size(newY,2)),newY,centerPt(3)+zeros(1,size(newY,2)));
    
    newZ = centerPt(3,1)-(zRange/2):zRange/(nSampleZ-1):centerPt(3,1)+(zRange/2);
    newZ_I = InterpFunction(centerPt(1)+zeros(1,size(newZ,2)),centerPt(2)+zeros(1,size(newZ,2)),newZ);
    
    dataX2 = [newX; newX_I];
    dataY2 = [newY; newY_I];
    dataZ2 = [newZ; newZ_I];
    
    dataX2 = sortrows(dataX2',1)';    
    dataY2 = sortrows(dataY2',1)';
    dataZ2 = sortrows(dataZ2',1)';
    
    try
        sizeX2 = fitHalfHeight(dataX2, fitParams(6));
        if isempty(sizeX2)
            sizeX2 = NaN;
        end
    catch
        sizeX2 = NaN;
    end
    try
        sizeY2 = fitHalfHeight(dataY2, fitParams(6));
        if isempty(sizeY2)
            sizeY2 = NaN;
        end
    catch
        sizeY2 = NaN;
    end
    try
        sizeZ2 = fitHalfHeight(dataZ2, fitParams(6));
        if isempty(sizeZ2)
            sizeZ2 = NaN;
        end
    catch
        sizeZ2 = NaN;
    end
    
    if isempty(resnorm)
        resnorm = NaN;
    end
    
    fitParams = [fitParams FWHM_X FWHM_Y FWHM_Z sum(intensityVals) max(intensityVals) sizeX sizeY sizeZ sizeX2 sizeY2 sizeZ2 resnorm/size(scaledCoords,2)];

end

%%

function updateCurrentPts()

    global excludePts finalFitParams currentPts currentBB boxLimits...
        pxlCentroids currentCentroids
    
    excludePts = unique(excludePts);
    tempSize = size(finalFitParams);
    tempData = [finalFitParams(:,1:end-1) ones(tempSize(1),1)];

    excludeSize = size(excludePts);
    
    if excludeSize >= 1
        for i = 1:max(excludeSize)
            exPt = excludePts(i);
            tempData(exPt,end) = false;   
        end
    end
    
    finalFitParams(:,end) = tempData(:,end);
    currentPts = tempData(tempData(:,end) == 1, 1:end-1);
    currentBB = boxLimits(tempData(:,tempSize(2))== 1, :);
    currentCentroids = pxlCentroids(tempData(:,tempSize(2))== 1, :);
end


%%

function selectParticles()

    global mainFig currentPts zoomObj

    mainFig;
    zoomObj = get(gca, {'xlim','ylim'});
    set(gcf, 'WindowButtonDownFcn', @removeParticle);
    
    disp(strcat('Current Particles Detected: *', num2str(size(currentPts,1))));

    disp('.');
    disp('PARTICLE SELECTION');
    disp('Tips:');
    disp('	- Double click the particle you want to remove/add.');
    disp('	- For best figure visualization, do not change the figure size.');
    disp('	- Use the (+) & (-) buttons on the top right of figure and mouse scroller to zoom.');
    disp('	- Only particles originally detected post-thresholding can be added or removed.');
    disp('	- After choosing particles, choose the "EXPORT" button to export your data.');
    disp('...............................................................................');
    disp('PARTICLE CHANGE LOG:');
    
    set(gca, {'xlim','ylim'}, zoomObj);

end

%%

function removeParticle(clickSource, ~)

  global excludePts zoomObj zSlice nPlanes g3DOpt g2DOpt boxLimits pxlCentroids currentBB

  if strcmp(get(clickSource, 'SelectionType'), 'open')
      
    cursPos = get(gca, 'CurrentPoint');
    newPos = [cursPos(1,1) cursPos(1,2)];
    
    zoomObj = get(gca, {'xlim','ylim'});
    
    if (g3DOpt == 1)
        indexPN = find( newPos(1) >= boxLimits(:,1) & newPos(1) <= boxLimits(:,2) & newPos(2) >= boxLimits(:,3) & newPos(2) <= boxLimits(:,4) & zSlice >= boxLimits(:,5)+0.5 & zSlice <= boxLimits(:,6)-0.5);
    elseif (g2DOpt == 1) && (nPlanes > 1)
        indexPN = find( newPos(1) >= boxLimits(:,1) & newPos(1) <= boxLimits(:,2) & newPos(2) >= boxLimits(:,3) & newPos(2) <= boxLimits(:,4) & zSlice == pxlCentroids(:,3));
    elseif (g2DOpt == 1) && (nPlanes == 1)
        indexPN = find( newPos(1) >= boxLimits(:,1) & newPos(1) <= boxLimits(:,2) & newPos(2) >= boxLimits(:,3) & newPos(2) <= boxLimits(:,4));
    end
    indexPN
    sizeIND = size(indexPN);
    
    if isempty(indexPN)
        disp('No Particle Detected Here.');
    elseif ~isempty(indexPN)
        if sizeIND(1) == 1
            
            if ismember(indexPN, excludePts)
                addIND = find(excludePts == indexPN);
                excludePts(addIND) = [];
                currTime = strcat('[', strcat(datestr(now,'HH:MM:SS'),']'));
                disp(strcat(currTime, ': Particle Added.'));
            elseif ~ismember(indexPN, excludePts)
                excludePts(end+1) = indexPN;
                currTime = strcat('[', strcat(datestr(now,'HH:MM:SS'),']'));
                disp(strcat(currTime, ': Particle Removed.'));
                %disp(strcat('Particle #', strcat(num2str(indexPN), ' removed.')));
            end
            
            updateCurrentPts();
            updateVisualFigure();
            
        elseif sizeIND(1) > 1
            disp('Detection Error. Please try again.');
        end
    else
        disp('Issue Detected. Choose Again.');
    end
    
  end
  
end

%%

function updateVisualFigure()

    global mainFig currentPts finalFitParams excludePts currentMaxIMG...
            boxLimits zoomObj xyRes currentBB zSlice g2DOpt g3DOpt...
            currentCentroids nPlanes h4 anno4 viewFigSize pxlCentroids...
        

    warning off;
    
    mainFig;
    zoomObj = get(gca, {'xlim','ylim'});
    clearParticleN(mainFig);
    set(gca, {'xlim','ylim'}, zoomObj);
    hold on;
    xlabel('Double Click To Add Or Remove', 'FontSize', 10)

    sizeCurrent = size(currentPts);
    sizeFinalFit = size(finalFitParams);

    % Plot Bounding Boxes of Current Points %
    for m = 1:sizeFinalFit(1)

        if ~ismember(m,excludePts)
            boxPlot(1,:) = [boxLimits(m,1), boxLimits(m,3)];
            boxPlot(4,:) = [boxLimits(m,2), boxLimits(m,3)];
            boxPlot(2,:) = [boxLimits(m,1), boxLimits(m,4)];
            boxPlot(3,:) = [boxLimits(m,2), boxLimits(m,4)];
            boxPlot(5,:) = [boxLimits(m,1), boxLimits(m,3)];
            mainFig;
            hold on;
            if (g3DOpt == 1) && (zSlice >= boxLimits(m,5)+0.5) && (zSlice <= boxLimits(m,6)-0.5)
                plot(boxPlot(:,1), boxPlot(:,2), '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 0.6 1], 'LineWidth', 1.0, 'Clipping', 'on');
            elseif (g2DOpt == 1) && (nPlanes > 1) && (pxlCentroids(m,3) == zSlice)
                plot(boxPlot(:,1), boxPlot(:,2), '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 0.6 1], 'LineWidth', 1.0, 'Clipping', 'on');
            elseif (g2DOpt == 1) && (nPlanes == 1)
                plot(boxPlot(:,1), boxPlot(:,2), '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 0.6 1], 'LineWidth', 1.0, 'Clipping', 'on');
            end
        end
    end

    % Plot Gaussian Centers of Current Points %
    for m = 1:sizeCurrent(1)
        mainFig;
        hold on;
        if (g3DOpt == 1) && (zSlice >= currentBB(m,5)+0.5) && (zSlice <= currentBB(m,6)-0.5)
            plot(currentPts(m,1)/xyRes + 0.5, currentPts(m,2)/xyRes + 0.5, '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 1 0.6], 'LineWidth', 1.0, 'Clipping', 'on');
            text(currentPts(m,1)/xyRes + 0.5 + 2.5, currentPts(m,2)/xyRes + 0.5 + 2, num2str(m), 'Fontsize', 8, 'Color', 'r', 'fontweight', 'bold', 'Clipping', 'on');
        elseif (g2DOpt == 1) && (nPlanes > 1) && (currentCentroids(m,3) == zSlice)
            plot(currentPts(m,1)/xyRes + 0.5, currentPts(m,2)/xyRes + 0.5, '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 1 0.6], 'LineWidth', 1.0, 'Clipping', 'on');
            text(currentPts(m,1)/xyRes + 0.5 + 2.5, currentPts(m,2)/xyRes + 0.5 + 2, num2str(m), 'Fontsize', 8, 'Color', 'r', 'fontweight', 'bold', 'Clipping', 'on');
        elseif (g2DOpt == 1) && (nPlanes == 1)
            plot(currentPts(m,1)/xyRes + 0.5, currentPts(m,2)/xyRes + 0.5, '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 1 0.6], 'LineWidth', 1.0, 'Clipping', 'on');
            text(currentPts(m,1)/xyRes + 0.5 + 2.5, currentPts(m,2)/xyRes + 0.5 + 2, num2str(m), 'Fontsize', 8, 'Color', 'r', 'fontweight', 'bold', 'Clipping', 'on');
        end
    end
    
    if nPlanes > 1
        try
            delete(h4);
            delete(anno4);
        end
        h4 = uicontrol('Parent', mainFig,'Style','slider','Position',[viewFigSize(1)*0.775, viewFigSize(2)*0.11,20,600],...
            'SliderStep', [1/(nPlanes-1) , 10/(nPlanes-1) ],...
            'value',zSlice, 'min', 1, 'max',nPlanes, 'Callback', {@updateVisualFigure2});
        anno4 = annotation('textbox', [0.77, 0.875, 0.025, 0.025], 'string', num2str(zSlice),'FontSize',7.5);
    end

    annotateFigure();
    set(gcf, 'WindowButtonDownFcn', @removeParticle);

end

%%

function updateVisualFigure2(~,~)

    global mainFig currentPts finalFitParams excludePts boxLimits... 
        zoomObj xyRes currentBB zSlice h4 currentIMG currentChannel...
        g2DOpt g3DOpt currentCentroids nPlanes anno4 pxlCentroids...

    warning off;
    
    mainFig;
    zoomObj = get(gca, {'xlim','ylim'});
    zSlice = round(get(h4, 'Value'));
    clearParticleN(mainFig);
    set(gca, {'xlim','ylim'}, zoomObj);
    hold on;
    xlabel('Double Click To Add Or Remove', 'FontSize', 10)

    sizeCurrent = size(currentPts);
    sizeFinalFit = size(finalFitParams);

    currentIMG = imshow(currentChannel(:,:,zSlice), [], 'InitialMagnification', 450);
    % Plot Bounding Boxes of Current Points %
    for m = 1:sizeFinalFit(1)

        if ~ismember(m,excludePts)
            boxPlot(1,:) = [boxLimits(m,1), boxLimits(m,3)];
            boxPlot(4,:) = [boxLimits(m,2), boxLimits(m,3)];
            boxPlot(2,:) = [boxLimits(m,1), boxLimits(m,4)];
            boxPlot(3,:) = [boxLimits(m,2), boxLimits(m,4)];
            boxPlot(5,:) = [boxLimits(m,1), boxLimits(m,3)];
            mainFig;
            hold on;
            if (g3DOpt == 1) && (zSlice >= boxLimits(m,5)+0.5) && (zSlice <= boxLimits(m,6)-0.5)
                plot(boxPlot(:,1), boxPlot(:,2), '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 0.6 1], 'LineWidth', 1.0, 'Clipping', 'on');
            elseif (g2DOpt == 1) && (nPlanes > 1) && (pxlCentroids(m,3) == zSlice)
                plot(boxPlot(:,1), boxPlot(:,2), '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 0.6 1], 'LineWidth', 1.0, 'Clipping', 'on');
            elseif (g2DOpt == 1) && (nPlanes == 1)
                plot(boxPlot(:,1), boxPlot(:,2), '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 0.6 1], 'LineWidth', 1.0, 'Clipping', 'on');
            end
        end
    end

    % Plot Gaussian Centers of Current Points %
    for m = 1:sizeCurrent(1)
        mainFig;
        hold on;
        if (g3DOpt == 1) && (zSlice >= currentBB(m,5)+0.5) && (zSlice <= currentBB(m,6)-0.5)
            plot(currentPts(m,1)/xyRes + 0.5, currentPts(m,2)/xyRes + 0.5, '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 1 0.6], 'LineWidth', 1.0, 'Clipping', 'on');
            text(currentPts(m,1)/xyRes + 0.5 + 2.5, currentPts(m,2)/xyRes + 0.5 + 2, num2str(m), 'Fontsize', 8, 'Color', 'r', 'fontweight', 'bold', 'Clipping', 'on');
        elseif (g2DOpt == 1) && (nPlanes > 1) && (currentCentroids(m,3) == zSlice)
            plot(currentPts(m,1)/xyRes + 0.5, currentPts(m,2)/xyRes + 0.5, '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 1 0.6], 'LineWidth', 1.0, 'Clipping', 'on');
            text(currentPts(m,1)/xyRes + 0.5 + 2.5, currentPts(m,2)/xyRes + 0.5 + 2, num2str(m), 'Fontsize', 8, 'Color', 'r', 'fontweight', 'bold', 'Clipping', 'on');
        elseif (g2DOpt == 1) && (nPlanes == 1)
            plot(currentPts(m,1)/xyRes + 0.5, currentPts(m,2)/xyRes + 0.5, '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 1 0.6], 'LineWidth', 1.0, 'Clipping', 'on');
            text(currentPts(m,1)/xyRes + 0.5 + 2.5, currentPts(m,2)/xyRes + 0.5 + 2, num2str(m), 'Fontsize', 8, 'Color', 'r', 'fontweight', 'bold', 'Clipping', 'on');
        end
    end
    
    if nPlanes > 1
        try
            delete(anno4);
        end
        anno4 = annotation('textbox', [0.77, 0.875, 0.025, 0.025], 'string', num2str(zSlice),'FontSize',7.5);
    end

    annotateFigure();
    set(gcf, 'WindowButtonDownFcn', @removeParticle);

end

%%
function extractAll3DGauss()

    global  excludePts boxLimits sizeCentroids finalFitParams...
            currentIMG trueCentroids currentChannel xyRes h4...
            currentPts zoomObj mainFig bgOpt overlapOpt overlapThreshold...
            sizeOpt sizeL sizeU gaussFitted zSlice nPlanes viewFigSize...
            anno4 h4 gauss3DN
            

    excludePts = [];
    boxLimits = zeros(sizeCentroids(1),6);

    finalFitParams = zeros(sizeCentroids(1), gauss3DN);

    mainFig;
    warning off;
    zoomObj = get(gca, {'xlim','ylim'});
    clearParticleN(mainFig);
    currentIMG = imshow(currentChannel(:,:,zSlice), [], 'InitialMagnification', 450);
    xlabel('Double Click To Add Or Remove', 'FontSize', 10)
    set(gca, {'xlim','ylim'}, zoomObj);
    hold on;

    disp('.');
    disp('Fitting 3D Gaussian for Detected Particles:');
    tic
    for i = 1:sizeCentroids(1)

        pN = i;
        if (bgOpt == 0)
            [particleBB, boxPts, boxPlot] = extractBoundBox(pN, currentChannel);
        elseif (bgOpt == 1)
            [particleBB, boxPts, boxPlot, percBG] = extractBoundBoxBG(pN, currentChannel);
        end
        boxLimits(i,1) = boxPts(1,1)-0.5;
        boxLimits(i,2) = boxPts(1,2)+0.5;
        boxLimits(i,3) = boxPts(2,1)-0.5;
        boxLimits(i,4) = boxPts(2,2)+0.5;
        boxLimits(i,5) = boxPts(3,1)-0.5;
        boxLimits(i,6) = boxPts(3,2)+0.5;

        [bbCoords] = extractBBCoords(particleBB);
        try
            [fitParams] = fit3DGauss(particleBB, bbCoords, boxPts);
        catch
            fitParams = zeros(1,gauss3DN);
            finalFitParams(i,:) = fitParams;
        end

        if mod(i,2) == 0
            disp(strcat(strcat('Current Progress: ', num2str(round(100*(i/sizeCentroids(1)), 1, 'decimals'))), '%'));
        end

        % Filter Conditions for Particles %
        if size(finalFitParams,2) == size(fitParams,2)
            finalFitParams(i,:) = fitParams;
            if sum(fitParams) == 0
                disp(strcat('Particle #', strcat(num2str(i), ' was fitted incorrectly and has been removed.')));
                excludePts(end+1) = i;
            elseif (fitParams(17) == 0) || (fitParams(18) == 0)
                disp(strcat('Particle #', strcat(num2str(i), ' X or Y FWHM did not fit properly.')));
            else
                if (fitParams(19) == 0)
                    disp(strcat('Particle #', strcat(num2str(i), ' Z FWHM did not fit properly.')));
                end
                if (zSlice >= boxPts(3,1)) && (zSlice <= boxPts(3,2))
                    % For Visualization %
                    plot(boxPlot(:,1), boxPlot(:,2), '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 0.6 1], 'LineWidth', 1.0, 'Clipping', 'on');
                    % Numbering Particles
                    text(trueCentroids(i,1)+2.5, trueCentroids(i,2)+2, num2str(i), 'Fontsize', 8, 'Color', 'r', 'fontweight', 'bold', 'Clipping', 'on');
                    plot(toPixelScale(fitParams(1),xyRes), toPixelScale(fitParams(2),xyRes), '-s', 'MarkerSize', 6, 'MarkerEdgeColor', 'green', 'MarkerFaceColor', [1 0.6 0.1], 'Clipping', 'on');
                end
            end
        else
            disp(strcat('Particle #', strcat(num2str(i), ' was fitted incorrectly and has been removed.')));
            excludePts(end+1) = i;
        end
        
        if i == sizeCentroids(1)
            disp('.');
            disp('3D Gaussian Fitting Completed Successfully.');
            disp('*********************************************************************');
        end
    
    end
    toc
    zoomObj = get(gca, {'xlim','ylim'});
    outTest = isoutlier(finalFitParams(:,gauss3DN));
    finalFitParams = [finalFitParams outTest];
    currentPts = finalFitParams;
    finalFitParams = [finalFitParams ones(sizeCentroids(1),1)];
    
    if (overlapOpt == 1)
        overlapFilterCurrPts(overlapThreshold);
    end
    if (sizeOpt == 1)
        sizeFilterCurrPts(sizeL, sizeU)
    end
    
    if nPlanes > 1
        try
            delete(h4);
            delete(anno4);
        end
        h4 = uicontrol('Parent', mainFig,'Style','slider','Position',[viewFigSize(1)*0.775, viewFigSize(2)*0.11,20,600],...
            'SliderStep', [1/(nPlanes-1) , 10/(nPlanes-1) ],...
            'value',zSlice, 'min', 1, 'max',nPlanes, 'Callback', {@updateVisualFigure2});
        anno4 = annotation('textbox', [0.77, 0.875, 0.025, 0.025], 'string', num2str(zSlice),'FontSize',7.5);
    end
    
    gaussFitted = true;
    
    updateCurrentPts();
    updateVisualFigure();
    selectParticles();
    chooseParticleButton();

end

%%

function [pxlCoord] = toPixelScale(val1, pxlRes)

    pxlCoord = val1/pxlRes + 0.5;

end


%%

function overlapFinal = bbOverlap3D(pN1, pN2, channelData)

    [particleBB1, bbPts1, boxPlot1] = extractBoundBox(pN1, channelData);
    [particleBB2, bbPts2, boxPlot2] = extractBoundBox(pN2, channelData);

    xyBB1 = [bbPts1(1,1), bbPts1(2,1), bbPts1(1,2)-bbPts1(1,1)+1, bbPts1(2,2)-bbPts1(2,1)+1];
    xzBB1 = [bbPts1(1,1), bbPts1(3,1), bbPts1(1,2)-bbPts1(1,1)+1, bbPts1(3,2)-bbPts1(3,1)+1];
    yzBB1 = [bbPts1(2,1), bbPts1(3,1), bbPts1(2,2)-bbPts1(2,1)+1, bbPts1(3,2)-bbPts1(3,1)+1];
    xyBB2 = [bbPts2(1,1), bbPts2(2,1), bbPts2(1,2)-bbPts2(1,1)+1, bbPts2(2,2)-bbPts2(2,1)+1];
    xzBB2 = [bbPts2(1,1), bbPts2(3,1), bbPts2(1,2)-bbPts2(1,1)+1, bbPts2(3,2)-bbPts2(3,1)+1];
    yzBB2 = [bbPts2(2,1), bbPts2(3,1), bbPts2(2,2)-bbPts2(2,1)+1, bbPts2(3,2)-bbPts2(3,1)+1];

    overlapXY = bboxOverlapRatio(xyBB1, xyBB2);
    overlapXZ = bboxOverlapRatio(xzBB1, xzBB2);
    overlapYZ = bboxOverlapRatio(yzBB1, yzBB2);

    overlapP1XY = overlapXY*(1 + ((bbPts2(2,2)-bbPts2(2,1)+1)*(bbPts2(1,2)-bbPts2(1,1)+1))/((bbPts1(2,2)-bbPts1(2,1)+1)*(bbPts1(1,2)-bbPts1(1,1)+1)))/(1+overlapXY);
    overlapP2XY = overlapXY*(1 + ((bbPts1(2,2)-bbPts1(2,1)+1)*(bbPts1(1,2)-bbPts1(1,1)+1))/((bbPts2(2,2)-bbPts2(2,1)+1)*(bbPts2(1,2)-bbPts2(1,1)+1)))/(1+overlapXY);

    overlapP1XZ = overlapXZ*(1 + ((bbPts2(3,2)-bbPts2(3,1)+1)*(bbPts2(1,2)-bbPts2(1,1)+1))/((bbPts1(3,2)-bbPts1(3,1)+1)*(bbPts1(1,2)-bbPts1(1,1)+1)))/(1+overlapXZ);
    overlapP2XZ = overlapXZ*(1 + ((bbPts1(3,2)-bbPts1(3,1)+1)*(bbPts1(1,2)-bbPts1(1,1)+1))/((bbPts2(3,2)-bbPts2(3,1)+1)*(bbPts2(1,2)-bbPts2(1,1)+1)))/(1+overlapXZ);

    overlapP1YZ = overlapYZ*(1 + ((bbPts2(3,2)-bbPts2(3,1)+1)*(bbPts2(2,2)-bbPts2(2,1)+1))/((bbPts1(3,2)-bbPts1(3,1)+1)*(bbPts1(2,2)-bbPts1(2,1)+1)))/(1+overlapYZ);
    overlapP2YZ = overlapYZ*(1 + ((bbPts1(3,2)-bbPts1(3,1)+1)*(bbPts1(2,2)-bbPts1(2,1)+1))/((bbPts2(3,2)-bbPts2(3,1)+1)*(bbPts2(2,2)-bbPts2(2,1)+1)))/(1+overlapYZ);

    overlapFinal = [overlapP1XY overlapP2XY; overlapP1XZ overlapP2XZ; overlapP1YZ overlapP2YZ];

end

%%

function overlapFinal = bbOverlap2D(pN1, pN2, channelData)

    [particleBB1, bbPts1, boxPlot1] = extractBoundBox(pN1, channelData);
    [particleBB2, bbPts2, boxPlot2] = extractBoundBox(pN2, channelData);

    xyBB1 = [bbPts1(1,1), bbPts1(2,1), bbPts1(1,2)-bbPts1(1,1)+1, bbPts1(2,2)-bbPts1(2,1)+1];
    xyBB2 = [bbPts2(1,1), bbPts2(2,1), bbPts2(1,2)-bbPts2(1,1)+1, bbPts2(2,2)-bbPts2(2,1)+1];

    overlapXY = bboxOverlapRatio(xyBB1, xyBB2);

    overlapP1XY = overlapXY*(1 + ((bbPts2(2,2)-bbPts2(2,1)+1)*(bbPts2(1,2)-bbPts2(1,1)+1))/((bbPts1(2,2)-bbPts1(2,1)+1)*(bbPts1(1,2)-bbPts1(1,1)+1)))/(1+overlapXY);
    overlapP2XY = overlapXY*(1 + ((bbPts1(2,2)-bbPts1(2,1)+1)*(bbPts1(1,2)-bbPts1(1,1)+1))/((bbPts2(2,2)-bbPts2(2,1)+1)*(bbPts2(1,2)-bbPts2(1,1)+1)))/(1+overlapXY);

    overlapFinal = [overlapP1XY overlapP2XY];

end

%%

function overlapFilterCurrPts(overlapThreshold)

    global  currentPts excludePts mainFig zoomObj currentChannel g2DOpt...
            g3DOpt

    mainFig;
    zoomObj = get(gca, {'xlim','ylim'});
    currSize = size(currentPts);
    bbExclude = [];
    disp('Filtering Overlapping Particles...');
    for i = 1:currSize(1)

        for j = i:currSize(1)

            if i ~= j
                
                if (length(size(currentChannel)) == 3) && (g3DOpt == 1)
                    overlapVec = bbOverlap3D(i, j, currentChannel);
                    if ((overlapVec(1,1) > overlapThreshold) && ((overlapVec(2,1) > overlapThreshold) || (overlapVec(3,1) > overlapThreshold)))
                        bbExclude(end+1) = i;
                    end
                    if ((overlapVec(1,2) > overlapThreshold) && ((overlapVec(2,2) > overlapThreshold) || (overlapVec(3,2) > overlapThreshold)))
                        bbExclude(end+1) = j;
                    end
                end
                
                if ((length(size(currentChannel)) == 3) && (g2DOpt == 1)) || ((length(size(currentChannel)) == 2) && (g2DOpt == 1))
                    overlapVec = bbOverlap2D(i, j, currentChannel);
                    if (overlapVec(1) > overlapThreshold)
                        bbExclude(end+1) = i;
                    end
                    if (overlapVec(2) > overlapThreshold)
                        bbExclude(end+1) = j;
                    end
                   
                end

            end

        end

        if mod(i,5) == 0
            perc = 100*i/currSize(1);
            str1 = strcat(num2str(round(perc,1,'decimals')),'%');
            disp(strcat('Current Progress:',str1));
        end
    end

    disp('.');
    disp('Particle Filtering Complete.');
    disp('.............................................');
    bbExclude = unique(bbExclude);
    excludePts = [excludePts bbExclude];
    excludePts = unique(excludePts);
    updateCurrentPts();

end

%%

function f = gauss2D(params, bbCoords)

    % Coordinates %
    xi = bbCoords(1,:);
    yi = bbCoords(2,:);
    
    % Parameters %
    meanX = params(1);
    meanY = params(2);
    
    theta = params(3);
    
    sigmaX = params(4);
    sigmaY = params(5);
    
    gaussBase = params(6);
    coeffA0 = params(7);
    
    % Translation and Rotation %
    
    trans_x = xi - meanX;
    trans_y = yi - meanY;
    x = trans_x*cos(-theta) - trans_y*sin(-theta);
    y = trans_x*sin(-theta) + trans_y*cos(-theta);
    
    expX = exp(-0.5*x.*x/(sigmaX*sigmaX));
    expY = exp(-0.5*y.*y/(sigmaY*sigmaY));
    
    f = gaussBase + coeffA0*expX.*expY;

end

%%

function [fitParams] = fit2DGauss(particleBB, bbCoords, boxPts)

    global xyRes fwhmDiv
    
    if isempty(xyRes)
        disp('ERROR: Pixel scaling is not properly set!')
        return;
    end
    
    bbSize = size(particleBB);
    bbSize(1) = bbSize(1)*xyRes;
    bbSize(2) = bbSize(2)*xyRes;
    
    scaledCoords = bbCoords(1:2,:);
    scaledCoords(1:2,:) = (bbCoords(1:2,:)-0.5)*xyRes;
    
    intensityVals = bbCoords(3,:);

    baseGuess = min(min(min(particleBB)));
    ampGuess = max(max(max(particleBB)))-baseGuess;

    sigmaX = bbSize(2)/2;
    sigmaY = bbSize(1)/2;

    params = [0 0 0 sigmaX sigmaY baseGuess ampGuess];

    lb = [min(scaledCoords(1,:)), min(scaledCoords(2,:)), -pi, sigmaX/10, sigmaY/10, baseGuess/2, 1];
    ub = [bbSize(2), bbSize(1), pi, sigmaX*2, sigmaY*2, baseGuess*3, ampGuess*2-baseGuess];

    [fitParams, resnorm] = lsqcurvefit(@gauss2D, params, scaledCoords, intensityVals, lb, ub, optimset('Display','off'));

    % Correct for Frame of Reference %
    trueX = fitParams(1)+ (boxPts(1,1)-1)*xyRes;
    trueY = fitParams(2)+ (boxPts(2,1)-1)*xyRes;
    
    fitX = fitParams(1);
    fitY = fitParams(2);
       
    fitParams(1) = trueX;
    fitParams(2) = trueY;
    
    FWHM_X = 2*sqrt(2*log(2))*fitParams(4);
    FWHM_Y = 2*sqrt(2*log(2))*fitParams(5);
    
    rotCoords = zeros(2, size(scaledCoords,2));
    rotCoords(1,:) = scaledCoords(1,:)*cos(fitParams(3)) - scaledCoords(2,:)*sin(fitParams(3));
    rotCoords(2,:) = scaledCoords(1,:)*sin(fitParams(3)) + scaledCoords(2,:)*cos(fitParams(3));
    rotX = fitX*cos(fitParams(3)) - fitY*sin(fitParams(3));
    rotY = fitX*sin(fitParams(3)) + fitY*cos(fitParams(3));
    
    closeX = (  (rotCoords(1,:) <= (rotX + xyRes/fwhmDiv)) & (rotCoords(1,:) >= (rotX - xyRes/fwhmDiv))   );
    closeY = (  (rotCoords(2,:) <= (rotY + xyRes/fwhmDiv)) & (rotCoords(2,:) >= (rotY - xyRes/fwhmDiv))   );

    dataX = zeros(2, sum(closeY));
    dataX(1,:) = rotCoords(1, closeY == 1);
    dataX(2,:) = intensityVals(1, closeY == 1);

    dataY = zeros(2, sum(closeX));
    dataY(1,:) = rotCoords(2, closeX == 1);
    dataY(2,:) = intensityVals(1, closeX == 1);
    
    try
        sizeX = fitHalfHeight(dataX, fitParams(6));
        if isempty(sizeX)
            sizeX = NaN;
        end
    catch
        sizeX = NaN;
    end
    try
        sizeY = fitHalfHeight(dataY, fitParams(6));
        if isempty(sizeY)
            sizeY = NaN;
        end
    catch
        sizeY = NaN;
    end
    
    if isempty(resnorm)
        resnorm = NaN;
    end
    
    % Determine Interpolated FWHM %
    
    InterpFunction = scatteredInterpolant(rotCoords(1,:)',rotCoords(2,:)',intensityVals(1,:)','natural','nearest');
    
    xRange = bbSize(2);
    yRange = bbSize(1);
    
    nSampleX = xRange/xyRes;
    nSampleY = yRange/xyRes;
    
    newX = rotX-(xRange/2):xRange/(nSampleX-1):rotX+(xRange/2);
    newX_I = InterpFunction(newX,rotY+zeros(1,size(newX,2)));
    
    newY = rotY-(yRange/2):yRange/(nSampleY-1):rotY+(yRange/2);
    newY_I = InterpFunction(rotX+zeros(1,size(newY,2)),newY);
    
    dataX2 = [newX; newX_I];
    dataY2 = [newY; newY_I];
    
    dataX2 = sortrows(dataX2',1)';    
    dataY2 = sortrows(dataY2',1)';
    
    try
        sizeX2 = fitHalfHeight(dataX2, fitParams(6));
        if isempty(sizeX2)
            sizeX2 = NaN;
        end
    catch
        sizeX2 = NaN;
    end
    try
        sizeY2 = fitHalfHeight(dataY2, fitParams(6));
        if isempty(sizeY2)
            sizeY2 = NaN;
        end
    catch
        sizeY2 = NaN;
    end
    if isempty(resnorm)
        resnorm = NaN;
    end  
    
    fitParams = [fitParams FWHM_X FWHM_Y sum(intensityVals) max(intensityVals) sizeX sizeY sizeX2 sizeY2 resnorm/size(scaledCoords,2)];

end

%%

function extractAll2DGauss()

    global  excludePts boxLimits sizeCentroids finalFitParams...
            currentMaxIMG trueCentroids currentChannel xyRes...
            currentPts zoomObj mainFig bgOpt overlapOpt overlapThreshold...
            imgSize sizeOpt sizeL sizeU gaussFitted gauss2DN
            

    excludePts = [];
    boxLimits = zeros(sizeCentroids(1),4);

    finalFitParams = zeros(sizeCentroids(1), gauss2DN);

    mainFig;
    warning off;
    zoomObj = get(gca, {'xlim','ylim'});
    clearParticleN(mainFig);
    xlabel('Double Click To Add Or Remove', 'FontSize', 10)
    set(gca, {'xlim','ylim'}, zoomObj);
    hold on;

    disp('.');
    disp('Fitting 2D Gaussian for Detected Particles:');

    for i = 1:sizeCentroids(1)

        pN = i;
        if (bgOpt == 0)
            [particleBB, boxPts, boxPlot] = extractBoundBox(pN, currentChannel);
        elseif (bgOpt == 1)
            [particleBB, boxPts, boxPlot, percBG] = extractBoundBoxBG(pN, currentChannel);
        end
        boxLimits(i,1) = boxPts(1,1)-0.5;
        boxLimits(i,2) = boxPts(1,2)+0.5;
        boxLimits(i,3) = boxPts(2,1)-0.5;
        boxLimits(i,4) = boxPts(2,2)+0.5;

%         % For Visualization %
%         plot(boxPlot(:,1), boxPlot(:,2), '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 0.6 1], 'LineWidth', 1.0, 'Clipping', 'on');
%         % Numbering Particles
%         text(trueCentroids(i,1)+2.5, trueCentroids(i,2)+2, num2str(i), 'Fontsize', 8, 'Color', 'r', 'fontweight', 'bold', 'Clipping', 'on');

        [bbCoords] = extractBBCoords(particleBB);
        try
            [fitParams] = fit2DGauss(particleBB, bbCoords, boxPts);
        catch
            fitParams = zeros(1,gauss2DN);
            finalFitParams(i,:) = fitParams;
        end

        if mod(i,2) == 0
            disp(strcat(strcat('Current Progress: ', num2str(round(100*(i/sizeCentroids(1)), 1, 'decimals'))), '%'));
        end

        % Filter Conditions for Particles %
        if size(finalFitParams,2) == size(fitParams,2)
            finalFitParams(i,:) = fitParams;
            if sum(fitParams) == 0
                disp(strcat('Particle #', strcat(num2str(i), ' was fitted incorrectly and has been removed.')));
                excludePts(end+1) = i;
            elseif (fitParams(12) == 0) || (fitParams(13) == 0)
                disp(strcat('Particle #', strcat(num2str(i), ' X or Y FWHM did not fit properly.')));
%             else
%                 plot(toPixelScale(fitParams(1),xyRes), toPixelScale(fitParams(2),xyRes), '-s', 'MarkerSize', 6, 'MarkerEdgeColor', 'green', 'MarkerFaceColor', [1 0.6 0.1], 'Clipping', 'on');
            end
        else
            disp(strcat('Particle #', strcat(num2str(i), ' was fitted incorrectly and has been removed.')));
            excludePts(end+1) = i;
        end
        
        if i == sizeCentroids(1)
            disp('.');
            disp('2D Gaussian Fitting Completed Successfully.');
            disp('*********************************************************************');
        end

    end

    zoomObj = get(gca, {'xlim','ylim'});
    outTest = isoutlier(finalFitParams(:,gauss2DN));
    finalFitParams = [finalFitParams outTest];
    currentPts = finalFitParams;
    finalFitParams = [finalFitParams ones(sizeCentroids(1),1)];
    
    if (overlapOpt == 1)
        overlapFilterCurrPts(overlapThreshold);
    end
    if (sizeOpt == 1)
        sizeFilterCurrPts(sizeL, sizeU)
    end
    
    gaussFitted = true;
    
    updateCurrentPts();
    updateVisualFigure();
    selectParticles();
    chooseParticleButton()

end

%%

function extractAll2DGauss3DOpt()

    global  excludePts boxLimits sizeCentroids finalFitParams...
            currentMaxIMG trueCentroids currentChannel xyRes...
            currentPts zoomObj mainFig bgOpt overlapOpt overlapThreshold...
            imgSize sizeOpt sizeL sizeU gaussFitted zSlice...
            viewFigSize nPlanes h4 anno4 gauss2DN
            

    excludePts = [];
    boxLimits = zeros(sizeCentroids(1),4);

    finalFitParams = zeros(sizeCentroids(1), gauss2DN);

    mainFig;
    warning off;
    zoomObj = get(gca, {'xlim','ylim'});
    clearParticleN(mainFig);
    xlabel('Double Click To Add Or Remove', 'FontSize', 10)
    set(gca, {'xlim','ylim'}, zoomObj);
    hold on;

    disp('.');
    disp('Fitting 2D Gaussian for Best Focal Plane of Detected Particles:');
    tic
    for i = 1:sizeCentroids(1)

        pN = i;
        if (bgOpt == 0)
            [particleBB, boxPts, boxPlot] = extractBoundBox(pN, currentChannel);
        elseif (bgOpt == 1)
            [particleBB, boxPts, boxPlot, percBG] = extractBoundBoxBG(pN,  currentChannel);
        end
        boxLimits(i,1) = boxPts(1,1)-0.5;
        boxLimits(i,2) = boxPts(1,2)+0.5;
        boxLimits(i,3) = boxPts(2,1)-0.5;
        boxLimits(i,4) = boxPts(2,2)+0.5;

%         % For Visualization %
%         plot(boxPlot(:,1), boxPlot(:,2), '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 0.6 1], 'LineWidth', 1.0, 'Clipping', 'on');
%         % Numbering Particles
%         text(trueCentroids(i,1)+2.5, trueCentroids(i,2)+2, num2str(i), 'Fontsize', 8, 'Color', 'r', 'fontweight', 'bold', 'Clipping', 'on');

        [bbCoords] = extractBBCoords(particleBB);
        
        % Test Fitting Success %
        try
            [fitParams] = fit2DGauss(particleBB, bbCoords, boxPts);
        catch
            fitParams = zeros(1,gauss2DN);
            finalFitParams(i,:) = fitParams;
        end
        
        if mod(i,2) == 0
            disp(strcat(strcat('Current Progress: ', num2str(round(100*(i/sizeCentroids(1)), 1, 'decimals'))), '%'));
        end

        % Filter Conditions for Particles %
        if size(finalFitParams,2) == size(fitParams,2)
            finalFitParams(i,:) = fitParams;
            if sum(fitParams) == 0
                disp(strcat('Particle #', strcat(num2str(i), ' was fitted incorrectly and has been removed.')));
                excludePts(end+1) = i;
            elseif (fitParams(12) == 0) || (fitParams(13) == 0)
                disp(strcat('Particle #', strcat(num2str(i), ' X or Y FWHM did not fit properly.')));
%             else
%                 plot(toPixelScale(fitParams(1),xyRes), toPixelScale(fitParams(2),xyRes), '-s', 'MarkerSize', 6, 'MarkerEdgeColor', 'green', 'MarkerFaceColor', [1 0.6 0.1], 'Clipping', 'on');
            end
        else
            disp(strcat('Particle #', strcat(num2str(i), ' was fitted incorrectly and has been removed.')));
            excludePts(end+1) = i;
        end

        if i == sizeCentroids(1)
            disp('.');
            disp('2D Gaussian Fitting Completed Successfully.');
            disp('*********************************************************************');
        end
       
    end
    toc 
    zoomObj = get(gca, {'xlim','ylim'});
    outTest = isoutlier(finalFitParams(:,gauss2DN));
    finalFitParams = [finalFitParams outTest];
    currentPts = finalFitParams;
    finalFitParams = [finalFitParams ones(sizeCentroids(1),1)];
    
    if nPlanes > 1
        try
            delete(h4);
            delete(anno4);
        end
        h4 = uicontrol('Parent', mainFig,'Style','slider','Position',[viewFigSize(1)*0.775, viewFigSize(2)*0.11,20,600],...
            'SliderStep', [1/(nPlanes-1) , 10/(nPlanes-1) ],...
            'value',zSlice, 'min', 1, 'max',nPlanes, 'Callback', {@updateVisualFigure2});
        anno4 = annotation('textbox', [0.77, 0.875, 0.025, 0.025], 'string', num2str(zSlice),'FontSize',7.5);
    end
    
    if (overlapOpt == 1)
        overlapFilterCurrPts(overlapThreshold);
    end
    if (sizeOpt == 1)
        sizeFilterCurrPts(sizeL, sizeU)
    end
    
    gaussFitted = true;
    
    updateCurrentPts();
    updateVisualFigure();
    selectParticles();
    chooseParticleButton();

end

%%

function sizePrediction = fitHalfHeight(profData, baseLine)

    profData = sortrows(profData.',1).';
    binX = profData(1,:);
    binY = profData(2,:);
    tempsize = length(binY);
    baseline = baseLine;
    %baseline = min(binY);
    peakInd = find(binY >= max(binY), 1, 'first');
    
    i1 = find(binY(1:peakInd) <= (((max(binY)-baseline)/2)+baseline), 1, 'last');
    i2 = find(binY((peakInd+1):tempsize) <= (((max(binY)-baseline)/2)+baseline), 1, 'first')+peakInd;

    indCenter = find(binY >= max(binY), 1, 'first');

    start1 = i1;
    end1 = i1+1;
    start2 = i2-1;
    end2 = i2;

    m1 = (binY(end1)-binY(start1))/(binX(end1)-binX(start1));
    X1 = ((((max(binY)-baseline)/2)+baseline)-binY(start1))/m1 + binX(start1);

    m2 = (binY(end2)-binY(start2))/(binX(end2)-binX(start2));
    X2 = ((((max(binY)-baseline)/2)+baseline)-binY(start2))/m2 + binX(start2);

    sizePrediction = sqrt((X2-X1)^2);

    %centerPrediction = binX(indCenter);

end

%%

function sizeFilterCurrPts(sizeL, sizeU)

    global bbCentroids excludePts currentChannel g3DOpt g2DOpt 
    
    tempExclude = [];
    
    for i = 1:size(bbCentroids,1)
        
        
        % If Data is 3D with 3D Option %
        if (length(size(currentChannel)) == 3) && (g3DOpt == 1)
            
            if (bbCentroids(i,4) < sizeL) || (bbCentroids(i,5) < sizeL) || (bbCentroids(i,6) < sizeL) ||...
                    (bbCentroids(i,4) > sizeU) || (bbCentroids(i,5) > sizeU)
                tempExclude(end+1) = i;
            end
        
        % If Data is 3D with 3D Option %
        elseif (length(size(currentChannel)) == 3) && (g2DOpt == 1)
            if (bbCentroids(i,4) < sizeL) || (bbCentroids(i,5) < sizeL) ||...
                    (bbCentroids(i,4) > sizeU) || (bbCentroids(i,5) > sizeU)
                tempExclude(end+1) = i;
            end
            
        end
        
        % If Data is 2D with 2D Option %
        if ((length(size(currentChannel)) == 2) && (g2DOpt == 1))

            if (bbCentroids(i,3) < sizeL) || (bbCentroids(i,4) < sizeL) ||...
                    (bbCentroids(i,3) > sizeU) || (bbCentroids(i,4) > sizeU) 
                tempExclude(end+1) = i;
            end
            
        end
        
        if mod(i,5) == 0
            disp(strcat(strcat('Current Progress: ', num2str(round(100*(i/size(bbCentroids,1)), 1, 'decimals'))), '%'));
        end
        
    end
    
    
    disp('Size Filtering Completed.');
    disp('................................................');
    
    
    tempExclude = unique(tempExclude);
    excludePts = [excludePts tempExclude];
    excludePts = unique(excludePts);
    updateCurrentPts();
    
end

%%

function annotateFigure()

    global mainFig
    
    mainFig;
    annotation('textbox', [0.041, 0.43, 0.1, 0.1], 'string', 'BOUNDING BOX BUFFER', 'FontSize', 9, 'fontweight', 'bold', 'EdgeColor', 'none', 'Color', [0,0,0.8]);
    annotation('textbox', [0.025, 0.45, 0.1, 0.05], 'string', 'XY Box Buffer (0-1)', 'FontSize', 7, 'fontweight', 'bold', 'EdgeColor', 'none');
    annotation('textbox', [0.115, 0.45, 0.1, 0.05], 'string', 'Z Box Buffer (0-1)', 'FontSize', 7, 'fontweight', 'bold', 'EdgeColor', 'none');
    annotation('textbox', [0.044, 0.28, 0.1, 0.1], 'string', 'PARTICLE SIZE FILTER', 'FontSize', 9, 'fontweight', 'bold', 'EdgeColor', 'none', 'Color', [0.8,0.4,0]);
    annotation('textbox', [0.027, 0.3, 0.1, 0.05], 'string', 'Lower Limit (pxls)', 'FontSize', 7, 'fontweight', 'bold', 'EdgeColor', 'none');
    annotation('textbox', [0.112, 0.3, 0.1, 0.05], 'string', 'Upper Limit (pxls)', 'FontSize', 7, 'fontweight', 'bold', 'EdgeColor', 'none');
    
end

%%

function chooseParticleButton()

    global mainFig zoomObj viewFigSize
    
    uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.9001, viewFigSize(2)*0.735, 60, 15],...
            'String', 'SELECT', 'FontSize', 7, 'BackgroundColor',[1,0.75,0.75], 'Callback', {@chooseParticleButton});
    
    function chooseParticleButton(~,~)
        
        mainFig;
        zoomObj = get(gca, {'xlim','ylim'});
        set(gcf, 'WindowButtonDownFcn', @removeParticle);
        
    end

end

%%

function findStartThreshold()

    global  startThreshold currentChannel filtInterval countThreshold...
            sizeCentroids
    
    disp('Identifying Ideal Threshold...');
    interv = 0.5;
    startThreshold = 0.8;
    [Ibw] = binarizeIMG(currentChannel, filtInterval, startThreshold, 0);
    getCentroids(Ibw,0);

    while sizeCentroids(1) == 0
        [Ibw] = binarizeIMG(currentChannel, filtInterval, startThreshold, 0);
        getCentroids(Ibw,0);
        startThreshold = startThreshold + interv;
    end

    startThreshold = startThreshold - interv;
    countThreshold = startThreshold;

end

%%

function plotChannelPts(chFitData, chBB, chCentroids)

    global mainFig xyRes zoomObj g3DOpt g2DOpt nPlanes zSlice

    zoomObj = get(gca, {'xlim','ylim'});
    disp('Updating Figure...')
    for m = 1:size(chFitData,1)
        
        boxPlot(1,:) = [chBB(m,1), chBB(m,3)];
        boxPlot(4,:) = [chBB(m,2), chBB(m,3)];
        boxPlot(2,:) = [chBB(m,1), chBB(m,4)];
        boxPlot(3,:) = [chBB(m,2), chBB(m,4)];
        boxPlot(5,:) = [chBB(m,1), chBB(m,3)];
        mainFig;
        hold on;
        if (g3DOpt == 1) %&& (zSlice >= chBB(m,5)+0.5) && (zSlice <= chBB(m,6)-0.5)
            plot(boxPlot(:,1), boxPlot(:,2), '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 0.6 1], 'LineWidth', 1.0, 'Clipping', 'on');
            plot(chFitData(m,1)/xyRes + 0.5, chFitData(m,2)/xyRes + 0.5, '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 1 0.6], 'LineWidth', 1.0, 'Clipping', 'on');
            text(chFitData(m,1)/xyRes + 0.5 + 2.5, chFitData(m,2)/xyRes + 0.5 + 2, num2str(m), 'Fontsize', 8, 'Color', 'r', 'fontweight', 'bold', 'Clipping', 'on');
        elseif (g2DOpt == 1) && (nPlanes > 1) %&& (chCentroids(m,3) == zSlice)
            plot(boxPlot(:,1), boxPlot(:,2), '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 0.6 1], 'LineWidth', 1.0, 'Clipping', 'on');
            plot(chFitData(m,1)/xyRes + 0.5, chFitData(m,2)/xyRes + 0.5, '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 1 0.6], 'LineWidth', 1.0, 'Clipping', 'on');
            text(chFitData(m,1)/xyRes + 0.5 + 2.5, chFitData(m,2)/xyRes + 0.5 + 2, num2str(m), 'Fontsize', 8, 'Color', 'r', 'fontweight', 'bold', 'Clipping', 'on');
        elseif (g2DOpt == 1) && (nPlanes == 1)
            plot(boxPlot(:,1), boxPlot(:,2), '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 0.6 1], 'LineWidth', 1.0, 'Clipping', 'on');
            plot(chFitData(m,1)/xyRes + 0.5, chFitData(m,2)/xyRes + 0.5, '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 1 0.6], 'LineWidth', 1.0, 'Clipping', 'on');
            text(chFitData(m,1)/xyRes + 0.5 + 2.5, chFitData(m,2)/xyRes + 0.5 + 2, num2str(m), 'Fontsize', 8, 'Color', 'r', 'fontweight', 'bold', 'Clipping', 'on');
        end
        
        if mod(m,10) == 0
            perc = 100*m/size(chFitData,1);
            str1 = strcat(num2str(round(perc,1,'decimals')),'%');
            disp(strcat('Current Progress:',str1));
        end
    end
    disp('Figure Updated.')
    disp('...........................................')
    set(gca, {'xlim','ylim'}, zoomObj);
end


%%

function exportData(~, ~)
            
    global fullPath exportPath finalFit488 finalBB488 finalFit594...
            finalBB594 finalFit640 finalBB640 finalFit405 finalBB405...
            nOptions channel1 channel2 channel3 channel4 xyRes...
            anaParams488 anaParams594 anaParams640 anaParams405...
            distMatrix488 distMatrix594 distMatrix640 distMatrix405...
            distMatrix488_594 distMatrix488_640 distMatrix488_405...
            distMatrix594_640 distMatrix594_405 distMatrix640_405...
            ab488_594 ab488_640 ab488_405 ab594_640 ab594_405 ab640_405...
            multi488 multi594 multi640 multi405 cropROI finalCentroids488...
            finalCentroids594 finalCentroids640 finalCentroids405 gauss3DN...
            gauss2DN redSurfCalTrue redAffineCalTrue farRedSurfCalTrue... 
            farRedAffineCalTrue blueSurfCalTrue blueAffineCalTrue...
            affineRG affineFRG affineBG affineFRR affineBR affineBFR...
            abOptExport

    greenChannel = []; redChannel = []; farRedChannel = []; blueChannel = [];
    channelCheck = [nOptions(1) ~= 0 nOptions(2) ~= 0 nOptions(3) ~= 0 nOptions(4) ~= 0];
    expIMG = [];

    if (redAffineCalTrue == true) || (farRedAffineCalTrue == true) || (blueAffineCalTrue == true)
        answer = questdlg('3D-Speckler has detected corrected channels.  Would you like to export images for corrected channels?', ...
            'Export Aberration Corrected Images?', ...
            'Yes','No','Cancel','Yes');
        % Handle response
        switch answer
            case 'Yes'
                expIMG = 1;
            case 'No'
                expIMG = 0;
            case 'Cancel'
                disp('Data export cancelled.')
                return;
        end
    end

    [fp,fname] = fileparts(fullPath);
    if (size(finalFit488,2) == gauss3DN+1) || (size(finalFit594,2) == gauss3DN+1) || (size(finalFit640,2) == gauss3DN+1) || (size(finalFit405,2) == gauss3DN+1)
        expTempName = strcat('3DGaussResults_', fname);
    elseif (size(finalFit488,2) == gauss2DN+1) || (size(finalFit594,2) == gauss2DN+1) || (size(finalFit640,2) == gauss2DN+1) || (size(finalFit405,2) == gauss2DN+1)
        expTempName = strcat('2DGaussResults_', fname);
    end
    
    [baseFileName, folderExp] = uiputfile(strcat(expTempName, '.xlsx'), 'Choose File Name');
    if baseFileName == 0
        % User clicked the Cancel button.
        return;
    end
    newDirName = strcat('RESULTS_', fname);
    mkdir(fullfile(folderExp,newDirName));
    exportPath = fullfile(strcat(folderExp,newDirName), baseFileName);

    % Export Excel Affine Data %
    abOptExport = [];
    if channelCheck(1) == 1

        if (redSurfCalTrue == true) || (redAffineCalTrue == true)
            abOptExport = [abOptExport; (redAffineCalTrue == true) (redSurfCalTrue == true)];
        end
        if (farRedSurfCalTrue == true) || (farRedAffineCalTrue == true)
            abOptExport = [abOptExport; (farRedAffineCalTrue == true) (farRedSurfCalTrue == true)];
        end
        if (blueSurfCalTrue == true) || (blueAffineCalTrue == true)
            abOptExport = [abOptExport; (blueAffineCalTrue == true) (blueSurfCalTrue == true)];
        end

    elseif (channelCheck(1) == 0) && (channelCheck(2) == 1)

        if (farRedSurfCalTrue == true) || (farRedAffineCalTrue == true)
            abOptExport = [abOptExport; (farRedAffineCalTrue == true) (farRedSurfCalTrue == true)];
        end
        if (blueSurfCalTrue == true) || (blueAffineCalTrue == true)
            abOptExport = [abOptExport; (blueAffineCalTrue == true) (blueSurfCalTrue == true)];
        end

    elseif (channelCheck(1) == 0) && (channelCheck(2) == 0) && (channelCheck(3) == 1)

        if (blueSurfCalTrue == true) || (blueAffineCalTrue == true)
            abOptExport = [abOptExport; (blueAffineCalTrue == true) (blueSurfCalTrue == true)];
        end

    end

    % Export Aberration Corrected Images
    if ~isempty(expIMG) && (expIMG == 1)

        imgExportPath = fullfile(folderExp,newDirName,'Aberration Corrected Images');
        mkdir(imgExportPath);

        exportPathG = fullfile(imgExportPath,strcat(fname,'_CorrectedIMG_Green.tif'));
        exportPathR = fullfile(imgExportPath,strcat(fname,'_CorrectedIMG_Red.tif'));
        exportPathFR = fullfile(imgExportPath,strcat(fname,'_CorrectedIMG_FarRed.tif'));
        exportPathB = fullfile(imgExportPath,strcat(fname,'_CorrectedIMG_Blue.tif'));

        % Sort Channels
        if nOptions(1) ~= 0
            if nOptions(1) == 1
                greenChannel = channel1;
            elseif nOptions(1) == 2
                greenChannel = channel2;
            elseif nOptions(1) == 3
                greenChannel = channel3;
            elseif nOptions(1) == 4
                greenChannel = channel4;
            end
        end
        if nOptions(2) ~= 0
            if nOptions(2) == 1
                redChannel = channel1;
            elseif nOptions(2) == 2
                redChannel = channel2;
            elseif nOptions(2) == 3
                redChannel = channel3;
            elseif nOptions(2) == 4
                redChannel = channel4;
            end
        end
        if nOptions(3) ~= 0
            if nOptions(3) == 1
                farRedChannel = channel1;
            elseif nOptions(3) == 2
                farRedChannel = channel2;
            elseif nOptions(3) == 3
                farRedChannel = channel3;
            elseif nOptions(3) == 4
                farRedChannel = channel4;
            end
        end
        if nOptions(4) ~= 0
            if nOptions(4) == 1
                blueChannel = channel1;
            elseif nOptions(4) == 2
                blueChannel = channel2;
            elseif nOptions(4) == 3
                blueChannel = channel3;
            elseif nOptions(4) == 4
                blueChannel = channel4;
            end
        end

        if channelCheck(1) == 1

            if (redSurfCalTrue == true) || (redAffineCalTrue == true) && ~isempty(affineRG) && ~isempty(redChannel) && (ndims(redChannel) == affineRG.Dimensionality)
                redChannel = imwarp(redChannel,affineRG);
                disp('Corrected Red (with Green) Image Successfully Generated.')
            end
            if (farRedSurfCalTrue == true) || (farRedAffineCalTrue == true) && ~isempty(affineFRG) && ~isempty(farRedChannel)  && (ndims(farRedChannel) == affineFRG.Dimensionality)
                farRedChannel = imwarp(farRedChannel,affineFRG);
                disp('Corrected Far Red (with Green) Image Successfully Generated.')
            end
            if (blueSurfCalTrue == true) || (blueAffineCalTrue == true) && ~isempty(affineBG) && ~isempty(blueChannel) && (ndims(blueChannel) == affineBG.Dimensionality)
                blueChannel = imwarp(blueChannel,affineBG);
                disp('Corrected Blue (with Green) Image Successfully Generated.')
            end

            % Pad and Export Images %
            if (channelCheck(2) == 1) && (channelCheck(3) == 1) && (channelCheck(4) == 1)
                disp('Exporting corrected images...')
                [greenChannelF,redChannelF,farRedChannelF,blueChannelF] = padIMG4(greenChannel,redChannel,farRedChannel,blueChannel);
                disp('Image padding and alignment successful.')
                exportIMG(exportPathG,greenChannelF);
                exportIMG(exportPathR,redChannelF);
                exportIMG(exportPathFR,farRedChannelF);
                exportIMG(exportPathB,blueChannelF);
                disp('Export of Corrected Green/Red/Far Red/Blue Images Successful.')
            elseif (channelCheck(2) == 0) && (channelCheck(3) == 1) && (channelCheck(4) == 1)
                disp('Exporting corrected images...')
                [greenChannelF,farRedChannelF,blueChannelF] = padIMG3(greenChannel,farRedChannel,blueChannel);
                disp('Image padding and alignment successful.')
                exportIMG(exportPathG,greenChannelF);
                exportIMG(exportPathFR,farRedChannelF);
                exportIMG(exportPathB,blueChannelF);
                disp('Export of Corrected Green/Far Red/Blue Images Successful.')
            elseif (channelCheck(2) == 1) && (channelCheck(3) == 0) && (channelCheck(4) == 1)
                disp('Exporting corrected images...')
                [greenChannelF,redChannelF,blueChannelF] = padIMG3(greenChannel,redChannel,blueChannel);
                disp('Image padding and alignment successful.')
                exportIMG(exportPathG,greenChannelF);
                exportIMG(exportPathR,redChannelF);
                exportIMG(exportPathB,blueChannelF);
                disp('Export of Corrected Green/Red/Blue Images Successful.')
            elseif (channelCheck(2) == 1) && (channelCheck(3) == 1) && (channelCheck(4) == 0)
                disp('Exporting corrected images...')
                [greenChannelF,redChannelF,farRedChannelF] = padIMG3(greenChannel,redChannel,farRedChannel);
                disp('Image padding and alignment successful.')
                exportIMG(exportPathG,greenChannelF);
                exportIMG(exportPathR,redChannelF);
                exportIMG(exportPathFR,farRedChannelF);
                disp('Export of Corrected Green/Red/Far Red Images Successful.')
            elseif (channelCheck(2) == 0) && (channelCheck(3) == 0) && (channelCheck(4) == 1)
                disp('Exporting corrected images...')
                [greenChannelF,blueChannelF] = padIMG2(greenChannel,blueChannel);
                exportIMG(exportPathG,greenChannelF);
                exportIMG(exportPathB,blueChannelF);
                disp('Export of Corrected Green/Blue Images Successful.')
            elseif (channelCheck(2) == 1) && (channelCheck(3) == 0) && (channelCheck(4) == 0)
                disp('Exporting corrected images...')
                [greenChannelF,redChannelF] = padIMG2(greenChannel,redChannel);
                disp('Image padding and alignment successful.')
                exportIMG(exportPathG,greenChannelF);
                exportIMG(exportPathR,redChannelF);
                disp('Export of Corrected Green/Red Images Successful.')
            elseif (channelCheck(2) == 0) && (channelCheck(3) == 1) && (channelCheck(4) == 0)
                disp('Exporting corrected images...')
                [greenChannelF,farRedChannelF] = padIMG2(greenChannel,farRedChannel);
                disp('Image padding and alignment successful.')
                exportIMG(exportPathG,greenChannelF);
                exportIMG(exportPathFR,farRedChannelF);
                disp('Export of Corrected Green/Far Red Images Successful.')
            end
            disp('*********************************************************************')

        elseif (channelCheck(1) == 0) && (channelCheck(2) == 1)

            if (farRedSurfCalTrue == true) || (farRedAffineCalTrue == true) && ~isempty(affineFRR) && ~isempty(farRedChannel)  && (ndims(farRedChannel) == affineFRR.Dimensionality)
                farRedChannel = imwarp(farRedChannel,affineFRR);
                disp('Corrected Far Red (with Red) Image Successfully Generated.')
            end
            if (blueSurfCalTrue == true) || (blueAffineCalTrue == true) && ~isempty(affineBR) && ~isempty(blueChannel) && (ndims(blueChannel) == affineBR.Dimensionality)
                blueChannel = imwarp(blueChannel,affineBR);
                disp('Corrected Blue (with Red) Image Successfully Generated.')
            end

            % Pad and Export Images %
            if (channelCheck(3) == 1) && (channelCheck(4) == 1)
                disp('Exporting corrected images...')
                [redChannelF,farRedChannelF,blueChannelF] = padIMG3(redChannel,farRedChannel,blueChannel);
                disp('Image padding and alignment successful.')
                exportIMG(exportPathR,redChannelF);
                exportIMG(exportPathFR,farRedChannelF);
                exportIMG(exportPathB,blueChannelF);
                disp('Export of Corrected Red/Far Red/Blue Images Successful.')
            elseif (channelCheck(3) == 0) && (channelCheck(4) == 1)
                disp('Exporting corrected images...')
                [redChannelF,blueChannelF] = padIMG2(redChannel,blueChannel);
                disp('Image padding and alignment successful.')
                exportIMG(exportPathR,redChannelF);
                exportIMG(exportPathB,blueChannelF);
                disp('Export of Corrected Red/Blue Images Successful.')
            elseif (channelCheck(3) == 1) && (channelCheck(4) == 0) 
                disp('Exporting corrected images...')
                [redChannelF,farRedChannelF] = padIMG2(redChannel,farRedChannel);
                disp('Image padding and alignment successful.')
                exportIMG(exportPathR,redChannelF);
                exportIMG(exportPathFR,farRedChannelF);
                disp('Export of Corrected Red/Far Red Images Successful.')
            end
            disp('*********************************************************************')

        elseif (channelCheck(1) == 0) && (channelCheck(2) == 0) && (channelCheck(3) == 1)

            if (blueSurfCalTrue == true) || (blueAffineCalTrue == true) && ~isempty(affineBFR) && ~isempty(blueChannel) && (ndims(blueChannel) == affineBFR.Dimensionality)
                blueChannel = imwarp(blueChannel,affineBFR);
                disp('Corrected Blue (with Far Red) Image Successfully Generated.')
            end

            % Pad and Export Images %
            if (channelCheck(3) == 1) && (channelCheck(4) == 1) 
                disp('Exporting corrected images...')
                [farRedChannelF,blueChannelF] = padIMG2(farRedChannel,blueChannel);
                disp('Image padding and alignment successful.')
                exportIMG(exportPathFR,farRedChannelF);
                exportIMG(exportPathB,blueChannelF);
                disp('Export of Corrected Red/Far Red Images Successful.')
            end
            disp('*********************************************************************')

        end

    end
    
    % Save Figure Name
    [figF,fileName,figExt] = fileparts(exportPath);
    
    delete(exportPath);
    
    disp('..............................................');
    disp('Saving Data to Excel File:');
    disp(strcat(exportPath, '...'));
    disp('.');
    
    % Save Parameters
    paramTest = [~isempty(anaParams488) ~isempty(anaParams594) ~isempty(anaParams640) ~isempty(anaParams405)];
    sizeTest = [size(anaParams488, 1) size(anaParams594, 1) size(anaParams640, 1) size(anaParams405, 1)];
    
    if max(sizeTest) == 6
        rowNames = {'BoundBox_XY_Buffer', 'Background_Correction_Buffer', 'Overlap Threshold',...
            'Size_LowerBound', 'Size_UpperBound', 'Particle_Threshold'};
    elseif max(sizeTest) == 7
        rowNames = {'BoundBox_XY_Buffer', 'BoundBox_Z_Buffer', 'Background_Correction_Buffer', 'Overlap Threshold',...
            'Size_LowerBound', 'Size_UpperBound', 'Particle_Threshold'};
    end
    
    if sum(paramTest) == 4
        pcolNames = {'Green_Params', 'Red_Params', 'FarRed_Params', 'Blue_Params'};
        finalParamsVec = [anaParams488, anaParams594, anaParams640, anaParams405];
    elseif sum(paramTest) == 3
        if (paramTest(1) == 1) && (paramTest(2) == 1) && (paramTest(3) == 1)
            pcolNames = {'Green_Params', 'Red_Params', 'FarRed_Params'};
            finalParamsVec = [anaParams488, anaParams594, anaParams640];
        elseif (paramTest(1) == 1) && (paramTest(2) == 1) && (paramTest(4) == 1)
            pcolNames = {'Green_Params', 'Red_Params', 'Blue_Params'};
            finalParamsVec = [anaParams488, anaParams594, anaParams405];
        elseif (paramTest(1) == 1) && (paramTest(3) == 1) && (paramTest(4) == 1)
            pcolNames = {'Green_Params', 'FarRed_Params', 'Blue_Params'};
            finalParamsVec = [anaParams488, anaParams640, anaParams405];
        elseif (paramTest(2) == 1) && (paramTest(3) == 1) && (paramTest(4) == 1)
            pcolNames = {'Red_Params', 'FarRed_Params', 'Blue_Params'};
            finalParamsVec = [anaParams594, anaParams640, anaParams405];
        end
    elseif sum(paramTest) == 2
        if (paramTest(1) == 1) && (paramTest(2) == 1)
            pcolNames = {'Green_Params', 'Red_Params'};
            finalParamsVec = [anaParams488, anaParams594];
        elseif (paramTest(1) == 1) && (paramTest(3) == 1)
            pcolNames = {'Green_Params', 'FarRed_Params'};
            finalParamsVec = [anaParams488, anaParams640];
        elseif (paramTest(1) == 1) && (paramTest(4) == 1) 
            pcolNames = {'Green_Params', 'Blue_Params'};
            finalParamsVec = [anaParams488, anaParams405];
        elseif (paramTest(2) == 1) && (paramTest(3) == 1) 
            pcolNames = {'Red_Params', 'FarRed_Params'};
            finalParamsVec = [anaParams594, anaParams640];
        elseif (paramTest(2) == 1) && (paramTest(4) == 1) 
            pcolNames = {'Red_Params', 'Blue_Params'};
            finalParamsVec = [anaParams594, anaParams405];
        elseif (paramTest(3) == 1) && (paramTest(4) == 1) 
            pcolNames = {'FarRed_Params', 'Blue_Params'};
            finalParamsVec = [anaParams640, anaParams405];
        end
    elseif sum(paramTest) == 1
        if (paramTest(1) == 1)
            pcolNames = {'Green_Params'};
            finalParamsVec = [anaParams488];
        elseif (paramTest(2) == 1)
            pcolNames = {'Red_Params'};
            finalParamsVec = [anaParams594];
        elseif (paramTest(3) == 1)
            pcolNames = {'FarRed_Params'};
            finalParamsVec = [anaParams640];
        elseif (paramTest(4) == 1)
            pcolNames = {'Blue_Params'};
            finalParamsVec = [anaParams405];
        end
    end
    
    exportParams = array2table(finalParamsVec, 'VariableNames', pcolNames, 'RowNames', rowNames);
    
    disp('Saving Analysis Parameters to Excel...');
    warning('off', 'MATLAB:xlswrite:AddSheet');
    writetable(exportParams, exportPath, 'WriteRowNames', true, 'Sheet', 'AnalysisParameters');

    % Export Aberration Options %
    if ~isempty(abOptExport)

        if size(abOptExport,1) == 3
            pcolNames = {'Affine', 'Polynomial Surface'};
            rowNames = {'Red', 'Far Red', 'Blue'};
            tableROI = array2table(abOptExport, 'VariableNames', pcolNames, 'RowNames', rowNames);
            warning('off', 'MATLAB:xlswrite:AddSheet');
            writetable(tableROI, exportPath, 'WriteRowNames', true, 'Sheet', 'AberrationCorrections');
        end
        if size(abOptExport,1) == 2
            if (nOptions(1) ~= 0) && ((farRedAffineCalTrue == 1) || (farRedSurfCalTrue == 1)) && ((blueAffineCalTrue == 1) || (blueSurfCalTrue == 1))
                pcolNames = {'Affine', 'Polynomial Surface'};
                rowNames = {'Far Red', 'Blue'};
                tableROI = array2table(abOptExport, 'VariableNames', pcolNames, 'RowNames', rowNames);
                warning('off', 'MATLAB:xlswrite:AddSheet');
                writetable(tableROI, exportPath, 'WriteRowNames', true, 'Sheet', 'AberrationCorrections');
            elseif (nOptions(1) ~= 0) && ((redAffineCalTrue == 1) || (redSurfCalTrue == 1)) && ((blueAffineCalTrue == 1) || (blueSurfCalTrue == 1))
                pcolNames = {'Affine', 'Polynomial Surface'};
                rowNames = {'Red', 'Blue'};
                tableROI = array2table(abOptExport, 'VariableNames', pcolNames, 'RowNames', rowNames);
                warning('off', 'MATLAB:xlswrite:AddSheet');
                writetable(tableROI, exportPath, 'WriteRowNames', true, 'Sheet', 'AberrationCorrections');
            elseif (nOptions(1) ~= 0) && ((redAffineCalTrue == 1) || (redSurfCalTrue == 1)) && ((farRedAffineCalTrue == 1) || (farRedSurfCalTrue == 1))
                pcolNames = {'Affine', 'Polynomial Surface'};
                rowNames = {'Red', 'Far Red'};
                tableROI = array2table(abOptExport, 'VariableNames', pcolNames, 'RowNames', rowNames);
                warning('off', 'MATLAB:xlswrite:AddSheet');
                writetable(tableROI, exportPath, 'WriteRowNames', true, 'Sheet', 'AberrationCorrections');
            elseif (nOptions(1) == 0) && (nOptions(2) ~= 0) && ((farRedAffineCalTrue == 1) || (farRedSurfCalTrue == 1)) && ((blueAffineCalTrue == 1) || (blueSurfCalTrue == 1))
                pcolNames = {'Affine', 'Polynomial Surface'};
                rowNames = {'Far Red', 'Blue'};
                tableROI = array2table(abOptExport, 'VariableNames', pcolNames, 'RowNames', rowNames);
                warning('off', 'MATLAB:xlswrite:AddSheet');
                writetable(tableROI, exportPath, 'WriteRowNames', true, 'Sheet', 'AberrationCorrections');
            end

        end
        if size(abOptExport,1) == 1

            if (nOptions(1) ~= 0) && ((blueAffineCalTrue == 1) || (blueSurfCalTrue == 1))
                pcolNames = {'Affine', 'Polynomial Surface'};
                rowNames = {'Blue'};
                tableROI = array2table(abOptExport, 'VariableNames', pcolNames, 'RowNames', rowNames);
                warning('off', 'MATLAB:xlswrite:AddSheet');
                writetable(tableROI, exportPath, 'WriteRowNames', true, 'Sheet', 'AberrationCorrections');
            elseif (nOptions(1) ~= 0) && ((farRedAffineCalTrue == 1) || (farRedSurfCalTrue == 1))
                pcolNames = {'Affine', 'Polynomial Surface'};
                rowNames = {'Far Red'};
                tableROI = array2table(abOptExport, 'VariableNames', pcolNames, 'RowNames', rowNames);
                warning('off', 'MATLAB:xlswrite:AddSheet');
                writetable(tableROI, exportPath, 'WriteRowNames', true, 'Sheet', 'AberrationCorrections');
            elseif (nOptions(1) ~= 0) && ((redAffineCalTrue == 1) || (redSurfCalTrue == 1))
                pcolNames = {'Affine', 'Polynomial Surface'};
                rowNames = {'Red'};
                tableROI = array2table(abOptExport, 'VariableNames', pcolNames, 'RowNames', rowNames);
                warning('off', 'MATLAB:xlswrite:AddSheet');
                writetable(tableROI, exportPath, 'WriteRowNames', true, 'Sheet', 'AberrationCorrections');
            elseif (nOptions(1) == 0) && (nOptions(2) ~= 0) && ((blueAffineCalTrue == 1) || (blueSurfCalTrue == 1))
                pcolNames = {'Affine', 'Polynomial Surface'};
                rowNames = {'Blue'};
                tableROI = array2table(abOptExport, 'VariableNames', pcolNames, 'RowNames', rowNames);
                warning('off', 'MATLAB:xlswrite:AddSheet');
                writetable(tableROI, exportPath, 'WriteRowNames', true, 'Sheet', 'AberrationCorrections');
            elseif (nOptions(1) == 0) && (nOptions(2) ~= 0) && ((farRedAffineCalTrue == 1) || (farRedSurfCalTrue == 1))
                pcolNames = {'Affine', 'Polynomial Surface'};
                rowNames = {'Far Red'};
                tableROI = array2table(abOptExport, 'VariableNames', pcolNames, 'RowNames', rowNames);
                warning('off', 'MATLAB:xlswrite:AddSheet');
                writetable(tableROI, exportPath, 'WriteRowNames', true, 'Sheet', 'AberrationCorrections');
            elseif (nOptions(1) == 0) && (nOptions(2) == 0) && (nOptions(3) ~= 0) && ((blueAffineCalTrue == 1) || (blueSurfCalTrue == 1))
                pcolNames = {'Affine', 'Polynomial Surface'};
                rowNames = {'Blue'};
                tableROI = array2table(abOptExport, 'VariableNames', pcolNames, 'RowNames', rowNames);
                warning('off', 'MATLAB:xlswrite:AddSheet');
                writetable(tableROI, exportPath, 'WriteRowNames', true, 'Sheet', 'AberrationCorrections');
            end

        end

    end

    % Export ROI Crop Values %
    if ~isempty(cropROI)
        pcolNames = {'Begin', 'End'};
        rowNames = {'X Crop', 'Y Crop'};
        tableROI = array2table(cropROI, 'VariableNames', pcolNames, 'RowNames', rowNames);
        warning('off', 'MATLAB:xlswrite:AddSheet');
        writetable(tableROI, exportPath, 'WriteRowNames', true, 'Sheet', 'ROI');
    end
    
    % Export Multi Thresholds %
    multiTest = [~isempty(multi488) ~isempty(multi594) ~isempty(multi640) ~isempty(multi405)];
    if sum(multiTest) >= 1
        if sum(multiTest) == 4
            pcolNames = {'Green_MultiThresholds', 'Red_MultiThresholds', 'FarRed_MultiThresholds', 'Blue_MultiThresholds'};
            [multi488, multi594, multi640, multi405] = multiMatch4(multi488, multi594, multi640, multi405);
            finalParamsVec = [multi488, multi594, multi640, multi405];
        elseif sum(multiTest) == 3
            if (multiTest(1) == 1) && (multiTest(2) == 1) && (multiTest(3) == 1)
                pcolNames = {'Green_MultiThresholds', 'Red_MultiThresholds', 'FarRed_MultiThresholds'};
                [multi488, multi594, multi640] = multiMatch3(multi488, multi594, multi640);
                finalParamsVec = [multi488, multi594, multi640];
            elseif (multiTest(1) == 1) && (multiTest(2) == 1) && (multiTest(4) == 1)
                pcolNames = {'Green_MultiThresholds', 'Red_MultiThresholds', 'Blue_MultiThresholds'};
                [multi488, multi594, multi405] = multiMatch3(multi488, multi594, multi405);
                finalParamsVec = [multi488, multi594, multi405];
            elseif (multiTest(1) == 1) && (multiTest(3) == 1) && (multiTest(4) == 1)
                pcolNames = {'Green_MultiThresholds', 'FarRed_MultiThresholds', 'Blue_MultiThresholds'};
                [multi488, multi640, multi405] = multiMatch3(multi488, multi640, multi405);
                finalParamsVec = [multi488, multi640, multi405];
            elseif (multiTest(2) == 1) && (multiTest(3) == 1) && (multiTest(4) == 1)
                pcolNames = {'Red_MultiThresholds', 'FarRed_MultiThresholds', 'Blue_MultiThresholds'};
                [multi594, multi640, multi405] = multiMatch3(multi594, multi640, multi405);
                finalParamsVec = [multi594, multi640, multi405];
            end
        elseif sum(multiTest) == 2
            if (multiTest(1) == 1) && (multiTest(2) == 1)
                pcolNames = {'Green_MultiThresholds', 'Red_MultiThresholds'};
                [multi488, multi594] = multiMatch2(multi488, multi594);
                finalParamsVec = [multi488, multi594];
            elseif (multiTest(1) == 1) && (multiTest(3) == 1)
                pcolNames = {'Green_MultiThresholds', 'FarRed_MultiThresholds'};
                [multi488, multi640] = multiMatch2(multi488, multi640);
                finalParamsVec = [multi488, multi640];
            elseif (multiTest(1) == 1) && (multiTest(4) == 1)
                pcolNames = {'Green_MultiThresholds', 'Blue_MultiThresholds'};
                [multi488, multi405] = multiMatch2(multi488, multi405);
                finalParamsVec = [multi488, multi405];
            elseif (multiTest(2) == 1) && (multiTest(3) == 1)
                pcolNames = {'Red_MultiThresholds', 'FarRed_MultiThresholds'};
                [multi594, multi640] = multiMatch2(multi594, multi640);
                finalParamsVec = [multi594, multi640];
            elseif (multiTest(2) == 1) && (multiTest(4) == 1)
                pcolNames = {'Red_MultiThresholds', 'Blue_MultiThresholds'};
                [multi594, multi405] = multiMatch2(multi594, multi405);
                finalParamsVec = [multi594, multi405];
            elseif (multiTest(3) == 1) && (multiTest(4) == 1)
                pcolNames = {'FarRed_MultiThresholds', 'Blue_MultiThresholds'};
                [multi640, multi405] = multiMatch2(multi640, multi405);
                finalParamsVec = [multi640, multi405];
            end
        elseif sum(multiTest) == 1
            if (multiTest(1) == 1)
                pcolNames = {'Green_MultiThresholds'};
                finalParamsVec = [multi488];
            elseif (multiTest(2) == 1)
                pcolNames = {'Red_MultiThresholds'};
                finalParamsVec = [multi594];
            elseif (multiTest(3) == 1)
                pcolNames = {'FarRed_MultiThresholds'};
                finalParamsVec = [multi640];
            elseif (multiTest(4) == 1)
                pcolNames = {'Blue_MultiThresholds'};
                finalParamsVec = [multi405];
            end
        end
        
        multiParams = array2table(finalParamsVec, 'VariableNames', pcolNames);
        warning('off', 'MATLAB:xlswrite:AddSheet');
        writetable(multiParams, exportPath, 'Sheet', 'MultiThresholds');
    end
    
    % Green Channel %
    if ~isempty(finalFit488) && ~isempty(finalBB488)
        
        if size(finalFit488,2) == gauss3DN+1
            colNames = {'Gauss_X', 'Gauss_Y', 'Gauss_Z', 'Theta_X', 'Theta_Y', 'Theta_Z', 'STD_X', 'STD_Y', 'STD_Z',...
                'GaussBase', 'GaussPeak', 'GaussFWHM_X', 'GaussFWHM_Y', 'GaussFWHM_Z', 'Integrated_Intensity', 'MaxIntensity',...
                'tFWHM_X', 'tFWHM_Y', 'tFWHM_Z','iFWHM_X', 'iFWHM_Y', 'iFWHM_Z','ResNorm', 'isOutlier?'};
            bbNames = {'StartX', 'EndX', 'StartY', 'EndY', 'StartZ', 'EndZ'};
            Name488 = '3D_Green';
            BB488 = '3D_Green_BB';
            gDim = 3;
        elseif size(finalFit488,2) == gauss2DN+1
            colNames = {'Gauss_X', 'Gauss_Y', 'Theta', 'STD_X', 'STD_Y',...
                'GaussBase', 'GaussPeak', 'GaussFWHM_X', 'GaussFWHM_Y', 'Integrated_Intensity', 'MaxIntensity',...
                'tFWHM_X', 'tFWHM_Y', 'iFWHM_X', 'iFWHM_Y', 'ResNorm', 'isOutlier?'};
            bbNames = {'StartX', 'EndX', 'StartY', 'EndY'};
            Name488 = '2D_Green';
            BB488 = '2D_Green_BB';
            gDim = 2;
        end
        
        finalT488 = array2table(finalFit488, 'VariableNames', colNames);
        finalTBB488 = array2table(finalBB488, 'VariableNames', bbNames);
        
        disp('Saving Green Channel Data to Excel...');
        warning('off', 'MATLAB:xlswrite:AddSheet');
        writetable(finalT488, exportPath, 'Sheet', Name488);
        writetable(finalTBB488, exportPath, 'Sheet', BB488);
        
        visFig = figure();
        if nOptions(1) == 1
            visChannel = channel1;
        elseif nOptions(1) == 2
            visChannel = channel2;
        elseif nOptions(1) == 3
            visChannel = channel3;
        elseif nOptions(1) == 4
            visChannel = channel4;
        end
        
        imshow(max(visChannel, [], 3), [], 'InitialMagnification', 400);
        title('Green Channel Points');
        hold on;
        
        for m = 1:size(finalFit488,1)           
            boxPlot(1,:) = [finalBB488(m,1), finalBB488(m,3)];
            boxPlot(4,:) = [finalBB488(m,2), finalBB488(m,3)];
            boxPlot(2,:) = [finalBB488(m,1), finalBB488(m,4)];
            boxPlot(3,:) = [finalBB488(m,2), finalBB488(m,4)];
            boxPlot(5,:) = [finalBB488(m,1), finalBB488(m,3)];
            plot(boxPlot(:,1), boxPlot(:,2), '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 0.6 1], 'LineWidth', 1.0);
            plot(finalFit488(m,1)/xyRes + 0.5, finalFit488(m,2)/xyRes + 0.5, '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 1 0.6], 'LineWidth', 1.0, 'Clipping', 'on');
            text(finalFit488(m,1)/xyRes + 0.5 + 2.5, finalFit488(m,2)/xyRes + 0.5 + 2, num2str(m), 'Fontsize', 8, 'Color', 'r', 'fontweight', 'bold', 'Clipping', 'on');
        end
        
        disp('Saving Green Channel Figure...');
        if gDim == 3
            saveas(visFig, fullfile(figF,erase(strcat(fname, '_3DGreenChannelPts'),'.')));
        elseif gDim == 2
            saveas(visFig, fullfile(figF,erase(strcat(fname, '_2DGreenChannelPts'),'.')));
        end
        close(visFig);
    end
    
    % Red Channel %
    if ~isempty(finalFit594) && ~isempty(finalBB594)
        
        if size(finalFit594,2) == gauss3DN+1
            colNames = {'Gauss_X', 'Gauss_Y', 'Gauss_Z', 'Theta_X', 'Theta_Y', 'Theta_Z', 'STD_X', 'STD_Y', 'STD_Z',...
                'GaussBase', 'GaussPeak', 'GaussFWHM_X', 'GaussFWHM_Y', 'GaussFWHM_Z', 'Integrated_Intensity', 'MaxIntensity',...
                'tFWHM_X', 'tFWHM_Y', 'tFWHM_Z','iFWHM_X', 'iFWHM_Y', 'iFWHM_Z','ResNorm', 'isOutlier?'};
            bbNames = {'StartX', 'EndX', 'StartY', 'EndY', 'StartZ', 'EndZ'};
            Name594 = '3D_Red';
            BB594 = '3D_Red_BB';
            gDim = 3;
        elseif size(finalFit594,2) == gauss2DN+1
            colNames = {'Gauss_X', 'Gauss_Y', 'Theta', 'STD_X', 'STD_Y',...
                'GaussBase', 'GaussPeak', 'GaussFWHM_X', 'GaussFWHM_Y', 'Integrated_Intensity', 'MaxIntensity',...
                'tFWHM_X', 'tFWHM_Y', 'iFWHM_X', 'iFWHM_Y', 'ResNorm', 'isOutlier?'};
            bbNames = {'StartX', 'EndX', 'StartY', 'EndY'};
            Name594 = '2D_Red';
            BB594 = '2D_Red_BB';
            gDim = 2;
        end
        
        finalT594 = array2table(finalFit594, 'VariableNames', colNames);
        finalTBB594 = array2table(finalBB594, 'VariableNames', bbNames);
        
        disp('Saving Red Channel Data to Excel...');
        warning('off', 'MATLAB:xlswrite:AddSheet');
        writetable(finalT594, exportPath, 'Sheet', Name594);
        writetable(finalTBB594, exportPath, 'Sheet', BB594);
        
        visFig = figure();
        if nOptions(2) == 1
            visChannel = channel1;
        elseif nOptions(2) == 2
            visChannel = channel2;
        elseif nOptions(2) == 3
            visChannel = channel3;
        elseif nOptions(2) == 4
            visChannel = channel4;
        end
        
        imshow(max(visChannel, [], 3), [], 'InitialMagnification', 400);
        title('Red Channel Points');
        hold on;
        
        for m = 1:size(finalFit594,1)
            boxPlot(1,:) = [finalBB594(m,1), finalBB594(m,3)];
            boxPlot(4,:) = [finalBB594(m,2), finalBB594(m,3)];
            boxPlot(2,:) = [finalBB594(m,1), finalBB594(m,4)];
            boxPlot(3,:) = [finalBB594(m,2), finalBB594(m,4)];
            boxPlot(5,:) = [finalBB594(m,1), finalBB594(m,3)];
            plot(boxPlot(:,1), boxPlot(:,2), '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 0.6 1], 'LineWidth', 1.0);
            plot(finalFit594(m,1)/xyRes + 0.5, finalFit594(m,2)/xyRes + 0.5, '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 1 0.6], 'LineWidth', 1.0, 'Clipping', 'on');
            text(finalFit594(m,1)/xyRes + 0.5 + 2.5, finalFit594(m,2)/xyRes + 0.5 + 2, num2str(m), 'Fontsize', 8, 'Color', 'r', 'fontweight', 'bold', 'Clipping', 'on');
        end
        
        disp('Saving Red Channel Figure...');
        if gDim == 3
            saveas(visFig, fullfile(figF,erase(strcat(fname, '_3DRedChannelPts'),'.')));
        elseif gDim == 2
            saveas(visFig, fullfile(figF,erase(strcat(fname, '_2DRedChannelPts'),'.')));
        end
        close(visFig);
    end
    
    % Far Red Channel %
    if ~isempty(finalFit640) && ~isempty(finalBB640)
        
        if size(finalFit640,2) == gauss3DN+1
            colNames = {'Gauss_X', 'Gauss_Y', 'Gauss_Z', 'Theta_X', 'Theta_Y', 'Theta_Z', 'STD_X', 'STD_Y', 'STD_Z',...
                'GaussBase', 'GaussPeak', 'GaussFWHM_X', 'GaussFWHM_Y', 'GaussFWHM_Z', 'Integrated_Intensity', 'MaxIntensity',...
                'tFWHM_X', 'tFWHM_Y', 'tFWHM_Z','iFWHM_X', 'iFWHM_Y', 'iFWHM_Z','ResNorm', 'isOutlier?'};
            bbNames = {'StartX', 'EndX', 'StartY', 'EndY', 'StartZ', 'EndZ'};
            Name640 = '3D_FarRed';
            BB640 = '3D_FarRed_BB';
            gDim = 3;
        elseif size(finalFit640,2) == gauss2DN+1
            colNames = {'Gauss_X', 'Gauss_Y', 'Theta', 'STD_X', 'STD_Y',...
                'GaussBase', 'GaussPeak', 'GaussFWHM_X', 'GaussFWHM_Y', 'Integrated_Intensity', 'MaxIntensity',...
                'tFWHM_X', 'tFWHM_Y', 'iFWHM_X', 'iFWHM_Y', 'ResNorm', 'isOutlier?'};
            bbNames = {'StartX', 'EndX', 'StartY', 'EndY'};
            Name640 = '2D_FarRed';
            BB640 = '2D_FarRed_BB';
            gDim = 2;
        end
        
        finalT640 = array2table(finalFit640, 'VariableNames', colNames);
        finalTBB640 = array2table(finalBB640, 'VariableNames', bbNames);
        
        disp('Saving Far Red Channel Data to Excel...');
        warning('off', 'MATLAB:xlswrite:AddSheet');
        writetable(finalT640, exportPath, 'Sheet', Name640);
        writetable(finalTBB640, exportPath, 'Sheet', BB640);
        
        visFig = figure();
        if nOptions(3) == 1
            visChannel = channel1;
        elseif nOptions(3) == 2
            visChannel = channel2;
        elseif nOptions(3) == 3
            visChannel = channel3;
        elseif nOptions(3) == 4
            visChannel = channel4;
        end
        
        imshow(max(visChannel, [], 3), [], 'InitialMagnification', 400);
        title('Far Red Channel Points');
        hold on;
        
        for m = 1:size(finalFit640,1)
            boxPlot(1,:) = [finalBB640(m,1), finalBB640(m,3)];
            boxPlot(4,:) = [finalBB640(m,2), finalBB640(m,3)];
            boxPlot(2,:) = [finalBB640(m,1), finalBB640(m,4)];
            boxPlot(3,:) = [finalBB640(m,2), finalBB640(m,4)];
            boxPlot(5,:) = [finalBB640(m,1), finalBB640(m,3)];
            plot(boxPlot(:,1), boxPlot(:,2), '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 0.6 1], 'LineWidth', 1.0);
            plot(finalFit640(m,1)/xyRes + 0.5, finalFit640(m,2)/xyRes + 0.5, '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 1 0.6], 'LineWidth', 1.0, 'Clipping', 'on');
            text(finalFit640(m,1)/xyRes + 0.5 + 2.5, finalFit640(m,2)/xyRes + 0.5 + 2, num2str(m), 'Fontsize', 8, 'Color', 'r', 'fontweight', 'bold', 'Clipping', 'on');
        end
        
        disp('Saving Far Red Channel Figure...');
        if gDim == 3
            saveas(visFig, fullfile(figF,erase(strcat(fname, '_3DFarRedChannelPts'),'.')));
        elseif gDim == 2
            saveas(visFig, fullfile(figF,erase(strcat(fname, '_2DFarRedChannelPts'),'.')));
        end
        close(visFig);
    end
    
    % Blue Channel %
    if ~isempty(finalFit405) && ~isempty(finalBB405)
        
        if size(finalFit405,2) == gauss3DN+1
            colNames = {'Gauss_X', 'Gauss_Y', 'Gauss_Z', 'Theta_X', 'Theta_Y', 'Theta_Z', 'STD_X', 'STD_Y', 'STD_Z',...
                'GaussBase', 'GaussPeak', 'GaussFWHM_X', 'GaussFWHM_Y', 'GaussFWHM_Z', 'Integrated_Intensity', 'MaxIntensity',...
                'tFWHM_X', 'tFWHM_Y', 'tFWHM_Z','iFWHM_X', 'iFWHM_Y', 'iFWHM_Z','ResNorm', 'isOutlier?'};
            bbNames = {'StartX', 'EndX', 'StartY', 'EndY', 'StartZ', 'EndZ'};
            Name405 = '3D_Blue';
            BB405 = '3D_Blue_BB';
            gDim = 3;
        elseif size(finalFit405,2) == gauss2DN+1
            colNames = {'Gauss_X', 'Gauss_Y', 'Theta', 'STD_X', 'STD_Y',...
                'GaussBase', 'GaussPeak', 'GaussFWHM_X', 'GaussFWHM_Y', 'Integrated_Intensity', 'MaxIntensity',...
                'tFWHM_X', 'tFWHM_Y', 'iFWHM_X', 'iFWHM_Y', 'ResNorm', 'isOutlier?'};
            bbNames = {'StartX', 'EndX', 'StartY', 'EndY'};
            Name405 = '2D_Blue';
            BB405 = '2D_Blue_BB';
            gDim = 2;
        end
        
        finalT405 = array2table(finalFit405, 'VariableNames', colNames);
        finalTBB405 = array2table(finalBB405, 'VariableNames', bbNames);
        
        disp('Saving Blue Channel Data to Excel...');
        warning('off', 'MATLAB:xlswrite:AddSheet');
        writetable(finalT405, exportPath, 'Sheet', Name405);
        writetable(finalTBB405, exportPath, 'Sheet', BB405);
        
        visFig = figure();
        if nOptions(4) == 1
            visChannel = channel1;
        elseif nOptions(4) == 2
            visChannel = channel2;
        elseif nOptions(4) == 3
            visChannel = channel3;
        elseif nOptions(4) == 4
            visChannel = channel4;
        end
        
        imshow(max(visChannel, [], 3), [], 'InitialMagnification', 400);
        title('Blue Channel Points');
        hold on;
        
        for m = 1:size(finalFit405,1)
            boxPlot(1,:) = [finalBB405(m,1), finalBB405(m,3)];
            boxPlot(4,:) = [finalBB405(m,2), finalBB405(m,3)];
            boxPlot(2,:) = [finalBB405(m,1), finalBB405(m,4)];
            boxPlot(3,:) = [finalBB405(m,2), finalBB405(m,4)];
            boxPlot(5,:) = [finalBB405(m,1), finalBB405(m,3)];
            plot(boxPlot(:,1), boxPlot(:,2), '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 0.6 1], 'LineWidth', 1.0);
            plot(finalFit405(m,1)/xyRes + 0.5, finalFit405(m,2)/xyRes + 0.5, '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 1 0.6], 'LineWidth', 1.0, 'Clipping', 'on');
            text(finalFit405(m,1)/xyRes + 0.5 + 2.5, finalFit405(m,2)/xyRes + 0.5 + 2, num2str(m), 'Fontsize', 8, 'Color', 'r', 'fontweight', 'bold', 'Clipping', 'on');
        end
        
        disp('Saving Blue Channel Figure...');
        if gDim == 3
            saveas(visFig, fullfile(figF,erase(strcat(fname, '_3DBlueChannelPts'),'.')));
        elseif gDim == 2
            saveas(visFig, fullfile(figF,erase(strcat(fname, '_2DBlueChannelPts'),'.')));
        end
        close(visFig);
    end
    
    % Export Centroids %
    if ~isempty(finalCentroids488)
        if size(finalCentroids488,2) == 2
            colNames = {'Green_X', 'Green_Y'};
        elseif size(finalCentroids488,2) == 3
            colNames = {'Green_X', 'Green_Y', 'Green_Z'};
        end
        centroids488 = array2table(finalCentroids488, 'VariableNames', colNames);
        warning('off', 'MATLAB:xlswrite:AddSheet');
        writetable(centroids488, exportPath, 'Sheet', 'Green_Centroids');
    end
    if ~isempty(finalCentroids594)
        if size(finalCentroids594,2) == 2
            colNames = {'Red_X', 'Red_Y'};
        elseif size(finalCentroids594,2) == 3
            colNames = {'Red_X', 'Red_Y', 'Red_Z'};
        end
        centroids594 = array2table(finalCentroids594);
        warning('off', 'MATLAB:xlswrite:AddSheet');
        writetable(centroids594, exportPath, 'Sheet', 'Red_Centroids');
    end
    if ~isempty(finalCentroids640)
        if size(finalCentroids640,2) == 2
            colNames = {'FarRed_X', 'FarRed_Y'};
        elseif size(finalCentroids640,2) == 3
            colNames = {'FarRed_X', 'FarRed_Y', 'FarRed_Z'};
        end
        centroids640 = array2table(finalCentroids640);
        warning('off', 'MATLAB:xlswrite:AddSheet');
        writetable(centroids640, exportPath, 'Sheet', 'FarRed_Centroids');
    end
    if ~isempty(finalCentroids405)
        if size(finalCentroids488,2) == 2
            colNames = {'Blue_X', 'Blue_Y'};
        elseif size(finalCentroids488,2) == 3
            colNames = {'Blue_X', 'Blue_Y', 'Blue_Z'};
        end
        centroids405 = array2table(finalCentroids405);
        warning('off', 'MATLAB:xlswrite:AddSheet');
        writetable(centroids405, exportPath, 'Sheet', 'Blue_Centroids');
    end
    
    % Saving Aberration Calculations %
    if ~isempty(ab488_594) || ~isempty(ab488_640) || ~isempty(ab488_405) ||...
       ~isempty(ab594_640) || ~isempty(ab594_405) || ~isempty(ab640_405)
   
        disp('Writing Aberration Calculations to Excel...');
        if ~isempty(ab488_594)
            if size(ab488_594,2) == 3
                colNames = {'X_Aberration','Y_Aberration', 'Distance'};
            elseif size(ab488_594,2) == 4
                colNames = {'X_Aberration','Y_Aberration', 'Z_Aberration', 'Distance'};
            end
            abTable = array2table(ab488_594, 'VariableNames', colNames);
            warning('off', 'MATLAB:xlswrite:AddSheet');
            writetable(abTable, exportPath, 'Sheet', 'aberration_Green_Red');
        end
        if ~isempty(ab488_640)
            if size(ab488_640,2) == 3
                colNames = {'X_Aberration','Y_Aberration', 'Distance'};
            elseif size(ab488_640,2) == 4
                colNames = {'X_Aberration','Y_Aberration', 'Z_Aberration', 'Distance'};
            end
            abTable = array2table(ab488_640, 'VariableNames', colNames);
            warning('off', 'MATLAB:xlswrite:AddSheet');
            writetable(abTable, exportPath, 'Sheet', 'aberration_Green_FarRed');
        end
        if ~isempty(ab488_405)
            if size(ab488_405,2) == 3
                colNames = {'X_Aberration','Y_Aberration', 'Distance'};
            elseif size(ab488_405,2) == 4
                colNames = {'X_Aberration','Y_Aberration', 'Z_Aberration', 'Distance'};
            end
            abTable = array2table(ab488_405, 'VariableNames', colNames);
            warning('off', 'MATLAB:xlswrite:AddSheet');
            writetable(abTable, exportPath, 'Sheet', 'aberration_Green_Blue');
        end
        if ~isempty(ab594_640)
            if size(ab594_640,2) == 3
                colNames = {'X_Aberration','Y_Aberration', 'Distance'};
            elseif size(ab594_640,2) == 4
                colNames = {'X_Aberration','Y_Aberration', 'Z_Aberration', 'Distance'};
            end
            abTable = array2table(ab594_640, 'VariableNames', colNames);
            warning('off', 'MATLAB:xlswrite:AddSheet');
            writetable(abTable, exportPath, 'Sheet', 'aberration_Red_FarRed');
        end
        if ~isempty(ab594_405)
            if size(ab594_405,2) == 3
                colNames = {'X_Aberration','Y_Aberration', 'Distance'};
            elseif size(ab594_405,2) == 4
                colNames = {'X_Aberration','Y_Aberration', 'Z_Aberration', 'Distance'};
            end
            abTable = array2table(ab594_405, 'VariableNames', colNames);
            warning('off', 'MATLAB:xlswrite:AddSheet');
            writetable(abTable, exportPath, 'Sheet', 'aberration_Red_Blue');
        end
        if ~isempty(ab640_405)
            if size(ab640_405,2) == 3
                colNames = {'X_Aberration','Y_Aberration', 'Distance'};
            elseif size(ab640_405,2) == 4
                colNames = {'X_Aberration','Y_Aberration', 'Z_Aberration', 'Distance'};
            end
            abTable = array2table(ab640_405, 'VariableNames', colNames);
            warning('off', 'MATLAB:xlswrite:AddSheet');
            writetable(abTable, exportPath, 'Sheet', 'aberration_FarRed_Blue');
        end
        
    end
    
    
    % Saving Distance Matrices %
    if ~isempty(distMatrix488) || ~isempty(distMatrix594) || ~isempty(distMatrix640) ||...
       ~isempty(distMatrix405) || ~isempty(distMatrix488_594) || ~isempty(distMatrix488_640) ||...
       ~isempty(distMatrix488_405) || ~isempty(distMatrix594_640) || ~isempty(distMatrix594_405) ||...
       ~isempty(distMatrix640_405)
   
        disp('Writing Distance Matrices to Excel...');
   
        if ~isempty(distMatrix488)
            distMatTable = array2table(distMatrix488);
            warning('off', 'MATLAB:xlswrite:AddSheet');
            writetable(distMatTable, exportPath, 'Sheet', 'distMatGreen', 'WriteVariableNames', false, 'WriteRowNames', false);
        end
        if ~isempty(distMatrix594)
            distMatTable = array2table(distMatrix594);
            warning('off', 'MATLAB:xlswrite:AddSheet');
            writetable(distMatTable, exportPath, 'Sheet', 'distMatRed', 'WriteVariableNames', false, 'WriteRowNames', false);
        end
        if ~isempty(distMatrix640)
            distMatTable = array2table(distMatrix640);
            warning('off', 'MATLAB:xlswrite:AddSheet');
            writetable(distMatTable, exportPath, 'Sheet', 'distMatFarRed', 'WriteVariableNames', false, 'WriteRowNames', false);
        end
        if ~isempty(distMatrix405)
            distMatTable = array2table(distMatrix405);
            warning('off', 'MATLAB:xlswrite:AddSheet');
            writetable(distMatTable, exportPath, 'Sheet', 'distMatBlue', 'WriteVariableNames', false, 'WriteRowNames', false);
        end
        if ~isempty(distMatrix488_594)
            distMatTable = array2table(distMatrix488_594);
            warning('off', 'MATLAB:xlswrite:AddSheet');
            writetable(distMatTable, exportPath, 'Sheet', 'distMatGreen_Red', 'WriteVariableNames', false, 'WriteRowNames', false);
        end
        if ~isempty(distMatrix488_640)
            distMatTable = array2table(distMatrix488_640);
            warning('off', 'MATLAB:xlswrite:AddSheet');
            writetable(distMatTable, exportPath, 'Sheet', 'distMatGreen_FarRed', 'WriteVariableNames', false, 'WriteRowNames', false);
        end
        if ~isempty(distMatrix488_405)
            distMatTable = array2table(distMatrix488_405);
            warning('off', 'MATLAB:xlswrite:AddSheet');
            writetable(distMatTable, exportPath, 'Sheet', 'distMatGreen_Blue', 'WriteVariableNames', false, 'WriteRowNames', false);
        end
        if ~isempty(distMatrix594_640)
            distMatTable = array2table(distMatrix594_640);
            warning('off', 'MATLAB:xlswrite:AddSheet');
            writetable(distMatTable, exportPath, 'Sheet', 'distMatRed_FarRed', 'WriteVariableNames', false, 'WriteRowNames', false);
        end
        if ~isempty(distMatrix594_405)
            distMatTable = array2table(distMatrix594_405);
            warning('off', 'MATLAB:xlswrite:AddSheet');
            writetable(distMatTable, exportPath, 'Sheet', 'distMatRed_Blue', 'WriteVariableNames', false, 'WriteRowNames', false);
        end
        if ~isempty(distMatrix640_405)
            distMatTable = array2table(distMatrix640_405);
            warning('off', 'MATLAB:xlswrite:AddSheet');
            writetable(distMatTable, exportPath, 'Sheet', 'distMatFarRed_Blue', 'WriteVariableNames', false, 'WriteRowNames', false);
        end
   
    end
    
    
    
    disp('Data Export Complete.');
    disp('................................................................');
    msgbox('Data Export Completed Successfully.');

    function [pIMG1, pIMG2, pIMG3, pIMG4] = padIMG4(IMG1,IMG2,IMG3,IMG4)

        redCorrectedIMG = IMG2;
        farredCorrectedIMG = IMG3;
        blueCorrectedIMG = IMG4;

        bufferMultiple = 2;

        DimG = bufferMultiple*ceil(size(IMG1)/bufferMultiple);
        warpDimR = bufferMultiple*ceil(size(redCorrectedIMG)/bufferMultiple);
        warpDimFR = bufferMultiple*ceil(size(farredCorrectedIMG)/bufferMultiple);
        warpDimB = bufferMultiple*ceil(size(blueCorrectedIMG)/bufferMultiple);

        newDim = [max([DimG(1) warpDimR(1) warpDimFR(1) warpDimB(1)]) max([DimG(2) warpDimR(2) warpDimFR(2) warpDimB(2)]) max([DimG(3) warpDimR(3) warpDimFR(3) warpDimB(3)])];

        bufferG = newDim - size(IMG1);
        bufferR = newDim - size(redCorrectedIMG);
        bufferFR = newDim - size(farredCorrectedIMG);
        bufferB = newDim - size(blueCorrectedIMG);

        % Pad Green IMG %

        temp = padarray(IMG1,[floor(bufferG(1)/2),0,0],0,'pre');
        temp = padarray(temp,[ceil(bufferG(1)/2),0,0],0,'post');
        temp = padarray(temp,[0,floor(bufferG(2)/2),0],0,'pre');
        temp = padarray(temp,[0,ceil(bufferG(2)/2),0],0,'post');
        temp = padarray(temp,[0,0,floor(bufferG(3)/2)],0,'pre');
        pIMG1 = padarray(temp,[0,0,ceil(bufferG(3)/2)],0,'post');

        % Pad Red IMG %

        temp = padarray(redCorrectedIMG,[floor(bufferR(1)/2),0,0],0,'pre');
        temp = padarray(temp,[ceil(bufferR(1)/2),0,0],0,'post');
        temp = padarray(temp,[0,floor(bufferR(2)/2),0],0,'pre');
        temp = padarray(temp,[0,ceil(bufferR(2)/2),0],0,'post');
        temp = padarray(temp,[0,0,floor(bufferR(3)/2)],0,'pre');
        pIMG2 = padarray(temp,[0,0,ceil(bufferR(3)/2)],0,'post');

        % Pad Far Red IMG %

        temp = padarray(farredCorrectedIMG,[floor(bufferFR(1)/2),0,0],0,'pre');
        temp = padarray(temp,[ceil(bufferFR(1)/2),0,0],0,'post');
        temp = padarray(temp,[0,floor(bufferFR(2)/2),0],0,'pre');
        temp = padarray(temp,[0,ceil(bufferFR(2)/2),0],0,'post');
        temp = padarray(temp,[0,0,floor(bufferFR(3)/2)],0,'pre');
        pIMG3 = padarray(temp,[0,0,ceil(bufferFR(3)/2)],0,'post');

        % Pad Blue IMG %

        temp = padarray(blueCorrectedIMG,[floor(bufferB(1)/2),0,0],0,'pre');
        temp = padarray(temp,[ceil(bufferB(1)/2),0,0],0,'post');
        temp = padarray(temp,[0,floor(bufferB(2)/2),0],0,'pre');
        temp = padarray(temp,[0,ceil(bufferB(2)/2),0],0,'post');
        temp = padarray(temp,[0,0,floor(bufferB(3)/2)],0,'pre');
        pIMG4 = padarray(temp,[0,0,ceil(bufferB(3)/2)],0,'post');

    end

    function [pIMG1, pIMG2, pIMG3] = padIMG3(IMG1,IMG2,IMG3)

        redCorrectedIMG = IMG2;
        farredCorrectedIMG = IMG3;

        bufferMultiple = 2;

        DimG = bufferMultiple*ceil(size(IMG1)/bufferMultiple);
        warpDimR = bufferMultiple*ceil(size(redCorrectedIMG)/bufferMultiple);
        warpDimFR = bufferMultiple*ceil(size(farredCorrectedIMG)/bufferMultiple);

        newDim = [max([DimG(1) warpDimR(1) warpDimFR(1)]) max([DimG(2) warpDimR(2) warpDimFR(2)]) max([DimG(3) warpDimR(3) warpDimFR(3)])];

        bufferG = newDim - size(IMG1);
        bufferR = newDim - size(redCorrectedIMG);
        bufferFR = newDim - size(farredCorrectedIMG);

        % Pad Green IMG %

        temp = padarray(IMG1,[floor(bufferG(1)/2),0,0],0,'pre');
        temp = padarray(temp,[ceil(bufferG(1)/2),0,0],0,'post');
        temp = padarray(temp,[0,floor(bufferG(2)/2),0],0,'pre');
        temp = padarray(temp,[0,ceil(bufferG(2)/2),0],0,'post');
        temp = padarray(temp,[0,0,floor(bufferG(3)/2)],0,'pre');
        pIMG1 = padarray(temp,[0,0,ceil(bufferG(3)/2)],0,'post');

        % Pad Red IMG %

        temp = padarray(redCorrectedIMG,[floor(bufferR(1)/2),0,0],0,'pre');
        temp = padarray(temp,[ceil(bufferR(1)/2),0,0],0,'post');
        temp = padarray(temp,[0,floor(bufferR(2)/2),0],0,'pre');
        temp = padarray(temp,[0,ceil(bufferR(2)/2),0],0,'post');
        temp = padarray(temp,[0,0,floor(bufferR(3)/2)],0,'pre');
        pIMG2 = padarray(temp,[0,0,ceil(bufferR(3)/2)],0,'post');

        % Pad Far Red IMG %

        temp = padarray(farredCorrectedIMG,[floor(bufferFR(1)/2),0,0],0,'pre');
        temp = padarray(temp,[ceil(bufferFR(1)/2),0,0],0,'post');
        temp = padarray(temp,[0,floor(bufferFR(2)/2),0],0,'pre');
        temp = padarray(temp,[0,ceil(bufferFR(2)/2),0],0,'post');
        temp = padarray(temp,[0,0,floor(bufferFR(3)/2)],0,'pre');
        pIMG3 = padarray(temp,[0,0,ceil(bufferFR(3)/2)],0,'post');

    end

    function [pIMG1, pIMG2] = padIMG2(IMG1,IMG2)

        redCorrectedIMG = IMG2;

        bufferMultiple = 2;

        DimG = bufferMultiple*ceil(size(IMG1)/bufferMultiple);
        warpDimR = bufferMultiple*ceil(size(redCorrectedIMG)/bufferMultiple);

        newDim = [max([DimG(1) warpDimR(1)]) max([DimG(2) warpDimR(2)]) max([DimG(3) warpDimR(3)])];

        bufferG = newDim - size(IMG1);
        bufferR = newDim - size(redCorrectedIMG);

        % Pad Green IMG %

        temp = padarray(IMG1,[floor(bufferG(1)/2),0,0],0,'pre');
        temp = padarray(temp,[ceil(bufferG(1)/2),0,0],0,'post');
        temp = padarray(temp,[0,floor(bufferG(2)/2),0],0,'pre');
        temp = padarray(temp,[0,ceil(bufferG(2)/2),0],0,'post');
        temp = padarray(temp,[0,0,floor(bufferG(3)/2)],0,'pre');
        pIMG1 = padarray(temp,[0,0,ceil(bufferG(3)/2)],0,'post');

        % Pad Red IMG %

        temp = padarray(redCorrectedIMG,[floor(bufferR(1)/2),0,0],0,'pre');
        temp = padarray(temp,[ceil(bufferR(1)/2),0,0],0,'post');
        temp = padarray(temp,[0,floor(bufferR(2)/2),0],0,'pre');
        temp = padarray(temp,[0,ceil(bufferR(2)/2),0],0,'post');
        temp = padarray(temp,[0,0,floor(bufferR(3)/2)],0,'pre');
        pIMG2 = padarray(temp,[0,0,ceil(bufferR(3)/2)],0,'post');

    end

    function exportIMG(exportPathG,finalGreenIMG)
        for k = 1:size(finalGreenIMG,3)
            imwrite(mat2gray(finalGreenIMG(:,:,k)),exportPathG,'WriteMode','append', 'Compression', 'none');
        end
    end
            
end

%%

function matchPoints()

    global  finalFit488 finalFit594 finalFit640 finalFit405 matchVec...
            finalBB488 finalBB594 finalBB640 finalBB405 nnThreshold...
            finalCentroids488 finalCentroids594 finalCentroids640...
            finalCentroids405 oFit488 oBB488 oCen488 oFit594 oBB594 oCen594...
            oFit640 oBB640 oCen640 oFit405 oBB405 oCen405 matchNtimes
    
    size488 = size(finalFit488,2);
    size594 = size(finalFit594,2);
    size640 = size(finalFit640,2);
    size405 = size(finalFit405,2);
    tempCheck = [size488 size594 size640 size405];
    sizeCheck = tempCheck(matchVec == 1);
    
    matchNtimes = matchNtimes + 1;
    
    if matchNtimes == 1
        oFit488 = finalFit488;
        oBB488 = finalBB488;
        oCen488 = finalCentroids488;

        oFit594 = finalFit594;
        oBB594 = finalBB594;
        oCen594 = finalCentroids594;

        oFit640 = finalFit640;
        oBB640 = finalBB640;
        oCen640 = finalCentroids640;

        oFit405 = finalFit405;
        oBB405 = finalBB405;
        oCen405 = finalCentroids405;
    end
    
    resetResultsButton();
    
    
    if (sum(matchVec) == 0) || (sum(matchVec) == 1) || isempty(matchVec)
        warndlg('Matching Error.  Need 2 or more channel data sets.');
        return;
    end
    if ~all(diff(sizeCheck) == 0)
        warndlg('Matching Error.  Data Dimensionalities do not match!');
        return;
    end
    
    
    disp('Matching Points...');
    % Match and Align 4 Channels %
    if (sum(matchVec) == 4) && all(diff(sizeCheck) == 0)
        try
            disp('Matching points for 4 channels...');
            matchPoints4(finalFit488, finalFit594, finalFit640,finalFit405, nnThreshold);
            disp('COMPLETE: Point Matching Successful.');
            disp('******************************************************');
            alignAllPts();
        catch
            msgbox('Matching Error for 4 Channels.');
            return;
        end
    end
    % Match and Align 3 Channels %
    if (sum(matchVec) == 3) && all(diff(sizeCheck) == 0)
        disp('Matching points for 3 channels...');
        
        try
            if (matchVec(1) == 1) && (matchVec(2) == 1) && (matchVec(3) == 1)
                matchPoints3(finalFit488, finalFit594, finalFit640, nnThreshold);
            elseif (matchVec(1) == 1) && (matchVec(2) == 1) && (matchVec(4) == 1)
                matchPoints3(finalFit488, finalFit594, finalFit405, nnThreshold);
            elseif (matchVec(1) == 1) && (matchVec(3) == 1) && (matchVec(4) == 1)
                matchPoints3(finalFit488, finalFit640, finalFit405, nnThreshold);
            elseif (matchVec(2) == 1) && (matchVec(3) == 1) && (matchVec(4) == 1)
                matchPoints3(finalFit594, finalFit640, finalFit405, nnThreshold);
            end
            
            disp('COMPLETE: Point Matching Successful.');
            disp('******************************************************');
            alignAllPts();
        catch
            msgbox('Matching Error for 3 Channels.');
            return;
        end
    end
    % Match and Align 2 Channels %
    if (sum(matchVec) == 2) && all(diff(sizeCheck) == 0)
        disp('Matching points for 2 channels...');
        
        try
            if (matchVec(1) == 1) && (matchVec(2) == 1)
                matchPoints2(finalFit488, finalFit594, nnThreshold);
            elseif (matchVec(1) == 1) && (matchVec(3) == 1)
                matchPoints2(finalFit488, finalFit640, nnThreshold);
            elseif (matchVec(1) == 1) && (matchVec(4) == 1)
                matchPoints2(finalFit488, finalFit405, nnThreshold);
            elseif (matchVec(2) == 1) && (matchVec(3) == 1)
                matchPoints2(finalFit594, finalFit640, nnThreshold);
            elseif (matchVec(2) == 1) && (matchVec(4) == 1)
                matchPoints2(finalFit594, finalFit405, nnThreshold);
            elseif (matchVec(3) == 1) && (matchVec(4) == 1)
                matchPoints2(finalFit640, finalFit405, nnThreshold);
            end
            
            disp('COMPLETE: Point Matching Successful.');
            disp('******************************************************');
            alignAllPts();
        catch
            msgbox('Matching Error for 2 Channels.');
            return;
        end
    end
    
    msgbox('COMPLETE: Point Matching Successful.');
    

end

%%

function matchPoints4(data1, data2, data3, data4, nnThreshold)

    global finalFit488 finalBB488 finalFit594 finalBB594...
            finalFit640 finalBB640 finalFit405 finalBB405...
            finalCentroids488 finalCentroids594 finalCentroids640...
            finalCentroids405

    dName1 = inputname(1);
    dName2 = inputname(2);
    dName3 = inputname(3);
    dName4 = inputname(4);
    
    if dName1 == 'finalFit488'
        bbName1 = 'finalBB488';
        cenName1 = 'finalCentroids488';
        bb1 = finalBB488;
        cen1 = finalCentroids488;
    elseif dName1 == 'finalFit594'
        bbName1 = 'finalBB594';
        cenName1 = 'finalCentroids594';
        bb1 = finalBB594;
        cen1 = finalCentroids594;
    elseif dName1 == 'finalFit640'
        bbName1 = 'finalBB640';
        cenName1 = 'finalCentroids640';
        bb1 = finalBB640;
        cen1 = finalCentroids640;
    elseif dName1 == 'finalFit405'
        bbName1 = 'finalBB405';
        cenName1 = 'finalCentroids405';
        bb1 = finalBB405;
        cen1 = finalCentroids405;
    end
    
    
    if dName2 == 'finalFit488'
        bbName2 = 'finalBB488';
        cenName2 = 'finalCentroids488';
        bb2 = finalBB488;
        cen2 = finalCentroids488;
    elseif dName2 == 'finalFit594'
        bbName2 = 'finalBB594';
        cenName2 = 'finalCentroids594';
        bb2 = finalBB594;
        cen2 = finalCentroids594;
    elseif dName2 == 'finalFit640'
        bbName2 = 'finalBB640';
        cenName2 = 'finalCentroids640';
        bb2 = finalBB640;
        cen2 = finalCentroids640;
    elseif dName2 == 'finalFit405'
        bbName2 = 'finalBB405';
        cenName2 = 'finalCentroids405';
        bb2 = finalBB405;
        cen2 = finalCentroids405;
    end
    
    if dName3 == 'finalFit488'
        bbName3 = 'finalBB488';
        cenName3 = 'finalCentroids488';
        bb3 = finalBB488;
        cen3 = finalCentroids488;
    elseif dName3 == 'finalFit594'
        bbName3 = 'finalBB594';
        cenName3 = 'finalCentroids594';
        bb3 = finalBB594;
        cen3 = finalCentroids594;
    elseif dName3 == 'finalFit640'
        bbName3 = 'finalBB640';
        cenName3 = 'finalCentroids640';
        bb3 = finalBB640;
        cen3 = finalCentroids640;
    elseif dName3 == 'finalFit405'
        bbName3 = 'finalBB405';
        cenName3 = 'finalCentroids405';
        bb3 = finalBB405;
        cen3 = finalCentroids405;
    end
    
    if dName4 == 'finalFit488'
        bbName4 = 'finalBB488';
        cenName4 = 'finalCentroids488';
        bb4 = finalBB488;
        cen4 = finalCentroids488;
    elseif dName4 == 'finalFit594'
        bbName4 = 'finalBB594';
        cenName4 = 'finalCentroids594';
        bb4 = finalBB594;
        cen4 = finalCentroids594;
    elseif dName4 == 'finalFit640'
        bbName4 = 'finalBB640';
        cenName4 = 'finalCentroids640';
        bb4 = finalBB640;
        cen4 = finalCentroids640;
    elseif dName4 == 'finalFit405'
        bbName4 = 'finalBB405';
        cenName4 = 'finalCentroids405';
        bb4 = finalBB405;
        cen4 = finalCentroids405;
    end
    
    size1 = size(data1,1);
    size2 = size(data2,1);
    size3 = size(data3,1);
    size4 = size(data4,1);
    
    sizeCheck = [size1 size2 size3 size4];

    loopCounter = 0;
    while ~all(diff(sizeCheck) == 0)
        
        if loopCounter >= 20
            error('Matching Error. Data Sets cannot be fully matched.');
        end
        
        %----------------Match 1 with 2----------------%
        set1 = data1(:,1:3);
        set2 = data2(:,1:3);
        [k,dist] = dsearchn(set1,set2);
        matchPairs = [];
        
        % Find all matching pairs %
        for i = 1:size(k,1)

            indVal = 0;
            minCheck = [];
            copyN = sum(k == k(i));
            if copyN > 1
                indCheck = find(k == k(i));
                for j = 1:size(indCheck,1)
                    minCheck(j) = dist(indCheck(j));
                end
                [minVal,minInd] = min(minCheck);
                if minVal <= nnThreshold
                    indVal = indCheck(minInd);
                end
            else
                if dist(i) <= nnThreshold
                    indVal = i;
                end
            end

            if i == indVal
                matchPairs(end+1,:) = [k(i) i];
            end

        end

        % Re-sort Original Data
        newData1 = [];
        newData2 = [];
        newBB1 = [];
        newBB2 = [];
        newCen1 = [];
        newCen2 = [];
        for i = 1:size(matchPairs,1)
            newData1(i,:) = data1(matchPairs(i,1),:);
            newData2(i,:) = data2(matchPairs(i,2),:);

            newBB1(i,:) = bb1(matchPairs(i,1),:);
            newBB2(i,:) = bb2(matchPairs(i,2),:);

            newCen1(i,:) = cen1(matchPairs(i,1),:);
            newCen2(i,:) = cen2(matchPairs(i,2),:);
        end
        
        data1 = newData1;
        data2 = newData2;
        bb1 = newBB1;
        bb2 = newBB2;
        cen1 = newCen1;
        cen2 = newCen2;
        
        %----------------Match 2 with 3----------------%
        set1 = data2(:,1:3);
        set2 = data3(:,1:3);
        [k,dist] = dsearchn(set1,set2);
        matchPairs = [];
        
        % Find all matching pairs %
        for i = 1:size(k,1)

            indVal = 0;
            minCheck = [];
            copyN = sum(k == k(i));
            if copyN > 1
                indCheck = find(k == k(i));
                for j = 1:size(indCheck,1)
                    minCheck(j) = dist(indCheck(j));
                end
                [minVal,minInd] = min(minCheck);
                if minVal <= nnThreshold
                    indVal = indCheck(minInd);
                end
            else
                if dist(i) <= nnThreshold
                    indVal = i;
                end
            end

            if i == indVal
                matchPairs(end+1,:) = [k(i) i];
            end

        end

        % Re-sort Original Data
        newData2 = [];
        newData3 = [];
        newBB2 = [];
        newBB3 = [];
        newCen2 = [];
        newCen3 = [];
        for i = 1:size(matchPairs,1)
            newData2(i,:) = data2(matchPairs(i,1),:);
            newData3(i,:) = data3(matchPairs(i,2),:);

            newBB2(i,:) = bb2(matchPairs(i,1),:);
            newBB3(i,:) = bb3(matchPairs(i,2),:);

            newCen2(i,:) = cen2(matchPairs(i,1),:);
            newCen3(i,:) = cen3(matchPairs(i,2),:);
        end
        
        data2 = newData2;
        data3 = newData3;
        bb2 = newBB2;
        bb3 = newBB3;
        cen2 = newCen2;
        cen3 = newCen3;
        
        %----------------Match 3 with 4----------------%
        set1 = data3(:,1:3);
        set2 = data4(:,1:3);
        [k,dist] = dsearchn(set1,set2);
        matchPairs = [];
        
        % Find all matching pairs %
        for i = 1:size(k,1)

            indVal = 0;
            minCheck = [];
            copyN = sum(k == k(i));
            if copyN > 1
                indCheck = find(k == k(i));
                for j = 1:size(indCheck,1)
                    minCheck(j) = dist(indCheck(j));
                end
                [minVal,minInd] = min(minCheck);
                if minVal <= nnThreshold
                    indVal = indCheck(minInd);
                end
            else
                if dist(i) <= nnThreshold
                    indVal = i;
                end
            end

            if i == indVal
                matchPairs(end+1,:) = [k(i) i];
            end

        end

        % Re-sort Original Data
        newData3 = [];
        newData4 = [];
        newBB3 = [];
        newBB4 = [];
        newCen3 = [];
        newCen4 = [];
        for i = 1:size(matchPairs,1)
            newData3(i,:) = data3(matchPairs(i,1),:);
            newData4(i,:) = data4(matchPairs(i,2),:);

            newBB3(i,:) = bb3(matchPairs(i,1),:);
            newBB4(i,:) = bb4(matchPairs(i,2),:);

            newCen3(i,:) = cen3(matchPairs(i,1),:);
            newCen4(i,:) = cen4(matchPairs(i,2),:);
        end
        
        data3 = newData3;
        data4 = newData4;
        bb3 = newBB3;
        bb4 = newBB4;
        cen3 = newCen3;
        cen4 = newCen4;
        
        %----------------Match 4 with 1----------------%
        set1 = data4(:,1:3);
        set2 = data1(:,1:3);
        [k,dist] = dsearchn(set1,set2);
        matchPairs = [];
        
        % Find all matching pairs %
        for i = 1:size(k,1)

            indVal = 0;
            minCheck = [];
            copyN = sum(k == k(i));
            if copyN > 1
                indCheck = find(k == k(i));
                for j = 1:size(indCheck,1)
                    minCheck(j) = dist(indCheck(j));
                end
                [minVal,minInd] = min(minCheck);
                if minVal <= nnThreshold
                    indVal = indCheck(minInd);
                end
            else
                if dist(i) <= nnThreshold
                    indVal = i;
                end
            end

            if i == indVal
                matchPairs(end+1,:) = [k(i) i];
            end

        end

        % Re-sort Original Data
        newData1 = [];
        newData4 = [];
        newBB1 = [];
        newBB4 = [];
        newCen1 = [];
        newCen4 = [];
        for i = 1:size(matchPairs,1)
            newData4(i,:) = data4(matchPairs(i,1),:);
            newData1(i,:) = data1(matchPairs(i,2),:);

            newBB4(i,:) = bb4(matchPairs(i,1),:);
            newBB1(i,:) = bb1(matchPairs(i,2),:);

            newCen4(i,:) = cen4(matchPairs(i,1),:);
            newCen1(i,:) = cen1(matchPairs(i,2),:);
        end
        
        data4 = newData4;
        data1 = newData1;
        bb4 = newBB4;
        bb1 = newBB1;
        cen4 = newCen4;
        cen1 = newCen1;
        
        %-------------------------------------------------------%
        
        size1 = size(data1,1);
        size2 = size(data2,1);
        size3 = size(data3,1);
        size4 = size(data4,1);

        sizeCheck = [size1 size2 size3 size4];
        loopCounter = loopCounter + 1;
    end
    
    eval([dName1, '= data1;']);
    eval([bbName1, '= bb1;']);
    eval([cenName1, '= cen1;']);
    
    eval([dName2, '= data2;']);
    eval([bbName2, '= bb2;']);
    eval([cenName2, '= cen2;']);
    
    eval([dName3, '= data3;']);
    eval([bbName3, '= bb3;']);
    eval([cenName3, '= cen3;']);
    
    eval([dName4, '= data4;']);
    eval([bbName4, '= bb4;']);
    eval([cenName4, '= cen4;']);
end

%%

function alignAllPts()

    global finalFit488 finalFit594 finalFit640 finalFit405 matchVec
    
    size488 = size(finalFit488,1);
    size594 = size(finalFit594,1);
    size640 = size(finalFit640,1);
    size405 = size(finalFit405,1);
    tempCheck = [size488 size594 size640 size405];
    sizeCheck = tempCheck(matchVec == 1);
    
%     if ~all(diff(sizeCheck) == 0)
%         warndlg('Alignment Error.  Points  matched.');
%         return;
%     end
    
    disp('Performing Alignment...');
    
    % 4 Channel Alignment %
    if (sum(matchVec) == 4) && all(diff(sizeCheck) == 0)
        disp('Aligning for 4 Channels...');
        alignPoints4();
        disp('COMPLETE: Alignment Successful.');
        disp('****************************************************');
    end
    
    % 3 Channel Alignment %
    if (sum(matchVec) == 3) && all(diff(sizeCheck) == 0)
        disp('Aligning for 3 Channels...');
        alignPoints3();
        disp('COMPLETE: Alignment Successful.');
        disp('****************************************************');
    end
    
    % 2 Channel Alignment %
    if (sum(matchVec) == 2) && all(diff(sizeCheck) == 0)
        disp('Aligning for 2 Channels...');
        alignPoints2();
        disp('COMPLETE: Alignment Successful.');
        disp('****************************************************');
    end
    

end

%%

function [distMatrix] = distanceMatrix(data1, data2)
    
    if size(data1,2) ~= size(data2,2)
        disp('Error: Dimensionality of Sets Do Not Agree.');
    elseif size(data1,2) == size(data2,2)

        distMatrix = zeros(size(data1,2), size(data2,2));
        
        if (size(data1,2) == 3) && (size(data2,2) == 3)
            
            for i = 1:size(data1,1)
                for j = 1:size(data2,1)
                    distMatrix(i,j) = sqrt( (data2(j,1)-data1(i,1))^2 + (data2(j,2)-data1(i,2))^2 + (data2(j,3)-data1(i,3))^2 );
                end
            end
            
        elseif (size(data1,2) == 2) && (size(data2,2) == 2)
            
            for i = 1:size(data1,1)
                for j = 1:size(data2,1)
                    distMatrix(i,j) = sqrt( (data2(j,1)-data1(i,1))^2 + (data2(j,2)-data1(i,2))^2 );
                end
            end
            
        end

    end
    
end

%%

function alignPoints4()

    global finalFit488 finalFit594 finalFit640 finalFit405...
           finalBB488 finalBB594 finalBB640 finalBB405 gauss3DN gauss2DN
    
    % For 2D Alignment %
    if (size(finalFit488,2) == gauss2DN+1) && (size(finalFit594,2) == gauss2DN+1) && (size(finalFit640,2) == gauss2DN+1) && (size(finalFit405,2) == gauss2DN+1)
        
        % Align Red with Green %
        distMatrix594 = distanceMatrix(finalFit488(:,1:2), finalFit594(:,1:2));
        [finalFit594, finalBB594] = alignPts(finalFit594, finalBB594, distMatrix594);
        % Align Far Red with Green %
        distMatrix640 = distanceMatrix(finalFit488(:,1:2), finalFit640(:,1:2));
        [finalFit640, finalBB640] = alignPts(finalFit640, finalBB640, distMatrix640);
        % Align Blue with Green %
        distMatrix405 = distanceMatrix(finalFit488(:,1:2), finalFit405(:,1:2));
        [finalFit405, finalBB405] = alignPts(finalFit405, finalBB405, distMatrix405);

    % For 3D Alignment %
    elseif (size(finalFit488,2) == gauss3DN+1) && (size(finalFit594,2) == gauss3DN+1) && (size(finalFit640,2) == gauss3DN+1) && (size(finalFit405,2) == gauss3DN+1)
    
        % Align Red with Green %
        distMatrix594 = distanceMatrix(finalFit488(:,1:3), finalFit594(:,1:3));
        [finalFit594, finalBB594] = alignPts(finalFit594, finalBB594, distMatrix594);
        % Align Far Red with Green %
        distMatrix640 = distanceMatrix(finalFit488(:,1:3), finalFit640(:,1:3));
        [finalFit640, finalBB640] = alignPts(finalFit640, finalBB640, distMatrix640);
        % Align Blue with Green %
        distMatrix405 = distanceMatrix(finalFit488(:,1:3), finalFit405(:,1:3));
        [finalFit405, finalBB405] = alignPts(finalFit405, finalBB405, distMatrix405);     
        
    end
    
end



%%

function [orgPts, orgBB] = alignPts(finalChannelPts, finalChannelBB, distanceMatrixChannel)

    distSize = size(distanceMatrixChannel);
    matchPts = zeros(distSize(1),2);
    
    for i = 1:distSize(1)   
        matchPts(i,1) = i;
        [M, indMin] = min(distanceMatrixChannel(i,:));
        matchPts(i,2) = indMin;
    end

    % Reorganizing Data to Match Particles %
    
    currSize = size(finalChannelPts);
    orgPts = zeros(currSize(1), currSize(2));
    orgBB = zeros(size(finalChannelBB,1), size(finalChannelBB,2));
    
    for i = 1:currSize(1)    
        orgPts(i,:) = finalChannelPts(matchPts(i,2),:);
        orgBB(i,:) = finalChannelBB(matchPts(i,2),:);
    end

end


%%

function matchPoints3(data1, data2, data3, nnThreshold)

    global finalFit488 finalFit594 finalFit640 finalFit405...
           finalBB488 finalBB594 finalBB640 finalBB405...
           finalCentroids488 finalCentroids594 finalCentroids640...
           finalCentroids405
    
    dName1 = inputname(1);
    dName2 = inputname(2);
    dName3 = inputname(3);
    
    if dName1 == 'finalFit488'
        bbName1 = 'finalBB488';
        cenName1 = 'finalCentroids488';
        bb1 = finalBB488;
        cen1 = finalCentroids488;
    elseif dName1 == 'finalFit594'
        bbName1 = 'finalBB594';
        cenName1 = 'finalCentroids594';
        bb1 = finalBB594;
        cen1 = finalCentroids594;
    elseif dName1 == 'finalFit640'
        bbName1 = 'finalBB640';
        cenName1 = 'finalCentroids640';
        bb1 = finalBB640;
        cen1 = finalCentroids640;
    elseif dName1 == 'finalFit405'
        bbName1 = 'finalBB405';
        cenName1 = 'finalCentroids405';
        bb1 = finalBB405;
        cen1 = finalCentroids405;
    end
    
    
    if dName2 == 'finalFit488'
        bbName2 = 'finalBB488';
        cenName2 = 'finalCentroids488';
        bb2 = finalBB488;
        cen2 = finalCentroids488;
    elseif dName2 == 'finalFit594'
        bbName2 = 'finalBB594';
        cenName2 = 'finalCentroids594';
        bb2 = finalBB594;
        cen2 = finalCentroids594;
    elseif dName2 == 'finalFit640'
        bbName2 = 'finalBB640';
        cenName2 = 'finalCentroids640';
        bb2 = finalBB640;
        cen2 = finalCentroids640;
    elseif dName2 == 'finalFit405'
        bbName2 = 'finalBB405';
        cenName2 = 'finalCentroids405';
        bb2 = finalBB405;
        cen2 = finalCentroids405;
    end
    
    if dName3 == 'finalFit488'
        bbName3 = 'finalBB488';
        cenName3 = 'finalCentroids488';
        bb3 = finalBB488;
        cen3 = finalCentroids488;
    elseif dName3 == 'finalFit594'
        bbName3 = 'finalBB594';
        cenName3 = 'finalCentroids594';
        bb3 = finalBB594;
        cen3 = finalCentroids594;
    elseif dName3 == 'finalFit640'
        bbName3 = 'finalBB640';
        cenName3 = 'finalCentroids640';
        bb3 = finalBB640;
        cen3 = finalCentroids640;
    elseif dName3 == 'finalFit405'
        bbName3 = 'finalBB405';
        cenName3 = 'finalCentroids405';
        bb3 = finalBB405;
        cen3 = finalCentroids405;
    end
    
    size1 = size(data1,1);
    size2 = size(data2,1);
    size3 = size(data3,1);
    
    sizeCheck = [size1 size2 size3];
    
    loopCounter = 0;
    while ~all(diff(sizeCheck) == 0)
        
        if loopCounter >= 50
            error('Matching Error. Data Sets cannot be fully matched.');
        end
        
        %----------------Match 1 with 2----------------%
        set1 = data1(:,1:3);
        set2 = data2(:,1:3);
        [k,dist] = dsearchn(set1,set2);
        matchPairs = [];
        
        % Find all matching pairs %
        for i = 1:size(k,1)

            indVal = 0;
            minCheck = [];
            copyN = sum(k == k(i));
            if copyN > 1
                indCheck = find(k == k(i));
                for j = 1:size(indCheck,1)
                    minCheck(j) = dist(indCheck(j));
                end
                [minVal,minInd] = min(minCheck);
                if minVal <= nnThreshold
                    indVal = indCheck(minInd);
                end
            else
                if dist(i) <= nnThreshold
                    indVal = i;
                end
            end

            if i == indVal
                matchPairs(end+1,:) = [k(i) i];
            end

        end

        % Re-sort Original Data
        newData1 = [];
        newData2 = [];
        newBB1 = [];
        newBB2 = [];
        newCen1 = [];
        newCen2 = [];
        for i = 1:size(matchPairs,1)
            newData1(i,:) = data1(matchPairs(i,1),:);
            newData2(i,:) = data2(matchPairs(i,2),:);

            newBB1(i,:) = bb1(matchPairs(i,1),:);
            newBB2(i,:) = bb2(matchPairs(i,2),:);

            newCen1(i,:) = cen1(matchPairs(i,1),:);
            newCen2(i,:) = cen2(matchPairs(i,2),:);
        end
        
        data1 = newData1;
        data2 = newData2;
        bb1 = newBB1;
        bb2 = newBB2;
        cen1 = newCen1;
        cen2 = newCen2;
        
        %----------------Match 2 with 3----------------%
        set1 = data2(:,1:3);
        set2 = data3(:,1:3);
        [k,dist] = dsearchn(set1,set2);
        matchPairs = [];
        
        % Find all matching pairs %
        for i = 1:size(k,1)

            indVal = 0;
            minCheck = [];
            copyN = sum(k == k(i));
            if copyN > 1
                indCheck = find(k == k(i));
                for j = 1:size(indCheck,1)
                    minCheck(j) = dist(indCheck(j));
                end
                [minVal,minInd] = min(minCheck);
                if minVal <= nnThreshold
                    indVal = indCheck(minInd);
                end
            else
                if dist(i) <= nnThreshold
                    indVal = i;
                end
            end

            if i == indVal
                matchPairs(end+1,:) = [k(i) i];
            end

        end

        % Re-sort Original Data
        newData2 = [];
        newData3 = [];
        newBB2 = [];
        newBB3 = [];
        newCen2 = [];
        newCen3 = [];
        for i = 1:size(matchPairs,1)
            newData2(i,:) = data2(matchPairs(i,1),:);
            newData3(i,:) = data3(matchPairs(i,2),:);

            newBB2(i,:) = bb2(matchPairs(i,1),:);
            newBB3(i,:) = bb3(matchPairs(i,2),:);

            newCen2(i,:) = cen2(matchPairs(i,1),:);
            newCen3(i,:) = cen3(matchPairs(i,2),:);
        end
        
        data2 = newData2;
        data3 = newData3;
        bb2 = newBB2;
        bb3 = newBB3;
        cen2 = newCen2;
        cen3 = newCen3;
        
        %----------------Match 3 with 1----------------%
        set1 = data3(:,1:3);
        set2 = data1(:,1:3);
        [k,dist] = dsearchn(set1,set2);
        matchPairs = [];
        
        % Find all matching pairs %
        for i = 1:size(k,1)

            indVal = 0;
            minCheck = [];
            copyN = sum(k == k(i));
            if copyN > 1
                indCheck = find(k == k(i));
                for j = 1:size(indCheck,1)
                    minCheck(j) = dist(indCheck(j));
                end
                [minVal,minInd] = min(minCheck);
                if minVal <= nnThreshold
                    indVal = indCheck(minInd);
                end
            else
                if dist(i) <= nnThreshold
                    indVal = i;
                end
            end

            if i == indVal
                matchPairs(end+1,:) = [k(i) i];
            end

        end

        % Re-sort Original Data
        newData1 = [];
        newData3 = [];
        newBB1 = [];
        newBB3 = [];
        newCen1 = [];
        newCen3 = [];
        for i = 1:size(matchPairs,1)
            newData3(i,:) = data3(matchPairs(i,1),:);
            newData1(i,:) = data1(matchPairs(i,2),:);

            newBB3(i,:) = bb3(matchPairs(i,1),:);
            newBB1(i,:) = bb1(matchPairs(i,2),:);

            newCen3(i,:) = cen3(matchPairs(i,1),:);
            newCen1(i,:) = cen1(matchPairs(i,2),:);
        end
        
        data3 = newData3;
        data1 = newData1;
        bb3 = newBB3;
        bb1 = newBB1;
        cen3 = newCen3;
        cen1 = newCen1;
        
        %---------------------------------------
        size1 = size(data1,1);
        size2 = size(data2,1);
        size3 = size(data3,1);
        
        sizeCheck = [size1 size2 size3];
       
        loopCounter = loopCounter + 1;
    end
    
    eval([dName1, '= data1;']);
    eval([bbName1, '= bb1;']);
    eval([cenName1, '= cen1;']);
    
    eval([dName2, '= data2;']);
    eval([bbName2, '= bb2;']);
    eval([cenName2, '= cen2;']);
    
    eval([dName3, '= data3;']);
    eval([bbName3, '= bb3;']);
    eval([cenName3, '= cen3;']);

end

%%

function chooseMatch(~,~)

    global finalFit488 finalFit594 finalFit640 finalFit405 matchVec...
            nnThreshold

    matchFig = figure();
    set(gcf,'NumberTitle','off')
    set(gcf,'Name','Choose Channels To Match')
    clf;
    set(gcf, 'Position',  [100, 100, 350, 350]);
    set(gcf, 'Resize', 'off');
    matchPan = uibuttongroup('Title','Choose Channels To Match','FontSize',12,...
        'BackgroundColor',[1,1,1],'FontWeight', 'bold',...
        'Position',[0.05 0.2 .9 .7]);

    posVec = [170 120 70 20];
    pos = 1;
    
    if ~isempty(finalFit488)
        opt488 = uicontrol(matchPan,'Style','Checkbox','String','Green Channel','FontSize',12,...
            'pos',[10 posVec(pos) 250 30], 'BackgroundColor',[0.6,1,0.6]);
        set(opt488, 'Value', 1)
        pos = pos + 1;
    else
        opt488 = 0;
    end
    if ~isempty(finalFit594)
        opt594 = uicontrol(matchPan,'Style','Checkbox','String','Red Channel','FontSize',12,...
            'pos',[10 posVec(pos) 250 30], 'BackgroundColor',[1,0.5,0.5]);
        set(opt594, 'Value', 1)
        pos = pos + 1;
    else
        opt594 = 0;
    end
    if ~isempty(finalFit640)
        opt640 = uicontrol(matchPan,'Style','Checkbox','String','Far Red Channel','FontSize',12,...
            'pos',[10 posVec(pos) 250 30], 'BackgroundColor',[0.8,0.3,0.8]);
        set(opt640, 'Value', 1)
        pos = pos + 1;
    else
        opt640 = 0;
    end
    if ~isempty(finalFit405)
        opt405 = uicontrol(matchPan,'Style','Checkbox','String','Blue Channel','FontSize',12,...
            'pos',[10 posVec(pos) 250 30], 'BackgroundColor',[0.6,0.6,1]);
        set(opt405, 'Value', 1)
        pos = pos + 1;
    else
        opt405 = 0;
    end
    
    uicontrol('Parent', matchFig, 'Style', 'pushbutton', 'Position', [200,20,120, 35],...
        'FontSize',16, 'String', 'MATCH', 'Callback', {@setMatch});
    
    uicontrol('Parent', matchFig,'Style','Text','String','NN Threshold (um):','FontSize',10,...
    'pos',[28,37,120, 25]);
    nnTField = uicontrol('Parent', matchFig,'Style','edit','String','0.5','FontSize',13,...
            'pos',[30,21,120, 25], 'BackgroundColor',[1,1,1]);

    function setMatch(~,~)
        
        try
            ch488 = get(opt488, 'Value');
        catch
            ch488 = 0;
        end
        try
            ch594 = get(opt594, 'Value');
        catch
            ch594 = 0;
        end
        try
            ch640 = get(opt640, 'Value');
        catch
            ch640 = 0;
        end
        try
            ch405 = get(opt405, 'Value');
        catch
            ch405 = 0;
        end
        
        matchVec = [ch488 ch594 ch640 ch405];
        nnText = get(nnTField, 'String');
        nnThreshold = str2double(nnText);
        close(matchFig);
        matchPoints();
        
    end


end


%%

function alignPoints3()

    global finalFit488 finalFit594 finalFit640 finalFit405...
           finalBB488 finalBB594 finalBB640 finalBB405 matchVec gauss3DN...
           gauss2DN
    
    size488 = size(finalFit488,2);
    size594 = size(finalFit594,2);
    size640 = size(finalFit640,2);
    size405 = size(finalFit405,2);
    tempCheck = [size488 size594 size640 size405];
    sizeCheck = tempCheck(matchVec == 1);  
       
       
    % For 2D Alignment %
    if (sizeCheck(1) == gauss2DN+1) && (sizeCheck(2) == gauss2DN+1) && (sizeCheck(3) == gauss2DN+1)
        
        % Align G R FR %
        if (matchVec(1) == 1) && (matchVec(2) == 1) && (matchVec(3) == 1)
            % Align Red with Green %
            distMatrix594 = distanceMatrix(finalFit488(:,1:2), finalFit594(:,1:2));
            [finalFit594, finalBB594] = alignPts(finalFit594, finalBB594, distMatrix594);
            % Align Far Red with Green %
            distMatrix640 = distanceMatrix(finalFit488(:,1:2), finalFit640(:,1:2));
            [finalFit640, finalBB640] = alignPts(finalFit640, finalBB640, distMatrix640);
        % Align G R B %
        elseif (matchVec(1) == 1) && (matchVec(2) == 1) && (matchVec(4) == 1)
            % Align Red with Green %
            distMatrix594 = distanceMatrix(finalFit488(:,1:2), finalFit594(:,1:2));
            [finalFit594, finalBB594] = alignPts(finalFit594, finalBB594, distMatrix594);
            % Align Blue with Green %
            distMatrix405 = distanceMatrix(finalFit488(:,1:2), finalFit405(:,1:2));
            [finalFit405, finalBB405] = alignPts(finalFit405, finalBB405, distMatrix405);
        % Align G FR B %
        elseif (matchVec(1) == 1) && (matchVec(3) == 1) && (matchVec(4) == 1)
            % Align Far Red with Green %
            distMatrix640 = distanceMatrix(finalFit488(:,1:2), finalFit640(:,1:2));
            [finalFit640, finalBB640] = alignPts(finalFit640, finalBB640, distMatrix640);
            % Align Blue with Green %
            distMatrix405 = distanceMatrix(finalFit488(:,1:2), finalFit405(:,1:2));
            [finalFit405, finalBB405] = alignPts(finalFit405, finalBB405, distMatrix405);
        % Align R FR B %
        elseif (matchVec(2) == 1) && (matchVec(3) == 1) && (matchVec(4) == 1)
            % Align Far Red with Red %
            distMatrix640 = distanceMatrix(finalFit594(:,1:2), finalFit640(:,1:2));
            [finalFit640, finalBB640] = alignPts(finalFit640, finalBB640, distMatrix640);
            % Align Blue with Green %
            distMatrix405 = distanceMatrix(finalFit594(:,1:2), finalFit405(:,1:2));
            [finalFit405, finalBB405] = alignPts(finalFit405, finalBB405, distMatrix405);
        end
        

    % For 3D Alignment %
    elseif (sizeCheck(1) == gauss3DN+1) && (sizeCheck(2) == gauss3DN+1) && (sizeCheck(3) == gauss3DN+1)
    
        % Align G R FR %
        if (matchVec(1) == 1) && (matchVec(2) == 1) && (matchVec(3) == 1)
            % Align Red with Green %
            distMatrix594 = distanceMatrix(finalFit488(:,1:3), finalFit594(:,1:3));
            [finalFit594, finalBB594] = alignPts(finalFit594, finalBB594, distMatrix594);
            % Align Far Red with Green %
            distMatrix640 = distanceMatrix(finalFit488(:,1:3), finalFit640(:,1:3));
            [finalFit640, finalBB640] = alignPts(finalFit640, finalBB640, distMatrix640);
        % Align G R B %
        elseif (matchVec(1) == 1) && (matchVec(2) == 1) && (matchVec(4) == 1)
            % Align Red with Green %
            distMatrix594 = distanceMatrix(finalFit488(:,1:3), finalFit594(:,1:3));
            [finalFit594, finalBB594] = alignPts(finalFit594, finalBB594, distMatrix594);
            % Align Blue with Green %
            distMatrix405 = distanceMatrix(finalFit488(:,1:3), finalFit405(:,1:3));
            [finalFit405, finalBB405] = alignPts(finalFit405, finalBB405, distMatrix405);
        % Align G FR B %
        elseif (matchVec(1) == 1) && (matchVec(3) == 1) && (matchVec(4) == 1)
            % Align Far Red with Green %
            distMatrix640 = distanceMatrix(finalFit488(:,1:3), finalFit640(:,1:3));
            [finalFit640, finalBB640] = alignPts(finalFit640, finalBB640, distMatrix640);
            % Align Blue with Green %
            distMatrix405 = distanceMatrix(finalFit488(:,1:3), finalFit405(:,1:3));
            [finalFit405, finalBB405] = alignPts(finalFit405, finalBB405, distMatrix405);
        % Align R FR B %
        elseif (matchVec(2) == 1) && (matchVec(3) == 1) && (matchVec(4) == 1)
            % Align Far Red with Red %
            distMatrix640 = distanceMatrix(finalFit594(:,1:3), finalFit640(:,1:3));
            [finalFit640, finalBB640] = alignPts(finalFit640, finalBB640, distMatrix640);
            % Align Blue with Green %
            distMatrix405 = distanceMatrix(finalFit594(:,1:3), finalFit405(:,1:3));
            [finalFit405, finalBB405] = alignPts(finalFit405, finalBB405, distMatrix405);
        end  
        
    end
    
end


%%

function matchPoints2(data1, data2, nnThreshold)

    global finalFit488 finalFit594 finalFit640 finalFit405...
           finalBB488 finalBB594 finalBB640 finalBB405...
           finalCentroids488 finalCentroids594 finalCentroids640...
           finalCentroids405
    
    dName1 = inputname(1);
    dName2 = inputname(2);
    
    if dName1 == 'finalFit488'
        bbName1 = 'finalBB488';
        cenName1 = 'finalCentroids488';
        bb1 = finalBB488;
        cen1 = finalCentroids488;
    elseif dName1 == 'finalFit594'
        bbName1 = 'finalBB594';
        cenName1 = 'finalCentroids594';
        bb1 = finalBB594;
        cen1 = finalCentroids594;
    elseif dName1 == 'finalFit640'
        bbName1 = 'finalBB640';
        cenName1 = 'finalCentroids640';
        bb1 = finalBB640;
        cen1 = finalCentroids640;
    elseif dName1 == 'finalFit405'
        bbName1 = 'finalBB405';
        cenName1 = 'finalCentroids405';
        bb1 = finalBB405;
        cen1 = finalCentroids405;
    end
    
    
    if dName2 == 'finalFit488'
        bbName2 = 'finalBB488';
        cenName2 = 'finalCentroids488';
        bb2 = finalBB488;
        cen2 = finalCentroids488;
    elseif dName2 == 'finalFit594'
        bbName2 = 'finalBB594';
        cenName2 = 'finalCentroids594';
        bb2 = finalBB594;
        cen2 = finalCentroids594;
    elseif dName2 == 'finalFit640'
        bbName2 = 'finalBB640';
        cenName2 = 'finalCentroids640';
        bb2 = finalBB640;
        cen2 = finalCentroids640;
    elseif dName2 == 'finalFit405'
        bbName2 = 'finalBB405';
        cenName2 = 'finalCentroids405';
        bb2 = finalBB405;
        cen2 = finalCentroids405;
    end
    
    set1 = data1(:,1:3);
    set2 = data2(:,1:3);
    [k,dist] = dsearchn(set1,set2);
    matchPairs = [];

    
    % Find all matching pairs %
    for i = 1:size(k,1)
        
        indVal = 0;
        minCheck = [];
        copyN = sum(k == k(i));
        if copyN > 1
            indCheck = find(k == k(i));
            for j = 1:size(indCheck,1)
                minCheck(j) = dist(indCheck(j));
            end
            [minVal,minInd] = min(minCheck);
            if minVal <= nnThreshold
                indVal = indCheck(minInd);
            end
        else
            if dist(i) <= nnThreshold
                indVal = i;
            end
        end
        
        if i == indVal
            matchPairs(end+1,:) = [k(i) i];
        end
        
    end
    
    % Re-sort Original Data
    newData1 = [];
    newData2 = [];
    newBB1 = [];
    newBB2 = [];
    newCen1 = [];
    newCen2 = [];
    for i = 1:size(matchPairs,1)
        newData1(i,:) = data1(matchPairs(i,1),:);
        newData2(i,:) = data2(matchPairs(i,2),:);
        
        newBB1(i,:) = bb1(matchPairs(i,1),:);
        newBB2(i,:) = bb2(matchPairs(i,2),:);
        
        newCen1(i,:) = cen1(matchPairs(i,1),:);
        newCen2(i,:) = cen2(matchPairs(i,2),:);
    end
    
    eval([dName1, '= newData1;']);
    eval([bbName1, '= newBB1;']);
    eval([cenName1, '= newCen1;']);
    
    eval([dName2, '= newData2;']);
    eval([bbName2, '= newBB2;']);
    eval([cenName2, '= newCen2;']);

end

%%

function alignPoints2()

    global finalFit488 finalFit594 finalFit640 finalFit405...
           finalBB488 finalBB594 finalBB640 finalBB405 matchVec gauss3DN...
            gauss2DN
    
    size488 = size(finalFit488,2);
    size594 = size(finalFit594,2);
    size640 = size(finalFit640,2);
    size405 = size(finalFit405,2);
    tempCheck = [size488 size594 size640 size405];
    sizeCheck = tempCheck(matchVec == 1);  
       
       
    % For 2D Alignment %
    if (sizeCheck(1) == gauss2DN+1) && (sizeCheck(2) == gauss2DN+1)
        
        % Align G R %
        if (matchVec(1) == 1) && (matchVec(2) == 1) 
            % Align Red with Green %
            distMatrix594 = distanceMatrix(finalFit488(:,1:2), finalFit594(:,1:2));
            [finalFit594, finalBB594] = alignPts(finalFit594, finalBB594, distMatrix594);
        % Align G FR %
        elseif (matchVec(1) == 1) && (matchVec(3) == 1)
            % Align Far Red with Green %
            distMatrix640 = distanceMatrix(finalFit488(:,1:2), finalFit640(:,1:2));
            [finalFit640, finalBB640] = alignPts(finalFit640, finalBB640, distMatrix640);
        % Align G B %
        elseif (matchVec(1) == 1) && (matchVec(4) == 1) 
            % Align Far Red with Green %
            distMatrix405 = distanceMatrix(finalFit488(:,1:2), finalFit405(:,1:2));
            [finalFit405, finalBB405] = alignPts(finalFit405, finalBB405, distMatrix405);
        % Align R FR %
        elseif (matchVec(2) == 1) && (matchVec(3) == 1)
            % Align Far Red with Red %
            distMatrix640 = distanceMatrix(finalFit594(:,1:2), finalFit640(:,1:2));
            [finalFit640, finalBB640] = alignPts(finalFit640, finalBB640, distMatrix640);
        % Align R B %
        elseif (matchVec(2) == 1) && (matchVec(4) == 1) 
            % Align Blue with Red %
            distMatrix405 = distanceMatrix(finalFit594(:,1:2), finalFit405(:,1:2));
            [finalFit405, finalBB405] = alignPts(finalFit405, finalBB405, distMatrix405);
        % Align FR B %
        elseif (matchVec(3) == 1) && (matchVec(4) == 1)
            % Align Blue with Far Red %
            distMatrix405 = distanceMatrix(finalFit640(:,1:2), finalFit405(:,1:2));
            [finalFit405, finalBB405] = alignPts(finalFit405, finalBB405, distMatrix405);
        end
        

    % For 3D Alignment %
    elseif (sizeCheck(1) == gauss3DN+1) && (sizeCheck(2) == gauss3DN+1)
    
        % Align G R %
        if (matchVec(1) == 1) && (matchVec(2) == 1) 
            % Align Red with Green %
            distMatrix594 = distanceMatrix(finalFit488(:,1:3), finalFit594(:,1:3));
            [finalFit594, finalBB594] = alignPts(finalFit594, finalBB594, distMatrix594);
        % Align G FR %
        elseif (matchVec(1) == 1) && (matchVec(3) == 1)
            % Align Far Red with Green %
            distMatrix640 = distanceMatrix(finalFit488(:,1:3), finalFit640(:,1:3));
            [finalFit640, finalBB640] = alignPts(finalFit640, finalBB640, distMatrix640);
        % Align G B %
        elseif (matchVec(1) == 1) && (matchVec(4) == 1) 
            % Align Far Red with Green %
            distMatrix405 = distanceMatrix(finalFit488(:,1:3), finalFit405(:,1:3));
            [finalFit405, finalBB405] = alignPts(finalFit405, finalBB405, distMatrix405);
        % Align R FR %
        elseif (matchVec(2) == 1) && (matchVec(3) == 1)
            % Align Far Red with Red %
            distMatrix640 = distanceMatrix(finalFit594(:,1:3), finalFit640(:,1:3));
            [finalFit640, finalBB640] = alignPts(finalFit640, finalBB640, distMatrix640);
        % Align R B %
        elseif (matchVec(2) == 1) && (matchVec(4) == 1) 
            % Align Blue with Red %
            distMatrix405 = distanceMatrix(finalFit594(:,1:3), finalFit405(:,1:3));
            [finalFit405, finalBB405] = alignPts(finalFit405, finalBB405, distMatrix405);
        % Align FR B %
        elseif (matchVec(3) == 1) && (matchVec(4) == 1)
            % Align Blue with Far Red %
            distMatrix405 = distanceMatrix(finalFit640(:,1:3), finalFit405(:,1:3));
            [finalFit405, finalBB405] = alignPts(finalFit405, finalBB405, distMatrix405);
        end
        
    end
    
end

%%

function generateDistanceMatrices()

    global  distChoiceVec finalFit488 finalFit594 finalFit640 finalFit405...
            distMatrix488 distMatrix594 distMatrix640 distMatrix405...
            distMatrix488_594 distMatrix488_640 distMatrix488_405...
            distMatrix594_640 distMatrix594_405 distMatrix640_405 gauss3DN...
            gauss2DN
    
    disp('Generating Distance Matrices...');
    % Generate Self Matrices First
    if distChoiceVec(1) == 1
        if size(finalFit488,2) == gauss2DN+1
            distMatrix488 = distanceMatrix(finalFit488(:,1:2), finalFit488(:,1:2));
        elseif size(finalFit488,2) == gauss3DN+1
            distMatrix488 = distanceMatrix(finalFit488(:,1:3), finalFit488(:,1:3));
        end
    end
    if distChoiceVec(2) == 1
        if size(finalFit594,2) == gauss2DN+1
            distMatrix594 = distanceMatrix(finalFit594(:,1:2), finalFit594(:,1:2));
        elseif size(finalFit594,2) == gauss3DN+1
            distMatrix594 = distanceMatrix(finalFit594(:,1:3), finalFit594(:,1:3));
        end
    end
    if distChoiceVec(3) == 1
        if size(finalFit640,2) == gauss2DN+1
            distMatrix640 = distanceMatrix(finalFit640(:,1:2), finalFit640(:,1:2));
        elseif size(finalFit488,2) == gauss3DN+1
            distMatrix640 = distanceMatrix(finalFit640(:,1:3), finalFit640(:,1:3));
        end
    end
    if distChoiceVec(4) == 1
        if size(finalFit405,2) == gauss2DN+1
            distMatrix405 = distanceMatrix(finalFit405(:,1:2), finalFit405(:,1:2));
        elseif size(finalFit488,2) == gauss3DN+1
            distMatrix405 = distanceMatrix(finalFit405(:,1:3), finalFit405(:,1:3));
        end
    end
    
    % HANDLE COMBINATIONS %
    
    % Green and Red %
    if (distChoiceVec(1) == 1) && (distChoiceVec(2) == 1)
        if (size(finalFit488,2) == gauss2DN+1) && (size(finalFit594,2) == gauss2DN+1)
            distMatrix488_594 = distanceMatrix(finalFit488(:,1:2), finalFit594(:,1:2));
        elseif (size(finalFit488,2) == gauss3DN+1) && (size(finalFit594,2) == gauss3DN+1)
            distMatrix488_594 = distanceMatrix(finalFit488(:,1:3), finalFit594(:,1:3));
        else
            disp('Error: Green and Red Dimensionality Mismatch!');
        end
    end
    
    % Green and Far Red %
    if (distChoiceVec(1) == 1) && (distChoiceVec(3) == 1)
        if (size(finalFit488,2) == gauss2DN) && (size(finalFit640,2) == gauss2DN)
            distMatrix488_640 = distanceMatrix(finalFit488(:,1:2), finalFit640(:,1:2));
        elseif (size(finalFit488,2) == gauss3DN) && (size(finalFit640,2) == gauss3DN)
            distMatrix488_640 = distanceMatrix(finalFit488(:,1:3), finalFit640(:,1:3));
        else
            disp('Error: Green and Far Red Dimensionality Mismatch!');
        end
    end

    % Green and Blue %
    if (distChoiceVec(1) == 1) && (distChoiceVec(4) == 1)
        if (size(finalFit488,2) == gauss2DN+1) && (size(finalFit405,2) == gauss2DN+1)
            distMatrix488_405 = distanceMatrix(finalFit488(:,1:2), finalFit405(:,1:2));
        elseif (size(finalFit488,2) == gauss3DN+1) && (size(finalFit405,2) == gauss3DN+1)
            distMatrix488_405 = distanceMatrix(finalFit488(:,1:3), finalFit405(:,1:3));
        else
            disp('Error: Green and Blue Dimensionality Mismatch!');
        end
    end
    
    % Red and Far Red %
    if (distChoiceVec(2) == 1) && (distChoiceVec(3) == 1)
        if (size(finalFit594,2) == gauss2DN+1) && (size(finalFit640,2) == gauss2DN+1)
            distMatrix594_640 = distanceMatrix(finalFit594(:,1:2), finalFit640(:,1:2));
        elseif (size(finalFit594,2) == gauss3DN+1) && (size(finalFit640,2) == gauss3DN+1)
            distMatrix594_640 = distanceMatrix(finalFit594(:,1:3), finalFit640(:,1:3));
        else
            disp('Error: Red and Far Red Dimensionality Mismatch!');
        end
    end
    
    % Red and Blue %
    if (distChoiceVec(2) == 1) && (distChoiceVec(4) == 1)
        if (size(finalFit594,2) == gauss2DN+1) && (size(finalFit405,2) == gauss2DN+1)
            distMatrix594_405 = distanceMatrix(finalFit594(:,1:2), finalFit405(:,1:2));
        elseif (size(finalFit594,2) == gauss3DN+1) && (size(finalFit405,2) == gauss3DN+1)
            distMatrix594_405 = distanceMatrix(finalFit594(:,1:3), finalFit405(:,1:3));
        else
            disp('Error: Red and Blue Dimensionality Mismatch!');
        end
    end
    
    % Far Red and Blue %
    if (distChoiceVec(3) == 1) && (distChoiceVec(4) == 1)
        if (size(finalFit640,2) == gauss2DN+1) && (size(finalFit405,2) == gauss2DN+1)
            distMatrix640_405 = distanceMatrix(finalFit640(:,1:2), finalFit405(:,1:2));
        elseif (size(finalFit640,2) == gauss3DN+1) && (size(finalFit405,2) == gauss3DN+1)
            distMatrix640_405 = distanceMatrix(finalFit640(:,1:3), finalFit405(:,1:3));
        else
            disp('Error: Far Red and Blue Dimensionality Mismatch!');
        end
    end

    disp('Distance Matrices Successfully Generated.');
    disp('****************************************************');
    
    msgbox('COMPLETE: Distance Matrices Successfully Generated.');

end

%%

function chooseDistanceMatrices(~,~)

    global finalFit488 finalFit594 finalFit640 finalFit405 distChoiceVec

    matchFig = figure();
    set(gcf,'NumberTitle','off')
    set(gcf,'Name','Choose Channels For Distance Matrices')
    clf;
    set(gcf, 'Position',  [100, 100, 350, 350]);
    set(gcf, 'Resize', 'off');
    matchPan = uibuttongroup('Title','Choose Channels - Distance Matrices','FontSize',12,...
        'BackgroundColor',[1,1,1],'FontWeight', 'bold',...
        'Position',[0.05 0.2 .9 .7]);

    posVec = [170 120 70 20];
    pos = 1;
    
    if ~isempty(finalFit488)
        opt488 = uicontrol(matchPan,'Style','Checkbox','String','Green Channel','FontSize',12,...
            'pos',[10 posVec(pos) 250 30], 'BackgroundColor',[0.6,1,0.6]);
        set(opt488, 'Value', 1)
        pos = pos + 1;
    else
        opt488 = 0;
    end
    if ~isempty(finalFit594)
        opt594 = uicontrol(matchPan,'Style','Checkbox','String','Red Channel','FontSize',12,...
            'pos',[10 posVec(pos) 250 30], 'BackgroundColor',[1,0.5,0.5]);
        set(opt594, 'Value', 1)
        pos = pos + 1;
    else
        opt594 = 0;
    end
    if ~isempty(finalFit640)
        opt640 = uicontrol(matchPan,'Style','Checkbox','String','Far Red Channel','FontSize',12,...
            'pos',[10 posVec(pos) 250 30], 'BackgroundColor',[0.8,0.3,0.8]);
        set(opt640, 'Value', 1)
        pos = pos + 1;
    else
        opt640 = 0;
    end
    if ~isempty(finalFit405)
        opt405 = uicontrol(matchPan,'Style','Checkbox','String','Blue Channel','FontSize',12,...
            'pos',[10 posVec(pos) 250 30], 'BackgroundColor',[0.6,0.6,1]);
        set(opt405, 'Value', 1)
        pos = pos + 1;
    else
        opt405 = 0;
    end
    
    uicontrol('Parent', matchFig, 'Style', 'pushbutton', 'Position', [200,20,120, 35],...
        'FontSize',12, 'String', 'GENERATE', 'Callback', {@setDist});

    function setDist(~,~)
        
        try
            ch488 = get(opt488, 'Value');
        catch
            ch488 = 0;
        end
        try
            ch594 = get(opt594, 'Value');
        catch
            ch594 = 0;
        end
        try
            ch640 = get(opt640, 'Value');
        catch
            ch640 = 0;
        end
        try
            ch405 = get(opt405, 'Value');
        catch
            ch405 = 0;
        end
        
        distChoiceVec = [ch488 ch594 ch640 ch405];
        close(matchFig);
        generateDistanceMatrices();
        
    end

end


%%

function chooseAberrations(~,~)

    global finalFit488 finalFit594 finalFit640 finalFit405 aberrationsVec

    matchFig = figure();
    set(gcf,'NumberTitle','off')
    set(gcf,'Name','Choose Channels For Aberration Calculations')
    clf;
    set(gcf, 'Position',  [100, 100, 350, 350]);
    set(gcf, 'Resize', 'off');
    matchPan = uibuttongroup('Title','Choose Channels - Aberrations','FontSize',12,...
        'BackgroundColor',[1,1,1],'FontWeight', 'bold',...
        'Position',[0.05 0.2 .9 .7]);

    posVec = [170 120 70 20];
    pos = 1;
    
    if ~isempty(finalFit488)
        opt488 = uicontrol(matchPan,'Style','Checkbox','String','Green Channel','FontSize',12,...
            'pos',[10 posVec(pos) 250 30], 'BackgroundColor',[0.6,1,0.6]);
        set(opt488, 'Value', 1)
        pos = pos + 1;
    else
        opt488 = 0;
    end
    if ~isempty(finalFit594)
        opt594 = uicontrol(matchPan,'Style','Checkbox','String','Red Channel','FontSize',12,...
            'pos',[10 posVec(pos) 250 30], 'BackgroundColor',[1,0.5,0.5]);
        set(opt594, 'Value', 1)
        pos = pos + 1;
    else
        opt594 = 0;
    end
    if ~isempty(finalFit640)
        opt640 = uicontrol(matchPan,'Style','Checkbox','String','Far Red Channel','FontSize',12,...
            'pos',[10 posVec(pos) 250 30], 'BackgroundColor',[0.8,0.3,0.8]);
        set(opt640, 'Value', 1)
        pos = pos + 1;
    else
        opt640 = 0;
    end
    if ~isempty(finalFit405)
        opt405 = uicontrol(matchPan,'Style','Checkbox','String','Blue Channel','FontSize',12,...
            'pos',[10 posVec(pos) 250 30], 'BackgroundColor',[0.6,0.6,1]);
        set(opt405, 'Value', 1)
        pos = pos + 1;
    else
        opt405 = 0;
    end
    
    uicontrol('Parent', matchFig, 'Style', 'pushbutton', 'Position', [200,20,120, 35],...
        'FontSize',12, 'String', 'GENERATE', 'Callback', {@setAberrations});

    function setAberrations(~,~)
        
        try
            ch488 = get(opt488, 'Value');
        catch
            ch488 = 0;
        end
        try
            ch594 = get(opt594, 'Value');
        catch
            ch594 = 0;
        end
        try
            ch640 = get(opt640, 'Value');
        catch
            ch640 = 0;
        end
        try
            ch405 = get(opt405, 'Value');
        catch
            ch405 = 0;
        end
        
        aberrationsVec = [ch488 ch594 ch640 ch405];
        
        % Check for Dimensionality Mismatch %
        size488 = size(finalFit488,2);
        size594 = size(finalFit594,2);
        size640 = size(finalFit640,2);
        size405 = size(finalFit405,2);
        tempCheck = [size488 size594 size640 size405];
        sizeCheck = tempCheck(aberrationsVec == 1);  
        
        if ~all(diff(sizeCheck) == 0)
            warndlg('Error: Dimensionality Mismatch.');
            return;
        end
        
        % Check for Size Mismatch %
        size488 = size(finalFit488,1);
        size594 = size(finalFit594,1);
        size640 = size(finalFit640,1);
        size405 = size(finalFit405,1);
        tempCheck = [size488 size594 size640 size405];
        sizeCheck = tempCheck(aberrationsVec == 1);  
        
        if ~all(diff(sizeCheck) == 0)
            warndlg('Error: Data Sizes Different. Aberration calculations cannot be performed.');
            return;
        end
         
        close(matchFig);
        getAllAberrations();
        
    end

end

%%

function getAllAberrations()

    global  aberrationsVec ab488_594 ab488_640 ab488_405 ab594_640...
            ab594_405 ab640_405 finalFit488 finalFit594 finalFit640...
            finalFit405 gauss3DN gauss2DN
    
    disp('Calculating Aberrations...');
    
    % HANDLE COMBINATIONS %
    
    % Green and Red %
    if (aberrationsVec(1) == 1) && (aberrationsVec(2) == 1)
        if (size(finalFit488,2) == gauss2DN+1) && (size(finalFit594,2) == gauss2DN+1)
            ab488_594 = getAberration(finalFit488(:,1:2), finalFit594(:,1:2));
        elseif (size(finalFit488,2) == gauss3DN+1) && (size(finalFit594,2) == gauss3DN+1)
            ab488_594 = getAberration(finalFit488(:,1:3), finalFit594(:,1:3));
        else
            disp('Error: Green and Red Dimensionality Mismatch!');
        end
    end
    
    % Green and Far Red %
    if (aberrationsVec(1) == 1) && (aberrationsVec(3) == 1)
        if (size(finalFit488,2) == gauss2DN+1) && (size(finalFit640,2) == gauss2DN+1)
            ab488_640 = getAberration(finalFit488(:,1:2), finalFit640(:,1:2));
        elseif (size(finalFit488,2) == gauss3DN+1) && (size(finalFit640,2) == gauss3DN+1)
            ab488_640 = getAberration(finalFit488(:,1:3), finalFit640(:,1:3));
        else
            disp('Error: Green and Far Red Dimensionality Mismatch!');
        end
    end

    % Green and Blue %
    if (aberrationsVec(1) == 1) && (aberrationsVec(4) == 1)
        if (size(finalFit488,2) == gauss2DN+1) && (size(finalFit405,2) == gauss2DN+1)
            ab488_405 = getAberration(finalFit488(:,1:2), finalFit405(:,1:2));
        elseif (size(finalFit488,2) == gauss3DN+1) && (size(finalFit405,2) == gauss3DN+1)
            ab488_405 = getAberration(finalFit488(:,1:3), finalFit405(:,1:3));
        else
            disp('Error: Green and Blue Dimensionality Mismatch!');
        end
    end
    
    % Red and Far Red %
    if (aberrationsVec(2) == 1) && (aberrationsVec(3) == 1)
        if (size(finalFit594,2) == gauss2DN+1) && (size(finalFit640,2) == gauss2DN+1)
            ab594_640 = getAberration(finalFit594(:,1:2), finalFit640(:,1:2));
        elseif (size(finalFit594,2) == gauss3DN+1) && (size(finalFit640,2) == gauss3DN+1)
            ab594_640 = getAberration(finalFit594(:,1:3), finalFit640(:,1:3));
        else
            disp('Error: Red and Far Red Dimensionality Mismatch!');
        end
    end
    
    % Red and Blue %
    if (aberrationsVec(2) == 1) && (aberrationsVec(4) == 1)
        if (size(finalFit594,2) == gauss2DN+1) && (size(finalFit405,2) == gauss2DN+1)
            ab594_405 = getAberration(finalFit594(:,1:2), finalFit405(:,1:2));
        elseif (size(finalFit594,2) == gauss3DN+1) && (size(finalFit405,2) == gauss3DN+1)
            ab594_405 = getAberration(finalFit594(:,1:3), finalFit405(:,1:3));
        else
            disp('Error: Red and Blue Dimensionality Mismatch!');
        end
    end
    
    % Far Red and Blue %
    if (aberrationsVec(3) == 1) && (aberrationsVec(4) == 1)
        if (size(finalFit640,2) == gauss2DN+1) && (size(finalFit405,2) == gauss2DN+1)
            ab640_405 = getAberration(finalFit640(:,1:2), finalFit405(:,1:2));
        elseif (size(finalFit640,2) == gauss3DN+1) && (size(finalFit405,2) == gauss3DN+1)
            ab640_405 = getAberration(finalFit640(:,1:3), finalFit405(:,1:3));
        else
            disp('Error: Far Red and Blue Dimensionality Mismatch!');
        end
    end    

    disp('Aberrations Successfully Calculated.');
    disp('****************************************************');
    
    msgbox('COMPLETE: Aberrations Successfully Calculated.');
    
    function [aberration] = getAberration(data1, data2)
        
        if (size(data1, 2) == 2) && (size(data2, 2) == 2)
            
            aberration = zeros(size(data1,1),3);
            aberration(:,1) = data2(:,1) - data1(:,1);
            aberration(:,2) = data2(:,2) - data1(:,2);
            aberration(:,3) = sqrt((data2(:,1)-data1(:,1)).^2 + (data2(:,2)-data1(:,2)).^2);
            
        elseif (size(data1, 2) == 3) && (size(data2, 2) == 3)
            
            aberration = zeros(size(data1,1),4);
            aberration(:,1) = data2(:,1) - data1(:,1);
            aberration(:,2) = data2(:,2) - data1(:,2);
            aberration(:,3) = data2(:,3) - data1(:,3);
            aberration(:,4) = sqrt((data2(:,1)-data1(:,1)).^2 + (data2(:,2)-data1(:,2)).^2 + (data2(:,3)-data1(:,3)).^2);
            
        end
        
    end

end


%% 

function [match1, match2, match3, match4] = multiMatch4(data1, data2, data3, data4)

    sizeTest = [size(data1,1) size(data2,1) size(data3,1) size(data4,1)];
    
    if (sizeTest(1) == sizeTest(2)) && (sizeTest(1) == sizeTest(3)) && (sizeTest(1) == sizeTest(4))
        match1 = data1;
        match2 = data2;
        match3 = data3;
        match4 = data4;
        return;
    else   
    
        maxInd = find(sizeTest == max(sizeTest));
        maxVal = sizeTest(maxInd);

        diff1 = maxVal - size(data1,1);
        diff2 = maxVal - size(data2,1);
        diff3 = maxVal - size(data3,1);
        diff4 = maxVal - size(data4,1);

        na1 = NaN(diff1,1);
        na2 = NaN(diff2,1);
        na3 = NaN(diff3,1);
        na4 = NaN(diff4,1);

        match1 = [data1; na1];
        match2 = [data2; na2];
        match3 = [data3; na3];
        match4 = [data4; na4];
    
    end

end

%% 

function [match1, match2, match3] = multiMatch3(data1, data2, data3)

    sizeTest = [size(data1,1) size(data2,1) size(data3,1)];
    
    if (sizeTest(1) == sizeTest(2)) && (sizeTest(1) == sizeTest(3))
        match1 = data1;
        match2 = data2;
        match3 = data3;
        return;
    else   
        maxInd = find(sizeTest == max(sizeTest));
        maxVal = sizeTest(maxInd);
        
        diff1 = maxVal - size(data1,1);
        diff2 = maxVal - size(data2,1);
        diff3 = maxVal - size(data3,1);
        
        na1 = NaN(diff1,1);
        na2 = NaN(diff2,1);
        na3 = NaN(diff3,1);
        
        match1 = [data1; na1];
        match2 = [data2; na2];
        match3 = [data3; na3];    
    end

end

%% 

function [match1, match2] = multiMatch2(data1, data2)

    sizeTest = [size(data1,1) size(data2,1)];
    
    if sizeTest(1) == sizeTest(2)
        match1 = data1;
        match2 = data2;
        return;
    else
        maxInd = find(sizeTest == max(sizeTest));
        maxVal = sizeTest(maxInd);

        diff1 = maxVal - size(data1,1);
        diff2 = maxVal - size(data2,1);

        na1 = NaN(diff1,1);
        na2 = NaN(diff2,1);

        match1 = [data1; na1];
        match2 = [data2; na2];
    end

end


%%

function importData(~,~)

    global  finalFit488 finalBB488 finalFit594 finalBB594 finalFit640...
            finalBB640 finalFit405 finalBB405 anaParams488...
            anaParams594 anaParams640 anaParams405

    % Choose File to Import %
    [file,path] = uigetfile({'*.xls;*.xlsx'});
    if file == 0
        % User clicked the Cancel button.
        return;
    else
        disp('File Selected:');
        importFile = strcat(path, file);
        disp(importFile);
    end
    disp('Importing Data...');

    [A,B] = xlsfinfo(importFile);

    % Import All Analysis Results

    % Import Green Data %
    if any(strcmp(B, '2D_Green'))
        disp('Importing Green Channel Data...');
        finalFit488 = xlsread(importFile, '2D_Green');
    elseif any(strcmp(B, '3D_Green'))
        disp('Importing Green Channel Data...');
        finalFit488 = xlsread(importFile, '3D_Green');
    end
    if any(strcmp(B, '2D_Green_BB'))
        finalBB488 = xlsread(importFile, '2D_Green_BB');
    elseif any(strcmp(B, '3D_Green_BB'))
        finalBB488 = xlsread(importFile, '3D_Green_BB');
    end

    % Import Red Data %
    if any(strcmp(B, '2D_Red'))
        disp('Importing Red Channel Data...');
        finalFit594 = xlsread(importFile, '2D_Red');
    elseif any(strcmp(B, '3D_Red'))
        disp('Importing Red Channel Data...');
        finalFit594 = xlsread(importFile, '3D_Red');
    end
    if any(strcmp(B, '2D_Red_BB'))
        finalBB594 = xlsread(importFile, '2D_Red_BB');
    elseif any(strcmp(B, '3D_Red_BB'))
        finalBB594 = xlsread(importFile, '3D_Red_BB');
    end

    % Import Far Red Data %
    if any(strcmp(B, '2D_FarRed'))
        disp('Importing Far Red Channel Data...');
        finalFit640 = xlsread(importFile, '2D_FarRed');
    elseif any(strcmp(B, '3D_FarRed'))
        disp('Importing Far Red Channel Data...');
        finalFit640 = xlsread(importFile, '3D_FarRed');
    end
    if any(strcmp(B, '2D_FarRed_BB'))
        finalBB640 = xlsread(importFile, '2D_FarRed_BB');
    elseif any(strcmp(B, '3D_FarRed_BB'))
        finalBB640 = xlsread(importFile, '3D_FarRed_BB');
    end

    % Import Blue Data %
    if any(strcmp(B, '2D_Blue'))
        disp('Importing Blue Channel Data...');
        finalFit405 = xlsread(importFile, '2D_Blue');
    elseif any(strcmp(B, '3D_Blue'))
        disp('Importing Blue Channel Data...');
        finalFit405 = xlsread(importFile, '3D_Blue');
    end
    if any(strcmp(B, '2D_Blue_BB'))
        finalBB405 = xlsread(importFile, '2D_Blue_BB');
    elseif any(strcmp(B, '3D_Blue_BB'))
        finalBB405 = xlsread(importFile, '3D_Blue_BB');
    end

    % Import Analysis Parameters %
    if any(strcmp(B, 'AnalysisParameters'))
        disp('Importing Analysis Parameters...');
        analysisParams = xlsread(importFile, 'AnalysisParameters');
    end
    paramTest = [~isempty(finalFit488) ~isempty(finalFit594) ~isempty(finalFit640) ~isempty(finalFit405)];

    if sum(paramTest) == 4
        anaParams488 = analysisParams(:,1);
        anaParams594 = analysisParams(:,2);
        anaParams640 = analysisParams(:,3);
        anaParams405 = analysisParams(:,4);
    elseif sum(paramTest) == 3
        if (paramTest(1) == 1) && (paramTest(2) == 1) && (paramTest(3) == 1)
            anaParams488 = analysisParams(:,1);
            anaParams594 = analysisParams(:,2);
            anaParams640 = analysisParams(:,3);
        elseif (paramTest(1) == 1) && (paramTest(2) == 1) && (paramTest(4) == 1)
            anaParams488 = analysisParams(:,1);
            anaParams594 = analysisParams(:,2);
            anaParams405 = analysisParams(:,3);
        elseif (paramTest(1) == 1) && (paramTest(3) == 1) && (paramTest(4) == 1)
            anaParams488 = analysisParams(:,1);
            anaParams640 = analysisParams(:,2);
            anaParams405 = analysisParams(:,3);
        elseif (paramTest(2) == 1) && (paramTest(3) == 1) && (paramTest(4) == 1)
            anaParams594 = analysisParams(:,1);
            anaParams640 = analysisParams(:,2);
            anaParams405 = analysisParams(:,3);
        end
    elseif sum(paramTest) == 2
        if (paramTest(1) == 1) && (paramTest(2) == 1)
            anaParams488 = analysisParams(:,1);
            anaParams594 = analysisParams(:,2);
        elseif (paramTest(1) == 1) && (paramTest(3) == 1)
            anaParams488 = analysisParams(:,1);
            anaParams640 = analysisParams(:,2);
        elseif (paramTest(1) == 1) && (paramTest(4) == 1)
            anaParams488 = analysisParams(:,1);
            anaParams405 = analysisParams(:,2);
        elseif (paramTest(2) == 1) && (paramTest(3) == 1)
            anaParams594 = analysisParams(:,1);
            anaParams640 = analysisParams(:,2);
        elseif (paramTest(2) == 1) && (paramTest(4) == 1)
            anaParams594 = analysisParams(:,1);
            anaParams405 = analysisParams(:,2);
        elseif (paramTest(3) == 1) && (paramTest(4) == 1)
            anaParams640 = analysisParams(:,1);
            anaParams405 = analysisParams(:,2);
        end
    elseif sum(paramTest) == 1
        if (paramTest(1) == 1)
            anaParams488 = analysisParams(:,1);
        elseif (paramTest(2) == 1)
            anaParams594 = analysisParams(:,1);
        elseif (paramTest(3) == 1)
            anaParams640 = analysisParams(:,1);
        elseif (paramTest(4) == 1)
            anaParams405 = analysisParams(:,1);
        end
    end

    disp('COMPLETE: Import Process Finished.');
    disp('..................................................');
    
end



function resetResultsButton()

    global mainFig viewFigSize
    
    uicontrol('Parent', mainFig, 'Style', 'pushbutton', 'Position', [viewFigSize(1)*0.899, viewFigSize(2)*0.46, 60, 15],...
            'String', 'RESET', 'FontSize', 7, 'BackgroundColor',[1,0.75,0.75], 'Callback', {@resetResults});
    
    function resetResults(~,~)
        
        global finalFit488 finalFit594 finalFit640 finalFit405...
            finalBB488 finalBB594 finalBB640 finalBB405 ...
            finalCentroids488 finalCentroids594 finalCentroids640...
            finalCentroids405 oFit488 oBB488 oCen488 oFit594 oBB594 oCen594...
            oFit640 oBB640 oCen640 oFit405 oBB405 oCen405
        
        finalFit488 = oFit488;
        finalBB488 = oBB488;
        finalCentroids488 = oCen488;
        
        finalFit594 = oFit594;
        finalBB594 = oBB594;
        finalCentroids594 = oCen594;
        
        finalFit640 = oFit640;
        finalBB640 = oBB640;
        finalCentroids640 = oCen640;
        
        finalFit405 = oFit405;
        finalBB405 = oBB405;
        finalCentroids405 = oCen405;
        
    end

end


function extractAll3DGaussTransfer()

    global boxLimits fromCentroids finalFitParams mainFig zoomObj...
            currentIMG currentChannel zSlice fromBB fromFit xyRes...
            nPlanes viewFigSize gaussFitted currentChN finalFit488...
            currentPts msgbx saveCheck finalFit594 finalFit640...
            finalFit405 transferBuffer gauss3DN

    boxLimits = zeros(size(fromCentroids,1),6);

    finalFitParams = zeros(size(fromCentroids,1), gauss3DN);

    mainFig;
    warning off;
    zoomObj = get(gca, {'xlim','ylim'});
    clearParticleN(mainFig);
    currentIMG = imshow(currentChannel(:,:,zSlice), [], 'InitialMagnification', 450);
    xlabel('Double Click To Add Or Remove', 'FontSize', 10)
    set(gca, {'xlim','ylim'}, zoomObj);
    hold on;

    disp('.');
    disp('Fitting 3D Gaussian for Detected Particles:');
    tic
    for i = 1:size(fromCentroids,1)

        pN = i;
        particleBB = currentChannel(fromBB(i,3)+0.5:fromBB(i,4)-0.5,fromBB(i,1)+0.5:fromBB(i,2)-0.5,fromBB(i,5)+0.5:fromBB(i,6)-0.5);
        boxPts = [fromBB(i,1)+0.5, fromBB(i,2)-0.5; fromBB(i,3)+0.5, fromBB(i,4)-0.5; fromBB(i,5)+0.5,fromBB(i,6)-0.5];
        boxPlot = [fromBB(i,1), fromBB(i,3); fromBB(i,1), fromBB(i,4); fromBB(i,2), fromBB(i,4); fromBB(i,2), fromBB(i,3); fromBB(i,1), fromBB(i,3)];

        %         if (bgOpt == 0)
        %             [particleBB, boxPts, boxPlot] = extractBoundBox(pN, currentChannel);
        %         elseif (bgOpt == 1)
        %             [particleBB, boxPts, boxPlot, percBG] = extractBoundBoxBG(pN, currentChannel);
        %         end
        boxLimits(i,1) = boxPts(1,1)-0.5;
        boxLimits(i,2) = boxPts(1,2)+0.5;
        boxLimits(i,3) = boxPts(2,1)-0.5;
        boxLimits(i,4) = boxPts(2,2)+0.5;
        boxLimits(i,5) = boxPts(3,1)-0.5;
        boxLimits(i,6) = boxPts(3,2)+0.5;

        [bbCoords] = extractBBCoords(particleBB);

        try

            [fitParams] = fit3DGauss(particleBB, bbCoords, boxPts);

        catch
            fitParams = zeros(1,gauss3DN);
            fitParams(1,1) = fromFit(i,1);
            fitParams(1,2) = fromFit(i,2);
            fitParams(1,3) = fromFit(i,3);
            fitParams(1,15) = sum(sum(sum(particleBB)));
            fitParams(1,16) = max(max(max(particleBB)));
        end

        finalFitParams(i,:) = fitParams;

        if mod(i,2) == 0
            disp(strcat(strcat('Current Progress: ', num2str(round(100*(i/size(fromCentroids,1)), 1, 'decimals'))), '%'));
        end

        if (zSlice >= boxPts(3,1)) && (zSlice <= boxPts(3,2))
            % For Visualization %
            plot(boxPlot(:,1), boxPlot(:,2), '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 0.6 1], 'LineWidth', 1.0, 'Clipping', 'on');
            % Numbering Particles
            text(fromCentroids(i,1)+2.5, fromCentroids(i,2)+2, num2str(i), 'Fontsize', 8, 'Color', 'r', 'fontweight', 'bold', 'Clipping', 'on');
            plot(toPixelScale(fromFit(i,1),xyRes), toPixelScale(fromFit(i,2),xyRes), '-s', 'MarkerSize', 5, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', [0.6 1 0.6], 'Clipping', 'on');
        end

        if i == size(fromCentroids,1)
            disp('.');
            disp('3D Gaussian Fitting Completed Successfully.');
            disp('*********************************************************************');
        end

    end
    toc
    zoomObj = get(gca, {'xlim','ylim'});
    currentPts = finalFitParams;

    if nPlanes > 1
        try
            delete(h4);
            delete(anno4);
        end
        h4 = uicontrol('Parent', mainFig,'Style','slider','Position',[viewFigSize(1)*0.775, viewFigSize(2)*0.11,20,600],...
            'SliderStep', [1/(nPlanes-1) , 10/(nPlanes-1) ],...
            'value',zSlice, 'min', 1, 'max',nPlanes, 'Callback', {@updateVisualFigure2});
        anno4 = annotation('textbox', [0.77, 0.875, 0.025, 0.025], 'string', num2str(zSlice),'FontSize',7.5);
    end

    gaussFitted = true;

    if currentChN == 1
        finalFit488 = currentPts;
        msgbx = msgbox('Green Channel 3D Fit Results Stored.');
        saveCheck = 1;
    elseif currentChN == 2
        finalFit594 = currentPts;
        msgbx = msgbox('Red Channel 3D Fit Results Stored.');
        saveCheck = 1;
    elseif currentChN == 3
        finalFit640 = currentPts;
        msgbx = msgbox('Far Red Channel 3D Fit Results Stored.');
        saveCheck = 1;
    elseif currentChN == 4
        finalFit405 = currentPts;
        msgbx = msgbox('Blue Channel 3D Fit Results Stored.');
        saveCheck = 1;
    end

end