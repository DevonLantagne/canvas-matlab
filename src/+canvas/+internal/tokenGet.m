function token = tokenGet()
% Obtains the token stored on the device. Will first check
% credential managers and then local secrets.json. If no
% credential or secrets file exists, this function returns [],
% otherwise the token is a string.

% Local Storate per OS:
%   Windows: %APPDATA%\CanvasMATLAB\
%   macOS: ~/Library/Application Support/CanvasMATLAB/
%   Linux: $XDG_CONFIG_HOME/CanvasMATLAB/

token = []; % default

% Check Credential Manager Tools

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
        '$cred = Get-StoredCredential -Target ''' Canvas.credTarget '''; ' ...
        'if ($cred -eq $null) { exit 1 }; ' ...
        '$cred.Password ' ...
        '} Catch { exit 2 }"'
        ];
    [status, output] = system(cmd);
    if status == 0
        token = strtrim(output);
        return
    end
else
    disp('Platform not supported')
end

% Check secrets.json

end
