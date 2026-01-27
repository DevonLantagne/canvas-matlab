function [module, status, resp] = createModule(obj, name, opts)
%
% Default position is at the end.
% UnlockAt should be a datetime object in local time

arguments
    obj (1,1) Canvas
    name (1,1) string
    opts.UnlockAt datetime = NaT
    opts.Position uint16 {mustBeInteger,mustBeGreaterThan(opts.Position, 0)} = []
end

endpoint = "modules";
url = buildURL(obj, endpoint);

RequiredArgs = {"module[name]", name};

% build the form and validate optional arguments
argSet = buildArgSet( ...
    "UnlockAt",     "module[unlock_at]",       "datetime", ...
    "Position",     "module[position]",        "integer");

form = buildBody("post", opts, argSet, FirstArgs=RequiredArgs);

[module, status, resp] = postPayload(obj, url, form);
end
