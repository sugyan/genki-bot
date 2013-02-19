### げんきだしてbot ###

    $ heroku apps:create
    $ heroku config:set TWITTER_CONSUMER_KEY=... TWITTER_CONSUMER_SECRET=... ...
    $ git push heroku master
    $ heroku ps:scale bot=1
