classdef Canvas
    %CANVAS Summary of this class goes here
    %   Detailed explanation goes here

    properties (Access = private)
        token (1,1) string
        baseURL (1,1) string
        courseID (1,1) string
    end

    properties (Dependent)
        courseURL
    end

    properties (Access = private, Hidden)
        headers
    end


    %% Constructor
    methods
        function obj = Canvas(baseURL, token, courseID)
            %CANVAS Construct an instance of this class
            %   Detailed explanation goes here
            import matlab.net.*
            import matlab.net.http.*

            obj.token = string(token);
            obj.baseURL = string(baseURL);
            obj.courseID = string(courseID);

            obj.headers = [
                HeaderField('Authorization', ['Bearer ' char(obj.token)]), ...
                HeaderField('Accept', 'application/json')
                ];

            % Test connection
            import matlab.net.*
            import matlab.net.http.*

            uri = URI(sprintf('%s/courses/%s', ...
                obj.baseURL, obj.courseID));

            request = RequestMessage('GET', obj.headers);
            try
                response = request.send(uri);
                if response.StatusCode ~= StatusCode.OK
                    error("CanvasAPI:ConnectionFailed", ...
                        "Connection failed: %s", response.StatusLine);
                end
            catch ME
                error("CanvasAPI:ConnectionTestError", ...
                    "Could not connect to Canvas API: %s", ME.message);
            end

        end
    end

    methods
        function out = get.courseURL(obj)
            out = sprintf("%s/courses/%s", obj.baseURL, obj.courseID);
        end
    end

    %% HTTP GET Methods
    % These methods only get data from Canvas and do not modify data on
    % Canvas.
    methods
        function students = getStudents(obj, opts)
            arguments
                obj (1,1) Canvas
                opts.ShowAvatar (1,1) logical = false
            end
            import matlab.net.*
            import matlab.net.http.*

            uri = URI(sprintf('%s/search_users', ...
                obj.courseURL));

            qs = [...
                QueryParameter('enrollment_type[]', 'student'), ...
                QueryParameter('enrollment_state[]', 'active'), ...
                QueryParameter('per_page', '100'), ...
                QueryParameter('include[]', 'enrollments') ...
                ];
            if opts.ShowAvatar
                qs = [qs, QueryParameter('include[]', 'avatar_url')];
            end
            uri.Query = qs;

            students = getPayload(obj, uri);

        end
        function asmts = getAssignments(obj)

            import matlab.net.*
            import matlab.net.http.*

            uri = URI(sprintf('%s/courses/%s/assignments', ...
                obj.baseURL, obj.courseID));

            asmts = getPayload(obj, uri);
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
        function data = getPayload(obj, uri)
            import matlab.net.*
            import matlab.net.http.*

            data = [];

            req = RequestMessage('GET', obj.headers);

            %queries = uri.Query;

            while true
                
                resp = req.send(uri);

                if resp.StatusCode ~= StatusCode.OK
                    error('Failed to fetch data: %s', char(resp.StatusLine.ReasonPhrase));
                end

                %fprintf("Queries remaining: %d\n", double(resp.getFields("x-rate-limit-remaining").Value))

                if isstruct(resp.Body.Data)
                    data = Canvas.unionStructs(data, resp.Body.Data);
                elseif iscell(resp.Body.Data)
                    S = Canvas.normalizeStruct(resp.Body.Data); % convert cell array of hetero structures
                    data = Canvas.unionStructs(data, S); % append to existing assignments
                else
                    error("Unknown body data type.")
                end

                % Check for pagination
                linkHeader = resp.getFields("Link");
                if isempty(linkHeader)
                    break;
                end

                % Look for rel="next" in the Link header
                links = Canvas.parseLinkHeader(linkHeader.Value);
                % Check if there is a 'next' field in structure
                if ~isfield(links, 'next')
                    break;
                end

                uri = URI(links.next);
                %uri.Query = queries;
            end
        end
    end

    methods (Static, Access = private)

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
            % Converts a 1xN cell array of structs with unequal fields
            % into a struct array with all fields present in each element.

            % All unique field names
            allFields = [];
            for s = cellStructs'
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
    end
end

