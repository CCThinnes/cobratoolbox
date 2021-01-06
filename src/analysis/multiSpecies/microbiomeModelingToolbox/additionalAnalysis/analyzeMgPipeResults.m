function analyzeMgPipeResults(infoFilePath,resPath,statPath,sampleGroupHeaders)
% This function takes simulation results generated by mgPipe as the input
% and determines which computed fluxes and reaction abundances are
% significantly different between groups. Requires a file with sample
% information (e.g., disease group, age) for the microbiome models that 
% were generated and interrogated through mgPipe.
%
% USAGE:
%
%    analyzeMgPipeResults(infoFilePath,resPath,statPath,sampleGroupHeaders)
%
% INPUTS:
% infoFilePath:         Path to text file or spreadsheet with information 
%                       on analyzed samples including group classification
%                       with sample IDs as rows
% resPath:              char with path of directory where simulation 
%                       results are saved
% statPath:             char with path of directory where results of
%                       statistical analysis are saved
% sampleGroupHeaders    list of one or more column headers in file with the
%                       sample information that should be analyzed 
%                       (e.g., disease status, age)
%
% .. Author: Almut Heinken, 12/2020

% Read in the file with sample information

infoFile = readtable(infoFilePath, 'ReadVariableNames', false);
infoFile = table2cell(infoFile);

% get all spreadsheet files in results folder
dInfo = dir(resPath);
fileList={dInfo.name};
fileList=fileList';
delInd=find(~(contains(fileList(:,1),{'csv','.txt'})));
fileList(delInd,:)=[];

% analyze data in spreadsheets
for i=1:length(fileList)
    sampleData = readtable([resPath filesep fileList{i}], 'ReadVariableNames', false);
    sampleData = table2cell(sampleData);
    
    % merge columns for shadow price results
    if strcmp(sampleData{1,2},'Source')
        for j=2:size(sampleData,1)
            sampleData{j,1}=[sampleData{j,1} '_' sampleData{j,2}];
        end
        sampleData(:,2)=[];
    end
    if strcmp(sampleData{1,3},'Source')
        for j=2:size(sampleData,1)
            sampleData{j,2}=[sampleData{j,2} '_' sampleData{j,3}];
        end
        sampleData(:,2:3)=[];
    end
    if strcmp(sampleData{1,1},'Objective') || strcmp(sampleData{1,2},'Objective')
        for j=2:size(sampleData,1)
            sampleData{j,1}=[sampleData{j,1} '_' sampleData{j,2}];
        end
        sampleData(:,2)=[];
    end
    
    sampleData(1,2:end)=strrep(sampleData(1,2:end),'microbiota_model_samp_','');
    
    % remove entries not in data
    [C,IA]=intersect(infoFile,sampleData(1,2:end));
    if length(C)<length(sampleData(1,2:end))
        error('Some sample IDs are not found in the file with sample information!')
    end
    
    for j=1:length(sampleGroupHeaders)
        [Statistics,significantFeatures] = performStatisticalAnalysis(sampleData',infoFile,sampleGroupHeaders{j});
        
        % Print the results as a text file
        filename = strrep(fileList{i},'.csv','');
        filename = strrep(filename,'.txt','');
        writetable(cell2table(Statistics),[statPath filesep filename '_' sampleGroupHeaders{j} '_Statistics'],'FileType','text','WriteVariableNames',false,'Delimiter','tab');
        if size(significantFeatures,2)>1
            writetable(cell2table(significantFeatures),[statPath filesep filename '_' sampleGroupHeaders{j} '_SignificantFeatures'],'FileType','text','WriteVariableNames',false,'Delimiter','tab');
        end
    end
end

end