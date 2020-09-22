import requests
import random
import scrapy
import tweepy
import os

consumer_key = os.environ['TWITTER_CONSUMER_KEY']
consumer_secret = os.environ['TWITTER_CONSUMER_SECRET']
access_token = os.environ['TWITTER_ACCESS_TOKEN']
access_secret = os.environ['TWITTER_ACCESS_SECRET']

parse_url = 'https://www.php.net/manual/en/indexes.functions.php'
manual_url = 'https://www.php.net/manual/en'


def lambda_handler(event, context):
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

    # authorize twitter

    auth = tweepy.OAuthHandler(consumer_key, consumer_secret)
    auth.set_access_token(access_token, access_secret)
    api = tweepy.API(auth)

    # update status

    api.update_status(status=tweet)


if __name__ == "__main__":
    lambda_handler(None, None)
