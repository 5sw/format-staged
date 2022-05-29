# frozen_string_literal: true

require_relative 'format-staged/job'

##
# FormatStaged module
module FormatStaged
  def self.run(**options)
    Job.new(**options).run
  end
end
