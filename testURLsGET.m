%% Fresh Start

clc;clear;close all;

env = read_env(".env");

canv = Canvas(env.BASE_URL, env.API_KEY, env.COURSE_ID);

fprintf("Canvas API connected!\n")

%% Get Assignments
fprintf("\nGetting Assignments...\n\n")
asmts = canv.getAssignments;

% Display some basic info
for i = 1:length(asmts)
    fprintf('[%d] %s\n', ...
        asmts(i).id, ...
        asmts(i).name);
end

%% Get Students
fprintf("\nGetting Students...\n\n")

students = canv.getStudents(GetAvatar=true);

% Display some basic info
for i = 1:length(students)
    fprintf('Name: %s  |  MSOEID: %s  |  Section: %s\n', ...
        students(i).short_name, ...
        students(i).section, ...
        students(i).sis_user_id);
end