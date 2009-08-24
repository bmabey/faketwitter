require 'fakeweb'
require 'cgi'
require File.dirname(__FILE__) + "/core_ext/hash"

module FakeTwitter

  class << self

    def register_search(query, search_options = {})
      escaped_query = CGI.escape(query)
      search_options['query'] = escaped_query
      FakeWeb.register_uri(
        :get,
        "http://search.twitter.com/search.json?q=#{escaped_query}",
        :body => search_response(search_options).to_json
      )
    end

    def new_tweet(attributes)
      TweetFactory.create(attributes)
    end

    def search_response(options={})
      SearchResponseFactory.create(options)
    end

  end


  class SearchResponseFactory
    DEFAULTS = {
      'results' => [],
      'since_id' => 0,
      'max_id' => -1,
      'results_per_page' => 15,
      'completed_in' => 0.008646,
      'page' => 1,
      'query' => ''
    }

    class << self

      def create(attributes)
        # TODO: remove duplication between factories.
        response =   DEFAULTS.merge(attributes.stringify_keys)
        response['results'] = create_tweets(response['results'].dup)

        unless response['results'].empty?
          response['max_id'] = response['results'].map { |t| t['id'] }.max
        end

        response
      end


      private
      def create_tweets(tweets)
        now = Time.now
        tweets.sort! do |tweet_a, tweet_b|
          (tweet_b['created_at'] || now) <=> (tweet_a['created_at'] || now)
        end
        # We do the reverses so that the id's are auto-incremented correctly
        tweets.reverse!.map! do |tweet_hash|
          tweet = FakeTwitter.new_tweet(tweet_hash)
          # hardcoding +0000 because %z was giving -0700 for UTC for some reason (leopard MRI)..
          tweet['created_at'] = tweet['created_at'].utc.strftime("%a, %d %b %Y %H:%M:%S +0000")
          tweet['source'] = CGI.escapeHTML(tweet['source'])
          tweet
        end

        tweets.reverse!
      end

    end

  end

  class TweetFactory
    DEFAULTS = {
       "text"=>"just some tweet",
       "from_user"=>"jojo",
       "to_user_id"=>nil,
       "iso_language_code"=>"en",
       "source"=>'<a href="http://twitter.com/">web</a>',
    }

    class << self

      def reset
        @counter = nil
        @users = nil
      end

      def create(attributes)
        tweet                       =   DEFAULTS.merge(attributes.stringify_keys)
        clean_user_names(tweet)
        tweet['id']                 ||= counter(:id)
        tweet['from_user_id']       ||= user_id_for(tweet['from_user'])
        tweet['to_user_id']         ||= user_id_for(tweet['to_user'])
        tweet['profile_image_url']  ||= "http://s3.amazonaws.com/twitter_production/profile_images/#{tweet['from_user_id']}/photo.jpg"
        tweet['created_at']         ||= Time.now

        tweet
      end

      def counter(counter_type)
        @counter ||= Hash.new(0)
        @counter[counter_type] += 1
      end

      def user_id_for(user)
        return unless user
        @users ||= {}
        @users[user] ||= counter(:user_id)
      end

      private

      def clean_user_names(tweet)
        ['from_user', 'to_user'].each do |key|
          next unless tweet[key]
          tweet[key].sub!('@','')
        end
      end

    end
  end

end
