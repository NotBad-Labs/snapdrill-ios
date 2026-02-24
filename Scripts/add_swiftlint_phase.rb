require 'xcodeproj'

project_path = 'SnapDrill.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target_name = 'SnapDrill'
target = project.targets.find { |t| t.name == target_name }

if target.nil?
  puts "Error: Target #{target_name} not found"
  exit 1
end

phase_name = 'SwiftLint'
# Check if phase exists. Some build phases don't have a 'name' attribute (like SourcesBuildPhase), so we must be careful.
existing_phase = target.build_phases.find do |p| 
  p.isa == 'PBXShellScriptBuildPhase' && p.name == phase_name
end

if existing_phase
  puts "SwiftLint phase already exists."
else
  puts "Adding SwiftLint build phase..."
  # new_shell_script_build_phase automatically adds it to the end
  phase = target.new_shell_script_build_phase(phase_name)
  phase.shell_path = '/bin/sh'
  phase.shell_script = <<-SCRIPT
if [ -z "${CI}" ]; then
  export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"
  if which swiftlint >/dev/null; then
    swiftlint
  else
    echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
  fi
fi
SCRIPT
  
  # Improve positioning: Move before Compile Sources
  target.build_phases.delete(phase)
  
  compile_index = target.build_phases.index { |p| p.isa == 'PBXSourcesBuildPhase' }
  
  if compile_index
    target.build_phases.insert(compile_index, phase)
  else
    target.build_phases.unshift(phase)
  end

  project.save
  puts "SwiftLint build phase added successfully."
end
