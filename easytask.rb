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
    Date :due
    Boolean :completed
  end
end

tasks_dataset = DB[:tasks]

command :create do |create|
  create.syntax = "easytask create"
  create.description = "Creates a task"
  create.action do |args, options|
    options.description = args.first || ask("Task Description: ")
    options.due_date = args[1] || ask_for_date("Due Date: ")
    tasks_dataset.insert(description: options.description, due: options.due_date, completed: false)
    puts "Task \"#{options.description}\" created"
  end
  tasks_dataset.order(:due)
end

command :list do |list|
  list.syntax = "easytask list"
  list.description = "List tasks"
  list.action do |args, options|
    tasks_dataset.order(:due).each do |task|
      puts "%-20s #{task[:due].strftime("%A [%m/%d]")}" % task[:description] 
    end
  end
end

command :remove do |remove|
  remove.syntax = "easytask remove"
  remove.description = "Remove tasks"
  remove.option "--A", 'Remove all tasks'
  remove.action do |args, options|
    tasks = tasks_dataset.map(:description)
    if tasks.empty?
      puts "No tasks to remove"
    elsif options.A
      tasks_dataset.delete
    else
      tasks_dataset.where(id: args.first).delete
      puts "Removed: #{args.first}"
    end
  end
end

command :complete do |complete|
  complete.syntax = "easytask complete"
  complete.description = "Mark task complete"
  complete.action do |args, options|
    options.id = ask("Task id's: ")
  end
end
