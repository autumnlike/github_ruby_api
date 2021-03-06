#! /usr/bin/env ruby

require 'bundler/setup'
require 'octokit'
require "pry" # 開発用
require "csv"
require "dotenv"

Dotenv.load

# 仕様
#
# 指定ラベルのIssueをCSVにエクスポート
#
# @param 0 repository: リポジトリ
# @param 1 label: 集計するラベル名
# @param 2 ignore_labels: 除外ラベル名(カンマ区切り)
#
# ruby ./get_issues_csv.rb <repository_name> <label> <ignore_labels>

if ARGV.count != 2 && ARGV.count != 3
  puts "引数が違います"
  puts "ruby ./get_reviewed.rb <token> <repository_name> <label> <ignore_labels>"
  puts "ex: ruby ./get_reviewed.rb tokentokentoken username/repository_name label_name"
  puts "ex: ruby ./get_reviewed.rb tokentokentoken username/repository_name label_name 'ignore1, ignore2'"
  exit
end

token = ENV['GITHUB_TOKEN']
repository = ARGV[0]
label_name = ARGV[1]
ignore_labels = []
ignore_labels = ARGV[2].split(',') unless ARGV[2].nil?

rows = [
  ['number', 'state', 'title', 'body', 'created_user', 'assignees', 'labels', 'url', 'created_at', 'created_month', 'closed_at', 'closed_month']
]

client = Octokit::Client.new(access_token: token)
client.auto_paginate = true

client.issues(repository, labels: label_name, state: 'all', sort: 'updated', direction: 'desc').each do |issue|
  next unless issue.pull_request.nil?
  labels = issue.labels.map{ |l| l[:name] }
  assignees = issue.assignees.map{ |a| a[:login] }

  rows << [
    issue.number,
    issue.state,
    issue.title,
    issue.body,
    issue.user.login,
    assignees.join("\n"),
    labels.join("\n"),
    issue.html_url,
    issue.created_at,
    issue.created_at.strftime("%Y%m"),
    issue.closed_at,
    issue.closed_at.nil? ? nil : issue.closed_at.strftime("%Y%m")
  ]

end

csv = CSV.open('tmp/issues_' + label_name + '_' + Time.now.strftime('%Y%m%d') + '.csv','w')
rows.each { |r| csv.puts r }
csv.close
