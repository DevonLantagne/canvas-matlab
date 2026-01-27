function [module, status, resp] = getModule(obj, moduleID)

arguments
    obj (1,1) Canvas
    moduleID (1,1) string
end

endpoint = "modules/" + moduleID;
url = buildURL(obj, endpoint,...
    {"include[]", "items",...
    "include[]", "content_details"});

[module, status, resp] = getPayload(obj, url);
if isempty(module); return; end
module = forceStruct(module, "items");
module = Chars2StringsRec(module);
end
