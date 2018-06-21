#!/usr/bin/env python3

"""
urls.py

This script scrapes Motu's working paper directory for a list of working paper
years, numbers and URL suffixes.

Ben Davies
2018 06 06
"""

from bs4 import BeautifulSoup
import re
from urllib.request import urlopen

DIRECTORY_URL = "https://motu.nz/resources/working-papers/"


def get_directory_html():
    """Scrape and clean the HTML from Motu's working paper directory.

    The cleaning procedure is as follows:
        1. Trim whitespace.
        2. Remove horizontal rules.
        3. Collapse <div> blocks.
        4. Skip table of year hyperlinks.
        5. Remove year anchors (<h4> blocks).
        6. Collapse <span> blocks.
        7. Separate <p> blocks with linebreaks.
    """
    page = urlopen(DIRECTORY_URL)
    soup = BeautifulSoup(page, "html.parser")
    raw_html = soup.find("div", attrs={"class": "content__abstract-content"})
    html = ""
    for line in raw_html.decode().split("\n"):
        html += line.strip(" ")
    html = re.sub("<hr/>", "", html)
    html = re.sub("<div.*?>(.*?)</div>", "\\1", html)
    html = html[html.find("<h4>"):]
    html = re.sub("(<h4>.*?</h4>)", "", html)
    html = re.sub("<span.*?>(.*?)</span>", "\\1", html)
    html = re.sub("</p>", "</p>\n", html)
    return html[:-1]  # Ignore final linebreak


def get_url_list(html):
    """Return a comma-separated list of working paper years, numbers and URLs.

    Args:
        html (str): The cleaned HTML for the working paper directory.
    """
    res = "year,number,url\n"
    for line in html.split("\n"):
        line = re.sub("<p>(.*)</p>", "\\1", line)
        year = "20" + line[:2]
        number = re.sub("(\d+).*?(\d+).*", "\\2", line)
        if line.find("<a href") > 0:  # Test for outgoing hyperlink
            url = re.sub(r".*?<a href=\"(.*?)\">.*?</a>.*", "\\1", line)
        else:
            url = ""
        res += "{},{},{}\n".format(year, number, url)
    return res


def main():
    """Run the main program block."""
    html = get_directory_html()
    url_list = get_url_list(html)
    with open("../data/urls.csv", "w") as f:
        f.write(url_list)


# Run the program.
main()
