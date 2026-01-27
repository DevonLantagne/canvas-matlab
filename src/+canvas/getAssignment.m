function [asmt, status, resp] = getAssignment(obj, assignmentID)
%getAssignment Retrieve a specific assignment in the current Canvas course
%   asmt = getAssignment(obj, asmtID) returns a struct array of
%   an assignment
arguments
    obj (1,1) Canvas
    assignmentID (1,1) double
end

endpoint = "assignments/" + assignmentID;
url = buildURL(obj, endpoint);

[asmt, status, resp] = getPayload(obj, url);
asmt = Chars2StringsRec(asmt);
end
