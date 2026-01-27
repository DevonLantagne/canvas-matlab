function [subs, status, resp] = getSubmissions(obj, assignmentID)
%getSubmissions Retrieve all submission metadata for specific assignment
%   subs = getSubmissions(obj, asmtID) returns a struct array of
%   all submissions
arguments
    obj (1,1) Canvas
    assignmentID (1,1) double
end
endpoint = "assignments/" + assignmentID + "/submissions";
url = buildURL(obj, endpoint, ...
    {'per_page', obj.perPage,...
    'include[]', 'submission_comments',...
    'include[]', 'submission_history'});

[subs, status, resp] = getPayload(obj, url);
subs = Chars2StringsRec(subs);
end
