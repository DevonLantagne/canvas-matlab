function path = localSavePath()
% Return per-user configuration directory for CanvasMATLAB

SaveFolder = 'CanvasMATLAB';

if ispc
    base = getenv('APPDATA');
    if isempty(base)
        error('APPDATA environment variable not set.');
    end

elseif ismac
    home = getenv('HOME');
    if isempty(home)
        error('HOME environment variable not set.');
    end
    base = fullfile(home, 'Library', 'Application Support');

elseif isunix
    base = getenv('XDG_CONFIG_HOME');
    if isempty(base)
        home = getenv('HOME');
        if isempty(home)
            error('Neither XDG_CONFIG_HOME nor HOME are set.');
        end
        base = fullfile(home, '.config');
    end

else
    error('Unsupported platform.');
end

path = fullfile(base, SaveFolder);

end
