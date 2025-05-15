%% Fresh Start
% This script tests POST/PUT requests

clc;clear;close all;

env = read_env(".env");

canv = Canvas(env.BASE_URL, env.API_KEY, env.COURSE_ID, debug=true)

fprintf("Canvas API connected!\n")

%% File Upload Test
% Uploads the testFile.txt to Canvas, waits for user input (to check
% Canvas), and then deletes the file
testFileName = "testFile.txt";

fprintf("--- Starting Upload/Delete File Test ---\n")

fileInfo = dir(testFileName);
if isempty(fileInfo); error("File not found."); end
testFile = fullfile(fileInfo.folder, fileInfo.name);

endpoint = "files"; % generic file upload for the course
fprintf("Uploading File...\n")
file = canv.uploadFile(endpoint, testFile);
fprintf("File uploaded. Check Canvas.\n")

input("Press ENTER to continue");

fprintf("Deleting File...\n")
[~,status] = canv.deleteFile(file.id);
fprintf("File deleted. Check Canvas.\n")


%% Test Create Module
% This test creates a module, waits for user input (to check Canvas), and
% then deletes the module. The unlock time will be 1 hour from time of
% execution.
fprintf("--- Starting Creation/Delete Module Test ---\n")

fprintf("Creating module...\n")
NewModule = canv.createModule("Test Module 01", "UnlockAt", datetime()+hours(1));
fprintf("Module created. Check Canvas.\n")

input("Press ENTER to continue");

DeletedModule = canv.deleteModule(NewModule.id);
fprintf("Module deleted. Check Canvas.\n")





