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
        %DEBUG Enable verbose debug printing
        %   If true, API requests and rate limit details are printed to the console.
        debug (1,1) logical = false
        
        %PERPAGE Sets the number of items per API call before paging
        %   Must be a value between 10 and 100 (default is 100).
        PerPage (1,1) uint8 {mustBeNumeric, mustBeInRange(PerPage,10,100)} = 100
    end

    properties (Access = private)
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
                if response.StatusCode ~= matlab.net.http.StatusCode.OK
                    error("CanvasAPI:ConnectionFailed", ...
                        "Connection failed: %s", response.StatusLine);
                end
            catch ME
                error("CanvasAPI:ConnectionTestError", ...
                    "Could not connect to Canvas API: %s", ME.message);
            end

        end
    end

    %% GET Methods
    methods
        function out = get.PerPage(obj)
            out = num2str(obj.PerPage);
        end
    end

    %% HTTP GET Methods
    % These methods only get data from Canvas and do not modify data on
    % Canvas.
    methods
        function students = getStudents(obj, opts)
            %GETSTUDENTS Retrieve all active students enrolled in the course
            %   students = getStudents(obj) fetches enrolled students in the current course.
            %
            %   Optional name-value pairs:
            %       GetAvatar - if true, includes avatar URLs in the response

            arguments
                obj (1,1) Canvas
                opts.GetAvatar (1,1) logical = false
            end

            endpoint = "search_users";
            url = obj.buildURL(endpoint,...
                {'enrollment_type[]',   'student'},...
                {'enrollment_state[]',  'active'},...
                {'per_page',            obj.PerPage},...
                {'include[]',           'enrollments'});
            if opts.GetAvatar
                url = obj.addQuery(url, {'include[]', 'avatar_url'});
            end

            students = getPayload(obj, url);

            % Modify data output by relocating enrollment section
            for n = 1:length(students)
                enroleCode = students(n).enrollments.sis_section_id;
                students(n).section = extractAfter(enroleCode, '-');
            end

            students = Chars2StringsRec(students);

        end
        function asmt_grps = getAssignmentGroups(obj)
            %getAssignmentGroups Retrieve all assignments groups in the current Canvas course
            %   asmt_grps = getAssignmentGroups(obj) returns a struct array
            %   of assignment groups available in the configured course.
            %   Also returns the assignments within those groups.

            endpoint = "assignment_groups";
            url = buildURL(obj, endpoint, ...
                {'per_page',    obj.PerPage}, ...
                {'include[]',   'assignments'});

            asmt_grps = getPayload(obj, url);

            % Force "assignments" to be structs
            for n = 1:length(asmt_grps)
                asmt_grps(n).assignments = normalizeStruct(asmt_grps(n).assignments);
            end

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
            url = buildURL(obj, endpoint, {'per_page', obj.PerPage});

            asmts = getPayload(obj, url);

            asmts = Chars2StringsRec(asmts);
        end
    end

    %% HTTP POST Methods
    methods
        function [success, msg] = sendGrade(obj, assignmentID, studentID, grade)
            error("Don't")

            studentID = num2str(studentID);

            % Prepare URL and payload
            url = sprintf('%s/courses/%s/assignments/%s/submissions/%s', ...
                obj.baseURL, obj.courseID, assignmentID, studentID);

            body = struct('submission', struct('posted_grade', num2str(grade)));

            % Send HTTP PUT request to Canvas
            try
                response = webwrite(url, body, obj.webopts);

                msg = sprintf('Updated grade for student %s, assignment %s\n', ...
                    studentID, assignmentID);
                success = true;
            catch ME
                msg = sprintf('Failed to update student %s, assignment %s: %s', ...
                    studentID, assignmentID, ME.message);
                success = false;
            end
        end
    end

    %% Private
    methods (Access = private)
        function printdb(obj, message)
            if obj.debug
                fprintf("[DEBUG] %s\n", message)
            end
        end
        function url = buildURL(obj, endpoint, varargin)
            %BUILDURL Construct a full API URI from the endpoint and arguments
            %   url = buildURL(obj, endpoint) returns the full URL to use for a GET/POST
            %   Arguments are passed as 1x2 cell arrays {argName, value}
            %   url = buildURL(obj, endpoint, {arg1,val1}, {arg2,val2})

            if (nargin==1) || isempty(endpoint)
                % if no endpoint, just use course URI
                endpoint = "";
            else
                % For all other endpoints
                endpoint = "/" + string(endpoint); % ensure a string
            end
            url = matlab.net.URI(sprintf(...
                '%s/courses/%s%s', obj.baseURL, obj.courseID, endpoint));

            % Add arguments to URL
            url = obj.addQuery(url, varargin{:});
        end
        function url = addQuery(obj, url, varargin)
            % Add arguments to URL
            if ~isempty(varargin)
                queryList = url.Query;
                for arg = 1:length(varargin)
                    queryList = [queryList, ...
                        matlab.net.QueryParameter(...
                        varargin{arg}{1}, varargin{arg}{2})];
                end
                url.Query = queryList;
            end
        end
        function data = getPayload(obj, url)
            %GETPAYLOAD Performs a GET request and returns the data from the response.

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

function S = normalizeStruct(cellStructs)
% Converts a 1xN or Nx1 cell array of structs with unequal fields
% into a struct array with all fields present in each element.

if isstruct(cellStructs)
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
