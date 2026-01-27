function argSet = buildArgSet(name, key, type)

arguments (Repeating)
    name (1,1) string
    key (1,1) string
    type (1,1) string {mustBeMember(type, ["string", "integer", "boolean", "datetime", "path"])}
end

numArgs = length(name);
argSet = struct();

% For each tripplet, build the argSet
for a = 1:numArgs
    argSet.(name{a}) = struct(...
        "type", type{a}, ...
        "array", endsWith(key{a},"[]"), ...
        "key", key{a});
end

end