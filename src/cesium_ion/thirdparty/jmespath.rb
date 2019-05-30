require 'thread'

module Cesium::IonExporter

module JMESPath
  class CachingParser

    def initialize(options = {})
      @parser = options[:parser] || Parser.new(options)
      @mutex = Mutex.new
      @cache = {}
    end

    def parse(expression)
      if cached = @cache[expression]
        cached
      else
        cache_expression(expression)
      end
    end

    private

    def cache_expression(expression)
      @mutex.synchronize do
        @cache.clear if @cache.size > 1000
        @cache[expression] = @parser.parse(expression)
      end
    end

  end
end
module JMESPath
  module Errors

    class Error < StandardError; end

    class RuntimeError < Error; end

    class SyntaxError < Error; end

    class InvalidTypeError < Error; end

    class InvalidValueError < Error; end

    class InvalidArityError < Error; end

    class UnknownFunctionError < Error; end

  end
end
require 'json'
require 'set'

module JMESPath
  # @api private
  class Lexer

    T_DOT = :dot
    T_STAR = :star
    T_COMMA = :comma
    T_COLON = :colon
    T_CURRENT = :current
    T_EXPREF = :expref
    T_LPAREN = :lparen
    T_RPAREN = :rparen
    T_LBRACE = :lbrace
    T_RBRACE = :rbrace
    T_LBRACKET = :lbracket
    T_RBRACKET = :rbracket
    T_FLATTEN = :flatten
    T_IDENTIFIER = :identifier
    T_NUMBER = :number
    T_QUOTED_IDENTIFIER = :quoted_identifier
    T_UNKNOWN = :unknown
    T_PIPE = :pipe
    T_OR = :or
    T_AND = :and
    T_NOT = :not
    T_FILTER = :filter
    T_LITERAL = :literal
    T_EOF = :eof
    T_COMPARATOR = :comparator

    STATE_IDENTIFIER = 0
    STATE_NUMBER = 1
    STATE_SINGLE_CHAR = 2
    STATE_WHITESPACE = 3
    STATE_STRING_LITERAL = 4
    STATE_QUOTED_STRING = 5
    STATE_JSON_LITERAL = 6
    STATE_LBRACKET = 7
    STATE_PIPE = 8
    STATE_LT = 9
    STATE_GT = 10
    STATE_EQ = 11
    STATE_NOT = 12
    STATE_AND = 13

    TRANSLATION_TABLE = {
      '<'  => STATE_LT,
      '>'  => STATE_GT,
      '='  => STATE_EQ,
      '!'  => STATE_NOT,
      '['  => STATE_LBRACKET,
      '|'  => STATE_PIPE,
      '&'  => STATE_AND,
      '`'  => STATE_JSON_LITERAL,
      '"'  => STATE_QUOTED_STRING,
      "'"  => STATE_STRING_LITERAL,
      '-'  => STATE_NUMBER,
      '0'  => STATE_NUMBER,
      '1'  => STATE_NUMBER,
      '2'  => STATE_NUMBER,
      '3'  => STATE_NUMBER,
      '4'  => STATE_NUMBER,
      '5'  => STATE_NUMBER,
      '6'  => STATE_NUMBER,
      '7'  => STATE_NUMBER,
      '8'  => STATE_NUMBER,
      '9'  => STATE_NUMBER,
      ' '  => STATE_WHITESPACE,
      "\t" => STATE_WHITESPACE,
      "\n" => STATE_WHITESPACE,
      "\r" => STATE_WHITESPACE,
      '.'  => STATE_SINGLE_CHAR,
      '*'  => STATE_SINGLE_CHAR,
      ']'  => STATE_SINGLE_CHAR,
      ','  => STATE_SINGLE_CHAR,
      ':'  => STATE_SINGLE_CHAR,
      '@'  => STATE_SINGLE_CHAR,
      '('  => STATE_SINGLE_CHAR,
      ')'  => STATE_SINGLE_CHAR,
      '{'  => STATE_SINGLE_CHAR,
      '}'  => STATE_SINGLE_CHAR,
      '_'  => STATE_IDENTIFIER,
      'A'  => STATE_IDENTIFIER,
      'B'  => STATE_IDENTIFIER,
      'C'  => STATE_IDENTIFIER,
      'D'  => STATE_IDENTIFIER,
      'E'  => STATE_IDENTIFIER,
      'F'  => STATE_IDENTIFIER,
      'G'  => STATE_IDENTIFIER,
      'H'  => STATE_IDENTIFIER,
      'I'  => STATE_IDENTIFIER,
      'J'  => STATE_IDENTIFIER,
      'K'  => STATE_IDENTIFIER,
      'L'  => STATE_IDENTIFIER,
      'M'  => STATE_IDENTIFIER,
      'N'  => STATE_IDENTIFIER,
      'O'  => STATE_IDENTIFIER,
      'P'  => STATE_IDENTIFIER,
      'Q'  => STATE_IDENTIFIER,
      'R'  => STATE_IDENTIFIER,
      'S'  => STATE_IDENTIFIER,
      'T'  => STATE_IDENTIFIER,
      'U'  => STATE_IDENTIFIER,
      'V'  => STATE_IDENTIFIER,
      'W'  => STATE_IDENTIFIER,
      'X'  => STATE_IDENTIFIER,
      'Y'  => STATE_IDENTIFIER,
      'Z'  => STATE_IDENTIFIER,
      'a'  => STATE_IDENTIFIER,
      'b'  => STATE_IDENTIFIER,
      'c'  => STATE_IDENTIFIER,
      'd'  => STATE_IDENTIFIER,
      'e'  => STATE_IDENTIFIER,
      'f'  => STATE_IDENTIFIER,
      'g'  => STATE_IDENTIFIER,
      'h'  => STATE_IDENTIFIER,
      'i'  => STATE_IDENTIFIER,
      'j'  => STATE_IDENTIFIER,
      'k'  => STATE_IDENTIFIER,
      'l'  => STATE_IDENTIFIER,
      'm'  => STATE_IDENTIFIER,
      'n'  => STATE_IDENTIFIER,
      'o'  => STATE_IDENTIFIER,
      'p'  => STATE_IDENTIFIER,
      'q'  => STATE_IDENTIFIER,
      'r'  => STATE_IDENTIFIER,
      's'  => STATE_IDENTIFIER,
      't'  => STATE_IDENTIFIER,
      'u'  => STATE_IDENTIFIER,
      'v'  => STATE_IDENTIFIER,
      'w'  => STATE_IDENTIFIER,
      'x'  => STATE_IDENTIFIER,
      'y'  => STATE_IDENTIFIER,
      'z'  => STATE_IDENTIFIER,
    }

    VALID_IDENTIFIERS = Set.new(%w(
      A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
      a b c d e f g h i j k l m n o p q r s t u v w x y z
      _ 0 1 2 3 4 5 6 7 8 9
    ))

    NUMBERS = Set.new(%w(0 1 2 3 4 5 6 7 8 9))

    SIMPLE_TOKENS = {
      '.' => T_DOT,
      '*' => T_STAR,
      ']' => T_RBRACKET,
      ',' => T_COMMA,
      ':' => T_COLON,
      '@' => T_CURRENT,
      '(' => T_LPAREN,
      ')' => T_RPAREN,
      '{' => T_LBRACE,
      '}' => T_RBRACE,
    }

    # @param [String<JMESPath>] expression
    # @return [Array<Hash>]
    def tokenize(expression)

      tokens = []
      chars = CharacterStream.new(expression.chars.to_a)

      while chars.current
        case TRANSLATION_TABLE[chars.current]
        when nil
          tokens << Token.new(
            T_UNKNOWN,
            chars.current,
            chars.position
          )
          chars.next
        when STATE_SINGLE_CHAR
          # consume simple tokens like ".", ",", "@", etc.
          tokens << Token.new(
            SIMPLE_TOKENS[chars.current],
            chars.current,
            chars.position
          )
          chars.next
        when STATE_IDENTIFIER
          start = chars.position
          buffer = []
          begin
            buffer << chars.current
            chars.next
          end while VALID_IDENTIFIERS.include?(chars.current)
          tokens << Token.new(
            T_IDENTIFIER,
            buffer.join,
            start
          )
        when STATE_WHITESPACE
          # skip whitespace
          chars.next
        when STATE_LBRACKET
          # consume "[", "[?" and "[]"
          position = chars.position
          actual = chars.next
          if actual == ']'
            chars.next
            tokens << Token.new(T_FLATTEN, '[]', position)
          elsif actual == '?'
            chars.next
            tokens << Token.new(T_FILTER, '[?', position)
          else
            tokens << Token.new(T_LBRACKET, '[',  position)
          end
        when STATE_STRING_LITERAL
          # consume raw string literals
          t = inside(chars, "'", T_LITERAL)
          t.value = t.value.gsub("\\'", "'")
          tokens << t
        when STATE_PIPE
          # consume pipe and OR
          tokens << match_or(chars, '|', '|', T_OR, T_PIPE)
        when STATE_JSON_LITERAL
          # consume JSON literals
          token = inside(chars, '`', T_LITERAL)
          if token.type == T_LITERAL
            token.value = token.value.gsub('\\`', '`')
            token = parse_json(token)
          end
          tokens << token
        when STATE_NUMBER
          start = chars.position
          buffer = []
          begin
            buffer << chars.current
            chars.next
          end while NUMBERS.include?(chars.current)
          tokens << Token.new(
            T_NUMBER,
            buffer.join.to_i,
            start
          )
        when STATE_QUOTED_STRING
          # consume quoted identifiers
          token = inside(chars, '"', T_QUOTED_IDENTIFIER)
          if token.type == T_QUOTED_IDENTIFIER
            token.value = "\"#{token.value}\""
            token = parse_json(token, true)
          end
          tokens << token
        when STATE_EQ
          # consume equals
          tokens << match_or(chars, '=', '=', T_COMPARATOR, T_UNKNOWN)
        when STATE_AND
          tokens << match_or(chars, '&', '&', T_AND, T_EXPREF)
        when STATE_NOT
          # consume not equals
          tokens << match_or(chars, '!', '=', T_COMPARATOR, T_NOT);
        else
          # either '<' or '>'
          # consume less than and greater than
          tokens << match_or(chars, chars.current, '=', T_COMPARATOR, T_COMPARATOR)
        end
      end
      tokens << Token.new(T_EOF, nil, chars.position)
      tokens
    end

    private

    def match_or(chars, current, expected, type, or_type)
      if chars.next == expected
        chars.next
        Token.new(type, current + expected, chars.position - 1)
      else
        Token.new(or_type, current, chars.position - 1)
      end
    end

    def inside(chars, delim, type)
      position = chars.position
      current = chars.next
      buffer = []
      while current != delim
        if current == '\\'
          buffer << current
          current = chars.next
        end
        if current.nil?
          # unclosed delimiter
          return Token.new(T_UNKNOWN, buffer.join, position)
        end
        buffer << current
        current = chars.next
      end
      chars.next
      Token.new(type, buffer.join, position)
    end

    # Certain versions of Ruby and of the pure_json gem not support loading
    # scalar JSON values, such a numbers, booleans, strings, etc. These
    # simple values must be first wrapped inside a JSON object before calling
    # `JSON.load`.
    #
    #    # works in most JSON versions, raises in some versions
    #    JSON.load("true")
    #    JSON.load("123")
    #    JSON.load("\"abc\"")
    #
    # This is an known issue for:
    #
    # * Ruby 1.9.3 bundled v1.5.5 of json; Ruby 1.9.3 defaults to bundled
    #   version despite newer versions being available.
    #
    # * json_pure v2.0.0+
    #
    # It is not possible to change the version of JSON loaded in the
    # user's application. Adding an explicit dependency on json gem
    # causes issues in environments that cannot compile the gem. We previously
    # had a direct dependency on `json_pure`, but this broke with the v2 update.
    #
    # This method allows us to detect how the `JSON.load` behaves so we know
    # if we have to wrap scalar JSON values to parse them or not.
    # @api private
    def self.requires_wrapping?
      begin
        JSON.load('false')
      rescue JSON::ParserError
        true
      end
    end

    if requires_wrapping?
      def parse_json(token, quoted = false)
        begin
          if quoted
            token.value = JSON.load("{\"value\":#{token.value}}")['value']
          else
            begin
              token.value = JSON.load("{\"value\":#{token.value}}")['value']
            rescue
              token.value = JSON.load(sprintf('{"value":"%s"}', token.value.lstrip))['value']
            end
          end
        rescue JSON::ParserError
          token.type = T_UNKNOWN
        end
        token
      end
    else
      def parse_json(token, quoted = false)
        begin
          if quoted
            token.value = JSON.load(token.value)
          else
            token.value = JSON.load(token.value) rescue JSON.load(sprintf('"%s"', token.value.lstrip))
          end
        rescue JSON::ParserError
          token.type = T_UNKNOWN
        end
        token
      end
    end

    class CharacterStream

      def initialize(chars)
        @chars = chars
        @position = 0
      end

      def current
        @chars[@position]
      end

      def next
        @position += 1
        @chars[@position]
      end

      def position
        @position
      end

    end
  end
end

module JMESPath
  # @api private
  module Nodes
    class Node
      def visit(value)
      end

      def hash_like?(value)
        Hash === value || Struct === value
      end

      def optimize
        self
      end

      def chains_with?(other)
        false
      end
    end
    
# KG-dev::RubyPacker replaced for jmespath/nodes/subexpression.rb
# KG-dev::RubyPacker replaced for jmespath/nodes/and.rb
# KG-dev::RubyPacker replaced for jmespath/nodes/comparator.rb
# KG-dev::RubyPacker replaced for jmespath/nodes/comparator.rb
# KG-dev::RubyPacker replaced for jmespath/nodes/condition.rb
# KG-dev::RubyPacker replaced for jmespath/nodes/current.rb
# KG-dev::RubyPacker replaced for jmespath/nodes/expression.rb
# KG-dev::RubyPacker replaced for jmespath/nodes/field.rb
# KG-dev::RubyPacker replaced for jmespath/nodes/flatten.rb
# KG-dev::RubyPacker replaced for jmespath/nodes/function.rb
# KG-dev::RubyPacker replaced for jmespath/nodes/index.rb
# KG-dev::RubyPacker replaced for jmespath/nodes/literal.rb
# KG-dev::RubyPacker replaced for jmespath/nodes/multi_select_hash.rb
# KG-dev::RubyPacker replaced for jmespath/nodes/multi_select_list.rb
# KG-dev::RubyPacker replaced for jmespath/nodes/not.rb
# KG-dev::RubyPacker replaced for jmespath/nodes/or.rb
# KG-dev::RubyPacker replaced for jmespath/nodes/pipe.rb
# KG-dev::RubyPacker replaced for jmespath/nodes/projection.rb
# KG-dev::RubyPacker replaced for jmespath/nodes/projection.rb
# KG-dev::RubyPacker replaced for jmespath/nodes/projection.rb
# KG-dev::RubyPacker replaced for jmespath/nodes/slice.rb


  end
end

module JMESPath
  # @api private
  module Nodes
    class Subexpression < Node
      def initialize(left, right)
        @left = left
        @right = right
      end

      def visit(value)
        @right.visit(@left.visit(value))
      end

      def optimize
        Chain.new(flatten).optimize
      end

      protected

      attr_reader :left, :right

      def flatten
        nodes = [@left, @right]
        until nodes.none? { |node| node.is_a?(Subexpression) }
          nodes = nodes.flat_map do |node|
            if node.is_a?(Subexpression)
              [node.left, node.right]
            else
              [node]
            end
          end
        end
        nodes.map(&:optimize)
      end
    end

    class Chain
      def initialize(children)
        @children = children
      end

      def visit(value)
        @children.reduce(value) do |v, child|
          child.visit(v)
        end
      end

      def optimize
        children = @children.map(&:optimize)
        index = 0
        while index < children.size - 1
          if children[index].chains_with?(children[index + 1])
            children[index] = children[index].chain(children[index + 1])
            children.delete_at(index + 1)
          else
            index += 1
          end
        end
        Chain.new(children)
      end
    end
  end
end
module JMESPath
  module Nodes
    class And < Node

      def initialize(left, right)
        @left = left
        @right = right
      end

      def visit(value)
        result = @left.visit(value)
        if JMESPath::Util.falsey?(result)
          result
        else
          @right.visit(value)
        end
      end

      def optimize
        self.class.new(@left.optimize, @right.optimize)
      end

    end
  end
end
module JMESPath
  # @api private
  module Nodes
    class Comparator < Node
      attr_reader :left, :right

      def initialize(left, right)
        @left = left
        @right = right
      end

      def self.create(relation, left, right)
        type = begin
          case relation
          when '==' then Comparators::Eq
          when '!=' then Comparators::Neq
          when '>' then Comparators::Gt
          when '>=' then Comparators::Gte
          when '<' then Comparators::Lt
          when '<=' then Comparators::Lte
          end
        end
        type.new(left, right)
      end

      def visit(value)
        check(@left.visit(value), @right.visit(value))
      end

      def optimize
        self.class.new(@left.optimize, @right.optimize)
      end

      private

      def check(left_value, right_value)
        nil
      end
    end

    module Comparators

      class Eq < Comparator
        def check(left_value, right_value)
          left_value == right_value
        end
      end

      class Neq < Comparator
        def check(left_value, right_value)
          left_value != right_value
        end
      end

      class Gt < Comparator
        def check(left_value, right_value)
          if left_value.is_a?(Numeric) && right_value.is_a?(Numeric)
            left_value > right_value
          else
            nil
          end
        end
      end

      class Gte < Comparator
        def check(left_value, right_value)
          if left_value.is_a?(Numeric) && right_value.is_a?(Numeric)
            left_value >= right_value
          else
            nil
          end
        end
      end

      class Lt < Comparator
        def check(left_value, right_value)
          if left_value.is_a?(Numeric) && right_value.is_a?(Numeric)
            left_value < right_value
          else
            nil
          end
        end
      end

      class Lte < Comparator
        def check(left_value, right_value)
          if left_value.is_a?(Numeric) && right_value.is_a?(Numeric)
            left_value <= right_value
          else
            nil
          end
        end
      end
    end
  end
end
module JMESPath
  # @api private
  module Nodes
    class Condition < Node
      def initialize(test, child)
        @test = test
        @child = child
      end

      def visit(value)
        if JMESPath::Util.falsey?(@test.visit(value))
          nil
        else
          @child.visit(value)
        end
      end

      def optimize
        test = @test.optimize
        if (new_type = ComparatorCondition::COMPARATOR_TO_CONDITION[@test.class])
          new_type.new(test.left, test.right, @child).optimize
        else
          self.class.new(test, @child.optimize)
        end
      end
    end

    class ComparatorCondition < Node
      COMPARATOR_TO_CONDITION = {}

      def initialize(left, right, child)
        @left = left
        @right = right
        @child = child
      end

      def visit(value)
        nil
      end
    end

    class EqCondition < ComparatorCondition
      COMPARATOR_TO_CONDITION[Comparators::Eq] = self

      def visit(value)
        @left.visit(value) == @right.visit(value) ? @child.visit(value) : nil
      end

      def optimize
        if @right.is_a?(Literal)
          LiteralRightEqCondition.new(@left, @right, @child)
        else
          self
        end
      end
    end

    class LiteralRightEqCondition < EqCondition
      def initialize(left, right, child)
        super
        @right = @right.value
      end

      def visit(value)
        @left.visit(value) == @right ? @child.visit(value) : nil
      end
    end

    class NeqCondition < ComparatorCondition
      COMPARATOR_TO_CONDITION[Comparators::Neq] = self

      def visit(value)
        @left.visit(value) != @right.visit(value) ? @child.visit(value) : nil
      end

      def optimize
        if @right.is_a?(Literal)
          LiteralRightNeqCondition.new(@left, @right, @child)
        else
          self
        end
      end
    end

    class LiteralRightNeqCondition < NeqCondition
      def initialize(left, right, child)
        super
        @right = @right.value
      end

      def visit(value)
        @left.visit(value) != @right ? @child.visit(value) : nil
      end
    end

    class GtCondition < ComparatorCondition
      COMPARATOR_TO_CONDITION[Comparators::Gt] = self

      def visit(value)
        left_value = @left.visit(value)
        right_value = @right.visit(value)
        left_value.is_a?(Integer) && right_value.is_a?(Integer) && left_value > right_value ? @child.visit(value) : nil
      end
    end

    class GteCondition < ComparatorCondition
      COMPARATOR_TO_CONDITION[Comparators::Gte] = self

      def visit(value)
        left_value = @left.visit(value)
        right_value = @right.visit(value)
        left_value.is_a?(Integer) && right_value.is_a?(Integer) && left_value >= right_value ? @child.visit(value) : nil
      end
    end

    class LtCondition < ComparatorCondition
      COMPARATOR_TO_CONDITION[Comparators::Lt] = self

      def visit(value)
        left_value = @left.visit(value)
        right_value = @right.visit(value)
        left_value.is_a?(Integer) && right_value.is_a?(Integer) && left_value < right_value ? @child.visit(value) : nil
      end
    end

    class LteCondition < ComparatorCondition
      COMPARATOR_TO_CONDITION[Comparators::Lte] = self

      def visit(value)
        left_value = @left.visit(value)
        right_value = @right.visit(value)
        left_value.is_a?(Integer) && right_value.is_a?(Integer) && left_value <= right_value ? @child.visit(value) : nil
      end
    end
  end
end
module JMESPath
  # @api private
  module Nodes
    class Current < Node
      def visit(value)
        value
      end
    end
  end
end
module JMESPath
  # @api private
  module Nodes
    class Expression < Node
      attr_reader :expression

      def initialize(expression)
        @expression = expression
      end

      def visit(value)
        self
      end

      def eval(value)
        @expression.visit(value)
      end

      def optimize
        self.class.new(@expression.optimize)
      end
    end
  end
end

module JMESPath
  # @api private
  module Nodes
    class Field < Node
      def initialize(key)
        @key = key
        @key_sym = key.respond_to?(:to_sym) ? key.to_sym : nil
      end

      def visit(value)
        if value.is_a?(Array) && @key.is_a?(Integer)
          value[@key]
        elsif value.is_a?(Hash)
          if !(v = value[@key]).nil?
            v
          elsif @key_sym && !(v = value[@key_sym]).nil?
            v
          end
        elsif value.is_a?(Struct) && value.respond_to?(@key)
          value[@key]
        end
      end

      def chains_with?(other)
        other.is_a?(Field)
      end

      def chain(other)
        ChainedField.new([@key, *other.keys])
      end

      protected

      def keys
        [@key]
      end
    end

    class ChainedField < Field
      def initialize(keys)
        @keys = keys
        @key_syms = keys.each_with_object({}) do |k, syms|
          if k.respond_to?(:to_sym)
            syms[k] = k.to_sym
          end
        end
      end

      def visit(obj)
        @keys.reduce(obj) do |value, key|
          if value.is_a?(Array) && key.is_a?(Integer)
            value[key]
          elsif value.is_a?(Hash)
            if !(v = value[key]).nil?
              v
            elsif (sym = @key_syms[key]) && !(v = value[sym]).nil?
              v
            end
          elsif value.is_a?(Struct) && value.respond_to?(key)
            value[key]
          end
        end
      end

      def chain(other)
        ChainedField.new([*@keys, *other.keys])
      end

      private

      def keys
        @keys
      end

    end
  end
end
module JMESPath
  # @api private
  module Nodes
    class Flatten < Node
      def initialize(child)
        @child = child
      end

      def visit(value)
        value = @child.visit(value)
        if Array === value
          value.each_with_object([]) do |v, values|
            if Array === v
              values.concat(v)
            else
              values.push(v)
            end
          end
        else
          nil
        end
      end

      def optimize
        self.class.new(@child.optimize)
      end
    end
  end
end
module JMESPath
  # @api private
  module Nodes
    class Function < Node

      FUNCTIONS = {}

      def initialize(children, options = {})
        @children = children
        @options = options
        @disable_visit_errors = @options[:disable_visit_errors]
      end

      def self.create(name, children, options = {})
        if (type = FUNCTIONS[name])
          type.new(children, options)
        else
          raise Errors::UnknownFunctionError, "unknown function #{name}()"
        end
      end

      def visit(value)
        call(@children.map { |child| child.visit(value) })
      end

      def optimize
        self.class.new(@children.map(&:optimize), @options)
      end

      class FunctionName
        attr_reader :name

        def initialize(name)
          @name = name
        end
      end

      private

      def maybe_raise(error_type, message)
        unless @disable_visit_errors
          raise error_type, message
        end
      end

      def call(args)
        nil
      end
    end

    module TypeChecker
      def get_type(value)
        case value
        when String then STRING_TYPE
        when true, false then BOOLEAN_TYPE
        when nil then NULL_TYPE
        when Numeric then NUMBER_TYPE
        when Hash, Struct then OBJECT_TYPE
        when Array then ARRAY_TYPE
        when Expression then EXPRESSION_TYPE
        end
      end

      ARRAY_TYPE = 0
      BOOLEAN_TYPE = 1
      EXPRESSION_TYPE = 2
      NULL_TYPE = 3
      NUMBER_TYPE = 4
      OBJECT_TYPE = 5
      STRING_TYPE = 6

      TYPE_NAMES = {
        ARRAY_TYPE => 'array',
        BOOLEAN_TYPE => 'boolean',
        EXPRESSION_TYPE => 'expression',
        NULL_TYPE => 'null',
        NUMBER_TYPE => 'number',
        OBJECT_TYPE => 'object',
        STRING_TYPE => 'string',
      }.freeze
    end

    class AbsFunction < Function
      FUNCTIONS['abs'] = self

      def call(args)
        if args.count == 1
          value = args.first
        else
          return maybe_raise Errors::InvalidArityError, "function abs() expects one argument"
        end
        if Numeric === value
          value.abs
        else
          return maybe_raise Errors::InvalidTypeError, "function abs() expects a number"
        end
      end
    end

    class AvgFunction < Function
      FUNCTIONS['avg'] = self

      def call(args)
        if args.count == 1
          values = args.first
        else
          return maybe_raise Errors::InvalidArityError, "function avg() expects one argument"
        end
        if Array === values
          return nil if values.empty?
          values.inject(0) do |total,n|
            if Numeric === n
              total + n
            else
              return maybe_raise Errors::InvalidTypeError, "function avg() expects numeric values"
            end
          end / values.size.to_f
        else
          return maybe_raise Errors::InvalidTypeError, "function avg() expects a number"
        end
      end
    end

    class CeilFunction < Function
      FUNCTIONS['ceil'] = self

      def call(args)
        if args.count == 1
          value = args.first
        else
          return maybe_raise Errors::InvalidArityError, "function ceil() expects one argument"
        end
        if Numeric === value
          value.ceil
        else
          return maybe_raise Errors::InvalidTypeError, "function ceil() expects a numeric value"
        end
      end
    end

    class ContainsFunction < Function
      FUNCTIONS['contains'] = self

      def call(args)
        if args.count == 2
          haystack = args[0]
          needle = args[1]
          if String === haystack || Array === haystack
            haystack.include?(needle)
          else
            return maybe_raise Errors::InvalidTypeError, "contains expects 2nd arg to be a list"
          end
        else
          return maybe_raise Errors::InvalidArityError, "function contains() expects 2 arguments"
        end
      end
    end

    class FloorFunction < Function
      FUNCTIONS['floor'] = self

      def call(args)
        if args.count == 1
          value = args.first
        else
          return maybe_raise Errors::InvalidArityError, "function floor() expects one argument"
        end
        if Numeric === value
          value.floor
        else
          return maybe_raise Errors::InvalidTypeError, "function floor() expects a numeric value"
        end
      end
    end

    class LengthFunction < Function
      FUNCTIONS['length'] = self

      def call(args)
        if args.count == 1
          value = args.first
        else
          return maybe_raise Errors::InvalidArityError, "function length() expects one argument"
        end
        case value
        when Hash, Array, String then value.size
        else return maybe_raise Errors::InvalidTypeError, "function length() expects string, array or object"
        end
      end
    end

    class Map < Function

      FUNCTIONS['map'] = self

      def call(args)
        if args.count != 2
          return maybe_raise Errors::InvalidArityError, "function map() expects two arguments"
        end
        if Nodes::Expression === args[0]
          expr = args[0]
        else
          return maybe_raise Errors::InvalidTypeError, "function map() expects the first argument to be an expression"
        end
        if Array === args[1]
          list = args[1]
        else
          return maybe_raise Errors::InvalidTypeError, "function map() expects the second argument to be an list"
        end
        list.map { |value| expr.eval(value) }
      end

    end

    class MaxFunction < Function
      include TypeChecker

      FUNCTIONS['max'] = self

      def call(args)
        if args.count == 1
          values = args.first
        else
          return maybe_raise Errors::InvalidArityError, "function max() expects one argument"
        end
        if Array === values
          return nil if values.empty?
          first = values.first
          first_type = get_type(first)
          unless first_type == NUMBER_TYPE || first_type == STRING_TYPE
            msg = "function max() expects numeric or string values"
            return maybe_raise Errors::InvalidTypeError, msg
          end
          values.inject([first, first_type]) do |(max, max_type), v|
            v_type = get_type(v)
            if max_type == v_type
              v > max ? [v, v_type] : [max, max_type]
            else
              msg = "function max() encountered a type mismatch in sequence: "
              msg << "#{max_type}, #{v_type}"
              return maybe_raise Errors::InvalidTypeError, msg
            end
          end.first
        else
          return maybe_raise Errors::InvalidTypeError, "function max() expects an array"
        end
      end
    end

    class MinFunction < Function
      include TypeChecker

      FUNCTIONS['min'] = self

      def call(args)
        if args.count == 1
          values = args.first
        else
          return maybe_raise Errors::InvalidArityError, "function min() expects one argument"
        end
        if Array === values
          return nil if values.empty?
          first = values.first
          first_type = get_type(first)
          unless first_type == NUMBER_TYPE || first_type == STRING_TYPE
            msg = "function min() expects numeric or string values"
            return maybe_raise Errors::InvalidTypeError, msg
          end
          values.inject([first, first_type]) do |(min, min_type), v|
            v_type = get_type(v)
            if min_type == v_type
              v < min ? [v, v_type] : [min, min_type]
            else
              msg = "function min() encountered a type mismatch in sequence: "
              msg << "#{min_type}, #{v_type}"
              return maybe_raise Errors::InvalidTypeError, msg
            end
          end.first
        else
          return maybe_raise Errors::InvalidTypeError, "function min() expects an array"
        end
      end
    end

    class TypeFunction < Function
      include TypeChecker

      FUNCTIONS['type'] = self

      def call(args)
        if args.count == 1
          TYPE_NAMES[get_type(args.first)]
        else
          return maybe_raise Errors::InvalidArityError, "function type() expects one argument"
        end
      end
    end

    class KeysFunction < Function
      FUNCTIONS['keys'] = self

      def call(args)
        if args.count == 1
          value = args.first
          if hash_like?(value)
            case value
            when Hash then value.keys.map(&:to_s)
            when Struct then value.members.map(&:to_s)
            else raise NotImplementedError
            end
          else
            return maybe_raise Errors::InvalidTypeError, "function keys() expects a hash"
          end
        else
          return maybe_raise Errors::InvalidArityError, "function keys() expects one argument"
        end
      end
    end

    class ValuesFunction < Function
      FUNCTIONS['values'] = self

      def call(args)
        if args.count == 1
          value = args.first
          if hash_like?(value)
            value.values
          elsif Array === value
            value
          else
            return maybe_raise Errors::InvalidTypeError, "function values() expects an array or a hash"
          end
        else
          return maybe_raise Errors::InvalidArityError, "function values() expects one argument"
        end
      end
    end

    class JoinFunction < Function
      FUNCTIONS['join'] = self

      def call(args)
        if args.count == 2
          glue = args[0]
          values = args[1]
          if !(String === glue)
            return maybe_raise Errors::InvalidTypeError, "function join() expects the first argument to be a string"
          elsif Array === values && values.all? { |v| String === v }
            values.join(glue)
          else
            return maybe_raise Errors::InvalidTypeError, "function join() expects values to be an array of strings"
          end
        else
          return maybe_raise Errors::InvalidArityError, "function join() expects an array of strings"
        end
      end
    end

    class ToStringFunction < Function
      FUNCTIONS['to_string'] = self

      def call(args)
        if args.count == 1
          value = args.first
          String === value ? value : value.to_json
        else
          return maybe_raise Errors::InvalidArityError, "function to_string() expects one argument"
        end
      end
    end

    class ToNumberFunction < Function
      FUNCTIONS['to_number'] = self

      def call(args)
        if args.count == 1
          begin
            value = Float(args.first)
            Integer(value) === value ? value.to_i : value
          rescue
            nil
          end
        else
          return maybe_raise Errors::InvalidArityError, "function to_number() expects one argument"
        end
      end
    end

    class SumFunction < Function
      FUNCTIONS['sum'] = self

      def call(args)
        if args.count == 1 && Array === args.first
          args.first.inject(0) do |sum,n|
            if Numeric === n
              sum + n
            else
              return maybe_raise Errors::InvalidTypeError, "function sum() expects values to be numeric"
            end
          end
        else
          return maybe_raise Errors::InvalidArityError, "function sum() expects one argument"
        end
      end
    end

    class NotNullFunction < Function
      FUNCTIONS['not_null'] = self

      def call(args)
        if args.count > 0
          args.find { |value| !value.nil? }
        else
          return maybe_raise Errors::InvalidArityError, "function not_null() expects one or more arguments"
        end
      end
    end

    class SortFunction < Function
      include TypeChecker

      FUNCTIONS['sort'] = self

      def call(args)
        if args.count == 1
          value = args.first
          if Array === value
            # every element in the list must be of the same type
            array_type = get_type(value[0])
            if array_type == STRING_TYPE || array_type == NUMBER_TYPE || value.size == 0
              # stable sort
              n = 0
              value.sort_by do |v|
                value_type = get_type(v)
                if value_type != array_type
                  msg = "function sort() expects values to be an array of only numbers, or only integers"
                  return maybe_raise Errors::InvalidTypeError, msg
                end
                n += 1
                [v, n]
              end
            else
              return maybe_raise Errors::InvalidTypeError, "function sort() expects values to be an array of numbers or integers"
            end
          else
            return maybe_raise Errors::InvalidTypeError, "function sort() expects values to be an array of numbers or integers"
          end
        else
          return maybe_raise Errors::InvalidArityError, "function sort() expects one argument"
        end
      end
    end

    class SortByFunction < Function
      include TypeChecker

      FUNCTIONS['sort_by'] = self

      def call(args)
        if args.count == 2
          if get_type(args[0]) == ARRAY_TYPE && get_type(args[1]) == EXPRESSION_TYPE
            values = args[0]
            expression = args[1]
            array_type = get_type(expression.eval(values[0]))
            if array_type == STRING_TYPE || array_type == NUMBER_TYPE || values.size == 0
              # stable sort the list
              n = 0
              values.sort_by do |value|
                value = expression.eval(value)
                value_type = get_type(value)
                if value_type != array_type
                  msg = "function sort() expects values to be an array of only numbers, or only integers"
                  return maybe_raise Errors::InvalidTypeError, msg
                end
                n += 1
                [value, n]
              end
            else
              return maybe_raise Errors::InvalidTypeError, "function sort() expects values to be an array of numbers or integers"
            end
          else
            return maybe_raise Errors::InvalidTypeError, "function sort_by() expects an array and an expression"
          end
        else
          return maybe_raise Errors::InvalidArityError, "function sort_by() expects two arguments"
        end
      end
    end

    module CompareBy
      include TypeChecker

      def compare_by(mode, *args)
        if args.count == 2
          values = args[0]
          expression = args[1]
          if get_type(values) == ARRAY_TYPE && get_type(expression) == EXPRESSION_TYPE
            type = get_type(expression.eval(values.first))
            if type != NUMBER_TYPE && type != STRING_TYPE
              msg = "function #{mode}() expects values to be strings or numbers"
              return maybe_raise Errors::InvalidTypeError, msg
            end
            values.send(mode) do |entry|
              value = expression.eval(entry)
              value_type = get_type(value)
              if value_type != type
                msg = "function #{mode}() encountered a type mismatch in "
                msg << "sequence: #{type}, #{value_type}"
                return maybe_raise Errors::InvalidTypeError, msg
              end
              value
            end
          else
            msg = "function #{mode}() expects an array and an expression"
            return maybe_raise Errors::InvalidTypeError, msg
          end
        else
          msg = "function #{mode}() expects two arguments"
          return maybe_raise Errors::InvalidArityError, msg
        end
      end
    end

    class MaxByFunction < Function
      include CompareBy

      FUNCTIONS['max_by'] = self

      def call(args)
        compare_by(:max_by, *args)
      end
    end

    class MinByFunction < Function
      include CompareBy

      FUNCTIONS['min_by'] = self

      def call(args)
        compare_by(:min_by, *args)
      end
    end

    class EndsWithFunction < Function
      include TypeChecker

      FUNCTIONS['ends_with'] = self

      def call(args)
        if args.count == 2
          search, suffix = args
          search_type = get_type(search)
          suffix_type = get_type(suffix)
          if search_type != STRING_TYPE
            msg = "function ends_with() expects first argument to be a string"
            return maybe_raise Errors::InvalidTypeError, msg
          end
          if suffix_type != STRING_TYPE
            msg = "function ends_with() expects second argument to be a string"
            return maybe_raise Errors::InvalidTypeError, msg
          end
          search.end_with?(suffix)
        else
          msg = "function ends_with() expects two arguments"
          return maybe_raise Errors::InvalidArityError, msg
        end
      end
    end

    class StartsWithFunction < Function
      include TypeChecker

      FUNCTIONS['starts_with'] = self

      def call(args)
        if args.count == 2
          search, prefix = args
          search_type = get_type(search)
          prefix_type = get_type(prefix)
          if search_type != STRING_TYPE
            msg = "function starts_with() expects first argument to be a string"
            return maybe_raise Errors::InvalidTypeError, msg
          end
          if prefix_type != STRING_TYPE
            msg = "function starts_with() expects second argument to be a string"
            return maybe_raise Errors::InvalidTypeError, msg
          end
          search.start_with?(prefix)
        else
          msg = "function starts_with() expects two arguments"
          return maybe_raise Errors::InvalidArityError, msg
        end
      end
    end

    class MergeFunction < Function
      FUNCTIONS['merge'] = self

      def call(args)
        if args.count == 0
          msg = "function merge() expects 1 or more arguments"
          return maybe_raise Errors::InvalidArityError, msg
        end
        args.inject({}) do |h, v|
          h.merge(v)
        end
      end
    end

    class ReverseFunction < Function
      FUNCTIONS['reverse'] = self

      def call(args)
        if args.count == 0
          msg = "function reverse() expects 1 or more arguments"
          return maybe_raise Errors::InvalidArityError, msg
        end
        value = args.first
        if Array === value || String === value
          value.reverse
        else
          msg = "function reverse() expects an array or string"
          return maybe_raise Errors::InvalidTypeError, msg
        end
      end
    end

    class ToArrayFunction < Function
      FUNCTIONS['to_array'] = self

      def call(args)
        value = args.first
        Array === value ? value : [value]
      end
    end
  end
end
module JMESPath
  # @api private
  module Nodes
    Index = Field
  end
end
module JMESPath
  # @api private
  module Nodes
    class Literal < Node
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def visit(value)
        @value
      end
    end
  end
end
module JMESPath
  # @api private
  module Nodes
    class MultiSelectHash < Node
      def initialize(kv_pairs)
        @kv_pairs = kv_pairs
      end

      def visit(value)
        if value.nil?
          nil
        else
          @kv_pairs.each_with_object({}) do |pair, hash|
            hash[pair.key] = pair.value.visit(value)
          end
        end
      end

      def optimize
        self.class.new(@kv_pairs.map(&:optimize))
      end

      class KeyValuePair
        attr_reader :key, :value

        def initialize(key, value)
          @key = key
          @value = value
        end

        def optimize
          self.class.new(@key, @value.optimize)
        end
      end
    end
  end
end
module JMESPath
  # @api private
  module Nodes
    class MultiSelectList < Node
      def initialize(children)
        @children = children
      end

      def visit(value)
        if value.nil?
          value
        else
          @children.map { |n| n.visit(value) }
        end
      end

      def optimize
        self.class.new(@children.map(&:optimize))
      end
    end
  end
end
module JMESPath
  module Nodes
    class Not < Node

      def initialize(expression)
        @expression = expression
      end

      def visit(value)
        JMESPath::Util.falsey?(@expression.visit(value))
      end

      def optimize
        self.class.new(@expression.optimize)
      end

    end
  end
end
module JMESPath
  # @api private
  module Nodes
    class Or < Node
      def initialize(left, right)
        @left = left
        @right = right
      end

      def visit(value)
        result = @left.visit(value)
        if JMESPath::Util.falsey?(result)
          @right.visit(value)
        else
          result
        end
      end

      def optimize
        self.class.new(@left.optimize, @right.optimize)
      end
    end
  end
end
module JMESPath
  # @api private
  module Nodes
    Pipe = Subexpression
  end
end
module JMESPath
  # @api private
  module Nodes
    class Projection < Node
      def initialize(target, projection)
        @target = target
        @projection = projection
      end

      def visit(value)
        if (targets = extract_targets(@target.visit(value)))
          list = []
          targets.each do |v|
            vv = @projection.visit(v)
            unless vv.nil?
              list << vv
            end
          end
          list
        end
      end

      def optimize
        if @projection.is_a?(Current)
          fast_instance
        else
          self.class.new(@target.optimize, @projection.optimize)
        end
      end

      private

      def extract_targets(left_value)
        nil
      end
    end

    module FastProjector
      def visit(value)
        if (targets = extract_targets(@target.visit(value)))
          targets.compact
        end
      end
    end

    class ArrayProjection < Projection
      def extract_targets(target)
        if Array === target
          target
        else
          nil
        end
      end

      def fast_instance
        FastArrayProjection.new(@target.optimize, @projection.optimize)
      end
    end

    class FastArrayProjection < ArrayProjection
      include FastProjector
    end

    class ObjectProjection < Projection
      def extract_targets(target)
        if hash_like?(target)
          target.values
        else
          nil
        end
      end

      def fast_instance
        FastObjectProjection.new(@target.optimize, @projection.optimize)
      end
    end

    class FastObjectProjection < ObjectProjection
      include FastProjector
    end
  end
end
module JMESPath
  # @api private
  module Nodes
    class Slice < Node
      def initialize(start, stop, step)
        @start = start
        @stop = stop
        @step = step
        raise Errors::InvalidValueError.new('slice step cannot be 0') if @step == 0
      end

      def visit(value)
        if String === value || Array === value
          start, stop, step = adjust_slice(value.size, @start, @stop, @step)
          result = []
          if step > 0
            i = start
            while i < stop
              result << value[i]
              i += step
            end
          else
            i = start
            while i > stop
              result << value[i]
              i += step
            end
          end
          String === value ? result.join : result
        else
          nil
        end
      end

      def optimize
        if (@step.nil? || @step == 1) && @start && @stop && @start > 0 && @stop > @start
          SimpleSlice.new(@start, @stop)
        else
          self
        end
      end

      private

      def adjust_slice(length, start, stop, step)
        if step.nil?
          step = 1
        end

        if start.nil?
          start = step < 0 ? length - 1 : 0
        else
          start = adjust_endpoint(length, start, step)
        end

        if stop.nil?
          stop = step < 0 ? -1 : length
        else
          stop = adjust_endpoint(length, stop, step)
        end
        [start, stop, step]
      end

      def adjust_endpoint(length, endpoint, step)
        if endpoint < 0
          endpoint += length
          endpoint = step < 0 ? -1 : 0 if endpoint < 0
          endpoint
        elsif endpoint >= length
          step < 0 ? length - 1 : length
        else
          endpoint
        end
      end
    end

    class SimpleSlice < Slice
      def initialize(start, stop)
        super(start, stop, 1)
      end

      def visit(value)
        if String === value || Array === value
          value[@start, @stop - @start]
        else
          nil
        end
      end
    end
  end
end

require 'set'

module JMESPath
  # @api private
  class Parser

    AFTER_DOT = Set.new([
      Lexer::T_IDENTIFIER,        # foo.bar
      Lexer::T_QUOTED_IDENTIFIER, # foo."bar"
      Lexer::T_STAR,              # foo.*
      Lexer::T_LBRACE,            # foo{a: 0}
      Lexer::T_LBRACKET,          # foo[1]
      Lexer::T_FILTER,            # foo.[?bar==10]
    ])

    NUM_COLON_RBRACKET = Set.new([
      Lexer::T_NUMBER,
      Lexer::T_COLON,
      Lexer::T_RBRACKET,
    ])

    COLON_RBRACKET = Set.new([
      Lexer::T_COLON,
      Lexer::T_RBRACKET,
    ])

    CURRENT_NODE = Nodes::Current.new

    # @option options [Lexer] :lexer
    def initialize(options = {})
      @lexer = options[:lexer] || Lexer.new
      @disable_visit_errors = options[:disable_visit_errors]
    end

    # @param [String<JMESPath>] expression
    def parse(expression)
      tokens =  @lexer.tokenize(expression)
      stream = TokenStream.new(expression, tokens)
      result = expr(stream)
      if stream.token.type != Lexer::T_EOF
        raise Errors::SyntaxError, "expected :eof got #{stream.token.type}"
      else
        result
      end
    end

    # @api private
    def method_missing(method_name, *args)
      if matches = method_name.to_s.match(/^(nud_|led_)(.*)/)
        raise Errors::SyntaxError, "unexpected token #{matches[2]}"
      else
        super
      end
    end

    private

    # @param [TokenStream] stream
    # @param [Integer] rbp Right binding power
    def expr(stream, rbp = 0)
      left = send("nud_#{stream.token.type}", stream)
      while rbp < (stream.token.binding_power || 0)
        left = send("led_#{stream.token.type}", stream, left)
      end
      left
    end

    def nud_current(stream)
      stream.next
      CURRENT_NODE
    end

    def nud_expref(stream)
      stream.next
      Nodes::Expression.new(expr(stream, Token::BINDING_POWER[:expref]))
    end

    def nud_not(stream)
      stream.next
      Nodes::Not.new(expr(stream, Token::BINDING_POWER[:not]))
    end

    def nud_lparen(stream)
      stream.next
      result = expr(stream, 0)
      if stream.token.type != Lexer::T_RPAREN
        raise Errors::SyntaxError, 'Unclosed `(`'
      end
      stream.next
      result
    end

    def nud_filter(stream)
      led_filter(stream, CURRENT_NODE)
    end

    def nud_flatten(stream)
      led_flatten(stream, CURRENT_NODE)
    end

    def nud_identifier(stream)
      token = stream.token
      n = stream.next
      if n.type == :lparen
        Nodes::Function::FunctionName.new(token.value)
      else
        Nodes::Field.new(token.value)
      end
    end

    def nud_lbrace(stream)
      valid_keys = Set.new([:quoted_identifier, :identifier])
      stream.next(match:valid_keys)
      pairs = []
      begin
        pairs << parse_key_value_pair(stream)
        if stream.token.type == :comma
          stream.next(match:valid_keys)
        end
      end while stream.token.type != :rbrace
      stream.next
      Nodes::MultiSelectHash.new(pairs)
    end

    def nud_lbracket(stream)
      stream.next
      type = stream.token.type
      if type == :number || type == :colon
        parse_array_index_expression(stream)
      elsif type == :star && stream.lookahead(1).type == :rbracket
        parse_wildcard_array(stream)
      else
        parse_multi_select_list(stream)
      end
    end

    def nud_literal(stream)
      value = stream.token.value
      stream.next
      Nodes::Literal.new(value)
    end

    def nud_quoted_identifier(stream)
      token = stream.token
      next_token = stream.next
      if next_token.type == :lparen
        msg = 'quoted identifiers are not allowed for function names'
        raise Errors::SyntaxError, msg
      else
        Nodes::Field.new(token[:value])
      end
    end

    def nud_star(stream)
      parse_wildcard_object(stream, CURRENT_NODE)
    end

    def nud_unknown(stream)
      raise Errors::SyntaxError, "unknown token #{stream.token.value.inspect}"
    end

    def led_comparator(stream, left)
      token = stream.token
      stream.next
      right = expr(stream, Token::BINDING_POWER[:comparator])
      Nodes::Comparator.create(token.value, left, right)
    end

    def led_dot(stream, left)
      stream.next(match:AFTER_DOT)
      if stream.token.type == :star
        parse_wildcard_object(stream, left)
      else
        right = parse_dot(stream, Token::BINDING_POWER[:dot])
        Nodes::Subexpression.new(left, right)
      end
    end

    def led_filter(stream, left)
      stream.next
      expression = expr(stream)
      if stream.token.type != Lexer::T_RBRACKET
        raise Errors::SyntaxError, 'expected a closing rbracket for the filter'
      end
      stream.next
      rhs = parse_projection(stream, Token::BINDING_POWER[Lexer::T_FILTER])
      left ||= CURRENT_NODE
      right = Nodes::Condition.new(expression, rhs)
      Nodes::ArrayProjection.new(left, right)
    end

    def led_flatten(stream, left)
      stream.next
      left = Nodes::Flatten.new(left)
      right = parse_projection(stream, Token::BINDING_POWER[:flatten])
      Nodes::ArrayProjection.new(left, right)
    end

    def led_lbracket(stream, left)
      stream.next(match: Set.new([:number, :colon, :star]))
      type = stream.token.type
      if type == :number || type == :colon
        right = parse_array_index_expression(stream)
        Nodes::Subexpression.new(left, right)
      else
        parse_wildcard_array(stream, left)
      end
    end

    def led_lparen(stream, left)
      args = []
      if Nodes::Function::FunctionName === left
        name = left.name
      else
        raise Errors::SyntaxError, 'invalid function invocation'
      end
      stream.next
      while stream.token.type != :rparen
        args << expr(stream, 0)
        if stream.token.type == :comma
          stream.next
        end
      end
      stream.next
      Nodes::Function.create(name, args, :disable_visit_errors => @disable_visit_errors)
    end

    def led_or(stream, left)
      stream.next
      right = expr(stream, Token::BINDING_POWER[:or])
      Nodes::Or.new(left, right)
    end

    def led_and(stream, left)
      stream.next
      right = expr(stream, Token::BINDING_POWER[:or])
      Nodes::And.new(left, right)
    end

    def led_pipe(stream, left)
      stream.next
      right = expr(stream, Token::BINDING_POWER[:pipe])
      Nodes::Pipe.new(left, right)
    end

    # parse array index expressions, for example [0], [1:2:3], etc.
    def parse_array_index_expression(stream)
      pos = 0
      parts = [nil, nil, nil]
      expected = NUM_COLON_RBRACKET

      begin
        if stream.token.type == Lexer::T_COLON
          pos += 1
          expected = NUM_COLON_RBRACKET
        elsif stream.token.type == Lexer::T_NUMBER
          parts[pos] = stream.token.value
          expected = COLON_RBRACKET
        end
        stream.next(match: expected)
      end while stream.token.type != Lexer::T_RBRACKET

      stream.next # consume the closing bracket

      if pos == 0
        # no colons found, this is a single index extraction
        Nodes::Index.new(parts[0])
      elsif pos > 2
        raise Errors::SyntaxError, 'invalid array slice syntax: too many colons'
      else
        Nodes::ArrayProjection.new(
          Nodes::Slice.new(*parts),
          parse_projection(stream, Token::BINDING_POWER[Lexer::T_STAR])
        )
      end
    end

    def parse_dot(stream, binding_power)
      if stream.token.type == :lbracket
        stream.next
        parse_multi_select_list(stream)
      else
        expr(stream, binding_power)
      end
    end

    def parse_key_value_pair(stream)
      key = stream.token.value
      stream.next(match:Set.new([:colon]))
      stream.next
      Nodes::MultiSelectHash::KeyValuePair.new(key, expr(stream))
    end

    def parse_multi_select_list(stream)
      nodes = []
      begin
        nodes << expr(stream)
        if stream.token.type == :comma
          stream.next
          if stream.token.type == :rbracket
            raise Errors::SyntaxError, 'expression epxected, found rbracket'
          end
        end
      end while stream.token.type != :rbracket
      stream.next
      Nodes::MultiSelectList.new(nodes)
    end

    def parse_projection(stream, binding_power)
      type = stream.token.type
      if stream.token.binding_power < 10
        CURRENT_NODE
      elsif type == :dot
        stream.next(match:AFTER_DOT)
        parse_dot(stream, binding_power)
      elsif type == :lbracket || type == :filter
        expr(stream, binding_power)
      else
        raise Errors::SyntaxError, 'syntax error after projection'
      end
    end

    def parse_wildcard_array(stream, left = nil)
      stream.next(match:Set.new([:rbracket]))
      stream.next
      left ||= CURRENT_NODE
      right = parse_projection(stream, Token::BINDING_POWER[:star])
      Nodes::ArrayProjection.new(left, right)
    end

    def parse_wildcard_object(stream, left = nil)
      stream.next
      left ||= CURRENT_NODE
      right = parse_projection(stream, Token::BINDING_POWER[:star])
      Nodes::ObjectProjection.new(left, right)
    end

  end
end
module JMESPath
  # @api private
  class Runtime

    # @api private
    DEFAULT_PARSER = CachingParser

    # Constructs a new runtime object for evaluating JMESPath expressions.
    #
    #     runtime = JMESPath::Runtime.new
    #     runtime.search(expression, data)
    #     #=> ...
    #
    # ## Caching
    #
    # When constructing a {Runtime}, the default parser caches expressions.
    # This significantly speeds up calls to {#search} multiple times
    # with the same expression but different data. To disable caching, pass
    # `:cache_expressions => false` to the constructor or pass a custom
    # `:parser`.
    #
    # @example Re-use a Runtime, caching enabled by default
    #
    #   runtime = JMESPath::Runtime.new
    #   runtime.parser
    #   #=> #<JMESPath::CachingParser ...>
    #
    # @example Disable caching
    #
    #   runtime = JMESPath::Runtime.new(cache_expressions: false)
    #   runtime.parser
    #   #=> #<JMESPath::Parser ...>
    #
    # @option options [Boolean] :cache_expressions (true) When `false`, a non
    #   caching parser will be used. When `true`, a shared instance of
    #   {CachingParser} is used.  Defaults to `true`.
    #
    # @option options [Boolean] :disable_visit_errors (false) When `true`,
    #   no errors will be raised during runtime processing. Parse errors
    #   will still be raised, but unexpected data sent to visit will
    #   result in nil being returned.
    #
    # @option options [Parser,CachingParser] :parser
    #
    def initialize(options = {})
      @parser = options[:parser] || default_parser(options)
    end

    # @return [Parser, CachingParser]
    attr_reader :parser

    # @param [String<JMESPath>] expression
    # @param [Hash] data
    # @return [Mixed,nil]
    def search(expression, data)
      optimized_expression = @parser.parse(expression).optimize
      optimized_expression.visit(data)
    end

    private

    def default_parser(options)
      if options[:cache_expressions] == false
        Parser.new(options)
      else
        DEFAULT_PARSER.new(options)
      end
    end

  end
end
module JMESPath
  # @api private
  class Token < Struct.new(:type, :value, :position, :binding_power)

    NULL_TOKEN = Token.new(:eof, '', nil)

    BINDING_POWER = {
      Lexer::T_UNKNOWN           => 0,
      Lexer::T_EOF               => 0,
      Lexer::T_QUOTED_IDENTIFIER => 0,
      Lexer::T_IDENTIFIER        => 0,
      Lexer::T_RBRACKET          => 0,
      Lexer::T_RPAREN            => 0,
      Lexer::T_COMMA             => 0,
      Lexer::T_RBRACE            => 0,
      Lexer::T_NUMBER            => 0,
      Lexer::T_CURRENT           => 0,
      Lexer::T_EXPREF            => 0,
      Lexer::T_COLON             => 0,
      Lexer::T_PIPE              => 1,
      Lexer::T_OR                => 2,
      Lexer::T_AND               => 3,
      Lexer::T_COMPARATOR        => 5,
      Lexer::T_FLATTEN           => 9,
      Lexer::T_STAR              => 20,
      Lexer::T_FILTER            => 21,
      Lexer::T_DOT               => 40,
      Lexer::T_NOT               => 45,
      Lexer::T_LBRACE            => 50,
      Lexer::T_LBRACKET          => 55,
      Lexer::T_LPAREN            => 60,
    }

    # @param [Symbol] type
    # @param [Mixed] value
    # @param [Integer] position
    def initialize(type, value, position)
      super(type, value, position, BINDING_POWER[type])
    end

  end
end
module JMESPath
  # @api private
  class TokenStream

    # @param [String<JMESPath>] expression
    # @param [Array<Token>] tokens
    def initialize(expression, tokens)
      @expression = expression
      @tokens = tokens
      @token = nil
      @position = -1
      self.next
    end

    # @return [String<JMESPath>]
    attr_reader :expression

    # @return [Token]
    attr_reader :token

    # @return [Integer]
    attr_reader :position

    # @option options [Array<Symbol>] :match Requires the next token to be
    #   one of the given symbols or an error is raised.
    def next(options = {})
      validate_match(_next, options[:match])
    end

    def lookahead(count)
      @tokens[@position + count] || Token::NULL_TOKEN
    end

    # @api private
    def inspect
      str = []
      @tokens.each do |token|
        str << "%3d  %-15s %s" %
         [token.position, token.type, token.value.inspect]
      end
      str.join("\n")
    end

    private

    def _next
      @position += 1
      @token = @tokens[@position] || Token::NULL_TOKEN
    end

    def validate_match(token, match)
      if match && !match.include?(token.type)
        raise Errors::SyntaxError, "type missmatch"
      else
        token
      end
    end

  end
end
module JMESPath
  # @api private
  module Util
    class << self

      # Determines if a value is false as defined by JMESPath:
      #
      #   https://github.com/jmespath/jmespath.site/blob/master/docs/proposals/improved-filters.rst#and-expressions-1
      #
      def falsey?(value)
        !value ||
        (value.respond_to?(:empty?) && value.empty?) ||
        (value.respond_to?(:entries) && !value.entries.any?)
        # final case necessary to support Enumerable and Struct
      end
    end
  end
end
module JMESPath
  VERSION = '1.4.0'
end
require 'json'
require 'stringio'
require 'pathname'

module JMESPath

# KG-dev::RubyPacker replaced for jmespath/caching_parser.rb
# KG-dev::RubyPacker replaced for jmespath/errors.rb
# KG-dev::RubyPacker replaced for jmespath/lexer.rb
# KG-dev::RubyPacker replaced for jmespath/nodes.rb
# KG-dev::RubyPacker replaced for jmespath/parser.rb
# KG-dev::RubyPacker replaced for jmespath/runtime.rb
# KG-dev::RubyPacker replaced for jmespath/token.rb
# KG-dev::RubyPacker replaced for jmespath/token_stream.rb
# KG-dev::RubyPacker replaced for jmespath/util.rb
# KG-dev::RubyPacker replaced for jmespath/version.rb

  class << self

    # @param [String] expression A valid
    #   [JMESPath](https://github.com/boto/jmespath) expression.
    # @param [Hash] data
    # @return [Mixed,nil] Returns the matched values. Returns `nil` if the
    #   expression does not resolve inside `data`.
    def search(expression, data, runtime_options = {})
      data = case data
        when Hash, Struct then data # check for most common case first
        when Pathname then load_json(data)
        when IO, StringIO then JSON.load(data.read)
        else data
        end
      Runtime.new(runtime_options).search(expression, data)
    end

    # @api private
    def load_json(path)
      JSON.load(File.open(path, 'r', encoding: 'UTF-8') { |f| f.read })
    end

  end
end

end # Cesium::IonExporter
