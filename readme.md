# Canvas Class for MATLAB

This MATLAB class provides a lightweight interface for interacting with the [Canvas LMS REST API](https://canvas.instructure.com/doc/api/) from within MATLAB. It supports secure access using API tokens and provides methods to retrieve course-related data such as students, assignments, and submissions.

## Features

- 🧾 Get active students and their enrollment sections
- 📝 Fetch all assignments and submissions in a course
- 🔐 Token-based authentication with custom headers
- 🔍 Debugging output
- 📡 Automatically handles paginated results from Canvas API
- 👷 Modular and extensible for additional Canvas API features

## Requirements

- MATLAB R2021b or newer
- Access to a Canvas course and a valid API token
- Knowledge of your course's Canvas `courseID` and base API URL (usually `https://yourschool.instructure.com/api/v1` or your institution-specific URL)

## Installation

### For Regular Users
Download and place the `Canvas.m` file in your MATLAB path or working directory. That's it! 🍷

### For Developers

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

### 3. Create a Canvas object

```matlab
% Canvas(baseURL, API_Token, CourseID)
api = Canvas("https://yourschool.instructure.com/api/v1", "your_token_here", "12345");
```

If no errors occur, the `api` variable will be the interface object. You can call methods from this object to perform tasks.

## Notes

- Currently, only GET endpoints are supported.
- POST/PUT methods such as `sendGrade` are stubbed and not functional (to avoid accidental data modifications).
- This is intended for internal use (e.g., grade audits, reporting) rather than real-time LMS modifications.

## Security

🚨 **Never hardcode your token in shared or public files.** Use secure methods to load credentials when using this in production workflows.

## API Reference

Use MATLAB's build-in docstring viewer to get help on any method or property.
```matlab
doc Canvas
```

### Methods
You can call methods from the interface object you created earlier. For example:
```matlab
StudentList = api.getStudents();
```

#### `getStudents(opts)`: 
Get a list of students in the course.\
```matlab
StudentList = api.getStudents();
```
Optional `GetAvatar` includes avatar URLs in the output.
```matlab
StudentList = api.getStudents(GetAvatar=true);
```

#### `getAssignmentGroups()`:
Lists all assignment groups (e.g. Homework, Quizzes, Exams...) and their weights toward the final grade.
```matlab
asmtGrps = api.getAssignmentGroups();
```

#### `getAssignments()`:
Retrieve all course assignments. This does not include any student performance.
```matlab
asmts = api.getAssignments();
```

#### `getAssignment(assignmentID)`:
Retrieve a particular course assignment. This does not include any student performance.\
Use `getAssignments()` to get the list of assignment IDs.
```matlab
asmt = api.getAssignment(12345);
```

#### `getSubmissions(assignmentID)`:
Retrieve all submissions for an assignment. This includes comments of instructors and students as well as a ledger of all submitted content.\
Use `getAssignments()` to get the list of assignment IDs.
```matlab
asmt = api.getSubmissions(12345);
```

#### `downloadSubmissions(assignmentID, downloadsPath)`:
Download all submission attachments for an assignment. This includes comments of instructors and students as well as all submitted content.\
Files that already exist will not be modified except for `comments.txt`.\
Use `getAssignments()` to get the list of assignment IDs.\
`downloadsPath` is a path on your computer to place the downloaded content. If the path does not exist, it will be created.
```matlab
api.downloadSubmissions(12345, "C:\MyFilePath\AssignmentFolder");
```
You can also filter the downloads by section numbers:
```matlab
api.downloadSubmissions(12345, "C:\MyFilePath\AssignmentFolder", Sections=["001", "002"]);
```



