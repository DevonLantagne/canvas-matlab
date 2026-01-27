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