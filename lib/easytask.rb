require 'rubygems'
require 'bundler/setup'
require 'commander/import'
require 'sequel'

program :name, "Easy Task"
program :version, '0.0.1'
program :description, "CLI Task Manager"

db_dir = File.expand_path('~/.easytask')
Dir::mkdir(db_dir) unless Dir.exists? db_dir


DB = Sequel.sqlite("#{db_dir}/tasks.db")

unless DB.table_exists? :tasks
  DB.create_table(:tasks) do
    primary_key :id
    String :description
    Date :due
    Boolean :completed
  end
end

tasks_dataset = DB[:tasks]

command :mk do |create|
  create.syntax = "easytask mk"
  create.description = "Creates a task"
  create.action do |args, options|
    options.description = args.first || ask("Task Description: ")
    options.due_date = args[1] || ask_for_date("Due Date: ")
    tasks_dataset.insert(description: options.description, due: options.due_date, completed: false)
    puts "Task \"#{options.description}\" created"
    puts
    tasks_dataset.order(:completed, :due).each do |task|
      check = task[:completed] ? "\u2713".encode('utf-8') : "\u2716".encode('utf-8')
      puts "#{check} %-20s %-20s %-5s" % [task[:description], task[:due].strftime("%10A [%m/%d]"), "{#{task[:id]}}"]
    end
  end
end

command :ls do |list|
  list.syntax = "easytask ls"
  list.description = "List tasks"
  list.action do |args, options|
    tasks_dataset.order(:completed, :due).each do |task|
      check = task[:completed] ? "\u2713".encode('utf-8') : "\u2716".encode('utf-8')
      puts "#{check} %-20s %-20s %-5s" % [task[:description], task[:due].strftime("%10A [%m/%d]"), "{#{task[:id]}}"]
    end
  end
end

command :rm do |remove|
  remove.syntax = "easytask rm"
  remove.description = "Remove tasks"
  remove.option "--a", 'Remove all tasks'
  remove.action do |args, options|
    tasks = tasks_dataset.map(:description)
    if tasks.empty?
      puts "No tasks to remove"
    elsif options.a
      tasks_dataset.delete
      puts "Removed all tasks"
    else
      options.description = ask_for_array("Task id(s): ")
      options.description.each do |task|
        if tasks_dataset.filter(id: task).first
          tasks_dataset.where(id: task).delete
          puts "Task \"#{task}\" removed"
        else 
          puts "Task \"#{task}\" not found"
        end
      end
    end
    puts
    tasks_dataset.order(:completed, :due).each do |task|
      check = task[:completed] ? "\u2713".encode('utf-8') : "\u2716".encode('utf-8')
      puts "#{check} %-20s %-20s %-5s" % [task[:description], task[:due].strftime("%10A [%m/%d]"), "{#{task[:id]}}"]
    end
  end
end

command :fin do |complete|
  complete.syntax = "easytask fin"
  complete.description = "Mark task complete"
  complete.option "--r", "Unmarks task complete"
  complete.action do |args, options|
    options.descriptions = ask_for_array("Task description(s): ")
    options.descriptions.each do |d|
      if options.r
        tasks_dataset.where(description: d).update(completed: false)
      else
        tasks_dataset.where(description: d).update(completed: true)
      end
    end
    puts
    tasks_dataset.order(:completed, :due).each do |task|
      check = task[:completed] ? "\u2713".encode('utf-8') : "\u2716".encode('utf-8')
      puts "#{check} %-20s %-20s %-5s" % [task[:description], task[:due].strftime("%10A [%m/%d]"), "{#{task[:id]}}"]
    end
  end
end
