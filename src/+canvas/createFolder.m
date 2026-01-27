function [folder, status, resp] = createFolder(obj, name, opts)

arguments
    obj (1,1) Canvas
    name (1,1) string
    opts.ParentID string = []
    opts.ParentPath string = []
    opts.UnlockAt datetime = NaT
    opts.LockAt datetime = NaT
    opts.Locked logical = []
    opts.Hidden logical = []
    opts.Position uint16 = []
end

endpoint = "folders";
url = buildURL(obj, endpoint);

% Guard
if ~isempty(opts.ParentID) && ~isempty(opts.ParentPath)
    error("ParentID and ParentPath are mutually exclusive.")
end

RequiredArgs = {"name", name};

% build the form and validate optional arguments
argSet = buildArgSet( ...
    "ParentID",     "parent_folder_id",     "string", ...
    "ParentPath",   "parent_folder_path",   "path", ...
    "UnlockAt",     "unlock_at",            "datetime", ...
    "LockAt",       "lock_at",              "datetime", ...
    "Locked",       "locked",               "boolean", ...
    "Hidden",       "hidden",               "boolean", ...
    "Position",     "position",             "integer");

form = buildBody("post", opts, argSet, FirstArgs=RequiredArgs);

[folder, status, resp] = postPayload(obj, url, form);

end
