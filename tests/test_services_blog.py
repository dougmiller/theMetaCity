"""Blog document-service tests (the 'documents on the CLI' workflow)."""

import os

from tmc.queries import blog as blog_queries
from tmc.services import blog as blog_service


def test_process_markdown_inserts_and_writes_id_back(app, db_session) -> None:
    docs = app.config["DOCUMENTS_FOLDER_PATH"]
    os.makedirs(docs, exist_ok=True)
    filename = "hello-world.md"
    path = os.path.join(docs, filename)
    with open(path, "w", encoding="utf-8") as f:
        f.write("title: Hello World\nurl: hello-world\nblurb: A greeting\ntags: intro, news\n\n# Body\n\nSome content.\n")

    result = blog_service.process_markdown_file(db_session, filename)
    assert result.action == "inserted"
    assert result.title == "Hello World"

    got = blog_queries.blog_by_url(db_session, "hello-world")
    assert got is not None
    assert got.title == "Hello World"
    assert {t.tag for t in got.tags} == {"intro", "news"}

    with open(path, encoding="utf-8") as f:
        first_line = f.readline()
    assert first_line.startswith("id: ")


def test_process_missing_file_raises(app, db_session) -> None:
    import pytest

    with pytest.raises(blog_service.BlogProcessingError):
        blog_service.process_markdown_file(db_session, "does-not-exist.md")
