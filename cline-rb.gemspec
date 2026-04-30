require_relative 'lib/cline/version'

Gem::Specification.new do |spec|
  spec.name          = 'cline-rb'
  spec.version       = Cline::VERSION
  spec.summary       = 'Ruby bindings on the Cline ecosystem (CLI, skills, tasks, config...)'
  spec.homepage      = 'https://github.com/Muriel-Salvan/cline-rb'
  spec.license       = 'BSD-3-Clause'

  spec.author        = 'Muriel Salvan'
  spec.email         = 'muriel@x-aeon.com'

  spec.files         = Dir['*.{md,txt}', '{lib}/**/*']
  spec.executables   = Dir['bin/*'].map { |exe_file| File.basename(exe_file) }
  spec.require_path  = 'lib'

  spec.required_ruby_version = '>= 3.1'

  spec.add_dependency 'json', '~> 2.18'
  spec.add_dependency 'shale', '~> 1.2'
  spec.add_dependency 'zeitwerk', '~> 2.7'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
