function links = parseLinkHeader(linkStr)
% Parses a Canvas-style Link header
% Returns a struct with rel names as fields: e.g., links.next, links.last
links = struct;
entries = strsplit(linkStr, ',');

for i = 1:length(entries)
    entry = strtrim(entries{i});
    tokens = regexp(entry, '<([^>]+)>;\s*rel="([^"]+)"', 'tokens');
    if ~isempty(tokens)
        url = tokens{1}{1};
        rel = tokens{1}{2};
        links.(rel) = url;
    end
end
end
