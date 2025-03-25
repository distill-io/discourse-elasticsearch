module Jobs
  class UpdateElasticsearchUser < Jobs::Base
    def execute(args)
      DiscourseElasticsearch::ElasticsearchHelper.index_user(args[:user_id], args[:discourse_event])
    end
  end

  class UpdateElasticsearchTopic < Jobs::Base
    def execute(args)
      DiscourseElasticsearch::ElasticsearchHelper.index_topic(
        args[:topic_id],
        args[:discourse_event],
      )
    end
  end

  class UpdateElasticsearchTag < Jobs::Base
    def execute(args)
      DiscourseElasticsearch::ElasticsearchHelper.index_tags(args[:tags], args[:discourse_event])
    end
  end

  class UpdateElasticsearchPost < Jobs::Base
    def execute(args)
      DiscourseElasticsearch::ElasticsearchHelper.index_post(args[:post_id], args[:discourse_event])
    end
  end
end
