function NewPath = sanitizePath(OldPath)
% Canvas only uses forward slashes / for filepath values
NewPath = strrep(OldPath, '\', '/');
end
