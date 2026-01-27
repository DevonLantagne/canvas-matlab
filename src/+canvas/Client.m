classdef Client
    %Client Interface to the Canvas LMS REST API
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
        % Token Management
        credTarget = 'CanvasMATLAB'
        credUserName = 'CanvasAPIToken'
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

            url = canvas.internal.http.buildURL(obj); % Build default course URL

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

    %% Private
    methods (Access = private)

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


        function [respData, status, resp] = delete(obj, url)

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
                respData = canvas.internal.chars2StringsRec(respData);
            end
        end


        function [respData, status, resp] = send(obj, method, url, form, opts)
            % Performs POST and PUT methods

            arguments
                obj (1,1) Canvas
                method (1,1) string {mustBeMember(method, ["PUT","POST"])}
                url (1,1) matlab.net.URI
                form
                opts.Header = [obj.authHeader, obj.formHeader];
            end

            respData = [];

            obj.printdb(sprintf("%s: %s", method, url.EncodedURI))
            obj.printdb(sprintf("Form: %s", form.string))

            req = matlab.net.http.RequestMessage(method, opts.Header, form);
            resp = req.send(url);

            status = resp.StatusLine;

            % Return if bad status
            if method == "PUT"
                if status.StatusCode ~= matlab.net.http.StatusCode.OK
                    return
                end
            else % POST
                if ~(status.StatusCode == matlab.net.http.StatusCode.OK || ...
                        status.StatusCode == matlab.net.http.StatusCode.Created)
                    return
                end
            end

            % Otherwise status is good...

            obj.printdb_limits(resp)

            respData = resp.Body.Data;
            if resp.Body.ContentType.Subtype == "json"
                respData = canvas.internal.chars2StringsRec(respData);
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
            warning('Depricated: use ''canvas.send()''')

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
                respData = canvas.internal.chars2StringsRec(respData);
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
            warning('Depricated: use ''canvas.send()''')

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
                respData = canvas.internal.chars2StringsRec(respData);
            end

        end


        function [respData, status, resp] = get(obj, url, queries)
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
                    respData = canvas.internal.unionStructs(respData, resp.Body.Data);
                elseif iscell(resp.Body.Data)
                    S = canvas.internal.normalizeStruct(resp.Body.Data); % convert cell array of hetero structures
                    respData = canvas.internal.unionStructs(respData, S); % append to existing assignments
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
                links = canvas.internal.parseLinkHeader(linkHeader.Value);
                % Check if there is a 'next' field in structure
                if ~isfield(links, 'next')
                    break;
                end

                url = matlab.net.URI(links.next);
            end
        end
    end

end