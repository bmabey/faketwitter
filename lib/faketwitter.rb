require 'fakeweb'
require 'cgi'
require File.dirname(__FILE__) + "/core_ext/hash"

module FakeTwitter

  class << self

    def register_search(query, search_options = {})
      return register_searches(query, search_options) if search_options.is_a?(Array)
      escaped_query = CGI.escape(query)
      search_options['query'] = escaped_query
      FakeWeb.register_uri(
        :get,
        search_url(escaped_query),
        fake_web_options(search_options)
      )
    end

    def register_searches(query, rotated_search_options)
      escaped_query = CGI.escape(query)
      search_results = rotated_search_options.map do |search_options|
        search_options['query'] = escaped_query
        fake_web_options(search_options)
      end
      FakeWeb.register_uri(
        :get,
        search_url(escaped_query),
        search_results
      )
    end

    def reset
      FakeWeb.clean_registry
      TweetFactory.reset
    end

    def new_tweet(attributes)
      TweetFactory.create(attributes)
    end

    def search_response(options={})
      SearchResponseFactory.create(options)
    end

    def tweets_from(user)
      TweetFactory.tweets_from(user)
    end

    private

    def search_url(escaped_query)
      "http://search.twitter.com/search.json?q=#{escaped_query}"
    end

    def fake_web_options(search_options)
      {:body => search_response(search_options).to_json}
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
        @tweet_repo = nil
      end

      def create(attributes)
        tweet                       =   DEFAULTS.merge(attributes.stringify_keys)
        clean_user_names(tweet)
        tweet['id']                 ||= counter(:id)
        tweet['from_user_id']       ||= user_id_for(tweet['from_user'])
        tweet['to_user_id']         ||= user_id_for(tweet['to_user'])
        tweet['profile_image_url']  ||= "http://s3.amazonaws.com/twitter_production/profile_images/#{tweet['from_user_id']}/photo.jpg"
        tweet['created_at']         ||= Time.now

        tweet_repo << tweet
        tweet
      end

      def tweets_from(user)
        tweet_repo.select { |tweet| tweet['from_user'] == user }
      end

      private

      def counter(counter_type)
        @counter ||= Hash.new(0)
        @counter[counter_type] += 1
      end

      def user_id_for(user)
        return unless user
        @users ||= {}
        @users[user] ||= counter(:user_id)
      end

      def clean_user_names(tweet)
        ['from_user', 'to_user'].each do |key|
          next unless tweet[key]
          tweet[key].sub!('@','')
        end
      end

      def tweet_repo
        @tweet_repo ||= []
      end

    end
  end

end
