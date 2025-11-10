function env = read_env(filename)
% Reads a .env file similar to linux environments.
% Returns a structure of env variables and values

    env = struct();

    if ~isfile(filename)
        warning('.env file not found');
        return;
    end

    fid = fopen(filename);

    while ~feof(fid)
        line = strtrim(fgets(fid));
        
        % Ignore empty lines or # comments
        if isempty(line) || startsWith(line, '#')
            continue;
        end
        
        % Extract name and value
        tokens = regexp(line, '^(.*?)=(.*)$', 'tokens');

        if ~isempty(tokens)
            key = strtrim(tokens{1}{1});
            val = strtrim(tokens{1}{2});
            env.(key) = val;
        end
    end

    fclose(fid);
end
