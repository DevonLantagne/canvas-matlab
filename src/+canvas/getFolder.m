function [folder, status, resp] = getFolder(obj, folderID)
%GETFOLDER Retrieve metadata of a folder
arguments
    obj (1,1) Canvas
    folderID (1,1) string
end

endpoint = "folders/" + folderID;
url = buildURL(obj, endpoint);

[folder, status, resp] = getPayload(obj, url);
folder = Chars2StringsRec(folder);
end
