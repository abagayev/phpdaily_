import requests
import scrapy
import datetime
from rfeed import *


def build_feed():
    parse_url = 'https://nitter.net/phpdaily_/search?f=tweets&since={}&until={}'.format(
        (datetime.datetime.today() - datetime.timedelta(days=10)).strftime("%Y-%m-%d"),
        datetime.datetime.today().strftime("%Y-%m-%d"),
    )

    headers = {
        # I am so sorry Nitter, but I am here not to bother you too much
        'Accept-Language': 'uk-UA,uk;q=0.8,en-US;q=0.7,en;q=0.6',
        'User-Agent': 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:15.0) Gecko/20100101 Firefox/15.0.1',
    }

    # download page and init selector

    data = requests.get(parse_url, headers=headers)
    selector = scrapy.Selector(text=data.content)

    # grab some tweets

    tweets = []

    for li in selector.css('.timeline .timeline-item'):
        parts = li.css('.tweet-content ::text').get().split(':', 1)
        href = li.css('.tweet-content a::attr(href)').get()

        # can't split or there's no href means this is not a regular post
        if len(parts) < 2 or not href:
            continue

        tweets.append(Item(
            title="{}: {}".format(*[s.strip() for s in parts]),
            link=href,
        ))

    return Feed(
        title="PHP daily feed",
        link="https://twitter.com/phpdaily_",
        description="Daily PHP function, piece of news, library or just a tip.",
        lastBuildDate=datetime.datetime.now(),
        items=tweets)


def lambda_handler(event, context):
    feed = build_feed()
    print(feed.rss())


if __name__ == "__main__":
    lambda_handler(None, None)