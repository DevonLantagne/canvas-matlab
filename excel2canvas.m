function excel2canvas(excelFile, canvasToken, courseID, opts)
%% excel2canvas
% This function copies grades from an excel file to Canvas LMS.
%
% Several setup steps must be made prior to using this function.
%
% Excel File:
%
% See example excel file. You will need to include student and assignment
% IDs.
%
% Canvas:
%
% You must make assignments in canvas first before uploading grades. When
% viewing an assignment, take note of the ID number in the URL. You will
% need this ID number in the excel table.
%
%

arguments
    excelFile (1,1) string
    canvasToken (1,1) string
    courseID (1,1) string
    opts.AssignmentIdRow (1,1) double = 2
    opts.AssignmentIdCol double = 3
    opts.StudentIdRow double = 3
    opts.StudentIdCol (1,1) double = 2
end

tbl = readcell(excelFile);
NumCols = size(tbl,2);
NumRows = size(tbl,1);

% Extract assigment IDs
if isscalar(opts.AssignmentIdCol)
    % Assign stop point to end of table col
    opts.AssignmentIdCol(2) = NumCols;
elseif length(opts.AssignmentIdCol) == 2
    % Pass
else
    error('AssignmentIdCol must be the start column number or a 1x2 vector of [start stop].')
end
AssignmentIDs = [tbl{opts.AssignmentIdRow, opts.AssignmentIdCol(1):opts.AssignmentIdCol(2)}];

% Extract student IDs
if isscalar(opts.StudentIdRow)
    opts.StudentIdRow(2) = NumRows;
elseif length(opts.StudentIdRow) == 2
    % Pass
else
    error('StudentIdRow must be the start row number or a 1x2 vector of [start stop].')
end
StudentIDs = [tbl{opts.StudentIdRow(1):opts.StudentIdRow(2), opts.StudentIdCol}];

% Extract scores
Scores = tbl(...
    opts.StudentIdRow(1):opts.StudentIdRow(2), ...
    opts.AssignmentIdCol(1):opts.AssignmentIdCol(2));

% Set Canvas API base URL
baseURL = 'https://msoe.instructure.com/api/v1';
canv = Canvas(baseURL, canvasToken, courseID);

% Loop over each AssignmentID and StudentID
for asmtIdx = 1:length(AssignmentIDs)
    assignmentID = AssignmentIDs(asmtIdx);

    for stIdx = 1:length(StudentIDs)
        studentID = StudentIDs(stIdx);

        score = Scores{stIdx, asmtIdx}; % Extract score
        
        if ismissing(score)
            fprintf("No score for student: '%d' assignment: '%d'\n",...
                studentID, assignmentID)
            continue
        end

        % Send score to Canvas
        fprintf("Uploading student: '%d' assignment: '%d'\n",...
            studentID, assignmentID)
        canv.sendGrade(assignmentID, studentID, score)
    end
end


fprintf('Grade upload complete.\n');
end
