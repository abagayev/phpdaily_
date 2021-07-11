import requests
import random
import scrapy
import tweepy
import os


def describe_function():
    parse_url = 'https://www.php.net/manual/en/indexes.functions.php'
    manual_url = 'https://www.php.net/manual/en'

    # download index and init selector

    data = requests.get(parse_url)
    selector = scrapy.Selector(text=data.content)

    # grab a collection of functions

    functions = []

    for li in selector.css('.index-for-refentry li li'):
        function = li.css('li ::text').get()
        if any(x in function for x in ('::', '\\')):
            continue

        description = li.css('li::text').get().lstrip(' - ')
        href = li.css("a::attr(href)").get()

        functions.append({
            'function': function,
            'description': description,
            'href': href,
        })

    # make a tweet

    choice = random.choice(functions)
    tweet = '{}: {} {}/{}'.format(
        choice.get('function'), choice.get('description'), manual_url, choice.get('href'))

    return tweet


def describe_package():
    parse_url = 'https://packagist.org/explore/popular?page={}'
    manual_url = 'https://packagist.org'

    # download index and init selector

    page = random.randint(1, 100)
    data = requests.get(parse_url.format(page))
    selector = scrapy.Selector(text=data.content)

    # grab a collection of packages

    packages = []

    for li in selector.css('ul.packages li'):
        package = li.css('a::text').get()
        description = li.css('h4 ~ p ::text').get()
        href = li.css("a::attr(href)").get().lstrip('/')

        packages.append({
            'package': package,
            'description': description,
            'href': href,
        })

    # make a tweet

    choice = random.choice(packages)
    tweet = '{}: {} {}/{}'.format(
        choice.get('package'), choice.get('description'), manual_url, choice.get('href'))

    return tweet


def post_tweet(tweet):
    consumer_key = os.environ['TWITTER_CONSUMER_KEY']
    consumer_secret = os.environ['TWITTER_CONSUMER_SECRET']
    access_token = os.environ['TWITTER_ACCESS_TOKEN']
    access_secret = os.environ['TWITTER_ACCESS_SECRET']

    # authorize twitter

    auth = tweepy.OAuthHandler(consumer_key, consumer_secret)
    auth.set_access_token(access_token, access_secret)
    api = tweepy.API(auth)

    # update status

    api.update_status(status=tweet)


def lambda_handler(event, context):
    fortune = random.randint(1, 100)
    if fortune < 70:
        tweet = describe_function()
    else:
        tweet = describe_package()

    post_tweet(tweet)


if __name__ == "__main__":
    lambda_handler(None, None)
