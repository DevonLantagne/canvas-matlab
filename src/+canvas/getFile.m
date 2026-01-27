function [file, status, resp] = getFile(obj, fileID)
%GETFILE Retrieve metadata of a folder
arguments
    obj (1,1) Canvas
    fileID (1,1) string
end

endpoint = "files/" + fileID;
url = buildURL(obj, endpoint);

[file, status, resp] = getPayload(obj, url);
file = Chars2StringsRec(file);
end
