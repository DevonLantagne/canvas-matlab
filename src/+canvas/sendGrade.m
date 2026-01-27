function [submission, status, resp] = sendGrade(obj, assignmentID, studentID, opts)
%%SENDGRADE Sends instructor feedback and grade to a student's submission.
%   Can also send additional information with the grade posting
%   such as comments or files. At least one optional argument
%   must be provided.
%
%   Optional Arguments:
%   Grade - A grade to be given for the submission:
%       Floating point value "13.5" is absolute points;
%       A percentage "40%";
%       Letter grade "B" will be given the highest percentage
%           for that letter.
%       Pass/Fail "pass", "complete", "fail", "incomplete" will
%           grant 100% or 0%.
%   Comment - A string of text to post as a simple comment.
%
arguments
    obj (1,1) Canvas
    assignmentID (1,1) string
    studentID (1,1) string
    opts.Grade (1,1) string = []
    opts.Comment (1,1) string = []
    opts.FileNames (:,1) string = []
end
error("Not fully implemented or tested")

submission = [];
status = [];
resp = [];

endpoint = "assignments/" + assignmentID + "/submissions/" + studentID;
url = buildURL(obj, endpoint);

formArgs = {}

% Append new grade
if ~isempty(opts.Grade)
    formArgs = [formArgs, {"submission[posted_grade]", string(opts.Grade)}];
end

% Append comment
if ~isempty(opts.Comment)
    formArgs = [formArgs, {"comment[text_comment]", opts.Comment}];
end

% Append files
if ~isempty(opts.FileNames)
    for fileName = opts.FileNames
        % Upload File
        [file, status, resp] = uploadFile(obj, "comment", fileName,...
            AssignmentID=assignmentID, StudentID=studentID);
        if isempty(file)
            return
        end
        % Attach ID to request arguments
        formArgs = [formArgs, {"comment[file_ids][]", file.id}];
    end
end

if isempty(formArgs)
    warning("No form entries")
    return
end

form = matlab.net.http.io.FormProvider(formArgs{:});
[submission, status, resp] = putPayload(obj, url, form);

end
