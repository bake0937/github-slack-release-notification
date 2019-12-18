class SlackNoticeClient
  require 'slack-ruby-client'

  def initialize
    Slack.configure do |config|
      config.token = ENV['SLACK_API_TOKEN']
    end
    @slack_client = Slack::Web::Client.new
  end

  def error_notification(message)
    danger = "#D50200"
    ENV['ERROR_POST_CHANNELS'].split(",").each do |error_post_channel|
      @slack_client.chat_postMessage(username: 'タグ付けに失敗', channel: "##{error_post_channel}", text: message, icon_emoji: ENV['FAIL_EMOJI'])
    end
    exit
  end

  def release_notification(html_url, pr_title, body, tag_page, head_repo_name, released_at, base_ref, head_ref)
    good = "#36a64f"
    release_notice = ''
    File.open("release_notice.json") do |j|
      release_notice = JSON.load(j)
    end

    release_notice[0]["text"]["text"] = "*<#{html_url}|#{pr_title}>*"
    release_notice[1]["text"]["text"] = "------------\n#{body}"
    release_notice[2]["elements"][0]["text"]["text"] = "Go #{ENV['ENVIRONMENT']} Page"
    release_notice[2]["elements"][0]["url"] = "#{ENV['PRODUCT_PAGE']}"
    release_notice[2]["elements"][1]["url"] = tag_page
    release_notice[3]["fields"][0]["text"] = "*Project*\n#{head_repo_name}"
    release_notice[3]["fields"][1]["text"] = "*Released at:*\n#{released_at}"
    release_notice[3]["fields"][2]["text"] = "*Deployed branch*\n#{base_ref}"
    release_notice[3]["fields"][3]["text"] = "*Merged branch*\n#{head_ref}"
    release_notice[3]["fields"][4]["text"] = "*Environment*\n#{ENV['ENVIRONMENT']}"

    ENV['RELEASE_POST_CHANNELS'].split(",").each do |release_post_channel|
      @slack_client.chat_postMessage(username: '本番リリースお知らせベア', channel: "##{release_post_channel}", text: "本番リリースしたよ〜", icon_emoji: ENV['SUCCESS_EMOJI'], attachments: [{blocks: release_notice, color: good}])
    end
  end
end
