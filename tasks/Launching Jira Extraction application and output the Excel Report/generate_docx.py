import os
from docx import Document
from docx.shared import Pt, Inches
from docx.enum.text import WD_ALIGN_PARAGRAPH

def create_docx():
    doc = Document()
    
    # Title Page
    title = doc.add_heading('Jira Extraction Application – Deployment & Testing Guide', 0)
    title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    
    doc.add_paragraph('\n\n\n\n')
    
    author = doc.add_paragraph('Author: Devvrat Mishra')
    author.alignment = WD_ALIGN_PARAGRAPH.CENTER
    
    date = doc.add_paragraph('Date: 2026-09-15')
    date.alignment = WD_ALIGN_PARAGRAPH.CENTER
    
    doc.add_page_break()
    
    # Sections
    doc.add_heading('1. Overview and Purpose', level=1)
    doc.add_paragraph('The Jira Extraction Application extracts issue data and metadata from Jira instances via the Jira REST API v3 (specifically targeting https://glynac.atlassian.net). It transforms the extracted data into structured Pandas DataFrames and generates highly formatted, multi-sheet Excel reports containing both issue details and summary analytics.')
    
    doc.add_heading('2. Architecture', level=1)
    doc.add_paragraph('User / CLI -> jira_extraction.py <-> Jira REST API v3 (glynac.atlassian.net) -> Pandas DataFrame -> Excel Workbook -> Issues / Summary Sheets')
    
    doc.add_heading('3. Prerequisites', level=1)
    p = doc.add_paragraph()
    p.add_run('• Python: 3.12 or higher\n')
    p.add_run('• Docker: 29.x or higher\n')
    p.add_run('• Git: For version control and deployment scripts\n')
    p.add_run('• Nomad: (Optional) For scheduled batch deployment\n')
    p.add_run('• Atlassian API Token: A valid Jira API token with read permissions for the target project.')
    
    doc.add_heading('4. Environment Setup', level=1)
    p = doc.add_paragraph()
    p.add_run('1. Clone the repository and navigate to the application directory.\n')
    p.add_run('2. Create a virtual environment: python -m venv venv\n')
    p.add_run('3. Activate the environment:\n   - Windows: .\\venv\\Scripts\\activate\n   - Linux/macOS: source venv/bin/activate\n')
    p.add_run('4. Install dependencies: pip install -r requirements.txt\n')
    p.add_run('5. Configure .env file based on .env.example')
    
    doc.add_heading('5. Docker Deployment', level=1)
    doc.add_paragraph('The application is fully containerized using a hardened image.\n- Dockerfile: Built on python:3.12-slim, configures a non-root appuser, installs only necessary packages, and sets a volume /app/output for the generated Excel reports.\n- docker-compose: Use docker-compose up to run the application securely.')
    
    doc.add_heading('6. Nomad Periodic Batch Deployment', level=1)
    doc.add_paragraph('To run the extraction automatically, use HashiCorp Nomad.\n- Job File: nomad/jira-extraction.nomad\n- Schedule: Daily cron at 06:00 UTC\n- Secrets: Consul KV secret injection for credentials.\n- Storage: Host volume persistence for generated reports.')
    
    doc.add_heading('7. Deployment Scripts', level=1)
    doc.add_paragraph('Automate deployment and execution across platforms:\n- Windows: deploy.ps1 - Automates venv setup, dependency installation, credential validation, and execution.\n- Linux/macOS: deploy.sh - Bash equivalent for Unix systems.')
    
    doc.add_heading('8. Automated Testing Procedures', level=1)
    doc.add_paragraph('Run the test suite using run_tests.py. The suite (tests/test_jira_extraction.py) covers 8 categories:\n1. Config: Environment variable validation.\n2. Credentials: API token formatting.\n3. Data Transforms: Flattening custom fields and nested JSON.\n4. Sprint Extraction: Parsing agile board details.\n5. Proxy Objects: Testing mock responses.\n6. DataFrame Schema: Column validation and types.\n7. Excel Generation: OpenPyXL formatting and sheet creation.\n8. API Error Handling: HTTP 401/404 handling.\n9. CLI Parsing: Argument validation.\n10. Live Integration: E2E smoke tests.\n11. Project Structure: Ensuring deployment files exist.')
    
    doc.add_heading('9. Usage Examples', level=1)
    doc.add_paragraph('- Default: python jira_extraction.py\n- Custom JQL: python jira_extraction.py --jql "project = DEV AND status = \'In Progress\'"\n- Templates: python jira_extraction.py --template open_bugs\n- Limit: python jira_extraction.py --limit 50\n- Output: python jira_extraction.py --output reports/weekly_status.xlsx')
    
    doc.add_heading('10. Troubleshooting Guide', level=1)
    doc.add_paragraph('- 401 Unauthorized: Ensure JIRA_API_TOKEN is correct and associated with the JIRA_USER email.\n- 404 Not Found: Verify JIRA_URL is correct (https://glynac.atlassian.net) and the project exists.\n- JQL Syntax: If query fails, ensure quotes are correctly escaped and field names are valid in Jira.\n- ModuleNotFoundError: Ensure the virtual environment is activated and pip install -r requirements.txt was run.\n- Excel won\'t open: Ensure no other program is locking the file if regenerating, or check volume mounts in Docker.')
    
    doc.add_heading('11. Project Structure', level=1)
    doc.add_paragraph('├── .env\n├── .env.example\n├── Dockerfile\n├── docker-compose.yml\n├── deploy.ps1\n├── deploy.sh\n├── generate_docx.py\n├── JIRA_EXTRACTION_DEPLOYMENT_AND_TESTING_GUIDE.md\n├── jira_extraction.py\n├── requirements.txt\n├── run_tests.py\n├── nomad/\n│   └── jira-extraction.nomad\n├── tests/\n│   └── test_jira_extraction.py\n└── output/')
    
    output_path = os.path.join(os.path.dirname(__file__), 'Jira_Extraction_Deployment_and_Testing_Guide.docx')
    doc.save(output_path)
    print(f"Saved: {output_path}")

if __name__ == '__main__':
    create_docx()
