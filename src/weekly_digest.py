import requests
import scrapy
import datetime


def parse_tweets():
    parse_url = 'https://nitter.net/phpdaily_/search?f=tweets&since={}&until={}'.format(
        (datetime.datetime.today() - datetime.timedelta(days=7)).strftime("%Y-%m-%d"),
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
        function, description = li.css('.tweet-content ::text').get().split(':', 1)
        href = li.css('.tweet-content a::attr(href)').get()

        tweets.append({
            function, description, href
        })

    return tweets


def lambda_handler(event, context):
    tweet = parse_tweets()
    print(tweet)


if __name__ == "__main__":
    lambda_handler(None, None)
