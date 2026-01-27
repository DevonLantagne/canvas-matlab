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
