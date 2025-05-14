classdef Canvas
    %CANVAS Interface to the Canvas LMS REST API
    %   This class allows you to interact with the Canvas Learning Management System
    %   using the public REST API. You can retrieve data such as students, assignments,
    %   and post grades using authenticated HTTP requests.
    %
    %   obj = Canvas(baseURL, token, courseID) creates a new Canvas API object.
    %
    %   INPUTS:
    %       baseURL  - Base URL of the Canvas instance (e.g., "https://canvas.instructure.com/api/v1")
    %       token    - Canvas API access token (string)
    %       courseID - Canvas course ID (string)
    %
    %   OPTIONAL NAME-VALUE ARGUMENTS:
    %       debug    - Logical flag to enable verbose debug printing

    properties
        %COURSENAME Name of the course from Canvas
        courseName

        %COURSECODE Canvas course code of the course
        courseCode

        %DEBUG Enable verbose debug printing
        %   If true, API requests and rate limit details are printed to the console.
        debug (1,1) logical = false

        %PERPAGE Sets the number of items per API call before paging
        %   Must be a value between 10 and 100 (default is 100).
        perPage (1,1) uint8 {mustBeNumeric, mustBeInRange(perPage,10,100)} = 100
    end

    properties (SetAccess = private)
        %BASEURL The base URL for the Canvas API
        baseURL (1,1) string

        %COURSEID The Canvas course identifier
        courseID (1,1) string
    end

    properties (Dependent)

    end

    properties (Access = private, Hidden)
        %TOKEN Bearer token used for authentication
        token (1,1) string

        %HEADERS Precomputed HTTP headers used in each request
        headers
    end


    %% Constructor
    methods
        function obj = Canvas(baseURL, token, courseID, opts)
            %CANVAS Construct a Canvas API interface object
            %   obj = Canvas(baseURL, token, courseID) initializes a connection to
            %   a Canvas course using the provided API token.
            %
            %   Optional:
            %       opts.debug - enable verbose printing of requests (default: false)

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

            obj.headers = [
                matlab.net.http.HeaderField('Authorization', ['Bearer ' char(obj.token)]), ...
                matlab.net.http.HeaderField('Accept', 'application/json')
                ];

            url = buildURL(obj); % Build default course URL

            request = matlab.net.http.RequestMessage('GET', obj.headers);

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
            out = num2str(obj.perPage);
        end
    end

    %% HTTP GET Methods
    % These methods only get data from Canvas and do not modify data on
    % Canvas.
    methods
        % Student Info
        function students = getStudents(obj, opts)
            %GETSTUDENTS Retrieve all active students enrolled in the course
            %   students = getStudents(obj) fetches active enrolled students in the current course.
            %
            %   Optional name-value pairs:
            %       GetAvatar - if true, includes avatar URLs in the response
            %       Query - if empty, does not send default query params.
            %               User can supply a cell array of name,values:
            %               st = canv.getStudents(Query={'arg1','val1','arg2','val2'})

            arguments
                obj (1,1) Canvas
                opts.GetAvatar (1,1) logical = false
                opts.Query = 0;
            end

            endpoint = "search_users";

            % Determine query args
            if opts.Query == 0
                % Use defaults
                qry = {'enrollment_type[]',   'student',...
                    'enrollment_state[]',  'active',...
                    'per_page',            obj.perPage,...
                    'include[]',           'enrollments'};
                % Append avatar links if needed
                if opts.GetAvatar
                    qry = [qry, {'include[]', 'avatar_url'}];
                end
            else
                % Use User's (can be empty for no queries)
                qry = opts.Query;
            end

            url = obj.buildURL(endpoint, qry);

            students = getPayload(obj, url);

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
        function asmt_grps = getAssignmentGroups(obj)
            %getAssignmentGroups Retrieve all assignments groups in the current Canvas course
            %   asmt_grps = getAssignmentGroups(obj) returns a struct array
            %   of assignment groups available in the configured course.
            %   Also returns the assignments within those groups.

            endpoint = "assignment_groups";
            url = buildURL(obj, endpoint, ...
                {'per_page',    obj.perPage, ...
                'include[]',   'assignments'});

            asmt_grps = getPayload(obj, url);

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
        function asmts = getAssignments(obj)
            %GETASSIGNMENTS Retrieve all assignments in the current Canvas course
            %   asmts = getAssignments(obj) returns a struct array of assignments
            %   available in the configured course.

            endpoint = "assignments";
            url = buildURL(obj, endpoint, {'per_page', obj.perPage});

            asmts = getPayload(obj, url);
            asmts = Chars2StringsRec(asmts);
        end
        function asmt = getAssignment(obj, assignmentID)
            %getAssignment Retrieve a specific assignment in the current Canvas course
            %   asmt = getAssignment(obj, asmtID) returns a struct array of
            %   an assignment
            arguments
                obj (1,1) Canvas
                assignmentID (1,1) double
            end

            endpoint = "assignments/" + assignmentID;
            url = buildURL(obj, endpoint);

            asmt = getPayload(obj, url);
            asmt = Chars2StringsRec(asmt);
        end
        
        % Submissions
        function subs = getSubmissions(obj, assignmentID)
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

            subs = getPayload(obj, url);
            subs = Chars2StringsRec(subs);
        end
        
        % Files and Folders
        function files = getFiles(obj, opts)
            %getFiles Retrieve metadata of all files on canvas.
            %   Optional Parameters:
            %   IncludeTypes - a string array of file types to filter for.
            %   ExcludeTypes - a string array of file types to filter out.
            %   Search - a string of a term to search for
            arguments
                obj (1,1) Canvas
                opts.IncludeTypes (1,:) string = ""
                opts.ExcludeTypes (1,:) string = ""
                opts.Search (1,1) string = ""
            end

            endpoint = "files";
            url = buildURL(obj, endpoint, ...
                {'per_page', obj.perPage});

            % Check IncludeTypes
            if opts.IncludeTypes ~= ""
                for n = 1:length(opts.IncludeTypes)
                    url = appendQuery(url, {'content_types[]', opts.IncludeTypes(n)});
                end
            end

            % Check ExcludeTypes
            if opts.ExcludeTypes ~= ""
                for n = 1:length(opts.IncludeTypes)
                    url = appendQuery(url, {'exclude_content_types[]', opts.ExcludeTypes(n)});
                end
            end

            % Check Search
            if opts.Search ~= ""
                url = appendQuery(url, {'search_term', opts.Search});
            end

            files = getPayload(obj, url);
            files = Chars2StringsRec(files);
        end
        function file = getFile(obj, fileID)
            %GETFILE Retrieve metadata of a folder
            arguments
                obj (1,1) Canvas
                fileID (1,1) string
            end

            endpoint = "files/" + fileID;
            url = buildURL(obj, endpoint);

            file = getPayload(obj, url);
            file = Chars2StringsRec(file);
        end
        function folders = getFolders(obj)
            %getFiles Retrieve metadata of all folders on canvas.
            arguments
                obj (1,1) Canvas
            end

            endpoint = "folders";
            url = buildURL(obj, endpoint, ...
                {'per_page', obj.perPage});

            folders = getPayload(obj, url);
            folders = Chars2StringsRec(folders);

            % Sort folder tree
            [~,index] = sortrows([folders.full_name].');
            folders = folders(index);
        end
        function folder = getFolder(obj, folderID)
            %GETFOLDER Retrieve metadata of a folder
            arguments
                obj (1,1) Canvas
                folderID (1,1) string
            end

            endpoint = "folders/" + folderID;
            url = buildURL(obj, endpoint);

            folder = getPayload(obj, url);
            folder = Chars2StringsRec(folder);
        end

        % Modules
        function modules = getModules(obj, opts)
            
            arguments
                obj (1,1) Canvas
                opts.Search (1,1) string = ""
            end

            endpoint = "modules";
            url = buildURL(obj, endpoint,...
                {"include[]", "items",...
                "include[]", "content_details",...
                'per_page', obj.perPage});

            % Check Search
            if opts.Search ~= ""
                url = appendQuery(url, {'search_term', opts.Search});
            end

            modules = getPayload(obj, url);
            modules = forceStruct(modules, "items");
            modules = Chars2StringsRec(modules);
        end
        function module = getModule(obj, moduleID)
            
            arguments
                obj (1,1) Canvas
                moduleID (1,1) string
            end

            endpoint = "modules/" + moduleID;
            url = buildURL(obj, endpoint,...
                {"include[]", "items",...
                "include[]", "content_details"});

            module = getPayload(obj, url);
            module = forceStruct(module, "items");
            module = Chars2StringsRec(module);
        end

        % Downloads
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
            subs = obj.getSubmissions(assignmentID);

            % Get list of all students
            students = obj.getStudents();

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

    end


    %% HTTP PUT/POST Methods
    % These methods send data to Canvas. Use with caution!
    methods
        function [success, msg] = sendGrade(obj, assignmentID, studentID, opts)
            %%SENDGRADE Sends instructor feedback and grade to a student's submission.
            %   Can also send additional information with the grade posting
            %   such as comments or files. 
            %   Optional Arguments:
            %   Grade - A grade to be given for the submission. Can be a
            %   decimal number (for raw score), 
            %   
            arguments
                obj (1,1) Canvas
                assignmentID (1,1) string
                studentID (1,1) string
                opts.Grade (1,1) string = []
                opts.Comment (1,1) string = []
                opts.FileNames (:,1) string = []
            end

            endpoint = "assignments/" + assignmentID + "/submissions/" + studentID;
            url = buildURL(obj, endpoint);

            % Form data structure
            bodyStruct = struct();

            % Append new grade
            if ~isempty(opts.Grade)
                bodyStruct.submission = struct('posted_grade', opts.Grade);
            end

            % Append comment
            if ~isempty(opts.Comment)
                bodyStruct.comment = struct('text_comment', opts.Comment);
            end

            % Append files
            if ~isempty(opts.FileNames)
                % TODO
                fileEndpoint = "assignments/" + assignmentID + ...
                    "/submissions/" + studentID + "/comments/files";
                for fileName = opts.FileNames
                    
                end
            end

            % send PUT request
            resp = putPayload(obj, url, bodyStruct);

            success = [];
            msg = resp;

        end
        function fileID = uploadFile(obj, endpoint, fullFileName)
            %UPLOADFILE Uploads a file to Canvas and returns the file's ID.
            %   The endpoint controls the file's access permissions.
            %   Uploading to the course's files just places is at a generic
            %   file. You can also use the submissions endpoint for student
            %   feedback or submission files.

            arguments
                obj (1,1) Canvas
                endpoint (1,1) string
                fullFileName (1,1) string
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

            form = matlab.net.http.io.FormProvider('name', fileName, 'size', num2str(fileSize));

            % Only send auth header.
            authheader = matlab.net.http.HeaderField(...
                'Authorization', ['Bearer ' char(obj.token)]);
            
            % Send the request
            req = matlab.net.http.RequestMessage('post', authheader, form);
            resp = req.send(url);

            if resp.StatusCode ~= matlab.net.http.StatusCode.OK
                error("Failed to request file upload: %s", char(resp.StatusLine.ReasonPhrase))
            end

            % Parse the response
            uploadData = resp.Body.Data;
            uploadURL = uploadData.upload_url;
            uploadParams = uploadData.upload_params;

            % Step 2: Upload the File
            % Start forming multipart forms
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
            uploadReq = matlab.net.http.RequestMessage('post', [], uploadForm);
            uploadResp = uploadReq.send(uploadURL);

            % Check if good upload:
            % Get "location" from response
            % if 3XX, perform a GET to the same location to complete the
            % upload.
            if uploadResp.StatusCode == matlab.net.http.StatusCode.Created
                location = uploadResp.Body.Data.location;
                testURL = matlab.net.URI(location);
                testReq = matlab.net.http.RequestMessage('GET', obj.headers);
                testresp = testReq.send(testURL);
            else
                error("A non 201 code was returned in the response. Incomplete implementation.")
            end

            fileID = testresp.Body.Data.id;
        end
        
        % Modules
        function [module, status] = createModule(obj, name, opts)
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

            formArgs = {"module[name]", name};

            if ~isempty(opts.Position)
                formArgs = [formArgs, {"module[position]", opts.Position}];
            end

            if isnat(opts.UnlockAt)
                formArgs = [formArgs, {"module[unlock_at]", local2UTCchar(opts.UnlockAt)}];
            end

            form = matlab.net.http.io.FormProvider(formArgs{:});

            [module, status] = putPayload(obj, url, form);
        end
        
    end

    %% Private
    methods (Access = private)
        function printdb(obj, message)
            if obj.debug
                fprintf("[DEBUG] %s\n", message)
            end
        end
        function url = buildURL(obj, endpoint, queries)
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
            end

            if endpoint == ""
                % if no endpoint, just use course URI
            else
                % For all other endpoints, prepend with /
                endpoint = "/" + endpoint;
            end

            url = matlab.net.URI(sprintf('%s/courses/%s%s', ...
                obj.baseURL, obj.courseID, endpoint));

            % Add query arguments to URL
            if ~isempty(queries)
                url = appendQuery(url, queries);
            end
        end

        function [respData, status] = putPayload(obj, url, form)
            %PUTPAYLOAD Performs a PUT request and returns status of response.
            arguments
                obj (1,1) Canvas
                url (1,1) matlab.net.URI
                form
            end

            postheaders = [
                matlab.net.http.HeaderField('Authorization', ['Bearer ' char(obj.token)]), ...
                matlab.net.http.field.ContentTypeField('application/x-www-form-urlencoded')
                ];
            
            req = matlab.net.http.RequestMessage('post', postheaders, form);
            resp = req.send(url);

            if resp.StatusCode == matlab.net.http.StatusCode.OK
                respData = resp.Body.Data;
                if resp.Body.ContentType.Subtype == "json"
                    respData = Chars2StringsRec(respData);
                end
            else
                respData = [];
            end

            status = resp.StatusLine;
        end
        function data = getPayload(obj, url)
            %GETPAYLOAD Performs a GET request and returns the data from the response.
            arguments
                obj (1,1) Canvas
                url (1,1) matlab.net.URI
            end

            data = [];

            obj.printdb(sprintf("GET: %s", url.EncodedURI))

            req = matlab.net.http.RequestMessage('GET', obj.headers);

            while true

                resp = req.send(url);

                if resp.StatusCode ~= matlab.net.http.StatusCode.OK
                    error('Failed to fetch data: %s', char(resp.StatusLine.ReasonPhrase));
                end

                obj.printdb(sprintf("API Limiting:  Cost: %f  |  Remaining: %f",...
                    double(resp.getFields("x-request-cost").Value), ...
                    double(resp.getFields("x-rate-limit-remaining").Value)))

                if isstruct(resp.Body.Data)
                    data = unionStructs(data, resp.Body.Data);
                elseif iscell(resp.Body.Data)
                    S = normalizeStruct(resp.Body.Data); % convert cell array of hetero structures
                    data = unionStructs(data, S); % append to existing assignments
                elseif isempty(resp.Body.Data)
                    data = [];
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

function timechar = local2UTCchar(localDT)
localDT.TimeZone = 'UTC';
timechar = char(opts.UnlockAt, 'yyyy-MM-dd''T''HH:mm:ss''Z''');
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
