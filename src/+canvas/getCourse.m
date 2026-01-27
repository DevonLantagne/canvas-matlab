function [course, status, resp] = getCourse(obj)
%getCourse Returns a Canvas course structure containing information about the course.
%   Description:
%       Returns a course structure from the Canvas API.
%
%   Syntax:
%       [course, status, resp] = getCourse(api)
%
%   Inputs:
%       obj - the Canvas API object.
%
%   Outputs:
%       course -  struct of course information.
%       status -  HTTP status code of the API call.
%       resp -  full HTTP response from the API.
%
%   Examples:
%
%       Get the course structure:
%       courseInfo = api.getCourse;
%
%       Get the course structure and HTTP response code:
%       [courseInfo, status] = api.getCourse;
%
%       Only get the raw HTTP response:
%       [~,~,resp] = api.getCourse;

url = buildURL(obj);
[course, status, resp] = getPayload(obj, url);
course = Chars2StringsRec(course);
end
