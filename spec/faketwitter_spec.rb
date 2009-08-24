require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'activesupport'

describe FakeTwitter do
  before(:each) do
    FakeTwitter::TweetFactory.reset
  end

  describe '::register_search' do
    it "registers the twitter search url and the specified query with FakeWeb" do
      # expect
      FakeWeb.should_receive(:register_uri).with(:get, "http://search.twitter.com/search.json?q=%23foo+%22some+string%22", anything)
      # when
      FakeTwitter.register_search('#foo "some string"', {})
    end

    it "uses the provided tweets for the stubbed response" do
      # given
      created_at = Time.parse("Thu, 20 Aug 2009 23:23:09 +0000")
      tweets = [
        {:from_user => "bmabey", :id => 1000, :from_user_id => 100,
         :created_at => created_at, :text => 'making FakeTwitter'}
      ]

      # expect
      expected_json_tweet = <<-EOT
  {
      "text": "making FakeTwitter",
      "to_user_id": null,
      "from_user": "bmabey",
      "id": 1000,
      "from_user_id": 100,
      "iso_language_code": "en",
      "source": "&lt;a href=&quot;http:\/\/twitter.com\/&quot;&gt;web&lt;\/a&gt;",
      "profile_image_url": "http:\/\/s3.amazonaws.com\/twitter_production\/profile_images\/100\/photo.jpg",
      "created_at": "Thu, 20 Aug 2009 23:23:09 +0000"
  }
      EOT

      FakeWeb.should_receive(:register_uri).with do |_, _, fakeweb_return_options|
        json = fakeweb_return_options[:body]
        JSON.parse(json)['results'].first.should == JSON.parse(expected_json_tweet)
      end

      # when
      FakeTwitter.register_search('foo', :results => tweets)
    end

    it "includes the escaped query in the response" do
      FakeWeb.should_receive(:register_uri).with do |_, _, fakeweb_return_options|
        json = fakeweb_return_options[:body]
        JSON.parse(json)['query'].should == "%23foo"
      end

      # when
      FakeTwitter.register_search('#foo')
    end

  end


  describe '::search_response' do
    it "has sane defaults for the other response values" do
      response = FakeTwitter.search_response()
      response.slice(*%w[since_id max_id results_per_page completed_in page query]).should == {
          'since_id' =>   0,
          'max_id'   =>  -1,
          'results_per_page' => 15,
          'completed_in' => 0.008646,
          'page' => 1,
          'query' => ''
      }
    end

    it "sets the max_id based on the highest tweet id in the result set" do
      response = FakeTwitter.search_response(:results => [{:id => 1}, {:id => 100}])
      response['max_id'].should == 100
    end

    it "creates the tweets based on the defined created_at times if possible" do
      response = FakeTwitter.search_response(:results => [
        {'created_at' => Time.now - 100, :text => 'first tweet'},
        {'created_at' => Time.now, :text => 'most recent tweet'}
      ])
      response['results'].first['text'].should == 'most recent tweet'
      response['results'].first['id'].should > response['results'].last['id']
    end


  end



  describe '::new_tweet' do

    it "returns hash of an API compliant tweet with sane defaults" do
      tweet = FakeTwitter.new_tweet({})
      tweet.slice(*%w[text from_user to_user_id iso_language_code source]).should == {
       "text"=>"just some tweet",
       "from_user"=>"jojo",
       "to_user_id"=>nil,
       "iso_language_code"=>"en",
       "source"=>'<a href="http://twitter.com/">web</a>',
      }
    end

    it "auto-increments the tweet ids when they are not provided" do
      FakeTwitter.new_tweet({})['id'].should == 1
      FakeTwitter.new_tweet({})['id'].should == 2
    end

    it "auto-increments user ids when none are provided" do
      FakeTwitter.new_tweet({'from_user' => 'jojo'})['from_user_id'].should == 1
      FakeTwitter.new_tweet({'from_user' => 'krusty'})['from_user_id'].should == 2
    end

    it "assigns a user_id for to_user when needed" do
      FakeTwitter.new_tweet({'to_user' => 'billy'})['to_user_id'].should_not be_nil
    end


    it "resuses the same user id for tweets made for the same user" do
      FakeTwitter.new_tweet({'from_user' => 'jojo'})['from_user_id'].should == 1
      FakeTwitter.new_tweet({'from_user' => 'jojo'})['from_user_id'].should == 1
    end

    it "defaults create_at to Time.now" do
      Time.stub!(:now => 'current time')
      FakeTwitter.new_tweet({})['created_at'].should == 'current time'
    end

    it "bases the default profile_image_url off of the user id" do
      FakeTwitter.new_tweet('from_user_id' => 123)['profile_image_url'].
        should == "http://s3.amazonaws.com/twitter_production/profile_images/123/photo.jpg"
    end

    it "strips leading @s from user names" do
      tweet = FakeTwitter.new_tweet('from_user' => '@james', 'to_user' => '@john')
      tweet['from_user'].should == 'james'
      tweet['to_user'].should == 'john'
    end


  end

end
