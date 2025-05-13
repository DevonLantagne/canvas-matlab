%% Fresh Start

clc;clear;close all;

env = read_env(".env");

canv = Canvas(env.BASE_URL, env.API_KEY, env.COURSE_ID, debug=true)

fprintf("Canvas API connected!\n")

%% Get Students
fprintf("\nGetting Students...\n\n")

students = canv.getStudents(GetAvatar=true);

% Display some basic info
for i = 1:length(students)
    fprintf('Name: %s  |  MSOEID: %s  |  Section: %s\n', ...
        students(i).short_name, ...
        students(i).sis_user_id,...
        students(i).section);
end

%% Get Assignment Groups

fprintf("\nGetting Assignment Groups...\n\n")

asmt_grps = canv.getAssignmentGroups();

% Display some basic info
for i = 1:length(asmt_grps)
    fprintf('Group: [%d] %s, Weight: %f\n', ...
        asmt_grps(i).id,...
        asmt_grps(i).name, ...
        asmt_grps(i).group_weight);
end

%% Get Assignments
fprintf("\nGetting Assignments...\n\n")
asmts = canv.getAssignments();

% Display some basic info
for i = 1:length(asmts)
    fprintf('[%d] %s\n', ...
        asmts(i).id, ...
        asmts(i).name);
end

%% Get a specific assignment submissions
ThisAsmtID = asmts(1).id;
ThisAsmtID = 257963;
fprintf("\nGetting Specific Assignment [%d]...\n\n", ThisAsmtID)
ThisAsmt = canv.getAssignment(ThisAsmtID);
subs = canv.getSubmissions(ThisAsmtID);
% Download Submissions (windows user downloads folder)
downloadsPath = fullfile(getenv('USERPROFILE'), 'Downloads', "CanvasTest");
canv.downloadSubmissions(ThisAsmtID, downloadsPath, Sections=["002","003"]);

