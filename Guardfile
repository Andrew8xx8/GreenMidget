# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'rspec', :version => 2, :cli => '--color' do
  watch(/^lib\/green_midget\/(.+)\.rb$/) { |m| "spec/#{m[1]}_spec.rb" }
  watch(/^lib\/green_midget\/models\/(.+)\.rb$/) { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^spec/.+_spec\.rb$})
end
