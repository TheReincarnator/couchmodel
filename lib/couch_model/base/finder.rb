
module CouchModel

  # This should extend the Base class to provide basic find methods.
  class Base

    module Finder

      def self.included(base_class)
        base_class.class_eval do
          extend ClassMethods
        end
      end

      module ClassMethods

        def find(id)
          document = new :id => id
          document.load
          document
        end

      end

    end

  end

end