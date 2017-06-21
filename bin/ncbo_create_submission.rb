#!/usr/bin/env ruby

# Exit cleanly from an early interrupt
Signal.trap("INT") { exit 1 }

# Setup the bundled gems in our environment
require 'bundler/setup'

# require 'pry'
# require 'pry-nav'
# require 'pry-stack_explorer'


# Configure the process for the current cron configuration.
require_relative '../lib/ncbo_cron'
config_exists = File.exist?(File.expand_path('../../config/config.rb', __FILE__))
abort("Please create a config/config.rb file using the config/config.rb.sample as a template") unless config_exists
require_relative '../config/config'


platform = "local"
if LinkedData.settings.goo_host.include? "stage"
  platform = "stage"
elsif LinkedData.settings.goo_host.include? "prod"
  platform = "prod"
end
puts "Running on #{platform} platform"

if ARGV.length < 2
  puts "Syntax: ./ncbo_create_submission ACRONYM /path/to/ontology administratorUserName"
else

  username = ARGV.pop
  path=ARGV.pop
  acronym=ARGV.pop


  # ontology acronym must be unique
  ont = LinkedData::Models::Ontology.find(acronym.upcase).first

  puts 'Looking for user '+ username
  user = LinkedData::Models::User.find(username).first

  if ont.nil?
    ont = LinkedData::Models::Ontology.new
    ont.acronym = acronym.upcase
    ont.administeredBy = [user]
    ont.name = acronym

    # ontology name must be unique
    ont_names = LinkedData::Models::Ontology.where.include(:name).to_a.map { |o| o.name }
    if ont_names.include?(ont.name)
      puts 'Ontology name is already in use by another ontology.'
    end

    if ont.valid?
      ont.save
    else
      puts "#{ont.errors}"
    end
  end


  sub = ont.latest_submission(status: :any)

  # puts sub.inspect.to_s
  # puts ont.inspect.to_s

  #  pull = NcboCron::Models::OntologyPull.new
  # #
  #  pull.create_submission(ont,sub,path,path.split("/")[-1],logger=nil,
  #                         add_to_pull=true)

  new_sub = LinkedData::Models::OntologySubmission.new
  submission_id = ont.next_submission_id
  file_location = LinkedData::Models::OntologySubmission.copy_file_repository(ont.acronym, submission_id, path, path.split("/")[-1])


  unless sub.nil?
    sub.bring_remaining
    sub.loaded_attributes.each do |attr|
      new_sub.send("#{attr}=", sub.send(attr))
    end
  end


  new_sub.submissionId = submission_id
  new_sub.uploadFilePath = file_location
  new_sub.submissionStatus = [ ]
  new_sub.creationDate = nil
  new_sub.released = DateTime.now
  new_sub.missingImports = nil
  new_sub.metrics = nil
  new_sub.hasOntologyLanguage = LinkedData::Models::OntologyFormat.find('OWL').first
  new_sub.ontology=ont
  contact = LinkedData::Models::Contact.new
  contact.name = 'God'
  contact.email = 'god@universe.org'
  if contact.valid?
    contact.save
  else
    puts "Unable to create contact: #{contact.errors}"
  end
  new_sub.contact = [contact]

  if new_sub.valid?
    new_sub.save
    submission_queue = NcboCron::Models::OntologySubmissionParser.new
    submission_queue.queue_submission(new_sub, {all: true})
    puts "Created a new submission (#{submission_id}) for ontology #{ont.acronym}"
  else
    puts "Unable to create a new submission: #{new_sub.errors}"
  end

end