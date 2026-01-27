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
