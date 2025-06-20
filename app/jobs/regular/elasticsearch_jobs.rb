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

  class ReindexAllPostsToElasticsearch < Jobs::Base
    def execute(args)
      return unless SiteSetting.elasticsearch_enabled?
      
      begin
        # Load the rake task methods  
        load File.expand_path("../../../lib/tasks/discourse_elasticsearch.rake", __dir__)
        
        Rails.logger.info("Starting Elasticsearch reindex job")
        
        elasticsearch_configure_users
        elasticsearch_configure_posts
        elasticsearch_configure_tags
        elasticsearch_configure_map
        elasticsearch_reindex_posts
        
        Rails.logger.info("Completed Elasticsearch reindex job successfully")
      rescue => e
        Rails.logger.error("Elasticsearch reindex job failed: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        raise e
      end
    end
  end
end
