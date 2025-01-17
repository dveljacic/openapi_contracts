module OpenapiContracts
  # Represents a part or the whole schema
  # Generally even parts of the schema contain the whole schema, but store the pointer to
  # their position in the overall schema. This allows even small sub-schemas to resolve
  # links to any other part of the schema
  class Doc::Schema
    attr_reader :pointer, :raw

    def initialize(raw, pointer = [])
      @raw = raw
      @pointer = pointer.freeze
    end

    # Resolves Schema ref pointers links like "$ref: #/some/path" and returns new sub-schema
    # at the target if the current schema is only a ref link.
    def follow_refs
      if (ref = as_h['$ref'])
        at_pointer(ref.split('/')[1..])
      else
        self
      end
    end

    # Generates a fragment pointer for the current schema path
    def fragment
      pointer.map { |p| URI.encode_www_form_component(p.gsub('/', '~1')) }.join('/').then { |s| "#/#{s}" }
    end

    delegate :dig, :fetch, :keys, :key?, :[], :to_h, to: :resolve

    def at_pointer(pointer)
      self.class.new(raw, pointer)
    end

    def as_h
      resolve
    end

    def resolve
      return @raw if pointer.nil? || pointer.empty?

      pointer.inject(@raw) do |obj, key|
        return nil unless obj

        if obj.is_a?(Array)
          raise ArgumentError unless /^\d+$/ =~ key

          key = key.to_i
        end

        obj[key]
      end
    end

    def navigate(*spointer)
      self.class.new(@raw, (pointer + Array.wrap(spointer)))
    end
  end
end
