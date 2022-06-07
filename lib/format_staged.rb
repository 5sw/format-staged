# frozen_string_literal: true

require_relative 'format-staged/job'
require_relative 'format-staged/version'

##
# FormatStaged module
module FormatStaged
  def self.run(**options)
    Job.new(**options).run
  end
end
