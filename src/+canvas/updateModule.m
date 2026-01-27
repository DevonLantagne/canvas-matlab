function [module, status, resp] = updateModule(obj, moduleID, opts)
arguments
    obj (1,1) Canvas
    moduleID (1,1) string
    opts.Name string = []
    opts.UnlockAt datetime = NaT
    opts.Position uint16 {mustBeInteger,mustBeGreaterThan(opts.Position, 0)} = []
    opts.Publish logical = []
end

endpoint = "modules/" + moduleID;
url = buildURL(obj, endpoint);

% build the form and validate optional arguments
argSet = buildArgSet( ...
    "Name",        "module[name]",           "string", ...
    "UnlockAt",    "module[unlock_at]",      "datetime", ...
    "Position",    "module[position]",       "integer", ...
    "Publish",     "module[published]",      "boolean");

form = buildBody("post", opts, argSet);

if isempty(form)
    warning("No form entries")
    module = [];
    status = [];
    resp = [];
    return
end

[module, status, resp] = putPayload(obj, url, form);
end
