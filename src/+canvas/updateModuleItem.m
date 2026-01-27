function [moduleItem, status, resp] = updateModuleItem(obj, moduleID, itemID, opts)
arguments
    obj (1,1) Canvas
    moduleID (1,1) string
    itemID (1,1) string
    opts.Title string = []
    opts.Position uint16 = []
    opts.Indent uint8 = []
    opts.ExternalURL string = []
    opts.Published logical = []
    opts.NewModuleID string = []
end

endpoint = "modules/" + moduleID + "/items/" + itemID;
url = buildURL(obj, endpoint);

% build the form and validate optional arguments
argSet = buildArgSet( ...
    "Title",        "module_item[title]",           "string", ...
    "Position",     "module_item[position]",        "integer", ...
    "Indent",       "module_item[indent]",          "integer", ...
    "ExternalURL",  "module_item[external_url]",    "string", ...
    "Published",    "module_item[published]",       "boolean", ...
    "NewModuleID",  "module_item[module_id]",       "string");
form = buildBody("put", opts, argSet);

if isempty(form)
    warning("No form entries")
    moduleItem = [];
    status = [];
    resp = [];
    return
end

[moduleItem, status, resp] = putPayload(obj, url, form);
end
