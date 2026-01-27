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
