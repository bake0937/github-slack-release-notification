class GithubClient
  require 'octokit'
  require './slack_notice_client'

  attr_accessor :released_at, :merge_comment, :tag_name, :html_url, :pr_title, :body,:tag_page, :head_repo_name, :base_ref, :head_ref, :pr_number, :web_endpoint

  def initialize
    @slack = SlackNoticeClient.new
    @client = Octokit::Client.new(:access_token => ENV['GITHUB_PERSONAL_ACCESS_TOKEN'])
  end

  def latest_pull_request
    begin
      @client.pull_requests(ENV['GITHUB_REPOSITORY'], :state => 'closed', :per_page => 1)[0]
    rescue => exception
      @slack.error_notification("本番リリースしたんだけど、プルリクエスト情報を取ってくるのに失敗しましたよ〜\nAWS Lambdaのコンソールからもう一度実行してみて〜\n```#{exception}```")
    end
  end

  def get_web_endpoint
    @client.web_endpoint
  end

  def create_release(tag_name, pr_title, merge_comment)
    begin
      @client.create_release(ENV['GITHUB_REPOSITORY'], tag_name, name: pr_title, body: merge_comment)
    rescue => exception
      @slack.error_notification("本番リリースしたんだけど、タグ付けに失敗したよ〜\nAWS Lambdaのコンソールからもう一度実行してみて〜\n```#{exception}```")
    end
  end

  def add_comment(pr_number, tag_name, web_endpoint)
    begin
      @client.add_comment(ENV['GITHUB_REPOSITORY'], pr_number, \
      ":hammer_and_pick: 本番にタグ [#{tag_name}](#{web_endpoint}#{ENV['GITHUB_REPOSITORY']}/releases/tag/#{tag_name}) でリリースしたよ〜 :rocket:")
    rescue => exception
      @slack.error_notification("本番リリースしたんだけど、PRにコメント付けるのに失敗したよ〜\n```#{exception}```\nReleaseタグを打つのは成功してるので、ぼくに代わってPRに↓の内容をコピってコメントしておいて〜\n対象PR: #{web_endpoint}#{ENV['GITHUB_REPOSITORY']}/pull/#{pr_number}\nコメント内容:```:hammer_and_pick: 本番にタグ [#{tag_name}](#{web_endpoint}#{ENV['GITHUB_REPOSITORY']}/releases/tag/#{tag_name}) でリリースしたよ〜 :rocket:```")
    end
  end
end
