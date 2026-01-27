function [students, status, resp] = getStudents(obj, qopts, opts)
%GETSTUDENTS Retrieve all active students enrolled in the course
%   students = getStudents(obj) fetches active enrolled students in the current course.
%
%   Optional name-value pairs:
%       GetAvatar - if true, includes avatar URLs in the response

arguments
    obj (1,1) Canvas

    qopts.Search string = []
    qopts.Sort (1,1) string {mustBeMember(qopts.Sort, ...
        ["username", "last_login", "email", "sis_id"])} = "username"
    qopts.EnrollmentType string {mustBeMember(qopts.EnrollmentType, ...
        ["teacher", "student", "student_view", "ta", "observer", "designer"])} = "student"
    qopts.UserIDs (1,:) string = []
    qopts.EnrollmentState (1,:) string {mustBeMember(qopts.EnrollmentState, ...
        ["active", "invited", "rejected", "completed", "inactive"])} = "active"

    opts.GetAvatar (1,1) logical = false
    opts.GetBio (1,1) logical = false
    opts.GetTestStudent (1,1) logical = false
end

endpoint = "search_users";
url = obj.buildURL(endpoint);

ExtraQueryArgs = {...
    'per_page',     obj.perPage, ...
    'include[]',    'enrollments'};

if opts.GetAvatar
    ExtraQueryArgs = [ExtraQueryArgs, {'include[]', 'avatar_url'}];
end
if opts.GetBio
    ExtraQueryArgs = [ExtraQueryArgs, {'include[]', 'bio'}];
end
if opts.GetTestStudent
    ExtraQueryArgs = [ExtraQueryArgs, {'include[]', 'test_student'}];
end

argSet = buildArgSet( ...
    "Search",           "search_term",          "string", ...
    "Sort",             "sort",                 "string", ...
    "EnrollmentType",   "enrollment_type[]",    "string", ...
    "UserIDs",          "user_ids[]",           "integer", ...
    "EnrollmentState",  "enrollment_state[]",   "string");

queries = buildBody("get", qopts, argSet, LastArgs=ExtraQueryArgs);

[students, status, resp] = getPayload(obj, url, queries);

% Modify data output by relocating enrollment section (if it is
% in the response)
if isfield(students, "enrollments")
    for n = 1:length(students)
        enroleCode = students(n).enrollments.sis_section_id;
        students(n).section = extractAfter(enroleCode, '-');
    end
end

students = Chars2StringsRec(students);
end
