#!/usr/bin/env python3
"""
Twitter Marketing Automation for @OpenClawKit
Engages with the OpenClaw community authentically
"""

import os
import json
import time
from datetime import datetime
from requests_oauthlib import OAuth1Session

# Load credentials from environment
API_KEY = os.environ.get('TWITTER_API_KEY')
API_SECRET = os.environ.get('TWITTER_API_SECRET')
ACCESS_TOKEN = os.environ.get('TWITTER_ACCESS_TOKEN')
ACCESS_SECRET = os.environ.get('TWITTER_ACCESS_TOKEN_SECRET')

# Create OAuth1 session
twitter = OAuth1Session(
    API_KEY,
    client_secret=API_SECRET,
    resource_owner_key=ACCESS_TOKEN,
    resource_owner_secret=ACCESS_SECRET
)

LOG_FILE = '/Users/nealme/clawd/openclaw-kit/twitter-engagement-log.md'

def log(message):
    """Log activity to file and print"""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    entry = f"[{timestamp}] {message}"
    print(entry)
    with open(LOG_FILE, 'a') as f:
        f.write(entry + '\n')

def verify_credentials():
    """Verify API credentials work"""
    log("🔐 Verifying Twitter API credentials...")
    response = twitter.get("https://api.twitter.com/2/users/me")
    if response.status_code == 200:
        data = response.json()
        username = data['data']['username']
        log(f"✅ Authenticated as @{username}")
        return True
    else:
        log(f"❌ Authentication failed: {response.status_code} - {response.text}")
        return False

def search_tweets(query, max_results=20):
    """Search for recent tweets"""
    log(f"🔍 Searching: '{query}'")
    params = {
        'query': query,
        'max_results': max_results,
        'tweet.fields': 'author_id,created_at,public_metrics',
        'expansions': 'author_id'
    }
    response = twitter.get("https://api.twitter.com/2/tweets/search/recent", params=params)
    
    if response.status_code == 200:
        data = response.json()
        tweets = data.get('data', [])
        log(f"   Found {len(tweets)} tweets")
        return tweets
    else:
        log(f"   ❌ Search failed: {response.status_code}")
        return []

def like_tweet(tweet_id):
    """Like a tweet"""
    # Get my user ID first
    me = twitter.get("https://api.twitter.com/2/users/me").json()
    my_id = me['data']['id']
    
    url = f"https://api.twitter.com/2/users/{my_id}/likes"
    response = twitter.post(url, json={"tweet_id": tweet_id})
    
    if response.status_code == 200:
        log(f"   ❤️  Liked tweet {tweet_id}")
        return True
    elif response.status_code == 403:
        log(f"   ⚠️  Already liked or can't like {tweet_id}")
        return False
    else:
        log(f"   ❌ Like failed: {response.status_code}")
        return False

def retweet(tweet_id):
    """Retweet a tweet"""
    me = twitter.get("https://api.twitter.com/2/users/me").json()
    my_id = me['data']['id']
    
    url = f"https://api.twitter.com/2/users/{my_id}/retweets"
    response = twitter.post(url, json={"tweet_id": tweet_id})
    
    if response.status_code == 200:
        log(f"   🔁 Retweeted {tweet_id}")
        return True
    else:
        log(f"   ❌ Retweet failed: {response.status_code}")
        return False

def post_tweet(text):
    """Post a new tweet"""
    log(f"📝 Posting: {text[:50]}...")
    response = twitter.post("https://api.twitter.com/2/tweets", json={"text": text})
    
    if response.status_code == 201:
        tweet_id = response.json()['data']['id']
        log(f"   ✅ Posted! ID: {tweet_id}")
        return True
    else:
        log(f"   ❌ Post failed: {response.status_code} - {response.text}")
        return False

def main():
    """Main engagement routine"""
    log("\n" + "="*60)
    log("🦞 OpenClawKit Twitter Marketing - Starting")
    log("="*60)
    
    # Verify credentials
    if not verify_credentials():
        log("❌ Exiting - authentication failed")
        return
    
    # Search queries to engage with
    queries = [
        "OpenClaw",
        "local AI assistant",
        "AI terminal setup",
        "Claude desktop alternative"
    ]
    
    liked_count = 0
    retweeted_count = 0
    
    for query in queries:
        tweets = search_tweets(query, max_results=10)
        
        for tweet in tweets[:5]:  # Process top 5 from each search
            tweet_id = tweet['id']
            
            # Like the tweet
            if like_tweet(tweet_id):
                liked_count += 1
                time.sleep(2)  # Rate limiting
            
            # Retweet occasionally (1 in 3)
            if liked_count % 3 == 0 and retweeted_count < 3:
                if retweet(tweet_id):
                    retweeted_count += 1
                    time.sleep(2)
        
        time.sleep(5)  # Pause between searches
    
    log("\n" + "="*60)
    log(f"✅ Engagement complete!")
    log(f"   ❤️  Liked: {liked_count} tweets")
    log(f"   🔁 Retweeted: {retweeted_count} tweets")
    log("="*60)

if __name__ == "__main__":
    main()
