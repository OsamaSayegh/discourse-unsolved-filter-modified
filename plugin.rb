# name: discourse-unsolved-filter-modified
# about: A modified verions of discourse-unsolved-filter to support modified verions of the official Solved plugin
# version: 0.2
# authors: Osama Sayegh
# url: https://github.com/OsamaSayegh/discourse-unsolved-filter-modified

Discourse.filters << :unsolved
Discourse.filters << :'myunsolved'
Discourse.anonymous_filters << :unsolved

after_initialize do
  module ::UnsolvedFilter
    def self.get_unsolved_topics(topics)
      topics = topics.where("topics.id NOT IN (
        SELECT tc.topic_id
        FROM topic_custom_fields tc
        WHERE (tc.name = 'accepted_answer_post_id' AND tc.value IS NOT NULL) OR
        (tc.name = 'accepted_answer_post_ids' AND tc.value IS NOT NULL) OR
        (tc.name = 'solved_state' AND tc.value = 'solved')
      ) OR topics.id IN (
        SELECT tc.topic_id
        FROM topic_custom_fields tc
        WHERE tc.name = 'solved_state' AND (tc.value = 'unsolved')
      ) AND topics.id NOT IN (
        SELECT tc.topic_id
        FROM topic_custom_fields tc
        WHERE (tc.name = 'solved_state' AND tc.value = '') AND tc.topic_id NOT IN (
          SELECT tc.topic_id
          FROM topic_custom_fields tc
          WHERE ((tc.name = 'accepted_answer_post_ids' OR tc.name = 'accepted_answer_post_id')
          AND tc.value IS NOT NULL)
        )
      )").where("topics.id NOT IN (
        SELECT cats.topic_id
        FROM categories cats WHERE cats.topic_id IS NOT NULL
      )")

      if !SiteSetting.allow_solved_on_all_topics
        topics = topics.where("topics.category_id IN (
          SELECT ccf.category_id
          FROM category_custom_fields ccf
          WHERE ccf.name = 'enable_accepted_answers' AND
          ccf.value = 'true'
        )")
      end
      topics
    end
  end

  TopicQuery.class_eval do
    def list_unsolved
      create_list(:unsolved) do |topics|
        ::UnsolvedFilter::get_unsolved_topics(topics)
      end
    end
    def list_myunsolved
      create_list(:'myunsolved') do |topics|
        ::UnsolvedFilter::get_unsolved_topics(topics).where("topics.user_id = #{@user.id}")
      end
    end
  end
end
