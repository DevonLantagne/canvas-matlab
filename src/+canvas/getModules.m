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
