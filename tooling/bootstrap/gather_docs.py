#!/usr/bin/env python3
"""
Documentation gatherer for developer tooling monorepo.
Scans the repository for files with standardized doc comments, extracts context
and documentation, and presents it in an easily copyable format. Optionally
copies directly to clipboard for easy sharing with Claude or other assistants.

Part of a larger developer tools ecosystem designed for rapid prototyping
and cross-platform development.

Created with Claude 3.5 (2024-01-02)
"""

import os
import re
import pyperclip
from pathlib import Path
from typing import Dict, List, Optional
from dataclasses import dataclass

@dataclass
class FileDoc:
    path: str
    description: str
    created_date: Optional[str]
    created_with: Optional[str]

class DocGatherer:
    def __init__(self, root_dir: str):
        self.root_dir = Path(root_dir)
        self.project_context = """
Developer Tools Monorepo Context:
--------------------------------
This is a monorepo designed for rapid prototyping and exploration of various development tools
and utilities. The project aims to provide a consistent development environment across
Windows, OSX, and Linux platforms, with initial focus on Python development, cloud tools (gcloud),
and version control (git).

Key Features:
- Cross-platform compatibility
- Idempotent installations
- Version management
- Automated environment setup
- Self-documenting codebase

Initial implementation includes environment bootstrapping with cross-platform support
and version-checked installations of core development tools.

All generated scripts should follow the pattern that is already established,
so that our automated documentation gatherer continues to be useful for
sending context to LLMs for further development.
"""

    def extract_doc_comment(self, file_path: Path) -> Optional[FileDoc]:
        try:
            content = file_path.read_text()
            
            # Handle different comment styles
            doc_patterns = [
                r'"""(.*?)"""',           # Python-style
                r'/\*\*(.*?)\*/',         # C-style
                r'<#(.*?)#>',             # PowerShell
                r"'''\s*(.*?)'''",        # Alternative Python-style
            ]
            
            for pattern in doc_patterns:
                match = re.search(pattern, content, re.DOTALL)
                if match:
                    doc_text = match.group(1).strip()
                    
                    # Extract creation info
                    created_with = None
                    created_date = None
                    created_match = re.search(r'Created with (.*?)\((.*?)\)', doc_text)
                    if created_match:
                        created_with = created_match.group(1).strip()
                        created_date = created_match.group(2).strip()
                    
                    return FileDoc(
                        path=str(file_path.relative_to(self.root_dir)),
                        description=doc_text,
                        created_with=created_with,
                        created_date=created_date
                    )
            
            return None
        except Exception as e:
            print(f"Error processing {file_path}: {e}")
            return None

    def gather_docs(self) -> List[FileDoc]:
        docs = []
        for file_path in self.root_dir.rglob('*'):
            if file_path.is_file() and file_path.suffix in ['.py', '.sh', '.ps1']:
                doc = self.extract_doc_comment(file_path)
                if doc:
                    docs.append(doc)
        return docs

    def format_output(self, docs: List[FileDoc]) -> str:
        output = [self.project_context, "\nFile Documentation:\n-------------------"]
        
        for doc in docs:
            output.append(f"\n{doc.path}")
            output.append("-" * len(doc.path))
            output.append(doc.description)
            if doc.created_with and doc.created_date:
                output.append(f"\nCreated with {doc.created_with} ({doc.created_date})")
            output.append("\n")
        
        return "\n".join(output)

def main():
    # Get the root directory (assumes script is in the repo)
    root_dir = Path(__file__).parent.parent.parent
    
    gatherer = DocGatherer(root_dir)
    docs = gatherer.gather_docs()
    formatted_output = gatherer.format_output(docs)
    
    # Print to console
    print(formatted_output)
    
    # Copy to clipboard
    try:
        pyperclip.copy(formatted_output)
        print("\nDocumentation has been copied to clipboard!")
    except Exception as e:
        print(f"\nCouldn't copy to clipboard: {e}")
        print("Please copy the output above manually.")

if __name__ == "__main__":
    main()