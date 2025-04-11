# name: discourse-elasticsearch
# about:
# version: 0.2
# authors: imMMX
# url: https://github.com/imMMX

gem "httpclient", "2.8.3"
gem "elastic-transport", "8.4.0"
gem "elasticsearch-api", "8.4.0"
gem "elasticsearch", "8.4.0"

register_asset "stylesheets/variables.scss"
register_asset "stylesheets/elasticsearch-base.scss"
register_asset "stylesheets/elasticsearch-layout.scss"
register_asset "lib/typehead.bundle.js"

enabled_site_setting :elasticsearch_enabled

PLUGIN_NAME ||= "discourse-elasticsearch".freeze

after_initialize do
  load File.expand_path("lib/discourse_elasticsearch/elasticsearch_helper.rb", __dir__)

  # see lib/plugin/instance.rb for the methods available in this context

  module ::DiscourseElasticsearch
    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace DiscourseElasticsearch
    end
  end

  require_dependency File.expand_path("app/jobs/regular/elasticsearch_jobs.rb", __dir__)
  require_dependency "discourse_event"

  require_dependency "application_controller"
  class DiscourseElasticsearch::ActionsController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    before_action :ensure_logged_in

    def list
      render json: success_json
    end
  end

  DiscourseElasticsearch::Engine.routes.draw { get "/list" => "actions#list" }

  Discourse::Application.routes.append do
    mount ::DiscourseElasticsearch::Engine, at: "/discourse-elasticsearch"
  end

  %i[user_created user_updated].each do |discourse_event|
    DiscourseEvent.on(discourse_event) do |user|
      if SiteSetting.elasticsearch_enabled?
        Jobs.enqueue_in(
          0,
          :update_elasticsearch_user,
          user_id: user.id,
          discourse_event: discourse_event,
        )
      end
    end
  end


=begin
  Note: When a topic is updated, all its posts are reindexed. 

  Posts are reindxed when: 
  * Post is created -> post_created
  * Post is edited. -> post_edited && !is_first_post
  * Post is destroyed -> post_destroyed && !is_first_post
  * Post is recovered -> post_recovered && !is_first_post

  Topics are reindexed when: 
  * Topic is edited -> post_edited && is_first_post && topic_changed
  * Topic is destroyed -> post_desroyed && is_first_post
  * Topic is recovered -> post_recovered && is_first_post

  * Topic : make personal message -> post_edited + topic_changed
  * Topic : make public(from personal) -> post_edited + topic_changed

  * Topic: list -> post_created && post.action_code == visible.enabled
  * Topic: unlist -> post_created && post.action_code == visible.disabled
=end

  # %i[
  #   topic_destroyed
  #   topic_recovered
  #   topic_published
  #   topic_created
  #   post_moved
  #   post_created
  #   post_edited
  #   post_recovered
  #   post_destroyed
  # ].each do |discourse_event|
  #   on(discourse_event) do |topic|
  #     print("Got Event #{discourse_event} #{topic.id}  \n")
  #     puts
  #   end
  # end

  on(:post_created) do |post|
    if post.action_code == "visible.enabled" || post.action_code == "visible.disabled" 
      Jobs.enqueue_in(0, :update_elasticsearch_topic, topic_id: post.topic_id, discourse_event: :post_created)
    else
      Jobs.enqueue_in(0, :update_elasticsearch_post, post_id: post.id, discourse_event: :post_created)
    end
  end

  on(:post_edited) do |post, topic_changed|
    if post.post_number == 1 && topic_changed
      Jobs.enqueue_in(
        0,
        :update_elasticsearch_topic,
        topic_id: post.topic_id,
        discourse_event: :post_edited,
      )
    else
      Jobs.enqueue_in(
        0,
        :update_elasticsearch_post,
        post_id: post.id,
        discourse_event: :post_edited,
      )
    end
  end

  %i[post_destroyed post_recovered].each do |discourse_event|
    on(discourse_event) do |post|
      if post.post_number == 1
        Jobs.enqueue_in(
          0,
          :update_elasticsearch_topic,
          topic_id: post.topic_id,
          discourse_event: discourse_event,
        )
      else
        Jobs.enqueue_in(
          0,
          :update_elasticsearch_post,
          post_id: post.id,
          discourse_event: discourse_event,
        )
      end
    end
  end
end
