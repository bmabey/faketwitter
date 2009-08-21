# faketwitter

Factory goodness for twitter search responses wrapped in FakeWeb awesomeness.

<pre>
irb(main):001:0> require 'faketwitter'
=> true
irb(main):002:0> require 'twitter_search'
=> true
irb(main):003:0> FakeTwitter.register_search("#cheese", {:results => [{:text => "#cheese is good"}]})
=> [#<FakeWeb::Responder:0x19792c0 @times=1, @uri="http://search.twitter.com/search.json?q=%23cheese", @options={:body=>"{"results":[{"text":"#cheese is good","from_user":"jojo","to_user_id":null,"id":1,"from_user_id":1,"iso_language_code":"en","source":"&lt;a href=&quot;http:\\/\\/twitter.com\\/&quot;&gt;web&lt;\\/a&gt;","created_at":"Fri, 21 Aug 2009 09:31:27 +0000","profile_image_url":"http:\\/\\/s3.amazonaws.com\\/twitter_production\\/profile_images\\/1\\/photo.jpg"}],"since_id":0,"max_id":1,"results_per_page":15,"completed_in":0.008646,"page":1,"query":"%23cheese"}"}, method:get]
irb(main):004:0> TwitterSearch::Client.new('').query('#cheese')
=> [#<TwitterSearch::Tweet:0x196cef8 @id=1, @text="#cheese is good", @created_at="Fri, 21 Aug 2009 09:31:27 +0000", @to_user_id=nil, @from_user_id=1, @to_user=nil, @source="&lt;a href=&quot;http://twitter.com/&quot;&gt;web&lt;/a&gt;", @iso_language_code="en", @from_user="jojo", @language="en", @profile_image_url="http://s3.amazonaws.com/twitter_production/profile_images/1/photo.jpg">]
irb(main):005:0> 

</pre>

For more information look at the specs.
