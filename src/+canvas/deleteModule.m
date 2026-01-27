function [module, status, resp] = deleteModule(obj, moduleID)

arguments
    obj (1,1) Canvas
    moduleID (1,1) string
end

endpoint = "modules/" + moduleID;
url = buildURL(obj, endpoint);

[module, status, resp] = deleteObject(obj, url);

end
