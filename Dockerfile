FROM rranshous/simpleagent

ADD robogachi.rb /app/robogachi.rb
ADD Gemfile /app/Gemfile-alt

RUN cat Gemfile-alt >> Gemfile
RUN bundle install

ENTRYPOINT ["bundle", "exec", "ruby", "robogachi.rb"]
