%% Fresh Start

clc;clear;close all;

env = read_env(".env");

canv = Canvas(env.BASE_URL, env.API_KEY, env.COURSE_ID, debug=true)

fprintf("Canvas API connected!\n")

%% Get Students
if true
    fprintf("\n--- Getting Students ---\n")
    students = canv.getStudents(GetAvatar=true);

    % Display some basic info
    if isempty(students)
        fprintf("No students found.\n")
    else
        for i = 1:length(students)
            fprintf('[%d]  Name: %s  |  SchoolID: %s  |  Section: %s\n', ...
                students(i).id, ...
                students(i).short_name, ...
                students(i).sis_user_id,...
                students(i).section);
        end
    end
end

%% Get Assignment Groups
if true
    fprintf("\n--- Getting Assignment Groups ---\n")
    asmt_grps = canv.getAssignmentGroups();

    % Display some basic info
    for i = 1:length(asmt_grps)
        fprintf('[%d] %s, Weight: %f\n', ...
            asmt_grps(i).id,...
            asmt_grps(i).name, ...
            asmt_grps(i).group_weight);
    end
end

%% Get Assignments
if true
    fprintf("\n--- Getting Assignments ---\n")
    asmts = canv.getAssignments();

    % Display some basic info
    for i = 1:length(asmts)
        fprintf('[%d] Pts: %d  Group: %d  %s\n', ...
            asmts(i).id, ...
            asmts(i).points_possible, ...
            asmts(i).assignment_group_id, ...
            asmts(i).name);
    end
end

%% Download a specific assignment's submissions
if false
    ThisAsmtID = asmts(1).id;
    ThisAsmtID = 257963;
    fprintf("\nGetting Specific Assignment [%d]...\n\n", ThisAsmtID)
    ThisAsmt = canv.getAssignment(ThisAsmtID);
    subs = canv.getSubmissions(ThisAsmtID);
    % Download Submissions (windows user downloads folder)
    downloadsPath = fullfile(getenv('USERPROFILE'), 'Downloads', "CanvasTest");
    canv.downloadSubmissions(ThisAsmtID, downloadsPath, Sections=["002","003"]);
end

%% Get Folders in the course
if true
    fprintf("\n--- Getting Folders ---\n")
    courseFolders = canv.getFolders();

    % Display
    for i = 1:length(courseFolders)
        fprintf("[%d] ""%s""  (%d files, %d folders)\n",...
            courseFolders(i).id,...
            courseFolders(i).full_name, ...
            courseFolders(i).files_count,...
            courseFolders(i).folders_count)
    end
end

%% Get Files in the course
if true
    fprintf("\n--- Getting Files ---\n")
    courseFiles = canv.getFiles();

    % Display
    for i = 1:length(courseFiles)
        fprintf("[%d] %s\n",...
            courseFiles(i).id,...
            courseFiles(i).display_name)
    end
end

%% Get Modules
if true
    fprintf("\n--- Getting Modules ---\n")
    modules = canv.getModules();
    
    % Display
    for i = 1:length(modules)
        fprintf("[%d] %s  (%d items)\n",...
            modules(i).id,...
            modules(i).name,...
            modules(i).items_count)
    end
end