function goodRemove = tokenRemove()
% Removes tokens from host system (cred managers and
% secrets.json).

if ismac
    % Check the 'secrets' service
    disp('secrets service not yet implemented')
    goodRemove = false;

elseif isunix
    % Don't even bother with a credential manager for now. Only
    % use secrets.json
    goodRemove = false;

elseif ispc
    % Use Windows Credential Manager (via Powershell)
    cmd = [
        'powershell -NoProfile -Command ' ...
        '"Try { ' ...
        'Remove-StoredCredential -Target ''' Canvas.credTarget ''' -ErrorAction Stop ' ...
        '} Catch { exit 1 }"'
        ];

    status = system(cmd);

    if status ~= 0
        warning('No Canvas credential found to delete.');
        goodRemove = false;
    else
        goodRemove = true;
    end

else
    disp('Platform not supported')
    goodRemove = false;
end

end
