function goodSave = tokenSave(token)
% First tries to save the token to an OS cred manager. If
% fails, tries to save token in secrets.json.
%
% If a target token already exists, it is overwritten!!
%
% Returns true for good save.

token = string(token);

if ismac
    % Check the 'secrets' service
    disp('secrets service not yet implemented')

elseif isunix
    % Don't even bother with a credential manager for now. Only
    % use secrets.json
elseif ispc
    % Use Windows Credential Manager (via Powershell)
    cmd = [
        'powershell -NoProfile -Command ' ...
        '"Try { ' ...
        'New-StoredCredential ' ...
        '-Target ''' Canvas.credTarget ''' ' ...
        '-UserName ''' Canvas.credUserName ''' ' ...
        '-Password ''' token ''' ' ...
        '-Persist LocalMachine | Out-Null ' ...
        '} Catch { exit 1 }"'
        ];
    status = system(cmd);
    if status ~= 0
        goodSave = false;
        disp('Failed to store Canvas token in Windows Credential Manager.');
    else
        goodSave = true;
    end

else
    disp('Platform not supported')
end

end
