%% GenerateMarkdownDoc.m
%   This script reads the Canvas.m source code as text and parses the
%   docstrings to be written as markdown text.

InputFile = "Canvas.m";
OutputFile = fullfile("dev","markdownMethods.md");

% Read file lines
lines = readlines(InputFile);

% Only consider public methods: methods (Access = public)
% Find the public methods block
publicLines = extractPublicMethodsBlock(lines);





docEntries = [];

for i = 1:length(lines)
    line = strtrim(lines(i));

    % Only search for methods
    if startsWith(line, 'function')

        methodLine = line;
        methodName = extractAfter(methodLine, 'function ');
        methodName = regexp(methodName, '(\w+)\s*=', 'tokens', 'once');
        if isempty(methodName)
            methodName = regexp(methodLine, 'function\s+\w+\s*', 'match', 'once');
        end

        % Backtrack to get docstring
        docBlock = [];
        j = i - 1;
        while j > 0 && startsWith(strtrim(lines(j)), '%')
            docBlock = [strtrim(lines(j)); docBlock];
            j = j - 1;
        end

        if ~isempty(docBlock)
            docEntries(end+1) = struct( ...
                'name', methodName{1}, ...
                'doc', parseDocBlock(docBlock) ...
                );
        end
    end
end





% Function to extract only the lines for public methods
function publicLines = extractPublicMethodsBlock(lines)

publicLines = strings(0);

insidePublicBlock = false;
nestingLevel = 0;

for i = 1:length(lines)
    line = strtrim(lines(i));

    % Start of public methods block
    if contains(line, 'methods') && contains(line, '(Access = public)')
        insidePublicBlock = true;
        nestingLevel = 1;
        publicLines(end+1) = lines(i); % Include the opening line
        continue;
    end

    % Collect all lines in public methods
    if insidePublicBlock
        publicLines(end+1) = lines(i);
        % Adjust nesting level for nested blocks
        if startsWith(line, 'methods') || startsWith(line, 'function')
            nestingLevel = nestingLevel + 1;
        elseif strcmp(line, 'end')
            nestingLevel = nestingLevel - 1;
            if nestingLevel == 0
                insidePublicBlock = false;
            end
        end
    end
end
end