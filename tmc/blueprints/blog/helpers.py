from flask import url_for

from .bp import bp


@bp.context_processor
def construct_other_articles_series() -> dict:
    """
    Builds the 'Other articles...' sections
    :return: Dict with the functions that can be called to generate the menu
    """

    def construct_blog_list(article) -> str:
        """
        Builds the 'Other articles in this series' section
        :param article: current page article
        :return: Nav UL with other articles in the series with current article not linked and appended with a 'you are here note'
        """
        articles_list = []
        for child in article.parent.children:
            if child != article:
                articles_list.append(f'<li><a href="{url_for("blog.title", url=child.url)}">{child.title}</a></li>')
            else:
                articles_list.append(f'<li class="active_article">{child.title} (this article)</li>')
        return "<nav><ul>" + "".join(articles_list) + "</ul></nav>"

    def construct_workshop_list(article) -> str:
        """
        Builds the 'Other articles in this series' section
        :param article: current page article
        :return: Nav UL with other articles in the series with current article not linked and appended with a 'you are here note'
        """
        articles_list = []
        for child in article.parent.children:
            if child != article:
                articles_list.append(f'<li><a href="{url_for("blog_with_title", url=child.url)}">{child.title}</a></li>')
            else:
                articles_list.append(f"<li>{child.title} (this article)</li>")
        return "<nav><ul>" + "".join(articles_list) + "</ul></nav>"

    return {"other_blog_articles_list": construct_blog_list, "other_workshop_articles_list": construct_workshop_list}
