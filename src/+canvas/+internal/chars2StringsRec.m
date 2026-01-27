function data = Chars2StringsRec(data)
% Recursive search through structure to change char arrays to strings.

if isstruct(data)
    % If it's a structure, recurse through each field
    fields = fieldnames(data);
    for i = 1:numel(fields)
        for j = 1:numel(data)
            fieldValue = data(j).(fields{i});
            data(j).(fields{i}) = Chars2StringsRec(fieldValue);
        end
    end

elseif iscell(data)
    % Recurse through each cell
    for i = 1:numel(data)
        data{i} = Chars2StringsRec(data{i});
    end

elseif ischar(data)
    % Convert char array to string
    data = string(data);
    
end

% Leave other data types (numeric, logical, etc.) untouched
end
