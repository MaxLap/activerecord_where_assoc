# frozen_string_literal: true

module ActiveRecordWhereAssoc
  class MySQLIsTerribleError < StandardError
  end

  class LimitFromThroughScopeError < StandardError
  end

  class OffsetFromThroughScopeError < StandardError
  end
end
