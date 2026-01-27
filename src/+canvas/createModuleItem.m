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
