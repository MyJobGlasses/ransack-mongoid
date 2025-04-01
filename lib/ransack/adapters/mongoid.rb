require 'ransack/adapters/mongoid/base'
require 'ransack/adapters/mongoid/attributes/attribute'
require 'ransack/adapters/mongoid/table'
require 'ransack/adapters/mongoid/inquiry_hash'

Mongoid::Document.include Ransack::Adapters::Mongoid::Base

Mongoid::Document.singleton_class.prepend(Module.new do
  def included(base)
    super
    base.extend Ransack::Adapters::Mongoid::Base::ClassMethods
  end
end)

case ::Mongoid::VERSION
when /^3\.2\./
  require 'ransack/adapters/mongoid/3.2/context'
else
  require 'ransack/adapters/mongoid/context'
end

Ransack::SUPPORTS_ATTRIBUTE_ALIAS = false
