function [asmts, status, resp] = getAssignments(obj)
%GETASSIGNMENTS Retrieve all assignments in the current Canvas course
%   asmts = getAssignments(obj) returns a struct array of assignments
%   available in the configured course.

endpoint = "assignments";
url = buildURL(obj, endpoint, {'per_page', obj.perPage});

[asmts, status, resp] = getPayload(obj, url);
asmts = Chars2StringsRec(asmts);
end
