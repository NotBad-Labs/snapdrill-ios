#!/usr/bin/env ruby
require 'xcodeproj'

project = Xcodeproj::Project.open('SnapDrill.xcodeproj')
target = project.targets.find { |t| t.name == 'SnapDrill' }

puts "Target: #{target.name}"
target.build_phases.each do |phase|
  puts "Phase: #{phase.class.name}"
  if phase.is_a?(Xcodeproj::Project::Object::PBXResourcesBuildPhase)
    puts "  Resources:"
    phase.files.each do |file|
        if file.file_ref
           puts "    - #{file.file_ref.name || file.file_ref.path}" 
        else
           puts "    - (nil ref)"
        end
    end
  end
end

group = project.main_group['SnapDrill']
puts "Group 'SnapDrill' class: #{group.class}"
