function S = forceStruct(S, fieldname)
% Forces a field of heterogenous values to be structs. This is useful when
% canvas returns a field that is sometimes a struct arrray but other times
% it is a cell array.
for n = 1:length(S)
    S(n).(fieldname) = normalizeStruct(S(n).(fieldname));
end
end
