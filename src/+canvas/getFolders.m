function [folders, status, resp] = getFolders(obj)
%getFiles Retrieve metadata of all folders on canvas.
arguments
    obj (1,1) Canvas
end

endpoint = "folders";
url = buildURL(obj, endpoint, {'per_page', obj.perPage});

[folders, status, resp] = getPayload(obj, url);
if isempty(folders); return; end
folders = Chars2StringsRec(folders);

% Sort folder tree
[~,index] = sortrows([folders.full_name].');
folders = folders(index);
end
