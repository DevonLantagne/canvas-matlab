function [file, status, resp] = deleteFile(obj, fileID)

arguments
    obj (1,1) Canvas
    fileID (1,1) string
end

endpoint = "files/" + fileID;
url = buildURL(obj, endpoint, {}, UseCourse=false);

[file, status, resp] = deleteObject(obj, url);
end
