function S = normalizeStruct(cellStructs)
% Converts a 1xN or Nx1 cell array of structs with unequal fields
% into a struct array with all fields present in each element.

if ~iscell(cellStructs)
    S = cellStructs;
    return
end

cellStructs = vertcat(cellStructs(:));

% All unique field names
allFields = [];
for s = cellStructs
    theseFields = string(fieldnames(s{1}));
    allFields = unique([theseFields; allFields]);
end

% Initialize output
N = numel(cellStructs);
S = repmat(struct(), N, 1);

for i = 1:N
    thisStruct = cellStructs{i};
    for f = allFields'
        fname = f{1};
        if isfield(thisStruct, fname)
            S(i).(fname) = thisStruct.(fname);
        else
            S(i).(fname) = [];
        end
    end
end

end
