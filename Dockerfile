FROM rranshous/simpleagent

ADD robogachi.rb /app/robogachi.rb

ENTRYPOINT ["bundle", "exec", "ruby", "robogachi.rb"]
