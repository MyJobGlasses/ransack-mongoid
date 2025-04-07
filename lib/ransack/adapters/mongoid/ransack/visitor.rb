require 'ransack/visitor'

module Ransack
  class Visitor

    def accept(object)
      visit(object)
    end

    def can_accept?(object)
      respond_to? DISPATCH[object.class]
    end

    def visit_Array(object)
      object.map { |o| accept(o) }.compact
    end

    def visit_Ransack_Nodes_Grouping(object)
      if object.combinator == Constants::OR
        visit_or(object)
      else
        visit_and(object)
      end
    end

    def visit_and(object)
      nodes = object.values.map { |o| accept(o) }.compact
      return nil unless nodes.size > 0

      if nodes.size > 1
        # Combine conditions with $and
        { '$and' => nodes }
      else
        nodes.first
      end
    end

    # def visit_and(object)
    #   nodes = object.values.map { |o| accept(o) }.compact
    #   nodes.inject(&:and)
    # end

    def quoted?(object)
      case object
      when Arel::Nodes::SqlLiteral, Bignum, Fixnum
        false
      else
        true
      end
    end

    def visit_or(object)
      nodes = object.values.map { |o| accept(o) }.compact
      return nil unless nodes.size > 0

      if nodes.size > 1
        # Combine conditions with $or
        { '$or' => nodes }
      else
        nodes.first
      end
    end

    def quoted?(object)
      case object
      when Numeric, BSON::ObjectId
        false
      else
        true
      end
    end

    def visit(object)
      send(DISPATCH[object.class], object)
    end

    def visit_Ransack_Nodes_Sort(object)
      if object.valid?
        # MongoDB sort syntax: { field: 1 } for asc, { field: -1 } for desc
        { object.name => (object.dir == 'asc' ? 1 : -1) }
      else
        scope_name = :"sort_by_#{object.name}_#{object.dir}"
        scope_name if object.context.object.respond_to?(scope_name)
      end
    end

    DISPATCH = Hash.new do |hash, klass|
      hash[klass] = "visit_#{
        klass.name.gsub(Constants::TWO_COLONS, Constants::UNDERSCORE)
        }"
    end

    private

      def ordered(object)
        # Convert to MongoDB sort syntax
        field = object.attr.respond_to?(:name) ? object.attr.name : object.attr.to_s
        case object.dir
        when 'asc'.freeze
          { field => 1 }
        when 'desc'.freeze
          { field => -1 }
        end
      end
  end
end
