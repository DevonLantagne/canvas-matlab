# Canvas Class for MATLAB

This MATLAB class provides a lightweight interface for interacting with the [Canvas LMS REST API](https://canvas.instructure.com/doc/api/) from within MATLAB. It supports secure access using API tokens and provides methods to retrieve course-related data such as students and assignments.

## Features

- 🧾 Get active students and their enrollment sections
- 📝 Fetch all assignments in a course
- 🔐 Token-based authentication with custom headers
- 🔍 Debugging output with rate-limit awareness
- 📡 Automatically handles paginated results from Canvas API
- 👷 Modular and extensible for additional Canvas API features

## Requirements

- MATLAB R2021b or newer (for the `arguments` block syntax and HTTP interface)
- Access to a Canvas course and a valid API token
- Knowledge of your course's Canvas `courseID` and base API URL (usually `https://canvas.instructure.com/api/v1` or your institution-specific URL)

## Installation

Clone or download this repository. Place the `Canvas.m` file in your MATLAB path or working directory.
Developers may wish to clone the entire repo. Consider using a `.env` file for easy usage.

```bash
git clone https://github.com/your-org/matlab-canvas.git
```

## Usage

### 1. Create a Canvas API token

Log into your Canvas account, go to your account settings, and generate a new access token. Keep it safe! Consider setting an expiration date.

### 2. Create a Canvas object

```matlab
api = Canvas("https://yourschool.instructure.com/api/v1", "your_token_here", "12345");
```

### 3. Get Students

```matlab
students = api.getStudents();
```

Include avatars:

```matlab
students = api.getStudents("GetAvatar", true);
```

### 4. Get Assignments

```matlab
assignments = api.getAssignments();
```

## API Reference

Use MATLAB's build-in docstring viewer.
```matlab
doc Canvas
```

### Constructor

```matlab
obj = Canvas(baseURL, token, courseID, opts)
```

- `baseURL`: Canvas API base URL (string)
- `token`: Your API token (string)
- `courseID`: Course identifier (string)
- `opts.debug`: Optional boolean flag to enable debug output

### Methods

- `getStudents(opts)`: Get a list of students in the course. Optional `opts.GetAvatar` fetches avatar URLs.
- `getAssignments()`: Retrieve all course assignments.
- `sendGrade(assignmentID, studentID, grade)`: Placeholder (not implemented).

## Private/Internal Functions

- `buildURL`: Constructs the course-based endpoint URLs
- `getPayload`: Sends a GET request and handles pagination
- `parseLinkHeader`: Parses Canvas pagination link headers
- `normalizeStruct`, `unionStructs`, `Chars2StringsRec`: Utility functions for struct handling

## Notes

- Currently, only GET endpoints are supported.
- POST/PUT methods such as `sendGrade` are stubbed and not functional (to avoid accidental data modifications).
- This is intended for internal use (e.g., grade audits, reporting) rather than real-time LMS modifications.

## Security

🚨 **Never hardcode your token in shared or public files.** Use secure methods to load credentials when using this in production workflows.

