"""Service layer: file + database workflows that sit behind the CLI.

Services own the "documents on the command line" logic (reading Markdown from
DOCUMENTS_FOLDER_PATH, validating frontmatter, upserting records, writing ids
back to files). CLI commands are thin wrappers that only handle I/O.
"""
