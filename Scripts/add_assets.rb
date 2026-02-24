#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'SnapDrill.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target_name = 'SnapDrill'
target = project.targets.find { |t| t.name == target_name }

if target
  puts "Found target: #{target.name}"
  
  resources_phase = target.resources_build_phase
  
  # Check if already added (by path)
  existing = resources_phase.files.find { |f| f.file_ref && f.file_ref.path && f.file_ref.path.end_with?('Assets.xcassets') }
  
  if existing
    puts "Assets.xcassets already in Resources phase."
  else
    puts "Adding Assets.xcassets to project and Resources phase..."
    
    # Create a clean Resources group since we can't touch the synced SnapDrill group
    resources_group = project.main_group['Resources'] || project.main_group.new_group('Resources')
    
    # Create reference relative to project root
    file_ref = resources_group.new_file('SnapDrill/Assets.xcassets')
    
    # Add to target
    target.add_resources([file_ref])
    project.save
    puts "Success! Added to Resources build phase."
  end
else
  puts "Error: Could not find target '#{target_name}'."
end
