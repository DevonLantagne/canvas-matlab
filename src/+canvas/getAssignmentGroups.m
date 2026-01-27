function [asmt_grps, status, resp] = getAssignmentGroups(obj)
%getAssignmentGroups Retrieve all assignments groups in the current Canvas course
%   asmt_grps = getAssignmentGroups(obj) returns a struct array
%   of assignment groups available in the configured course.
%   Also returns the assignments within those groups.

endpoint = "assignment_groups";
url = buildURL(obj, endpoint, ...
    {'per_page',    obj.perPage, ...
    'include[]',   'assignments'});

[asmt_grps, status, resp] = getPayload(obj, url);
if isempty(asmt_grps); return; end

% Force "assignments" to be structs
asmt_grps = forceStruct(asmt_grps, "assignments");
asmt_grps = Chars2StringsRec(asmt_grps);

% Add field for percentage of final grade
totalWeight = sum([asmt_grps.group_weight]);
for n = 1:length(asmt_grps)
    asmt_grps(n).group_weight_perc = ...
        asmt_grps(n).group_weight ./ totalWeight;
end
end
