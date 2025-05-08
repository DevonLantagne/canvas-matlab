%% Fresh Start

clc;clear;close all;

env = read_env(".env");

canv = Canvas(env.BASE_URL, env.API_KEY, env.COURSE_ID);

fprintf("Canvas API connected!\n\n")

%% Get Assignments
fprintf("Getting Assignments...\n\n")
asmts = canv.getAssignments;

% Display some basic info
for i = 1:length(asmts)
    fprintf('[%d] %s\n', ...
        asmts(i).id, ...
        asmts(i).name);
end

%% Get Students
fprintf("Getting Students...\n\n")

students = canv.getStudents(GetAvatar=true);