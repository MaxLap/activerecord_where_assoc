# frozen_string_literal: true

module ActiveRecordWhereAssoc
  class MySQLDoesntSupportSubLimitError < StandardError
  end

  class PolymorphicBelongsToWithoutClasses < StandardError
  end
end
