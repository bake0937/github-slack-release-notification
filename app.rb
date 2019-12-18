require 'dotenv'
require './slack_notice_client'
require './github_client'
Dotenv.load

slack = SlackNoticeClient.new
github = GithubClient.new

# 最新のプルリクエストを取得
pr = github.latest_pull_request

github.released_at = "#{Time.now.strftime('%Y-%m-%d %H:%M:%S %z')}"
github.merge_comment = "released at #{github.released_at}\n"
github.pr_number = pr[:number]
github.merge_comment += "pull request: ##{github.pr_number}"
github.tag_name = Time.now.strftime("%Y%m%d-%H%M%S%z")
github.html_url = pr[:html_url]
github.pr_title = pr[:title]
github.body = pr[:body]
github.web_endpoint = github.get_web_endpoint
github.tag_page = "#{github.web_endpoint}#{ENV['GITHUB_REPOSITORY']}/releases/tag/#{github.tag_name}"
github.head_repo_name = pr[:head][:repo][:name]
github.base_ref = pr[:base][:ref]
github.head_ref = pr[:head][:ref]

# Releaseタグを打つ
github.create_release(github.tag_name, github.pr_title, github.merge_comment)
# 該当PRにReleaseした旨をコメント
github.add_comment(github.pr_number, github.tag_name, github.web_endpoint)
# SlackにReleaseを報告
slack.release_notification(github.html_url, github.pr_title, github.body, github.tag_page, github.head_repo_name, github.released_at, github.base_ref, github.head_ref)
