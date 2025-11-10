# Canvas Class for MATLAB

This MATLAB class provides a lightweight interface for interacting with the
 [Canvas LMS REST API](https://canvas.instructure.com/doc/api/) from within
 MATLAB. It supports secure access using API tokens and provides methods to
 retrieve course-related data such as students, assignments, and 
submissions.\
\
This project is currently under heavy development!

## Features

- Get active students and their enrollment sections
- Fetch all assignments and submissions in a course
- Add modules and module items.
- Automatically handles paginated results from Canvas API
- Modular and extensible for additional Canvas API features

## Requirements

- MATLAB R2021b or newer
- Access to a Canvas course and a valid API token
- Knowledge of your course's Canvas `courseID` and base API URL (usually `https://yourschool.instructure.com/api/v1` or your institution-specific URL)

## Installation

### For Regular Users
Download and place the `Canvas.m` file in your MATLAB path or working directory. That's it! 🍷

### For Developers

You will want a test instance or test course on Canvas. You can also spin up your own
containerized instance of Canvas using Docker.

First, clone the repo. You can also execute from MATLAB by adding ! before the command.

```bash
git clone https://github.com/DevonLantagne/canvas-matlab.git
```

Create a `.env` file from the `example.env` file and replace values. `testURLsGET.m` will read the `.env` with the `read_env.m` function.

## Usage

### 1. Create a Canvas API token

Log into your Canvas account, go to your account settings, and generate a new access token. Keep it safe! Consider setting an expiration date.

### 2. Get your Course ID

Navigate to the Canvas course you would like to interface. Check the URL in your browser and find the number after "courses" - this is the Course ID.

### 3. Create a Canvas object in MATLAB

```matlab
% Canvas(baseURL, API_Token, CourseID)
api = Canvas("https://yourschool.instructure.com/api/v1", "your_token_here", "12345");
```

If no errors occur, the `api` variable will be the interface object. You can call methods from this object to perform tasks.

## Notes

- Currently, only GET endpoints are supported and posting grades is under development.

## Security

🚨 **Never hardcode your token in shared or public files.** Use secure methods to load credentials when using this in production workflows.

## API Reference

Use MATLAB's build-in docstring viewer to get help on any method or property.
```matlab
doc Canvas
doc Canvas.getStudents
% Or use the help command
help Canvas
help Canvas.getStudents
```

Most methods return structures defined by the Canvas API which can be found
[here](https://developerdocs.instructure.com/services/canvas/file.all_resources).

### Methods
You can call methods from the interface object you created earlier. For example:
```matlab
StudentList = api.getStudents();
% or
StudentList = getStudents(api);
```
Consult the MATLAB `help` or `doc` functions for more information for each method.
