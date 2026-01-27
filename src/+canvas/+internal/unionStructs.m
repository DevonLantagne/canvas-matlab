function merged = unionStructs(A, B)
% Merges two struct arrays A and B, handling missing fields.
% Ensures all structs have the same fields before concatenation.

if isempty(A); merged = B; return; end
if isempty(B); merged = A; return; end

% Get all fieldnames
fieldsA = fieldnames(A);
fieldsB = fieldnames(B);
allFields = unique([fieldsA; fieldsB]);

% Pad missing fields in A
for i = 1:numel(A)
    for f = allFields'
        fname = f{1};
        if ~isfield(A(i), fname)
            A(i).(fname) = [];
        end
    end
end

% Pad missing fields in B
for i = 1:numel(B)
    for f = allFields'
        fname = f{1};
        if ~isfield(B(i), fname)
            B(i).(fname) = [];
        end
    end
end

% Concatenate
merged = [A; B];
end
