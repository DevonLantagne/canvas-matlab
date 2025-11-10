classdef Canvas
    %CANVAS Interface to the Canvas LMS REST API
    %   This class allows you to interact with the Canvas Learning Management System
    %   using the public REST API. You can retrieve data such as students, assignments,
    %   and post grades using authenticated HTTP requests.
    %
    %   Structures returned by Canvas methods mirror those described in the
    %   <a href="matlab: web('https://developerdocs.instructure.com/services/canvas/file.all_resources')">Canvas LMS API documentation</a>
    %
    %   api = Canvas(baseURL, token, courseID) creates a new Canvas API object.
    %
    %   Inputs:
    %       baseURL  - [string] Base URL of the Canvas instance (e.g.,
    %                  "https://yourinstitution.instructure.com/api/v1").
    %       token    - [string] Canvas API access token.
    %                  You can generate this token from your Canvas user
    %                  settings.
    %       courseID - [string] Canvas course ID.
    %
    %   Optional Inputs (name,value pairs):
    %       debug    - [default = false] Logical flag to enable verbose debug printing
    %
    %   Output:
    %       A Canvas object connected to the specified course.

    properties (Access = public)
        %COURSENAME Name of the course from Canvas
        %   COURSENAME is automatically populated on object construction by
        %   using the name provided by Canvas. You can overwrite this name
        %   after construction.
        courseName

        %COURSECODE Canvas course code of the course
        %   COURSECODE is the university-specified course name/code that
        %   you might find in your course catalog. This is automatically
        %   populated on object construction but can be overwritten after
        %   construction.
        courseCode

        %DEBUG Enable verbose debug printing
        %   If true, API requests and rate limit details are printed to the console.
        %   Default is FALSE.
        debug (1,1) logical = false

        %PERPAGE Sets the number of items per API call before paging
        %   The Canvas API utilizes paging for large lists of data which
        %   requires API calls for each page. PERPAGE sets the number of
        %   items returned per page. Setting to 100 would return 100 items
        %   (i.e., assignments or students) before another API call would
        %   occur. The Canvas.m class will combine all pages together for
        %   one output; you do not have to call the methods multiple times.
        %
        %   Must be a value between 10 and 100 (default is 100).
        perPage (1,1) uint8 {mustBeNumeric, mustBeInRange(perPage,10,100)} = 100
    end

    properties (SetAccess = private)
        %BASEURL The base URL for the Canvas API
        baseURL (1,1) string

        %COURSEID The Canvas course identifier
        %   COURSEID is the course ID from Canvas. You can find this on
        %   Canvas by reading your URL when visiting the course. You will
        %   find this course ID after the /course/ in the URL.
        courseID (1,1) string
    end

    properties (Dependent)

    end

    properties (Access = private, Hidden)
        %TOKEN Bearer token used for authentication
        token (1,1) string
        authHeader
    end

    properties (Constant, Hidden)
        jsonHeader = matlab.net.http.HeaderField(...
            'Accept', 'application/json')
        formHeader = matlab.net.http.field.ContentTypeField(...
            'application/x-www-form-urlencoded')
    end


    %% Constructor
    methods
        function obj = Canvas(baseURL, token, courseID, opts)
            %CANVAS Construct a Canvas API interface object
            %   obj = Canvas(baseURL, token, courseID) initializes a connection to
            %   a Canvas course using the provided API token and course ID.
            %
            %   Optional:
            %       debug - [logical, default=false] enable verbose
            %               printing of requests.

            arguments
                baseURL (1,1) string
                token (1,1) string
                courseID (1,1) string
                opts.debug (1,1) logical = false
            end

            obj.token = token;
            obj.baseURL = baseURL;
            obj.courseID = courseID;

            obj.debug = opts.debug;

            obj.authHeader = matlab.net.http.HeaderField(...
                'Authorization', ['Bearer ' char(obj.token)]);

            url = buildURL(obj); % Build default course URL

            request = matlab.net.http.RequestMessage('GET', ...
                [obj.authHeader, obj.jsonHeader]);

            try
                response = request.send(url);
                if response.StatusCode == matlab.net.http.StatusCode.Unauthorized
                    error("CanvasAPI:ConnectionFailedAuth", ...
                        "Connection failed: %s\nCheck your API token and expiration.", response.StatusLine);
                end
                if response.StatusCode ~= matlab.net.http.StatusCode.OK
                    error("CanvasAPI:ConnectionFailed", ...
                        "Connection failed: %s", response.StatusLine);
                end
            catch ME
                error("CanvasAPI:ConnectionTestError", ...
                    "Could not connect to Canvas API: %s", ME.message);
            end

            % We have connection. Pull in some other info
            obj.courseCode = string(response.Body.Data.course_code);
            obj.courseName = string(response.Body.Data.name);

        end
    end

    %% GET Methods
    methods
        function out = get.perPage(obj)
            % @ignore
            out = num2str(obj.perPage);
        end
    end

    %% HTTP Methods
    methods (Access = public)
        % Course
        function [course, status, resp] = getCourse(obj)
            %getCourse Returns a Canvas course structure containing information about the course.
            %   Description:
            %       Returns a course structure from the Canvas API.
            %
            %   Syntax:
            %       [course, status, resp] = getCourse(api)
            %
            %   Inputs:
            %       obj - the Canvas API object.
            %
            %   Outputs:
            %       course -  struct of course information.
            %       status -  HTTP status code of the API call.
            %       resp -  full HTTP response from the API.
            %
            %   Examples:
            %
            %       Get the course structure:
            %       courseInfo = api.getCourse;
            %
            %       Get the course structure and HTTP response code:
            %       [courseInfo, status] = api.getCourse;
            %
            %       Only get the raw HTTP response:
            %       [~,~,resp] = api.getCourse;

            url = buildURL(obj);
            [course, status, resp] = getPayload(obj, url);
            course = Chars2StringsRec(course);
        end
        function [object, status, resp] = smartSearch(obj, search, filter)
            arguments
                obj (1,1) Canvas
                search (1,1) string
                filter (1,:) string {mustBeMember(filter, ["pages", "assignments", "announcements", "discussion_topics"])}
            end

            opts.search = search;
            opts.filter = filter;

            endpoint = "smartsearch";

            argSet = buildArgSet( ...
                "search",   "q",        "string", ...
                "filter",   "filter[]", "string");

            queries = buildBody("get", opts, argSet);

            url = buildURL(obj, endpoint);

            [object, status, resp] = getPayload(obj, url, queries);
        end

        % Students
        function [students, status, resp] = getStudents(obj, qopts, opts)
            %GETSTUDENTS Retrieve all active students enrolled in the course
            %   students = getStudents(obj) fetches active enrolled students in the current course.
            %
            %   Optional name-value pairs:
            %       GetAvatar - if true, includes avatar URLs in the response

            arguments
                obj (1,1) Canvas

                qopts.Search string = []
                qopts.Sort (1,1) string {mustBeMember(qopts.Sort, ...
                    ["username", "last_login", "email", "sis_id"])} = "username"
                qopts.EnrollmentType string {mustBeMember(qopts.EnrollmentType, ...
                    ["teacher", "student", "student_view", "ta", "observer", "designer"])} = "student"
                qopts.UserIDs (1,:) string = []
                qopts.EnrollmentState (1,:) string {mustBeMember(qopts.EnrollmentState, ...
                    ["active", "invited", "rejected", "completed", "inactive"])} = "active"
                
                opts.GetAvatar (1,1) logical = false
                opts.GetBio (1,1) logical = false
                opts.GetTestStudent (1,1) logical = false
            end

            endpoint = "search_users";
            url = obj.buildURL(endpoint);

            ExtraQueryArgs = {...
                'per_page',     obj.perPage, ...
                'include[]',    'enrollments'};

            if opts.GetAvatar
                ExtraQueryArgs = [ExtraQueryArgs, {'include[]', 'avatar_url'}];
            end
            if opts.GetBio
                ExtraQueryArgs = [ExtraQueryArgs, {'include[]', 'bio'}];
            end
            if opts.GetTestStudent
                ExtraQueryArgs = [ExtraQueryArgs, {'include[]', 'test_student'}];
            end

            argSet = buildArgSet( ...
                "Search",           "search_term",          "string", ...
                "Sort",             "sort",                 "string", ...
                "EnrollmentType",   "enrollment_type[]",    "string", ...
                "UserIDs",          "user_ids[]",           "integer", ...
                "EnrollmentState",  "enrollment_state[]",   "string");

            queries = buildBody("get", qopts, argSet, LastArgs=ExtraQueryArgs);

            [students, status, resp] = getPayload(obj, url, queries);

            % Modify data output by relocating enrollment section (if it is
            % in the response)
            if isfield(students, "enrollments")
                for n = 1:length(students)
                    enroleCode = students(n).enrollments.sis_section_id;
                    students(n).section = extractAfter(enroleCode, '-');
                end
            end

            students = Chars2StringsRec(students);
        end

        % Assignments and Weighting
        function [asmt_grps, status, resp] = getAssignmentGroups(obj)
            %getAssignmentGroups Retrieve all assignments groups in the current Canvas course
            %   asmt_grps = getAssignmentGroups(obj) returns a struct array
            %   of assignment groups available in the configured course.
            %   Also returns the assignments within those groups.

            endpoint = "assignment_groups";
            url = buildURL(obj, endpoint, ...
                {'per_page',    obj.perPage, ...
                'include[]',   'assignments'});

            [asmt_grps, status, resp] = getPayload(obj, url);
            if isempty(asmt_grps); return; end

            % Force "assignments" to be structs
            asmt_grps = forceStruct(asmt_grps, "assignments");
            asmt_grps = Chars2StringsRec(asmt_grps);

            % Add field for percentage of final grade
            totalWeight = sum([asmt_grps.group_weight]);
            for n = 1:length(asmt_grps)
                asmt_grps(n).group_weight_perc = ...
                    asmt_grps(n).group_weight ./ totalWeight;
            end
        end
        function [asmts, status, resp] = getAssignments(obj)
            %GETASSIGNMENTS Retrieve all assignments in the current Canvas course
            %   asmts = getAssignments(obj) returns a struct array of assignments
            %   available in the configured course.

            endpoint = "assignments";
            url = buildURL(obj, endpoint, {'per_page', obj.perPage});

            [asmts, status, resp] = getPayload(obj, url);
            asmts = Chars2StringsRec(asmts);
        end
        function [asmt, status, resp] = getAssignment(obj, assignmentID)
            %getAssignment Retrieve a specific assignment in the current Canvas course
            %   asmt = getAssignment(obj, asmtID) returns a struct array of
            %   an assignment
            arguments
                obj (1,1) Canvas
                assignmentID (1,1) double
            end

            endpoint = "assignments/" + assignmentID;
            url = buildURL(obj, endpoint);

            [asmt, status, resp] = getPayload(obj, url);
            asmt = Chars2StringsRec(asmt);
        end
        
        % Submissions
        function [subs, status, resp] = getSubmissions(obj, assignmentID)
            %getSubmissions Retrieve all submission metadata for specific assignment
            %   subs = getSubmissions(obj, asmtID) returns a struct array of
            %   all submissions
            arguments
                obj (1,1) Canvas
                assignmentID (1,1) double
            end
            endpoint = "assignments/" + assignmentID + "/submissions";
            url = buildURL(obj, endpoint, ...
                {'per_page', obj.perPage,...
                'include[]', 'submission_comments',...
                'include[]', 'submission_history'});

            [subs, status, resp] = getPayload(obj, url);
            subs = Chars2StringsRec(subs);
        end
        function [submission, status, resp] = sendGrade(obj, assignmentID, studentID, opts)
            %%SENDGRADE Sends instructor feedback and grade to a student's submission.
            %   Can also send additional information with the grade posting
            %   such as comments or files. At least one optional argument
            %   must be provided.
            %
            %   Optional Arguments:
            %   Grade - A grade to be given for the submission:
            %       Floating point value "13.5" is absolute points;
            %       A percentage "40%";
            %       Letter grade "B" will be given the highest percentage
            %           for that letter.
            %       Pass/Fail "pass", "complete", "fail", "incomplete" will
            %           grant 100% or 0%.
            %   Comment - A string of text to post as a simple comment.
            %   
            arguments
                obj (1,1) Canvas
                assignmentID (1,1) string
                studentID (1,1) string
                opts.Grade (1,1) string = []
                opts.Comment (1,1) string = []
                opts.FileNames (:,1) string = []
            end
            error("Not fully implemented or tested")

            submission = [];
            status = [];
            resp = [];

            endpoint = "assignments/" + assignmentID + "/submissions/" + studentID;
            url = buildURL(obj, endpoint);

            formArgs = {}

            % Append new grade
            if ~isempty(opts.Grade)
                formArgs = [formArgs, {"submission[posted_grade]", string(opts.Grade)}];
            end

            % Append comment
            if ~isempty(opts.Comment)
                formArgs = [formArgs, {"comment[text_comment]", opts.Comment}];
            end

            % Append files
            if ~isempty(opts.FileNames)
                for fileName = opts.FileNames
                    % Upload File
                    [file, status, resp] = uploadFile(obj, "comment", fileName,...
                        AssignmentID=assignmentID, StudentID=studentID);
                    if isempty(file)
                        return
                    end
                    % Attach ID to request arguments
                    formArgs = [formArgs, {"comment[file_ids][]", file.id}];
                end
            end

            if isempty(formArgs)
                warning("No form entries")
                return
            end
            
            form = matlab.net.http.io.FormProvider(formArgs{:});
            [submission, status, resp] = putPayload(obj, url, form);

        end
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

        % Files and Folders
        function [quota, status, resp] = getQuota(obj)
            
            endpoint = "files/quota";
            url = buildURL(obj, endpoint);

            [quota, status, resp] = getPayload(obj, url);
            if isempty(quota); return; end
            quota = Chars2StringsRec(quota);

            quota.quota_remaining = quota.quota - quota.quota_used;
            quota.quota_used_percent = quota.quota_used / quota.quota;
            quota.quota_remaining_percent = 1 - quota.quota_used_percent;
        end
        function [files, status, resp] = getFiles(obj, opts)
            %getFiles Retrieve metadata of all files on canvas.
            %   Optional Parameters:
            %   IncludeTypes - a string array of file types to filter for.
            %   ExcludeTypes - a string array of file types to filter out.
            %   Search - a string of a term to search for
            arguments
                obj (1,1) Canvas
                opts.IncludeTypes (1,:) string = []
                opts.ExcludeTypes (1,:) string = []
                opts.Search string = []
            end

            endpoint = "files";

            ExtraQueries = {'per_page', obj.perPage};

            url = buildURL(obj, endpoint);

            % build the form and validate optional arguments
            argSet = buildArgSet( ...
                "IncludeTypes", "content_types[]",          "string", ...
                "ExcludeTypes", "exclude_content_types[]",  "string", ...
                "Search",       "search_term",              "string");
            queries = buildBody("get", opts, argSet, LastArgs=ExtraQueries);

            [files, status, resp] = getPayload(obj, url, queries);
            files = Chars2StringsRec(files);
        end
        function [file, status, resp] = getFile(obj, fileID)
            %GETFILE Retrieve metadata of a folder
            arguments
                obj (1,1) Canvas
                fileID (1,1) string
            end

            endpoint = "files/" + fileID;
            url = buildURL(obj, endpoint);

            [file, status, resp] = getPayload(obj, url);
            file = Chars2StringsRec(file);
        end
        function [folders, status, resp] = getFolders(obj)
            %getFiles Retrieve metadata of all folders on canvas.
            arguments
                obj (1,1) Canvas
            end

            endpoint = "folders";
            url = buildURL(obj, endpoint, {'per_page', obj.perPage});

            [folders, status, resp] = getPayload(obj, url);
            if isempty(folders); return; end
            folders = Chars2StringsRec(folders);

            % Sort folder tree
            [~,index] = sortrows([folders.full_name].');
            folders = folders(index);
        end
        function [folder, status, resp] = getFolder(obj, folderID)
            %GETFOLDER Retrieve metadata of a folder
            arguments
                obj (1,1) Canvas
                folderID (1,1) string
            end

            endpoint = "folders/" + folderID;
            url = buildURL(obj, endpoint);

            [folder, status, resp] = getPayload(obj, url);
            folder = Chars2StringsRec(folder);
        end
        function [folder, status, resp] = createFolder(obj, name, opts)
            
            arguments
                obj (1,1) Canvas
                name (1,1) string
                opts.ParentID string = []
                opts.ParentPath string = []
                opts.UnlockAt datetime = NaT
                opts.LockAt datetime = NaT
                opts.Locked logical = []
                opts.Hidden logical = []
                opts.Position uint16 = []
            end

            endpoint = "folders";
            url = buildURL(obj, endpoint);

            % Guard
            if ~isempty(opts.ParentID) && ~isempty(opts.ParentPath)
                error("ParentID and ParentPath are mutually exclusive.")
            end

            RequiredArgs = {"name", name};

            % build the form and validate optional arguments
            argSet = buildArgSet( ...
                "ParentID",     "parent_folder_id",     "string", ...
                "ParentPath",   "parent_folder_path",   "path", ...
                "UnlockAt",     "unlock_at",            "datetime", ...
                "LockAt",       "lock_at",              "datetime", ...
                "Locked",       "locked",               "boolean", ...
                "Hidden",       "hidden",               "boolean", ...
                "Position",     "position",             "integer");
            
            form = buildBody("post", opts, argSet, FirstArgs=RequiredArgs);
            
            [folder, status, resp] = postPayload(obj, url, form);

        end
        function [file, status, resp] = uploadFile(obj, uploadType, fullFileName, opts)
            %UPLOADFILE Uploads a file to Canvas and returns the file's ID.
            %   The uploadType controls the file permissions. If uploadType
            %   is the following:
            %       "files" - generic file upload. User can supply which
            %       folder to place the file using FolderID or FolderPath.
            %       If none is provided, the file will be placed in the
            %       default folder "unfiled".
            %       "comment" - a file used to attach to a student's
            %       assignment submission. The use MUST supply the
            %       AssignmentID and the StudentID.
            %       

            % TODO: Split folder and endpoint args, use argSet

            arguments
                obj (1,1) Canvas
                uploadType (1,1) string {mustBeMember(uploadType, ["files", "comment"])}
                fullFileName (1,1) string
                opts.FolderID (1,1) string = ""
                opts.FolderPath (1,1) string = ""
                opts.AssignmentID (1,1) string = ""
                opts.StudentID (1,1) string = ""
            end

            switch uploadType
                case "files"
                    % Check requirements
                    if opts.FolderID ~= "" && opts.FolderPath ~= ""
                        error("ParentID and ParentPath are mutually exclusive.")
                    end
                    % Set endpoint
                    endpoint = "files";

                case "comment"
                    error("Untested and unsafe!")
                    % Check requirements
                    if opts.AssignmentID=="" || opts.StudentID==""
                        error("If using ""comment"", you must also provide AssignmentID and StudentID.")
                    end
                    % Set endpoint
                    endpoint = "assignments/" + opts.AssignmentID + ...
                        "/submissions/" + opts.StudentID + "/files";
            end

            % Get information about the file the user wants to upload
            fileInfo = dir(fullFileName);
            if isempty(fileInfo)
                error("No such file or directory for\n%s", fullFileName)
            end
            fileName = fileInfo.name;
            fileSize = fileInfo.bytes;

            % Step 1: Instruct Canvas to make a file object
            % This requires a POST request with multipart/form-data.
            url = buildURL(obj, endpoint);

            formArgs = {'name', fileName, 'size', num2str(fileSize)};
            if opts.FolderID ~= ""
                formArgs = [formArgs, {"parent_folder_id", opts.FolderID}];
            end
            if opts.FolderPath ~= ""
                opts.FolderPath = sanitizePath(opts.FolderPath);
                formArgs = [formArgs, {"parent_folder_path", opts.FolderPath}];
            end
            form = matlab.net.http.io.FormProvider(formArgs{:});
            
            [uploadData, status] = postPayload(obj, url, form);

            if status.StatusCode ~= matlab.net.http.StatusCode.OK
                file = [];
                return
            end

            % Parse the response
            uploadURL = uploadData.upload_url;
            uploadParams = uploadData.upload_params;

            % Step 2: Upload the File
            % Send a form with all returned args from first request, then
            % add the file provider.
            multipart = {};
            % Add the form fields from Canvas
            fields = fieldnames(uploadParams);
            for i = 1:numel(fields)
                multipart = [multipart, fields(i), {uploadParams.(fields{i})}];
            end
            % Add the actual file to the multipart
            multipart = [multipart, {'file'}, {matlab.net.http.io.FileProvider(fullFileName)}];

            uploadForm = matlab.net.http.io.MultipartFormProvider(multipart{:});

            % Send the request to the upload URL (no auth header needed)
            [file, status, resp] = postPayload(obj, uploadURL, uploadForm, Header=[]);
            if isempty(file); return; end
            % Send the request to the upload URL (no auth header needed)
            % uploadReq = matlab.net.http.RequestMessage('post', [], uploadForm);
            % uploadResp = uploadReq.send(uploadURL);

            % Check if good upload:
            % Get "location" from response
            % if 3XX, perform a GET to the same location to complete the
            % upload.
            if status.StatusCode == matlab.net.http.StatusCode.Created
                % testURL = matlab.net.URI(uploadResp.location);
                % testReq = matlab.net.http.RequestMessage('GET', obj.headers);
                % testresp = testReq.send(testURL);
            else
                error("A non 201 code was returned in the response. Incomplete implementation.")
            end

        end
        function [file, status, resp] = deleteFile(obj, fileID)

            arguments
                obj (1,1) Canvas
                fileID (1,1) string
            end

            endpoint = "files/" + fileID;
            url = buildURL(obj, endpoint, {}, UseCourse=false);

            [file, status, resp] = deleteObject(obj, url);
        end

        % Pages
        function [pages, status, resp] = getPages(obj, opts)
            %getPages Retrieve metadata of all pages on canvas.
            %   Optional Parameters:
            arguments
                obj (1,1) Canvas
                opts.Sort string {mustBeMember(opts.Sort, ["title", "created_at", "updated_at"])} = "updated_at"
                opts.Order (1,1) string {mustBeMember(opts.Order, ["asc", "desc"])} = "asc"
                opts.Search string = []
                opts.Published logical = []
            end

            endpoint = "pages";
            
            ExtraQueries = {'per_page', obj.perPage};

            url = buildURL(obj, endpoint);

            % build the form and validate optional arguments
            argSet = buildArgSet( ...
                "Sort", "sort",             "string", ...
                "Order", "order",           "string", ...
                "Search", "search_term",    "string", ...
                "Published", "published",   "boolean");
            queries = buildBody("get", opts, argSet, LastArgs=ExtraQueries);

            [pages, status, resp] = getPayload(obj, url, queries);
            pages = Chars2StringsRec(pages);
        end

        % Modules and Module Items
        function [modules, status, resp] = getModules(obj, opts)
            
            arguments
                obj (1,1) Canvas
                opts.Search string = []
            end

            endpoint = "modules";

            ExtraQueries = {...
                "include[]", "items",...
                "include[]", "content_details",...
                'per_page', obj.perPage};

            url = buildURL(obj, endpoint);

            % build the form and validate optional arguments
            argSet = buildArgSet( ...
                "Search", "search_term",    "string");
            queries = buildBody("get", opts, argSet, LastArgs=ExtraQueries);

            [modules, status, resp] = getPayload(obj, url, queries);

            if isempty(modules); return; end
            modules = forceStruct(modules, "items");
            modules = Chars2StringsRec(modules);
        end
        function [module, status, resp] = getModule(obj, moduleID)
            
            arguments
                obj (1,1) Canvas
                moduleID (1,1) string
            end

            endpoint = "modules/" + moduleID;
            url = buildURL(obj, endpoint,...
                {"include[]", "items",...
                "include[]", "content_details"});

            [module, status, resp] = getPayload(obj, url);
            if isempty(module); return; end
            module = forceStruct(module, "items");
            module = Chars2StringsRec(module);
        end
        function [module, status, resp] = createModule(obj, name, opts)
            % 
            % Default position is at the end.
            % UnlockAt should be a datetime object in local time

            arguments
                obj (1,1) Canvas
                name (1,1) string
                opts.UnlockAt datetime = NaT
                opts.Position uint16 {mustBeInteger,mustBeGreaterThan(opts.Position, 0)} = []
            end

            endpoint = "modules";
            url = buildURL(obj, endpoint);

            RequiredArgs = {"module[name]", name};

            % build the form and validate optional arguments
            argSet = buildArgSet( ...
                "UnlockAt",     "module[unlock_at]",       "datetime", ...
                "Position",     "module[position]",        "integer");

            form = buildBody("post", opts, argSet, FirstArgs=RequiredArgs);

            [module, status, resp] = postPayload(obj, url, form);
        end
        function [module, status, resp] = updateModule(obj, moduleID, opts)
            arguments
                obj (1,1) Canvas
                moduleID (1,1) string
                opts.Name string = []
                opts.UnlockAt datetime = NaT
                opts.Position uint16 {mustBeInteger,mustBeGreaterThan(opts.Position, 0)} = []
                opts.Publish logical = []
            end

            endpoint = "modules/" + moduleID;
            url = buildURL(obj, endpoint);

            % build the form and validate optional arguments
            argSet = buildArgSet( ...
                "Name",        "module[name]",           "string", ...
                "UnlockAt",    "module[unlock_at]",      "datetime", ...
                "Position",    "module[position]",       "integer", ...
                "Publish",     "module[published]",      "boolean");

            form = buildBody("post", opts, argSet);

            if isempty(form)
                warning("No form entries")
                module = [];
                status = [];
                resp = [];
                return
            end

            [module, status, resp] = putPayload(obj, url, form);
        end
        function [module, status, resp] = deleteModule(obj, moduleID)
            
            arguments
                obj (1,1) Canvas
                moduleID (1,1) string
            end

            endpoint = "modules/" + moduleID;
            url = buildURL(obj, endpoint);

            [module, status, resp] = deleteObject(obj, url);

        end
        function [moduleItem, status, resp] = createModuleItem(obj, moduleID, itemType, opts)
            arguments
                obj (1,1) Canvas
                moduleID (1,1) string
                itemType (1,1) string {mustBeMember(itemType,...
                    ["File", "Page", "Discussion", "Assignment", "Quiz", ...
                    "SubHeader", "ExternalUrl", "ExternalTool"])}
                % Args for API call
                opts.Title string = []
                opts.ContentID string = []
                opts.Position uint16 = []
                opts.Indent uint16 = []
                opts.PageURL string = []
                opts.ExternalURL string = []
                % Args for app features
                opts.Publish (1,1) logical = false
            end

            % First check requirements depending on selected itemType
            % Required for ContentID
            if ismember(itemType, ["File", "Discussion", "Assignment", "Quiz", "ExternalTool"])
                if isempty(opts.ContentID)
                    error("ContentID must be defined for itemType=%s", itemType)
                end
            end
            % For Page
            if itemType == "Page"
                if opts.PageURL == ""
                    error("PageURL must be defined for itemType=%s", itemType)
                end
            end
            % For ExternalURL
            if ismember(itemType, ["ExternalUrl", "ExternalTool"])
                if opts.ExternalURL == ""
                    error("ExternalURL must be defined for itemType=%s", itemType)
                end
            end

            % Now build the request

            endpoint = "modules/" + moduleID + "/items";
            url = buildURL(obj, endpoint);

            RequiredArgs = {"module_item[type]", itemType};

            % build the form and validate optional arguments
            argSet = buildArgSet( ...
                "Title",        "module_item[title]",           "string", ...
                "ContentID",    "module_item[content_id]",      "integer", ...
                "Position",     "module_item[position]",        "integer", ...
                "Indent",       "module_item[indent]",          "integer", ...
                "PageURL",      "module_item[page_url]",        "string", ...
                "ExternalURL",  "module_item[external_url]",    "string");

            form = buildBody("post", opts, argSet, FirstArgs=RequiredArgs);

            [moduleItem, status, resp] = postPayload(obj, url, form);

            if opts.Publish && ~isempty(moduleItem)
                % send update request right away
                [moduleItem, status, resp] = updateModuleItem(obj, ...
                    moduleID, moduleItem.id, Published=true);
            end

        end
        function [moduleItem, status, resp] = updateModuleItem(obj, moduleID, itemID, opts)
            arguments
                obj (1,1) Canvas
                moduleID (1,1) string
                itemID (1,1) string
                opts.Title string = []
                opts.Position uint16 = []
                opts.Indent uint8 = []
                opts.ExternalURL string = []
                opts.Published logical = []
                opts.NewModuleID string = []
            end

            endpoint = "modules/" + moduleID + "/items/" + itemID;
            url = buildURL(obj, endpoint);

            % build the form and validate optional arguments
            argSet = buildArgSet( ...
                "Title",        "module_item[title]",           "string", ...
                "Position",     "module_item[position]",        "integer", ...
                "Indent",       "module_item[indent]",          "integer", ...
                "ExternalURL",  "module_item[external_url]",    "string", ...
                "Published",    "module_item[published]",       "boolean", ...
                "NewModuleID",  "module_item[module_id]",       "string");
            form = buildBody("put", opts, argSet);

            if isempty(form)
                warning("No form entries")
                moduleItem = [];
                status = [];
                resp = [];
                return
            end

            [moduleItem, status, resp] = putPayload(obj, url, form);
        end
    
    end

    %% Private
    methods (Access = private)
        % Utility
        function printdb(obj, message)
            if obj.debug
                fprintf("[DEBUG] %s\n", message)
            end
        end
        function printdb_limits(obj, resp)
            % This function prints a debug statement (printdb) if the
            % response (resp) has limit headers. printdb checks if
            % debugging is enabled.
            CostHeader = resp.getFields("x-request-cost");
            RemHeader = resp.getFields("x-rate-limit-remaining");

            if isempty(CostHeader) || isempty(RemHeader)
                % no data to print, abort
                return
            end
            
            obj.printdb(sprintf("API Limiting:  Cost: %f  |  Remaining: %f",...
                double(resp.getFields("x-request-cost").Value), ...
                double(resp.getFields("x-rate-limit-remaining").Value)))
        end
        
        function url = buildURL(obj, endpoint, queries, opts)
            %BUILDURL Construct a full API URL from the endpoint and arguments
            %   url = buildURL(obj, endpoint) returns the full URL to use
            %   for a GET request.
            %   Queries (optional) must be a cell array of name,value pairs
            %   of arguments and values for the request query.
            %   url = buildURL(obj, endpoint, {arg1,val1,arg2,val2})
            arguments
                obj (1,1) Canvas
                endpoint (1,1) string = ""
                queries (1,:) cell = {}
                opts.UseCourse (1,1) logical = true
            end

            urlStr = obj.baseURL;

            if opts.UseCourse
                urlStr = urlStr + "/courses/" + obj.courseID;
            end

            if endpoint ~= ""
                % For all other endpoints, prepend with /
                % Otherwise we are left with course URI
                endpoint = "/" + endpoint;
            end
            urlStr = urlStr + endpoint;

            url = matlab.net.URI(urlStr);

            % Add query arguments to URL
            if ~isempty(queries)
                url.Query = [url.Query, matlab.net.QueryParameter(queries{:})];
            end
        end

        function [respData, status, resp] = deleteObject(obj, url)
            
            arguments
                obj (1,1) Canvas
                url (1,1) matlab.net.URI
            end

            respData = [];

            obj.printdb(sprintf("DELETE: %s", url.EncodedURI))

            req = matlab.net.http.RequestMessage('delete', obj.authHeader);
            resp = req.send(url);

            status = resp.StatusLine;

            if status.StatusCode ~= matlab.net.http.StatusCode.OK
                return
            end

            obj.printdb_limits(resp)

            respData = resp.Body.Data;
            if resp.Body.ContentType.Subtype == "json"
                respData = Chars2StringsRec(respData);
            end
        end
        function [respData, status, resp] = putPayload(obj, url, form, opts)
            %PUTPAYLOAD Performs a PUT request and returns status of response.
            %   HTTP PUT is mainly used to modify existing data on Canvas.
            arguments
                obj (1,1) Canvas
                url (1,1) matlab.net.URI
                form
                opts.Header = [obj.authHeader, obj.formHeader];
            end

            respData = [];

            obj.printdb(sprintf("PUT: %s", url.EncodedURI))
            obj.printdb(sprintf("Form: %s", form.string))
            
            req = matlab.net.http.RequestMessage('put', opts.Header, form);
            resp = req.send(url);

            status = resp.StatusLine;

            if status.StatusCode ~= matlab.net.http.StatusCode.OK
                return
            end

            obj.printdb_limits(resp)

            respData = resp.Body.Data;
            if resp.Body.ContentType.Subtype == "json"
                respData = Chars2StringsRec(respData);
            end

        end
        function [respData, status, resp] = postPayload(obj, url, form, opts)
            %POSTPAYLOAD Performs a POST request and returns status of response.
            %   HTTP POST is mainly used to create data on Canvas
            arguments
                obj (1,1) Canvas
                url (1,1) matlab.net.URI
                form
                opts.Header = [obj.authHeader, obj.formHeader];
            end

            respData = [];

            obj.printdb(sprintf("POST: %s", url.EncodedURI))
            obj.printdb(sprintf("Form: %s", form.string))
            
            req = matlab.net.http.RequestMessage('post', opts.Header, form);
            resp = req.send(url);

            status = resp.StatusLine;

            if ~(status.StatusCode == matlab.net.http.StatusCode.OK || ...
                    status.StatusCode == matlab.net.http.StatusCode.Created)
                return
            end

            obj.printdb_limits(resp)

            respData = resp.Body.Data;
            if resp.Body.ContentType.Subtype == "json"
                respData = Chars2StringsRec(respData);
            end

        end
        function [respData, status, resp] = getPayload(obj, url, queries)
            %GETPAYLOAD Performs a GET request and returns the data from the response.
            %   If pagination is required, data contains all collected
            %   data.
            %   status and resp are from the most recent page response

            arguments
                obj (1,1) Canvas
                url (1,1) matlab.net.URI
                queries (1,:) matlab.net.QueryParameter = []
            end

            respData = [];

            if ~isempty(queries)
                url.Query = [url.Query, queries];
            end

            obj.printdb(sprintf("GET: %s", url.EncodedURI))

            req = matlab.net.http.RequestMessage('GET', [obj.authHeader, obj.jsonHeader]);

            while true

                resp = req.send(url);
                status = resp.StatusLine;

                if resp.StatusCode ~= matlab.net.http.StatusCode.OK
                    % Failed, return empty (or partial), user should check
                    % status.
                    return
                end

                obj.printdb_limits(resp)

                if isstruct(resp.Body.Data)
                    respData = unionStructs(respData, resp.Body.Data);
                elseif iscell(resp.Body.Data)
                    S = normalizeStruct(resp.Body.Data); % convert cell array of hetero structures
                    respData = unionStructs(respData, S); % append to existing assignments
                elseif isempty(resp.Body.Data)
                    respData = [];
                    return
                else
                    error("Unknown body data type.")
                end

                % Check for pagination
                linkHeader = resp.getFields("Link");
                if isempty(linkHeader)
                    break;
                end
                % Look for rel="next" in the Link header
                links = parseLinkHeader(linkHeader.Value);
                % Check if there is a 'next' field in structure
                if ~isfield(links, 'next')
                    break;
                end

                url = matlab.net.URI(links.next);

            end
        end
    end

end

%% Helper Functions
% These functions are encapsulated inside this .m file and cannot be
% accessed outside the class.

function argSet = buildArgSet(name, key, type)
arguments (Repeating)
    name (1,1) string
    key (1,1) string
    type (1,1) string {mustBeMember(type, ["string", "integer", "boolean", "datetime", "path"])}
end
numArgs = length(name);
argSet = struct();
% For each tripplet, build the argSet
for a = 1:numArgs
    argSet.(name{a}) = struct(...
        "type", type{a}, ...
        "array", endsWith(key{a},"[]"), ...
        "key", key{a});
end
end

function body = buildBody(method, argStruct, argSet, opts)
% buildBody generates a query array (if method="get") or generates a
% multipart form (if method="post" or "put").
%
% Use buildArgSet to build a structure to help validate optional arugments
% of the API call.

arguments
    method (1,1) string {mustBeMember(method, ["get", "put", "post"])}
    argStruct struct
    argSet (1,1) struct
    opts.FirstArgs (1,:) cell = {}
    opts.LastArgs (1,:) cell = {}
end

argNames = string(fields(argSet))'; % row vector
bodyCell = {};

for argName = argNames
    % get data
    argValue = argStruct.(argName);

    % guard if no value for this arg
    if isempty(argValue); continue; end

    % guard for "empty" datetime
    if isdatetime(argValue) && isnat(argValue); continue; end

    % Convert any char arrays into strings to avoid bad array check
    if ischar(argValue); argValue = string(argValue); end

    % Process scalar or array
    argInfo = argSet.(argName); % arg type info
    if ~argInfo.array && (length(argValue) > 1)
        error("A vector was supplied instead of a scalar for %s", argName)
    end
    for a = 1:length(argValue)
        % Process value based on type (if needed)
        value = argValue(a);
        switch argInfo.type
            case "string"
                % do nothing
            case "integer"
                value = string(value); % converts a floating point to string format
            case "datetime"
                value = string(local2ISOchar(value));
            case "boolean"
                value = string(value);
            case "path"
                value = sanitizePath(value);
        end
        bodyCell = [bodyCell, {argInfo.key, value}];
    end
end

% Append special args
bodyCell = [opts.FirstArgs, bodyCell, opts.LastArgs];

% Package output
if isempty(bodyCell)
    return
end
switch method
    case "get"
        body = matlab.net.QueryParameter(bodyCell{:});
    case {"put", "post"}
        body = matlab.net.http.io.FormProvider(bodyCell{:});
end

end

function NewPath = sanitizePath(OldPath)
% Canvas only uses forward slashes / for filepath values
NewPath = strrep(OldPath, '\', '/');
end

function timechar = local2ISOchar(localDT)
if ~isa(localDT, 'datetime')
    error('Input must be a datetime object');
end
% If datetime has no timezone, assume system local timezone
if isempty(localDT.TimeZone)
    localDT.TimeZone = 'local';
end
% Format with ISO 8601 and timezone offset (±hh:mm)
localDT.Format = 'yyyy-MM-dd''T''HH:mm:ssXXX';
timechar = char(localDT);
end

function url = appendQuery(url, queries)
% Add arguments to URL
% queries is a cell array of name,value query args
if ~isempty(queries)
    % append new queries to existing queries
    url.Query = [url.Query, matlab.net.QueryParameter(queries{:})];
end
end

function links = parseLinkHeader(linkStr)
% Parses a Canvas-style Link header
% Returns a struct with rel names as fields: e.g., links.next, links.last
links = struct;
entries = strsplit(linkStr, ',');

for i = 1:length(entries)
    entry = strtrim(entries{i});
    tokens = regexp(entry, '<([^>]+)>;\s*rel="([^"]+)"', 'tokens');
    if ~isempty(tokens)
        url = tokens{1}{1};
        rel = tokens{1}{2};
        links.(rel) = url;
    end
end
end

function S = forceStruct(S, fieldname)
% Forces a field of heterogenous values to be structs. This is useful when
% canvas returns a field that is sometimes a struct arrray but other times
% it is a cell array.
for n = 1:length(S)
    S(n).(fieldname) = normalizeStruct(S(n).(fieldname));
end
end

function S = normalizeStruct(cellStructs)
% Converts a 1xN or Nx1 cell array of structs with unequal fields
% into a struct array with all fields present in each element.

if ~iscell(cellStructs)
    S = cellStructs;
    return
end

cellStructs = vertcat(cellStructs(:));

% All unique field names
allFields = [];
for s = cellStructs
    theseFields = string(fieldnames(s{1}));
    allFields = unique([theseFields; allFields]);
end

% Initialize output
N = numel(cellStructs);
S = repmat(struct(), N, 1);

for i = 1:N
    thisStruct = cellStructs{i};
    for f = allFields'
        fname = f{1};
        if isfield(thisStruct, fname)
            S(i).(fname) = thisStruct.(fname);
        else
            S(i).(fname) = [];
        end
    end
end
end

function merged = unionStructs(A, B)
% Merges two struct arrays A and B, handling missing fields.
% Ensures all structs have the same fields before concatenation.

if isempty(A); merged = B; return; end
if isempty(B); merged = A; return; end

% Get all fieldnames
fieldsA = fieldnames(A);
fieldsB = fieldnames(B);
allFields = unique([fieldsA; fieldsB]);

% Pad missing fields in A
for i = 1:numel(A)
    for f = allFields'
        fname = f{1};
        if ~isfield(A(i), fname)
            A(i).(fname) = [];
        end
    end
end

% Pad missing fields in B
for i = 1:numel(B)
    for f = allFields'
        fname = f{1};
        if ~isfield(B(i), fname)
            B(i).(fname) = [];
        end
    end
end

% Concatenate
merged = [A; B];
end

function data = Chars2StringsRec(data)
% Recursive search through structure to change char arrays to strings.
if isstruct(data)
    % If it's a structure, recurse through each field
    fields = fieldnames(data);
    for i = 1:numel(fields)
        for j = 1:numel(data)
            fieldValue = data(j).(fields{i});
            data(j).(fields{i}) = Chars2StringsRec(fieldValue);
        end
    end
elseif iscell(data)
    % Recurse through each cell
    for i = 1:numel(data)
        data{i} = Chars2StringsRec(data{i});
    end
elseif ischar(data)
    % Convert char array to string
    data = string(data);
end
% Leave other data types (numeric, logical, etc.) untouched
end
