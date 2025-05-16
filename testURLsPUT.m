%% Fresh Start
% This script tests POST/PUT requests

clc;clear;close all;

env = read_env(".env");

canv = Canvas(env.BASE_URL, env.API_KEY, env.COURSE_ID, debug=true)

fprintf("Canvas API connected!\n")

%% File Upload Test
% Uploads the testFile.txt to Canvas. If the file already exists, it is
% overwritten.

fprintf("--- Starting Upload File Test ---\n\n")

fileInfo = dir("testFile.txt");
if isempty(fileInfo); error("File not found."); end
testFile = fullfile(fileInfo.folder, fileInfo.name);

fprintf("Uploading File...\n")
file = canv.uploadFile("files", testFile);
if isempty(file)
    fprintf("UNABLE TO UPLOAD FILE\n")
else
    fprintf("File uploaded. Check Canvas.\n")
end

%% File Delete Test
% Deletes the testFile.txt that was uploaded with the upload test.

fprintf("--- Starting Delete File Test ---\n\n")

fprintf("Searching for testFile.txt on Canvas...\n")
file = canv.getFiles(Search="testFile.txt");
if isempty(file)
    fprintf("File not found.\n")
else
    fprintf("File found.\nDeleting File...\n")
    [~,status] = canv.deleteFile(file.id);
    fprintf("File deleted.\n")
end

%% Test Create Module
% This test creates a module and items. The unlock time will be 1 hour from
% time of execution.
%
% Use the Delete Module test to remove all created assets

fprintf("--- Starting Create Module and Module Item Test ---\n\n")

fprintf("Creating module...\n")
NewModule = canv.createModule("Test Module 01", "UnlockAt", datetime()+hours(1));
fprintf("Module created. Check Canvas.\n")

fprintf("Creating module item (subheader)...\n")
NewModuleItem = canv.createModuleItem(NewModule.id, "SubHeader", ...
    Title="Test Subheader", Publish=true);
fprintf("Module item created. Check Canvas.\n")

%% Test Delete Module
% This test delets a module and items from the Create Module test. 

fprintf("--- Starting Delete Module Test ---\n\n")

% Search for created module
createdMod = canv.getModules(Search="Test Module 01");
if isempty(createdMod)
    fprintf("Module not found.\n")
else
    fprintf("Module found.\nDeleting module...\n")
    DeletedModule = canv.deleteModule(NewModule.id);
    fprintf("Module deleted.\n")
end





