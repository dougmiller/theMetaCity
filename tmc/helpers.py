from tmc import tmc
from flask import url_for


@tmc.context_processor
def construct_other_articles_series():
    """
    Builds the 'Other articles in this series' section
    :return: Dict with the functions that can be called to generate the menu
    """
    def construct_list(article):
        formatted_article_list_entries = []
        for child in article.parent.children:
            if child != article:
                a = '<li><a href="{}">{}</a></li>'.format(url_for('blog_with_title', url=child.url), child.title)
                formatted_article_list_entries.append(a)
            else:
                a = '<li>{} (this article)</li>'.format(child.title)
                formatted_article_list_entries.append(a)
        return '<nav><ul>' + ''.join(formatted_article_list_entries) + '</ul></nav>'

    return dict(other_articles_list=construct_list)
