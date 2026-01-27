function body = buildBody(method, argStruct, argSet, opts)
% buildBody generates a query array (if method="get") or generates a
% multipart form (if method="post" or "put").
%
% Use buildArgSet to build a structure to help validate optional arugments
% of the API call.

arguments
    method (1,1) string {mustBeMember(method, ["get", "put", "post"])}
    argStruct struct
    argSet (1,1) struct
    opts.FirstArgs (1,:) cell = {}
    opts.LastArgs (1,:) cell = {}
end

argNames = string(fields(argSet))'; % row vector
bodyCell = {};

for argName = argNames
    % get data
    argValue = argStruct.(argName);

    % guard if no value for this arg
    if isempty(argValue); continue; end

    % guard for "empty" datetime
    if isdatetime(argValue) && isnat(argValue); continue; end

    % Convert any char arrays into strings to avoid bad array check
    if ischar(argValue); argValue = string(argValue); end

    % Process scalar or array
    argInfo = argSet.(argName); % arg type info
    if ~argInfo.array && (length(argValue) > 1)
        error("A vector was supplied instead of a scalar for %s", argName)
    end
    for a = 1:length(argValue)
        % Process value based on type (if needed)
        value = argValue(a);
        switch argInfo.type
            case "string"
                % do nothing
            case "integer"
                value = string(value); % converts a floating point to string format
            case "datetime"
                value = string(local2ISOchar(value));
            case "boolean"
                value = string(value);
            case "path"
                value = sanitizePath(value);
        end
        bodyCell = [bodyCell, {argInfo.key, value}];
    end
end

% Append special args
bodyCell = [opts.FirstArgs, bodyCell, opts.LastArgs];

% Package output
if isempty(bodyCell)
    return
end
switch method
    case "get"
        body = matlab.net.QueryParameter(bodyCell{:});
    case {"put", "post"}
        body = matlab.net.http.io.FormProvider(bodyCell{:});
end

end
