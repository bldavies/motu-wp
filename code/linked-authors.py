#!/usr/bin/env python3

"""
linked-authors.py

This script scrapes the landing page for each working paper listed in urls.csv.
It generates a list of working paper years and numbers, and the associated
authors' names and IDs.

Ben Davies
2018 06 07
"""

from bs4 import BeautifulSoup
import re
from urllib.request import urlopen

DOMAIN = "https://motu.nz"


def get_author_list(url_list):
    """Return a comma-separated list of working paper and author attributes.

    Args:
        url_list (str): A comma-separated list of working paper metadata.
    """
    res = "year,number,author_name,author_id\n"
    for item in url_list:
        (year, number, url) = tuple(item.split(","))
        print("Working on WP", number, "from", year)  # Update status
        if url != "":
            authors = get_authors(url)
        else:
            authors = {}
        for key in sorted(authors.keys()):
            (author_name, author_id) = authors[key]
            res += "{},{},{},{}\n".format(year, number, author_name, author_id)
    return res


def get_authors(url):
    """Return a dictionary of author (name, id) pairs for a given working paper.

    Args:
        url (str): The URL suffix for the paper's landing page.
    """
    res = {}
    html = get_metadata_html(url)
    html = re.sub(".*<p><b>Author.*?</b>(.*?)</p>.*", "\\1", html)
    author_links = re.findall("<a.*?</a>", html)
    for i in range(len(author_links)):
        link = author_links[i]
        author_name = re.sub(".*>(.*?)</a>", "\\1", link)
        author_id = re.sub(".*people/(.*?)/.*", "\\1", link)
        res[i] = (author_name, author_id)
    return res


def get_metadata_html(url):
    """Scrape and clean the metadata HTML for a given working paper.

    Args:
        url (str): The URL suffix for the paper's landing page.
    """
    page = urlopen(DOMAIN + url)
    soup = BeautifulSoup(page, "html.parser")
    raw_html = soup.find("div", attrs={"class": "item__infos l-col-3 h-right"})
    html = ""
    for line in raw_html.decode().split("\n"):
        html += line.strip(" \t\n")
    return html


def main():
    """Run the main program block."""
    with open("../data/urls.csv", "r") as f:
        url_list = f.read().strip("\n").split("\n")
    author_list = get_author_list(url_list[1:])
    with open("../data/linked-authors.csv", "w") as f:
        f.write(author_list)


# Run the program.
main()
