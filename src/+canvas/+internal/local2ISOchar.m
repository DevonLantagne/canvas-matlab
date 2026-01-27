function timechar = local2ISOchar(localDT)

if ~isa(localDT, 'datetime')
    error('Input must be a datetime object');
end

% If datetime has no timezone, assume system local timezone
if isempty(localDT.TimeZone)
    localDT.TimeZone = 'local';
end

% Format with ISO 8601 and timezone offset (±hh:mm)
localDT.Format = 'yyyy-MM-dd''T''HH:mm:ssXXX';
timechar = char(localDT);

end
