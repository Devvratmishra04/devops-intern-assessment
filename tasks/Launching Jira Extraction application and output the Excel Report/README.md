# Jira Extraction Application

A Python application that connects to Jira Cloud, extracts issue data using JQL queries, and generates formatted Excel reports for analysis and stakeholder communication.

## Features

- **Jira API Integration** – Authenticates via API token and retrieves issues using JQL.
- **Full Pagination** – Handles large datasets by fetching issues in batches.
- **Formatted Excel Output** – Generates `.xlsx` files with styled headers, alternating row colors, auto-sized columns, freeze panes, and auto-filters.
- **Summary Sheet** – Automatically calculates metrics (issues by status, priority, type, and assignee).
- **Configurable** – JQL queries, field mappings, and output paths are driven by `config.json`.
- **CLI Support** – Pass custom JQL, templates, limits, and output paths from the command line.
- **Logging** – Timestamped logs for connection status, progress, and errors.

---

## Prerequisites

- Python 3.8 or higher
- A Jira Cloud account with API access
- A Jira API token ([generate one here](https://id.atlassian.com/manage-profile/security/api-tokens))

---

## Quick Start

### 1. Clone or navigate to the project directory

```bash
cd "C:\Internships\devops\tasks\Launching Jira Extraction application and output the Excel Report"
```

### 2. Create and activate a virtual environment

```bash
# Windows
python -m venv venv
venv\Scripts\activate

# Linux / macOS
python3 -m venv venv
source venv/bin/activate
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

### 4. Configure credentials

Edit the `.env` file and replace `PASTE_YOUR_API_TOKEN_HERE` with your actual Jira API token:

```dotenv
JIRA_URL=https://glynac.atlassian.net
JIRA_EMAIL=dvp@glynac.ai
JIRA_API_TOKEN=your-real-api-token
```

> **Security:** The `.env` file is listed in `.gitignore` and will never be committed.

### 5. Run the application

```bash
python jira_extraction.py
```

The Excel report will be saved to the `output/` directory with a timestamp.

---

## Usage Examples

```bash
# Extract all issues (default query from config.json)
python jira_extraction.py

# Custom JQL query
python jira_extraction.py --jql "project = MYPROJ AND status = 'In Progress'"

# Use a saved template
python jira_extraction.py --template open_bugs
python jira_extraction.py --template recent_30_days
python jira_extraction.py --template sprint_active

# Limit results
python jira_extraction.py --limit 50

# Custom output path
python jira_extraction.py --output reports/weekly_report.xlsx

# Combine options
python jira_extraction.py --jql "project = PROJ" --limit 100 --output my_report.xlsx
```

---

## Configuration (`config.json`)

| Key | Description |
|---|---|
| `default_jql` | Default JQL query when no `--jql` or `--template` is provided |
| `max_results_per_page` | Batch size for API pagination (max 100) |
| `output_directory` | Default directory for generated Excel files |
| `fields` | List of Jira fields to extract |
| `report_templates` | Named JQL templates you can invoke with `--template` |

### Built-in Templates

| Template | JQL |
|---|---|
| `all_issues` | All issues across all projects |
| `open_bugs` | Unresolved bugs sorted by priority |
| `recent_30_days` | Issues created in the last 30 days |
| `my_open_issues` | Current user's unresolved issues |
| `sprint_active` | Issues in active sprints |

---

## Excel Report Format

The generated Excel workbook contains two worksheets:

### Issues Sheet
| Column | Description |
|---|---|
| Key | Jira issue key (e.g. PROJ-123) |
| Summary | Issue title |
| Status | Current status |
| Priority | Priority level |
| Issue Type | Bug, Story, Task, etc. |
| Assignee | Assigned team member |
| Reporter | Issue creator |
| Created | Creation date |
| Updated | Last update date |
| Resolved | Resolution date |
| Resolution | Resolution type |
| Labels | Comma-separated labels |
| Components | Comma-separated components |
| Fix Versions | Target fix versions |
| Sprint | Sprint name |
| Original Estimate | Estimated time |
| Remaining Estimate | Remaining time |
| Time Spent | Logged time |
| Age (Days) | Days since creation |

### Summary Sheet
- Total issue count
- Issues by Status
- Issues by Priority
- Issues by Type
- Issues by Assignee (top 15)

---

## Generating a Jira API Token

1. Go to [https://id.atlassian.com/manage-profile/security/api-tokens](https://id.atlassian.com/manage-profile/security/api-tokens)
2. Click **Create API token**
3. Enter a label (e.g. "Jira Extraction App")
4. Click **Create**
5. Copy the token immediately (it is shown only once)
6. Paste it into your `.env` file

---

## Troubleshooting

| Problem | Solution |
|---|---|
| `401 Unauthorized` | Check that `JIRA_EMAIL` and `JIRA_API_TOKEN` are correct in `.env` |
| `404 Not Found` | Verify `JIRA_URL` is correct (e.g. `https://yourcompany.atlassian.net`) |
| `JQL syntax error` | Validate your JQL in Jira's issue search before using it here |
| `No issues found` | The JQL query returned zero results – try a broader query |
| `ModuleNotFoundError` | Make sure the virtual environment is activated and dependencies are installed |
| `Excel file won't open` | Ensure the file isn't already open in Excel when regenerating |

---

## Project Structure

```
├── .env                  # Jira credentials (git-ignored)
├── .env.example          # Template for .env
├── .gitignore            # Git ignore rules
├── config.json           # Application configuration
├── jira_extraction.py    # Main application script
├── requirements.txt      # Python dependencies
├── README.md             # This file
└── output/               # Generated Excel reports (git-ignored)
```

---

## License

Internal use only.
