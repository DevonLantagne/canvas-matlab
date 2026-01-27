function [file, status, resp] = uploadFile(obj, uploadType, fullFileName, opts)
%UPLOADFILE Uploads a file to Canvas and returns the file's ID.
%   The uploadType controls the file permissions. If uploadType
%   is the following:
%       "files" - generic file upload. User can supply which
%       folder to place the file using FolderID or FolderPath.
%       If none is provided, the file will be placed in the
%       default folder "unfiled".
%       "comment" - a file used to attach to a student's
%       assignment submission. The use MUST supply the
%       AssignmentID and the StudentID.
%

% TODO: Split folder and endpoint args, use argSet

arguments
    obj (1,1) Canvas
    uploadType (1,1) string {mustBeMember(uploadType, ["files", "comment"])}
    fullFileName (1,1) string
    opts.FolderID (1,1) string = ""
    opts.FolderPath (1,1) string = ""
    opts.AssignmentID (1,1) string = ""
    opts.StudentID (1,1) string = ""
end

switch uploadType
    case "files"
        % Check requirements
        if opts.FolderID ~= "" && opts.FolderPath ~= ""
            error("ParentID and ParentPath are mutually exclusive.")
        end
        % Set endpoint
        endpoint = "files";

    case "comment"
        error("Untested and unsafe!")
        % Check requirements
        if opts.AssignmentID=="" || opts.StudentID==""
            error("If using ""comment"", you must also provide AssignmentID and StudentID.")
        end
        % Set endpoint
        endpoint = "assignments/" + opts.AssignmentID + ...
            "/submissions/" + opts.StudentID + "/files";
end

% Get information about the file the user wants to upload
fileInfo = dir(fullFileName);
if isempty(fileInfo)
    error("No such file or directory for\n%s", fullFileName)
end
fileName = fileInfo.name;
fileSize = fileInfo.bytes;

% Step 1: Instruct Canvas to make a file object
% This requires a POST request with multipart/form-data.
url = buildURL(obj, endpoint);

formArgs = {'name', fileName, 'size', num2str(fileSize)};
if opts.FolderID ~= ""
    formArgs = [formArgs, {"parent_folder_id", opts.FolderID}];
end
if opts.FolderPath ~= ""
    opts.FolderPath = sanitizePath(opts.FolderPath);
    formArgs = [formArgs, {"parent_folder_path", opts.FolderPath}];
end
form = matlab.net.http.io.FormProvider(formArgs{:});

[uploadData, status] = postPayload(obj, url, form);

if status.StatusCode ~= matlab.net.http.StatusCode.OK
    file = [];
    return
end

% Parse the response
uploadURL = uploadData.upload_url;
uploadParams = uploadData.upload_params;

% Step 2: Upload the File
% Send a form with all returned args from first request, then
% add the file provider.
multipart = {};
% Add the form fields from Canvas
fields = fieldnames(uploadParams);
for i = 1:numel(fields)
    multipart = [multipart, fields(i), {uploadParams.(fields{i})}];
end
% Add the actual file to the multipart
multipart = [multipart, {'file'}, {matlab.net.http.io.FileProvider(fullFileName)}];

uploadForm = matlab.net.http.io.MultipartFormProvider(multipart{:});

% Send the request to the upload URL (no auth header needed)
[file, status, resp] = postPayload(obj, uploadURL, uploadForm, Header=[]);
if isempty(file); return; end
% Send the request to the upload URL (no auth header needed)
% uploadReq = matlab.net.http.RequestMessage('post', [], uploadForm);
% uploadResp = uploadReq.send(uploadURL);

% Check if good upload:
% Get "location" from response
% if 3XX, perform a GET to the same location to complete the
% upload.
if status.StatusCode == matlab.net.http.StatusCode.Created
    % testURL = matlab.net.URI(uploadResp.location);
    % testReq = matlab.net.http.RequestMessage('GET', obj.headers);
    % testresp = testReq.send(testURL);
else
    error("A non 201 code was returned in the response. Incomplete implementation.")
end

end
