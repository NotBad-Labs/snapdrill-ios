#!/usr/bin/env ruby
require 'xcodeproj'

project = Xcodeproj::Project.open('SnapDrill.xcodeproj')
target = project.targets.find { |t| t.name == 'SnapDrill' }

if target
  puts "Checking Compile Sources phase for Assets.xcassets..."
  sources_phase = target.source_build_phase
  
  to_remove = sources_phase.files.select { |f| f.file_ref && f.file_ref.path && f.file_ref.path.include?('Assets.xcassets') }
  
  if to_remove.any?
    puts "Found #{to_remove.count} incorrect entries in Compile Sources. Removing..."
    to_remove.each { |f| sources_phase.remove_build_file(f) }
    project.save
    puts "Success! Removed Assets.xcassets from Compile Sources."
  else
    puts "No Assets.xcassets found in Compile Sources."
  end
else
  puts "Error: Target SnapDrill not found."
end
