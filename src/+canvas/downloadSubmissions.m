function downloadSubmissions(obj, assignmentID, downloadsPath, opts)
%downloadSubmissions Downloads all student submissions for an assignment
%   A folder will be created from the downloadsPath. Inside,
%   each student will have their own folder with all
%   submissions. Attempts will be indicated on filenames.
%   If files already exist, they will not be downloaded.
%   Comment files will always be overwritten.
%   Can also specify sections to filter.

arguments
    obj (1,1) Canvas
    assignmentID (1,1) double
    downloadsPath (1,1) string
    opts.Sections (1,:) string = []
end

% Make directory if it does not exist
if ~isfolder(downloadsPath); mkdir(downloadsPath);end

% Get the submissions for the assignment
[subs, status] = obj.getSubmissions(assignmentID);
if isempty(subs)
    error("Cound not get submissions: (%d) %s", ...
        status.StatusCode, status.ReasonPhrase)
end

% Get list of all students
[students, status] = obj.getStudents();
if isempty(students)
    error("Cound not get students: (%d) %s", ...
        status.StatusCode, status.ReasonPhrase)
end

% Filter students by section if not empty
if ~isempty(opts.Sections)
    KeepItem = matches(vertcat(students.section), opts.Sections);
    students(~KeepItem) = []; % remove
end

% For each student, find all their submissions and download
for st = 1:length(students)
    % Get student metadata
    ThisStudentID = students(st).id;
    ThisStudentName = students(st).name;

    obj.printdb(sprintf("Checking submissions for %s (%d/%d)", ...
        ThisStudentName, st, length(students)))

    % Make student folder if not exist
    StudentFolder = fullfile(downloadsPath, ThisStudentName);
    if ~isfolder(StudentFolder); mkdir(StudentFolder);end

    % Get submission for this student
    % The include[]=submission_history argument guarantees only
    % one "submission" row in the subs structure. Multiple
    % submissions are contained within that row object.
    ThisSub = subs(vertcat(subs.user_id) == ThisStudentID);

    % Write submission comments (can happen without actual
    % submission)
    if ~isempty(ThisSub.submission_comments)
        % make text file and enter comments:
        obj.printdb("Generating comments.txt")
        fid = fopen(fullfile(StudentFolder, 'comments.txt'), 'w');
        for cmt = 1:length(ThisSub.submission_comments)
            ThisCmt = ThisSub.submission_comments(cmt);
            fprintf(fid, "Attempt %d: %s: %s\n", ...
                ThisCmt.attempt,...
                ThisCmt.author_name,...
                ThisCmt.comment);
        end
        fclose(fid);
    end

    % Guard if an actual submission was made
    if isempty(ThisSub) || isempty(ThisSub.submission_type)
        obj.printdb("No submission found, generating empty.txt")
        fid = fopen(fullfile(StudentFolder, 'empty.txt'), 'w');
        fclose(fid);
        continue
    end

    % Download Attachments
    if ~isempty(ThisSub.submission_history)
        % For every submission (attempt)
        for attempt = 1:length(ThisSub.submission_history)
            ThisAttempt = ThisSub.submission_history(attempt);

            % Check due dates
            submitDate = datetime(ThisAttempt.submitted_at, ...
                'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss''Z''', ...
                'TimeZone', 'UTC');
            dueDate = datetime(ThisAttempt.cached_due_date, ...
                'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss''Z''', ...
                'TimeZone', 'UTC');
            lateness = submitDate - dueDate;
            if lateness > seconds(0)
                obj.printdb(sprintf("Attempt %d: generating LATE.txt", ThisAttempt.attempt))
                LateString = sprintf("attempt %d LATE %.0f hours.txt", ...
                    ThisAttempt.attempt, hours(lateness));
                fid = fopen(fullfile(StudentFolder, LateString), 'w');
                fclose(fid);
            end

            % For all attachments in this attempt
            for a = 1:length(ThisAttempt.attachments)
                ThisAttachment = ThisAttempt.attachments(a);
                filename = sprintf('attempt%d_%s', ThisAttempt.attempt, ThisAttachment.display_name);
                filepath = fullfile(StudentFolder, filename);
                % Check if file already exists (skip if true)
                if isfile(filepath)
                    obj.printdb(sprintf("Already Exists (skipping): %s", ThisAttachment.display_name))
                    continue
                end
                % Download
                try
                    obj.printdb(sprintf("Downloading %s", ThisAttachment.display_name))
                    websave(filepath, ThisAttachment.url);
                catch e
                    warning('Failed to download: %s\nError: %s', a.url, e.message);
                end
            end
        end
    end
end
end
