require 'rubygems'
require 'bundler/setup'
require 'commander/import'
require 'sequel'

program :name, "Easy Task"
program :version, '0.0.1'
program :description, "CLI Task Manager"

DB = Sequel.sqlite('tasks.db')

unless DB.table_exists? :tasks
  DB.create_table(:tasks) do
    primary_key :id
    String :description
    Boolean :completed
  end
end

tasks_dataset = DB[:tasks]

command :create do |create|
  create.syntax = "easytask create"
  create.description = "Creates a task"
  create.option "--description STRING", String, "Description"
  create.action do |args, options|
    options.description = ask("Task Description: ") unless options.description
    tasks_dataset.insert(description: options.description, completed: false)
    puts "Task Created"
  end
end

command :list do |list|
  list.syntax = "easytask list"
  list.description = "List tasks"
  list.action do |args, options|
    tasks_dataset.each do |task|
      puts "#{task[:id]}. #{task[:description]}"
    end
  end
end

command :remove do |remove|
  remove.syntax = "easytask remove"
  remove.description = "Remove tasks"
  remove.action do |args, options|
    tasks = tasks_dataset.map(:description)
    if tasks.empty?
      puts "No tasks to remove"
    else
      choice = choose("Task: ", tasks)
      tasks_dataset.where(description: choice).delete
      puts "Removed: #{choice}"
    end
  end
end
