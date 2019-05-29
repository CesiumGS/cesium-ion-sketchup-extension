require 'cgi'
require 'json'

require_relative 'aws-eventstream'
require_relative 'aws-partitions'
require_relative 'aws-sigv4'
require_relative 'jmespath'

module Cesium::IonExporter

module Seahorse
  # @api private
  module Util
    class << self

      def uri_escape(string)
        CGI.escape(string.to_s.encode('UTF-8')).gsub('+', '%20').gsub('%7E', '~')
      end

      def uri_path_escape(path)
        path.gsub(/[^\/]+/) { |part| uri_escape(part) }
      end

    end
  end
end
module Seahorse
  module Client
    class BlockIO

      def initialize(&block)
        @block = block
        @size = 0
      end

      # @param [String] chunk
      # @return [Integer]
      def write(chunk)
        @block.call(chunk)
        chunk.bytesize.tap { |chunk_size| @size += chunk_size }
      end

      # @param [Integer] bytes (nil)
      # @param [String] output_buffer (nil)
      # @return [String, nil]
      def read(bytes = nil, output_buffer = nil)
        data = bytes ? nil : ''
        output_buffer ? output_buffer.replace(data || '') : data
      end

      # @return [Integer]
      def size
        @size
      end

    end
  end
end
require 'set'

module Seahorse
  module Client

    # Configuration is used to define possible configuration options and
    # then build read-only structures with user-supplied data.
    #
    # ## Adding Configuration Options
    #
    # Add configuration options with optional default values.  These are used
    # when building configuration objects.
    #
    #     configuration = Configuration.new
    #
    #     configuration.add_option(:max_retries, 3)
    #     configuration.add_option(:use_ssl, true)
    #
    #     cfg = configuration.build!
    #     #=> #<struct max_retires=3 use_ssl=true>
    #
    # ## Building Configuration Objects
    #
    # Calling {#build!} on a {Configuration} object causes it to return
    # a read-only (frozen) struct.  Options passed to {#build!} are merged
    # on top of any default options.
    #
    #     configuration = Configuration.new
    #     configuration.add_option(:color, 'red')
    #
    #     # default
    #     cfg1 = configuration.build!
    #     cfg1.color #=> 'red'
    #
    #     # supplied color
    #     cfg2 = configuration.build!(color: 'blue')
    #     cfg2.color #=> 'blue'
    #
    # ## Accepted Options
    #
    # If you try to {#build!} a {Configuration} object with an unknown
    # option, an `ArgumentError` is raised.
    #
    #     configuration = Configuration.new
    #     configuration.add_option(:color)
    #     configuration.add_option(:size)
    #     configuration.add_option(:category)
    #
    #     configuration.build!(price: 100)
    #     #=> raises an ArgumentError, :price was not added as an option
    #
    class Configuration

      # @api private
      Defaults = Class.new(Array) do
        def each(&block)
          reverse.to_a.each(&block)
        end
      end

      # @api private
      class DynamicDefault
        attr_accessor :block

        def initialize(block = nil)
          @block = block
        end

        def call(*args) 
          @block.call(*args)
        end
      end

      # @api private
      def initialize
        @defaults = Hash.new { |h,k| h[k] = Defaults.new }
      end

      # Adds a getter method that returns the named option or a default
      # value.  Default values can be passed as a static positional argument
      # or via a block.
      #
      #    # defaults to nil
      #    configuration.add_option(:name)
      #
      #    # with a string default
      #    configuration.add_option(:name, 'John Doe')
      #
      #    # with a dynamic default value, evaluated once when calling #build!
      #    configuration.add_option(:name, 'John Doe')
      #    configuration.add_option(:username) do |config|
      #       config.name.gsub(/\W+/, '').downcase
      #    end
      #    cfg = configuration.build!
      #    cfg.name #=> 'John Doe'
      #    cfg.username #=> 'johndoe'
      #
      # @param [Symbol] name The name of the configuration option.  This will
      #   be used to define a getter by the same name.
      #
      # @param default The default value for this option.  You can specify
      #   a default by passing a value, a `Proc` object or a block argument.
      #   Procs and blocks are evaluated when {#build!} is called.
      #
      # @return [self]
      def add_option(name, default = nil, &block)
        default = DynamicDefault.new(Proc.new) if block_given?
        @defaults[name.to_sym] << default
        self
      end

      # Constructs and returns a configuration structure.
      # Values not present in `options` will default to those supplied via
      # add option.
      #
      #     configuration = Configuration.new
      #     configuration.add_option(:enabled, true)
      #
      #     cfg1 = configuration.build!
      #     cfg1.enabled #=> true
      #
      #     cfg2 = configuration.build!(enabled: false)
      #     cfg2.enabled #=> false
      #
      # If you pass in options to `#build!` that have not been defined,
      # then an `ArgumentError` will be raised.
      #
      #     configuration = Configuration.new
      #     configuration.add_option(:enabled, true)
      #
      #     # oops, spelling error for :enabled
      #     cfg = configuration.build!(enabld: true)
      #     #=> raises ArgumentError
      #
      # The object returned is a frozen `Struct`.
      #
      #     configuration = Configuration.new
      #     configuration.add_option(:enabled, true)
      #
      #     cfg = configuration.build!
      #     cfg.enabled #=> true
      #     cfg[:enabled] #=> true
      #     cfg['enabled'] #=> true
      #
      # @param [Hash] options ({}) A hash of configuration options.
      # @return [Struct] Returns a frozen configuration `Struct`.
      def build!(options = {})
        struct = empty_struct
        apply_options(struct, options)
        apply_defaults(struct, options)
        struct
      end

      private

      def empty_struct
        Struct.new(*@defaults.keys.sort).new
      end

      def apply_options(struct, options)
        options.each do |opt, value|
          begin
            struct[opt] = value
          rescue NameError
            msg = "invalid configuration option `#{opt.inspect}'"
            raise ArgumentError, msg
          end
        end
      end

      def apply_defaults(struct, options)
        @defaults.each do |opt_name, defaults|
          unless options.key?(opt_name)
            struct[opt_name] = defaults
          end
        end
        DefaultResolver.new(struct).resolve
      end

      # @api private
      class DefaultResolver

        def initialize(struct)
          @struct = struct
          @members = Set.new(@struct.members)
        end

        def resolve
          @members.each { |opt_name| value_at(opt_name) }
        end

        def respond_to?(method_name, *args)
          @members.include?(method_name) or super
        end

        private

        def value_at(opt_name)
          value = @struct[opt_name]
          if value.is_a?(Defaults)
            # this config value is used by endpoint discovery
            if opt_name == :endpoint && @struct.members.include?(:regional_endpoint)
              @struct[:regional_endpoint] = true
            end
            resolve_defaults(opt_name, value)
          else
            value
          end
        end

        def resolve_defaults(opt_name, defaults)
          defaults.each do |default|
            default = default.call(self) if default.is_a?(DynamicDefault)
            @struct[opt_name] = default
            break if !default.nil?
          end
          @struct[opt_name]
        end

        def method_missing(method_name, *args)
          if @members.include?(method_name)
            value_at(method_name)
          else
            super
          end
        end

      end
    end
  end
end
module Seahorse
  module Client
    class Handler

      # @param [Handler] handler (nil) The next handler in the stack that
      #   should be called from within the {#call} method.  This value
      #   must only be nil for send handlers.
      def initialize(handler = nil)
        @handler = handler
      end

      # @return [Handler, nil]
      attr_accessor :handler

      # @param [RequestContext] context
      # @return [Response]
      def call(context)
        @handler.call(context)
      end

      def inspect
        "#<#{self.class.name||'UnnamedHandler'} @handler=#{@handler.inspect}>"
      end
    end
  end
end
module Seahorse
  module Client

    # This module provides the ability to add handlers to a class or
    # module.  The including class or extending module must respond to
    # `#handlers`, returning a {HandlerList}.
    module HandlerBuilder

      def handle_request(*args, &block)
        handler(*args) do |context|
          block.call(context)
          @handler.call(context)
        end
      end

      def handle_response(*args, &block)
        handler(*args) do |context|
          resp = @handler.call(context)
          block.call(resp) if resp.context.http_response.status_code > 0
          resp
        end
      end

      def handle(*args, &block)
        options = args.last.is_a?(Hash) ? args.pop : {}
        handler_class = block ? handler_for(*args, &block) : args.first
        handlers.add(handler_class, options)
      end
      alias handler handle

      # @api private
      def handler_for(name = nil, &block)
        if name
          const_set(name, new_handler(block))
        else
          new_handler(block)
        end
      end

      # @api private
      def new_handler(block)
        Class.new(Handler) do
          define_method(:call, &block)
        end
      end

    end
  end
end
require 'thread'
require 'set'

module Seahorse
  module Client
    class HandlerList

      include Enumerable

      # @api private
      def initialize(options = {})
        @index = options[:index] || 0
        @entries = {}
        @mutex = Mutex.new
        entries = options[:entries] || []
        add_entries(entries) unless entries.empty?
      end

      # @return [Array<HandlerListEntry>]
      def entries
        @mutex.synchronize do
          @entries.values
        end
      end

      # Registers a handler.  Handlers are used to build a handler stack.
      # Handlers default to the `:build` step with default priority of 50.
      # The step and priority determine where in the stack a handler
      # will be.
      #
      # ## Handler Stack Ordering
      #
      # A handler stack is built from the inside-out.  The stack is
      # seeded with the send handler.  Handlers are constructed recursively
      # in reverse step and priority order so that the highest priority
      # handler is on the outside.
      #
      # By constructing the stack from the inside-out, this ensures
      # that the validate handlers will be called first and the sign handlers
      # will be called just before the final and only send handler is called.
      #
      # ## Steps
      #
      # Handlers are ordered first by step.  These steps represent the
      # life-cycle of a request.  Valid steps are:
      #
      # * `:initialize`
      # * `:validate`
      # * `:build`
      # * `:sign`
      # * `:send`
      #
      # Many handlers can be added to the same step, except for `:send`.
      # There can be only one `:send` handler.  Adding an additional
      # `:send` handler replaces the previous one.
      #
      # ## Priorities
      #
      # Handlers within a single step are executed in priority order.  The
      # higher the priority, the earlier in the stack the handler will
      # be called.
      #
      # * Handler priority is an integer between 0 and 99, inclusively.
      # * Handler priority defaults to 50.
      # * When multiple handlers are added to the same step with the same
      #   priority, the last one added will have the highest priority and
      #   the first one added will have the lowest priority.
      #
      # @param [Class<Handler>] handler_class This should be a subclass
      #   of {Handler}.
      #
      # @option options [Symbol] :step (:build) The request life-cycle
      #   step the handler should run in.  Defaults to `:build`.  The
      #   list of possible steps, in high-to-low priority order are:
      #
      #   * `:initialize`
      #   * `:validate`
      #   * `:build`
      #   * `:sign`
      #   * `:send`
      #
      #   There can only be one send handler. Registering an additional
      #   `:send` handler replaces the previous one.
      #
      # @option options [Integer] :priority (50) The priority of this
      #   handler within a step.  The priority must be between 0 and 99
      #   inclusively.  It defaults to 50.  When two handlers have the
      #   same `:step` and `:priority`, the handler registered last has
      #   the highest priority.
      #
      # @option options [Array<Symbol,String>] :operations A list of
      #   operations names the handler should be applied to.  When
      #   `:operations` is omitted, the handler is applied to all
      #   operations for the client.
      #
      # @raise [InvalidStepError]
      # @raise [InvalidPriorityError]
      # @note There can be only one `:send` handler.  Adding an additional
      #   send handler replaces the previous.
      #
      # @return [Class<Handler>] Returns the handler class that was added.
      #
      def add(handler_class, options = {})
        @mutex.synchronize do
          add_entry(
            HandlerListEntry.new(options.merge(
              handler_class: handler_class,
              inserted: next_index
            ))
          )
        end
        handler_class
      end

      # @param [Class<Handler>] handler_class
      def remove(handler_class)
        @entries.each do |key, entry|
          @entries.delete(key) if entry.handler_class == handler_class
        end
      end

      # Copies handlers from the `source_list` onto the current handler list.
      # If a block is given, only the entries that return a `true` value
      # from the block will be copied.
      # @param [HandlerList] source_list
      # @return [void]
      def copy_from(source_list, &block)
        entries = []
        source_list.entries.each do |entry|
          if block_given?
            entries << entry.copy(inserted: next_index) if yield(entry)
          else
            entries << entry.copy(inserted: next_index)
          end
        end
        add_entries(entries)
      end

      # Returns a handler list for the given operation.  The returned
      # will have the operation specific handlers merged with the common
      # handlers.
      # @param [String] operation The name of an operation.
      # @return [HandlerList]
      def for(operation)
        HandlerList.new(index: @index, entries: filter(operation.to_s))
      end

      # Yields the handlers in stack order, which is reverse priority.
      def each(&block)
        entries.sort.each do |entry|
          yield(entry.handler_class) if entry.operations.nil?
        end
      end

      # Constructs the handlers recursively, building a handler stack.
      # The `:send` handler will be at the top of the stack and the
      # `:validate` handlers will be at the bottom.
      # @return [Handler]
      def to_stack
        inject(nil) { |stack, handler| handler.new(stack) }
      end

      private

      def add_entries(entries)
        @mutex.synchronize do
          entries.each { |entry| add_entry(entry) }
        end
      end

      def add_entry(entry)
        key = entry.step == :send ? :send : entry.object_id
        @entries[key] = entry
      end

      def filter(operation)
        entries.inject([]) do |filtered, entry|
          if entry.operations.nil?
            filtered << entry.copy
          elsif entry.operations.include?(operation)
            filtered << entry.copy(operations: nil)
          end
          filtered
        end
      end

      def next_index
        @index += 1
      end

    end
  end
end
module Seahorse
  module Client

    # A container for an un-constructed handler. A handler entry has the
    # handler class, and information about handler priority/order.
    #
    # This class is an implementation detail of the {HandlerList} class.
    # Do not rely on public interfaces of this class.
    class HandlerListEntry

      STEPS = {
        initialize: 400,
        validate: 300,
        build: 200,
        sign: 100,
        send: 0,
      }

      # @option options [required, Class<Handler>] :handler_class
      # @option options [required, Integer] :inserted The insertion
      #   order/position. This is used to determine sort order when two
      #   entries have the same priority.
      # @option options [Symbol] :step (:build)
      # @option options [Integer] :priority (50)
      # @option options [Set<String>] :operations
      def initialize(options)
        @options = options
        @handler_class = option(:handler_class, options)
        @inserted = option(:inserted, options)
        @operations = options[:operations]
        @operations = Set.new(options[:operations]).map(&:to_s) if @operations
        set_step(options[:step] || :build)
        set_priority(options[:priority] || 50)
        compute_weight
      end

      # @return [Handler, Class<Handler>] Returns the handler.  This may
      #   be a constructed handler object or a handler class.
      attr_reader :handler_class

      # @return [Integer] The insertion order/position.  This is used to
      #   determine sort order when two entries have the same priority.
      #   Entries inserted later (with a higher inserted value) have a
      #   lower priority.
      attr_reader :inserted

      # @return [Symbol]
      attr_reader :step

      # @return [Integer]
      attr_reader :priority

      # @return [Set<String>]
      attr_reader :operations

      # @return [Integer]
      attr_reader :weight

      # @api private
      def <=>(other)
        if weight == other.weight
          other.inserted <=> inserted
        else
          weight <=> other.weight
        end
      end

      # @option options (see #initialize)
      # @return [HandlerListEntry]
      def copy(options = {})
        HandlerListEntry.new(@options.merge(options))
      end

      private

      def option(name, options)
        if options.key?(name)
          options[name]
        else
          msg = "invalid :priority `%s', must be between 0 and 99"
          raise ArgumentError, msg % priority.inspect
        end
      end

      def set_step(step)
        if STEPS.key?(step)
          @step = step
        else
          msg = "invalid :step `%s', must be one of :initialize, :validate, "
          msg << ":build, :sign or :send"
          raise ArgumentError, msg % step.inspect
        end
      end

      def set_priority(priority)
        if (0..99).include?(priority)
          @priority = priority
        else
          msg = "invalid :priority `%s', must be between 0 and 99"
          raise ArgumentError, msg % priority.inspect
        end
      end

      def compute_weight
        @weight = STEPS[@step] + @priority
      end

    end
  end
end
module Seahorse
  module Client
    # This utility class is used to track files opened by Seahorse.
    # This allows Seahorse to know what files it needs to close.
    class ManagedFile < File

      # @return [Boolean]
      def open?
        !closed?
      end

    end
  end
end
module Seahorse
  module Client
    class NetworkingError < StandardError

      def initialize(error, msg = nil)
        super(msg || error.message)
        set_backtrace(error.backtrace)
        @original_error = error
      end

      attr_reader :original_error

    end

    # Raised when sending initial headers and data failed
    # for event stream requests over Http2
    class Http2InitialRequestError < StandardError

      def initialize(error)
        @original_error = error
      end

      # @return [HTTP2::Error]
      attr_reader :original_error

    end

    # Raised when connection failed to initialize a new stream
    class Http2StreamInitializeError < StandardError

      def initialize(error)
        @original_error = error
      end

      # @return [HTTP2::Error]
      attr_reader :original_error

    end

    # Rasied when trying to use an closed connection
    class Http2ConnectionClosedError < StandardError; end
  end
end
module Seahorse
  module Client
    class Plugin

      extend HandlerBuilder

      # @param [Configuration] config
      # @return [void]
      def add_options(config)
        self.class.options.each do |option|
          if option.default_block
            config.add_option(option.name, &option.default_block)
          else
            config.add_option(option.name, option.default)
          end
        end
      end

      # @param [HandlerList] handlers
      # @param [Configuration] config
      # @return [void]
      def add_handlers(handlers, config)
        handlers.copy_from(self.class.handlers)
      end

      # @param [Class<Client::Base>] client_class
      # @param [Hash] options
      # @return [void]
      def before_initialize(client_class, options)
        self.class.before_initialize_hooks.each do |block|
          block.call(client_class, options)
        end
      end

      # @param [Client::Base] client
      # @return [void]
      def after_initialize(client)
        self.class.after_initialize_hooks.each do |block|
          block.call(client)
        end
      end

      class << self

        # @overload option(name, options = {}, &block)
        # @option options [Object] :default Can also be set by passing a block.
        # @option options [String] :doc_default
        # @option options [Boolean] :required
        # @option options [String] :doc_type
        # @option options [String] :docs
        # @return [void]
        def option(name, default = nil, options = {}, &block)
          # For backwards-compat reasons, the default value can be passed as 2nd
          # positional argument (before the options hash) or as the `:default` option
          # in the options hash.
          if Hash === default
            options = default
          else
            options[:default] = default
          end
          options[:default_block] = Proc.new if block_given?
          self.options << PluginOption.new(name, options)
        end

        def before_initialize(&block)
          before_initialize_hooks << block
        end

        def after_initialize(&block)
          after_initialize_hooks << block
        end

        # @api private
        def options
          @options ||= []
        end

        # @api private
        def handlers
          @handlers ||= HandlerList.new
        end

        # @api private
        def before_initialize_hooks
          @before_initialize_hooks ||= []
        end

        # @api private
        def after_initialize_hooks
          @after_initialize_hooks ||= []
        end

        # @api private
        def literal(string)
          CodeLiteral.new(string)
        end

        # @api private
        class CodeLiteral < String
          def inspect
            to_s
          end
        end

      end

      # @api private
      class PluginOption

        def initialize(name, options = {})
          @name = name
          options.each_pair do |opt_name, opt_value|
            self.send("#{opt_name}=", opt_value)
          end
        end

        attr_reader :name
        attr_accessor :default
        attr_accessor :default_block
        attr_accessor :required
        attr_accessor :doc_type
        attr_accessor :doc_default
        attr_accessor :docstring

        def doc_default
          if @doc_default.nil?
            Proc === default ? nil : default
          else
            @doc_default
          end
        end

        def documented?
          !!docstring
        end

      end
    end
  end
end
require 'set'
require 'thread'

module Seahorse
  module Client
    class PluginList

      include Enumerable

      # @param [Array, Set] plugins
      # @option options [Mutex] :mutex
      def initialize(plugins = [], options = {})
        @mutex = options[:mutex] || Mutex.new
        @plugins = Set.new
        if plugins.is_a?(PluginList)
          plugins.send(:each_plugin) { |plugin| _add(plugin) }
        else
          plugins.each { |plugin| _add(plugin) }
        end
      end

      # Adds and returns the `plugin`.
      # @param [Plugin] plugin
      # @return [void]
      def add(plugin)
        @mutex.synchronize do
          _add(plugin)
        end
        nil
      end

      # Removes and returns the `plugin`.
      # @param [Plugin] plugin
      # @return [void]
      def remove(plugin)
        @mutex.synchronize do
          @plugins.delete(PluginWrapper.new(plugin))
        end
        nil
      end

      # Replaces the existing list of plugins.
      # @param [Array<Plugin>] plugins
      # @return [void]
      def set(plugins)
        @mutex.synchronize do
          @plugins.clear
          plugins.each do |plugin|
            _add(plugin)
          end
        end
        nil
      end

      # Enumerates the plugins.
      # @return [Enumerator]
      def each(&block)
        each_plugin do |plugin_wrapper|
          yield(plugin_wrapper.plugin)
        end
      end

      private

      # Not safe to call outside the mutex.
      def _add(plugin)
        @plugins << PluginWrapper.new(plugin)
      end

      # Yield each PluginDetail behind the mutex
      def each_plugin(&block)
        @mutex.synchronize do
          @plugins.each(&block)
        end
      end

      # A utility class that computes the canonical name for a plugin
      # and defers requiring the plugin until the plugin class is
      # required.
      # @api private
      class PluginWrapper

        # @param [String, Symbol, Module, Class] plugin
        def initialize(plugin)
          case plugin
          when Module
            @canonical_name = plugin.name || plugin.object_id
            @plugin = plugin
          when Symbol, String
            words = plugin.to_s.split('.')
            @canonical_name = words.pop
            @gem_name = words.empty? ? nil : words.join('.')
            @plugin = nil
          else
            @canonical_name = plugin.object_id
            @plugin = plugin
          end
        end

        # @return [String]
        attr_reader :canonical_name

        # @return [Class<Plugin>]
        def plugin
          @plugin ||= require_plugin
        end

        # Returns the given plugin if it is already a PluginWrapper.
        def self.new(plugin)
          if plugin.is_a?(self)
            plugin
          else
            super
          end
        end

        # @return [Boolean]
        # @api private
        def eql? other
          canonical_name == other.canonical_name
        end

        # @return [String]
        # @api private
        def hash
          canonical_name.hash
        end

        private

        # @return [Class<Plugin>]
        def require_plugin
          require(@gem_name) if @gem_name
          plugin_class = Kernel
          @canonical_name.split('::').each do |const_name|
            plugin_class = plugin_class.const_get(const_name)
          end
          plugin_class
        end

      end
    end
  end
end
module Seahorse
  module Client
    class Request

      include HandlerBuilder

      # @param [HandlerList] handlers
      # @param [RequestContext] context
      def initialize(handlers, context)
        @handlers = handlers
        @context = context
      end

      # @return [HandlerList]
      attr_reader :handlers

      # @return [RequestContext]
      attr_reader :context

      # Sends the request, returning a {Response} object.
      #
      #     response = request.send_request
      #
      # # Streaming Responses
      #
      # By default, HTTP responses are buffered into memory.  This can be
      # bad if you are downloading large responses, e.g. large files.
      # You can avoid this by streaming the response to a block or some other
      # target.
      #
      # ## Streaming to a File
      #
      # You can stream the raw HTTP response body to a File, or any IO-like
      # object, by passing the `:target` option.
      #
      #     # create a new file at the given path
      #     request.send_request(target: '/path/to/target/file')
      #
      #     # or provide an IO object to write to
      #     File.open('photo.jpg', 'wb') do |file|
      #       request.send_request(target: file)
      #     end
      #
      # **Please Note**: The target IO object may receive `#truncate(0)`
      # if the request generates a networking error and bytes have already
      # been written to the target.
      #
      # ## Block Streaming
      #
      # Pass a block to `#send_request` and the response will be yielded in
      # chunks to the given block.
      #
      #     # stream the response data
      #     request.send_request do |chunk|
      #       file.write(chunk)
      #     end
      #
      # **Please Note**: When streaming to a block, it is not possible to
      # retry failed requests.
      #
      # @option options [String, IO] :target When specified, the HTTP response
      #   body is written to target.  This is helpful when you are sending
      #   a request that may return a large payload that you don't want to
      #   load into memory.
      #
      # @return [Response]
      #
      def send_request(options = {}, &block)
        @context[:response_target] = options[:target] || block
        @handlers.to_stack.call(@context)
      end

    end
  end
end
require 'stringio'

module Seahorse
  module Client
    class RequestContext

      # @option options [required,Symbol] :operation_name (nil)
      # @option options [required,Model::Operation] :operation (nil)
      # @option options [Model::Authorizer] :authorizer (nil)
      # @option options [Hash] :params ({})
      # @option options [Configuration] :config (nil)
      # @option options [Http::Request] :http_request (Http::Request.new)
      # @option options [Http::Response] :http_response (Http::Response.new)
      #   and #rewind.
      def initialize(options = {})
        @operation_name = options[:operation_name]
        @operation = options[:operation]
        @authorizer = options[:authorizer]
        @client = options[:client]
        @params = options[:params] || {}
        @config = options[:config]
        @http_request = options[:http_request] || Http::Request.new
        @http_response = options[:http_response] || Http::Response.new
        @retries = 0
        @metadata = {}
      end

      # @return [Symbol] Name of the API operation called.
      attr_accessor :operation_name

      # @return [Model::Operation]
      attr_accessor :operation

      # @return [Model::Authorizer] APIG SDKs only
      attr_accessor :authorizer

      # @return [Seahorse::Client::Base]
      attr_accessor :client

      # @return [Hash] The hash of request parameters.
      attr_accessor :params

      # @return [Configuration] The client configuration.
      attr_accessor :config

      # @return [Http::Request]
      attr_accessor :http_request

      # @return [Http::Response]
      attr_accessor :http_response

      # @return [Integer]
      attr_accessor :retries

      # @return [Hash]
      attr_reader :metadata

      # Returns the metadata for the given `key`.
      # @param [Symbol] key
      # @return [Object]
      def [](key)
        @metadata[key]
      end

      # Sets the request context metadata for the given `key`.  Request metadata
      # useful for handlers that need to keep state on the request, without
      # sending that data with the request over HTTP.
      # @param [Symbol] key
      # @param [Object] value
      def []=(key, value)
        @metadata[key] = value
      end

    end
  end
end
require 'delegate'

module Seahorse
  module Client
    class Response < Delegator

      # @option options [RequestContext] :context (nil)
      # @option options [Integer] :status_code (nil)
      # @option options [Http::Headers] :headers (Http::Headers.new)
      # @option options [String] :body ('')
      def initialize(options = {})
        @context = options[:context] || RequestContext.new
        @data = options[:data]
        @error = options[:error]
        @http_request = @context.http_request
        @http_response = @context.http_response
        @http_response.on_error do |error|
          @error = error
        end
      end

      # @return [RequestContext]
      attr_reader :context

      # @return The response data.  This may be `nil` if the response contains
      #   an {#error}.
      attr_accessor :data

      # @return [StandardError, nil]
      attr_accessor :error

      # @overload on(status_code, &block)
      #   @param [Integer] status_code The block will be
      #     triggered only for responses with the given status code.
      #
      # @overload on(status_code_range, &block)
      #   @param [Range<Integer>] status_code_range The block will be
      #     triggered only for responses with a status code that falls
      #     witin the given range.
      #
      # @return [self]
      def on(range, &block)
        response = self
        @context.http_response.on_success(range) do
          block.call(response)
        end
        self
      end

      # Yields to the block if the response has a 200 level status code.
      # @return [self]
      def on_success(&block)
        on(200..299, &block)
      end

      # @return [Boolean] Returns `true` if the response is complete with
      #   a ~ 200 level http status code.
      def successful?
        (200..299).include?(@context.http_response.status_code) && @error.nil?
      end

      # @api private
      def on_complete(&block)
        @context.http_response.on_done(&block)
        self
      end

      # Necessary to define as a subclass of Delegator
      # @api private
      def __getobj__
        @data
      end

      # Necessary to define as a subclass of Delegator
      # @api private
      def __setobj__(obj)
        @data = obj
      end

    end
  end
end
module Seahorse
  module Client
    class AsyncResponse

      def initialize(options = {})
        @response = Response.new(context: options[:context])
        @stream = options[:stream]
        @stream_mutex = options[:stream_mutex]
        @close_condition = options[:close_condition]
        @sync_queue = options[:sync_queue]
      end

      def context
        @response.context
      end

      def error
        @response.error
      end

      def on(range, &block)
        @response.on(range, &block)
        self
      end

      def on_complete(&block)
        @response.on_complete(&block)
        self
      end

      def wait
        if error && context.config.raise_response_errors
          raise error
        elsif @stream
          # have a sync signal that #signal can be blocked on
          # else, if #signal is called before #wait
          # will be waiting for a signal never arrives
          @sync_queue << "sync_signal"
          # now #signal is unlocked for
          # signaling close condition when ready
          @stream_mutex.synchronize {
            @close_condition.wait(@stream_mutex)
          }
          @response
        end
      end

      def join!
        if error && context.config.raise_response_errors
          raise error
        elsif @stream
          # close callback is waiting
          # for the "sync_signal"
          @sync_queue << "sync_signal"
          @stream.close
          @response
        end
      end

    end
  end
end
module Seahorse
  module Client
    module Http

      # Provides a Hash-like interface for HTTP headers.  Header names
      # are treated indifferently as lower-cased strings.  Header values
      # are cast to strings.
      #
      #     headers = Http::Headers.new
      #     headers['Content-Length'] = 100
      #     headers[:Authorization] = 'Abc'
      #
      #     headers.keys
      #     #=> ['content-length', 'authorization']
      #
      #     headers.values
      #     #=> ['100', 'Abc']
      #
      # You can get the header values as a vanilla hash by calling {#to_h}:
      #
      #     headers.to_h
      #     #=> { 'content-length' => '100', 'authorization' => 'Abc' }
      #
      class Headers

        include Enumerable

        # @api private
        def initialize(headers = {})
          @data = {}
          headers.each_pair do |key, value|
            self[key] = value
          end
        end

        # @param [String] key
        # @return [String]
        def [](key)
          @data[key.to_s.downcase]
        end

        # @param [String] key
        # @param [String] value
        def []=(key, value)
          @data[key.to_s.downcase] = value.to_s
        end

        # @param [Hash] headers
        # @return [Headers]
        def update(headers)
          headers.each_pair do |k, v|
            self[k] = v
          end
          self
        end

        # @param [String] key
        def delete(key)
          @data.delete(key.to_s.downcase)
        end

        def clear
          @data = {}
        end

        # @return [Array<String>]
        def keys
          @data.keys
        end

        # @return [Array<String>]
        def values
          @data.values
        end

        # @return [Array<String>]
        def values_at(*keys)
          @data.values_at(*keys.map{ |key| key.to_s.downcase })
        end

        # @yield [key, value]
        # @yieldparam [String] key
        # @yieldparam [String] value
        # @return [nil]
        def each(&block)
          if block_given?
            @data.each_pair do |key, value|
              yield(key, value)
            end
            nil
          else
            @data.enum_for(:each)
          end
        end
        alias each_pair each

        # @return [Boolean] Returns `true` if the header is set.
        def key?(key)
          @data.key?(key.to_s.downcase)
        end
        alias has_key? key?
        alias include? key?

        # @return [Hash]
        def to_hash
          @data.dup
        end
        alias to_h to_hash

        # @api private
        def inspect
          @data.inspect
        end

      end
    end
  end
end
require 'stringio'
require 'uri'

module Seahorse
  module Client
    module Http
      class Request

        # @option options [URI::HTTP, URI::HTTPS] :endpoint (nil)
        # @option options [String] :http_method ('GET')
        # @option options [Headers] :headers (Headers.new)
        # @option options [Body] :body (StringIO.new)
        def initialize(options = {})
          self.endpoint = options[:endpoint]
          self.http_method = options[:http_method] || 'GET'
          self.headers = Headers.new(options[:headers] || {})
          self.body = options[:body]
        end

        # @return [String] The HTTP request method, e.g. `GET`, `PUT`, etc.
        attr_accessor :http_method

        # @return [Headers] The hash of request headers.
        attr_accessor :headers

        # @return [URI::HTTP, URI::HTTPS, nil]
        def endpoint
          @endpoint
        end

        # @param [String, URI::HTTP, URI::HTTPS, nil] endpoint
        def endpoint=(endpoint)
          endpoint = URI.parse(endpoint) if endpoint.is_a?(String)
          if endpoint.nil? or URI::HTTP === endpoint or URI::HTTPS === endpoint
            @endpoint = endpoint
          else
            msg = "invalid endpoint, expected URI::HTTP, URI::HTTPS, or nil, "
            msg << "got #{endpoint.inspect}"
            raise ArgumentError, msg
          end
        end

        # @return [IO]
        def body
          @body
        end

        # @return [String]
        def body_contents
          body.rewind
          contents = body.read
          body.rewind
          contents
        end

        # @param [#read, #size, #rewind] io
        def body=(io)
          @body =case io
            when nil then StringIO.new('')
            when String then StringIO.new(io)
            else io
          end
        end

      end
    end
  end
end
module Seahorse
  module Client
    module Http
      class Response

        # @option options [Integer] :status_code (0)
        # @option options [Headers] :headers (Headers.new)
        # @option options [IO] :body (StringIO.new)
        def initialize(options = {})
          @status_code = options[:status_code] || 0
          @headers = options[:headers] || Headers.new
          @body = options[:body] || StringIO.new
          @listeners = Hash.new { |h,k| h[k] = [] }
          @complete = false
          @done = nil
          @error = nil
        end

        # @return [Integer] Returns `0` if the request failed to generate
        #   any response.
        attr_accessor :status_code

        # @return [Headers]
        attr_accessor :headers

        # @return [StandardError, nil]
        attr_reader :error

        # @return [IO]
        def body
          @body
        end

        # @param [#read, #size, #rewind] io
        def body=(io)
          @body = case io
            when nil then StringIO.new('')
            when String then StringIO.new(io)
            else io
          end
        end

        # @return [String|Array]
        def body_contents
          if body.is_a?(Array)
            # an array of parsed events
            body
          else
            body.rewind
            contents = body.read
            body.rewind
            contents
          end
        end

        # @param [Integer] status_code
        # @param [Hash<String,String>] headers
        def signal_headers(status_code, headers)
          @status_code = status_code
          @headers = Headers.new(headers)
          emit(:headers, @status_code, @headers)
        end

        # @param [string] chunk
        def signal_data(chunk)
          unless chunk == ''
            @body.write(chunk)
            emit(:data, chunk)
          end
        end

        # Completes the http response.
        #
        # @example Completing the response in a singal call
        #
        #     http_response.signal_done(
        #       status_code: 200,
        #       headers: {},
        #       body: ''
        #     )
        #
        # @example Complete the response in parts
        #
        #     # signal headers straight-way
        #     http_response.signal_headers(200, {})
        #
        #     # signal data as it is received from the socket
        #     http_response.signal_data("...")
        #     http_response.signal_data("...")
        #     http_response.signal_data("...")
        #
        #     # signal done once the body data is all written
        #     http_response.signal_done
        #
        # @overload signal_done()
        #
        # @overload signal_done(options = {})
        #   @option options [required, Integer] :status_code
        #   @option options [required, Hash] :headers
        #   @option options [required, String] :body
        #
        def signal_done(options = {})
          if options.keys.sort == [:body, :headers, :status_code]
            signal_headers(options[:status_code], options[:headers])
            signal_data(options[:body])
            signal_done
          elsif options.empty?
            @body.rewind if @body.respond_to?(:rewind)
            @done = true
            emit(:done)
          else
            msg = "options must be empty or must contain :status_code, :headers, "
            msg << "and :body"
            raise ArgumentError, msg
          end
        end

        # @param [StandardError] networking_error
        def signal_error(networking_error)
          @error = networking_error
          signal_done
        end

        def on_headers(status_code_range = nil, &block)
          @listeners[:headers] << listener(status_code_range, Proc.new)
        end

        def on_data(&callback)
          @listeners[:data] << Proc.new
        end

        def on_done(status_code_range = nil, &callback)
          listener = listener(status_code_range, Proc.new)
          if @done
            listener.call
          else
            @listeners[:done] << listener
          end
        end

        def on_success(status_code_range = 200..599, &callback)
          on_done(status_code_range) do
            unless @error
              yield
            end
          end
        end

        def on_error(&callback)
          on_done(0..599) do
            if @error
              yield(@error)
            end
          end
        end

        def reset
          @status_code = 0
          @headers.clear
          @body.truncate(0)
          @error = nil
        end

        private

        def listener(range, callback)
          range = range..range if Integer === range
          if range
            lambda do |*args|
              if range.include?(@status_code)
                callback.call(*args)
              end
            end
          else
            callback
          end
        end

        def emit(event_name, *args)
          @listeners[event_name].each { |listener| listener.call(*args) }
        end

      end
    end
  end
end
module Seahorse
  module Client
    module Http
      class AsyncResponse < Seahorse::Client::Http::Response

        def initialize(options = {})
          super
        end

        def signal_headers(headers)
          # H2 headers arrive as array of pair
          hash = headers.inject({}) do |h, pair|
            key, value = pair
            h[key] = value
            h
          end
          @status_code = hash[":status"].to_i
          @headers = Headers.new(hash)
          emit(:headers, @status_code, @headers)
        end

        def signal_done(options = {})
          # H2 only has header and body
          # ':status' header will be sent back
          if options.keys.sort == [:body, :headers]
            signal_headers(options[:headers])
            signal_data(options[:body])
            signal_done
          elsif options.empty?
            @body.rewind if @body.respond_to?(:rewind)
            @done = true
            emit(:done)
          else
            msg = "options must be empty or must contain :headers and :body"
            raise ArgumentError, msg
          end
        end

      end
    end
  end
end
module Seahorse
  module Client
    # @deprecated Use Aws::Logging instead.
    # @api private
    module Logging
      class Handler < Client::Handler

        # @param [RequestContext] context
        # @return [Response]
        def call(context)
          context[:logging_started_at] = Time.now
          @handler.call(context).tap do |response|
            context[:logging_completed_at] = Time.now
            log(context.config, response)
          end
        end

        private

        # @param [Configuration] config
        # @param [Response] response
        # @return [void]
        def log(config, response)
          config.logger.send(config.log_level, format(config, response))
        end

        # @param [Configuration] config
        # @param [Response] response
        # @return [String]
        def format(config, response)
          config.log_formatter.format(response)
        end

      end
    end
  end
end
require 'pathname'

module Seahorse
  module Client
    # @deprecated Use Aws::Logging instead.
    # @api private
    module Logging

      # A log formatter receives a {Response} object and return
      # a log message as a string. When you construct a {Formatter}, you provide
      # a pattern string with substitutions.
      #
      #     pattern = ':operation :http_response_status_code :time'
      #     formatter = Seahorse::Client::Logging::Formatter.new(pattern)
      #     formatter.format(response)
      #     #=> 'get_bucket 200 0.0352'
      #
      # # Canned Formatters
      #
      # Instead of providing your own pattern, you can choose a canned log
      # formatter.
      #
      # * {Formatter.default}
      # * {Formatter.colored}
      # * {Formatter.short}
      #
      # # Pattern Substitutions
      #
      # You can put any of these placeholders into you pattern.
      #
      #   * `:client_class` - The name of the client class.
      #
      #   * `:operation` - The name of the client request method.
      #
      #   * `:request_params` - The user provided request parameters. Long
      #     strings are truncated/summarized if they exceed the
      #     {#max_string_size}.  Other objects are inspected.
      #
      #   * `:time` - The total time in seconds spent on the
      #     request.  This includes client side time spent building
      #     the request and parsing the response.
      #
      #   * `:retries` - The number of times a client request was retried.
      #
      #   * `:http_request_method` - The http request verb, e.g., `POST`,
      #     `PUT`, `GET`, etc.
      #
      #   * `:http_request_endpoint` - The request endpoint.  This includes
      #      the scheme, host and port, but not the path.
      #
      #   * `:http_request_scheme` - This is replaced by `http` or `https`.
      #
      #   * `:http_request_host` - The host name of the http request
      #     endpoint (e.g. 's3.amazon.com').
      #
      #   * `:http_request_port` - The port number (e.g. '443' or '80').
      #
      #   * `:http_request_headers` - The http request headers, inspected.
      #
      #   * `:http_request_body` - The http request payload.
      #
      #   * `:http_response_status_code` - The http response status
      #     code, e.g., `200`, `404`, `500`, etc.
      #
      #   * `:http_response_headers` - The http response headers, inspected.
      #
      #   * `:http_response_body` - The http response body contents.
      #
      #   * `:error_class`
      #
      #   * `:error_message`
      #
      class Formatter

        # @param [String] pattern The log format pattern should be a string
        #   and may contain substitutions.
        #
        # @option options [Integer] :max_string_size (1000) When summarizing
        #   request parameters, strings longer than this value will be
        #   truncated.
        #
        def initialize(pattern, options = {})
          @pattern = pattern
          @max_string_size = options[:max_string_size] || 1000
        end

        # @return [String]
        attr_reader :pattern

        # @return [Integer]
        attr_reader :max_string_size

        # Given a {Response}, this will format a log message and return it
        #   as a string.
        # @param [Response] response
        # @return [String]
        def format(response)
          pattern.gsub(/:(\w+)/) {|sym| send("_#{sym[1..-1]}", response) }
        end

        # @api private
        def eql?(other)
          other.is_a?(self.class) and other.pattern == self.pattern
        end
        alias :== :eql?

        private

        def method_missing(method_name, *args)
          if method_name.to_s.chars.first == '_'
            ":#{method_name.to_s[1..-1]}"
          else
            super
          end
        end

        def _client_class(response)
          response.context.client.class.name
        end

        def _operation(response)
          response.context.operation_name
        end

        def _request_params(response)
          summarize_hash(response.context.params)
        end

        def _time(response)
          duration = response.context[:logging_completed_at] -
            response.context[:logging_started_at]
          ("%.06f" % duration).sub(/0+$/, '')
        end

        def _retries(response)
          response.context.retries
        end

        def _http_request_endpoint(response)
          response.context.http_request.endpoint.to_s
        end

        def _http_request_scheme(response)
          response.context.http_request.endpoint.scheme
        end

        def _http_request_host(response)
          response.context.http_request.endpoint.host
        end

        def _http_request_port(response)
          response.context.http_request.endpoint.port.to_s
        end

        def _http_request_method(response)
          response.context.http_request.http_method
        end

        def _http_request_headers(response)
          response.context.http_request.headers.inspect
        end

        def _http_request_body(response)
          summarize_value(response.context.http_request.body_contents)
        end

        def _http_response_status_code(response)
          response.context.http_response.status_code.to_s
        end

        def _http_response_headers(response)
          response.context.http_response.headers.inspect
        end

        def _http_response_body(response)
          response.context.http_response.body.respond_to?(:rewind) ?
            summarize_value(response.context.http_response.body_contents) :
            ''
        end

        def _error_class(response)
          response.error ? response.error.class.name : ''
        end

        def _error_message(response)
          response.error ? response.error.message : ''
        end

        # @param [Hash] hash
        # @return [String]
        def summarize_hash(hash)
          hash.keys.first.is_a?(String) ?
            summarize_string_hash(hash) :
            summarize_symbol_hash(hash)
        end

        def summarize_symbol_hash(hash)
          hash.map do |key,v|
            "#{key}:#{summarize_value(v)}"
          end.join(",")
        end

        def summarize_string_hash(hash)
          hash.map do |key,v|
            "#{key.inspect}=>#{summarize_value(v)}"
          end.join(",")
        end

        # @param [Object] value
        # @return [String]
        def summarize_value value
          case value
          when String   then summarize_string(value)
          when Hash     then '{' + summarize_hash(value) + '}'
          when Array    then summarize_array(value)
          when File     then summarize_file(value.path)
          when Pathname then summarize_file(value)
          else value.inspect
          end
        end

        # @param [String] str
        # @return [String]
        def summarize_string str
          max = max_string_size
          if str.size > max
            "#<String #{str[0...max].inspect} ... (#{str.size} bytes)>"
          else
            str.inspect
          end
        end

        # Given the path to a file on disk, this method returns a summarized
        # inspecton string that includes the file size.
        # @param [String] path
        # @return [String]
        def summarize_file path
          "#<File:#{path} (#{File.size(path)} bytes)>"
        end

        # @param [Array] array
        # @return [String]
        def summarize_array array
          "[" + array.map{|v| summarize_value(v) }.join(",") + "]"
        end

        class << self

          # The default log format.
          #
          # @example A sample of the default format.
          #
          #     [ClientClass 200 0.580066 0 retries] list_objects(:bucket_name => 'bucket')
          #
          # @return [Formatter]
          #
          def default
            pattern = []
            pattern << "[:client_class"
            pattern << ":http_response_status_code"
            pattern << ":time"
            pattern << ":retries retries]"
            pattern << ":operation(:request_params)"
            pattern << ":error_class"
            pattern << ":error_message"
            Formatter.new(pattern.join(' ') + "\n")
          end

          # The short log format.  Similar to default, but it does not
          # inspect the request params or report on retries.
          #
          # @example A sample of the short format
          #
          #     [ClientClass 200 0.494532] list_buckets
          #
          # @return [Formatter]
          #
          def short
            pattern = []
            pattern << "[:client_class"
            pattern << ":http_response_status_code"
            pattern << ":time]"
            pattern << ":operation"
            pattern << ":error_class"
            Formatter.new(pattern.join(' ') + "\n")
          end

          # The default log format with ANSI colors.
          #
          # @example A sample of the colored format (sans the ansi colors).
          #
          #     [ClientClass 200 0.580066 0 retries] list_objects(:bucket_name => 'bucket')
          #
          # @return [Formatter]
          #
          def colored
            bold = "\x1b[1m"
            color = "\x1b[34m"
            reset = "\x1b[0m"
            pattern = []
            pattern << "#{bold}#{color}[:client_class"
            pattern << ":http_response_status_code"
            pattern << ":time"
            pattern << ":retries retries]#{reset}#{bold}"
            pattern << ":operation(:request_params)"
            pattern << ":error_class"
            pattern << ":error_message#{reset}"
            Formatter.new(pattern.join(' ') + "\n")
          end

        end

      end
    end
  end
end
require 'net/http'

module Seahorse
  module Client
    # @api private
    module NetHttp

      # @api private
      module Patches

        def self.apply!
          return unless RUBY_VERSION < '2.5'
          if RUBY_VERSION >= '2.3'
            Net::HTTP::IDEMPOTENT_METHODS_.clear
            return
          end
          # no further patches needed for above versions

          if RUBY_VERSION >= '2.0'
            Net::HTTP.send(:include, Ruby_2)
            Net::HTTP::IDEMPOTENT_METHODS_.clear
          elsif RUBY_VERSION >= '1.9.3'
            Net::HTTP.send(:include, Ruby_1_9_3)
          end
          Net::HTTP.send(:alias_method, :old_transport_request, :transport_request)
          Net::HTTP.send(:alias_method, :transport_request, :new_transport_request)
        end

        module Ruby_2
          def new_transport_request(req)
            count = 0
            begin
              begin_transport req
              res = catch(:response) {
                req.exec @socket, @curr_http_version, edit_path(req.path)
                begin
                  res = Net::HTTPResponse.read_new(@socket)
                  res.decode_content = req.decode_content
                end while res.kind_of?(Net::HTTPInformation)

                res.uri = req.uri

                res
              }
              res.reading_body(@socket, req.response_body_permitted?) {
                yield res if block_given?
              }
            rescue Net::OpenTimeout
              raise
            rescue Net::ReadTimeout, IOError, EOFError,
                   Errno::ECONNRESET, Errno::ECONNABORTED, Errno::EPIPE,
                   # avoid a dependency on OpenSSL
                   defined?(OpenSSL::SSL) ? OpenSSL::SSL::SSLError : IOError,
                   Timeout::Error => exception
              if count == 0 && Net::HTTP::IDEMPOTENT_METHODS_.include?(req.method)
                count += 1
                @socket.close if @socket and not @socket.closed?
                D "Conn close because of error #{exception}, and retry"
                if req.body_stream
                  if req.body_stream.respond_to?(:rewind)
                    req.body_stream.rewind
                  else
                    raise
                  end
                end
                retry
              end
              D "Conn close because of error #{exception}"
              @socket.close if @socket and not @socket.closed?
              raise
            end

            end_transport req, res
            res
          rescue => exception
            D "Conn close because of error #{exception}"
            @socket.close if @socket and not @socket.closed?
            raise exception
          end
        end

        module Ruby_1_9_3
          def new_transport_request(req)
            begin_transport req
            res = catch(:response) {
              req.exec @socket, @curr_http_version, edit_path(req.path)
              begin
                res = Net::HTTPResponse.read_new(@socket)
              end while res.kind_of?(Net::HTTPContinue)
              res
            }
            res.reading_body(@socket, req.response_body_permitted?) {
              yield res if block_given?
            }
            end_transport req, res
            res
          rescue => exception
            D "Conn close because of error #{exception}"
            @socket.close if @socket and not @socket.closed?
            raise exception
          end
        end
      end
    end
  end
end
require 'cgi'
require 'net/http'
require 'net/https'
require 'delegate'
require 'thread'
require 'logger'

# KG-dev::RubyPacker replaced for patches.rb

Seahorse::Client::NetHttp::Patches.apply!

module Seahorse
  module Client
    # @api private
    module NetHttp

      class ConnectionPool

        @pools_mutex = Mutex.new
        @pools = {}

        OPTIONS = {
          http_proxy: nil,
          http_open_timeout: 15,
          http_read_timeout: 60,
          http_idle_timeout: 5,
          http_continue_timeout: 1,
          http_wire_trace: false,
          logger: nil,
          ssl_verify_peer: true,
          ssl_ca_bundle: nil,
          ssl_ca_directory: nil,
          ssl_ca_store: nil,
        }

        # @api private
        def initialize(options = {})
          OPTIONS.each_pair do |opt_name, default_value|
            value = options[opt_name].nil? ? default_value : options[opt_name]
            instance_variable_set("@#{opt_name}", value)
          end
          @pool_mutex = Mutex.new
          @pool = {}
        end

        OPTIONS.keys.each do |attr_name|
          attr_reader(attr_name)
        end

        alias http_wire_trace? http_wire_trace
        alias ssl_verify_peer? ssl_verify_peer

        # Makes an HTTP request, yielding a Net::HTTPResponse object.
        #
        #   pool.request('http://domain', Net::HTTP::Get.new('/')) do |resp|
        #     puts resp.code # status code
        #     puts resp.to_h.inspect # dump the headers
        #     puts resp.body
        #   end
        #
        # @param [String] endpoint The HTTP(S) endpoint to
        #    connect to (e.g. 'https://domain.com').
        #
        # @param [Net::HTTPRequest] request The request to make.  This can be
        #   any request object from Net::HTTP (e.g. Net::HTTP::Get,
        #   Net::HTTP::POST, etc).
        #
        # @yieldparam [Net::HTTPResponse] net_http_response
        #
        # @return (see #session_for)
        def request(endpoint, request, &block)
          session_for(endpoint) do |http|
            yield(http.request(request))
          end
        end

        # @param [URI::HTTP, URI::HTTPS] endpoint The HTTP(S) endpoint
        #    to connect to (e.g. 'https://domain.com').
        #
        # @yieldparam [Net::HTTPSession] session
        #
        # @return [nil]
        def session_for(endpoint, &block)
          endpoint = remove_path_and_query(endpoint)
          session = nil

          # attempt to recycle an already open session
          @pool_mutex.synchronize do
            _clean
            if @pool.key?(endpoint)
              session = @pool[endpoint].shift
            end
          end

          begin
            session ||= start_session(endpoint)
            session.read_timeout = http_read_timeout
            session.continue_timeout = http_continue_timeout if
              session.respond_to?(:continue_timeout=)
            yield(session)
          rescue
            session.finish if session
            raise
          else
            # No error raised? Good, check the session into the pool.
            @pool_mutex.synchronize do
              @pool[endpoint] = [] unless @pool.key?(endpoint)
              @pool[endpoint] << session
            end
          end
          nil
        end

        # @return [Integer] Returns the count of sessions currently in the
        #   pool, not counting those currently in use.
        def size
          @pool_mutex.synchronize do
            size = 0
            @pool.each_pair do |endpoint,sessions|
              size += sessions.size
            end
            size
          end
        end

        # Removes stale http sessions from the pool (that have exceeded
        # the idle timeout).
        # @return [nil]
        def clean!
          @pool_mutex.synchronize { _clean }
          nil
        end

        # Closes and removes removes all sessions from the pool.
        # If empty! is called while there are outstanding requests they may
        # get checked back into the pool, leaving the pool in a non-empty
        # state.
        # @return [nil]
        def empty!
          @pool_mutex.synchronize do
            @pool.each_pair do |endpoint,sessions|
              sessions.each(&:finish)
            end
            @pool.clear
          end
          nil
        end

        private

        def remove_path_and_query(endpoint)
          endpoint.dup.tap do |e|
            e.path = ''
            e.query = nil
          end.to_s
        end

        class << self

          # Returns a connection pool constructed from the given options.
          # Calling this method twice with the same options will return
          # the same pool.
          #
          # @option options [URI::HTTP,String] :http_proxy A proxy to send
          #   requests through.  Formatted like 'http://proxy.com:123'.
          #
          # @option options [Float] :http_open_timeout (15) The number of
          #   seconds to wait when opening a HTTP session before rasing a
          #   `Timeout::Error`.
          #
          # @option options [Integer] :http_read_timeout (60) The default
          #   number of seconds to wait for response data.  This value can
          #   safely be set
          #   per-request on the session yeidled by {#session_for}.
          #
          # @option options [Float] :http_idle_timeout (5) The number of
          #   seconds a connection is allowed to sit idble before it is
          #   considered stale.  Stale connections are closed and removed
          #   from the pool before making a request.
          #
          # @option options [Float] :http_continue_timeout (1) The number of
          #   seconds to wait for a 100-continue response before sending the
          #   request body.  This option has no effect unless the request has
          #   "Expect" header set to "100-continue".  Defaults to `nil` which
          #   disables this behaviour.  This value can safely be set per
          #   request on the session yeidled by {#session_for}.
          #
          # @option options [Boolean] :http_wire_trace (false) When `true`,
          #   HTTP debug output will be sent to the `:logger`.
          #
          # @option options [Logger] :logger Where debug output is sent.
          #    Defaults to `nil` when `:http_wire_trace` is `false`.
          #    Defaults to `Logger.new($stdout)` when `:http_wire_trace` is
          #    `true`.
          #
          # @option options [Boolean] :ssl_verify_peer (true) When `true`,
          #   SSL peer certificates are verified when establishing a
          #   connection.
          #
          # @option options [String] :ssl_ca_bundle Full path to the SSL
          #   certificate authority bundle file that should be used when
          #   verifying peer certificates.  If you do not pass
          #   `:ssl_ca_bundle` or `:ssl_ca_directory` the the system default
          #   will be used if available.
          #
          # @option options [String] :ssl_ca_directory Full path of the
          #   directory that contains the unbundled SSL certificate
          #   authority files for verifying peer certificates.  If you do
          #   not pass `:ssl_ca_bundle` or `:ssl_ca_directory` the the
          #   system default will be used if available.
          #
          # @return [ConnectionPool]
          def for options = {}
            options = pool_options(options)
            @pools_mutex.synchronize do
              @pools[options] ||= new(options)
            end
          end

          # @return [Array<ConnectionPool>] Returns a list of of the
          #   constructed connection pools.
          def pools
            @pools_mutex.synchronize do
              @pools.values
            end
          end

          private

          # Filters an option hash, merging in default values.
          # @return [Hash]
          def pool_options options
            wire_trace = !!options[:http_wire_trace]
            logger = options[:logger] || Logger.new($stdout) if wire_trace
            verify_peer = options.key?(:ssl_verify_peer) ?
              !!options[:ssl_verify_peer] : true
            {
              :http_proxy => URI.parse(options[:http_proxy].to_s),
              :http_continue_timeout => options[:http_continue_timeout],
              :http_open_timeout => options[:http_open_timeout] || 15,
              :http_idle_timeout => options[:http_idle_timeout] || 5,
              :http_read_timeout => options[:http_read_timeout] || 60,
              :http_wire_trace => wire_trace,
              :logger => logger,
              :ssl_verify_peer => verify_peer,
              :ssl_ca_bundle => options[:ssl_ca_bundle],
              :ssl_ca_directory => options[:ssl_ca_directory],
              :ssl_ca_store => options[:ssl_ca_store],
            }
          end

        end

        private

        # Extract the parts of the http_proxy URI
        # @return [Array(String)]
        def http_proxy_parts
          return [
            http_proxy.host,
            http_proxy.port,
            (http_proxy.user && CGI::unescape(http_proxy.user)),
            (http_proxy.password && CGI::unescape(http_proxy.password))
          ]
        end

        # Starts and returns a new HTTP(S) session.
        # @param [String] endpoint
        # @return [Net::HTTPSession]
        def start_session endpoint

          endpoint = URI.parse(endpoint)

          args = []
          args << endpoint.host
          args << endpoint.port
          args += http_proxy_parts

          http = ExtendedSession.new(Net::HTTP.new(*args.compact))
          http.set_debug_output(logger) if http_wire_trace?
          http.open_timeout = http_open_timeout

          if endpoint.scheme == 'https'
            http.use_ssl = true
            if ssl_verify_peer?
              http.verify_mode = OpenSSL::SSL::VERIFY_PEER
              http.ca_file = ssl_ca_bundle if ssl_ca_bundle
              http.ca_path = ssl_ca_directory if ssl_ca_directory
              http.cert_store = ssl_ca_store if ssl_ca_store
            else
              http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            end
          else
            http.use_ssl = false
          end

          http.start
          http
        end

        # Removes stale sessions from the pool.  This method *must* be called
        # @note **Must** be called behind a `@pool_mutex` synchronize block.
        def _clean
          now = Time.now
          @pool.each_pair do |endpoint,sessions|
            sessions.delete_if do |session|
              if
                session.last_used.nil? or
                now - session.last_used > http_idle_timeout
              then
                session.finish
                true
              end
            end
          end
        end

        # Helper methods extended onto Net::HTTPSession objects opend by the
        # connection pool.
        # @api private
        class ExtendedSession < Delegator

          def initialize(http)
            super(http)
            @http = http
          end

          # @return [Time,nil]
          attr_reader :last_used

          def __getobj__
            @http
          end

          def __setobj__(obj)
            @http = obj
          end

          # Sends the request and tracks that this session has been used.
          def request(*args, &block)
            @last_used = Time.now
            @http.request(*args, &block)
          end

          # Attempts to close/finish the session without raising an error.
          def finish
            @http.finish
          rescue IOError
            nil
          end

        end
      end
    end
  end
end
require 'net/https'
require 'openssl'

module Seahorse
  module Client
    # @api private
    module NetHttp

      # The default HTTP handler for Seahorse::Client.  This is based on
      # the Ruby's `Net::HTTP`.
      class Handler < Client::Handler

        # @api private
        class TruncatedBodyError < IOError
          def initialize(bytes_expected, bytes_received)
            msg = "http response body truncated, expected #{bytes_expected} "
            msg << "bytes, received #{bytes_received} bytes"
            super(msg)
          end
        end

        NETWORK_ERRORS = [
          SocketError, EOFError, IOError, Timeout::Error,
          Errno::ECONNABORTED, Errno::ECONNRESET, Errno::EPIPE,
          Errno::EINVAL, Errno::ETIMEDOUT, OpenSSL::SSL::SSLError,
          Errno::EHOSTUNREACH, Errno::ECONNREFUSED
        ]

        # does not exist in Ruby 1.9.3
        if OpenSSL::SSL.const_defined?(:SSLErrorWaitReadable)
          NETWORK_ERRORS << OpenSSL::SSL::SSLErrorWaitReadable
        end

        # @api private
        DNS_ERROR_MESSAGES = [
          'getaddrinfo: nodename nor servname provided, or not known', # MacOS
          'getaddrinfo: Name or service not known' # GNU
        ]

        # Raised when a {Handler} cannot construct a `Net::HTTP::Request`
        # from the given http verb.
        class InvalidHttpVerbError < StandardError; end

        # @param [RequestContext] context
        # @return [Response]
        def call(context)
          transmit(context.config, context.http_request, context.http_response)
          Response.new(context: context)
        end

        # @param [Configuration] config
        # @return [ConnectionPool]
        def pool_for(config)
          ConnectionPool.for(pool_options(config))
        end

        private

        def error_message(req, error)
          if error.is_a?(SocketError) && DNS_ERROR_MESSAGES.include?(error.message)
            host = req.endpoint.host
            "unable to connect to `#{host}`; SocketError: #{error.message}"
          else
            error.message
          end
        end

        # @param [Configuration] config
        # @param [Http::Request] req
        # @param [Http::Response] resp
        # @return [void]
        def transmit(config, req, resp)
          session(config, req) do |http|
            http.request(build_net_request(req)) do |net_resp|

              status_code = net_resp.code.to_i
              headers = extract_headers(net_resp)

              bytes_received = 0
              resp.signal_headers(status_code, headers)
              net_resp.read_body do |chunk|
                bytes_received += chunk.bytesize
                resp.signal_data(chunk)
              end
              complete_response(req, resp, bytes_received)

            end
          end
        rescue *NETWORK_ERRORS => error
          # these are retryable
          error = NetworkingError.new(error, error_message(req, error))
          resp.signal_error(error)
        rescue => error
          # not retryable
          resp.signal_error(error)
        end

        def complete_response(req, resp, bytes_received)
          if should_verify_bytes?(req, resp)
            verify_bytes_received(resp, bytes_received)
          else
            resp.signal_done
          end
        end

        def should_verify_bytes?(req, resp)
          req.http_method != 'HEAD' && resp.headers['content-length']
        end

        def verify_bytes_received(resp, bytes_received)
          bytes_expected = resp.headers['content-length'].to_i
          if bytes_expected == bytes_received
            resp.signal_done
          else
            error = TruncatedBodyError.new(bytes_expected, bytes_received)
            resp.signal_error(NetworkingError.new(error, error.message))
          end
        end

        def session(config, req, &block)
          pool_for(config).session_for(req.endpoint) do |http|
            # Ruby 2.5, can disable retries for idempotent operations
            # avoid patching for Ruby 2.5 for disable retry
            http.max_retries = 0 if http.respond_to?(:max_retries)
            http.read_timeout = config.http_read_timeout
            yield(http)
          end
        end

        # Extracts the {ConnectionPool} configuration options.
        # @param [Configuration] config
        # @return [Hash]
        def pool_options(config)
          ConnectionPool::OPTIONS.keys.inject({}) do |opts,opt|
            opts[opt] = config.send(opt)
            opts
          end
        end

        # Constructs and returns a Net::HTTP::Request object from
        # a {Http::Request}.
        # @param [Http::Request] request
        # @return [Net::HTTP::Request]
        def build_net_request(request)
          request_class = net_http_request_class(request)
          req = request_class.new(request.endpoint.request_uri, headers(request))
          req.body_stream = request.body
          req
        end

        # @param [Http::Request] request
        # @raise [InvalidHttpVerbError]
        # @return Returns a base `Net::HTTP::Request` class, e.g.,
        #   `Net::HTTP::Get`, `Net::HTTP::Post`, etc.
        def net_http_request_class(request)
          Net::HTTP.const_get(request.http_method.capitalize)
        rescue NameError
          msg = "`#{request.http_method}` is not a valid http verb"
          raise InvalidHttpVerbError, msg
        end

        # @param [Http::Request] request
        # @return [Hash] Returns a vanilla hash of headers to send with the
        #   HTTP request.
        def headers(request)
          # setting these to stop net/http from providing defaults
          headers = { 'content-type' => '', 'accept-encoding' => '' }
          request.headers.each_pair do |key, value|
            headers[key] = value
          end
          headers
        end

        # @param [Net::HTTP::Response] response
        # @return [Hash<String, String>]
        def extract_headers(response)
          response.to_hash.inject({}) do |headers, (k, v)|
            headers[k] = v.first
            headers
          end
        end

      end
    end
  end
end
if RUBY_VERSION >= '2.1'
  begin
    require 'http/2'
  rescue LoadError; end
end
require 'openssl'
require 'socket'

module Seahorse
  module Client
    # @api private
    module H2

      # H2 Connection build on top of `http/2` gem
      # (requires Ruby >= 2.1)
      # with TLS layer plus ALPN, requires:
      # Ruby >= 2.3 and OpenSSL >= 1.0.2
      class Connection

        OPTIONS = {
          max_concurrent_streams: 100,
          connection_timeout: 60,
          connection_read_timeout: 60,
          http_wire_trace: false,
          logger: nil,
          ssl_verify_peer: true,
          ssl_ca_bundle: nil,
          ssl_ca_directory: nil,
          ssl_ca_store: nil,
          enable_alpn: false
        }

        # chunk read size at socket
        CHUNKSIZE = 1024

        SOCKET_FAMILY = ::Socket::AF_INET

        def initialize(options = {})
          OPTIONS.each_pair do |opt_name, default_value|
            value = options[opt_name].nil? ? default_value : options[opt_name]
            instance_variable_set("@#{opt_name}", value)
          end
          @h2_client = HTTP2::Client.new(
            settings_max_concurrent_streams: max_concurrent_streams
          )
          @logger = options[:logger] || Logger.new($stdout) if @http_wire_trace
          @chunk_size = options[:read_chunk_size] || CHUNKSIZE
          @errors = []
          @status = :ready
          @mutex = Mutex.new # connection can be shared across requests
        end

        OPTIONS.keys.each do |attr_name|
          attr_reader(attr_name)
        end

        alias ssl_verify_peer? ssl_verify_peer

        attr_reader :errors

        attr_accessor :input_signal_thread

        def new_stream
          begin
            @h2_client.new_stream
          rescue => error
            raise Http2StreamInitializeError.new(error)
          end
        end

        def connect(endpoint)
          @mutex.synchronize {
            if @status == :ready
              tcp, addr = _tcp_socket(endpoint) 
              debug_output("opening connection to #{endpoint.host}:#{endpoint.port} ...")
              _nonblocking_connect(tcp, addr)
              debug_output("opened")

              @socket = OpenSSL::SSL::SSLSocket.new(tcp, _tls_context)
              @socket.sync_close = true
              @socket.hostname = endpoint.host

              debug_output("starting TLS for #{endpoint.host}:#{endpoint.port} ...")
              @socket.connect
              debug_output("TLS established")
              _register_h2_callbacks
              @status = :active
            elsif @status == :closed
              msg = "Async Client HTTP2 Connection is closed, you may"\
                " use #new_connection to create a new HTTP2 Connection for this client"
              raise Http2ConnectionClosedError.new(msg)
            end
          }
        end

        def start(stream)
          @mutex.synchronize {
            return if @socket_thread
            @socket_thread = Thread.new do
              while !@socket.closed?
                begin
                  data = @socket.read_nonblock(@chunk_size)
                  @h2_client << data
                rescue IO::WaitReadable
                  begin
                    unless IO.select([@socket], nil, nil, connection_read_timeout)
                      self.debug_output("socket connection read time out")
                      self.close!
                    else
                      # available, retry to start reading
                      retry
                    end
                  rescue
                    # error can happen when closing the socket
                    # while it's waiting for read
                    self.close!
                  end
                rescue EOFError
                  self.close!
                rescue => error
                  self.debug_output(error.inspect)
                  @errors << error
                  self.close!
                end
              end
            end
            @socket_thread.abort_on_exception = true
          }
        end

        def close!
          @mutex.synchronize {
            self.debug_output("closing connection ...")
            if @socket
              @socket.close
              @socket = nil
            end
            if @socket_thread
              Thread.kill(@socket_thread)
              @socket_thread = nil
            end
            @status = :closed
          }
        end

        def closed?
          @status == :closed
        end

        def debug_output(msg, type = nil)
          prefix = case type
            when :send then "-> "
            when :receive then "<- "
            else
              ""
            end
          return unless @logger
          _debug_entry(prefix + msg)
        end

        private

        def _debug_entry(str)
          @logger << str
          @logger << "\n"
        end

        def _register_h2_callbacks
          @h2_client.on(:frame) do |bytes|
            if @socket.nil?
              msg = "Connection is closed due to errors, "\
                "you can find errors at async_client.connection.errors"
              raise Http2ConnectionClosedError.new(msg)
            else
              @socket.print(bytes)
              @socket.flush
            end
          end
          @h2_client.on(:frame_sent) do |frame|
            debug_output("frame: #{frame.inspect}", :send)
          end
          @h2_client.on(:frame_received) do |frame|
            debug_output("frame: #{frame.inspect}", :receive)
          end
        end

        def _tcp_socket(endpoint)
          tcp = ::Socket.new(SOCKET_FAMILY, ::Socket::SOCK_STREAM, 0)
          tcp.setsockopt(::Socket::IPPROTO_TCP, ::Socket::TCP_NODELAY, 1)

          address = ::Socket.getaddrinfo(endpoint.host, nil, SOCKET_FAMILY).first[3]
          sockaddr = ::Socket.sockaddr_in(endpoint.port, address)

          [tcp, sockaddr]
        end

        def _nonblocking_connect(tcp, addr)
          begin
            tcp.connect_nonblock(addr)
          rescue IO::WaitWritable
            unless IO.select(nil, [tcp], nil, connection_timeout)
              tcp.close
              raise
            end
            begin
              tcp.connect_nonblock(addr)
            rescue Errno::EISCONN
              # tcp socket connected, continue
            end
          end
        end

        def _tls_context
          ssl_ctx = OpenSSL::SSL::SSLContext.new(:TLSv1_2)
          if ssl_verify_peer?
            ssl_ctx.verify_mode = OpenSSL::SSL::VERIFY_PEER
            ssl_ctx.ca_file = ssl_ca_bundle ? ssl_ca_bundle : _default_ca_bundle
            ssl_ctx.ca_path = ssl_ca_directory ? ssl_ca_directory : _default_ca_directory
            ssl_ctx.cert_store = ssl_ca_store if ssl_ca_store
          else
            ssl_ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
          end
          if enable_alpn
            debug_output("enabling ALPN for TLS ...")
            ssl_ctx.alpn_protocols = ['h2']
          end
          ssl_ctx
        end

        def _default_ca_bundle
          File.exist?(OpenSSL::X509::DEFAULT_CERT_FILE) ?
            OpenSSL::X509::DEFAULT_CERT_FILE : nil
        end

        def _default_ca_directory
          Dir.exist?(OpenSSL::X509::DEFAULT_CERT_DIR) ?
            OpenSSL::X509::DEFAULT_CERT_DIR : nil
        end

      end
    end
  end
end

if RUBY_VERSION >= '2.1'
  begin
    require 'http/2'
  rescue LoadError; end
end
require 'securerandom'

module Seahorse
  module Client
    # @api private
    module H2

      NETWORK_ERRORS = [
        SocketError, EOFError, IOError, Timeout::Error,
        Errno::ECONNABORTED, Errno::ECONNRESET, Errno::EPIPE,
        Errno::EINVAL, Errno::ETIMEDOUT, OpenSSL::SSL::SSLError,
        Errno::EHOSTUNREACH, Errno::ECONNREFUSED,# OpenSSL::SSL::SSLErrorWaitReadable
      ]

      # @api private
      DNS_ERROR_MESSAGES = [
        'getaddrinfo: nodename nor servname provided, or not known', # MacOS
        'getaddrinfo: Name or service not known' # GNU
      ]

      class Handler < Client::Handler

        def call(context)
          stream = nil
          begin
            conn = context.client.connection
            stream = conn.new_stream

            stream_mutex = Mutex.new
            close_condition = ConditionVariable.new
            sync_queue = Queue.new

            conn.connect(context.http_request.endpoint)
            _register_callbacks(
              context.http_response,
              stream,
              stream_mutex,
              close_condition,
              sync_queue
            )

            conn.debug_output("sending initial request ...")
            if input_emitter = context[:input_event_emitter]
              _send_initial_headers(context.http_request, stream)

              # prepare for sending events later
              input_emitter.stream = stream
              # request sigv4 serves as the initial #prior_signature
              input_emitter.encoder.prior_signature =
                context.http_request.headers['authorization'].split('Signature=').last
              input_emitter.validate_event = context.config.validate_params
            else
              _send_initial_headers(context.http_request, stream)
              _send_initial_data(context.http_request, stream)
            end

            conn.start(stream)
          rescue *NETWORK_ERRORS => error
            error = NetworkingError.new(
              error, error_message(context.http_request, error))
            context.http_response.signal_error(error)
          rescue => error
            conn.debug_output(error.inspect)
            # not retryable
            context.http_response.signal_error(error)
          end

          AsyncResponse.new(
            context: context,
            stream: stream,
            stream_mutex: stream_mutex,
            close_condition: close_condition,
            sync_queue: sync_queue
          )
        end

        private

        def _register_callbacks(resp, stream, stream_mutex, close_condition, sync_queue)
          stream.on(:headers) do |headers|
            resp.signal_headers(headers)
          end

          stream.on(:data) do |data|
            resp.signal_data(data)
          end

          stream.on(:close) do
            resp.signal_done
            # block until #wait is ready for signal
            # else deadlock may happen because #signal happened
            # eariler than #wait (see AsyncResponse#wait)
            sync_queue.pop
            stream_mutex.synchronize {
              close_condition.signal
            }
          end
        end

        def _send_initial_headers(req, stream)
          begin
            headers = _h2_headers(req)
            stream.headers(headers, end_stream: false)
          rescue => e
            raise Http2InitialRequestError.new(e)
          end
        end

        def _send_initial_data(req, stream)
          begin
            data = req.body.read
            stream.data(data, end_stream: true)
          rescue => e
            raise Http2InitialRequestError.new(e)
          end
          data
        end

        # H2 pseudo headers
        # https://http2.github.io/http2-spec/#rfc.section.8.1.2.3
        def _h2_headers(req)
          headers = {}
          headers[':method'] = req.http_method.upcase
          headers[':scheme'] = req.endpoint.scheme
          headers[':path'] = req.endpoint.path.empty? ? '/' : req.endpoint.path
          if req.endpoint.query && !req.endpoint.query.empty?
            headers[':path'] += "?#{req.endpoint.query}"
          end
          req.headers.each {|k, v| headers[k.downcase] = v }
          headers
        end

        def error_message(req, error)
          if error.is_a?(SocketError) && DNS_ERROR_MESSAGES.include?(error.message)
            host = req.endpoint.host
            "unable to connect to `#{host}`; SocketError: #{error.message}"
          else
            error.message
          end
        end

      end

    end
  end
end
module Seahorse
  module Client
    module Plugins
      class ContentLength < Plugin

        # @api private
        class Handler < Client::Handler

          def call(context)
            begin
              length = context.http_request.body.size
              context.http_request.headers['Content-Length'] = length
            rescue
              # allowing `Content-Length` failed to be set
              # see Aws::Plugins::TransferEncoding
            end
            @handler.call(context)
          end

        end

        handler(Handler, step: :sign, priority: 0)

      end
    end
  end
end
module Seahorse
  module Client
    module Plugins
      class Endpoint < Plugin

        option(:endpoint,
          doc_type: 'String, URI::HTTPS, URI::HTTP',
          docstring: <<-DOCS)
Normally you should not configure the `:endpoint` option
directly. This is normally constructed from the `:region`
option. Configuring `:endpoint` is normally reserved for
connecting to test endpoints. The endpoint should be a URI
formatted like:

    'http://example.com'
    'https://example.com'
    'http://example.com:123'

          DOCS

        def add_handlers(handlers, config)
          handlers.add(Handler, priority: 90)
        end

        def after_initialize(client)
          endpoint = client.config.endpoint
          if endpoint.nil?
            msg = "missing required option `:endpoint'"
            raise ArgumentError, msg
          end

          endpoint = URI.parse(endpoint.to_s)
          if URI::HTTPS === endpoint or URI::HTTP === endpoint
            client.config.endpoint = endpoint
          else
            msg = 'expected :endpoint to be a HTTP or HTTPS endpoint'
            raise ArgumentError, msg
          end
        end

        class Handler < Client::Handler

          def call(context)
            context.http_request.endpoint = URI.parse(context.config.endpoint.to_s)
            @handler.call(context)
          end

        end
      end
    end
  end
end
module Seahorse
  module Client
    module Plugins
      # @api private
      class Logging < Plugin

        option(:logger,
          default: nil,
          doc_type: 'Logger',
          docstring: <<-DOCS)
The Logger instance to send log messages to. If this option
is not set, logging is disabled.
          DOCS

        option(:log_level,
          default: :info,
          doc_type: Symbol,
          docstring: 'The log level to send messages to the logger at.')

        option(:log_formatter,
          default: Seahorse::Client::Logging::Formatter.default,
          doc_default: 'Aws::Log::Formatter.default',
          doc_type: 'Aws::Log::Formatter',
          docstring: 'The log formatter.')

        def add_handlers(handlers, config)
          if config.logger
            handlers.add(Client::Logging::Handler, step: :validate)
          end
        end

      end
    end
  end
end
# KG-dev::RubyPacker replaced for seahorse/client/net_http/handler.rb

module Seahorse
  module Client
    module Plugins
      class NetHttp < Plugin

        option(:http_proxy, default: nil, doc_type: String, docstring: '')

        option(:http_open_timeout, default: 15, doc_type: Integer, docstring: '')

        option(:http_read_timeout, default: 60, doc_type: Integer, docstring: '')

        option(:http_idle_timeout, default: 5, doc_type: Integer, docstring: '')

        option(:http_continue_timeout, default: 1, doc_type: Integer, docstring: '')

        option(:http_wire_trace, default: false, doc_type: 'Boolean', docstring: '')

        option(:ssl_verify_peer, default: true, doc_type: 'Boolean', docstring: '')

        option(:ssl_ca_bundle, default: nil, doc_type: String, docstring: '')

        option(:ssl_ca_directory, default: nil, doc_type: String, docstring: '')

        option(:ssl_ca_store, default: nil, doc_type: String, docstring: '')

        option(:logger) # for backwards compat

        handler(Client::NetHttp::Handler, step: :send)

      end
    end
  end
end
# KG-dev::RubyPacker replaced for seahorse/client/h2/handler.rb

module Seahorse
  module Client
    module Plugins
      class H2 < Plugin

        # H2 Client
        option(:max_concurrent_streams, default: 100, doc_type: Integer, docstring: <<-DOCS)
Maximum concurrent streams used in HTTP2 connection, defaults to 100. Note that server may send back
:settings_max_concurrent_streams value which will take priority when initializing new streams.
        DOCS

        option(:connection_timeout, default: 60, doc_type: Integer, docstring: <<-DOCS)
Connection timeout in seconds, defaults to 60 sec.
        DOCS

        option(:connection_read_timeout, default: 60, doc_type: Integer, docstring: <<-DOCS)
Connection read timeout in seconds, defaults to 60 sec.
        DOCS

        option(:read_chunk_size, default: 1024, doc_type: Integer, docstring: '')

        option(:raise_response_errors, default: true, doc_type: 'Boolean', docstring: <<-DOCS)
Defaults to `true`, raises errors if exist when #wait or #join! is called upon async response.
        DOCS

        # SSL Context
        option(:ssl_ca_bundle, default: nil, doc_type: String, docstring: <<-DOCS)
Full path to the SSL certificate authority bundle file that should be used when
verifying peer certificates. If you do not pass `:ssl_ca_directory` or `:ssl_ca_bundle`
the system default will be used if available.
        DOCS

        option(:ssl_ca_directory, default: nil, doc_type: String, docstring: <<-DOCS)
Full path of the directory that contains the unbundled SSL certificate authority
files for verifying peer certificates. If you do not pass `:ssl_ca_bundle` or
`:ssl_ca_directory` the system default will be used if available.
        DOCS

        option(:ssl_ca_store, default: nil, doc_type: String, docstring: '')

        option(:ssl_verify_peer, default: true, doc_type: 'Boolean', docstring: <<-DOCS)
When `true`, SSL peer certificates are verified when establishing a connection.
        DOCS

        option(:http_wire_trace, default: false, doc_type:  'Boolean', docstring: <<-DOCS)
When `true`, HTTP2 debug output will be sent to the `:logger`.
        DOCS

        option(:enable_alpn, default: false, doc_type: 'Boolean', docstring: <<-DOCS)
Setting to `true` to enable ALPN in HTTP2 over TLS, requires Ruby version >= 2.3 and
Openssl version >= 1.0.2. Defaults to false. Note: not all service HTTP2 operations
supports ALPN on server side, please refer to service documentation.
        DOCS

        option(:logger)

        handler(Client::H2::Handler, step: :send)

      end
    end
  end
end
module Seahorse
  module Client
    module Plugins
      class RaiseResponseErrors < Plugin

        option(:raise_response_errors,
          default: true,
          doc_type: 'Boolean',
          docstring: 'When `true`, response errors are raised.')

        # @api private
        class Handler < Client::Handler
          def call(context)
            response = @handler.call(context)
            raise response.error if response.error
            response
          end
        end

        def add_handlers(handlers, config)
          if config.raise_response_errors
            handlers.add(Handler, step: :validate, priority: 95)
          end
        end

      end
    end
  end
end
require 'pathname'

module Seahorse
  module Client
    module Plugins
      # @api private
      class ResponseTarget < Plugin

        # This handler is responsible for replacing the HTTP response body IO
        # object with custom targets, such as a block, or a file. It is important
        # to not write data to the custom target in the case of a non-success
        # response. We do not want to write an XML error message to someone's
        # file.
        class Handler < Client::Handler

          def call(context)
            if context.params.is_a?(Hash) && context.params[:response_target]
              target = context.params.delete(:response_target)
            else
              target = context[:response_target]
            end
            add_event_listeners(context, target) if target
            @handler.call(context)
          end

          private

          def add_event_listeners(context, target)
            handler = self
            context.http_response.on_headers(200..299) do
              context.http_response.body = handler.send(:io, target)
            end

            context.http_response.on_success(200..299) do
              body = context.http_response.body
              if ManagedFile === body && body.open?
                body.close
              end
            end

            context.http_response.on_error do
              body = context.http_response.body
              File.unlink(body) if ManagedFile === body
              # Aws::S3::Encryption::DecryptHandler (with lower priority)
              # has callbacks registered after ResponseTarget::Handler,
              # where http_response.body is an IODecrypter
              # and has error callbacks handling for it.
              # Thus avoid early remove of IODecrypter at ResponseTarget::Handler
              unless context.http_response.body.respond_to?(:io)
                context.http_response.body = StringIO.new
              end
            end
          end

          def io(target)
            case target
            when Proc then BlockIO.new(&target)
            when String, Pathname then ManagedFile.new(target, 'w+b')
            else target
            end
          end

        end

        handler(Handler, step: :initialize, priority: 90)

      end
    end
  end
end
module Seahorse
  module Model
    class Api

      def initialize
        @metadata = {}
        @operations = {}
        @authorizers = {}
        @endpoint_operation = nil
      end

      # @return [String, nil]
      attr_accessor :version

      # @return [Hash]
      attr_accessor :metadata

      # @return [Symbol|nil]
      attr_accessor :endpoint_operation

      def operations(&block)
        if block_given?
          @operations.each(&block)
        else
          @operations.enum_for(:each)
        end
      end

      def operation(name)
        if @operations.key?(name.to_sym)
          @operations[name.to_sym]
        else
          raise ArgumentError, "unknown operation #{name.inspect}"
        end
      end

      def operation_names
        @operations.keys
      end

      def async_operation_names
        @operations.select {|_, op| op.async }.keys
      end

      def add_operation(name, operation)
        @operations[name.to_sym] = operation
      end

      def authorizers(&block)
        if block_given?
          @authorizers.each(&block)
        else
          @authorizers.enum_for(:each)
        end
      end

      def authorizer(name)
        if @authorizers.key?(name.to_sym)
          @authorizers[name.to_sym]
        else
          raise ArgumentError, "unknown authorizer #{name.inspect}"
        end
      end

      def authorizer_names
        @authorizers.keys
      end

      def add_authorizer(name, authorizer)
        @authorizers[name.to_sym] = authorizer
      end

      def inspect(*args)
        "#<#{self.class.name}>"
      end

    end
  end
end
module Seahorse
  module Model
    class Operation

      def initialize
        @http_method = 'POST'
        @http_request_uri = '/'
        @deprecated = false
        @errors = []
        @metadata = {}
        @async = false
      end

      # @return [String, nil]
      attr_accessor :name

      # @return [String]
      attr_accessor :http_method

      # @return [String]
      attr_accessor :http_request_uri

      # @return [Boolean]
      attr_accessor :deprecated

      # @return [Boolean]
      attr_accessor :endpoint_operation

      # @return [Hash]
      attr_accessor :endpoint_discovery

      # @return [String, nil]
      attr_accessor :documentation

      # @return [Hash, nil]
      attr_accessor :endpoint_pattern

      # @return [String, nil]
      attr_accessor :authorizer

      # @return [ShapeRef, nil]
      attr_accessor :input

      # @return [ShapeRef, nil]
      attr_accessor :output

      # @return [Array<ShapeRef>]
      attr_accessor :errors

      # APIG only
      # @return [Boolean]
      attr_accessor :require_apikey

      # @return [Boolean]
      attr_accessor :async

      def [](key)
        @metadata[key.to_s]
      end

      def []=(key, value)
        @metadata[key.to_s] = value
      end

    end
  end
end
module Seahorse
  module Model
    class Authorizer

      def initialize
        @type = 'provided'
        @placement = {}
      end

      # @return [String]
      attr_accessor :name

      # @return [String]
      attr_accessor :type

      # @return [Hash]
      attr_accessor :placement

    end
  end
end
require 'set'

module Seahorse
  module Model
    module Shapes

      class ShapeRef

        def initialize(options = {})
          @metadata = {}
          @required = false
          @deprecated = false
          @location = nil
          @location_name = nil
          @event = false
          @eventstream = false
          @eventpayload = false
          @eventpayload_type = ''.freeze
          @eventheader = false
          @eventheader_type = ''.freeze
          options.each do |key, value|
            if key == :metadata
              value.each do |k,v|
                self[k] = v
              end
            else
              send("#{key}=", value)
            end
          end
        end

        # @return [Shape]
        attr_accessor :shape

        # @return [Boolean]
        attr_accessor :required

        # @return [String, nil]
        attr_accessor :documentation

        # @return [Boolean]
        attr_accessor :deprecated

        # @return [Boolean]
        attr_accessor :event

        # @return [Boolean]
        attr_accessor :eventstream

        # @return [Boolean]
        attr_accessor :eventpayload

        # @return [Boolean]
        attr_accessor :eventheader

        # @return [String]
        attr_accessor :eventpayload_type

        # @return [Boolean]
        attr_accessor :eventheader_type

        # @return [String, nil]
        def location
          @location || (shape && shape[:location])
        end

        def location= location
          @location = location
        end

        # @return [String, nil]
        def location_name
          @location_name || (shape && shape[:location_name])
        end

        def location_name= location_name
          @location_name = location_name
        end

        # Gets metadata for the given `key`.
        def [](key)
          if @metadata.key?(key.to_s)
            @metadata[key.to_s]
          else
            @shape[key.to_s]
          end
        end

        # Sets metadata for the given `key`.
        def []=(key, value)
          @metadata[key.to_s] = value
        end

      end

      class Shape

        def initialize(options = {})
          @metadata = {}
          options.each_pair do |key, value|
            if respond_to?("#{key}=")
              send("#{key}=", value)
            else
              self[key] = value
            end
          end
        end

        # @return [String]
        attr_accessor :name

        # @return [String, nil]
        attr_accessor :documentation

        # Gets metadata for the given `key`.
        def [](key)
          @metadata[key.to_s]
        end

        # Sets metadata for the given `key`.
        def []=(key, value)
          @metadata[key.to_s] = value
        end

      end

      class BlobShape < Shape

        # @return [Integer, nil]
        attr_accessor :min

        # @return [Integer, nil]
        attr_accessor :max

      end

      class BooleanShape < Shape; end

      class FloatShape < Shape

        # @return [Integer, nil]
        attr_accessor :min

        # @return [Integer, nil]
        attr_accessor :max

      end

      class IntegerShape < Shape

        # @return [Integer, nil]
        attr_accessor :min

        # @return [Integer, nil]
        attr_accessor :max

      end

      class ListShape < Shape

        # @return [ShapeRef]
        attr_accessor :member

        # @return [Integer, nil]
        attr_accessor :min

        # @return [Integer, nil]
        attr_accessor :max

        # @return [Boolean]
        attr_accessor :flattened

      end

      class MapShape < Shape

        # @return [ShapeRef]
        attr_accessor :key

        # @return [ShapeRef]
        attr_accessor :value

        # @return [Integer, nil]
        attr_accessor :min

        # @return [Integer, nil]
        attr_accessor :max

        # @return [Boolean]
        attr_accessor :flattened

      end

      class StringShape < Shape

        # @return [Set<String>, nil]
        attr_accessor :enum

        # @return [Integer, nil]
        attr_accessor :min

        # @return [Integer, nil]
        attr_accessor :max

      end

      class StructureShape < Shape

        def initialize(options = {})
          @members = {}
          @members_by_location_name = {}
          @required = Set.new
          super
        end

        # @return [Set<Symbol>]
        attr_accessor :required

        # @return [Class<Struct>]
        attr_accessor :struct_class

        # @param [Symbol] name
        # @param [ShapeRef] shape_ref
        def add_member(name, shape_ref)
          name = name.to_sym
          @required << name if shape_ref.required
          @members_by_location_name[shape_ref.location_name] = [name, shape_ref]
          @members[name] = shape_ref
        end

        # @return [Array<Symbol>]
        def member_names
          @members.keys
        end

        # @param [Symbol] member_name
        # @return [Boolean] Returns `true` if there exists a member with
        #   the given name.
        def member?(member_name)
          @members.key?(member_name.to_sym)
        end

        # @return [Enumerator<[Symbol,ShapeRef]>]
        def members
          @members.to_enum
        end

        # @param [Symbol] name
        # @return [ShapeRef]
        def member(name)
          if member?(name)
            @members[name.to_sym]
          else
            raise ArgumentError, "no such member #{name.inspect}"
          end
        end

        # @api private
        def member_by_location_name(location_name)
          @members_by_location_name[location_name]
        end

      end

      class TimestampShape < Shape; end

    end
  end
end
require 'thread'

module Seahorse
  module Client
    class Base

      include HandlerBuilder

      # default plugins
      @plugins = PluginList.new([
        Plugins::Endpoint,
        Plugins::NetHttp,
        Plugins::RaiseResponseErrors,
        Plugins::ResponseTarget,
      ])

      # @api private
      def initialize(plugins, options)
        @config = build_config(plugins, options)
        @handlers = build_handler_list(plugins)
        after_initialize(plugins)
      end

      # @return [Configuration<Struct>]
      attr_reader :config

      # @return [HandlerList]
      attr_reader :handlers

      # Builds and returns a {Request} for the named operation.  The request
      # will not have been sent.
      # @param [Symbol, String] operation_name
      # @return [Request]
      def build_request(operation_name, params = {})
        Request.new(
          @handlers.for(operation_name),
          context_for(operation_name, params))
      end

      # @api private
      def inspect
        "#<#{self.class.name}>"
      end

      # @return [Array<Symbol>] Returns a list of valid request operation
      #   names. These are valid arguments to {#build_request} and are also
      #   valid methods.
      def operation_names
        self.class.api.operation_names - self.class.api.async_operation_names
      end

      private

      # Constructs a {Configuration} object and gives each plugin the
      # opportunity to register options with default values.
      def build_config(plugins, options)
        config = Configuration.new
        config.add_option(:api)
        plugins.each do |plugin|
          plugin.add_options(config) if plugin.respond_to?(:add_options)
        end
        config.build!(options.merge(api: self.class.api))
      end

      # Gives each plugin the opportunity to register handlers for this client.
      def build_handler_list(plugins)
        plugins.inject(HandlerList.new) do |handlers, plugin|
          if plugin.respond_to?(:add_handlers)
            plugin.add_handlers(handlers, @config)
          end
          handlers
        end
      end

      # Gives each plugin the opportunity to modify this client.
      def after_initialize(plugins)
        plugins.reverse.each do |plugin|
          plugin.after_initialize(self) if plugin.respond_to?(:after_initialize)
        end
      end

      # @return [RequestContext]
      def context_for(operation_name, params)
        RequestContext.new(
          operation_name: operation_name,
          operation: config.api.operation(operation_name),
          client: self,
          params: params,
          config: config)
      end

      class << self

        def new(options = {})
          plugins = build_plugins
          options = options.dup
          before_initialize(plugins, options)
          client = allocate
          client.send(:initialize, plugins, options)
          client
        end

        # Registers a plugin with this client.
        #
        # @example Register a plugin
        #
        #   ClientClass.add_plugin(PluginClass)
        #
        # @example Register a plugin by name
        #
        #   ClientClass.add_plugin('gem-name.PluginClass')
        #
        # @example Register a plugin with an object
        #
        #   plugin = MyPluginClass.new(options)
        #   ClientClass.add_plugin(plugin)
        #
        # @param [Class, Symbol, String, Object] plugin
        # @see .clear_plugins
        # @see .set_plugins
        # @see .remove_plugin
        # @see .plugins
        # @return [void]
        def add_plugin(plugin)
          @plugins.add(plugin)
        end

        # @see .clear_plugins
        # @see .set_plugins
        # @see .add_plugin
        # @see .plugins
        # @return [void]
        def remove_plugin(plugin)
          @plugins.remove(plugin)
        end

        # @see .set_plugins
        # @see .add_plugin
        # @see .remove_plugin
        # @see .plugins
        # @return [void]
        def clear_plugins
          @plugins.set([])
        end

        # @param [Array<Plugin>] plugins
        # @see .clear_plugins
        # @see .add_plugin
        # @see .remove_plugin
        # @see .plugins
        # @return [void]
        def set_plugins(plugins)
          @plugins.set(plugins)
        end

        # Returns the list of registered plugins for this Client.  Plugins are
        # inherited from the client super class when the client is defined.
        # @see .clear_plugins
        # @see .set_plugins
        # @see .add_plugin
        # @see .remove_plugin
        # @return [Array<Plugin>]
        def plugins
          Array(@plugins).freeze
        end

        # @return [Model::Api]
        def api
          @api ||= Model::Api.new
        end

        # @param [Model::Api] api
        # @return [Model::Api]
        def set_api(api)
          @api = api
          define_operation_methods
          @api
        end

        # @option options [Model::Api, Hash] :api ({})
        # @option options [Array<Plugin>] :plugins ([]) A list of plugins to
        #   add to the client class created.
        # @return [Class<Client::Base>]
        def define(options = {})
          subclass = Class.new(self)
          subclass.set_api(options[:api] || api)
          Array(options[:plugins]).each do |plugin|
            subclass.add_plugin(plugin)
          end
          subclass
        end
        alias extend define

        private

        def define_operation_methods
          @api.operation_names.each do |method_name|
            define_method(method_name) do |*args, &block|
              params = args[0] || {}
              options = args[1] || {}
              build_request(method_name, params).send_request(options, &block)
            end
          end
        end

        def build_plugins
          plugins.map { |plugin| plugin.is_a?(Class) ? plugin.new : plugin }
        end

        def before_initialize(plugins, options)
          plugins.each do |plugin|
            plugin.before_initialize(self, options) if plugin.respond_to?(:before_initialize)
          end
        end

        def inherited(subclass)
          subclass.instance_variable_set('@plugins', PluginList.new(@plugins))
        end

      end
    end
  end
end
module Seahorse
  module Client
    class AsyncBase < Seahorse::Client::Base

      # default H2 plugins
      @plugins = PluginList.new([
        Plugins::Endpoint,
        Plugins::H2,
        Plugins::ResponseTarget
      ])

      def initialize(plugins, options)
        super
        @connection = H2::Connection.new(options)
        @options = options
      end

      # @return [H2::Connection]
      attr_reader :connection

      # @return [Array<Symbol>] Returns a list of valid async request
      #   operation names.
      def operation_names
        self.class.api.async_operation_names
      end

      # Closes the underlying HTTP2 Connection for the client
      # @return [Symbol] Returns the status of the connection (:closed)
      def close_connection
        @connection.close!
      end

      # Creates a new HTTP2 Connection for the client
      # @return [Seahorse::Client::H2::Connection]
      def new_connection
        if @connection.closed?
          @connection = H2::Connection.new(@options)
        else
          @connection
        end
      end

      def connection_errors
        @connection.errors
      end

    end
  end
end

# KG-dev::RubyPacker replaced for seahorse/util.rb

# client

# KG-dev::RubyPacker replaced for seahorse/client/block_io.rb
# KG-dev::RubyPacker replaced for seahorse/client/configuration.rb
# KG-dev::RubyPacker replaced for seahorse/client/handler.rb
# KG-dev::RubyPacker replaced for seahorse/client/handler_builder.rb
# KG-dev::RubyPacker replaced for seahorse/client/handler_list.rb
# KG-dev::RubyPacker replaced for seahorse/client/handler_list_entry.rb
# KG-dev::RubyPacker replaced for seahorse/client/managed_file.rb
# KG-dev::RubyPacker replaced for seahorse/client/networking_error.rb
# KG-dev::RubyPacker replaced for seahorse/client/plugin.rb
# KG-dev::RubyPacker replaced for seahorse/client/plugin_list.rb
# KG-dev::RubyPacker replaced for seahorse/client/request.rb
# KG-dev::RubyPacker replaced for seahorse/client/request_context.rb
# KG-dev::RubyPacker replaced for seahorse/client/response.rb
# KG-dev::RubyPacker replaced for seahorse/client/async_response.rb

# client http

# KG-dev::RubyPacker replaced for seahorse/client/http/headers.rb
# KG-dev::RubyPacker replaced for seahorse/client/http/request.rb
# KG-dev::RubyPacker replaced for seahorse/client/http/response.rb
# KG-dev::RubyPacker replaced for seahorse/client/http/async_response.rb

# client logging

# KG-dev::RubyPacker replaced for seahorse/client/logging/handler.rb
# KG-dev::RubyPacker replaced for seahorse/client/logging/formatter.rb

# net http handler

# KG-dev::RubyPacker replaced for seahorse/client/net_http/connection_pool.rb
# KG-dev::RubyPacker replaced for seahorse/client/net_http/handler.rb

# http2 handler

# KG-dev::RubyPacker replaced for seahorse/client/h2/connection.rb
# KG-dev::RubyPacker replaced for seahorse/client/h2/handler.rb

# plugins

# KG-dev::RubyPacker replaced for seahorse/client/plugins/content_length.rb
# KG-dev::RubyPacker replaced for seahorse/client/plugins/endpoint.rb
# KG-dev::RubyPacker replaced for seahorse/client/plugins/logging.rb
# KG-dev::RubyPacker replaced for seahorse/client/plugins/net_http.rb
# KG-dev::RubyPacker replaced for seahorse/client/plugins/h2.rb
# KG-dev::RubyPacker replaced for seahorse/client/plugins/raise_response_errors.rb
# KG-dev::RubyPacker replaced for seahorse/client/plugins/response_target.rb

# model

# KG-dev::RubyPacker replaced for seahorse/model/api.rb
# KG-dev::RubyPacker replaced for seahorse/model/operation.rb
# KG-dev::RubyPacker replaced for seahorse/model/authorizer.rb
# KG-dev::RubyPacker replaced for seahorse/model/shapes.rb

# KG-dev::RubyPacker replaced for seahorse/client/base.rb
# KG-dev::RubyPacker replaced for seahorse/client/async_base.rb
module Aws

  # A utility module that provides a class method that wraps
  # a method such that it generates a deprecation warning when called.
  # Given the following class:
  #
  #     class Example
  #
  #       def do_something
  #       end
  #
  #     end
  #
  # If you want to deprecate the `#do_something` method, you can extend
  # this module and then call `deprecated` on the method (after it
  # has been defined).
  #
  #     class Example
  #
  #       extend Aws::Deprecations
  #
  #       def do_something
  #       end
  #
  #       def do_something_else
  #       end
  #
  #       deprecated :do_something
  #
  #     end
  #
  # The `#do_something` method will continue to function, but will
  # generate a deprecation warning when called.
  #
  # @api private
  module Deprecations

    # @param [Symbol] method_name The name of the deprecated method.
    #
    # @option options [String] :message The warning message to issue
    #   when the deprecated method is called.
    #
    # @option options [Symbol] :use The name of an use
    #   method that should be used.
    #
    def deprecated(method_name, options = {})

      deprecation_msg = options[:message] || begin
        msg = "DEPRECATION WARNING: called deprecated method `#{method_name}' "
        msg << "of an #{self}"
        msg << ", use #{options[:use]} instead" if options[:use]
        msg
      end

      alias_method(:"deprecated_#{method_name}", method_name)

      warned = false # we only want to issue this warning once

      define_method(method_name) do |*args,&block|
        unless warned
          warned = true
          warn(deprecation_msg + "\n" + caller.join("\n"))
        end
        send("deprecated_#{method_name}", *args, &block)
      end
    end

  end
end
module Aws

  # A utility module that provides a class method that wraps
  # a method such that it generates a deprecation warning when called.
  # Given the following class:
  #
  #     class Example
  #
  #       def do_something
  #       end
  #
  #     end
  #
  # If you want to deprecate the `#do_something` method, you can extend
  # this module and then call `deprecated` on the method (after it
  # has been defined).
  #
  #     class Example
  #
  #       extend Aws::Deprecations
  #
  #       def do_something
  #       end
  #
  #       def do_something_else
  #       end
  #
  #       deprecated :do_something
  #
  #     end
  #
  # The `#do_something` method will continue to function, but will
  # generate a deprecation warning when called.
  #
  # @api private
  module Deprecations

    # @param [Symbol] method_name The name of the deprecated method.
    #
    # @option options [String] :message The warning message to issue
    #   when the deprecated method is called.
    #
    # @option options [Symbol] :use The name of an use
    #   method that should be used.
    #
    def deprecated(method_name, options = {})

      deprecation_msg = options[:message] || begin
        msg = "DEPRECATION WARNING: called deprecated method `#{method_name}' "
        msg << "of an #{self}"
        msg << ", use #{options[:use]} instead" if options[:use]
        msg
      end

      alias_method(:"deprecated_#{method_name}", method_name)

      warned = false # we only want to issue this warning once

      define_method(method_name) do |*args,&block|
        unless warned
          warned = true
          warn(deprecation_msg + "\n" + caller.join("\n"))
        end
        send("deprecated_#{method_name}", *args, &block)
      end
    end

  end
end
# KG-dev::RubyPacker replaced for deprecations.rb

module Aws
  module CredentialProvider

    extend Deprecations

    # @return [Credentials]
    attr_reader :credentials

    # @return [Boolean]
    def set?
      !!credentials && credentials.set?
    end

    # @deprecated Deprecated in 2.1.0. This method is subject to errors
    #   from a race condition when called against refreshable credential
    #   objects. Will be removed in 2.2.0.
    # @see #credentials
    def access_key_id
      credentials ? credentials.access_key_id : nil
    end
    deprecated(:access_key_id, use: '#credentials')

    # @deprecated Deprecated in 2.1.0. This method is subject to errors
    #   from a race condition when called against refreshable credential
    #   objects. Will be removed in 2.2.0.
    # @see #credentials
    def secret_access_key
      credentials ? credentials.secret_access_key : nil
    end
    deprecated(:secret_access_key, use: '#credentials')

    # @deprecated Deprecated in 2.1.0. This method is subject to errors
    #   from a race condition when called against refreshable credential
    #   objects. Will be removed in 2.2.0.
    # @see #credentials
    def session_token
      credentials ? credentials.session_token : nil
    end
    deprecated(:session_token, use: '#credentials')

  end
end
require 'thread'

module Aws

  # Base class used credential classes that can be refreshed. This
  # provides basic refresh logic in a thread-safe manner. Classes mixing in
  # this module are expected to implement a #refresh method that populates
  # the following instance variables:
  #
  # * `@access_key_id`
  # * `@secret_access_key`
  # * `@session_token`
  # * `@expiration`
  #
  # @api private
  module RefreshingCredentials

    def initialize(options = {})
      @mutex = Mutex.new
      refresh
    end

    # @return [Credentials]
    def credentials
      refresh_if_near_expiration
      @credentials
    end

    # @return [Time,nil]
    def expiration
      refresh_if_near_expiration
      @expiration
    end

    # Refresh credentials.
    # @return [void]
    def refresh!
      @mutex.synchronize { refresh }
    end

    private

    # Refreshes instance metadata credentials if they are within
    # 5 minutes of expiration.
    def refresh_if_near_expiration
      if near_expiration?
        @mutex.synchronize do
          refresh if near_expiration?
        end
      end
    end

    def near_expiration?
      if @expiration
        # are we within 5 minutes of expiration?
        (Time.now.to_i + 5 * 60) > @expiration.to_i
      else
        true
      end
    end

  end
end
require 'set'

module Aws

  # An auto-refreshing credential provider that works by assuming
  # a role via {Aws::STS::Client#assume_role}.
  #
  #     role_credentials = Aws::AssumeRoleCredentials.new(
  #       client: Aws::STS::Client.new(...),
  #       role_arn: "linked::account::arn",
  #       role_session_name: "session-name"
  #     )
  #
  #     ec2 = Aws::EC2::Client.new(credentials: role_credentials)
  #
  # If you omit `:client` option, a new {STS::Client} object will be
  # constructed.
  class AssumeRoleCredentials

    include CredentialProvider
    include RefreshingCredentials

    # @option options [required, String] :role_arn
    # @option options [required, String] :role_session_name
    # @option options [String] :policy
    # @option options [Integer] :duration_seconds
    # @option options [String] :external_id
    # @option options [STS::Client] :client
    def initialize(options = {})
      client_opts = {}
      @assume_role_params = {}
      options.each_pair do |key, value|
        if self.class.assume_role_options.include?(key)
          @assume_role_params[key] = value
        else
          client_opts[key] = value
        end
      end
      @client = client_opts[:client] || STS::Client.new(client_opts)
      super
    end

    # @return [STS::Client]
    attr_reader :client

    private

    def refresh
      c = @client.assume_role(@assume_role_params).credentials
      @credentials = Credentials.new(
        c.access_key_id,
        c.secret_access_key,
        c.session_token
      )
      @expiration = c.expiration
    end

    class << self

      # @api private
      def assume_role_options
        @aro ||= begin
          input = STS::Client.api.operation(:assume_role).input
          Set.new(input.shape.member_names)
        end
      end

    end
  end
end
module Aws
  class Credentials

    # @param [String] access_key_id
    # @param [String] secret_access_key
    # @param [String] session_token (nil)
    def initialize(access_key_id, secret_access_key, session_token = nil)
      @access_key_id = access_key_id
      @secret_access_key = secret_access_key
      @session_token = session_token
    end

    # @return [String, nil]
    attr_reader :access_key_id

    # @return [String, nil]
    attr_reader :secret_access_key

    # @return [String, nil]
    attr_reader :session_token

    # @return [Credentials]
    def credentials
      self
    end

    # @return [Boolean] Returns `true` if the access key id and secret
    #   access key are both set.
    def set?
      !access_key_id.nil? &&
      !access_key_id.empty? &&
      !secret_access_key.nil? &&
      !secret_access_key.empty?
    end

    # Removing the secret access key from the default inspect string.
    # @api private
    def inspect
      "#<#{self.class.name} access_key_id=#{access_key_id.inspect}>"
    end

  end
end
module Aws
  # @api private
  class CredentialProviderChain

    def initialize(config = nil)
      @config = config
    end

    # @return [CredentialProvider, nil]
    def resolve
      providers.each do |method_name, options|
        provider = send(method_name, options.merge(config: @config))
        return provider if provider && provider.set?
      end
      nil
    end

    private

    def providers
      [
        [:static_credentials, {}],
        [:env_credentials, {}],
        [:assume_role_credentials, {}],
        [:shared_credentials, {}],
        [:process_credentials, {}],
        [:instance_profile_credentials, {
          retries: @config ? @config.instance_profile_credentials_retries : 0,
          http_open_timeout: @config ? @config.instance_profile_credentials_timeout : 1,
          http_read_timeout: @config ? @config.instance_profile_credentials_timeout : 1,
        }],
      ]
    end

    def static_credentials(options)
      if options[:config]
        Credentials.new(
          options[:config].access_key_id,
          options[:config].secret_access_key,
          options[:config].session_token)
      else
        nil
      end
    end

    def env_credentials(options)
      key =    %w(AWS_ACCESS_KEY_ID     AMAZON_ACCESS_KEY_ID     AWS_ACCESS_KEY)
      secret = %w(AWS_SECRET_ACCESS_KEY AMAZON_SECRET_ACCESS_KEY AWS_SECRET_KEY)
      token =  %w(AWS_SESSION_TOKEN     AMAZON_SESSION_TOKEN)
      Credentials.new(envar(key), envar(secret), envar(token))
    end

    def envar(keys)
      keys.each do |key|
        if ENV.key?(key)
          return ENV[key]
        end
      end
      nil
    end

    def shared_credentials(options)
      if options[:config]
        SharedCredentials.new(profile_name: options[:config].profile)
      else
        SharedCredentials.new(
          profile_name: ENV['AWS_PROFILE'].nil? ? 'default' : ENV['AWS_PROFILE'])
      end
    rescue Errors::NoSuchProfileError
      nil
    end

    def process_credentials(options)
      profile_name = options[:config].profile if options[:config]
      profile_name ||= ENV['AWS_PROFILE'].nil? ? 'default' : ENV['AWS_PROFILE']
      
      config = Aws.shared_config
      if config.config_enabled? && process_provider = config.credentials_process(profile_name)
        ProcessCredentials.new(process_provider)
      else
        nil
      end
    rescue Errors::NoSuchProfileError
      nil
    end

    def assume_role_credentials(options)
      if Aws.shared_config.config_enabled?
        profile, region = nil, nil
        if options[:config]
          profile = options[:config].profile
          region = options[:config].region
          assume_role_with_profile(options[:config].profile, options[:config].region)
        end
        assume_role_with_profile(profile, region)
      else
        nil
      end
    end

    def instance_profile_credentials(options)
      if ENV["AWS_CONTAINER_CREDENTIALS_RELATIVE_URI"]
        ECSCredentials.new(options)
      else
        InstanceProfileCredentials.new(options)
      end
    end

    def assume_role_with_profile(prof, region)
      Aws.shared_config.assume_role_credentials_from_config(
        profile: prof,
        region: region,
        chain_config: @config
      )
    end

  end
end

require 'base64'

module Aws
  module Xml
    class Builder

      include Seahorse::Model::Shapes

      def initialize(rules, options = {})
        @rules = rules
        @xml = options[:target] || []
        indent = options[:indent] || '  '
        pad = options[:pad] || ''
        @builder = DocBuilder.new(target:@xml, indent:indent, pad:pad)
      end

      def to_xml(params)
        structure(@rules.location_name, @rules, params)
        @xml.join
      end
      alias serialize to_xml

      private

      def structure(name, ref, values)
        if values.empty?
          node(name, ref)
        else
          node(name, ref, structure_attrs(ref, values)) do
            ref.shape.members.each do |member_name, member_ref|
              next if values[member_name].nil?
              next if xml_attribute?(member_ref)
              member(member_ref.location_name, member_ref, values[member_name])
            end
          end
        end
      end

      def structure_attrs(ref, values)
        ref.shape.members.inject({}) do |attrs, (member_name, member_ref)|
          if xml_attribute?(member_ref) && values.key?(member_name)
            attrs[member_ref.location_name] = values[member_name]
          end
          attrs
        end
      end

      def list(name, ref, values)
        if ref.shape.flattened
          values.each do |value|
            member(ref.shape.member.location_name || name, ref.shape.member, value)
          end
        else
          node(name, ref) do
            values.each do |value|
              mname = ref.shape.member.location_name || 'member'
              member(mname, ref.shape.member, value)
            end
          end
        end
      end

      def map(name, ref, hash)
        key_ref = ref.shape.key
        value_ref = ref.shape.value
        if ref.shape.flattened
          hash.each do |key, value|
            node(name, ref) do
              member(key_ref.location_name || 'key', key_ref, key)
              member(value_ref.location_name || 'value', value_ref, value)
            end
          end
        else
          node(name, ref) do
            hash.each do |key, value|
              node('entry', ref)  do
                member(key_ref.location_name || 'key', key_ref, key)
                member(value_ref.location_name || 'value', value_ref, value)
              end
            end
          end
        end
      end

      def member(name, ref, value)
        case ref.shape
        when StructureShape then structure(name, ref, value)
        when ListShape      then list(name, ref, value)
        when MapShape       then map(name, ref, value)
        when TimestampShape then node(name, ref, timestamp(ref, value))
        when BlobShape      then node(name, ref, blob(value))
        else
          node(name, ref, value.to_s)
        end
      end

      def blob(value)
        value = value.read unless String === value
        Base64.strict_encode64(value)
      end

      def timestamp(ref, value)
        case ref['timestampFormat'] || ref.shape['timestampFormat']
        when 'unixTimestamp' then value.to_i
        when 'rfc822' then value.utc.httpdate
        else
          # xml defaults to iso8601
          value.utc.iso8601
        end
      end

      # The `args` list may contain:
      #
      #   * [] - empty, no value or attributes
      #   * [value] - inline element, no attributes
      #   * [value, attributes_hash] - inline element with attributes
      #   * [attributes_hash] - self closing element with attributes
      #
      # Pass a block if you want to nest XML nodes inside.  When doing this,
      # you may *not* pass a value to the `args` list.
      #
      def node(name, ref, *args, &block)
        attrs = args.last.is_a?(Hash) ? args.pop : {}
        attrs = shape_attrs(ref).merge(attrs)
        args << attrs
        @builder.node(name, *args, &block)
      end

      def shape_attrs(ref)
        if xmlns = ref['xmlNamespace']
          if prefix = xmlns['prefix']
            { 'xmlns:' + prefix => xmlns['uri'] }
          else
            { 'xmlns' => xmlns['uri'] }
          end
        else
          {}
        end
      end

      def xml_attribute?(ref)
        !!ref['xmlAttribute']
      end

    end
  end
end
module Aws
  module Xml
    # @api private
    class DefaultList < Array

      alias nil? empty?

    end
  end
end
module Aws
  module Xml
    # @api private
    class DefaultMap < Hash

      alias nil? empty?

    end
  end
end
module Aws
  module Xml
    class DocBuilder

      # @option options [#<<] :target ('')
      # @option options [String] :pad ('')
      # @option options [String] :indent ('')
      def initialize(options = {})
        @target = options[:target] || ''
        @indent = options[:indent] || ''
        @pad = options[:pad] || ''
        @end_of_line = @indent == '' ? '' : "\n"
      end

      attr_reader :target

      # @overload node(name, attributes = {})
      #   Adds a self closing element without any content.
      #
      # @overload node(name, value, attributes = {})
      #   Adds an element that opens and closes on the same line with
      #   simple text content.
      #
      # @overload node(name, attributes = {}, &block)
      #   Adds a wrapping element.  Calling {#node} from inside
      #   the yielded block creates nested elements.
      #
      # @return [void]
      #
      def node(name, *args, &block)
        attrs = args.last.is_a?(Hash) ? args.pop : {}
        if block_given?
          @target << open_el(name, attrs)
          @target << @end_of_line
          increase_pad { yield }
          @target << @pad
          @target << close_el(name)
        elsif args.empty?
          @target << empty_element(name, attrs)
        else
          @target << inline_element(name, args.first, attrs)
        end
      end

      private

      def empty_element(name, attrs)
        "#{@pad}<#{name}#{attributes(attrs)}/>#{@end_of_line}"
      end

      def inline_element(name, value, attrs)
        "#{open_el(name, attrs)}#{escape(value, :text)}#{close_el(name)}"
      end

      def open_el(name, attrs)
        "#{@pad}<#{name}#{attributes(attrs)}>"
      end

      def close_el(name)
        "</#{name}>#{@end_of_line}"
      end

      def escape(string, text_or_attr)
        string.to_s.encode(:xml => text_or_attr)
      end

      def attributes(attr)
        if attr.empty?
          ''
        else
          ' ' + attr.map do |key, value|
            "#{key}=#{escape(value, :attr)}"
          end.join(' ')
        end
      end

      def increase_pad(&block)
        pre_increase = @pad
        @pad = @pad + @indent
        yield
        @pad = pre_increase
      end

    end
  end
end
require 'cgi'

module Aws
  module Xml
    class ErrorHandler < Seahorse::Client::Handler

      def call(context)
        @handler.call(context).on(300..599) do |response|
          response.error = error(context)
          response.data = nil
        end
      end

      private

      def error(context)
        body = context.http_response.body_contents
        if body.empty?
          code = http_status_error_code(context)
          message = ''
          data = EmptyStructure.new
        else
          code, message, data = extract_error(body, context)
        end
        errors_module = context.client.class.errors_module
        error_class = errors_module.error_class(code).new(context, message, data)
        error_class
      end

      def extract_error(body, context)
        code = error_code(body, context)
        [
          code,
          error_message(body),
          error_data(context, code)
        ]
      end

      def error_data(context, code)
        data = EmptyStructure.new
        if error_rules = context.operation.errors
          error_rules.each do |rule|
            # for modeled shape with error trait
            # match `code` in the error trait before
            # match modeled shape name
            error_shape_code = rule.shape['error']['code'] if rule.shape['error']
            match = (code == error_shape_code || code == rule.shape.name)
            if match && rule.shape.members.any?
              data = Parser.new(rule).parse(context.http_response.body_contents)
            end
          end
        end
        data
      rescue Xml::Parser::ParsingError
        EmptyStructure.new
      end

      def error_code(body, context)
        if matches = body.match(/<Code>(.+?)<\/Code>/)
          remove_prefix(unescape(matches[1]), context)
        else
          http_status_error_code(context)
        end
      end

      def http_status_error_code(context)
        status_code = context.http_response.status_code
        {
          302 => 'MovedTemporarily',
          304 => 'NotModified',
          400 => 'BadRequest',
          403 => 'Forbidden',
          404 => 'NotFound',
          412 => 'PreconditionFailed',
          413 => 'RequestEntityTooLarge',
        }[status_code] || "Http#{status_code}Error"
      end

      def remove_prefix(error_code, context)
        if prefix = context.config.api.metadata['errorPrefix']
          error_code.sub(/^#{prefix}/, '')
        else
          error_code
        end
      end

      def error_message(body)
        if matches = body.match(/<Message>(.+?)<\/Message>/m)
          unescape(matches[1])
        else
          ''
        end
      end

      def unescape(str)
        CGI.unescapeHTML(str)
      end

    end
  end
end
module Aws
  # @api private
  module Xml
    # A SAX-style XML parser that uses a shape context to handle types.
    class Parser

      # @param [Seahorse::Model::ShapeRef] rules
      def initialize(rules, options = {})
        @rules = rules
        @engine = options[:engine] || self.class.engine
      end

      # Parses the XML document, returning a parsed structure.
      #
      # If you pass a block, this will yield for XML
      # elements that are not modeled in the rules given
      # to the constructor.
      #
      #   parser.parse(xml) do |path, value|
      #     puts "uhandled: #{path.join('/')} - #{value}"
      #   end
      #
      # The purpose of the unhandled callback block is to
      # allow callers to access values such as the EC2
      # request ID that are part of the XML body but not
      # part of the operation result.
      #
      # @param [String] xml An XML document string to parse.
      # @param [Structure] target (nil)
      # @return [Structure]
      def parse(xml, target = nil, &unhandled_callback)
        xml = '<xml/>' if xml.nil? or xml.empty?
        stack = Stack.new(@rules, target, &unhandled_callback)
        @engine.new(stack).parse(xml.to_s)
        stack.result
      end

      class << self

        # @param [Symbol,Class] engine
        #   Must be one of the following values:
        #
        #   * :ox
        #   * :oga
        #   * :libxml
        #   * :nokogiri
        #   * :rexml
        #
        def engine= engine
          @engine = Class === engine ? engine : load_engine(engine)
        end

        # @return [Class] Returns the default parsing engine.
        #   One of:
        #
        #   * {OxEngine}
        #   * {OgaEngine}
        #   * {LibxmlEngine}
        #   * {NokogiriEngine}
        #   * {RexmlEngine}
        #
        def engine
          set_default_engine unless @engine
          @engine
        end

        def set_default_engine
          [:ox, :oga, :libxml, :nokogiri, :rexml].each do |name|
            @engine ||= try_load_engine(name)
          end
        end

        private

        def load_engine(name)
          require_relative "aws-sdk-core/xml/parser/engines/#{name}"
          const_name = name[0].upcase + name[1..-1] + 'Engine'
          const_get(const_name)
        end

        def try_load_engine(name)
          load_engine(name)
        rescue LoadError
          false
        end

      end

      set_default_engine

    end
  end
end
module Aws
  module Xml
    class Parser
      class Stack

        def initialize(ref, result = nil, &unhandled_callback)
          @ref = ref
          @frame = self
          @result = result
          @unhandled_callback = unhandled_callback
        end

        attr_reader :frame

        attr_reader :result

        def start_element(name)
          @frame = @frame.child_frame(name.to_s)
        end

        def attr(name, value)
          if name.to_s == 'encoding' && value.to_s == 'base64'
            @frame = BlobFrame.new(name, @frame.parent, @frame.ref)
          else
            start_element(name)
            text(value)
            end_element(name)
          end
        end

        def text(value)
          @frame.set_text(value)
        end

        def end_element(*args)
          @frame.parent.consume_child_frame(@frame)
          if @frame.parent.is_a?(FlatListFrame)
            @frame = @frame.parent
            @frame.parent.consume_child_frame(@frame)
          end
          @frame = @frame.parent
        end

        def error(msg, line = nil, column = nil)
          raise ParsingError.new(msg, line, column)
        end

        def child_frame(name)
          Frame.new(name, self, @ref, @result)
        end

        def consume_child_frame(frame)
          @result = frame.result
        end

        # @api private
        def yield_unhandled_value(path, value)
          if @unhandled_callback
            @unhandled_callback.call(path, value)
          end
        end

      end
    end
  end
end
require 'base64'
require 'time'

module Aws
  module Xml
    class Parser
      class Frame

        include Seahorse::Model::Shapes

        class << self

          def new(path, parent, ref, result = nil)
            if self == Frame
              frame = frame_class(ref).allocate
              frame.send(:initialize, path, parent, ref, result)
              frame
            else
              super
            end
          end

          private

          def frame_class(ref)
            klass = FRAME_CLASSES[ref.shape.class]
            if ListFrame == klass && (ref.shape.flattened || ref["flattened"])
              FlatListFrame
            elsif MapFrame == klass && (ref.shape.flattened || ref["flattened"])
              MapEntryFrame
            else
              klass
            end
          end

        end

        def initialize(path, parent, ref, result)
          @path = path
          @parent = parent
          @ref = ref
          @result = result
          @text = []
        end

        attr_reader :parent

        attr_reader :ref

        attr_reader :result

        def set_text(value)
          @text << value
        end

        def child_frame(xml_name)
          NullFrame.new(xml_name, self)
        end

        def consume_child_frame(child); end

        # @api private
        def path
          if Stack === parent
            [@path]
          else
            parent.path + [@path]
          end
        end

        # @api private
        def yield_unhandled_value(path, value)
          parent.yield_unhandled_value(path, value)
        end

      end

      class StructureFrame < Frame

        def initialize(xml_name, parent, ref, result = nil)
          super
          @result ||= ref.shape.struct_class.new
          @members = {}
          ref.shape.members.each do |member_name, member_ref|
            apply_default_value(member_name, member_ref)
            @members[xml_name(member_ref)] = {
              name: member_name,
              ref: member_ref,
            }
          end
        end

        def child_frame(xml_name)
          if @member = @members[xml_name]
            Frame.new(xml_name, self, @member[:ref])
          else
            NullFrame.new(xml_name, self)
          end
        end

        def consume_child_frame(child)
          case child
          when MapEntryFrame
            @result[@member[:name]][child.key.result] = child.value.result
          when FlatListFrame
            @result[@member[:name]] << child.result
          when NullFrame
          else
            @result[@member[:name]] = child.result
          end
        end

        private

        def apply_default_value(name, ref)
          case ref.shape
          when ListShape then @result[name] = DefaultList.new
          when MapShape then @result[name] = DefaultMap.new
          end
        end

        def xml_name(ref)
          if flattened_list?(ref)
            ref.shape.member.location_name || ref.location_name
          else
            ref.location_name
          end
        end

        def flattened_list?(ref)
          ListShape === ref.shape && (ref.shape.flattened || ref["flattened"])
        end

      end

      class ListFrame < Frame

        def initialize(*args)
          super
          @result = []
          @member_xml_name = @ref.shape.member.location_name || 'member'
        end

        def child_frame(xml_name)
          if xml_name == @member_xml_name
            Frame.new(xml_name, self, @ref.shape.member)
          else
            raise NotImplementedError
          end
        end

        def consume_child_frame(child)
          @result << child.result unless NullFrame === child
        end

      end

      class FlatListFrame < Frame

        def initialize(xml_name, *args)
          super
          @member = Frame.new(xml_name, self, @ref.shape.member)
        end

        def result
          @member.result
        end

        def set_text(value)
          @member.set_text(value)
        end

        def child_frame(xml_name)
          @member.child_frame(xml_name)
        end

        def consume_child_frame(child)
          @result = @member.result
        end

      end

      class MapFrame < Frame

        def initialize(*args)
          super
          @result = {}
        end

        def child_frame(xml_name)
          if xml_name == 'entry'
            MapEntryFrame.new(xml_name, self, @ref)
          else
            raise NotImplementedError
          end
        end

        def consume_child_frame(child)
          @result[child.key.result] = child.value.result
        end

      end

      class MapEntryFrame < Frame

        def initialize(xml_name, *args)
          super
          @key_name = @ref.shape.key.location_name || 'key'
          @key = Frame.new(xml_name, self, @ref.shape.key)
          @value_name = @ref.shape.value.location_name || 'value'
          @value = Frame.new(xml_name, self, @ref.shape.value)
        end

        # @return [StringFrame]
        attr_reader :key

        # @return [Frame]
        attr_reader :value

        def child_frame(xml_name)
          if @key_name == xml_name
            @key
          elsif @value_name == xml_name
            @value
          else
            NullFrame.new(xml_name, self)
          end
        end

      end

      class NullFrame < Frame
        def self.new(xml_name, parent)
          super(xml_name, parent, nil, nil)
        end

        def set_text(value)
          yield_unhandled_value(path, value)
          super
        end
      end

      class BlobFrame < Frame
        def result
          @text.empty? ? nil : Base64.decode64(@text.join)
        end
      end

      class BooleanFrame < Frame
        def result
          @text.empty? ? nil : (@text.join == 'true')
        end
      end

      class FloatFrame < Frame
        def result
          @text.empty? ? nil : @text.join.to_f
        end
      end

      class IntegerFrame < Frame
        def result
          @text.empty? ? nil : @text.join.to_i
        end
      end

      class StringFrame < Frame
        def result
          @text.join
        end
      end

      class TimestampFrame < Frame
        def result
          @text.empty? ? nil : parse(@text.join)
        end
        def parse(value)
          case value
          when nil then nil
          when /^\d+$/ then Time.at(value.to_i)
          else
            begin
              Time.parse(value).utc
            rescue ArgumentError
              raise "unhandled timestamp format `#{value}'"
            end
          end
        end
      end

      include Seahorse::Model::Shapes

      FRAME_CLASSES = {
        NilClass => NullFrame,
        BlobShape => BlobFrame,
        BooleanShape => BooleanFrame,
        FloatShape => FloatFrame,
        IntegerShape => IntegerFrame,
        ListShape => ListFrame,
        MapShape => MapFrame,
        StringShape => StringFrame,
        StructureShape => StructureFrame,
        TimestampShape => TimestampFrame,
      }

    end
  end
end
module Aws
  module Xml
    class Parser
      class ParsingError < RuntimeError

        def initialize(msg, line, column)
          super(msg)
        end

        # @return [Integer,nil]
        attr_reader :line

        # @return [Integer,nil]
        attr_reader :column

      end
    end
  end
end
# KG-dev::RubyPacker replaced for xml/builder.rb
# KG-dev::RubyPacker replaced for xml/default_list.rb
# KG-dev::RubyPacker replaced for xml/default_map.rb
# KG-dev::RubyPacker replaced for xml/doc_builder.rb
# KG-dev::RubyPacker replaced for xml/error_handler.rb
# KG-dev::RubyPacker replaced for xml/parser.rb
# KG-dev::RubyPacker replaced for xml/parser/stack.rb
# KG-dev::RubyPacker replaced for xml/parser/frame.rb
# KG-dev::RubyPacker replaced for xml/parser/parsing_error.rb

require 'base64'

module Aws
  module Json
    class Builder

      include Seahorse::Model::Shapes

      def initialize(rules)
        @rules = rules
      end

      def to_json(params)
        Json.dump(format(@rules, params))
      end
      alias serialize to_json

      private

      def structure(ref, values)
        shape = ref.shape
        values.each_pair.with_object({}) do |(key, value), data|
          if shape.member?(key) && !value.nil?
            member_ref = shape.member(key)
            member_name = member_ref.location_name || key
            data[member_name] = format(member_ref, value)
          end
        end
      end

      def list(ref, values)
        member_ref = ref.shape.member
        values.collect { |value| format(member_ref, value) }
      end

      def map(ref, values)
        value_ref = ref.shape.value
        values.each.with_object({}) do |(key, value), data|
          data[key] = format(value_ref, value)
        end
      end

      def format(ref, value)
        case ref.shape
        when StructureShape then structure(ref, value)
        when ListShape      then list(ref, value)
        when MapShape       then map(ref, value)
        when TimestampShape then timestamp(ref, value)
        when BlobShape      then encode(value)
        else value
        end
      end

      def encode(blob)
        Base64.strict_encode64(String === blob ? blob : blob.read)
      end

      def timestamp(ref, value)
        case ref['timestampFormat'] || ref.shape['timestampFormat']
        when 'iso8601' then value.utc.iso8601
        when 'rfc822' then value.utc.httpdate
        else
          # rest-json and jsonrpc default to unixTimestamp
          value.to_i
        end
      end

    end
  end
end
module Aws
  module Json
    class ErrorHandler < Xml::ErrorHandler

      # @param [Seahorse::Client::RequestContext] context
      # @return [Seahorse::Client::Response]
      def call(context)
        @handler.call(context).on(300..599) do |response|
          response.error = error(context)
          response.data = nil
        end
      end

      private

      def extract_error(body, context)
        json = Json.load(body)
        code = error_code(json, context)
        message = error_message(code, json)
        data = parse_error_data(context, code)
        [code, message, data]
      rescue Json::ParseError
        [http_status_error_code(context), '', EmptyStructure.new]
      end

      def error_code(json, context)
        code = json['__type']
        code ||= json['code']
        code ||= context.http_response.headers['x-amzn-errortype']
        if code
          code.split('#').last
        else
          http_status_error_code(context)
        end
      end

      def error_message(code, json)
        if code == 'RequestEntityTooLarge'
          'Request body must be less than 1 MB'
        else
          json['message'] || json['Message'] || ''
        end
      end

      def parse_error_data(context, code)
        data = EmptyStructure.new
        if error_rules = context.operation.errors
          error_rules.each do |rule|
            # match modeled shape name with the type(code) only
            # some type(code) might contains invalid characters
            # such as ':' (efs) etc
            match = rule.shape.name == code.gsub(/[^^a-zA-Z0-9]/, '')
            if match && rule.shape.members.any?
              data = Parser.new(rule).parse(context.http_response.body_contents)
            end
          end
        end
        data
      end

    end
  end
end
module Aws
  module Json
    class Handler < Seahorse::Client::Handler

      CONTENT_TYPE = 'application/x-amz-json-%s'

      # @param [Seahorse::Client::RequestContext] context
      # @return [Seahorse::Client::Response]
      def call(context)
        build_request(context)
        response = @handler.call(context)
        response.on(200..299) { |resp| parse_response(resp) }
        response.on(200..599) { |resp| apply_request_id(context) }
        response
      end

      private

      def build_request(context)
        context.http_request.http_method = 'POST'
        context.http_request.headers['Content-Type'] = content_type(context)
        context.http_request.headers['X-Amz-Target'] = target(context)
        context.http_request.body = build_body(context)
      end

      def build_body(context)
        if simple_json?(context)
          Json.dump(context.params)
        else
          Builder.new(context.operation.input).serialize(context.params)
        end
      end

      def parse_response(response)
        response.data = parse_body(response.context)
      end

      def parse_body(context)
        if simple_json?(context)
          Json.load(context.http_response.body_contents)
        elsif rules = context.operation.output
          json = context.http_response.body_contents
          if json.is_a?(Array)
            # an array of emitted events
            if json[0].respond_to?(:response)
              # initial response exists
              # it must be the first event arrived
              resp_struct = json.shift.response
            else
              resp_struct = context.operation.output.shape.struct_class.new
            end

            rules.shape.members.each do |name, ref|
              if ref.eventstream
                resp_struct.send("#{name}=", json.to_enum)
              end
            end
            resp_struct
          else
            Parser.new(rules).parse(json == '' ? '{}' : json)
          end
        else
          EmptyStructure.new
        end
      end

      def content_type(context)
        CONTENT_TYPE % [context.config.api.metadata['jsonVersion']]
      end

      def target(context)
        prefix = context.config.api.metadata['targetPrefix']
        "#{prefix}.#{context.operation.name}"
      end

      def apply_request_id(context)
        context[:request_id] = context.http_response.headers['x-amzn-requestid']
      end

      def simple_json?(context)
        context.config.simple_json
      end

    end
  end
end
require 'base64'
require 'time'

module Aws
  module Json
    class Parser

      include Seahorse::Model::Shapes

      # @param [Seahorse::Model::ShapeRef] rules
      def initialize(rules)
        @rules = rules
      end

      # @param [String<JSON>] json
      def parse(json, target = nil)
        parse_ref(@rules, Json.load(json), target)
      end

      private

      def structure(ref, values, target = nil)
        shape = ref.shape
        target = ref.shape.struct_class.new if target.nil?
        values.each do |key, value|
          member_name, member_ref = shape.member_by_location_name(key)
          if member_ref
            target[member_name] = parse_ref(member_ref, value)
          end
        end
        target
      end

      def list(ref, values, target = nil)
        target = [] if target.nil?
        values.each do |value|
          target << parse_ref(ref.shape.member, value)
        end
        target
      end

      def map(ref, values, target = nil)
        target = {} if target.nil?
        values.each do |key, value|
          target[key] = parse_ref(ref.shape.value, value)
        end
        target
      end

      def parse_ref(ref, value, target = nil)
        if value.nil?
          nil
        else
          case ref.shape
          when StructureShape then structure(ref, value, target)
          when ListShape then list(ref, value, target)
          when MapShape then map(ref, value, target)
          when TimestampShape then time(value)
          when BlobShape then Base64.decode64(value)
          when BooleanShape then value.to_s == 'true'
          else value
          end
        end
      end

      # @param [String, Integer] value
      # @return [Time]
      def time(value)
        value.is_a?(Numeric) ? Time.at(value) : Time.parse(value)
      end

    end
  end
end
# KG-dev::RubyPacker replaced for json.rb
# KG-dev::RubyPacker replaced for json/builder.rb
# KG-dev::RubyPacker replaced for json/error_handler.rb
# KG-dev::RubyPacker replaced for json/handler.rb
# KG-dev::RubyPacker replaced for json/parser.rb

module Aws
  # @api private
  module Json

    class ParseError < StandardError

      def initialize(error)
        @error = error
        super(error.message)
      end

      attr_reader :error

    end

    class << self

      def load(json)
        ENGINE.load(json, *ENGINE_LOAD_OPTIONS)
      rescue ENGINE_ERROR => e
        raise ParseError.new(e)
      end

      def load_file(path)
        self.load(File.open(path, 'r', encoding: 'UTF-8') { |f| f.read })
      end

      def dump(value)
        ENGINE.dump(value, *ENGINE_DUMP_OPTIONS)
      end

      private

      def oj_engine
        require 'oj'
        [Oj, [{mode: :compat, symbol_keys: false}], [{ mode: :compat }], oj_parse_error]
      rescue LoadError
        false
      end

      def json_engine
        [JSON, [], [], JSON::ParserError]
      end

      def oj_parse_error
        if Oj.const_defined?('ParseError')
          Oj::ParseError
        else
          SyntaxError
        end
      end

    end

    # @api private
    ENGINE, ENGINE_LOAD_OPTIONS, ENGINE_DUMP_OPTIONS, ENGINE_ERROR =
      oj_engine || json_engine

  end
end
# KG-dev::RubyPacker replaced for json.rb
require 'time'
require 'net/http'

module Aws
  class ECSCredentials

    include CredentialProvider
    include RefreshingCredentials

    # @api private
    class Non200Response < RuntimeError; end

    # These are the errors we trap when attempting to talk to the
    # instance metadata service.  Any of these imply the service
    # is not present, no responding or some other non-recoverable
    # error.
    # @api private
    NETWORK_ERRORS = [
      Errno::EHOSTUNREACH,
      Errno::ECONNREFUSED,
      Errno::EHOSTDOWN,
      Errno::ENETUNREACH,
      SocketError,
      Timeout::Error,
      Non200Response,
    ]

    # @param [Hash] options
    # @option options [Integer] :retries (5) Number of times to retry
    #   when retrieving credentials.
    # @option options [String] :ip_address ('169.254.170.2')
    # @option options [Integer] :port (80)
    # @option options [String] :credential_path By default, the value of the
    #   AWS_CONTAINER_CREDENTIALS_RELATIVE_URI environment variable.
    # @option options [Float] :http_open_timeout (5)
    # @option options [Float] :http_read_timeout (5)
    # @option options [Numeric, Proc] :delay By default, failures are retried
    #   with exponential back-off, i.e. `sleep(1.2 ** num_failures)`. You can
    #   pass a number of seconds to sleep between failed attempts, or
    #   a Proc that accepts the number of failures.
    # @option options [IO] :http_debug_output (nil) HTTP wire
    #   traces are sent to this object.  You can specify something
    #   like $stdout.
    def initialize options = {}
      @retries = options[:retries] || 5
      @ip_address = options[:ip_address] || '169.254.170.2'
      @port = options[:port] || 80
      @credential_path = options[:credential_path]
      @credential_path ||= ENV['AWS_CONTAINER_CREDENTIALS_RELATIVE_URI']
      unless @credential_path
        raise ArgumentError.new(
          "Cannot instantiate an ECS Credential Provider without a credential path."
        )
      end
      @http_open_timeout = options[:http_open_timeout] || 5
      @http_read_timeout = options[:http_read_timeout] || 5
      @http_debug_output = options[:http_debug_output]
      @backoff = backoff(options[:backoff])
      super
    end

    # @return [Integer] The number of times to retry failed attempts to
    #   fetch credentials from the instance metadata service. Defaults to 0.
    attr_reader :retries

    private

    def backoff(backoff)
      case backoff
      when Proc then backoff
      when Numeric then lambda { |_| sleep(backoff) }
      else lambda { |num_failures| Kernel.sleep(1.2 ** num_failures) }
      end
    end

    def refresh
      # Retry loading credentials up to 3 times is the instance metadata
      # service is responding but is returning invalid JSON documents
      # in response to the GET profile credentials call.
      retry_errors([JSON::ParserError, StandardError], max_retries: 3) do
        c = JSON.parse(get_credentials.to_s)
        @credentials = Credentials.new(
          c['AccessKeyId'],
          c['SecretAccessKey'],
          c['Token']
        )
        @expiration = c['Expiration'] ? Time.iso8601(c['Expiration']) : nil
      end
    end

    def get_credentials
      # Retry loading credentials a configurable number of times if
      # the instance metadata service is not responding.
      begin
        retry_errors(NETWORK_ERRORS, max_retries: @retries) do
          open_connection do |conn|
            http_get(conn, @credential_path)
          end
        end
      rescue
        '{}'
      end
    end

    def open_connection
      http = Net::HTTP.new(@ip_address, @port, nil)
      http.open_timeout = @http_open_timeout
      http.read_timeout = @http_read_timeout
      http.set_debug_output(@http_debug_output) if @http_debug_output
      http.start
      yield(http).tap { http.finish }
    end

    def http_get(connection, path)
      response = connection.request(Net::HTTP::Get.new(path))
      if response.code.to_i == 200
        response.body
      else
        raise Non200Response
      end
    end

    def retry_errors(error_classes, options = {}, &block)
      max_retries = options[:max_retries]
      retries = 0
      begin
        yield
      rescue *error_classes => _error
        if retries < max_retries
          @backoff.call(retries)
          retries += 1
          retry
        else
          raise
        end
      end
    end

  end
end
# KG-dev::RubyPacker replaced for json.rb
require 'time'
require 'net/http'

module Aws
  class InstanceProfileCredentials

    include CredentialProvider
    include RefreshingCredentials

    # @api private
    class Non200Response < RuntimeError; end

    # These are the errors we trap when attempting to talk to the
    # instance metadata service.  Any of these imply the service
    # is not present, no responding or some other non-recoverable
    # error.
    # @api private
    NETWORK_ERRORS = [
      Errno::EHOSTUNREACH,
      Errno::ECONNREFUSED,
      Errno::EHOSTDOWN,
      Errno::ENETUNREACH,
      SocketError,
      Timeout::Error,
      Non200Response,
    ]

    # @param [Hash] options
    # @option options [Integer] :retries (5) Number of times to retry
    #   when retrieving credentials.
    # @option options [String] :ip_address ('169.254.169.254')
    # @option options [Integer] :port (80)
    # @option options [Float] :http_open_timeout (5)
    # @option options [Float] :http_read_timeout (5)
    # @option options [Numeric, Proc] :delay By default, failures are retried
    #   with exponential back-off, i.e. `sleep(1.2 ** num_failures)`. You can
    #   pass a number of seconds to sleep between failed attempts, or
    #   a Proc that accepts the number of failures.
    # @option options [IO] :http_debug_output (nil) HTTP wire
    #   traces are sent to this object.  You can specify something
    #   like $stdout.
    def initialize options = {}
      @retries = options[:retries] || 5
      @ip_address = options[:ip_address] || '169.254.169.254'
      @port = options[:port] || 80
      @http_open_timeout = options[:http_open_timeout] || 5
      @http_read_timeout = options[:http_read_timeout] || 5
      @http_debug_output = options[:http_debug_output]
      @backoff = backoff(options[:backoff])
      super
    end

    # @return [Integer] The number of times to retry failed attempts to
    #   fetch credentials from the instance metadata service. Defaults to 0.
    attr_reader :retries

    private

    def backoff(backoff)
      case backoff
      when Proc then backoff
      when Numeric then lambda { |_| sleep(backoff) }
      else lambda { |num_failures| Kernel.sleep(1.2 ** num_failures) }
      end
    end

    def refresh
      # Retry loading credentials up to 3 times is the instance metadata
      # service is responding but is returning invalid JSON documents
      # in response to the GET profile credentials call.
      retry_errors([JSON::ParserError, StandardError], max_retries: 3) do
        c = JSON.parse(get_credentials.to_s)
        @credentials = Credentials.new(
          c['AccessKeyId'],
          c['SecretAccessKey'],
          c['Token']
        )
        @expiration = c['Expiration'] ? Time.iso8601(c['Expiration']) : nil
      end
    end

    def get_credentials
      # Retry loading credentials a configurable number of times if
      # the instance metadata service is not responding.
      if _metadata_disabled?
        '{}'
      else
        begin
          retry_errors(NETWORK_ERRORS, max_retries: @retries) do
            open_connection do |conn|
              path = '/latest/meta-data/iam/security-credentials/'
              profile_name = http_get(conn, path).lines.first.strip
              http_get(conn, path + profile_name)
            end
          end
        rescue
          '{}'
        end
      end
    end

    def _metadata_disabled?
      flag = ENV["AWS_EC2_METADATA_DISABLED"]
      !flag.nil? && flag.downcase == "true"
    end

    def open_connection
      http = Net::HTTP.new(@ip_address, @port, nil)
      http.open_timeout = @http_open_timeout
      http.read_timeout = @http_read_timeout
      http.set_debug_output(@http_debug_output) if @http_debug_output
      http.start
      yield(http).tap { http.finish }
    end

    def http_get(connection, path)
      response = connection.request(Net::HTTP::Get.new(path, {"User-Agent" => "aws-sdk-ruby3/#{CORE_GEM_VERSION}"}))
      if response.code.to_i == 200
        response.body
      else
        raise Non200Response
      end
    end

    def retry_errors(error_classes, options = {}, &block)
      max_retries = options[:max_retries]
      retries = 0
      begin
        yield
      rescue *error_classes
        if retries < max_retries
          @backoff.call(retries)
          retries += 1
          retry
        else
          raise
        end
      end
    end

  end
end
module Aws
  # @api private
  class IniParser
    class << self

      def ini_parse(raw)
        current_profile = nil
        current_prefix = nil
        raw.lines.inject({}) do |acc, line|
          line = line.split(/^|\s;/).first # remove comments
          profile = line.match(/^\[([^\[\]]+)\]\s*(#.+)?$/) unless line.nil?
          if profile
            current_profile = profile[1]
            named_profile = current_profile.match(/^profile\s+(.+?)$/)
            current_profile = named_profile[1] if named_profile
          elsif current_profile
            unless line.nil?
              item = line.match(/^(.+?)\s*=\s*(.+?)\s*$/)
              prefix = line.match(/^(.+?)\s*=\s*$/)
            end
            if item && item[1].match(/^\s+/)
              # Need to add lines to a nested configuration.
              inner_item = line.match(/^\s*(.+?)\s*=\s*(.+?)\s*$/)
              acc[current_profile] ||= {}
              acc[current_profile][current_prefix] ||= {}
              acc[current_profile][current_prefix][inner_item[1]] = inner_item[2]
            elsif item
              current_prefix = nil
              acc[current_profile] ||= {}
              acc[current_profile][item[1]] = item[2]
            elsif prefix
              current_prefix = prefix[1]
            end
          end
          acc
        end
      end

    end
  end
end
# KG-dev::RubyPacker replaced for ini_parser.rb

module Aws
  class SharedCredentials

    include CredentialProvider

    # @api private
    KEY_MAP = {
      'aws_access_key_id' => 'access_key_id',
      'aws_secret_access_key' => 'secret_access_key',
      'aws_session_token' => 'session_token',
    }

    # Constructs a new SharedCredentials object. This will load AWS access
    # credentials from an ini file, which supports profiles. The default
    # profile name is 'default'. You can specify the profile name with the
    # `ENV['AWS_PROFILE']` or with the `:profile_name` option.
    #
    # @option [String] :path Path to the shared file.  Defaults
    #   to "#{Dir.home}/.aws/credentials".
    #
    # @option [String] :profile_name Defaults to 'default' or
    #   `ENV['AWS_PROFILE']`.
    #
    def initialize(options = {})
      shared_config = Aws.shared_config
      @path = options[:path]
      @path ||= shared_config.credentials_path
      @profile_name = options[:profile_name]
      @profile_name ||= ENV['AWS_PROFILE']
      @profile_name ||= shared_config.profile_name
      if @path && @path == shared_config.credentials_path
        @credentials = shared_config.credentials(profile: @profile_name)
      else
        config = SharedConfig.new(
          credentials_path: @path,
          profile_name: @profile_name
        )
        @credentials = config.credentials(profile: @profile_name)
      end
    end

    # @return [String]
    attr_reader :path

    # @return [String]
    attr_reader :profile_name

    # @return [Credentials]
    attr_reader :credentials

    # @api private
    def inspect
      parts = [
        self.class.name,
        "profile_name=#{profile_name.inspect}",
        "path=#{path.inspect}",
      ]
      "#<#{parts.join(' ')}>"
    end

    # @deprecated This method is no longer used.
    # @return [Boolean] Returns `true` if a credential file
    #   exists and has appropriate read permissions at {#path}.
    # @note This method does not indicate if the file found at {#path}
    #   will be parsable, only if it can be read.
    def loadable?
      !path.nil? && File.exist?(path) && File.readable?(path)
    end

  end
end
require 'open3'

module Aws

  # A credential provider that executes a given process and attempts
  # to read its stdout to recieve a JSON payload containing the credentials
  #
  # Automatically handles refreshing credentials if an Expiration time is 
  # provided in the credentials payload
  #
  #     credentials = Aws::ProcessCredentials.new('/usr/bin/credential_proc').credentials
  #
  #     ec2 = Aws::EC2::Client.new(credentials: credentials)
  #
  # More documentation on process based credentials can be found here:
  # https://docs.aws.amazon.com/cli/latest/topic/config-vars.html#sourcing-credentials-from-external-processes
  class ProcessCredentials

    include CredentialProvider
    include RefreshingCredentials

    # Creates a new ProcessCredentials object, which allows an
    # external process to be used as a credential provider.
    #
    # @param [String] process Invocation string for process
    # credentials provider. 
    def initialize(process)
      @process = process
      @credentials = credentials_from_process(@process)
      
      super
    end

    private
    def credentials_from_process(proc_invocation)
      begin
        raw_out, process_status = Open3.capture2(proc_invocation)
      rescue Errno::ENOENT
        raise Errors::InvalidProcessCredentialsPayload.new("Could not find process #{proc_invocation}")
      end

      if process_status.success?
        creds_json = JSON.parse(raw_out)
        payload_version = creds_json['Version']
        if payload_version == 1
          _parse_payload_format_v1(creds_json)
        else
          raise Errors::InvalidProcessCredentialsPayload.new("Invalid version #{payload_version} for credentials payload")
        end
      else
        raise Errors::InvalidProcessCredentialsPayload.new('credential_process provider failure, the credential process had non zero exit status and failed to provide credentials')
      end
    end

    def _parse_payload_format_v1(creds_json)
      creds = Credentials.new(
        creds_json['AccessKeyId'],
        creds_json['SecretAccessKey'],
        creds_json['SessionToken']
      )

      @expiration = creds_json['Expiration'] ? Time.iso8601(creds_json['Expiration']) : nil
      return creds if creds.set?
      raise Errors::InvalidProcessCredentialsPayload.new("Invalid payload for JSON credentials version 1")
    end

    def refresh
      @credentials = credentials_from_process(@process)
    end

    def near_expiration?
      # are we within 5 minutes of expiration?
      @expiration && (Time.now.to_i + 5 * 60) > @expiration.to_i
    end
  end
end
require 'thread'

module Aws

  # This module provides the ability to specify the data and/or errors to
  # return when a client is using stubbed responses. Pass
  # `:stub_responses => true` to a client constructor to enable this
  # behavior.
  #
  # Also allows you to see the requests made by the client by reading the
  # api_requests instance variable
  module ClientStubs

    # @api private
    def setup_stubbing
      @stubs = {}
      @stub_mutex = Mutex.new
      if Hash === @config.stub_responses
        @config.stub_responses.each do |operation_name, stubs|
          apply_stubs(operation_name, Array === stubs ? stubs : [stubs])
        end
      end

      # When a client is stubbed allow the user to access the requests made
      @api_requests = []

      requests = @api_requests
      self.handle do |context|
        requests << {
          operation_name: context.operation_name,
          params: context.params,
          context: context
        }
        @handler.call(context)
      end
    end

    # Configures what data / errors should be returned from the named operation
    # when response stubbing is enabled.
    #
    # ## Basic usage
    #
    # When you enable response stubbing, the client will generate fake
    # responses and will not make any HTTP requests.
    #
    #     client = Aws::S3::Client.new(stub_responses: true)
    #     client.list_buckets
    #     #=> #<struct Aws::S3::Types::ListBucketsOutput buckets=[], owner=nil>
    #
    # You can provide stub data that will be returned by the client.
    #
    #     # stub data in the constructor
    #     client = Aws::S3::Client.new(stub_responses: {
    #       list_buckets: { buckets: [{name: 'my-bucket' }] },
    #       get_object: { body: 'data' },
    #     })
    #
    #     client.list_buckets.buckets.map(&:name) #=> ['my-bucket']
    #     client.get_object(bucket:'name', key:'key').body.read #=> 'data'
    #
    # You can also specify the stub data using {#stub_responses}
    #
    #     client = Aws::S3::Client.new(stub_responses: true)
    #     client.stub_responses(:list_buckets, {
    #       buckets: [{ name: 'my-bucket' }]
    #     })
    #
    #     client.list_buckets.buckets.map(&:name)
    #     #=> ['my-bucket']
    #
    # With a Resource class {#stub_responses} on the corresponding client:
    #
    #     s3 = Aws::S3::Resource.new(stub_responses: true)
    #     s3.client.stub_responses(:list_buckets, {
    #       buckets: [{ name: 'my-bucket' }]
    #     })
    #
    #     s3.buckets.map(&:name)
    #     #=> ['my-bucket']
    #
    # Lastly, default stubs can be configured via `Aws.config`:
    #
    #     Aws.config[:s3] = {
    #       stub_responses: {
    #         list_buckets: { buckets: [{name: 'my-bucket' }] }
    #       }
    #     }
    #
    #     Aws::S3::Client.new.list_buckets.buckets.map(&:name)
    #     #=> ['my-bucket']
    #
    #     Aws::S3::Resource.new.buckets.map(&:name)
    #     #=> ['my-bucket']
    #
    # ## Dynamic Stubbing
    #
    # In addition to creating static stubs, it's also possible to generate
    # stubs dynamically based on the parameters with which operations were
    # called, by passing a `Proc` object:
    #
    #     s3 = Aws::S3::Resource.new(stub_responses: true)
    #     s3.client.stub_responses(:put_object, -> (context) {
    #       s3.client.stub_responses(:get_object, content_type: context.params[:content_type])
    #     })
    #
    # The yielded object is an instance of {Seahorse::Client::RequestContext}.
    #
    # ## Stubbing Errors
    #
    # When stubbing is enabled, the SDK will default to generate
    # fake responses with placeholder values. You can override the data
    # returned. You can also specify errors it should raise.
    #
    #     # simulate service errors, give the error code
    #     client.stub_responses(:get_object, 'NotFound')
    #     client.get_object(bucket:'aws-sdk', key:'foo')
    #     #=> raises Aws::S3::Errors::NotFound
    #
    #     # to simulate other errors, give the error class, you must
    #     # be able to construct an instance with `.new`
    #     client.stub_responses(:get_object, Timeout::Error)
    #     client.get_object(bucket:'aws-sdk', key:'foo')
    #     #=> raises new Timeout::Error
    #
    #     # or you can give an instance of an error class
    #     client.stub_responses(:get_object, RuntimeError.new('custom message'))
    #     client.get_object(bucket:'aws-sdk', key:'foo')
    #     #=> raises the given runtime error object
    #
    # ## Stubbing HTTP Responses
    #
    # As an alternative to providing the response data, you can provide
    # an HTTP response.
    #
    #     client.stub_responses(:get_object, {
    #       status_code: 200,
    #       headers: { 'header-name' => 'header-value' },
    #       body: "...",
    #     })
    #
    # To stub a HTTP response, pass a Hash with all three of the following
    # keys set:
    #
    # * **`:status_code`** - <Integer> - The HTTP status code
    # * **`:headers`** - Hash<String,String> - A hash of HTTP header keys and values
    # * **`:body`** - <String,IO> - The HTTP response body.
    #
    # ## Stubbing Multiple Responses
    #
    # Calling an operation multiple times will return similar responses.
    # You can configure multiple stubs and they will be returned in sequence.
    #
    #     client.stub_responses(:head_object, [
    #       'NotFound',
    #       { content_length: 150 },
    #     ])
    #
    #     client.head_object(bucket:'aws-sdk', key:'foo')
    #     #=> raises Aws::S3::Errors::NotFound
    #
    #     resp = client.head_object(bucket:'aws-sdk', key:'foo')
    #     resp.content_length #=> 150
    #
    # @param [Symbol] operation_name
    #
    # @param [Mixed] stubs One or more responses to return from the named
    #   operation.
    #
    # @return [void]
    #
    # @raise [RuntimeError] Raises a runtime error when called
    #   on a client that has not enabled response stubbing via
    #   `:stub_responses => true`.
    #
    def stub_responses(operation_name, *stubs)
      if config.stub_responses
        apply_stubs(operation_name, stubs.flatten)
      else
        msg = 'stubbing is not enabled; enable stubbing in the constructor '
        msg << 'with `:stub_responses => true`'
        raise msg
      end
    end

    # Allows you to access all of the requests that the stubbed client has made
    #
    # @params [Boolean] exclude_presign Setting to true for filtering out not sent requests from
    #                 generating presigned urls. Default to false.
    # @return [Array] Returns an array of the api requests made, each request object contains the
    #                 :operation_name, :params, and :context of the request. 
    # @raise [NotImplementedError] Raises `NotImplementedError` when the client is not stubbed
    def api_requests(options = {})
      if config.stub_responses
        if options[:exclude_presign]
          @api_requests.reject {|req| req[:context][:presigned_url] }
        else
          @api_requests
        end
      else
        msg = 'This method is only implemented for stubbed clients, and is '
        msg << 'available when you enable stubbing in the constructor with `stub_responses: true`'
        raise NotImplementedError.new(msg)
      end
    end

    # Generates and returns stubbed response data from the named operation.
    #
    #     s3 = Aws::S3::Client.new
    #     s3.stub_data(:list_buckets)
    #     #=> #<struct Aws::S3::Types::ListBucketsOutput buckets=[], owner=#<struct Aws::S3::Types::Owner display_name="DisplayName", id="ID">>
    #
    # In addition to generating default stubs, you can provide data to
    # apply to the response stub.
    #
    #     s3.stub_data(:list_buckets, buckets:[{name:'aws-sdk'}])
    #     #=> #<struct Aws::S3::Types::ListBucketsOutput
    #       buckets=[#<struct Aws::S3::Types::Bucket name="aws-sdk", creation_date=nil>],
    #       owner=#<struct Aws::S3::Types::Owner display_name="DisplayName", id="ID">>
    #
    # @param [Symbol] operation_name
    # @param [Hash] data
    # @return [Structure] Returns a stubbed response data structure. The
    #   actual class returned will depend on the given `operation_name`.
    def stub_data(operation_name, data = {})
      Stubbing::StubData.new(config.api.operation(operation_name)).stub(data)
    end

    # @api private
    def next_stub(context)
      operation_name = context.operation_name.to_sym
      stub = @stub_mutex.synchronize do
        stubs = @stubs[operation_name] || []
        case stubs.length
        when 0 then default_stub(operation_name)
        when 1 then stubs.first
        else stubs.shift
        end
      end
      Proc === stub ? convert_stub(operation_name, stub.call(context)) : stub
    end

    private

    def default_stub(operation_name)
      stub = stub_data(operation_name)
      http_response_stub(operation_name, stub)
    end

    # This method converts the given stub data and converts it to a
    # HTTP response (when possible). This enables the response stubbing
    # plugin to provide a HTTP response that triggers all normal events
    # during response handling.
    def apply_stubs(operation_name, stubs)
      @stub_mutex.synchronize do
        @stubs[operation_name.to_sym] = stubs.map do |stub|
          convert_stub(operation_name, stub)
        end
      end
    end

    def convert_stub(operation_name, stub)
      case stub
      when Proc then stub
      when Exception, Class then { error: stub }
      when String then service_error_stub(stub)
      when Hash then http_response_stub(operation_name, stub)
      else { data: stub }
      end
    end

    def service_error_stub(error_code)
      { http: protocol_helper.stub_error(error_code) }
    end

    def http_response_stub(operation_name, data)
      if Hash === data && data.keys.sort == [:body, :headers, :status_code]
        { http: hash_to_http_resp(data) }
      else
        { http: data_to_http_resp(operation_name, data) }
      end
    end

    def hash_to_http_resp(data)
      http_resp = Seahorse::Client::Http::Response.new
      http_resp.status_code = data[:status_code]
      http_resp.headers.update(data[:headers])
      http_resp.body = data[:body]
      http_resp
    end

    def data_to_http_resp(operation_name, data)
      api = config.api
      operation = api.operation(operation_name)
      ParamValidator.new(operation.output, input: false).validate!(data)
      protocol_helper.stub_data(api, operation, data)
    end

    def protocol_helper
      case config.api.metadata['protocol']
      when 'json'        then Stubbing::Protocols::Json
      when 'query'       then Stubbing::Protocols::Query
      when 'ec2'         then Stubbing::Protocols::EC2
      when 'rest-json'   then Stubbing::Protocols::RestJson
      when 'rest-xml'    then Stubbing::Protocols::RestXml
      when 'api-gateway' then Stubbing::Protocols::ApiGateway
      else raise "unsupported protocol"
      end.new
    end
  end
end
module Aws
  module AsyncClientStubs 

    include Aws::ClientStubs

    # @api private
    def setup_stubbing
      @stubs = {}
      @stub_mutex = Mutex.new
      if Hash === @config.stub_responses
        @config.stub_responses.each do |operation_name, stubs|
          apply_stubs(operation_name, Array === stubs ? stubs : [stubs])
        end
      end

      # When a client is stubbed allow the user to access the requests made
      @api_requests = []

      # allow to access signaled events when client is stubbed
      @send_events = []

      requests = @api_requests
      send_events = @send_events

      self.handle do |context|
        if input_stream = context[:input_event_stream_handler]
          stub_stream = StubStream.new
          stub_stream.send_events = send_events
          input_stream.event_emitter.stream = stub_stream 
          input_stream.event_emitter.validate_event = context.config.validate_params
        end
        requests << {
          operation_name: context.operation_name,
          params: context.params,
          context: context
        }
        @handler.call(context)
      end
    end

    def send_events
      if config.stub_responses
        @send_events
      else
        msg = 'This method is only implemented for stubbed clients, and is '
        msg << 'available when you enable stubbing in the constructor with `stub_responses: true`'
        raise NotImplementedError.new(msg)
      end
    end

    class StubStream

      def initialize
        @state = :open
      end

      attr_accessor :send_events

      attr_reader :state

      def data(bytes, options = {})
        if options[:end_stream]
          @state = :closed
        else
          decoder = Aws::EventStream::Decoder.new
          event = decoder.decode_chunk(bytes).first
          @send_events << decoder.decode_chunk(event.payload.read).first
        end
      end

      def closed?
        @state == :closed
      end

      def close
        @state = :closed
      end
    end
  end
end
require 'set'

module Aws
  # @api private
  class EagerLoader

    def initialize
      @loaded = Set.new
    end

    # @return [Set<Module>]
    attr_reader :loaded

    # @param [Module] klass_or_module
    # @return [self]
    def load(klass_or_module)
      @loaded << klass_or_module
      klass_or_module.constants.each do |const_name|
        path = klass_or_module.autoload?(const_name)
        begin
          require(path) if path
          const = klass_or_module.const_get(const_name)
          self.load(const) if Module === const && !@loaded.include?(const)
        rescue LoadError
        end
      end
      self
    end
  end
end
require 'thread'

module Aws
  module Errors

    class NonSupportedRubyVersionError < RuntimeError; end

    # The base class for all errors returned by an Amazon Web Service.
    # All ~400 level client errors and ~500 level server errors are raised
    # as service errors.  This indicates it was an error returned from the
    # service and not one generated by the client.
    class ServiceError < RuntimeError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::Structure] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        @code = self.class.code
        @message = message if message && !message.empty?
        @context = context
        @data = data
        super(message)
      end

      # @return [String]
      attr_reader :code

      # @return [Seahorse::Client::RequestContext] The context of the request
      #   that triggered the remote service to return this error.
      attr_reader :context

      # @return [Aws::Structure]
      attr_reader :data

      class << self

        # @return [String]
        attr_accessor :code

      end
    end

    # Raised when a `streaming` operation has `requiresLength` trait
    # enabled but request payload size/length cannot be calculated
    class MissingContentLength < RuntimeError
      def initialize(*args)
        msg = 'Required `Content-Length` value missing for the request.'
        super(msg)
      end
    end

    # Rasied when endpoint discovery failed for operations
    # that requires endpoints from endpoint discovery
    class EndpointDiscoveryError < RuntimeError
      def initialize(*args)
        msg = 'Endpoint discovery failed for the operation or discovered endpoint is not working, '\
          'request will keep failing until endpoint discovery succeeds or :endpoint option is provided.'
        super(msg)
      end
    end

    # raised when hostLabel member is not provided
    # at operation input when endpoint trait is available
    # with 'hostPrefix' requirement
    class MissingEndpointHostLabelValue < RuntimeError

      def initialize(name)
        msg = "Missing required parameter #{name} to construct"\
          " endpoint host prefix. You can disable host prefix by"\
          " setting :disable_host_prefix_injection to `true`."
        super(msg)
      end

    end

    # Raised when attempting to #signal an event before
    # making an async request
    class SignalEventError < RuntimeError; end

    # Raised when EventStream Parser failed to parse
    # a raw event message
    class EventStreamParserError < RuntimeError; end

    # Raise when EventStream Builder failed to build
    # an event message with parameters provided
    class EventStreamBuilderError < RuntimeError; end

    # Error event in an event stream which has event_type :error
    # error code and error message can be retrieved when available.
    #
    # example usage:
    #
    #   client.stream_foo(name: 'bar') do |event|
    #     stream.on_error_event do |event|
    #       puts "Error #{event.error_code}: #{event.error_message}"
    #       raise event
    #     end
    #   end
    #
    class EventError < RuntimeError

      def initialize(event_type, code, message)
        @event_type = event_type
        @error_code = code
        @error_message = message
      end

      # @return [Symbol]
      attr_reader :event_type

      # @return [String]
      attr_reader :error_code

      # @return [String]
      attr_reader :error_message

    end

    # Various plugins perform client-side checksums of responses.
    # This error indicates a checksum failed.
    class ChecksumError < RuntimeError; end

    # Raised when a client is constructed and the specified shared
    # credentials profile does not exist.
    class NoSuchProfileError < RuntimeError; end

    # Raised when a client is constructed, where Assume Role credentials are
    # expected, and there is no source profile specified.
    class NoSourceProfileError < RuntimeError; end

    # Raised when a client is constructed with Assume Role credentials using
    # a credential_source, and that source type is unsupported.
    class InvalidCredentialSourceError < RuntimeError; end

    # Raised when a client is constructed with Assume Role credentials, but
    # the profile has both source_profile and credential_source.
    class CredentialSourceConflictError < RuntimeError; end

    # Raised when a client is constructed with Assume Role credentials using
    # a credential_source, and that source doesn't provide credentials.
    class NoSourceCredentialsError < RuntimeError; end

    # Raised when a client is constructed and credentials are not
    # set, or the set credentials are empty.
    class MissingCredentialsError < RuntimeError
      def initialize(*args)
        msg = 'unable to sign request without credentials set'
        super(msg)
      end
    end

    # Raised when a credentials provider process returns a JSON
    # payload with either invalid version number or malformed contents
    class InvalidProcessCredentialsPayload < RuntimeError; end

    # Raised when a client is constructed and region is not specified.
    class MissingRegionError < ArgumentError
      def initialize(*args)
        msg = "missing region; use :region option or "
        msg << "export region name to ENV['AWS_REGION']"
        super(msg)
      end
    end

    # Raised when attempting to connect to an endpoint and a `SocketError`
    # is received from the HTTP client. This error is typically the result
    # of configuring an invalid `:region`.
    class NoSuchEndpointError < RuntimeError

      def initialize(options = {})
        @context = options[:context]
        @endpoint = @context.http_request.endpoint
        @original_error = options[:original_error]
        super(<<-MSG)
Encountered a `SocketError` while attempting to connect to:

  #{endpoint.to_s}

This is typically the result of an invalid `:region` option or a
poorly formatted `:endpoint` option.

* Avoid configuring the `:endpoint` option directly. Endpoints are constructed
  from the `:region`. The `:endpoint` option is reserved for connecting to
  non-standard test endpoints.

* Not every service is available in every region.

* Never suffix region names with availability zones.
  Use "us-east-1", not "us-east-1a"

Known AWS regions include (not specific to this service):

#{possible_regions}
        MSG
      end

      attr_reader :context

      attr_reader :endpoint

      attr_reader :original_error

      private

      def possible_regions
        Aws.partitions.inject([]) do |region_names, partition|
          partition.regions.each do |region|
            region_names << region.name
          end
          region_names
        end.join("\n")
      end

    end

    # This module is mixed into another module, providing dynamic
    # error classes.  Error classes all inherit from {ServiceError}.
    #
    #     # creates and returns the class
    #     Aws::S3::Errors::MyNewErrorClass
    #
    # Since the complete list of possible AWS errors returned by services
    # is not known, this allows us to create them as needed.  This also
    # allows users to rescue errors by class without them being concrete
    # classes beforehand.
    #
    # @api private
    module DynamicErrors

      def self.extended(submodule)
        submodule.instance_variable_set("@const_set_mutex", Mutex.new)
        submodule.const_set(:ServiceError, Class.new(ServiceError))
      end

      def const_missing(constant)
        set_error_constant(constant)
      end

      # Given the name of a service and an error code, this method
      # returns an error class (that extends {ServiceError}.
      #
      #     Aws::S3::Errors.error_class('NoSuchBucket').new
      #     #=> #<Aws::S3::Errors::NoSuchBucket>
      #
      # @api private
      def error_class(error_code)
        constant = error_class_constant(error_code)
        if error_const_set?(constant)
          # modeled error class exist
          # set code attribute
          err_class = const_get(constant)
          err_class.code = constant.to_s
          err_class
        else
          set_error_constant(constant)
        end
      end

      private

      # Convert an error code to an error class name/constant.
      # This requires filtering non-safe characters from the constant
      # name and ensuring it begins with an uppercase letter.
      # @param [String] error_code
      # @return [Symbol] Returns a symbolized constant name for the given
      #   `error_code`.
      def error_class_constant(error_code)
        constant = error_code.to_s
        constant = constant.gsub(/https?:.*$/, '')
        constant = constant.gsub(/[^a-zA-Z0-9]/, '')
        constant = 'Error' + constant unless constant.match(/^[a-z]/i)
        constant = constant[0].upcase + constant[1..-1]
        constant.to_sym
      end

      def set_error_constant(constant)
        @const_set_mutex.synchronize do
          # Ensure the const was not defined while blocked by the mutex
          if error_const_set?(constant)
            const_get(constant)
          else
            error_class = Class.new(const_get(:ServiceError))
            error_class.code = constant.to_s
            const_set(constant, error_class)
          end
        end
      end

      def error_const_set?(constant)
        # Purposefully not using #const_defined? as that method returns true
        # for constants not defined directly in the current module.
        constants.include?(constant.to_sym)
      end

    end
  end
end
module Aws

  # Decorates a {Seahorse::Client::Response} with paging methods:
  #
  #     resp = s3.list_objects(params)
  #     resp.last_page?
  #     #=> false
  #
  #     # sends a request to receive the next response page
  #     resp = resp.next_page
  #     resp.last_page?
  #     #=> true
  #
  #     resp.next_page
  #     #=> raises PageableResponse::LastPageError
  #
  # You can enumerate all response pages with a block
  #
  #     ec2.describe_instances(params).each do |page|
  #       # yields once per page
  #       page.reservations.each do |r|
  #         # ...
  #       end
  #     end
  #
  # Or using {#next_page} and {#last_page?}:
  #
  #     resp.last_page?
  #     resp = resp.next_page until resp.last_page?
  #
  module PageableResponse

    def self.extended(base)
      base.send(:extend, Enumerable)
      base.send(:extend, UnsafeEnumerableMethods)
      base.instance_variable_set("@last_page", nil)
      base.instance_variable_set("@more_results", nil)
    end

    # @return [Paging::Pager]
    attr_accessor :pager

    # Returns `true` if there are no more results.  Calling {#next_page}
    # when this method returns `false` will raise an error.
    # @return [Boolean]
    def last_page?
      if @last_page.nil?
        @last_page = !@pager.truncated?(self)
      end
      @last_page
    end

    # Returns `true` if there are more results.  Calling {#next_page} will
    # return the next response.
    # @return [Boolean]
    def next_page?
      !last_page?
    end

    # @return [Seahorse::Client::Response]
    def next_page(params = {})
      if last_page?
        raise LastPageError.new(self)
      else
        next_response(params)
      end
    end

    # Yields the current and each following response to the given block.
    # @yieldparam [Response] response
    # @return [Enumerable,nil] Returns a new Enumerable if no block is given.
    def each(&block)
      return enum_for(:each_page) unless block_given?
      response = self
      yield(response)
      until response.last_page?
        response = response.next_page
        yield(response)
      end
    end
    alias each_page each

    private

    # @param [Hash] params A hash of additional request params to
    #   merge into the next page request.
    # @return [Seahorse::Client::Response] Returns the next page of
    #   results.
    def next_response(params)
      params = next_page_params(params)
      request = context.client.build_request(context.operation_name, params)
      request.send_request
    end

    # @param [Hash] params A hash of additional request params to
    #   merge into the next page request.
    # @return [Hash] Returns the hash of request parameters for the
    #   next page, merging any given params.
    def next_page_params(params)
      context[:original_params].merge(@pager.next_tokens(self).merge(params))
    end

    # Raised when calling {PageableResponse#next_page} on a pager that
    # is on the last page of results.  You can call {PageableResponse#last_page?}
    # or {PageableResponse#next_page?} to know if there are more pages.
    class LastPageError < RuntimeError

      # @param [Seahorse::Client::Response] response
      def initialize(response)
        @response = response
        super("unable to fetch next page, end of results reached")
      end

      # @return [Seahorse::Client::Response]
      attr_reader :response

    end

    # A handful of Enumerable methods, such as #count are not safe
    # to call on a pageable response, as this would trigger n api calls
    # simply to count the number of response pages, when likely what is
    # wanted is to access count on the data. Same for #to_h.
    # @api private
    module UnsafeEnumerableMethods

      def count
        if data.respond_to?(:count)
          data.count
        else
          raise NoMethodError, "undefined method `count'"
        end
      end

      def respond_to?(method_name, *args)
        if method_name == :count
          data.respond_to?(:count)
        else
          super
        end
      end

      def to_h
        data.to_h
      end

    end
  end
end

module Aws
  # @api private
  class Pager

    # @option options [required, Hash<JMESPath,JMESPath>] :tokens
    # @option options [String<JMESPath>] :limit_key
    # @option options [String<JMESPath>] :more_results
    def initialize(options)
      @tokens = options.fetch(:tokens)
      @limit_key = options.fetch(:limit_key, nil)
      @more_results = options.fetch(:more_results, nil)
    end

    # @return [Symbol, nil]
    attr_reader :limit_key

    # @param [Seahorse::Client::Response] response
    # @return [Hash]
    def next_tokens(response)
      @tokens.each.with_object({}) do |(source, target), next_tokens|
        value = JMESPath.search(source, response.data)
        next_tokens[target.to_sym] = value unless empty_value?(value)
      end
    end

    # @api private
    def prev_tokens(response)
      @tokens.each.with_object({}) do |(_, target), tokens|
        value = JMESPath.search(target, response.context.params)
        tokens[target.to_sym] = value unless empty_value?(value)
      end
    end

    # @param [Seahorse::Client::Response] response
    # @return [Boolean]
    def truncated?(response)
      if @more_results
        JMESPath.search(@more_results, response.data)
      else
        next_t = next_tokens(response)
        prev_t = prev_tokens(response)
        !(next_t.empty? || next_t == prev_t)
      end
    end

    private

    def empty_value?(value)
      value.nil? || value == '' || value == [] || value == {}
    end

    class NullPager

      # @return [nil]
      attr_reader :limit_key

      def next_tokens
        {}
      end

      def prev_tokens
        {}
      end

      def truncated?(response)
        false
      end

    end
  end
end
require 'stringio'
require 'date'
require 'time'
require 'tempfile'
require 'thread'

module Aws
  # @api private
  class ParamConverter

    include Seahorse::Model::Shapes

    @mutex = Mutex.new
    @converters = Hash.new { |h,k| h[k] = {} }

    def initialize(rules)
      @rules = rules
      @opened_files = []
    end

    # @api private
    attr_reader :opened_files

    # @param [Hash] params
    # @return [Hash]
    def convert(params)
      if @rules
        structure(@rules, params)
      else
        params
      end
    end

    def close_opened_files
      @opened_files.each(&:close)
      @opened_files = []
    end

    private

    def structure(ref, values)
      values = c(ref, values)
      if ::Struct === values || Hash === values
        values.each_pair do |k, v|
          unless v.nil?
            if ref.shape.member?(k)
              values[k] = member(ref.shape.member(k), v)
            end
          end
        end
      end
      values
    end

    def list(ref, values)
      values = c(ref, values)
      if values.is_a?(Array)
        values.map { |v| member(ref.shape.member, v) }
      else
        values
      end
    end

    def map(ref, values)
      values = c(ref, values)
      if values.is_a?(Hash)
        values.each.with_object({}) do |(key, value), hash|
          hash[member(ref.shape.key, key)] = member(ref.shape.value, value)
        end
      else
        values
      end
    end

    def member(ref, value)
      case ref.shape
      when StructureShape then structure(ref, value)
      when ListShape then list(ref, value)
      when MapShape then map(ref, value)
      else c(ref, value)
      end
    end

    def c(ref, value)
      self.class.c(ref.shape.class, value, self)
    end

    class << self

      def convert(shape, params)
        new(shape).convert(params)
      end

      # Registers a new value converter.  Converters run in the context
      # of a shape and value class.
      #
      #     # add a converter that stringifies integers
      #     shape_class = Seahorse::Model::Shapes::StringShape
      #     ParamConverter.add(shape_class, Integer) { |i| i.to_s }
      #
      # @param [Class<Model::Shapes::Shape>] shape_class
      # @param [Class] value_class
      # @param [#call] converter (nil) An object that responds to `#call`
      #    accepting a single argument.  This function should perform
      #    the value conversion if possible, returning the result.
      #    If the conversion is not possible, the original value should
      #    be returned.
      # @return [void]
      def add(shape_class, value_class, converter = nil, &block)
        @converters[shape_class][value_class] = converter || block
      end

      def ensure_open(file, converter)
        if file.closed?
          new_file = File.open(file.path, 'rb')
          converter.opened_files << new_file
          new_file
        else
          file
        end
      end

      # @api private
      def c(shape, value, instance = nil)
        if converter = converter_for(shape, value)
          converter.call(value, instance)
        else
          value
        end
      end

      private

      def converter_for(shape_class, value)
        unless @converters[shape_class].key?(value.class)
          @mutex.synchronize {
            unless @converters[shape_class].key?(value.class)
              @converters[shape_class][value.class] = find(shape_class, value)
            end
          }
        end
        @converters[shape_class][value.class]
      end

      def find(shape_class, value)
        converter = nil
        each_base_class(shape_class) do |klass|
          @converters[klass].each do |value_class, block|
            if value_class === value
              converter = block
              break
            end
          end
          break if converter
        end
        converter
      end

      def each_base_class(shape_class, &block)
        shape_class.ancestors.each do |ancestor|
          yield(ancestor) if @converters.key?(ancestor)
        end
      end

    end

    add(StructureShape, Hash) { |h| h.dup }
    add(StructureShape, ::Struct)

    add(MapShape, Hash) { |h| h.dup }
    add(MapShape, ::Struct) do |s|
      s.members.each.with_object({}) {|k,h| h[k] = s[k] }
    end

    add(ListShape, Array) { |a| a.dup }
    add(ListShape, Enumerable) { |value| value.to_a }

    add(StringShape, String)
    add(StringShape, Symbol) { |sym| sym.to_s }

    add(IntegerShape, Integer)
    add(IntegerShape, Float) { |f| f.to_i }
    add(IntegerShape, String) do |str|
      begin
        Integer(str)
      rescue ArgumentError
        str
      end
    end

    add(FloatShape, Float)
    add(FloatShape, Integer) { |i| i.to_f }
    add(FloatShape, String) do |str|
      begin
        Float(str)
      rescue ArgumentError
        str
      end
    end

    add(TimestampShape, Time)
    add(TimestampShape, Date) { |d| d.to_time }
    add(TimestampShape, DateTime) { |dt| dt.to_time }
    add(TimestampShape, Integer) { |i| Time.at(i) }
    add(TimestampShape, Float) { |f| Time.at(f) }
    add(TimestampShape, String) do |str|
      begin
        Time.parse(str)
      rescue ArgumentError
        str
      end
    end

    add(BooleanShape, TrueClass)
    add(BooleanShape, FalseClass)
    add(BooleanShape, String) do |str|
      { 'true' => true, 'false' => false }[str]
    end

    add(BlobShape, IO)
    add(BlobShape, File) { |file, converter| ensure_open(file, converter) }
    add(BlobShape, Tempfile) { |tmpfile, converter| ensure_open(tmpfile, converter) }
    add(BlobShape, StringIO)
    add(BlobShape, String)

  end
end
module Aws
  # @api private
  class ParamValidator

    include Seahorse::Model::Shapes

    EXPECTED_GOT = "expected %s to be %s, got value %s (class: %s) instead."

    # @param [Seahorse::Model::Shapes::ShapeRef] rules
    # @param [Hash] params
    # @return [void]
    def self.validate!(rules, params)
      new(rules).validate!(params)
    end

    # @param [Seahorse::Model::Shapes::ShapeRef] rules
    # @option options [Boolean] :validate_required (true)
    def initialize(rules, options = {})
      @rules = rules || begin
        shape = StructureShape.new
        shape.struct_class = EmptyStructure
        ShapeRef.new(shape: shape)
      end
      @validate_required = options[:validate_required] != false
      @input = options[:input].nil? ? true : !!options[:input]
    end

    # @param [Hash] params
    # @return [void]
    def validate!(params)
      errors = []
      structure(@rules, params, errors, 'params') if @rules
      raise ArgumentError, error_messages(errors) unless errors.empty?
    end

    private

    def structure(ref, values, errors, context)
      # ensure the value is hash like
      return unless correct_type?(ref, values, errors, context)

      if ref.eventstream
        # input eventstream is provided from event signals
        values.each do |value|
          # each event is structure type
          case value[:message_type]
          when 'event'
            val = value.dup
            val.delete(:message_type)
            structure(ref.shape.member(val[:event_type]), val, errors, context)
          when 'error' # Error is unmodeled
          when 'exception' # Pending
            raise Aws::Errors::EventStreamParserError.new(
              ':exception event validation is not supported')
          end
        end
      else
        shape = ref.shape

        # ensure required members are present
        if @validate_required
          shape.required.each do |member_name|
            input_eventstream = ref.shape.member(member_name).eventstream && @input
            if values[member_name].nil? && !input_eventstream
              param = "#{context}[#{member_name.inspect}]"
              errors << "missing required parameter #{param}"
            end
          end
        end

        # validate non-nil members
        values.each_pair do |name, value|
          unless value.nil?
            # :event_type is not modeled
            # and also needed when construct body
            next if name == :event_type
            if shape.member?(name)
              member_ref = shape.member(name)
              shape(member_ref, value, errors, context + "[#{name.inspect}]")
            else
              errors << "unexpected value at #{context}[#{name.inspect}]"
            end
          end
        end

      end
    end

    def list(ref, values, errors, context)
      # ensure the value is an array
      unless values.is_a?(Array)
        errors << expected_got(context, "an Array", values)
        return
      end

      # validate members
      member_ref = ref.shape.member
      values.each.with_index do |value, index|
        shape(member_ref, value, errors, context + "[#{index}]")
      end
    end

    def map(ref, values, errors, context)
      unless Hash === values
        errors << expected_got(context, "a hash", values)
        return
      end

      key_ref = ref.shape.key
      value_ref = ref.shape.value

      values.each do |key, value|
        shape(key_ref, key, errors, "#{context} #{key.inspect} key")
        shape(value_ref, value, errors, context + "[#{key.inspect}]")
      end
    end

    def shape(ref, value, errors, context)
      case ref.shape
      when StructureShape then structure(ref, value, errors, context)
      when ListShape then list(ref, value, errors, context)
      when MapShape then map(ref, value, errors, context)
      when StringShape
        unless value.is_a?(String)
          errors << expected_got(context, "a String", value)
        end
      when IntegerShape
        unless value.is_a?(Integer)
          errors << expected_got(context, "an Integer", value)
        end
      when FloatShape
        unless value.is_a?(Float)
          errors << expected_got(context, "a Float", value)
        end
      when TimestampShape
        unless value.is_a?(Time)
          errors << expected_got(context, "a Time object", value)
        end
      when BooleanShape
        unless [true, false].include?(value)
          errors << expected_got(context, "true or false", value)
        end
      when BlobShape
        unless io_like?(value) or value.is_a?(String)
          errors << expected_got(context, "a String or IO object", value)
        end
      else
        raise "unhandled shape type: #{ref.shape.class.name}"
      end
    end

    def correct_type?(ref, value, errors, context)
      if ref.eventstream && @input
        errors << "instead of providing value directly for eventstreams at input,"\
          " expected to use #signal events per stream"
        return false
      end
      case value
      when Hash then true
      when ref.shape.struct_class then true
      when Enumerator then ref.eventstream && value.respond_to?(:event_types)
      else
        errors << expected_got(context, "a hash", value)
        false
      end
    end

    def io_like?(value)
      value.respond_to?(:read) &&
      value.respond_to?(:rewind) &&
      value.respond_to?(:size)
    end

    def error_messages(errors)
      if errors.size == 1
        errors.first
      else
        prefix = "\n  - "
        "parameter validator found #{errors.size} errors:" +
          prefix + errors.join(prefix)
      end
    end

    def expected_got(context, expected, got)
      EXPECTED_GOT % [context, expected, got.inspect, got.class.name]
    end

  end
end
module Aws

  # @api private
  class SharedConfig

    # @return [String]
    attr_reader :credentials_path

    # @return [String]
    attr_reader :config_path

    # @return [String]
    attr_reader :profile_name

    # Constructs a new SharedConfig provider object. This will load the shared
    # credentials file, and optionally the shared configuration file, as ini
    # files which support profiles.
    #
    # By default, the shared credential file (the default path for which is
    # `~/.aws/credentials`) and the shared config file (the default path for
    # which is `~/.aws/config`) are loaded. However, if you set the
    # `ENV['AWS_SDK_CONFIG_OPT_OUT']` environment variable, only the shared
    # credential file will be loaded. You can specify the shared credential
    # file path with the `ENV['AWS_SHARED_CREDENTIALS_FILE']` environment
    # variable or with the `:credentials_path` option. Similarly, you can
    # specify the shared config file path with the `ENV['AWS_CONFIG_FILE']`
    # environment variable or with the `:config_path` option.
    #
    # The default profile name is 'default'. You can specify the profile name
    # with the `ENV['AWS_PROFILE']` environment variable or with the
    # `:profile_name` option.
    #
    # @param [Hash] options
    # @option options [String] :credentials_path Path to the shared credentials
    #   file. If not specified, will check `ENV['AWS_SHARED_CREDENTIALS_FILE']`
    #   before using the default value of "#{Dir.home}/.aws/credentials".
    # @option options [String] :config_path Path to the shared config file.
    #   If not specified, will check `ENV['AWS_CONFIG_FILE']` before using the
    #   default value of "#{Dir.home}/.aws/config".
    # @option options [String] :profile_name The credential/config profile name
    #   to use. If not specified, will check `ENV['AWS_PROFILE']` before using
    #   the fixed default value of 'default'.
    # @option options [Boolean] :config_enabled If true, loads the shared config
    #   file and enables new config values outside of the old shared credential
    #   spec.
    def initialize(options = {})
      @parsed_config = nil
      @profile_name = determine_profile(options)
      @config_enabled = options[:config_enabled]
      @credentials_path = options[:credentials_path] ||
        determine_credentials_path
      @parsed_credentials = {}
      load_credentials_file if loadable?(@credentials_path)
      if @config_enabled
        @config_path = options[:config_path] || determine_config_path
        load_config_file if loadable?(@config_path)
      end
    end

    # @api private
    def fresh(options = {})
      @profile_name = nil
      @credentials_path = nil
      @config_path = nil
      @parsed_credentials = {}
      @parsed_config = nil
      @config_enabled = options[:config_enabled] ? true : false
      @profile_name = determine_profile(options)
      @credentials_path = options[:credentials_path] ||
        determine_credentials_path
      load_credentials_file if loadable?(@credentials_path)
      if @config_enabled
        @config_path = options[:config_path] || determine_config_path
        load_config_file if loadable?(@config_path)
      end
    end

    # @return [Boolean] Returns `true` if a credential file
    #   exists and has appropriate read permissions at {#path}.
    # @note This method does not indicate if the file found at {#path}
    #   will be parsable, only if it can be read.
    def loadable?(path)
      !path.nil? && File.exist?(path) && File.readable?(path)
    end

    # @return [Boolean] returns `true` if use of the shared config file is
    #   enabled.
    def config_enabled?
      @config_enabled ? true : false
    end

    # Sources static credentials from shared credential/config files.
    #
    # @param [Hash] opts
    # @option options [String] :profile the name of the configuration file from
    #   which credentials are being sourced.
    # @return [Aws::Credentials] credentials sourced from configuration values,
    #   or `nil` if no valid credentials were found.
    def credentials(opts = {})
      p = opts[:profile] || @profile_name
      validate_profile_exists(p) if credentials_present?
      if credentials = credentials_from_shared(p, opts)
        credentials
      elsif credentials = credentials_from_config(p, opts)
        credentials
      else
        nil
      end
    end

    # Attempts to assume a role from shared config or shared credentials file.
    # Will always attempt first to assume a role from the shared credentials
    # file, if present.
    def assume_role_credentials_from_config(opts = {})
      p = opts.delete(:profile) || @profile_name
      chain_config = opts.delete(:chain_config)
      credentials = assume_role_from_profile(@parsed_credentials, p, opts, chain_config)
      if @parsed_config
        credentials ||= assume_role_from_profile(@parsed_config, p, opts, chain_config)
      end
      credentials
    end

    def region(opts = {})
      p = opts[:profile] || @profile_name
      if @config_enabled
        if @parsed_credentials
          region = @parsed_credentials.fetch(p, {})["region"]
        end
        if @parsed_config
          region ||= @parsed_config.fetch(p, {})["region"]
        end
        region
      else
        nil
      end
    end

    def endpoint_discovery(opts = {})
      p = opts[:profile] || @profile_name
      if @config_enabled && @parsed_config
        @parsed_config.fetch(p, {})["endpoint_discovery_enabled"]
      end
    end

    def credentials_process(profile)
      validate_profile_exists(profile)
      @parsed_config[profile]['credential_process']
    end

    def csm_enabled(opts = {})
      p = opts[:profile] || @profile_name
      if @config_enabled
        if @parsed_credentials
          value = @parsed_credentials.fetch(p, {})["csm_enabled"]
        end
        if @parsed_config
          value ||= @parsed_config.fetch(p, {})["csm_enabled"]
        end
        value
      else
        nil
      end
    end

    def csm_client_id(opts = {})
      p = opts[:profile] || @profile_name
      if @config_enabled
        if @parsed_credentials
          value = @parsed_credentials.fetch(p, {})["csm_client_id"]
        end
        if @parsed_config
          value ||= @parsed_config.fetch(p, {})["csm_client_id"]
        end
        value
      else
        nil
      end
    end

    def csm_port(opts = {})
      p = opts[:profile] || @profile_name
      if @config_enabled
        if @parsed_credentials
          value = @parsed_credentials.fetch(p, {})["csm_port"]
        end
        if @parsed_config
          value ||= @parsed_config.fetch(p, {})["csm_port"]
        end
        value
      else
        nil
      end
    end

    private
    def credentials_present?
      (@parsed_credentials && !@parsed_credentials.empty?) ||
        (@parsed_config && !@parsed_config.empty?)
    end

    def assume_role_from_profile(cfg, profile, opts, chain_config)
      if cfg && prof_cfg = cfg[profile]
        opts[:source_profile] ||= prof_cfg["source_profile"]
        credential_source = opts.delete(:credential_source)
        credential_source ||= prof_cfg["credential_source"]
        if opts[:source_profile] && credential_source
          raise Errors::CredentialSourceConflictError.new(
            "Profile #{profile} has a source_profile, and "\
              "a credential_source. For assume role credentials, must "\
              "provide only source_profile or credential_source, not both."
          )
        elsif opts[:source_profile]
          opts[:credentials] = credentials(profile: opts[:source_profile])
          if opts[:credentials]
            opts[:role_session_name] ||= prof_cfg["role_session_name"]
            opts[:role_session_name] ||= "default_session"
            opts[:role_arn] ||= prof_cfg["role_arn"]
            opts[:external_id] ||= prof_cfg["external_id"]
            opts[:serial_number] ||= prof_cfg["mfa_serial"]
            opts[:profile] = opts.delete(:source_profile)
            AssumeRoleCredentials.new(opts)
          else
            raise Errors::NoSourceProfileError.new(
              "Profile #{profile} has a role_arn, and source_profile, but the"\
                " source_profile does not have credentials."
            )
          end
        elsif credential_source
          opts[:credentials] = credentials_from_source(
            credential_source,
            chain_config
          )
          if opts[:credentials]
            opts[:role_session_name] ||= prof_cfg["role_session_name"]
            opts[:role_session_name] ||= "default_session"
            opts[:role_arn] ||= prof_cfg["role_arn"]
            opts[:external_id] ||= prof_cfg["external_id"]
            opts[:serial_number] ||= prof_cfg["mfa_serial"]
            opts.delete(:source_profile) # Cleanup
            AssumeRoleCredentials.new(opts)
          else
            raise Errors::NoSourceCredentials.new(
              "Profile #{profile} could not get source credentials from"\
                " provider #{credential_source}"
            )
          end
        elsif prof_cfg["role_arn"]
          raise Errors::NoSourceProfileError.new(
            "Profile #{profile} has a role_arn, but no source_profile."
          )
        else
          nil
        end
      else
        nil
      end
    end

    def credentials_from_source(credential_source, config)
      case credential_source
      when "Ec2InstanceMetadata"
        InstanceProfileCredentials.new(
          retries: config ? config.instance_profile_credentials_retries : 0,
          http_open_timeout: config ? config.instance_profile_credentials_timeout : 1,
          http_read_timeout: config ? config.instance_profile_credentials_timeout : 1
        )
      when "EcsContainer"
        ECSCredentials.new
      else
        raise Errors::InvalidCredentialSourceError.new(
          "Unsupported credential_source: #{credential_source}"
        )
      end
    end

    def credentials_from_shared(profile, opts)
      if @parsed_credentials && prof_config = @parsed_credentials[profile]
        credentials_from_profile(prof_config)
      else
        nil
      end
    end

    def credentials_from_config(profile, opts)
      if @parsed_config && prof_config = @parsed_config[profile]
        credentials_from_profile(prof_config)
      else
        nil
      end
    end

    def credentials_from_profile(prof_config)
      creds = Credentials.new(
        prof_config['aws_access_key_id'],
        prof_config['aws_secret_access_key'],
        prof_config['aws_session_token']
      )
      if credentials_complete(creds)
        creds
      else
        nil
      end
    end

    def credentials_complete(creds)
      creds.set?
    end

    def load_credentials_file
      @parsed_credentials = IniParser.ini_parse(
        File.read(@credentials_path)
      )
    end

    def load_config_file
      @parsed_config = IniParser.ini_parse(File.read(@config_path))
    end

    def determine_credentials_path
      ENV['AWS_SHARED_CREDENTIALS_FILE'] || default_shared_config_path('credentials')
    end

    def determine_config_path
      ENV['AWS_CONFIG_FILE'] || default_shared_config_path('config')
    end

    def default_shared_config_path(file)
      File.join(Dir.home, '.aws', file)
    rescue ArgumentError
      # Dir.home raises ArgumentError when ENV['home'] is not set
      nil
    end

    def validate_profile_exists(profile)
      unless (@parsed_credentials && @parsed_credentials[profile]) ||
          (@parsed_config && @parsed_config[profile])
        msg = "Profile `#{profile}' not found in #{@credentials_path}"
        msg << " or #{@config_path}" if @config_path
        raise Errors::NoSuchProfileError.new(msg)
      end
    end

    def determine_profile(options)
      ret = options[:profile_name]
      ret ||= ENV["AWS_PROFILE"]
      ret ||= "default"
      ret
    end

  end
end
module Aws
  # @api private
  module Structure

    def initialize(values = {})
      values.each do |k, v|
        self[k] = v
      end
    end

    # @return [Boolean] Returns `true` if this structure has a value
    #   set for the given member.
    def key?(member_name)
      !self[member_name].nil?
    end

    # @return [Boolean] Returns `true` if all of the member values are `nil`.
    def empty?
      values.compact == []
    end

    # Deeply converts the Structure into a hash.  Structure members that
    # are `nil` are omitted from the resultant hash.
    #
    # You can call #orig_to_h to get vanilla #to_h behavior as defined
    # in stdlib Struct.
    #
    # @return [Hash]
    def to_h(obj = self)
      case obj
      when Struct
        obj.each_pair.with_object({}) do |(member, value), hash|
          hash[member] = to_hash(value) unless value.nil?
        end
      when Hash
        obj.each.with_object({}) do |(key, value), hash|
          hash[key] = to_hash(value)
        end
      when Array
        obj.collect { |value| to_hash(value) }
      else
        obj
      end
    end
    alias to_hash to_h

    # Wraps the default #to_s logic with filtering of sensitive parameters.
    def to_s(obj = self)
      Aws::Log::ParamFilter.new.filter(obj).to_s
    end

    class << self

      # @api private
      def new(*args)
        if args.empty?
          Aws::EmptyStructure
        else
          struct = Struct.new(*args)
          struct.send(:include, Aws::Structure)
          struct
        end
      end

      # @api private
      def self.included(base_class)
        base_class.send(:undef_method, :each)
      end

    end
  end

  # @api private
  class EmptyStructure < Struct.new('AwsEmptyStructure')
    include(Aws::Structure)
  end

end
module Aws
  # @api private
  class TypeBuilder

    def initialize(svc_module)
      @types_module = svc_module.const_set(:Types, Module.new)
    end

    def build_type(shape, shapes)
      @types_module.const_set(shape.name, Structure.new(*shape.member_names))
    end

  end
end
require 'cgi'

module Aws
  # @api private
  module Util
    class << self

      def deep_merge(left, right)
        case left
        when Hash then left.merge(right) { |key, v1, v2| deep_merge(v1, v2) }
        when Array then right + left
        else right
        end
      end

      def copy_hash(hash)
        if Hash === hash
          deep_copy(hash)
        else
          raise ArgumentError, "expected hash, got `#{hash.class}`"
        end
      end

      def deep_copy(obj)
        case obj
        when nil then nil
        when true then true
        when false then false
        when Hash
          obj.inject({}) do |h, (k,v)|
            h[k] = deep_copy(v)
            h
          end
        when Array
          obj.map { |v| deep_copy(v) }
        else
          if obj.respond_to?(:dup)
            obj.dup
          elsif obj.respond_to?(:clone)
            obj.clone
          else
            obj
          end
        end
      end

      def monotonic_milliseconds
        if defined?(Process::CLOCK_MONOTONIC)
          Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
        else
          DateTime.now.strftime('%Q').to_i
        end
      end

      def str_2_bool(str)
        case str.to_s
        when "true" then true
        when "false" then false
        else
          nil
        end
      end

    end
  end
end
module Aws
  module Resources
    class Collection

      extend Aws::Deprecations
      include Enumerable

      # @param [Enumerator<Array>] batches
      # @option options [Integer] :limit
      # @option options [Integer] :size
      # @api private
      def initialize(batches, options = {})
        @batches = batches
        @limit = options[:limit]
        @size = options[:size]
      end

      # @return [Integer,nil]
      #   Returns the size of this collection if known, returns `nil` when
      #   an API call is necessary to enumerate items in this collection.
      def size
        @size
      end
      alias :length :size

      # @deprecated
      # @api private
      def batches
        ::Enumerator.new do |y|
          batch_enum.each do |batch|
            y << self.class.new([batch], size: batch.size)
          end
        end
      end

      # @deprecated
      # @api private
      def [](index)
        if @size
          @batches[0][index]
        else
          raise "unable to index into a lazy loaded collection"
        end
      end
      deprecated :[]

      # @return [Enumerator<Band>]
      def each(&block)
        enum = ::Enumerator.new do |y|
          batch_enum.each do |batch|
            batch.each do |band|
              y.yield(band)
            end
          end
        end
        enum.each(&block) if block
        enum
      end

      # @param [Integer] count
      # @return [Resource, Collection]
      def first(count = nil)
        if count
          items = limit(count).to_a
          self.class.new([items], size: items.size)
        else
          begin
            each.next
          rescue StopIteration
            nil
          end
        end
      end

      # Returns a new collection that will enumerate a limited number of items.
      #
      #     collection.limit(10).each do |band|
      #       # yields at most 10 times
      #     end
      #
      # @return [Collection]
      # @param [Integer] limit
      def limit(limit)
        Collection.new(@batches, limit: limit)
      end

      private

      def batch_enum
        case @limit
        when 0 then []
        when nil then non_empty_batches
        else limited_batches
        end
      end

      def non_empty_batches
        ::Enumerator.new do |y|
          @batches.each do |batch|
            y.yield(batch) if batch.size > 0
          end
        end
      end

      def limited_batches
        ::Enumerator.new do |y|
          yielded = 0
          @batches.each do |batch|
            batch = batch.take(@limit - yielded)
            if batch.size > 0
              y.yield(batch)
              yielded += batch.size
            end
            break if yielded == @limit
          end
        end
      end

    end
  end
end
require 'pathname'

module Aws
  module Log

    # A log formatter generates a string for logging from a response. This
    # accomplished with a log pattern string:
    #
    #     pattern = ':operation :http_response_status_code :time'
    #     formatter = Aws::Log::Formatter.new(pattern)
    #     formatter.format(response)
    #     #=> 'get_bucket 200 0.0352'
    #
    # # Canned Formatters
    #
    # Instead of providing your own pattern, you can choose a canned log
    # formatter.
    #
    # * {Formatter.default}
    # * {Formatter.colored}
    # * {Formatter.short}
    #
    # # Pattern Substitutions
    #
    # You can put any of these placeholders into you pattern.
    #
    #   * `:client_class` - The name of the client class.
    #
    #   * `:operation` - The name of the client request method.
    #
    #   * `:request_params` - The user provided request parameters. Long
    #     strings are truncated/summarized if they exceed the
    #     `:max_string_size`.  Other objects are inspected.
    #
    #   * `:time` - The total time in seconds spent on the
    #     request.  This includes client side time spent building
    #     the request and parsing the response.
    #
    #   * `:retries` - The number of times a client request was retried.
    #
    #   * `:http_request_method` - The http request verb, e.g., `POST`,
    #     `PUT`, `GET`, etc.
    #
    #   * `:http_request_endpoint` - The request endpoint.  This includes
    #      the scheme, host and port, but not the path.
    #
    #   * `:http_request_scheme` - This is replaced by `http` or `https`.
    #
    #   * `:http_request_host` - The host name of the http request
    #     endpoint (e.g. 's3.amazon.com').
    #
    #   * `:http_request_port` - The port number (e.g. '443' or '80').
    #
    #   * `:http_request_headers` - The http request headers, inspected.
    #
    #   * `:http_request_body` - The http request payload.
    #
    #   * `:http_response_status_code` - The http response status
    #     code, e.g., `200`, `404`, `500`, etc.
    #
    #   * `:http_response_headers` - The http response headers, inspected.
    #
    #   * `:http_response_body` - The http response body contents.
    #
    #   * `:error_class`
    #
    #   * `:error_message`
    #
    class Formatter

      # @param [String] pattern The log format pattern should be a string
      #   and may contain substitutions.
      #
      # @option options [Integer] :max_string_size (1000) When summarizing
      #   request parameters, strings longer than this value will be
      #   truncated.
      #
      # @option options [Array<Symbol>] :filter A list of parameter
      #   names that should be filtered when logging `:request_params`.
      #
      #       Formatter.new(pattern, filter: [:password])
      #
      #   The default list of filtered parameters is documented on the
      #   {ParamFilter} class.
      #
      def initialize(pattern, options = {})
        @pattern = pattern
        @param_formatter = ParamFormatter.new(options)
        @param_filter = ParamFilter.new(options)
      end

      # @return [String]
      attr_reader :pattern

      # Given a resopnse, this will format a log message and return it as a
      #   string according to {#pattern}.
      # @param [Seahorse::Client::Response] response
      # @return [String]
      def format(response)
        pattern.gsub(/:(\w+)/) {|sym| send("_#{sym[1..-1]}", response) }
      end

      # @api private
      def method_missing(method_name, *args)
        if method_name.to_s.chars.first == '_'
          ":#{method_name.to_s[1..-1]}"
        else
          super
        end
      end

      private

      def _client_class(response)
        response.context.client.class.name
      end

      def _operation(response)
        response.context.operation_name
      end

      def _request_params(response)
        params = response.context.params
        @param_formatter.summarize(@param_filter.filter(params))
      end

      def _time(response)
        duration = response.context[:logging_completed_at] -
          response.context[:logging_started_at]
        ("%.06f" % duration).sub(/0+$/, '')
      end

      def _retries(response)
        response.context.retries
      end

      def _http_request_endpoint(response)
        response.context.http_request.endpoint.to_s
      end

      def _http_request_scheme(response)
        response.context.http_request.endpoint.scheme
      end

      def _http_request_host(response)
        response.context.http_request.endpoint.host
      end

      def _http_request_port(response)
        response.context.http_request.endpoint.port.to_s
      end

      def _http_request_method(response)
        response.context.http_request.http_method
      end

      def _http_request_headers(response)
        response.context.http_request.headers.inspect
      end

      def _http_request_body(response)
        @param_formatter.summarize(response.context.http_request.body_contents)
      end

      def _http_response_status_code(response)
        response.context.http_response.status_code.to_s
      end

      def _http_response_headers(response)
        response.context.http_response.headers.inspect
      end

      def _http_response_body(response)
        @param_formatter.summarize(response.context.http_response.body_contents)
      end

      def _error_class(response)
        response.error ? response.error.class.name : ''
      end

      def _error_message(response)
        response.error ? response.error.message : ''
      end

      class << self

        # The default log format.
        # @option (see #initialize)
        # @example A sample of the default format.
        #
        #     [ClientClass 200 0.580066 0 retries] list_objects(:bucket_name => 'bucket')
        #
        # @return [Formatter]
        def default(options = {})
          pattern = []
          pattern << "[:client_class"
          pattern << ":http_response_status_code"
          pattern << ":time"
          pattern << ":retries retries]"
          pattern << ":operation(:request_params)"
          pattern << ":error_class"
          pattern << ":error_message"
          Formatter.new(pattern.join(' ') + "\n", options)
        end

        # The short log format.  Similar to default, but it does not
        # inspect the request params or report on retries.
        # @option (see #initialize)
        # @example A sample of the short format
        #
        #     [ClientClass 200 0.494532] list_buckets
        #
        # @return [Formatter]
        def short(options = {})
          pattern = []
          pattern << "[:client_class"
          pattern << ":http_response_status_code"
          pattern << ":time]"
          pattern << ":operation"
          pattern << ":error_class"
          Formatter.new(pattern.join(' ') + "\n", options)
        end

        # The default log format with ANSI colors.
        # @option (see #initialize)
        # @example A sample of the colored format (sans the ansi colors).
        #
        #     [ClientClass 200 0.580066 0 retries] list_objects(:bucket_name => 'bucket')
        #
        # @return [Formatter]
        def colored(options = {})
          bold = "\x1b[1m"
          color = "\x1b[34m"
          reset = "\x1b[0m"
          pattern = []
          pattern << "#{bold}#{color}[:client_class"
          pattern << ":http_response_status_code"
          pattern << ":time"
          pattern << ":retries retries]#{reset}#{bold}"
          pattern << ":operation(:request_params)"
          pattern << ":error_class"
          pattern << ":error_message#{reset}"
          Formatter.new(pattern.join(' ') + "\n", options)
        end

      end
    end
  end
end
require 'pathname'
require 'set'

module Aws
  module Log
    class ParamFilter

      # A managed list of sensitive parameters that should be filtered from
      # logs. This is updated automatically as part of each release. See the
      # `tasks/sensitive.rake` for more information.
      #
      # @api private
      # begin
      SENSITIVE = [:access_token, :account_name, :account_password, :address, :admin_contact, :admin_password, :artifact_credentials, :auth_code, :authentication_token, :authorization_result, :backup_plan_tags, :backup_vault_tags, :base_32_string_seed, :body, :bot_configuration, :bot_email, :cause, :client_id, :client_secret, :configuration, :copy_source_sse_customer_key, :credentials, :current_password, :custom_attributes, :db_password, :default_phone_number, :definition, :description, :display_name, :e164_phone_number, :email, :email_address, :email_message, :embed_url, :error, :feedback_token, :file, :first_name, :id, :id_token, :input, :input_text, :key_id, :key_store_password, :kms_key_id, :kms_master_key_id, :lambda_function_arn, :last_name, :local_console_password, :master_account_email, :master_user_password, :message, :name, :new_password, :next_password, :notes, :old_password, :outbound_events_https_endpoint, :output, :owner_information, :parameters, :passphrase, :password, :payload, :phone_number, :plaintext, :previous_password, :primary_email, :primary_provisioned_number, :private_key, :proposed_password, :public_key, :qr_code_png, :query, :recovery_point_tags, :refresh_token, :registrant_contact, :request_attributes, :search_query, :secret_access_key, :secret_binary, :secret_code, :secret_hash, :secret_string, :security_token, :service_password, :session_attributes, :share_notes, :shared_secret, :slots, :sse_customer_key, :ssekms_key_id, :status_message, :tag_key_list, :tags, :task_parameters, :tech_contact, :temporary_password, :text, :token, :trust_password, :upload_credentials, :upload_url, :user_email, :user_name, :username, :value, :values, :variables, :zip_file]
      # end

      def initialize(options = {})
        @filters = Set.new(SENSITIVE + Array(options[:filter]))
      end

      def filter(value)
        case value
        when Struct, Hash then filter_hash(value)
        when Array then filter_array(value)
        else value
        end
      end

      private

      def filter_hash(values)
        filtered = {}
        values.each_pair do |key, value|
          filtered[key] = @filters.include?(key) ? '[FILTERED]' : filter(value)
        end
        filtered
      end

      def filter_array(values)
        values.map { |value| filter(value) }
      end

    end
  end
end
require 'pathname'

module Aws
  module Log
    # @api private
    class ParamFormatter

      # String longer than the max string size are truncated
      MAX_STRING_SIZE = 1000

      def initialize(options = {})
        @max_string_size = options[:max_string_size] || MAX_STRING_SIZE
      end

      def summarize(value)
        Hash === value ? summarize_hash(value) : summarize_value(value)
      end

      private

      def summarize_hash(hash)
        hash.keys.first.is_a?(String) ?
          summarize_string_hash(hash) :
          summarize_symbol_hash(hash)
      end

      def summarize_symbol_hash(hash)
        hash.map do |key,v|
          "#{key}:#{summarize_value(v)}"
        end.join(",")
      end

      def summarize_string_hash(hash)
        hash.map do |key,v|
          "#{key.inspect}=>#{summarize_value(v)}"
        end.join(",")
      end

      def summarize_string(str)
        if str.size > @max_string_size
          "#<String #{str[0...@max_string_size].inspect} ... (#{str.size} bytes)>"
        else
          str.inspect
        end
      end

      def summarize_value(value)
        case value
        when String   then summarize_string(value)
        when Hash     then '{' + summarize_hash(value) + '}'
        when Array    then summarize_array(value)
        when File     then summarize_file(value.path)
        when Pathname then summarize_file(value)
        else value.inspect
        end
      end

      def summarize_file(path)
        "#<File:#{path} (#{File.size(path)} bytes)>"
      end

      def summarize_array(array)
        "[" + array.map{|v| summarize_value(v) }.join(",") + "]"
      end

    end
  end
end
module Aws
  module Stubbing
    class EmptyStub

      include Seahorse::Model::Shapes

      # @param [Seahorse::Models::Shapes::ShapeRef] rules
      def initialize(rules)
        @rules = rules
      end

      # @return [Structure]
      def stub
        if @rules
          stub_ref(@rules)
        else
          EmptyStructure.new
        end
      end

      private

      def stub_ref(ref, visited = [])
        if visited.include?(ref.shape)
          return nil
        else
          visited = visited + [ref.shape]
        end
        case ref.shape
        when StructureShape then stub_structure(ref, visited)
        when ListShape then []
        when MapShape then {}
        else stub_scalar(ref)
        end
      end

      def stub_structure(ref, visited)
        ref.shape.members.inject(ref.shape.struct_class.new) do |struct, (mname, mref)|
          # For eventstream shape, it returns an Enumerator
          unless mref.eventstream
            struct[mname] = stub_ref(mref, visited)
          end
          struct
        end
      end

      def stub_scalar(ref)
        case ref.shape
        when StringShape then ref.shape.name || 'string'
        when IntegerShape then 0
        when FloatShape then 0.0
        when BooleanShape then false
        when TimestampShape then Time.now
        else nil
        end
      end

    end
  end
end
module Aws
  module Stubbing
    class DataApplicator

      include Seahorse::Model::Shapes

      # @param [Seahorse::Models::Shapes::ShapeRef] rules
      def initialize(rules)
        @rules = rules
      end

      # @param [Hash] data
      # @param [Structure] stub
      def apply_data(data, stub)
        apply_data_to_struct(@rules, data, stub)
      end

      private

      def apply_data_to_struct(ref, data, struct)
        data.each do |key, value|
          struct[key] = member_value(ref.shape.member(key), value)
        end
        struct
      end

      def member_value(ref, value)
        case ref.shape
        when StructureShape
          apply_data_to_struct(ref, value, ref.shape.struct_class.new)
        when ListShape
          value.inject([]) do |list, v|
            list << member_value(ref.shape.member, v)
          end
        when MapShape
          value.inject({}) do |map, (k,v)|
            map[k.to_s] = member_value(ref.shape.value, v)
            map
          end
        else
          value
        end
      end
    end
  end
end
module Aws
  # @api private
  module Stubbing
    class StubData

      def initialize(operation)
        @rules = operation.output
        @pager = operation[:pager]
      end

      def stub(data = {})
        stub = EmptyStub.new(@rules).stub
        remove_paging_tokens(stub)
        apply_data(data, stub)
        stub
      end

      private

      def remove_paging_tokens(stub)
        if @pager
          @pager.instance_variable_get("@tokens").keys.each do |path|
            if divide = (path[' || '] || path[' or '])
              path = path.split(divide)[0]
            end
            parts = path.split(/\b/)
            # if nested struct/expression, EmptyStub auto-pop "string"
            # currently not support remove "string" for nested/expression
            # as it requires reverse JMESPATH search
            stub[parts[0]] = nil if parts.size == 1
          end
          if more_results = @pager.instance_variable_get('@more_results')
            parts = more_results.split(/\b/)
            # if nested struct/expression, EmptyStub auto-pop false value
            # no further work needed
            stub[parts[0]] = false if parts.size == 1
          end
        end
      end

      def apply_data(data, stub)
        ParamValidator.new(@rules, validate_required: false, input: false).validate!(data)
        DataApplicator.new(@rules).apply_data(data, stub)
      end
    end
  end
end
module Aws
  module Stubbing
    class XmlError

      def initialize(error_code)
        @error_code = error_code
      end

      def to_xml
        <<-XML.strip
<ErrorResponse>
  <Error>
    <Code>#{@error_code}</Code>
    <Message>stubbed-response-error-message</Message>
  </Error>
</ErrorResponse>
        XML
      end

    end
  end
end
module Aws
  module Stubbing
    module Protocols
      class EC2

        def stub_data(api, operation, data)
          resp = Seahorse::Client::Http::Response.new
          resp.status_code = 200
          resp.body = build_body(api, operation, data) if operation.output
          resp.headers['Content-Length'] = resp.body.size
          resp.headers['Content-Type'] = 'text/xml;charset=UTF-8'
          resp.headers['Server'] = 'AmazonEC2'
          resp
        end

        def stub_error(error_code)
          http_resp = Seahorse::Client::Http::Response.new
          http_resp.status_code = 400
          http_resp.body = <<-XML.strip
<ErrorResponse>
  <Error>
    <Code>#{error_code}</Code>
    <Message>stubbed-response-error-message</Message>
  </Error>
</ErrorResponse>
          XML
          http_resp
        end

        private

        def build_body(api, operation, data)
          xml = []
          Xml::Builder.new(operation.output, target:xml).to_xml(data)
          xml.shift
          xml.pop
          xmlns = "http://ec2.amazonaws.com/doc/#{api.version}/".inspect
          xml.unshift("  <requestId>stubbed-request-id</requestId>")
          xml.unshift("<#{operation.name}Response xmlns=#{xmlns}>\n")
          xml.push("</#{operation.name}Response>\n")
          xml.join
        end

      end
    end
  end
end
module Aws
  module Stubbing
    module Protocols
      class Json

        def stub_data(api, operation, data)
          resp = Seahorse::Client::Http::Response.new
          resp.status_code = 200
          resp.headers["Content-Type"] = content_type(api)
          resp.headers["x-amzn-RequestId"] = "stubbed-request-id"
          resp.body = build_body(operation, data)
          resp
        end

        def stub_error(error_code)
          http_resp = Seahorse::Client::Http::Response.new
          http_resp.status_code = 400
          http_resp.body = <<-JSON.strip
{
  "code": #{error_code.inspect},
  "message": "stubbed-response-error-message"
}
          JSON
          http_resp
        end

        private

        def content_type(api)
          "application/x-amz-json-#{api.metadata['jsonVerison']}"
        end

        def build_body(operation, data)
          Aws::Json::Builder.new(operation.output).to_json(data)
        end

      end
    end
  end
end
module Aws
  module Stubbing
    module Protocols
      class Query

        def stub_data(api, operation, data)
          resp = Seahorse::Client::Http::Response.new
          resp.status_code = 200
          resp.body = build_body(api, operation, data)
          resp
        end

        def stub_error(error_code)
          http_resp = Seahorse::Client::Http::Response.new
          http_resp.status_code = 400
          http_resp.body = XmlError.new(error_code).to_xml
          http_resp
        end

        private

        def build_body(api, operation, data)
          xml = []
          builder = Aws::Xml::DocBuilder.new(target: xml, indent: '  ')
          builder.node(operation.name + 'Response', xmlns: xmlns(api)) do
            if rules = operation.output
              rules.location_name = operation.name + 'Result'
              Xml::Builder.new(rules, target:xml, pad:'  ').to_xml(data)
            end
            builder.node('ResponseMetadata') do
              builder.node('RequestId', 'stubbed-request-id')
            end
          end
          xml.join
        end

        def xmlns(api)
          api.metadata['xmlNamespace']
        end

      end
    end
  end
end

module Aws
  module Stubbing
    module Protocols
      class Rest

        include Seahorse::Model::Shapes

        def stub_data(api, operation, data)
          resp = new_http_response
          apply_status_code(operation, resp, data)
          apply_headers(operation, resp, data)
          apply_body(api, operation, resp, data)
          resp
        end

        private

        def new_http_response
          resp = Seahorse::Client::Http::Response.new
          resp.status_code = 200
          resp.headers["x-amzn-RequestId"] = "stubbed-request-id"
          resp
        end

        def apply_status_code(operation, resp, data)
          operation.output.shape.members.each do |member_name, member_ref|
            if member_ref.location == 'statusCode'
              resp.status_code = data[member_name] if data.key?(member_name)
            end
          end
        end

        def apply_headers(operation, resp, data)
          Aws::Rest::Request::Headers.new(operation.output).apply(resp, data)
        end

        def apply_body(api, operation, resp, data)
          resp.body = build_body(api, operation, data)
        end

        def build_body(api, operation, data)
          rules = operation.output
          if head_operation(operation)
            ""
          elsif streaming?(rules)
            data[rules[:payload]]
          elsif rules[:payload]
            body_for(api, operation, rules[:payload_member], data[rules[:payload]])
          else
            filtered = Seahorse::Model::Shapes::ShapeRef.new(
              shape: Seahorse::Model::Shapes::StructureShape.new.tap do |s|
                rules.shape.members.each do |member_name, member_ref|
                  s.add_member(member_name, member_ref) if member_ref.location.nil?
                end
              end
            )
            body_for(api, operation, filtered, data)
          end
        end

        def streaming?(ref)
          if ref[:payload]
            case ref[:payload_member].shape
            when StringShape then true
            when BlobShape then true
            else false
            end
          else
            false
          end
        end

        def head_operation(operation)
          operation.http_method == "HEAD"
        end

        def eventstream?(rules)
          rules.eventstream
        end

        def encode_eventstream_response(rules, data, builder)
          data.inject('') do |stream, event_data|
            # construct message headers and payload
            opts = {headers: {}}
            case event_data.delete(:message_type)
            when 'event'
              encode_event(opts, rules, event_data, builder)
            when 'error'
              # errors are unmodeled
              encode_error(opts, event_data)
            when 'exception'
              # Pending
              raise 'Stubbing :exception event is not supported'
            end
            stream << Aws::EventStream::Encoder.new.encode(
              Aws::EventStream::Message.new(opts))
            stream
          end
        end

        def encode_error(opts, event_data)
          opts[:headers][':error-message'] = Aws::EventStream::HeaderValue.new(
            value: event_data[:error_message],
            type: 'string'
          )
          opts[:headers][':error-code'] = Aws::EventStream::HeaderValue.new(
            value: event_data[:error_code],
            type: 'string'
          )
          opts[:headers][':message-type'] = Aws::EventStream::HeaderValue.new(
            value: 'error',
            type: 'string'
          )
          opts
        end

        def encode_event(opts, rules, event_data, builder)
          event_ref = rules.shape.member(event_data.delete(:event_type))
          explicit_payload = false
          implicit_payload_members = {}
          event_ref.shape.members.each do |name, ref|
            if ref.eventpayload
              explicit_payload = true
            else
              implicit_payload_members[name] = ref
            end
          end

          if !explicit_payload && !implicit_payload_members.empty?
            unless implicit_payload_members.size > 1
              m_name, _ = implicit_payload_members.first
              value = {}
              value[m_name] = event_data[m_name]
              opts[:payload] = StringIO.new(builder.new(event_ref).serialize(value))
            end
          end

          event_data.each do |k, v|
            member_ref = event_ref.shape.member(k)
            if member_ref.eventheader
              opts[:headers][member_ref.location_name] = Aws::EventStream::HeaderValue.new(
                value: v,
                type: member_ref.eventheader_type
              )
            elsif member_ref.eventpayload
              case member_ref.eventpayload_type
              when 'string'
                opts[:payload] = StringIO.new(v)
              when 'blob'
                opts[:payload] = v
              when 'structure'
                opts[:payload] = StringIO.new(builder.new(member_ref).serialize(v))
              end
            end
          end
          opts[:headers][':event-type'] = Aws::EventStream::HeaderValue.new(
            value: event_ref.location_name,
            type: 'string'
          )
          opts[:headers][':message-type'] = Aws::EventStream::HeaderValue.new(
            value: 'event',
            type: 'string'
          )
          opts
        end

      end
    end
  end
end
module Aws
  module Stubbing
    module Protocols
      class RestJson < Rest

        def body_for(_, _, rules, data)
          if eventstream?(rules)
            encode_eventstream_response(rules, data, Aws::Json::Builder)
          else
            Aws::Json::Builder.new(rules).serialize(data)
          end
        end

        def stub_error(error_code)
          http_resp = Seahorse::Client::Http::Response.new
          http_resp.status_code = 400
          http_resp.body = <<-JSON.strip
{
  "code": #{error_code.inspect},
  "message": "stubbed-response-error-message"
}
          JSON
          http_resp
        end

      end
    end
  end
end
module Aws
  module Stubbing
    module Protocols
      class RestXml < Rest

        include Seahorse::Model::Shapes

        def body_for(api, operation, rules, data)
          if eventstream?(rules)
            encode_eventstream_response(rules, data, Xml::Builder)
          else
            xml = []
            rules.location_name = operation.name + 'Result'
            rules['xmlNamespace'] = { 'uri' => api.metadata['xmlNamespace'] }
            Xml::Builder.new(rules, target:xml).to_xml(data)
            xml.join
          end
        end

        def stub_error(error_code)
          http_resp = Seahorse::Client::Http::Response.new
          http_resp.status_code = 400
          http_resp.body = XmlError.new(error_code).to_xml
          http_resp
        end

        def xmlns(api)
          api.metadata['xmlNamespace']
        end

      end
    end
  end
end
module Aws
  module Stubbing
    module Protocols
      class ApiGateway < RestJson
      end
    end
  end
end
module Aws
  # @api private
  module Rest
    class Handler < Seahorse::Client::Handler

      def call(context)
        Rest::Request::Builder.new.apply(context)
        resp = @handler.call(context)
        resp.on(200..299) { |response| Response::Parser.new.apply(response) }
        resp.on(200..599) { |response| apply_request_id(context) }
        resp
      end

      private

      def apply_request_id(context)
        h = context.http_response.headers
        context[:request_id] = h['x-amz-request-id'] || h['x-amzn-requestid']
      end

    end
  end
end
module Aws
  module Rest
    module Request
      class Body

        include Seahorse::Model::Shapes

        # @param [Class] serializer_class
        # @param [Seahorse::Model::ShapeRef] rules
        def initialize(serializer_class, rules)
          @serializer_class = serializer_class
          @rules = rules
        end

        # @param [Seahorse::Client::Http::Request] http_req
        # @param [Hash] params
        def apply(http_req, params)
          http_req.body = build_body(params)
        end

        private

        def build_body(params)
          if streaming?
            params[@rules[:payload]]
          elsif @rules[:payload]
            params = params[@rules[:payload]]
            serialize(@rules[:payload_member], params) if params
          else
            params = body_params(params)
            serialize(@rules, params) unless params.empty?
          end
        end

        def streaming?
          @rules[:payload] && (
            BlobShape === @rules[:payload_member].shape ||
            StringShape === @rules[:payload_member].shape
          )
        end

        def serialize(rules, params)
          @serializer_class.new(rules).serialize(params)
        end

        def body_params(params)
          @rules.shape.members.inject({}) do |hash, (member_name, member_ref)|
            if !member_ref.location && params.key?(member_name)
              hash[member_name] = params[member_name]
            end
            hash
          end
        end

      end
    end
  end
end
module Aws
  module Rest
    module Request
      class Builder

        def apply(context)
          populate_http_method(context)
          populate_endpoint(context)
          populate_headers(context)
          populate_body(context)
        end

        private

        def populate_http_method(context)
          context.http_request.http_method = context.operation.http_method
        end

        def populate_endpoint(context)
          context.http_request.endpoint = Endpoint.new(
            context.operation.input,
            context.operation.http_request_uri,
          ).uri(context.http_request.endpoint, context.params)
        end

        def populate_headers(context)
          headers = Headers.new(context.operation.input)
          headers.apply(context.http_request, context.params)
        end

        def populate_body(context)
          Body.new(
            serializer_class(context),
            context.operation.input
          ).apply(context.http_request, context.params)
        end

        def serializer_class(context)
          protocol = context.config.api.metadata['protocol']
          case protocol
          when 'rest-xml' then Xml::Builder
          when 'rest-json' then Json::Builder
          when 'api-gateway' then Json::Builder
          else raise "unsupported protocol #{protocol}"
          end
        end

      end
    end
  end
end
require 'uri'

module Aws
  module Rest
    module Request
      class Endpoint

        # @param [Seahorse::Model::Shapes::ShapeRef] rules
        # @param [String] request_uri_pattern
        def initialize(rules, request_uri_pattern)
          @rules = rules
          request_uri_pattern.split('?').tap do |path_part, query_part|
            @path_pattern = path_part
            @query_prefix = query_part
          end
        end

        # @param [URI::HTTPS,URI::HTTP] base_uri
        # @param [Hash,Struct] params
        # @return [URI::HTTPS,URI::HTTP]
        def uri(base_uri, params)
          uri = URI.parse(base_uri.to_s)
          apply_path_params(uri, params)
          apply_querystring_params(uri, params)
          uri
        end

        private

        def apply_path_params(uri, params)
          path = uri.path.sub(/\/$/, '') + @path_pattern.split('?')[0]
          uri.path = path.gsub(/{.+?}/) do |placeholder|
            param_value_for_placeholder(placeholder, params)
          end
        end

        def param_value_for_placeholder(placeholder, params)
          value = params[param_name(placeholder)].to_s
          placeholder.include?('+') ?
            value.gsub(/[^\/]+/) { |v| escape(v) } :
            escape(value)
        end

        def param_name(placeholder)
          location_name = placeholder.gsub(/[{}+]/,'')
          param_name, _ = @rules.shape.member_by_location_name(location_name)
          param_name
        end

        def apply_querystring_params(uri, params)
          # collect params that are supposed to be part of the query string
          parts = @rules.shape.members.inject([]) do |prts, (member_name, member_ref)|
            if member_ref.location == 'querystring' && !params[member_name].nil?
              prts << [member_ref, params[member_name]]
            end
            prts
          end
          querystring = QuerystringBuilder.new.build(parts)
          querystring = [@query_prefix, querystring == '' ? nil : querystring].compact.join('&')
          querystring = nil if querystring == ''
          uri.query = querystring
        end

        def escape(string)
          Seahorse::Util.uri_escape(string)
        end

      end
    end
  end
end
require 'time'
require 'base64'

module Aws
  module Rest
    module Request
      class Headers

        include Seahorse::Model::Shapes

        # @param [Seahorse::Model::ShapeRef] rules
        def initialize(rules)
          @rules = rules
        end

        # @param [Seahorse::Client::Http::Request] http_req
        # @param [Hash] params
        def apply(http_req, params)
          @rules.shape.members.each do |name, ref|
            value = params[name]
            next if value.nil?
            case ref.location
            when 'header' then apply_header_value(http_req.headers, ref, value)
            when 'headers' then apply_header_map(http_req.headers, ref, value)
            end
          end
        end

        private

        def apply_header_value(headers, ref, value)
          value = apply_json_trait(value) if ref['jsonvalue']
          headers[ref.location_name] =
            case ref.shape
            when TimestampShape then timestamp(ref, value)
            else value.to_s
            end
        end

        def timestamp(ref, value)
          case ref['timestampFormat'] || ref.shape['timestampFormat']
          when 'unixTimestamp' then value.to_i
          when 'iso8601' then value.utc.iso8601
          else
            # header default to rfc822
            value.utc.httpdate
          end
        end

        def apply_header_map(headers, ref, values)
          prefix = ref.location_name || ''
          values.each_pair do |name, value|
            headers["#{prefix}#{name}"] = value.to_s
          end
        end

        # With complex headers value in json syntax,
        # base64 encodes value to aviod weird characters
        # causing potential issues in headers
        def apply_json_trait(value)
          Base64.strict_encode64(value)
        end

      end
    end
  end
end
module Aws
  module Rest
    module Request
      class QuerystringBuilder

        include Seahorse::Model::Shapes

        # Provide shape references and param values:
        #
        #     [
        #       [shape_ref1, 123],
        #       [shape_ref2, "text"]
        #     ]
        #
        # Returns a querystring:
        #
        #   "Count=123&Words=text"
        #
        # @param [Array<Array<Seahorse::Model::ShapeRef, Object>>] params An array of
        #   model shape references and request parameter value pairs.
        #
        # @return [String] Returns a built querystring
        def build(params)
          params.map do |(shape_ref, param_value)|
            build_part(shape_ref, param_value)
          end.join('&')
        end

        private

        def build_part(shape_ref, param_value)
          case shape_ref.shape
          # supported scalar types
          when StringShape, BooleanShape, FloatShape, IntegerShape, StringShape
            param_name = shape_ref.location_name
            "#{param_name}=#{escape(param_value.to_s)}"
          when TimestampShape
            param_name = shape_ref.location_name
            "#{param_name}=#{escape(timestamp(shape_ref, param_value))}"
          when MapShape
            if StringShape === shape_ref.shape.value.shape
              query_map_of_string(param_value)
            elsif ListShape === shape_ref.shape.value.shape
              query_map_of_string_list(param_value)
            else
              msg = "only map of string and string list supported"
              raise NotImplementedError, msg
            end
          when ListShape
            if StringShape === shape_ref.shape.member.shape
              list_of_strings(shape_ref.location_name, param_value)
            else
              msg = "Only list of strings supported, got "
              msg << shape_ref.shape.member.shape.class.name
              raise NotImplementedError, msg
            end
          else
            raise NotImplementedError
          end
        end

        def timestamp(ref, value)
          case ref['timestampFormat'] || ref.shape['timestampFormat']
          when 'unixTimestamp' then value.to_i
          when 'rfc822' then value.utc.httpdate
          else
            # querystring defaults to iso8601
            value.utc.iso8601
          end
        end

        def query_map_of_string(hash)
          list = []
          hash.each_pair do |key, value|
            list << "#{escape(key)}=#{escape(value)}"
          end
          list
        end

        def query_map_of_string_list(hash)
          list = []
          hash.each_pair do |key, values|
            values.each do |value|
              list << "#{escape(key)}=#{escape(value)}"
            end
          end
          list
        end

        def list_of_strings(name, values)
          values.map do |value|
            "#{name}=#{escape(value)}"
          end
        end

        def escape(string)
          Seahorse::Util.uri_escape(string)
        end

      end
    end
  end
end
module Aws
  module Rest
    module Response
      class Body

        include Seahorse::Model::Shapes

        # @param [Class] parser_class
        # @param [Seahorse::Model::ShapeRef] rules
        def initialize(parser_class, rules)
          @parser_class = parser_class
          @rules = rules
        end

        # @param [IO] body
        # @param [Hash, Struct] data
        def apply(body, data)
          if event_stream?
            data[@rules[:payload]] = parse_eventstream(body)
          elsif streaming?
            data[@rules[:payload]] = body
          elsif @rules[:payload]
            data[@rules[:payload]] = parse(body.read, @rules[:payload_member])
          elsif !@rules.shape.member_names.empty?
            parse(body.read, @rules, data)
          end
        end

        private

        def event_stream?
          @rules[:payload] && @rules[:payload_member].eventstream
        end

        def streaming?
          @rules[:payload] && (
            BlobShape === @rules[:payload_member].shape ||
            StringShape === @rules[:payload_member].shape
          )
        end

        def parse(body, rules, target = nil)
          @parser_class.new(rules).parse(body, target) if body.size > 0
        end

        def parse_eventstream(body)
          # body contains an array of parsed event when they arrive
          @rules[:payload_member].shape.struct_class.new do |payload|
            body.each { |event| payload << event }
          end
        end

      end
    end
  end
end
require 'time'
require 'base64'

module Aws
  module Rest
    module Response
      class Headers

        include Seahorse::Model::Shapes

        # @param [Seahorse::Model::ShapeRef] rules
        def initialize(rules)
          @rules = rules
        end

        # @param [Seahorse::Client::Http::Response] http_resp
        # @param [Hash, Struct] target
        def apply(http_resp, target)
          headers = http_resp.headers
          @rules.shape.members.each do |name, ref|
            case ref.location
            when 'header' then extract_header_value(headers, name, ref, target)
            when 'headers' then extract_header_map(headers, name, ref, target)
            end
          end
        end

        def extract_header_value(headers, name, ref, data)
          if headers.key?(ref.location_name)
            data[name] = cast_value(ref, headers[ref.location_name])
          end
        end

        def cast_value(ref, value)
          value = extract_json_trait(value) if ref['jsonvalue']
          case ref.shape
          when StringShape then value
          when IntegerShape then value.to_i
          when FloatShape then value.to_f
          when BooleanShape then value == 'true'
          when TimestampShape
            if value =~ /\d+(\.\d*)/
              Time.at(value.to_f)
            elsif value =~ /^\d+$/
              Time.at(value.to_i)
            else
              begin
                Time.parse(value)
              rescue
                nil
              end
            end
          else raise "unsupported shape #{ref.shape.class}"
          end
        end

        def extract_header_map(headers, name, ref, data)
          data[name] = {}
          prefix = ref.location_name || ''
          headers.each do |header_name, header_value|
            if match = header_name.match(/^#{prefix}(.+)/i)
              data[name][match[1]] = header_value
            end
          end
        end

        def extract_json_trait(value)
          JSON.parse(Base64.decode64(value))
        end

      end
    end
  end
end
module Aws
  module Rest
    module Response
      class Parser

        def apply(response)
          # TODO : remove this unless check once response stubbing is fixed
          if rules = response.context.operation.output
            response.data = rules.shape.struct_class.new
            extract_status_code(rules, response)
            extract_headers(rules, response)
            extract_body(rules, response)
          else
            response.data = EmptyStructure.new
          end
        end

        private

        def extract_status_code(rules, response)
          status_code = StatusCode.new(rules)
          status_code.apply(response.context.http_response, response.data)
        end

        def extract_headers(rules, response)
          headers = Headers.new(rules)
          headers.apply(response.context.http_response, response.data)
        end

        def extract_body(rules, response)
          Body.new(parser_class(response), rules).
            apply(
              response.context.http_response.body,
              response.data
            )
        end

        def parser_class(response)
          protocol = response.context.config.api.metadata['protocol']
          case protocol
          when 'rest-xml' then Xml::Parser
          when 'rest-json' then Json::Parser
          when 'api-gateway' then Json::Parser
          else raise "unsupported protocol #{protocol}"
          end
        end

      end
    end
  end
end
module Aws
  module Rest
    module Response
      class StatusCode

        # @param [Seahorse::Model::Shapes::ShapeRef] rules
        def initialize(rules)
          @rules = rules
        end

        # @param [Seahorse::Client::Http::Response] http_resp
        # @param [Hash, Struct] data
        def apply(http_resp, data)
          @rules.shape.members.each do |member_name, member_ref|
            if member_ref.location == 'statusCode'
              data[member_name] = http_resp.status_code
            end
          end
        end

      end
    end
  end
end
# KG-dev::RubyPacker replaced for rest/handler.rb
# KG-dev::RubyPacker replaced for rest/request/body.rb
# KG-dev::RubyPacker replaced for rest/request/builder.rb
# KG-dev::RubyPacker replaced for rest/request/endpoint.rb
# KG-dev::RubyPacker replaced for rest/request/headers.rb
# KG-dev::RubyPacker replaced for rest/request/querystring_builder.rb
# KG-dev::RubyPacker replaced for rest/response/body.rb
# KG-dev::RubyPacker replaced for rest/response/headers.rb
# KG-dev::RubyPacker replaced for rest/response/parser.rb
# KG-dev::RubyPacker replaced for rest/response/status_code.rb

# KG-dev::RubyPacker replaced for json.rb
# KG-dev::RubyPacker replaced for json/builder.rb
# KG-dev::RubyPacker replaced for json/error_handler.rb
# KG-dev::RubyPacker replaced for json/handler.rb
# KG-dev::RubyPacker replaced for json/parser.rb

module Aws
  # @api private
  module Json

    class ParseError < StandardError

      def initialize(error)
        @error = error
        super(error.message)
      end

      attr_reader :error

    end

    class << self

      def load(json)
        ENGINE.load(json, *ENGINE_LOAD_OPTIONS)
      rescue ENGINE_ERROR => e
        raise ParseError.new(e)
      end

      def load_file(path)
        self.load(File.open(path, 'r', encoding: 'UTF-8') { |f| f.read })
      end

      def dump(value)
        ENGINE.dump(value, *ENGINE_DUMP_OPTIONS)
      end

      private

      def oj_engine
        require 'oj'
        [Oj, [{mode: :compat, symbol_keys: false}], [{ mode: :compat }], oj_parse_error]
      rescue LoadError
        false
      end

      def json_engine
        [JSON, [], [], JSON::ParserError]
      end

      def oj_parse_error
        if Oj.const_defined?('ParseError')
          Oj::ParseError
        else
          SyntaxError
        end
      end

    end

    # @api private
    ENGINE, ENGINE_LOAD_OPTIONS, ENGINE_DUMP_OPTIONS, ENGINE_ERROR =
      oj_engine || json_engine

  end
end
module Aws
  module Binary

    # @api private
    class DecodeHandler < Seahorse::Client::Handler

      def call(context)
        if eventstream_member = eventstream?(context)
          attach_eventstream_listeners(context, eventstream_member)
        end
        @handler.call(context)
      end

      private

      def eventstream?(ctx)
        ctx.operation.output.shape.members.each do |_, ref|
          return ref if ref.eventstream
        end
      end

      def attach_eventstream_listeners(context, rules)

        context.http_response.on_headers(200) do
          protocol = context.config.api.metadata['protocol']
          output_handler = context[:output_event_stream_handler] || context[:event_stream_handler]
          context.http_response.body = EventStreamDecoder.new(
            protocol,
            rules,
            context.operation.output,
            context.operation.errors,
            context.http_response.body,
            output_handler)
          if input_emitter = context[:input_event_emitter]
            # #emit will be blocked until 200 success
            # see Aws::EventEmitter#emit
            input_emitter.signal_queue << "ready"
          end
        end

        context.http_response.on_success(200) do
          context.http_response.body = context.http_response.body.events
        end

        context.http_response.on_error do
          # Potential enhancement to made
          # since we don't want to track raw bytes in memory
          context.http_response.body = StringIO.new
        end

      end

    end

  end
end
module Aws
  module Binary

    # @api private
    class EncodeHandler < Seahorse::Client::Handler

      def call(context)
        if eventstream_member = eventstream_input?(context)
          input_es_handler = context[:input_event_stream_handler]
          input_es_handler.event_emitter.encoder = EventStreamEncoder.new(
            context.config.api.metadata['protocol'],
            eventstream_member,
            context.operation.input,
            context.config.sigv4_signer
          )
          context[:input_event_emitter] = input_es_handler.event_emitter
        end
        @handler.call(context)
      end

      private

      def eventstream_input?(ctx)
        ctx.operation.input.shape.members.each do |_, ref|
          return ref if ref.eventstream
        end
      end

    end

  end
end

module Aws
  module Binary
    # @api private
    class EventStreamDecoder

      # @param [String] protocol
      # @param [ShapeRef] rules ShapeRef of the eventstream member
      # @param [ShapeRef] output_ref ShapeRef of output shape
      # @param [Array] error_refs array of ShapeRefs for errors
      # @param [EventStream|nil] event_stream_handler A Service EventStream object
      # that registered with callbacks for processing events when they arrive
      def initialize(protocol, rules, output_ref, error_refs, io, event_stream_handler = nil)
        @decoder = Aws::EventStream::Decoder.new
        @event_parser = EventParser.new(parser_class(protocol), rules, error_refs, output_ref)
        @stream_class = extract_stream_class(rules.shape.struct_class)
        @emitter = event_stream_handler.event_emitter
        @events = []
      end

      # @return [Array] events Array of arrived event objects
      attr_reader :events

      def write(chunk)
        raw_event, eof = @decoder.decode_chunk(chunk)
        emit_event(raw_event) if raw_event
        while !eof
          # exhaust message_buffer data
          raw_event, eof = @decoder.decode_chunk
          emit_event(raw_event) if raw_event
        end
      end

      private

      def emit_event(raw_event)
        event = @event_parser.apply(raw_event)
        @events << event
        @emitter.signal(event.event_type, event) unless @emitter.nil?
      end

      def parser_class(protocol)
        case protocol
        when 'rest-xml' then Aws::Xml::Parser
        when 'rest-json' then Aws::Json::Parser
        when 'json' then Aws::Json::Parser
        else raise "unsupported protocol #{protocol} for event stream"
        end
      end

      def extract_stream_class(type_class)
        parts = type_class.to_s.split('::')
        parts.inject(Kernel) do |const, part_name|
          part_name == 'Types' ? const.const_get('EventStreams')
            : const.const_get(part_name)
        end
      end
    end

  end
end

module Aws
  module Binary
    # @api private
    class EventStreamEncoder

      # @param [String] protocol
      # @param [ShapeRef] rules ShapeRef of the eventstream member
      # @param [ShapeRef] input_ref ShapeRef of the input shape
      # @param [Aws::Sigv4::Signer] signer
      def initialize(protocol, rules, input_ref, signer)
        @encoder = Aws::EventStream::Encoder.new
        @event_builder = EventBuilder.new(serializer_class(protocol), rules)
        @input_ref = input_ref
        @rules = rules
        @signer = signer
        @prior_signature = nil
      end

      attr_reader :rules

      attr_accessor :prior_signature

      def encode(event_type, params)
        if event_type == :end_stream
          payload = ''
        else
          payload = @encoder.encode(@event_builder.apply(event_type, params))
        end
        headers, signature = @signer.sign_event(@prior_signature, payload, @encoder)
        @prior_signature = signature
        message = Aws::EventStream::Message.new(
          headers: headers,
          payload: StringIO.new(payload)
        )
        @encoder.encode(message)
      end

      private

      def serializer_class(protocol)
        case protocol
        when 'rest-xml' then Xml::Builder
        when 'rest-json' then Json::Builder
        when 'json' then Json::Builder
        else raise "unsupported protocol #{protocol} for event stream"
        end
      end

    end
  end
end
module Aws
  module Binary
    # @api private
    class EventBuilder

      include Seahorse::Model::Shapes

      # @param [Class] parser_class
      # @param [Seahorse::Model::ShapeRef] rules (of eventstream member)
      def initialize(serializer_class, rules)
        @serializer_class = serializer_class
        @rules = rules
      end

      def apply(event_type, params)
        event_ref = @rules.shape.member(event_type)
        _event_stream_message(event_ref, params)
      end

      private

      def _event_stream_message(event_ref, params)
        es_headers = {}
        payload = ""

        es_headers[":message-type"] = Aws::EventStream::HeaderValue.new(
          type: "string", value: "event")
        es_headers[":event-type"] = Aws::EventStream::HeaderValue.new(
          type: "string", value: event_ref.location_name)

        explicit_payload = false
        implicit_payload_members = {}
        event_ref.shape.members.each do |member_name, member_ref|
          unless member_ref.eventheader
            if member_ref.eventpayload
              explicit_payload = true
            else
              implicit_payload_members[member_name] = member_ref
            end
          end
        end

        # implict payload
        if !explicit_payload && !implicit_payload_members.empty?
          if implicit_payload_members.size > 1
            payload_shape = Shapes::StructureShape.new
            implicit_payload_members.each do |m_name, m_ref|
              payload_shape.add_member(m_name, m_ref)
            end
            payload_ref = Shapes::ShapeRef.new(shape: payload_shape)

            payload = build_payload_members(payload_ref, params)
          else
            m_name, m_ref = implicit_payload_members.first
            streaming, content_type = _content_type(m_ref.shape)

            es_headers[":content-type"] = Aws::EventStream::HeaderValue.new(
              type: "string", value: content_type)
            payload = _build_payload(streaming, m_ref, params[m_name])
          end
        end
        

        event_ref.shape.members.each do |member_name, member_ref|
          if member_ref.eventheader && params[member_name]
            header_value = params[member_name]
            es_headers[member_ref.shape.name] = Aws::EventStream::HeaderValue.new(
              type: _header_value_type(member_ref.shape, header_value),
              value: header_value
            )
          elsif member_ref.eventpayload && params[member_name]
            # explicit payload 
            streaming, content_type = _content_type(member_ref.shape)

            es_headers[":content-type"] = Aws::EventStream::HeaderValue.new(
              type: "string", value: content_type)
            payload = _build_payload(streaming, member_ref, params[member_name])
          end
        end

        Aws::EventStream::Message.new(
          headers: es_headers,
          payload: StringIO.new(payload)
        )
      end

      def _content_type(shape)
        case shape
        when BlobShape then [true, "application/octet-stream"]
        when StringShape then [true, "text/plain"]
        when StructureShape then
          if @serializer_class.name.include?('Xml')
            [false, "text/xml"]
          elsif @serializer_class.name.include?('Json')
            [false, "application/json"]
          end
        else
          raise Aws::Errors::EventStreamBuilderError.new(
            "Unsupport eventpayload shape: #{shape.name}")
        end
      end
        
      def _header_value_type(shape, value)
        case shape
        when StringShape then "string"
        when IntegerShape then "integer"
        when TimestampShape then "timestamp"
        when BlobShape then "bytes"
        when BooleanShape then !!value ? "bool_true" : "bool_false"
        else 
          raise Aws::Errors::EventStreamBuilderError.new(
            "Unsupported eventheader shape: #{shape.name}") 
        end
      end

      def _build_payload(streaming, ref, value)
        streaming ? value : @serializer_class.new(ref).serialize(value)
      end

    end
  end
end
module Aws
  module Binary
    # @api private
    class EventParser

      include Seahorse::Model::Shapes

      # @param [Class] parser_class
      # @param [Seahorse::Model::ShapeRef] rules (of eventstream member)
      # @param [Array] error_refs array of errors ShapeRef
      # @param [Seahorse::Model::ShapeRef] output_ref
      def initialize(parser_class, rules, error_refs, output_ref)
        @parser_class = parser_class
        @rules = rules
        @error_refs = error_refs
        @output_ref = output_ref
      end

      # Parse raw event message into event struct
      # based on its ShapeRef
      #
      # @return [Struct] Event Struct
      def apply(raw_event)
        parse(raw_event)
      end

      private

      def parse(raw_event)
        message_type = raw_event.headers.delete(":message-type")
        if message_type
          case message_type.value
          when 'error'
            parse_error_event(raw_event)
          when 'event'
            parse_event(raw_event)
          when 'exception'
            parse_exception(raw_event)
          else
            raise Aws::Errors::EventStreamParserError.new(
              'Unrecognized :message-type value for the event')
          end
        else
          # no :message-type header, regular event by default
          parse_event(raw_event)
        end
      end

      def parse_exception(raw_event)
        exception_type = raw_event.headers.delete(":exception-type").value
        name, ref = @rules.shape.member_by_location_name(exception_type)
        # exception lives in payload implictly
        exception = parse_payload(raw_event.payload.read, ref)
        exception.event_type = name
        exception
      end

      def parse_error_event(raw_event)
        error_code = raw_event.headers.delete(":error-code")
        error_message = raw_event.headers.delete(":error-message")
        Aws::Errors::EventError.new(
          :error,
          error_code ? error_code.value : error_code,
          error_message ? error_message.value : error_message
        )
      end

      def parse_event(raw_event)
        event_type = raw_event.headers.delete(":event-type").value
        # content_type = raw_event.headers.delete(":content-type").value

        if event_type == 'initial-response'
          event = Struct.new(:event_type, :response).new
          event.event_type = :initial_response
          event.response = parse_payload(raw_event.payload.read, @output_ref)
          return event
        end

        # locate event from eventstream
        name, ref = @rules.shape.member_by_location_name(event_type)
        unless ref.event
          raise Aws::Errors::EventStreamParserError.new(
            "Failed to locate event shape for the event")
        end

        event = ref.shape.struct_class.new

        explicit_payload = false
        implicit_payload_members = {}
        ref.shape.members.each do |member_name, member_ref|
          unless member_ref.eventheader
            if member_ref.eventpayload
              explicit_payload = true
            else
              implicit_payload_members[member_name] = member_ref
            end
          end
        end

        # implicit payload
        if !explicit_payload && !implicit_payload_members.empty?
          event = parse_payload(raw_event.payload.read, ref)
        end
        event.event_type = name

        # locate payload and headers in the event
        ref.shape.members.each do |member_name, member_ref|
          if member_ref.eventheader
            # allow incomplete event members in response
            if raw_event.headers.key?(member_ref.location_name)
              event.send("#{member_name}=", raw_event.headers[member_ref.location_name].value)
            end
          elsif member_ref.eventpayload
            # explicit payload
            eventpayload_streaming?(member_ref) ?
             event.send("#{member_name}=", raw_event.payload) :
             event.send("#{member_name}=", parse_payload(raw_event.payload.read, member_ref))
          end
        end
        event
      end

      def eventpayload_streaming?(ref)
        BlobShape === ref.shape || StringShape === ref.shape
      end

      def parse_payload(body, rules)
        @parser_class.new(rules).parse(body) if body.size > 0
      end

    end

  end
end
# KG-dev::RubyPacker replaced for binary/decode_handler.rb
# KG-dev::RubyPacker replaced for binary/encode_handler.rb
# KG-dev::RubyPacker replaced for binary/event_stream_decoder.rb
# KG-dev::RubyPacker replaced for binary/event_stream_encoder.rb
# KG-dev::RubyPacker replaced for binary/event_builder.rb
# KG-dev::RubyPacker replaced for binary/event_parser.rb
module Aws
  class EventEmitter

    def initialize
      @listeners = {}
      @validate_event = true
      @status = :sleep
      @signal_queue = Queue.new
    end

    attr_accessor :stream

    attr_accessor :encoder

    attr_accessor :validate_event

    attr_accessor :signal_queue

    def on(type, callback)
      (@listeners[type] ||= []) << callback
    end

    def signal(type, event)
      return unless @listeners[type]
      @listeners[type].each do |listener|
        listener.call(event) if event.event_type == type
      end
    end

    def emit(type, params)
      unless @stream
        raise Aws::Errors::SignalEventError.new(
          "Singaling events before making async request"\
          " is not allowed."
        )
      end
      if @validate_event && type != :end_stream
        Aws::ParamValidator.validate!(
          @encoder.rules.shape.member(type), params)
      end
      _ready_for_events?
      @stream.data(
        @encoder.encode(type, params),
        end_stream: type == :end_stream
      )
    end

    private

    def _ready_for_events?
      return true if @status == :ready

      # blocked until once initial 200 response is received
      # signal will be available in @signal_queue
      # and this check will no longer be blocked
      @signal_queue.pop
      @status = :ready
      true
    end

  end
end
module Aws
  # @api private
  # a LRU cache caching endpoints data
  class EndpointCache

    # default cache entries limit
    MAX_ENTRIES = 1000

    # default max threads pool size
    MAX_THREADS = 10

    def initialize(options = {})
      @max_entries = options[:max_entries] || MAX_ENTRIES
      @entries = {} # store endpoints
      @max_threads = options[:max_threads] || MAX_THREADS
      @pool = {} # store polling threads
      @mutex = Mutex.new
      @require_identifier = nil # whether endpoint operation support identifier
    end

    # @return [Integer] Max size limit of cache
    attr_reader :max_entries

    # @return [Integer] Max count of polling threads
    attr_reader :max_threads

    # return [Hash] Polling threads pool
    attr_reader :pool

    # @param [String] key
    # @return [Endpoint]
    def [](key)
      @mutex.synchronize do
        # fetching an existing endpoint delete it and then append it
        endpoint = @entries[key]
        if endpoint
          @entries.delete(key)
          @entries[key] = endpoint
        end
        endpoint
      end
    end

    # @param [String] key
    # @param [Hash] value
    def []=(key, value)
      @mutex.synchronize do
        # delete the least recent used endpoint when cache is full
        unless @entries.size < @max_entries
          old_key, _ = @entries.shift
          self.delete_polling_thread(old_key)
        end
        # delete old value if exists
        @entries.delete(key)
        @entries[key] = Endpoint.new(value.to_hash)
      end
    end

    # checking whether an unexpired endpoint key exists in cache
    # @param [String] key
    # @return [Boolean]
    def key?(key)
      if @entries.key?(key) && (@entries[key].nil? || @entries[key].expired?)
        self.delete(key)
      end
      @entries.key?(key)
    end

    # checking whether an polling thread exist for the key
    # @param [String] key
    # @return [Boolean]
    def threads_key?(key)
      @pool.key?(key)
    end

    # remove entry only
    # @param [String] key
    def delete(key)
      @mutex.synchronize do
        @entries.delete(key)
      end
    end

    # kill the old polling thread and remove it from pool
    # @param [String] key
    def delete_polling_thread(key)
      Thread.kill(@pool[key]) if self.threads_key?(key)
      @pool.delete(key)
    end

    # update cache with requests (using service endpoint operation)
    # to fetch endpoint list (with identifiers when available)
    # @param [String] key
    # @param [RequestContext] ctx
    def update(key, ctx)
      resp = _request_endpoint(ctx)
      if resp && resp.endpoints
        resp.endpoints.each { |e| self[key] = e }
      end
    end

    # extract the key to be used in the cache from request context
    # @param [RequestContext] ctx
    # @return [String]
    def extract_key(ctx)
      parts = []
      # fetching from cred provider directly gives warnings
      parts << ctx.config.credentials.credentials.access_key_id
      if _endpoint_operation_identifier(ctx)
        parts << ctx.operation_name
        ctx.operation.input.shape.members.inject(parts) do |p, (name, ref)|
          p << ctx.params[name] if ref["endpointdiscoveryid"]
          p
        end
      end
      parts.join('_')
    end

    # update polling threads pool
    # param [String] key
    # param [Thread] thread
    def update_polling_pool(key, thread)
      unless @pool.size < @max_threads
        _, thread = @pool.shift
        Thread.kill(thread)
      end
      @pool[key] = thread
    end

    # kill all polling threads
    def stop_polling!
      @pool.each { |_, t| Thread.kill(t) }
      @pool = {}
    end

    private

    def _request_endpoint(ctx)
      params = {}
      if _endpoint_operation_identifier(ctx)
        # build identifier params when available
        params[:operation] = ctx.operation.name
        ctx.operation.input.shape.members.inject(params) do |p, (name, ref)|
          if ref["endpointdiscoveryid"]
            p[:identifiers] ||= {}
            p[:identifiers][ref.location_name] = ctx.params[name]
          end
          p
        end
      end

      begin
        endpoint_operation_name = ctx.config.api.endpoint_operation
        ctx.client.send(endpoint_operation_name, params)
      rescue Aws::Errors::ServiceError
        nil 
      end
    end

    def _endpoint_operation_identifier(ctx)
      return @require_identifier unless @require_identifier.nil?
      operation_name = ctx.config.api.endpoint_operation
      operation = ctx.config.api.operation(operation_name)
      @require_identifier = operation.input.shape.members.any?
    end

    class Endpoint
    
      # default endpoint cache time, 1 minute
      CACHE_PERIOD = 1

      def initialize(options)
        @address = options.fetch(:address)
        @cache_period = options[:cache_period_in_minutes] || CACHE_PERIOD
        @created_time = Time.now
      end

      # [String] valid URI address (with path) 
      attr_reader :address

      def expired?
        Time.now - @created_time > @cache_period * 60
      end

    end

  end
end
module Aws
  module ClientSideMonitoring
    # @api private
    class RequestMetrics
      attr_reader :api_call, :api_call_attempts

      FIELD_MAX_LENGTH = {
        "ClientId" => 255,
        "UserAgent" => 256,
        "SdkException" => 128,
        "SdkExceptionMessage" => 512,
        "AwsException" => 128,
        "AwsExceptionMessage" => 512,
        "FinalAwsException" => 128,
        "FinalAwsExceptionMessage" => 512,
        "FinalSdkException" => 128,
        "FinalSdkExceptionMessage" => 512,
      }

      def initialize(opts = {})
        @service = opts[:service]
        @api = opts[:operation]
        @client_id = opts[:client_id]
        @timestamp = opts[:timestamp] # In epoch milliseconds
        @region = opts[:region]
        @version = 1
        @api_call = ApiCall.new(@service, @api, @client_id, @version, @timestamp, @region)
        @api_call_attempts = []
      end

      def build_call_attempt(opts = {})
        timestamp = opts[:timestamp]
        fqdn = opts[:fqdn]
        region = opts[:region]
        user_agent = opts[:user_agent]
        access_key = opts[:access_key]
        session_token = opts[:session_token]
        ApiCallAttempt.new(
          @service,
          @api,
          @client_id,
          @version,
          timestamp,
          fqdn,
          region,
          user_agent,
          access_key,
          session_token
        )
      end

      def add_call_attempt(attempt)
        @api_call_attempts << attempt
      end

      class ApiCall
        attr_reader :service, :api, :client_id, :timestamp, :version,
          :attempt_count, :latency, :region, :max_retries_exceeded,
          :final_http_status_code, :user_agent, :final_aws_exception,
          :final_aws_exception_message, :final_sdk_exception,
          :final_sdk_exception_message

        def initialize(service, api, client_id, version, timestamp, region)
          @service = service
          @api = api
          @client_id = client_id
          @version = version
          @timestamp = timestamp
          @region = region
        end

        def complete(opts = {})
          @latency = opts[:latency]
          @attempt_count = opts[:attempt_count]
          @user_agent = opts[:user_agent]
          if opts[:final_error_retryable]
            @max_retries_exceeded = 1
          else
            @max_retries_exceeded = 0
          end
          @final_http_status_code = opts[:final_http_status_code]
          @final_aws_exception = opts[:final_aws_exception]
          @final_aws_exception_message = opts[:final_aws_exception_message]
          @final_sdk_exception = opts[:final_sdk_exception]
          @final_sdk_exception_message = opts[:final_sdk_exception_message]
          @region = opts[:region] if opts[:region] # in case region changes
        end

        def to_json(*a)
          document = {
            "Type" => "ApiCall",
            "Service" => @service,
            "Api" => @api,
            "ClientId" => @client_id,
            "Timestamp" => @timestamp,
            "Version" => @version,
            "AttemptCount" => @attempt_count,
            "Latency" => @latency,
            "Region" => @region,
            "MaxRetriesExceeded" => @max_retries_exceeded,
            "UserAgent" => @user_agent,
            "FinalHttpStatusCode" => @final_http_status_code,
          }
          document["FinalSdkException"] = @final_sdk_exception if @final_sdk_exception
          document["FinalSdkExceptionMessage"] = @final_sdk_exception_message if @final_sdk_exception_message
          document["FinalAwsException"] = @final_aws_exception if @final_aws_exception
          document["FinalAwsExceptionMessage"] = @final_aws_exception_message if @final_aws_exception_message
          document = _truncate(document)
          document.to_json
        end

        private
        def _truncate(document)
          document.each do |key, value|
            limit = FIELD_MAX_LENGTH[key]
            if limit && value.to_s.length > limit
              document[key] = value.to_s.slice(0...limit)
            end
          end
          document
        end
      end

      class ApiCallAttempt
        attr_reader :service, :api, :client_id, :version, :timestamp,
          :user_agent, :access_key, :session_token
        attr_accessor :region, :fqdn, :request_latency, :http_status_code,
          :aws_exception_msg, :x_amz_request_id, :x_amz_id_2,
          :x_amzn_request_id, :sdk_exception, :aws_exception, :sdk_exception_msg

        def initialize(
          service,
          api,
          client_id,
          version,
          timestamp,
          fqdn,
          region,
          user_agent,
          access_key,
          session_token
        )
          @service = service
          @api = api
          @client_id = client_id
          @version = version
          @timestamp = timestamp
          @fqdn = fqdn
          @region = region
          @user_agent = user_agent
          @access_key = access_key
          @session_token = session_token
        end

        def to_json(*a)
          json = {
            "Type" => "ApiCallAttempt",
            "Service" => @service,
            "Api" => @api,
            "ClientId" => @client_id,
            "Timestamp" => @timestamp,
            "Version" => @version,
            "Fqdn" => @fqdn,
            "Region" => @region,
            "UserAgent" => @user_agent,
            "AccessKey" => @access_key
          }
          # Optional Fields
          json["SessionToken"] = @session_token if @session_token
          json["HttpStatusCode"] = @http_status_code if @http_status_code
          json["AwsException"] = @aws_exception if @aws_exception
          json["AwsExceptionMessage"] = @aws_exception_msg if @aws_exception_msg
          json["XAmznRequestId"] = @x_amzn_request_id if @x_amzn_request_id
          json["XAmzRequestId"] = @x_amz_request_id if @x_amz_request_id
          json["XAmzId2"] = @x_amz_id_2 if @x_amz_id_2
          json["AttemptLatency"] = @request_latency if @request_latency
          json["SdkException"] = @sdk_exception if @sdk_exception
          json["SdkExceptionMessage"] = @sdk_exception_msg if @sdk_exception_msg
          json = _truncate(json)
          json.to_json
        end

        private
        def _truncate(document)
          document.each do |key, value|
            limit = FIELD_MAX_LENGTH[key]
            if limit && value.to_s.length > limit
              document[key] = value.to_s.slice(0...limit)
            end
          end
          document
        end
      end

    end
  end
end
require 'thread'
require 'socket'

module Aws
  module ClientSideMonitoring
    # @api private
    class Publisher
      attr_reader :agent_port

      def initialize(opts = {})
        @agent_port = opts[:agent_port]
        @mutex = Mutex.new
      end

      def agent_port=(value)
        @mutex.synchronize do
          @agent_port = value
        end
      end

      def publish(request_metrics)
        send_datagram(request_metrics.api_call.to_json)
        request_metrics.api_call_attempts.each do |attempt|
          send_datagram(attempt.to_json)
        end
      end

      def send_datagram(msg)
        if @agent_port
          socket = UDPSocket.new
          begin
            socket.connect("127.0.0.1", @agent_port)
            socket.send(msg, 0)
          rescue Errno::ECONNREFUSED
            # Drop on the floor
          end
        end
      end
    end
  end
end
# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/master/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::STS
  module Types

    # @note When making an API call, you may pass AssumeRoleRequest
    #   data as a hash:
    #
    #       {
    #         role_arn: "arnType", # required
    #         role_session_name: "roleSessionNameType", # required
    #         policy_arns: [
    #           {
    #             arn: "arnType",
    #           },
    #         ],
    #         policy: "sessionPolicyDocumentType",
    #         duration_seconds: 1,
    #         external_id: "externalIdType",
    #         serial_number: "serialNumberType",
    #         token_code: "tokenCodeType",
    #       }
    #
    # @!attribute [rw] role_arn
    #   The Amazon Resource Name (ARN) of the role to assume.
    #   @return [String]
    #
    # @!attribute [rw] role_session_name
    #   An identifier for the assumed role session.
    #
    #   Use the role session name to uniquely identify a session when the
    #   same role is assumed by different principals or for different
    #   reasons. In cross-account scenarios, the role session name is
    #   visible to, and can be logged by the account that owns the role. The
    #   role session name is also used in the ARN of the assumed role
    #   principal. This means that subsequent cross-account API requests
    #   that use the temporary security credentials will expose the role
    #   session name to the external account in their AWS CloudTrail logs.
    #
    #   The regex used to validate this parameter is a string of characters
    #   consisting of upper- and lower-case alphanumeric characters with no
    #   spaces. You can also include underscores or any of the following
    #   characters: =,.@-
    #   @return [String]
    #
    # @!attribute [rw] policy_arns
    #   The Amazon Resource Names (ARNs) of the IAM managed policies that
    #   you want to use as managed session policies. The policies must exist
    #   in the same account as the role.
    #
    #   This parameter is optional. You can provide up to 10 managed policy
    #   ARNs. However, the plain text that you use for both inline and
    #   managed session policies shouldn't exceed 2048 characters. For more
    #   information about ARNs, see [Amazon Resource Names (ARNs) and AWS
    #   Service Namespaces](general/latest/gr/aws-arns-and-namespaces.html)
    #   in the AWS General Reference.
    #
    #   <note markdown="1"> The characters in this parameter count towards the 2048 character
    #   session policy guideline. However, an AWS conversion compresses the
    #   session policies into a packed binary format that has a separate
    #   limit. This is the enforced limit. The `PackedPolicySize` response
    #   element indicates by percentage how close the policy is to the upper
    #   size limit.
    #
    #    </note>
    #
    #   Passing policies to this operation returns new temporary
    #   credentials. The resulting session's permissions are the
    #   intersection of the role's identity-based policy and the session
    #   policies. You can use the role's temporary credentials in
    #   subsequent AWS API calls to access resources in the account that
    #   owns the role. You cannot use session policies to grant more
    #   permissions than those allowed by the identity-based policy of the
    #   role that is being assumed. For more information, see [Session
    #   Policies][1] in the *IAM User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/IAM/latest/UserGuide/access_policies.html#policies_session
    #   @return [Array<Types::PolicyDescriptorType>]
    #
    # @!attribute [rw] policy
    #   An IAM policy in JSON format that you want to use as an inline
    #   session policy.
    #
    #   This parameter is optional. Passing policies to this operation
    #   returns new temporary credentials. The resulting session's
    #   permissions are the intersection of the role's identity-based
    #   policy and the session policies. You can use the role's temporary
    #   credentials in subsequent AWS API calls to access resources in the
    #   account that owns the role. You cannot use session policies to grant
    #   more permissions than those allowed by the identity-based policy of
    #   the role that is being assumed. For more information, see [Session
    #   Policies][1] in the *IAM User Guide*.
    #
    #   The plain text that you use for both inline and managed session
    #   policies shouldn't exceed 2048 characters. The JSON policy
    #   characters can be any ASCII character from the space character to
    #   the end of the valid character list (\\u0020 through \\u00FF). It
    #   can also include the tab (\\u0009), linefeed (\\u000A), and carriage
    #   return (\\u000D) characters.
    #
    #   <note markdown="1"> The characters in this parameter count towards the 2048 character
    #   session policy guideline. However, an AWS conversion compresses the
    #   session policies into a packed binary format that has a separate
    #   limit. This is the enforced limit. The `PackedPolicySize` response
    #   element indicates by percentage how close the policy is to the upper
    #   size limit.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/IAM/latest/UserGuide/access_policies.html#policies_session
    #   @return [String]
    #
    # @!attribute [rw] duration_seconds
    #   The duration, in seconds, of the role session. The value can range
    #   from 900 seconds (15 minutes) up to the maximum session duration
    #   setting for the role. This setting can have a value from 1 hour to
    #   12 hours. If you specify a value higher than this setting, the
    #   operation fails. For example, if you specify a session duration of
    #   12 hours, but your administrator set the maximum session duration to
    #   6 hours, your operation fails. To learn how to view the maximum
    #   value for your role, see [View the Maximum Session Duration Setting
    #   for a Role][1] in the *IAM User Guide*.
    #
    #   By default, the value is set to `3600` seconds.
    #
    #   <note markdown="1"> The `DurationSeconds` parameter is separate from the duration of a
    #   console session that you might request using the returned
    #   credentials. The request to the federation endpoint for a console
    #   sign-in token takes a `SessionDuration` parameter that specifies the
    #   maximum length of the console session. For more information, see
    #   [Creating a URL that Enables Federated Users to Access the AWS
    #   Management Console][2] in the *IAM User Guide*.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html
    #   @return [Integer]
    #
    # @!attribute [rw] external_id
    #   A unique identifier that might be required when you assume a role in
    #   another account. If the administrator of the account to which the
    #   role belongs provided you with an external ID, then provide that
    #   value in the `ExternalId` parameter. This value can be any string,
    #   such as a passphrase or account number. A cross-account role is
    #   usually set up to trust everyone in an account. Therefore, the
    #   administrator of the trusting account might send an external ID to
    #   the administrator of the trusted account. That way, only someone
    #   with the ID can assume the role, rather than everyone in the
    #   account. For more information about the external ID, see [How to Use
    #   an External ID When Granting Access to Your AWS Resources to a Third
    #   Party][1] in the *IAM User Guide*.
    #
    #   The regex used to validate this parameter is a string of characters
    #   consisting of upper- and lower-case alphanumeric characters with no
    #   spaces. You can also include underscores or any of the following
    #   characters: =,.@:/-
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user_externalid.html
    #   @return [String]
    #
    # @!attribute [rw] serial_number
    #   The identification number of the MFA device that is associated with
    #   the user who is making the `AssumeRole` call. Specify this value if
    #   the trust policy of the role being assumed includes a condition that
    #   requires MFA authentication. The value is either the serial number
    #   for a hardware device (such as `GAHT12345678`) or an Amazon Resource
    #   Name (ARN) for a virtual device (such as
    #   `arn:aws:iam::123456789012:mfa/user`).
    #
    #   The regex used to validate this parameter is a string of characters
    #   consisting of upper- and lower-case alphanumeric characters with no
    #   spaces. You can also include underscores or any of the following
    #   characters: =,.@-
    #   @return [String]
    #
    # @!attribute [rw] token_code
    #   The value provided by the MFA device, if the trust policy of the
    #   role being assumed requires MFA (that is, if the policy includes a
    #   condition that tests for MFA). If the role being assumed requires
    #   MFA and if the `TokenCode` value is missing or expired, the
    #   `AssumeRole` call returns an "access denied" error.
    #
    #   The format for this parameter, as described by its regex pattern, is
    #   a sequence of six numeric digits.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/AssumeRoleRequest AWS API Documentation
    #
    class AssumeRoleRequest < Struct.new(
      :role_arn,
      :role_session_name,
      :policy_arns,
      :policy,
      :duration_seconds,
      :external_id,
      :serial_number,
      :token_code)
      include Aws::Structure
    end

    # Contains the response to a successful AssumeRole request, including
    # temporary AWS credentials that can be used to make AWS requests.
    #
    # @!attribute [rw] credentials
    #   The temporary security credentials, which include an access key ID,
    #   a secret access key, and a security (or session) token.
    #
    #   <note markdown="1"> The size of the security token that STS API operations return is not
    #   fixed. We strongly recommend that you make no assumptions about the
    #   maximum size.
    #
    #    </note>
    #   @return [Types::Credentials]
    #
    # @!attribute [rw] assumed_role_user
    #   The Amazon Resource Name (ARN) and the assumed role ID, which are
    #   identifiers that you can use to refer to the resulting temporary
    #   security credentials. For example, you can reference these
    #   credentials as a principal in a resource-based policy by using the
    #   ARN or assumed role ID. The ARN and ID include the `RoleSessionName`
    #   that you specified when you called `AssumeRole`.
    #   @return [Types::AssumedRoleUser]
    #
    # @!attribute [rw] packed_policy_size
    #   A percentage value that indicates the size of the policy in packed
    #   form. The service rejects any policy with a packed size greater than
    #   100 percent, which means the policy exceeded the allowed space.
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/AssumeRoleResponse AWS API Documentation
    #
    class AssumeRoleResponse < Struct.new(
      :credentials,
      :assumed_role_user,
      :packed_policy_size)
      include Aws::Structure
    end

    # @note When making an API call, you may pass AssumeRoleWithSAMLRequest
    #   data as a hash:
    #
    #       {
    #         role_arn: "arnType", # required
    #         principal_arn: "arnType", # required
    #         saml_assertion: "SAMLAssertionType", # required
    #         policy_arns: [
    #           {
    #             arn: "arnType",
    #           },
    #         ],
    #         policy: "sessionPolicyDocumentType",
    #         duration_seconds: 1,
    #       }
    #
    # @!attribute [rw] role_arn
    #   The Amazon Resource Name (ARN) of the role that the caller is
    #   assuming.
    #   @return [String]
    #
    # @!attribute [rw] principal_arn
    #   The Amazon Resource Name (ARN) of the SAML provider in IAM that
    #   describes the IdP.
    #   @return [String]
    #
    # @!attribute [rw] saml_assertion
    #   The base-64 encoded SAML authentication response provided by the
    #   IdP.
    #
    #   For more information, see [Configuring a Relying Party and Adding
    #   Claims][1] in the *IAM User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/create-role-saml-IdP-tasks.html
    #   @return [String]
    #
    # @!attribute [rw] policy_arns
    #   The Amazon Resource Names (ARNs) of the IAM managed policies that
    #   you want to use as managed session policies. The policies must exist
    #   in the same account as the role.
    #
    #   This parameter is optional. You can provide up to 10 managed policy
    #   ARNs. However, the plain text that you use for both inline and
    #   managed session policies shouldn't exceed 2048 characters. For more
    #   information about ARNs, see [Amazon Resource Names (ARNs) and AWS
    #   Service Namespaces](general/latest/gr/aws-arns-and-namespaces.html)
    #   in the AWS General Reference.
    #
    #   <note markdown="1"> The characters in this parameter count towards the 2048 character
    #   session policy guideline. However, an AWS conversion compresses the
    #   session policies into a packed binary format that has a separate
    #   limit. This is the enforced limit. The `PackedPolicySize` response
    #   element indicates by percentage how close the policy is to the upper
    #   size limit.
    #
    #    </note>
    #
    #   Passing policies to this operation returns new temporary
    #   credentials. The resulting session's permissions are the
    #   intersection of the role's identity-based policy and the session
    #   policies. You can use the role's temporary credentials in
    #   subsequent AWS API calls to access resources in the account that
    #   owns the role. You cannot use session policies to grant more
    #   permissions than those allowed by the identity-based policy of the
    #   role that is being assumed. For more information, see [Session
    #   Policies][1] in the *IAM User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/IAM/latest/UserGuide/access_policies.html#policies_session
    #   @return [Array<Types::PolicyDescriptorType>]
    #
    # @!attribute [rw] policy
    #   An IAM policy in JSON format that you want to use as an inline
    #   session policy.
    #
    #   This parameter is optional. Passing policies to this operation
    #   returns new temporary credentials. The resulting session's
    #   permissions are the intersection of the role's identity-based
    #   policy and the session policies. You can use the role's temporary
    #   credentials in subsequent AWS API calls to access resources in the
    #   account that owns the role. You cannot use session policies to grant
    #   more permissions than those allowed by the identity-based policy of
    #   the role that is being assumed. For more information, see [Session
    #   Policies][1] in the *IAM User Guide*.
    #
    #   The plain text that you use for both inline and managed session
    #   policies shouldn't exceed 2048 characters. The JSON policy
    #   characters can be any ASCII character from the space character to
    #   the end of the valid character list (\\u0020 through \\u00FF). It
    #   can also include the tab (\\u0009), linefeed (\\u000A), and carriage
    #   return (\\u000D) characters.
    #
    #   <note markdown="1"> The characters in this parameter count towards the 2048 character
    #   session policy guideline. However, an AWS conversion compresses the
    #   session policies into a packed binary format that has a separate
    #   limit. This is the enforced limit. The `PackedPolicySize` response
    #   element indicates by percentage how close the policy is to the upper
    #   size limit.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/IAM/latest/UserGuide/access_policies.html#policies_session
    #   @return [String]
    #
    # @!attribute [rw] duration_seconds
    #   The duration, in seconds, of the role session. Your role session
    #   lasts for the duration that you specify for the `DurationSeconds`
    #   parameter, or until the time specified in the SAML authentication
    #   response's `SessionNotOnOrAfter` value, whichever is shorter. You
    #   can provide a `DurationSeconds` value from 900 seconds (15 minutes)
    #   up to the maximum session duration setting for the role. This
    #   setting can have a value from 1 hour to 12 hours. If you specify a
    #   value higher than this setting, the operation fails. For example, if
    #   you specify a session duration of 12 hours, but your administrator
    #   set the maximum session duration to 6 hours, your operation fails.
    #   To learn how to view the maximum value for your role, see [View the
    #   Maximum Session Duration Setting for a Role][1] in the *IAM User
    #   Guide*.
    #
    #   By default, the value is set to `3600` seconds.
    #
    #   <note markdown="1"> The `DurationSeconds` parameter is separate from the duration of a
    #   console session that you might request using the returned
    #   credentials. The request to the federation endpoint for a console
    #   sign-in token takes a `SessionDuration` parameter that specifies the
    #   maximum length of the console session. For more information, see
    #   [Creating a URL that Enables Federated Users to Access the AWS
    #   Management Console][2] in the *IAM User Guide*.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/AssumeRoleWithSAMLRequest AWS API Documentation
    #
    class AssumeRoleWithSAMLRequest < Struct.new(
      :role_arn,
      :principal_arn,
      :saml_assertion,
      :policy_arns,
      :policy,
      :duration_seconds)
      include Aws::Structure
    end

    # Contains the response to a successful AssumeRoleWithSAML request,
    # including temporary AWS credentials that can be used to make AWS
    # requests.
    #
    # @!attribute [rw] credentials
    #   The temporary security credentials, which include an access key ID,
    #   a secret access key, and a security (or session) token.
    #
    #   <note markdown="1"> The size of the security token that STS API operations return is not
    #   fixed. We strongly recommend that you make no assumptions about the
    #   maximum size.
    #
    #    </note>
    #   @return [Types::Credentials]
    #
    # @!attribute [rw] assumed_role_user
    #   The identifiers for the temporary security credentials that the
    #   operation returns.
    #   @return [Types::AssumedRoleUser]
    #
    # @!attribute [rw] packed_policy_size
    #   A percentage value that indicates the size of the policy in packed
    #   form. The service rejects any policy with a packed size greater than
    #   100 percent, which means the policy exceeded the allowed space.
    #   @return [Integer]
    #
    # @!attribute [rw] subject
    #   The value of the `NameID` element in the `Subject` element of the
    #   SAML assertion.
    #   @return [String]
    #
    # @!attribute [rw] subject_type
    #   The format of the name ID, as defined by the `Format` attribute in
    #   the `NameID` element of the SAML assertion. Typical examples of the
    #   format are `transient` or `persistent`.
    #
    #   If the format includes the prefix
    #   `urn:oasis:names:tc:SAML:2.0:nameid-format`, that prefix is removed.
    #   For example, `urn:oasis:names:tc:SAML:2.0:nameid-format:transient`
    #   is returned as `transient`. If the format includes any other prefix,
    #   the format is returned with no modifications.
    #   @return [String]
    #
    # @!attribute [rw] issuer
    #   The value of the `Issuer` element of the SAML assertion.
    #   @return [String]
    #
    # @!attribute [rw] audience
    #   The value of the `Recipient` attribute of the
    #   `SubjectConfirmationData` element of the SAML assertion.
    #   @return [String]
    #
    # @!attribute [rw] name_qualifier
    #   A hash value based on the concatenation of the `Issuer` response
    #   value, the AWS account ID, and the friendly name (the last part of
    #   the ARN) of the SAML provider in IAM. The combination of
    #   `NameQualifier` and `Subject` can be used to uniquely identify a
    #   federated user.
    #
    #   The following pseudocode shows how the hash value is calculated:
    #
    #   `BASE64 ( SHA1 ( "https://example.com/saml" + "123456789012" +
    #   "/MySAMLIdP" ) )`
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/AssumeRoleWithSAMLResponse AWS API Documentation
    #
    class AssumeRoleWithSAMLResponse < Struct.new(
      :credentials,
      :assumed_role_user,
      :packed_policy_size,
      :subject,
      :subject_type,
      :issuer,
      :audience,
      :name_qualifier)
      include Aws::Structure
    end

    # @note When making an API call, you may pass AssumeRoleWithWebIdentityRequest
    #   data as a hash:
    #
    #       {
    #         role_arn: "arnType", # required
    #         role_session_name: "roleSessionNameType", # required
    #         web_identity_token: "clientTokenType", # required
    #         provider_id: "urlType",
    #         policy_arns: [
    #           {
    #             arn: "arnType",
    #           },
    #         ],
    #         policy: "sessionPolicyDocumentType",
    #         duration_seconds: 1,
    #       }
    #
    # @!attribute [rw] role_arn
    #   The Amazon Resource Name (ARN) of the role that the caller is
    #   assuming.
    #   @return [String]
    #
    # @!attribute [rw] role_session_name
    #   An identifier for the assumed role session. Typically, you pass the
    #   name or identifier that is associated with the user who is using
    #   your application. That way, the temporary security credentials that
    #   your application will use are associated with that user. This
    #   session name is included as part of the ARN and assumed role ID in
    #   the `AssumedRoleUser` response element.
    #
    #   The regex used to validate this parameter is a string of characters
    #   consisting of upper- and lower-case alphanumeric characters with no
    #   spaces. You can also include underscores or any of the following
    #   characters: =,.@-
    #   @return [String]
    #
    # @!attribute [rw] web_identity_token
    #   The OAuth 2.0 access token or OpenID Connect ID token that is
    #   provided by the identity provider. Your application must get this
    #   token by authenticating the user who is using your application with
    #   a web identity provider before the application makes an
    #   `AssumeRoleWithWebIdentity` call.
    #   @return [String]
    #
    # @!attribute [rw] provider_id
    #   The fully qualified host component of the domain name of the
    #   identity provider.
    #
    #   Specify this value only for OAuth 2.0 access tokens. Currently
    #   `www.amazon.com` and `graph.facebook.com` are the only supported
    #   identity providers for OAuth 2.0 access tokens. Do not include URL
    #   schemes and port numbers.
    #
    #   Do not specify this value for OpenID Connect ID tokens.
    #   @return [String]
    #
    # @!attribute [rw] policy_arns
    #   The Amazon Resource Names (ARNs) of the IAM managed policies that
    #   you want to use as managed session policies. The policies must exist
    #   in the same account as the role.
    #
    #   This parameter is optional. You can provide up to 10 managed policy
    #   ARNs. However, the plain text that you use for both inline and
    #   managed session policies shouldn't exceed 2048 characters. For more
    #   information about ARNs, see [Amazon Resource Names (ARNs) and AWS
    #   Service Namespaces](general/latest/gr/aws-arns-and-namespaces.html)
    #   in the AWS General Reference.
    #
    #   <note markdown="1"> The characters in this parameter count towards the 2048 character
    #   session policy guideline. However, an AWS conversion compresses the
    #   session policies into a packed binary format that has a separate
    #   limit. This is the enforced limit. The `PackedPolicySize` response
    #   element indicates by percentage how close the policy is to the upper
    #   size limit.
    #
    #    </note>
    #
    #   Passing policies to this operation returns new temporary
    #   credentials. The resulting session's permissions are the
    #   intersection of the role's identity-based policy and the session
    #   policies. You can use the role's temporary credentials in
    #   subsequent AWS API calls to access resources in the account that
    #   owns the role. You cannot use session policies to grant more
    #   permissions than those allowed by the identity-based policy of the
    #   role that is being assumed. For more information, see [Session
    #   Policies][1] in the *IAM User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/IAM/latest/UserGuide/access_policies.html#policies_session
    #   @return [Array<Types::PolicyDescriptorType>]
    #
    # @!attribute [rw] policy
    #   An IAM policy in JSON format that you want to use as an inline
    #   session policy.
    #
    #   This parameter is optional. Passing policies to this operation
    #   returns new temporary credentials. The resulting session's
    #   permissions are the intersection of the role's identity-based
    #   policy and the session policies. You can use the role's temporary
    #   credentials in subsequent AWS API calls to access resources in the
    #   account that owns the role. You cannot use session policies to grant
    #   more permissions than those allowed by the identity-based policy of
    #   the role that is being assumed. For more information, see [Session
    #   Policies][1] in the *IAM User Guide*.
    #
    #   The plain text that you use for both inline and managed session
    #   policies shouldn't exceed 2048 characters. The JSON policy
    #   characters can be any ASCII character from the space character to
    #   the end of the valid character list (\\u0020 through \\u00FF). It
    #   can also include the tab (\\u0009), linefeed (\\u000A), and carriage
    #   return (\\u000D) characters.
    #
    #   <note markdown="1"> The characters in this parameter count towards the 2048 character
    #   session policy guideline. However, an AWS conversion compresses the
    #   session policies into a packed binary format that has a separate
    #   limit. This is the enforced limit. The `PackedPolicySize` response
    #   element indicates by percentage how close the policy is to the upper
    #   size limit.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/IAM/latest/UserGuide/access_policies.html#policies_session
    #   @return [String]
    #
    # @!attribute [rw] duration_seconds
    #   The duration, in seconds, of the role session. The value can range
    #   from 900 seconds (15 minutes) up to the maximum session duration
    #   setting for the role. This setting can have a value from 1 hour to
    #   12 hours. If you specify a value higher than this setting, the
    #   operation fails. For example, if you specify a session duration of
    #   12 hours, but your administrator set the maximum session duration to
    #   6 hours, your operation fails. To learn how to view the maximum
    #   value for your role, see [View the Maximum Session Duration Setting
    #   for a Role][1] in the *IAM User Guide*.
    #
    #   By default, the value is set to `3600` seconds.
    #
    #   <note markdown="1"> The `DurationSeconds` parameter is separate from the duration of a
    #   console session that you might request using the returned
    #   credentials. The request to the federation endpoint for a console
    #   sign-in token takes a `SessionDuration` parameter that specifies the
    #   maximum length of the console session. For more information, see
    #   [Creating a URL that Enables Federated Users to Access the AWS
    #   Management Console][2] in the *IAM User Guide*.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/AssumeRoleWithWebIdentityRequest AWS API Documentation
    #
    class AssumeRoleWithWebIdentityRequest < Struct.new(
      :role_arn,
      :role_session_name,
      :web_identity_token,
      :provider_id,
      :policy_arns,
      :policy,
      :duration_seconds)
      include Aws::Structure
    end

    # Contains the response to a successful AssumeRoleWithWebIdentity
    # request, including temporary AWS credentials that can be used to make
    # AWS requests.
    #
    # @!attribute [rw] credentials
    #   The temporary security credentials, which include an access key ID,
    #   a secret access key, and a security token.
    #
    #   <note markdown="1"> The size of the security token that STS API operations return is not
    #   fixed. We strongly recommend that you make no assumptions about the
    #   maximum size.
    #
    #    </note>
    #   @return [Types::Credentials]
    #
    # @!attribute [rw] subject_from_web_identity_token
    #   The unique user identifier that is returned by the identity
    #   provider. This identifier is associated with the `WebIdentityToken`
    #   that was submitted with the `AssumeRoleWithWebIdentity` call. The
    #   identifier is typically unique to the user and the application that
    #   acquired the `WebIdentityToken` (pairwise identifier). For OpenID
    #   Connect ID tokens, this field contains the value returned by the
    #   identity provider as the token's `sub` (Subject) claim.
    #   @return [String]
    #
    # @!attribute [rw] assumed_role_user
    #   The Amazon Resource Name (ARN) and the assumed role ID, which are
    #   identifiers that you can use to refer to the resulting temporary
    #   security credentials. For example, you can reference these
    #   credentials as a principal in a resource-based policy by using the
    #   ARN or assumed role ID. The ARN and ID include the `RoleSessionName`
    #   that you specified when you called `AssumeRole`.
    #   @return [Types::AssumedRoleUser]
    #
    # @!attribute [rw] packed_policy_size
    #   A percentage value that indicates the size of the policy in packed
    #   form. The service rejects any policy with a packed size greater than
    #   100 percent, which means the policy exceeded the allowed space.
    #   @return [Integer]
    #
    # @!attribute [rw] provider
    #   The issuing authority of the web identity token presented. For
    #   OpenID Connect ID tokens, this contains the value of the `iss`
    #   field. For OAuth 2.0 access tokens, this contains the value of the
    #   `ProviderId` parameter that was passed in the
    #   `AssumeRoleWithWebIdentity` request.
    #   @return [String]
    #
    # @!attribute [rw] audience
    #   The intended audience (also known as client ID) of the web identity
    #   token. This is traditionally the client identifier issued to the
    #   application that requested the web identity token.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/AssumeRoleWithWebIdentityResponse AWS API Documentation
    #
    class AssumeRoleWithWebIdentityResponse < Struct.new(
      :credentials,
      :subject_from_web_identity_token,
      :assumed_role_user,
      :packed_policy_size,
      :provider,
      :audience)
      include Aws::Structure
    end

    # The identifiers for the temporary security credentials that the
    # operation returns.
    #
    # @!attribute [rw] assumed_role_id
    #   A unique identifier that contains the role ID and the role session
    #   name of the role that is being assumed. The role ID is generated by
    #   AWS when the role is created.
    #   @return [String]
    #
    # @!attribute [rw] arn
    #   The ARN of the temporary security credentials that are returned from
    #   the AssumeRole action. For more information about ARNs and how to
    #   use them in policies, see [IAM Identifiers][1] in *Using IAM*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/AssumedRoleUser AWS API Documentation
    #
    class AssumedRoleUser < Struct.new(
      :assumed_role_id,
      :arn)
      include Aws::Structure
    end

    # AWS credentials for API authentication.
    #
    # @!attribute [rw] access_key_id
    #   The access key ID that identifies the temporary security
    #   credentials.
    #   @return [String]
    #
    # @!attribute [rw] secret_access_key
    #   The secret access key that can be used to sign requests.
    #   @return [String]
    #
    # @!attribute [rw] session_token
    #   The token that users must pass to the service API to use the
    #   temporary credentials.
    #   @return [String]
    #
    # @!attribute [rw] expiration
    #   The date on which the current credentials expire.
    #   @return [Time]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/Credentials AWS API Documentation
    #
    class Credentials < Struct.new(
      :access_key_id,
      :secret_access_key,
      :session_token,
      :expiration)
      include Aws::Structure
    end

    # @note When making an API call, you may pass DecodeAuthorizationMessageRequest
    #   data as a hash:
    #
    #       {
    #         encoded_message: "encodedMessageType", # required
    #       }
    #
    # @!attribute [rw] encoded_message
    #   The encoded message that was returned with the response.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/DecodeAuthorizationMessageRequest AWS API Documentation
    #
    class DecodeAuthorizationMessageRequest < Struct.new(
      :encoded_message)
      include Aws::Structure
    end

    # A document that contains additional information about the
    # authorization status of a request from an encoded message that is
    # returned in response to an AWS request.
    #
    # @!attribute [rw] decoded_message
    #   An XML document that contains the decoded message.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/DecodeAuthorizationMessageResponse AWS API Documentation
    #
    class DecodeAuthorizationMessageResponse < Struct.new(
      :decoded_message)
      include Aws::Structure
    end

    # The web identity token that was passed is expired or is not valid. Get
    # a new identity token from the identity provider and then retry the
    # request.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/ExpiredTokenException AWS API Documentation
    #
    class ExpiredTokenException < Struct.new(
      :message)
      include Aws::Structure
    end

    # Identifiers for the federated user that is associated with the
    # credentials.
    #
    # @!attribute [rw] federated_user_id
    #   The string that identifies the federated user associated with the
    #   credentials, similar to the unique ID of an IAM user.
    #   @return [String]
    #
    # @!attribute [rw] arn
    #   The ARN that specifies the federated user that is associated with
    #   the credentials. For more information about ARNs and how to use them
    #   in policies, see [IAM Identifiers][1] in *Using IAM*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/FederatedUser AWS API Documentation
    #
    class FederatedUser < Struct.new(
      :federated_user_id,
      :arn)
      include Aws::Structure
    end

    # @api private
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/GetCallerIdentityRequest AWS API Documentation
    #
    class GetCallerIdentityRequest < Aws::EmptyStructure; end

    # Contains the response to a successful GetCallerIdentity request,
    # including information about the entity making the request.
    #
    # @!attribute [rw] user_id
    #   The unique identifier of the calling entity. The exact value depends
    #   on the type of entity that is making the call. The values returned
    #   are those listed in the **aws:userid** column in the [Principal
    #   table][1] found on the **Policy Variables** reference page in the
    #   *IAM User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_variables.html#principaltable
    #   @return [String]
    #
    # @!attribute [rw] account
    #   The AWS account ID number of the account that owns or contains the
    #   calling entity.
    #   @return [String]
    #
    # @!attribute [rw] arn
    #   The AWS ARN associated with the calling entity.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/GetCallerIdentityResponse AWS API Documentation
    #
    class GetCallerIdentityResponse < Struct.new(
      :user_id,
      :account,
      :arn)
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetFederationTokenRequest
    #   data as a hash:
    #
    #       {
    #         name: "userNameType", # required
    #         policy: "sessionPolicyDocumentType",
    #         policy_arns: [
    #           {
    #             arn: "arnType",
    #           },
    #         ],
    #         duration_seconds: 1,
    #       }
    #
    # @!attribute [rw] name
    #   The name of the federated user. The name is used as an identifier
    #   for the temporary security credentials (such as `Bob`). For example,
    #   you can reference the federated user name in a resource-based
    #   policy, such as in an Amazon S3 bucket policy.
    #
    #   The regex used to validate this parameter is a string of characters
    #   consisting of upper- and lower-case alphanumeric characters with no
    #   spaces. You can also include underscores or any of the following
    #   characters: =,.@-
    #   @return [String]
    #
    # @!attribute [rw] policy
    #   An IAM policy in JSON format that you want to use as an inline
    #   session policy.
    #
    #   You must pass an inline or managed [session policy][1] to this
    #   operation. You can pass a single JSON policy document to use as an
    #   inline session policy. You can also specify up to 10 managed
    #   policies to use as managed session policies.
    #
    #   This parameter is optional. However, if you do not pass any session
    #   policies, then the resulting federated user session has no
    #   permissions. The only exception is when the credentials are used to
    #   access a resource that has a resource-based policy that specifically
    #   references the federated user session in the `Principal` element of
    #   the policy.
    #
    #   When you pass session policies, the session permissions are the
    #   intersection of the IAM user policies and the session policies that
    #   you pass. This gives you a way to further restrict the permissions
    #   for a federated user. You cannot use session policies to grant more
    #   permissions than those that are defined in the permissions policy of
    #   the IAM user. For more information, see [Session Policies][2] in the
    #   *IAM User Guide*.
    #
    #   The plain text that you use for both inline and managed session
    #   policies shouldn't exceed 2048 characters. The JSON policy
    #   characters can be any ASCII character from the space character to
    #   the end of the valid character list (\\u0020 through \\u00FF). It
    #   can also include the tab (\\u0009), linefeed (\\u000A), and carriage
    #   return (\\u000D) characters.
    #
    #   <note markdown="1"> The characters in this parameter count towards the 2048 character
    #   session policy guideline. However, an AWS conversion compresses the
    #   session policies into a packed binary format that has a separate
    #   limit. This is the enforced limit. The `PackedPolicySize` response
    #   element indicates by percentage how close the policy is to the upper
    #   size limit.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/IAM/latest/UserGuide/access_policies.html#policies_session
    #   @return [String]
    #
    # @!attribute [rw] policy_arns
    #   The Amazon Resource Names (ARNs) of the IAM managed policies that
    #   you want to use as a managed session policy. The policies must exist
    #   in the same account as the IAM user that is requesting federated
    #   access.
    #
    #   You must pass an inline or managed [session policy][1] to this
    #   operation. You can pass a single JSON policy document to use as an
    #   inline session policy. You can also specify up to 10 managed
    #   policies to use as managed session policies. The plain text that you
    #   use for both inline and managed session policies shouldn't exceed
    #   2048 characters. You can provide up to 10 managed policy ARNs. For
    #   more information about ARNs, see [Amazon Resource Names (ARNs) and
    #   AWS Service
    #   Namespaces](general/latest/gr/aws-arns-and-namespaces.html) in the
    #   AWS General Reference.
    #
    #   This parameter is optional. However, if you do not pass any session
    #   policies, then the resulting federated user session has no
    #   permissions. The only exception is when the credentials are used to
    #   access a resource that has a resource-based policy that specifically
    #   references the federated user session in the `Principal` element of
    #   the policy.
    #
    #   When you pass session policies, the session permissions are the
    #   intersection of the IAM user policies and the session policies that
    #   you pass. This gives you a way to further restrict the permissions
    #   for a federated user. You cannot use session policies to grant more
    #   permissions than those that are defined in the permissions policy of
    #   the IAM user. For more information, see [Session Policies][2] in the
    #   *IAM User Guide*.
    #
    #   <note markdown="1"> The characters in this parameter count towards the 2048 character
    #   session policy guideline. However, an AWS conversion compresses the
    #   session policies into a packed binary format that has a separate
    #   limit. This is the enforced limit. The `PackedPolicySize` response
    #   element indicates by percentage how close the policy is to the upper
    #   size limit.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/IAM/latest/UserGuide/access_policies.html#policies_session
    #   @return [Array<Types::PolicyDescriptorType>]
    #
    # @!attribute [rw] duration_seconds
    #   The duration, in seconds, that the session should last. Acceptable
    #   durations for federation sessions range from 900 seconds (15
    #   minutes) to 129,600 seconds (36 hours), with 43,200 seconds (12
    #   hours) as the default. Sessions obtained using AWS account root user
    #   credentials are restricted to a maximum of 3,600 seconds (one hour).
    #   If the specified duration is longer than one hour, the session
    #   obtained by using root user credentials defaults to one hour.
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/GetFederationTokenRequest AWS API Documentation
    #
    class GetFederationTokenRequest < Struct.new(
      :name,
      :policy,
      :policy_arns,
      :duration_seconds)
      include Aws::Structure
    end

    # Contains the response to a successful GetFederationToken request,
    # including temporary AWS credentials that can be used to make AWS
    # requests.
    #
    # @!attribute [rw] credentials
    #   The temporary security credentials, which include an access key ID,
    #   a secret access key, and a security (or session) token.
    #
    #   <note markdown="1"> The size of the security token that STS API operations return is not
    #   fixed. We strongly recommend that you make no assumptions about the
    #   maximum size.
    #
    #    </note>
    #   @return [Types::Credentials]
    #
    # @!attribute [rw] federated_user
    #   Identifiers for the federated user associated with the credentials
    #   (such as `arn:aws:sts::123456789012:federated-user/Bob` or
    #   `123456789012:Bob`). You can use the federated user's ARN in your
    #   resource-based policies, such as an Amazon S3 bucket policy.
    #   @return [Types::FederatedUser]
    #
    # @!attribute [rw] packed_policy_size
    #   A percentage value indicating the size of the policy in packed form.
    #   The service rejects policies for which the packed size is greater
    #   than 100 percent of the allowed value.
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/GetFederationTokenResponse AWS API Documentation
    #
    class GetFederationTokenResponse < Struct.new(
      :credentials,
      :federated_user,
      :packed_policy_size)
      include Aws::Structure
    end

    # @note When making an API call, you may pass GetSessionTokenRequest
    #   data as a hash:
    #
    #       {
    #         duration_seconds: 1,
    #         serial_number: "serialNumberType",
    #         token_code: "tokenCodeType",
    #       }
    #
    # @!attribute [rw] duration_seconds
    #   The duration, in seconds, that the credentials should remain valid.
    #   Acceptable durations for IAM user sessions range from 900 seconds
    #   (15 minutes) to 129,600 seconds (36 hours), with 43,200 seconds (12
    #   hours) as the default. Sessions for AWS account owners are
    #   restricted to a maximum of 3,600 seconds (one hour). If the duration
    #   is longer than one hour, the session for AWS account owners defaults
    #   to one hour.
    #   @return [Integer]
    #
    # @!attribute [rw] serial_number
    #   The identification number of the MFA device that is associated with
    #   the IAM user who is making the `GetSessionToken` call. Specify this
    #   value if the IAM user has a policy that requires MFA authentication.
    #   The value is either the serial number for a hardware device (such as
    #   `GAHT12345678`) or an Amazon Resource Name (ARN) for a virtual
    #   device (such as `arn:aws:iam::123456789012:mfa/user`). You can find
    #   the device for an IAM user by going to the AWS Management Console
    #   and viewing the user's security credentials.
    #
    #   The regex used to validate this parameter is a string of characters
    #   consisting of upper- and lower-case alphanumeric characters with no
    #   spaces. You can also include underscores or any of the following
    #   characters: =,.@:/-
    #   @return [String]
    #
    # @!attribute [rw] token_code
    #   The value provided by the MFA device, if MFA is required. If any
    #   policy requires the IAM user to submit an MFA code, specify this
    #   value. If MFA authentication is required, the user must provide a
    #   code when requesting a set of temporary security credentials. A user
    #   who fails to provide the code receives an "access denied" response
    #   when requesting resources that require MFA authentication.
    #
    #   The format for this parameter, as described by its regex pattern, is
    #   a sequence of six numeric digits.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/GetSessionTokenRequest AWS API Documentation
    #
    class GetSessionTokenRequest < Struct.new(
      :duration_seconds,
      :serial_number,
      :token_code)
      include Aws::Structure
    end

    # Contains the response to a successful GetSessionToken request,
    # including temporary AWS credentials that can be used to make AWS
    # requests.
    #
    # @!attribute [rw] credentials
    #   The temporary security credentials, which include an access key ID,
    #   a secret access key, and a security (or session) token.
    #
    #   <note markdown="1"> The size of the security token that STS API operations return is not
    #   fixed. We strongly recommend that you make no assumptions about the
    #   maximum size.
    #
    #    </note>
    #   @return [Types::Credentials]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/GetSessionTokenResponse AWS API Documentation
    #
    class GetSessionTokenResponse < Struct.new(
      :credentials)
      include Aws::Structure
    end

    # The request could not be fulfilled because the non-AWS identity
    # provider (IDP) that was asked to verify the incoming identity token
    # could not be reached. This is often a transient error caused by
    # network conditions. Retry the request a limited number of times so
    # that you don't exceed the request rate. If the error persists, the
    # non-AWS identity provider might be down or not responding.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/IDPCommunicationErrorException AWS API Documentation
    #
    class IDPCommunicationErrorException < Struct.new(
      :message)
      include Aws::Structure
    end

    # The identity provider (IdP) reported that authentication failed. This
    # might be because the claim is invalid.
    #
    # If this error is returned for the `AssumeRoleWithWebIdentity`
    # operation, it can also mean that the claim has expired or has been
    # explicitly revoked.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/IDPRejectedClaimException AWS API Documentation
    #
    class IDPRejectedClaimException < Struct.new(
      :message)
      include Aws::Structure
    end

    # The error returned if the message passed to
    # `DecodeAuthorizationMessage` was invalid. This can happen if the token
    # contains invalid characters, such as linebreaks.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/InvalidAuthorizationMessageException AWS API Documentation
    #
    class InvalidAuthorizationMessageException < Struct.new(
      :message)
      include Aws::Structure
    end

    # The web identity token that was passed could not be validated by AWS.
    # Get a new identity token from the identity provider and then retry the
    # request.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/InvalidIdentityTokenException AWS API Documentation
    #
    class InvalidIdentityTokenException < Struct.new(
      :message)
      include Aws::Structure
    end

    # The request was rejected because the policy document was malformed.
    # The error message describes the specific error.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/MalformedPolicyDocumentException AWS API Documentation
    #
    class MalformedPolicyDocumentException < Struct.new(
      :message)
      include Aws::Structure
    end

    # The request was rejected because the policy document was too large.
    # The error message describes how big the policy document is, in packed
    # form, as a percentage of what the API allows.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/PackedPolicyTooLargeException AWS API Documentation
    #
    class PackedPolicyTooLargeException < Struct.new(
      :message)
      include Aws::Structure
    end

    # A reference to the IAM managed policy that is passed as a session
    # policy for a role session or a federated user session.
    #
    # @note When making an API call, you may pass PolicyDescriptorType
    #   data as a hash:
    #
    #       {
    #         arn: "arnType",
    #       }
    #
    # @!attribute [rw] arn
    #   The Amazon Resource Name (ARN) of the IAM managed policy to use as a
    #   session policy for the role. For more information about ARNs, see
    #   [Amazon Resource Names (ARNs) and AWS Service
    #   Namespaces](general/latest/gr/aws-arns-and-namespaces.html) in the
    #   *AWS General Reference*.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/PolicyDescriptorType AWS API Documentation
    #
    class PolicyDescriptorType < Struct.new(
      :arn)
      include Aws::Structure
    end

    # STS is not activated in the requested region for the account that is
    # being asked to generate credentials. The account administrator must
    # use the IAM console to activate STS in that region. For more
    # information, see [Activating and Deactivating AWS STS in an AWS
    # Region][1] in the *IAM User Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/RegionDisabledException AWS API Documentation
    #
    class RegionDisabledException < Struct.new(
      :message)
      include Aws::Structure
    end

  end
end
# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/master/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::STS
  # @api private
  module ClientApi

    include Seahorse::Model

    AssumeRoleRequest = Shapes::StructureShape.new(name: 'AssumeRoleRequest')
    AssumeRoleResponse = Shapes::StructureShape.new(name: 'AssumeRoleResponse')
    AssumeRoleWithSAMLRequest = Shapes::StructureShape.new(name: 'AssumeRoleWithSAMLRequest')
    AssumeRoleWithSAMLResponse = Shapes::StructureShape.new(name: 'AssumeRoleWithSAMLResponse')
    AssumeRoleWithWebIdentityRequest = Shapes::StructureShape.new(name: 'AssumeRoleWithWebIdentityRequest')
    AssumeRoleWithWebIdentityResponse = Shapes::StructureShape.new(name: 'AssumeRoleWithWebIdentityResponse')
    AssumedRoleUser = Shapes::StructureShape.new(name: 'AssumedRoleUser')
    Audience = Shapes::StringShape.new(name: 'Audience')
    Credentials = Shapes::StructureShape.new(name: 'Credentials')
    DecodeAuthorizationMessageRequest = Shapes::StructureShape.new(name: 'DecodeAuthorizationMessageRequest')
    DecodeAuthorizationMessageResponse = Shapes::StructureShape.new(name: 'DecodeAuthorizationMessageResponse')
    ExpiredTokenException = Shapes::StructureShape.new(name: 'ExpiredTokenException')
    FederatedUser = Shapes::StructureShape.new(name: 'FederatedUser')
    GetCallerIdentityRequest = Shapes::StructureShape.new(name: 'GetCallerIdentityRequest')
    GetCallerIdentityResponse = Shapes::StructureShape.new(name: 'GetCallerIdentityResponse')
    GetFederationTokenRequest = Shapes::StructureShape.new(name: 'GetFederationTokenRequest')
    GetFederationTokenResponse = Shapes::StructureShape.new(name: 'GetFederationTokenResponse')
    GetSessionTokenRequest = Shapes::StructureShape.new(name: 'GetSessionTokenRequest')
    GetSessionTokenResponse = Shapes::StructureShape.new(name: 'GetSessionTokenResponse')
    IDPCommunicationErrorException = Shapes::StructureShape.new(name: 'IDPCommunicationErrorException')
    IDPRejectedClaimException = Shapes::StructureShape.new(name: 'IDPRejectedClaimException')
    InvalidAuthorizationMessageException = Shapes::StructureShape.new(name: 'InvalidAuthorizationMessageException')
    InvalidIdentityTokenException = Shapes::StructureShape.new(name: 'InvalidIdentityTokenException')
    Issuer = Shapes::StringShape.new(name: 'Issuer')
    MalformedPolicyDocumentException = Shapes::StructureShape.new(name: 'MalformedPolicyDocumentException')
    NameQualifier = Shapes::StringShape.new(name: 'NameQualifier')
    PackedPolicyTooLargeException = Shapes::StructureShape.new(name: 'PackedPolicyTooLargeException')
    PolicyDescriptorType = Shapes::StructureShape.new(name: 'PolicyDescriptorType')
    RegionDisabledException = Shapes::StructureShape.new(name: 'RegionDisabledException')
    SAMLAssertionType = Shapes::StringShape.new(name: 'SAMLAssertionType')
    Subject = Shapes::StringShape.new(name: 'Subject')
    SubjectType = Shapes::StringShape.new(name: 'SubjectType')
    accessKeyIdType = Shapes::StringShape.new(name: 'accessKeyIdType')
    accessKeySecretType = Shapes::StringShape.new(name: 'accessKeySecretType')
    accountType = Shapes::StringShape.new(name: 'accountType')
    arnType = Shapes::StringShape.new(name: 'arnType')
    assumedRoleIdType = Shapes::StringShape.new(name: 'assumedRoleIdType')
    clientTokenType = Shapes::StringShape.new(name: 'clientTokenType')
    dateType = Shapes::TimestampShape.new(name: 'dateType')
    decodedMessageType = Shapes::StringShape.new(name: 'decodedMessageType')
    durationSecondsType = Shapes::IntegerShape.new(name: 'durationSecondsType')
    encodedMessageType = Shapes::StringShape.new(name: 'encodedMessageType')
    expiredIdentityTokenMessage = Shapes::StringShape.new(name: 'expiredIdentityTokenMessage')
    externalIdType = Shapes::StringShape.new(name: 'externalIdType')
    federatedIdType = Shapes::StringShape.new(name: 'federatedIdType')
    idpCommunicationErrorMessage = Shapes::StringShape.new(name: 'idpCommunicationErrorMessage')
    idpRejectedClaimMessage = Shapes::StringShape.new(name: 'idpRejectedClaimMessage')
    invalidAuthorizationMessage = Shapes::StringShape.new(name: 'invalidAuthorizationMessage')
    invalidIdentityTokenMessage = Shapes::StringShape.new(name: 'invalidIdentityTokenMessage')
    malformedPolicyDocumentMessage = Shapes::StringShape.new(name: 'malformedPolicyDocumentMessage')
    nonNegativeIntegerType = Shapes::IntegerShape.new(name: 'nonNegativeIntegerType')
    packedPolicyTooLargeMessage = Shapes::StringShape.new(name: 'packedPolicyTooLargeMessage')
    policyDescriptorListType = Shapes::ListShape.new(name: 'policyDescriptorListType')
    regionDisabledMessage = Shapes::StringShape.new(name: 'regionDisabledMessage')
    roleDurationSecondsType = Shapes::IntegerShape.new(name: 'roleDurationSecondsType')
    roleSessionNameType = Shapes::StringShape.new(name: 'roleSessionNameType')
    serialNumberType = Shapes::StringShape.new(name: 'serialNumberType')
    sessionPolicyDocumentType = Shapes::StringShape.new(name: 'sessionPolicyDocumentType')
    tokenCodeType = Shapes::StringShape.new(name: 'tokenCodeType')
    tokenType = Shapes::StringShape.new(name: 'tokenType')
    urlType = Shapes::StringShape.new(name: 'urlType')
    userIdType = Shapes::StringShape.new(name: 'userIdType')
    userNameType = Shapes::StringShape.new(name: 'userNameType')
    webIdentitySubjectType = Shapes::StringShape.new(name: 'webIdentitySubjectType')

    AssumeRoleRequest.add_member(:role_arn, Shapes::ShapeRef.new(shape: arnType, required: true, location_name: "RoleArn"))
    AssumeRoleRequest.add_member(:role_session_name, Shapes::ShapeRef.new(shape: roleSessionNameType, required: true, location_name: "RoleSessionName"))
    AssumeRoleRequest.add_member(:policy_arns, Shapes::ShapeRef.new(shape: policyDescriptorListType, location_name: "PolicyArns"))
    AssumeRoleRequest.add_member(:policy, Shapes::ShapeRef.new(shape: sessionPolicyDocumentType, location_name: "Policy"))
    AssumeRoleRequest.add_member(:duration_seconds, Shapes::ShapeRef.new(shape: roleDurationSecondsType, location_name: "DurationSeconds"))
    AssumeRoleRequest.add_member(:external_id, Shapes::ShapeRef.new(shape: externalIdType, location_name: "ExternalId"))
    AssumeRoleRequest.add_member(:serial_number, Shapes::ShapeRef.new(shape: serialNumberType, location_name: "SerialNumber"))
    AssumeRoleRequest.add_member(:token_code, Shapes::ShapeRef.new(shape: tokenCodeType, location_name: "TokenCode"))
    AssumeRoleRequest.struct_class = Types::AssumeRoleRequest

    AssumeRoleResponse.add_member(:credentials, Shapes::ShapeRef.new(shape: Credentials, location_name: "Credentials"))
    AssumeRoleResponse.add_member(:assumed_role_user, Shapes::ShapeRef.new(shape: AssumedRoleUser, location_name: "AssumedRoleUser"))
    AssumeRoleResponse.add_member(:packed_policy_size, Shapes::ShapeRef.new(shape: nonNegativeIntegerType, location_name: "PackedPolicySize"))
    AssumeRoleResponse.struct_class = Types::AssumeRoleResponse

    AssumeRoleWithSAMLRequest.add_member(:role_arn, Shapes::ShapeRef.new(shape: arnType, required: true, location_name: "RoleArn"))
    AssumeRoleWithSAMLRequest.add_member(:principal_arn, Shapes::ShapeRef.new(shape: arnType, required: true, location_name: "PrincipalArn"))
    AssumeRoleWithSAMLRequest.add_member(:saml_assertion, Shapes::ShapeRef.new(shape: SAMLAssertionType, required: true, location_name: "SAMLAssertion"))
    AssumeRoleWithSAMLRequest.add_member(:policy_arns, Shapes::ShapeRef.new(shape: policyDescriptorListType, location_name: "PolicyArns"))
    AssumeRoleWithSAMLRequest.add_member(:policy, Shapes::ShapeRef.new(shape: sessionPolicyDocumentType, location_name: "Policy"))
    AssumeRoleWithSAMLRequest.add_member(:duration_seconds, Shapes::ShapeRef.new(shape: roleDurationSecondsType, location_name: "DurationSeconds"))
    AssumeRoleWithSAMLRequest.struct_class = Types::AssumeRoleWithSAMLRequest

    AssumeRoleWithSAMLResponse.add_member(:credentials, Shapes::ShapeRef.new(shape: Credentials, location_name: "Credentials"))
    AssumeRoleWithSAMLResponse.add_member(:assumed_role_user, Shapes::ShapeRef.new(shape: AssumedRoleUser, location_name: "AssumedRoleUser"))
    AssumeRoleWithSAMLResponse.add_member(:packed_policy_size, Shapes::ShapeRef.new(shape: nonNegativeIntegerType, location_name: "PackedPolicySize"))
    AssumeRoleWithSAMLResponse.add_member(:subject, Shapes::ShapeRef.new(shape: Subject, location_name: "Subject"))
    AssumeRoleWithSAMLResponse.add_member(:subject_type, Shapes::ShapeRef.new(shape: SubjectType, location_name: "SubjectType"))
    AssumeRoleWithSAMLResponse.add_member(:issuer, Shapes::ShapeRef.new(shape: Issuer, location_name: "Issuer"))
    AssumeRoleWithSAMLResponse.add_member(:audience, Shapes::ShapeRef.new(shape: Audience, location_name: "Audience"))
    AssumeRoleWithSAMLResponse.add_member(:name_qualifier, Shapes::ShapeRef.new(shape: NameQualifier, location_name: "NameQualifier"))
    AssumeRoleWithSAMLResponse.struct_class = Types::AssumeRoleWithSAMLResponse

    AssumeRoleWithWebIdentityRequest.add_member(:role_arn, Shapes::ShapeRef.new(shape: arnType, required: true, location_name: "RoleArn"))
    AssumeRoleWithWebIdentityRequest.add_member(:role_session_name, Shapes::ShapeRef.new(shape: roleSessionNameType, required: true, location_name: "RoleSessionName"))
    AssumeRoleWithWebIdentityRequest.add_member(:web_identity_token, Shapes::ShapeRef.new(shape: clientTokenType, required: true, location_name: "WebIdentityToken"))
    AssumeRoleWithWebIdentityRequest.add_member(:provider_id, Shapes::ShapeRef.new(shape: urlType, location_name: "ProviderId"))
    AssumeRoleWithWebIdentityRequest.add_member(:policy_arns, Shapes::ShapeRef.new(shape: policyDescriptorListType, location_name: "PolicyArns"))
    AssumeRoleWithWebIdentityRequest.add_member(:policy, Shapes::ShapeRef.new(shape: sessionPolicyDocumentType, location_name: "Policy"))
    AssumeRoleWithWebIdentityRequest.add_member(:duration_seconds, Shapes::ShapeRef.new(shape: roleDurationSecondsType, location_name: "DurationSeconds"))
    AssumeRoleWithWebIdentityRequest.struct_class = Types::AssumeRoleWithWebIdentityRequest

    AssumeRoleWithWebIdentityResponse.add_member(:credentials, Shapes::ShapeRef.new(shape: Credentials, location_name: "Credentials"))
    AssumeRoleWithWebIdentityResponse.add_member(:subject_from_web_identity_token, Shapes::ShapeRef.new(shape: webIdentitySubjectType, location_name: "SubjectFromWebIdentityToken"))
    AssumeRoleWithWebIdentityResponse.add_member(:assumed_role_user, Shapes::ShapeRef.new(shape: AssumedRoleUser, location_name: "AssumedRoleUser"))
    AssumeRoleWithWebIdentityResponse.add_member(:packed_policy_size, Shapes::ShapeRef.new(shape: nonNegativeIntegerType, location_name: "PackedPolicySize"))
    AssumeRoleWithWebIdentityResponse.add_member(:provider, Shapes::ShapeRef.new(shape: Issuer, location_name: "Provider"))
    AssumeRoleWithWebIdentityResponse.add_member(:audience, Shapes::ShapeRef.new(shape: Audience, location_name: "Audience"))
    AssumeRoleWithWebIdentityResponse.struct_class = Types::AssumeRoleWithWebIdentityResponse

    AssumedRoleUser.add_member(:assumed_role_id, Shapes::ShapeRef.new(shape: assumedRoleIdType, required: true, location_name: "AssumedRoleId"))
    AssumedRoleUser.add_member(:arn, Shapes::ShapeRef.new(shape: arnType, required: true, location_name: "Arn"))
    AssumedRoleUser.struct_class = Types::AssumedRoleUser

    Credentials.add_member(:access_key_id, Shapes::ShapeRef.new(shape: accessKeyIdType, required: true, location_name: "AccessKeyId"))
    Credentials.add_member(:secret_access_key, Shapes::ShapeRef.new(shape: accessKeySecretType, required: true, location_name: "SecretAccessKey"))
    Credentials.add_member(:session_token, Shapes::ShapeRef.new(shape: tokenType, required: true, location_name: "SessionToken"))
    Credentials.add_member(:expiration, Shapes::ShapeRef.new(shape: dateType, required: true, location_name: "Expiration"))
    Credentials.struct_class = Types::Credentials

    DecodeAuthorizationMessageRequest.add_member(:encoded_message, Shapes::ShapeRef.new(shape: encodedMessageType, required: true, location_name: "EncodedMessage"))
    DecodeAuthorizationMessageRequest.struct_class = Types::DecodeAuthorizationMessageRequest

    DecodeAuthorizationMessageResponse.add_member(:decoded_message, Shapes::ShapeRef.new(shape: decodedMessageType, location_name: "DecodedMessage"))
    DecodeAuthorizationMessageResponse.struct_class = Types::DecodeAuthorizationMessageResponse

    ExpiredTokenException.add_member(:message, Shapes::ShapeRef.new(shape: expiredIdentityTokenMessage, location_name: "message"))
    ExpiredTokenException.struct_class = Types::ExpiredTokenException

    FederatedUser.add_member(:federated_user_id, Shapes::ShapeRef.new(shape: federatedIdType, required: true, location_name: "FederatedUserId"))
    FederatedUser.add_member(:arn, Shapes::ShapeRef.new(shape: arnType, required: true, location_name: "Arn"))
    FederatedUser.struct_class = Types::FederatedUser

    GetCallerIdentityRequest.struct_class = Types::GetCallerIdentityRequest

    GetCallerIdentityResponse.add_member(:user_id, Shapes::ShapeRef.new(shape: userIdType, location_name: "UserId"))
    GetCallerIdentityResponse.add_member(:account, Shapes::ShapeRef.new(shape: accountType, location_name: "Account"))
    GetCallerIdentityResponse.add_member(:arn, Shapes::ShapeRef.new(shape: arnType, location_name: "Arn"))
    GetCallerIdentityResponse.struct_class = Types::GetCallerIdentityResponse

    GetFederationTokenRequest.add_member(:name, Shapes::ShapeRef.new(shape: userNameType, required: true, location_name: "Name"))
    GetFederationTokenRequest.add_member(:policy, Shapes::ShapeRef.new(shape: sessionPolicyDocumentType, location_name: "Policy"))
    GetFederationTokenRequest.add_member(:policy_arns, Shapes::ShapeRef.new(shape: policyDescriptorListType, location_name: "PolicyArns"))
    GetFederationTokenRequest.add_member(:duration_seconds, Shapes::ShapeRef.new(shape: durationSecondsType, location_name: "DurationSeconds"))
    GetFederationTokenRequest.struct_class = Types::GetFederationTokenRequest

    GetFederationTokenResponse.add_member(:credentials, Shapes::ShapeRef.new(shape: Credentials, location_name: "Credentials"))
    GetFederationTokenResponse.add_member(:federated_user, Shapes::ShapeRef.new(shape: FederatedUser, location_name: "FederatedUser"))
    GetFederationTokenResponse.add_member(:packed_policy_size, Shapes::ShapeRef.new(shape: nonNegativeIntegerType, location_name: "PackedPolicySize"))
    GetFederationTokenResponse.struct_class = Types::GetFederationTokenResponse

    GetSessionTokenRequest.add_member(:duration_seconds, Shapes::ShapeRef.new(shape: durationSecondsType, location_name: "DurationSeconds"))
    GetSessionTokenRequest.add_member(:serial_number, Shapes::ShapeRef.new(shape: serialNumberType, location_name: "SerialNumber"))
    GetSessionTokenRequest.add_member(:token_code, Shapes::ShapeRef.new(shape: tokenCodeType, location_name: "TokenCode"))
    GetSessionTokenRequest.struct_class = Types::GetSessionTokenRequest

    GetSessionTokenResponse.add_member(:credentials, Shapes::ShapeRef.new(shape: Credentials, location_name: "Credentials"))
    GetSessionTokenResponse.struct_class = Types::GetSessionTokenResponse

    IDPCommunicationErrorException.add_member(:message, Shapes::ShapeRef.new(shape: idpCommunicationErrorMessage, location_name: "message"))
    IDPCommunicationErrorException.struct_class = Types::IDPCommunicationErrorException

    IDPRejectedClaimException.add_member(:message, Shapes::ShapeRef.new(shape: idpRejectedClaimMessage, location_name: "message"))
    IDPRejectedClaimException.struct_class = Types::IDPRejectedClaimException

    InvalidAuthorizationMessageException.add_member(:message, Shapes::ShapeRef.new(shape: invalidAuthorizationMessage, location_name: "message"))
    InvalidAuthorizationMessageException.struct_class = Types::InvalidAuthorizationMessageException

    InvalidIdentityTokenException.add_member(:message, Shapes::ShapeRef.new(shape: invalidIdentityTokenMessage, location_name: "message"))
    InvalidIdentityTokenException.struct_class = Types::InvalidIdentityTokenException

    MalformedPolicyDocumentException.add_member(:message, Shapes::ShapeRef.new(shape: malformedPolicyDocumentMessage, location_name: "message"))
    MalformedPolicyDocumentException.struct_class = Types::MalformedPolicyDocumentException

    PackedPolicyTooLargeException.add_member(:message, Shapes::ShapeRef.new(shape: packedPolicyTooLargeMessage, location_name: "message"))
    PackedPolicyTooLargeException.struct_class = Types::PackedPolicyTooLargeException

    PolicyDescriptorType.add_member(:arn, Shapes::ShapeRef.new(shape: arnType, location_name: "arn"))
    PolicyDescriptorType.struct_class = Types::PolicyDescriptorType

    RegionDisabledException.add_member(:message, Shapes::ShapeRef.new(shape: regionDisabledMessage, location_name: "message"))
    RegionDisabledException.struct_class = Types::RegionDisabledException

    policyDescriptorListType.member = Shapes::ShapeRef.new(shape: PolicyDescriptorType)


    # @api private
    API = Seahorse::Model::Api.new.tap do |api|

      api.version = "2011-06-15"

      api.metadata = {
        "apiVersion" => "2011-06-15",
        "endpointPrefix" => "sts",
        "globalEndpoint" => "sts.amazonaws.com",
        "protocol" => "query",
        "serviceAbbreviation" => "AWS STS",
        "serviceFullName" => "AWS Security Token Service",
        "serviceId" => "STS",
        "signatureVersion" => "v4",
        "uid" => "sts-2011-06-15",
        "xmlNamespace" => "https://sts.amazonaws.com/doc/2011-06-15/",
      }

      api.add_operation(:assume_role, Seahorse::Model::Operation.new.tap do |o|
        o.name = "AssumeRole"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: AssumeRoleRequest)
        o.output = Shapes::ShapeRef.new(shape: AssumeRoleResponse)
        o.errors << Shapes::ShapeRef.new(shape: MalformedPolicyDocumentException)
        o.errors << Shapes::ShapeRef.new(shape: PackedPolicyTooLargeException)
        o.errors << Shapes::ShapeRef.new(shape: RegionDisabledException)
      end)

      api.add_operation(:assume_role_with_saml, Seahorse::Model::Operation.new.tap do |o|
        o.name = "AssumeRoleWithSAML"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o['authtype'] = "none"
        o.input = Shapes::ShapeRef.new(shape: AssumeRoleWithSAMLRequest)
        o.output = Shapes::ShapeRef.new(shape: AssumeRoleWithSAMLResponse)
        o.errors << Shapes::ShapeRef.new(shape: MalformedPolicyDocumentException)
        o.errors << Shapes::ShapeRef.new(shape: PackedPolicyTooLargeException)
        o.errors << Shapes::ShapeRef.new(shape: IDPRejectedClaimException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidIdentityTokenException)
        o.errors << Shapes::ShapeRef.new(shape: ExpiredTokenException)
        o.errors << Shapes::ShapeRef.new(shape: RegionDisabledException)
      end)

      api.add_operation(:assume_role_with_web_identity, Seahorse::Model::Operation.new.tap do |o|
        o.name = "AssumeRoleWithWebIdentity"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o['authtype'] = "none"
        o.input = Shapes::ShapeRef.new(shape: AssumeRoleWithWebIdentityRequest)
        o.output = Shapes::ShapeRef.new(shape: AssumeRoleWithWebIdentityResponse)
        o.errors << Shapes::ShapeRef.new(shape: MalformedPolicyDocumentException)
        o.errors << Shapes::ShapeRef.new(shape: PackedPolicyTooLargeException)
        o.errors << Shapes::ShapeRef.new(shape: IDPRejectedClaimException)
        o.errors << Shapes::ShapeRef.new(shape: IDPCommunicationErrorException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidIdentityTokenException)
        o.errors << Shapes::ShapeRef.new(shape: ExpiredTokenException)
        o.errors << Shapes::ShapeRef.new(shape: RegionDisabledException)
      end)

      api.add_operation(:decode_authorization_message, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DecodeAuthorizationMessage"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: DecodeAuthorizationMessageRequest)
        o.output = Shapes::ShapeRef.new(shape: DecodeAuthorizationMessageResponse)
        o.errors << Shapes::ShapeRef.new(shape: InvalidAuthorizationMessageException)
      end)

      api.add_operation(:get_caller_identity, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetCallerIdentity"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: GetCallerIdentityRequest)
        o.output = Shapes::ShapeRef.new(shape: GetCallerIdentityResponse)
      end)

      api.add_operation(:get_federation_token, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetFederationToken"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: GetFederationTokenRequest)
        o.output = Shapes::ShapeRef.new(shape: GetFederationTokenResponse)
        o.errors << Shapes::ShapeRef.new(shape: MalformedPolicyDocumentException)
        o.errors << Shapes::ShapeRef.new(shape: PackedPolicyTooLargeException)
        o.errors << Shapes::ShapeRef.new(shape: RegionDisabledException)
      end)

      api.add_operation(:get_session_token, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetSessionToken"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: GetSessionTokenRequest)
        o.output = Shapes::ShapeRef.new(shape: GetSessionTokenResponse)
        o.errors << Shapes::ShapeRef.new(shape: RegionDisabledException)
      end)
    end

  end
end
module Aws
  # @api private
  module Plugins
    # @api private
    class CredentialsConfiguration < Seahorse::Client::Plugin

      option(:access_key_id, doc_type: String, docstring: '')

      option(:secret_access_key, doc_type: String, docstring: '')

      option(:session_token, doc_type: String, docstring: '')

      option(:profile,
        doc_default: 'default',
        doc_type: String,
        docstring: <<-DOCS)
Used when loading credentials from the shared credentials file
at HOME/.aws/credentials.  When not specified, 'default' is used.
        DOCS

      option(:credentials,
        required: true,
        doc_type: 'Aws::CredentialProvider',
        docstring: <<-DOCS
Your AWS credentials. This can be an instance of any one of the
following classes:

* `Aws::Credentials` - Used for configuring static, non-refreshing
  credentials.

* `Aws::InstanceProfileCredentials` - Used for loading credentials
  from an EC2 IMDS on an EC2 instance.

* `Aws::SharedCredentials` - Used for loading credentials from a
  shared file, such as `~/.aws/config`.

* `Aws::AssumeRoleCredentials` - Used when you need to assume a role.

When `:credentials` are not configured directly, the following
locations will be searched for credentials:

* `Aws.config[:credentials]`
* The `:access_key_id`, `:secret_access_key`, and `:session_token` options.
* ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY']
* `~/.aws/credentials`
* `~/.aws/config`
* EC2 IMDS instance profile - When used by default, the timeouts are
  very aggressive. Construct and pass an instance of
  `Aws::InstanceProfileCredentails` to enable retries and extended
  timeouts.
        DOCS
      ) do |config|
        CredentialProviderChain.new(config).resolve
      end

      option(:instance_profile_credentials_retries, 0)

      option(:instance_profile_credentials_timeout, 1)

    end
  end
end
module Aws
  module Plugins
    # @see Log::Formatter
    # @api private
    class Logging < Seahorse::Client::Plugin

      option(:logger,
        doc_type: 'Logger',
        docstring: <<-DOCS
The Logger instance to send log messages to.  If this option
is not set, logging will be disabled.
        DOCS
      )

      option(:log_level,
        default: :info,
        doc_type: Symbol,
        docstring: 'The log level to send messages to the `:logger` at.'
      )

      option(:log_formatter,
        doc_type: 'Aws::Log::Formatter',
        doc_default: literal('Aws::Log::Formatter.default'),
        docstring: 'The log formatter.'
      ) do |config|
        Log::Formatter.default if config.logger
      end

      def add_handlers(handlers, config)
        handlers.add(Handler, step: :validate) if config.logger
      end

      class Handler < Seahorse::Client::Handler

        # @param [RequestContext] context
        # @return [Response]
        def call(context)
          context[:logging_started_at] = Time.now
          @handler.call(context).tap do |response|
            context[:logging_completed_at] = Time.now
            log(context.config, response)
          end
        end

        private

        # @param [Configuration] config
        # @param [Response] response
        # @return [void]
        def log(config, response)
          config.logger.send(config.log_level, format(config, response))
        end

        # @param [Configuration] config
        # @param [Response] response
        # @return [String]
        def format(config, response)
          config.log_formatter.format(response)
        end

      end
    end
  end
end
module Aws
  module Plugins
    # @api private
    class ParamConverter < Seahorse::Client::Plugin

      option(:convert_params,
         default: true,
         doc_type: 'Boolean',
         docstring: <<-DOCS
When `true`, an attempt is made to coerce request parameters into
the required types.
         DOCS
      )

      def add_handlers(handlers, config)
        handlers.add(Handler, step: :initialize) if config.convert_params
      end

      class Handler < Seahorse::Client::Handler

        def call(context)
          converter = Aws::ParamConverter.new(context.operation.input)
          context.params = converter.convert(context.params)
          @handler.call(context).on_complete do |resp|
            converter.close_opened_files
          end
        end

      end
    end
  end
end
module Aws
  module Plugins
    # @api private
    class ParamValidator < Seahorse::Client::Plugin

      option(:validate_params,
        default: true,
        doc_type: 'Boolean',
        docstring: <<-DOCS)
When `true`, request parameters are validated before
sending the request.
      DOCS

      def add_handlers(handlers, config)
        if config.validate_params
          handlers.add(Handler, step: :validate, priority: 50)
        end
      end

      class Handler < Seahorse::Client::Handler

        def call(context)
          Aws::ParamValidator.validate!(context.operation.input, context.params)
          @handler.call(context)
        end

      end

    end
  end
end
module Aws
  module Plugins
    # @api private
    class UserAgent < Seahorse::Client::Plugin

      option(:user_agent_suffix)

      # @api private
      class Handler < Seahorse::Client::Handler

        def call(context)
          set_user_agent(context)
          @handler.call(context)
        end

        def set_user_agent(context)
          execution_env = ENV["AWS_EXECUTION_ENV"]

          ua = "aws-sdk-ruby3/#{CORE_GEM_VERSION}"

          begin
            ua += " #{RUBY_ENGINE}/#{RUBY_VERSION}"
          rescue
            ua += " RUBY_ENGINE_NA/#{RUBY_VERSION}"
          end

          ua += " #{RUBY_PLATFORM}"

          if context[:gem_name] && context[:gem_version]
            ua += " #{context[:gem_name]}/#{context[:gem_version]}"
          end

          if execution_env
            ua += " exec-env/#{execution_env}"
          end

          ua += " #{context.config.user_agent_suffix}" if context.config.user_agent_suffix

          context.http_request.headers['User-Agent'] = ua.strip
        end

      end

      handler(Handler)

    end
  end
end
module Aws
  module Plugins
    # @api private
    class HelpfulSocketErrors < Seahorse::Client::Plugin

      class Handler < Seahorse::Client::Handler

        # Wrap `SocketError` errors with `Aws::Errors::NoSuchEndpointError`
        def call(context)
          response = @handler.call(context)
          response.context.http_response.on_error do |error|
            if socket_endpoint_error?(error)
              response.error = no_such_endpoint_error(context, error)
            end
          end
          response
        end

        private

        def socket_endpoint_error?(error)
          Seahorse::Client::NetworkingError === error &&
          SocketError === error.original_error &&
          error.original_error.message.match(/failed to open tcp connection/i) &&
          error.original_error.message.match(/getaddrinfo: nodename nor servname provided, or not known/i)
        end

        def no_such_endpoint_error(context, error)
          Errors::NoSuchEndpointError.new({
            context: context,
            original_error: error.original_error,
          })
        end

      end

      handle(Handler, step: :sign)

    end
  end
end
require 'set'

module Aws
  module Plugins
    # @api private
    class RetryErrors < Seahorse::Client::Plugin

      EQUAL_JITTER = lambda { |delay| (delay / 2) + Kernel.rand(0..(delay/2))}
      FULL_JITTER= lambda { |delay| Kernel.rand(0..delay) }
      NO_JITTER = lambda { |delay| delay }

      JITTERS = {
        none: NO_JITTER,
        equal: EQUAL_JITTER,
        full: FULL_JITTER
      }

      JITTERS.default_proc = lambda { |h,k|
        raise KeyError, "#{k} is not a named jitter function. Must be one of #{h.keys}"
      }

      DEFAULT_BACKOFF = lambda do |c|
        delay = 2 ** c.retries * c.config.retry_base_delay
        delay = [delay, c.config.retry_max_delay].min if (c.config.retry_max_delay || 0) > 0
        jitter = c.config.retry_jitter
        jitter = JITTERS[jitter] if Symbol === jitter
        delay = jitter.call(delay) if jitter
        Kernel.sleep(delay)
      end

      option(:retry_limit,
        default: 3,
        doc_type: Integer,
        docstring: <<-DOCS)
The maximum number of times to retry failed requests.  Only
~ 500 level server errors and certain ~ 400 level client errors
are retried.  Generally, these are throttling errors, data
checksum errors, networking errors, timeout errors and auth
errors from expired credentials.
        DOCS

      option(:retry_max_delay,
        default: 0,
        doc_type: Integer,
        docstring: <<-DOCS)
The maximum number of seconds to delay between retries (0 for no limit) used by the default backoff function.
        DOCS

      option(:retry_base_delay,
        default: 0.3,
        doc_type: Float,
        docstring: <<-DOCS)
The base delay in seconds used by the default backoff function.
        DOCS

      option(:retry_jitter,
        default: :none,
        doc_type: Symbol,
        docstring: <<-DOCS)
A delay randomiser function used by the default backoff function. Some predefined functions can be referenced by name - :none, :equal, :full, otherwise a Proc that takes and returns a number.

@see https://www.awsarchitectureblog.com/2015/03/backoff.html
        DOCS

      option(:retry_backoff, DEFAULT_BACKOFF)

      # @api private
      class ErrorInspector

        EXPIRED_CREDS = Set.new([
          'InvalidClientTokenId',        # query services
          'UnrecognizedClientException', # json services
          'InvalidAccessKeyId',          # s3
          'AuthFailure',                 # ec2
        ])

        THROTTLING_ERRORS = Set.new([
          'Throttling',                             # query services
          'ThrottlingException',                    # json services
          'RequestThrottled',                       # sqs
          'RequestThrottledException',
          'ProvisionedThroughputExceededException', # dynamodb
          'TransactionInProgressException',         # dynamodb
          'RequestLimitExceeded',                   # ec2
          'BandwidthLimitExceeded',                 # cloud search
          'LimitExceededException',                 # kinesis
          'TooManyRequestsException',               # batch
          'PriorRequestNotComplete',                # route53
        ])

        CHECKSUM_ERRORS = Set.new([
          'CRC32CheckFailed', # dynamodb
        ])

        NETWORKING_ERRORS = Set.new([
          'RequestTimeout', # s3
        ])

        def initialize(error, http_status_code)
          @error = error
          @name = extract_name(error)
          @http_status_code = http_status_code
        end

        def expired_credentials?
          !!(EXPIRED_CREDS.include?(@name) || @name.match(/expired/i))
        end

        def throttling_error?
          !!(THROTTLING_ERRORS.include?(@name) || @name.match(/throttl/i) || @http_status_code == 429)
        end

        def checksum?
          CHECKSUM_ERRORS.include?(@name) || @error.is_a?(Errors::ChecksumError)
        end

        def networking?
          @error.is_a?(Seahorse::Client::NetworkingError) ||
          NETWORKING_ERRORS.include?(@name)
        end

        def server?
          (500..599).include?(@http_status_code)
        end

        def endpoint_discovery?(context)
          return false unless context.operation.endpoint_discovery

          if @http_status_code == 421 ||
            extract_name(@error) == 'InvalidEndpointException'
            @error = Errors::EndpointDiscoveryError.new
          end

          # When endpoint discovery error occurs
          # evict the endpoint from cache
          if @error.is_a?(Errors::EndpointDiscoveryError)
            key = context.config.endpoint_cache.extract_key(context)
            context.config.endpoint_cache.delete(key)
            true
          else
            false
          end
        end
          
        def retryable?(context)
          (expired_credentials? and refreshable_credentials?(context)) or
            throttling_error? or
            checksum? or
            networking? or
            server? or
            endpoint_discovery?(context)
        end

        private

        def refreshable_credentials?(context)
          context.config.credentials.respond_to?(:refresh!)
        end

        def extract_name(error)
          if error.is_a?(Errors::ServiceError)
            error.class.code
          else
            error.class.name.to_s
          end
        end

      end

      class Handler < Seahorse::Client::Handler

        def call(context)
          response = @handler.call(context)
          if response.error
            retry_if_possible(response)
          else
            response
          end
        end

        private

        def retry_if_possible(response)
          context = response.context
          error = error_for(response)
          if should_retry?(context, error)
            retry_request(context, error)
          else
            response
          end
        end

        def error_for(response)
          status_code = response.context.http_response.status_code
          ErrorInspector.new(response.error, status_code)
        end

        def retry_request(context, error)
          delay_retry(context)
          context.retries += 1
          context.config.credentials.refresh! if error.expired_credentials?
          context.http_request.body.rewind
          context.http_response.reset
          call(context)
        end

        def delay_retry(context)
          context.config.retry_backoff.call(context)
        end

        def should_retry?(context, error)
          error.retryable?(context) and
          context.retries < retry_limit(context) and
          response_truncatable?(context)
        end

        def retry_limit(context)
          context.config.retry_limit
        end

        def response_truncatable?(context)
          context.http_response.body.respond_to?(:truncate)
        end

      end

      def add_handlers(handlers, config)
        if config.retry_limit > 0
          handlers.add(Handler, step: :sign, priority: 99)
        end
      end

    end
  end
end
require 'set'

module Aws
  module Plugins

    # This plugin provides the ability to provide global configuration for
    # all AWS classes or specific ones.
    #
    # ## Global AWS configuration
    #
    # You can specify global configuration defaults via `Aws.config`
    #
    #     Aws.config[:region] = 'us-west-2'
    #
    # Options applied to `Aws.config` are merged with constructed
    # service interfaces.
    #
    #     # uses the global configuration
    #     Aws::EC2.new.config.region #=> 'us-west-2'
    #
    #     # constructor args have priority over global configuration
    #     Aws::EC2.new(region: 'us-east-1').config.region #=> 'us-east-1'
    #
    # ## Service Specific Global Configuration
    #
    # Some services have very specific configuration options that are not
    # shared by other services.
    #
    #     # oops, this option is only recognized by Aws::S3
    #     Aws.config[:force_path_style] = true
    #     Aws::EC2.new
    #     #=> raises ArgumentError: invalid configuration option `:force_path_style'
    #
    # To avoid this issue, you can nest service specific options
    #
    #     Aws.config[:s3] = { force_path_style: true }
    #
    #     Aws::EC2.new # no error this time
    #     Aws::S3.new.config.force_path_style #=> true
    #
    # @api private
    class GlobalConfiguration < Seahorse::Client::Plugin

      @identifiers = Set.new()

      # @api private
      def before_initialize(client_class, options)
        # apply service specific defaults before the global aws defaults
        apply_service_defaults(client_class, options)
        apply_aws_defaults(client_class, options)
      end

      private

      def apply_service_defaults(client_class, options)
        if defaults = Aws.config[client_class.identifier]
          defaults.each do |option_name, default|
            options[option_name] = default unless options.key?(option_name)
          end
        end
      end

      def apply_aws_defaults(client_class, options)
        Aws.config.each do |option_name, default|
          next if self.class.identifiers.include?(option_name)
          next if options.key?(option_name)
          options[option_name] = default
        end
      end

      class << self

        # Registers an additional service identifier.
        # @api private
        def add_identifier(identifier)
          @identifiers << identifier
        end

        # @return [Set<String>]
        # @api private
        def identifiers
          @identifiers
        end

      end
    end
  end
end
module Aws
  module Plugins
    # @api private
    class RegionalEndpoint < Seahorse::Client::Plugin

      # raised when region is not configured
      MISSING_REGION = 'missing required configuration option :region'

      option(:profile)

      option(:region,
        required: true,
        doc_type: String,
        docstring: <<-DOCS) do |cfg|
The AWS region to connect to.  The configured `:region` is
used to determine the service `:endpoint`. When not passed,
a default `:region` is search for in the following locations:

* `Aws.config[:region]`
* `ENV['AWS_REGION']`
* `ENV['AMAZON_REGION']`
* `ENV['AWS_DEFAULT_REGION']`
* `~/.aws/credentials`
* `~/.aws/config`
        DOCS
        resolve_region(cfg)
      end

      option(:regional_endpoint, false)

      option(:endpoint, doc_type: String, docstring: <<-DOCS) do |cfg|
The client endpoint is normally constructed from the `:region`
option. You should only configure an `:endpoint` when connecting
to test endpoints. This should be avalid HTTP(S) URI.
        DOCS
        endpoint_prefix = cfg.api.metadata['endpointPrefix']
        if cfg.region && endpoint_prefix
          Aws::Partitions::EndpointProvider.resolve(cfg.region, endpoint_prefix)
        end
      end

      def after_initialize(client)
        if client.config.region.nil? or client.config.region == ''
          raise Errors::MissingRegionError
        end
      end

      private

      def self.resolve_region(cfg)
        keys = %w(AWS_REGION AMAZON_REGION AWS_DEFAULT_REGION)
        env_region = ENV.values_at(*keys).compact.first
        env_region = nil if env_region == ''
        cfg_region = Aws.shared_config.region(profile: cfg.profile)
        env_region || cfg_region
      end

    end
  end
end
module Aws
  module Plugins
    # @api private
    class EndpointDiscovery < Seahorse::Client::Plugin

      option(:endpoint_discovery,
        default: false,
        doc_type: 'Boolean',
        docstring: <<-DOCS) do |cfg|
When set to `true`, endpoint discovery will be enabled for operations when available. Defaults to `false`.
        DOCS
        resolve_endpoint_discovery(cfg)
      end

      option(:endpoint_cache_max_entries,
        default: 1000,
        doc_type: Integer,
        docstring: <<-DOCS
Used for the maximum size limit of the LRU cache storing endpoints data
for endpoint discovery enabled operations. Defaults to 1000.
        DOCS
      )

      option(:endpoint_cache_max_threads,
        default: 10,
        doc_type: Integer,
        docstring: <<-DOCS
Used for the maximum threads in use for polling endpoints to be cached, defaults to 10.
        DOCS
      )

      option(:endpoint_cache_poll_interval,
        default: 60,
        doc_type: Integer,
        docstring: <<-DOCS
When :endpoint_discovery and :active_endpoint_cache is enabled,
Use this option to config the time interval in seconds for making
requests fetching endpoints information. Defaults to 60 sec.
        DOCS
      )

      option(:endpoint_cache) do |cfg|
        Aws::EndpointCache.new(
          max_entries: cfg.endpoint_cache_max_entries,
          max_threads: cfg.endpoint_cache_max_threads
        )
      end

      option(:active_endpoint_cache,
        default: false,
        doc_type: 'Boolean',
        docstring: <<-DOCS
When set to `true`, a thread polling for endpoints will be running in
the background every 60 secs (default). Defaults to `false`.
        DOCS
      )

      def add_handlers(handlers, config)
        handlers.add(Handler, priority: 90) if config.regional_endpoint
      end

      class Handler < Seahorse::Client::Handler

        def call(context)
          if context.operation.endpoint_operation
            context.http_request.headers['x-amz-api-version'] = context.config.api.version
            _apply_endpoint_discovery_user_agent(context)
          elsif discovery_cfg = context.operation.endpoint_discovery
            endpoint = _discover_endpoint(
              context,
              Aws::Util.str_2_bool(discovery_cfg["required"])
            )
            context.http_request.endpoint = _valid_uri(endpoint.address) if endpoint
            if endpoint || context.config.endpoint_discovery
              _apply_endpoint_discovery_user_agent(context)
            end
          end
          @handler.call(context)
        end

        private

        def _valid_uri(address)
          # returned address can be missing scheme
          if address.start_with?('http')
            URI.parse(address)
          else
            URI.parse("https://" + address)
          end
        end

        def _apply_endpoint_discovery_user_agent(ctx)
          if ctx.config.user_agent_suffix.nil?
            ctx.config.user_agent_suffix = "endpoint-discovery"
          elsif !ctx.config.user_agent_suffix.include? "endpoint-discovery"
            ctx.config.user_agent_suffix += "endpoint-discovery"
          end
        end

        def _discover_endpoint(ctx, required)
          cache = ctx.config.endpoint_cache 
          key = cache.extract_key(ctx)

          if required
            # required for the operation
            unless cache.key?(key)
              cache.update(key, ctx)
            end
            endpoint = cache[key]
            # hard fail if endpoint is not discovered
            raise Aws::Errors::EndpointDiscoveryError.new unless endpoint
            endpoint
          elsif ctx.config.endpoint_discovery
            # not required for the operation
            # but enabled
            if cache.key?(key)
              cache[key]
            elsif ctx.config.active_endpoint_cache
              # enabled active cache pull
              interval = ctx.config.endpoint_cache_poll_interval
              if key.include?('_')
                # identifier related, kill the previous polling thread by key
                # because endpoint req params might be changed
                cache.delete_polling_thread(key)
              end

              # start a thread for polling endpoints when non-exist
              unless cache.threads_key?(key)
                thread = Thread.new do
                  while !cache.key?(key) do
                    cache.update(key, ctx)
                    sleep(interval)
                  end
                end
                cache.update_polling_pool(key, thread)
              end

              cache[key]
            else
              # disabled active cache pull
              # attempt, buit fail soft
              cache.update(key, ctx)
              cache[key]
            end
          end
        end

      end

      private

      def self.resolve_endpoint_discovery(cfg)
        env = ENV['AWS_ENABLE_ENDPOINT_DISCOVERY']
        shared_cfg = Aws.shared_config.endpoint_discovery(profile: cfg.profile)
        Aws::Util.str_2_bool(env) || Aws::Util.str_2_bool(shared_cfg)
      end

    end
  end
end
module Aws
  module Plugins
    # @api private
    class EndpointPattern < Seahorse::Client::Plugin

      option(:disable_host_prefix_injection,
        default: false,
        doc_type: 'Boolean',
        docstring: <<-DOCS
Set to true to disable SDK automatically adding host prefix
to default service endpoint when available.
        DOCS
      )

      def add_handlers(handlers, config)
        if config.regional_endpoint && !config.disable_host_prefix_injection
          handlers.add(Handler, priority: 90)
        end
      end

      class Handler < Seahorse::Client::Handler

        def call(context)
          endpoint_trait = context.operation.endpoint_pattern
          if endpoint_trait && !endpoint_trait.empty?
            _apply_endpoint_trait(context, endpoint_trait)
          end
          @handler.call(context)
        end

        private

        def _apply_endpoint_trait(context, trait)
          # currently only support host pattern
          ori_host = context.http_request.endpoint.host
          if pattern = trait['hostPrefix']
            host_prefix = pattern.gsub(/\{.+?\}/) do |label|
              label = label.delete("{}")
              _replace_label_value(
                ori_host, label, context.operation.input, context.params)
            end
            context.http_request.endpoint.host = host_prefix + context.http_request.endpoint.host
          end
        end

        def _replace_label_value(ori, label, input_ref, params)
          name = nil
          input_ref.shape.members.each do |m_name, ref|
            if ref['hostLabel'] && ref['hostLabelName'] == label
              name = m_name
            end
          end
          if name.nil? || params[name].nil?
            raise Errors::MissingEndpointHostLabelValue.new(name)
          end
          params[name]
        end

      end

    end
  end
end
module Aws
  module Plugins
    # @api private
    class ResponsePaging < Seahorse::Client::Plugin

      class Handler < Seahorse::Client::Handler

        def call(context)
          context[:original_params] = context.params
          resp = @handler.call(context)
          resp.extend(PageableResponse)
          resp.pager = context.operation[:pager] || Aws::Pager::NullPager.new
          resp
        end

      end

      handle(Handler, step: :initialize, priority: 90)

    end
  end
end
module Aws
  module Plugins
    # @api private
    class StubResponses < Seahorse::Client::Plugin

      option(:stub_responses,
        default: false,
        doc_type: 'Boolean',
        docstring: <<-DOCS)
Causes the client to return stubbed responses. By default
fake responses are generated and returned. You can specify
the response data to return or errors to raise by calling
{ClientStubs#stub_responses}. See {ClientStubs} for more information.

** Please note ** When response stubbing is enabled, no HTTP
requests are made, and retries are disabled.
        DOCS

      option(:region) do |config|
        'us-stubbed-1' if config.stub_responses
      end

      option(:credentials) do |config|
        if config.stub_responses
          Credentials.new('stubbed-akid', 'stubbed-secret')
        end
      end

      def add_handlers(handlers, config)
        handlers.add(Handler, step: :send) if config.stub_responses
      end

      def after_initialize(client)
        if client.config.stub_responses
          client.setup_stubbing
          client.handlers.remove(RetryErrors::Handler)
          client.handlers.remove(ClientMetricsPlugin::Handler)
          client.handlers.remove(ClientMetricsSendPlugin::LatencyHandler)
          client.handlers.remove(ClientMetricsSendPlugin::AttemptHandler)
        end
      end

      class Handler < Seahorse::Client::Handler

        def call(context)
          stub = context.client.next_stub(context)
          resp = Seahorse::Client::Response.new(context: context)
          async_mode = context.client.is_a? Seahorse::Client::AsyncBase
          apply_stub(stub, resp, async_mode)

          async_mode ? Seahorse::Client::AsyncResponse.new(
            context: context, stream: context[:input_event_stream_handler].event_emitter.stream, sync_queue: Queue.new) : resp
        end

        def apply_stub(stub, response, async_mode = false)
          http_resp = response.context.http_response
          case
          when stub[:error] then signal_error(stub[:error], http_resp)
          when stub[:http] then signal_http(stub[:http], http_resp, async_mode)
          when stub[:data] then response.data = stub[:data]
          end
        end

        def signal_error(error, http_resp)
          if Exception === error
            http_resp.signal_error(error)
          else
            http_resp.signal_error(error.new)
          end
        end

        # @param [Seahorse::Client::Http::Response] stub
        # @param [Seahorse::Client::Http::Response | Seahorse::Client::Http::AsyncResponse] http_resp
        # @param [Boolean] async_mode
        def signal_http(stub, http_resp, async_mode = false)
          if async_mode
            h2_headers = stub.headers.to_h.inject([]) do |arr, (k, v)|
              arr << [k, v]
            end
            h2_headers << [":status", stub.status_code]
            http_resp.signal_headers(h2_headers)
          else
            http_resp.signal_headers(stub.status_code, stub.headers.to_h)
          end
          while chunk = stub.body.read(1024 * 1024)
            http_resp.signal_data(chunk)
          end
          stub.body.rewind
          http_resp.signal_done
        end

      end
    end
  end
end
require 'securerandom'

module Aws
  module Plugins

    # Provides support for auto filling operation parameters
    # that enabled with `idempotencyToken` trait  with random UUID v4
    # when no value is provided
    # @api private
    class IdempotencyToken < Seahorse::Client::Plugin

      # @api private
      class Handler < Seahorse::Client::Handler

        def call(context)
          auto_fill(context.params, context.operation.input)
          @handler.call(context)
        end

        private

        def auto_fill(params, ref)
          ref.shape.members.each do |name, member_ref|
            if member_ref['idempotencyToken']
              params[name] ||= SecureRandom.uuid
            end
          end
        end

      end

      handler(Handler, step: :initialize)

    end
  end
end
module Aws
  module Plugins

    # Converts input value to JSON Syntax for members with jsonvalue trait
    class JsonvalueConverter < Seahorse::Client::Plugin

      # @api private
      class Handler < Seahorse::Client::Handler

        def call(context)
          context.operation.input.shape.members.each do |m, ref|
            if ref['jsonvalue']
              param_value = context.params[m]
              unless param_value.respond_to?(:to_json)
                raise ArgumentError, "The value of params[#{m}] is not JSON serializable."
              end
              context.params[m] = param_value.to_json
            end
          end
          @handler.call(context)
        end

      end

      handler(Handler, step: :initialize)
    end

  end
end
require 'date'

module Aws
  module Plugins
    class ClientMetricsPlugin < Seahorse::Client::Plugin

      option(:client_side_monitoring,
        default: false,
        doc_type: 'Boolean',
        docstring: <<-DOCS) do |cfg|
When `true`, client-side metrics will be collected for all API requests from
this client.
      DOCS
        resolve_client_side_monitoring(cfg)
      end

      option(:client_side_monitoring_port,
        default: 31000,
        doc_type: Integer,
        docstring: <<-DOCS) do |cfg|
Required for publishing client metrics. The port that the client side monitoring
agent is running on, where client metrics will be published via UDP.
      DOCS
        resolve_client_side_monitoring_port(cfg)
      end

      option(:client_side_monitoring_publisher,
        default: ClientSideMonitoring::Publisher,
        doc_type: Aws::ClientSideMonitoring::Publisher,
        docstring: <<-DOCS) do |cfg|
Allows you to provide a custom client-side monitoring publisher class. By default,
will use the Client Side Monitoring Agent Publisher.
      DOCS
        resolve_publisher(cfg)
      end

      option(:client_side_monitoring_client_id,
        default: "",
        doc_type: String,
        docstring: <<-DOCS) do |cfg|
Allows you to provide an identifier for this client which will be attached to
all generated client side metrics. Defaults to an empty string.
        DOCS
        resolve_client_id(cfg)
      end

      def add_handlers(handlers, config)
        if config.client_side_monitoring && config.client_side_monitoring_port
          handlers.add(Handler, step: :initialize)
          publisher = config.client_side_monitoring_publisher
          publisher.agent_port = config.client_side_monitoring_port
        end
      end

      private
      def self.resolve_publisher(cfg)
        ClientSideMonitoring::Publisher.new
      end

      def self.resolve_client_side_monitoring_port(cfg)
        env_source = ENV["AWS_CSM_PORT"]
        env_source = nil if env_source == ""
        cfg_source = Aws.shared_config.csm_port(profile: cfg.profile)
        if env_source
          env_source.to_i
        elsif cfg_source
          cfg_source.to_i
        else
          31000
        end
      end

      def self.resolve_client_side_monitoring(cfg)
        env_source = ENV["AWS_CSM_ENABLED"]
        env_source = nil if env_source == ""
        if env_source.is_a?(String) && (env_source.downcase == "false" || env_source.downcase == "f")
          env_source = false
        end
        cfg_source = Aws.shared_config.csm_enabled(profile: cfg.profile)
        if env_source || cfg_source
          true
        else
          false
        end
      end

      def self.resolve_client_id(cfg)
        default = ""
        env_source = ENV["AWS_CSM_CLIENT_ID"]
        env_source = nil if env_source == ""
        cfg_source = Aws.shared_config.csm_client_id(profile: cfg.profile)
        env_source || cfg_source || default
      end

      class Handler < Seahorse::Client::Handler
        def call(context)
          publisher = context.config.client_side_monitoring_publisher
          service_id = context.config.api.metadata["serviceId"]
          # serviceId not present in all versions, need a fallback
          service_id ||= _calculate_service_id(context)

          request_metrics = ClientSideMonitoring::RequestMetrics.new(
            service: service_id,
            operation: context.operation.name,
            client_id: context.config.client_side_monitoring_client_id,
            region: context.config.region,
            timestamp: DateTime.now.strftime('%Q').to_i,
          )
          context.metadata[:client_metrics] = request_metrics
          start_time = Aws::Util.monotonic_milliseconds
          final_error_retryable = false
          final_aws_exception = nil
          final_aws_exception_message = nil
          final_sdk_exception = nil
          final_sdk_exception_message = nil
          begin
            @handler.call(context)
          rescue StandardError => e
            # Handle SDK Exceptions
            inspector = Aws::Plugins::RetryErrors::ErrorInspector.new(
              e,
              context.http_response.status_code
            )
            if inspector.retryable?(context)
              final_error_retryable = true
            end
            if request_metrics.api_call_attempts.empty?
              attempt = request_metrics.build_call_attempt
              attempt.sdk_exception = e.class.to_s
              attempt.sdk_exception_msg = e.message
              request_metrics.add_call_attempt(attempt)
            elsif request_metrics.api_call_attempts.last.aws_exception.nil?
              # Handle exceptions during response handlers
              attempt = request_metrics.api_call_attempts.last
              attempt.sdk_exception = e.class.to_s
              attempt.sdk_exception_msg = e.message
            elsif !e.class.to_s.match(request_metrics.api_call_attempts.last.aws_exception)
              # Handle response handling exceptions that happened in addition to
              # an AWS exception
              attempt = request_metrics.api_call_attempts.last
              attempt.sdk_exception = e.class.to_s
              attempt.sdk_exception_msg = e.message
            end # Else we don't have an SDK exception and are done.
            final_attempt = request_metrics.api_call_attempts.last
            final_aws_exception = final_attempt.aws_exception
            final_aws_exception_message = final_attempt.aws_exception_msg
            final_sdk_exception = final_attempt.sdk_exception
            final_sdk_exception_message = final_attempt.sdk_exception_msg
            raise e
          ensure
            end_time = Aws::Util.monotonic_milliseconds
            complete_opts = {
              latency: end_time - start_time,
              attempt_count: context.retries + 1,
              user_agent: context.http_request.headers["user-agent"],
              final_error_retryable: final_error_retryable,
              final_http_status_code: context.http_response.status_code,
              final_aws_exception: final_aws_exception,
              final_aws_exception_message: final_aws_exception_message,
              final_sdk_exception: final_sdk_exception,
              final_sdk_exception_message: final_sdk_exception_message
            }
            if context.metadata[:redirect_region]
              complete_opts[:region] = context.metadata[:redirect_region]
            end
            request_metrics.api_call.complete(complete_opts)
            # Report the metrics by passing the complete RequestMetrics object
            if publisher
              publisher.publish(request_metrics)
            end # Else we drop all this on the floor.
          end
        end

        private
        def _calculate_service_id(context)
          class_name = context.client.class.to_s.match(/(.+)::Client/)[1]
          class_name.sub!(/^Aws::/, '')
          _fallback_service_id(class_name)
        end

        def _fallback_service_id(id)
          # Need hard-coded exceptions since information needed to
          # reverse-engineer serviceId is not present in older versions.
          # This list should not need to grow.
          exceptions = {
            "ACMPCA" => "ACM PCA",
            "APIGateway" => "API Gateway",
            "AlexaForBusiness" => "Alexa For Business",
            "ApplicationAutoScaling" => "Application Auto Scaling",
            "ApplicationDiscoveryService" => "Application Discovery Service",
            "AutoScaling" => "Auto Scaling",
            "AutoScalingPlans" => "Auto Scaling Plans",
            "CloudHSMV2" => "CloudHSM V2",
            "CloudSearchDomain" => "CloudSearch Domain",
            "CloudWatchEvents" => "CloudWatch Events",
            "CloudWatchLogs" => "CloudWatch Logs",
            "CognitoIdentity" => "Cognito Identity",
            "CognitoIdentityProvider" => "Cognito Identity Provider",
            "CognitoSync" => "Cognito Sync",
            "ConfigService" => "Config Service",
            "CostExplorer" => "Cost Explorer",
            "CostandUsageReportService" => "Cost and Usage Report Service",
            "DataPipeline" => "Data Pipeline",
            "DatabaseMigrationService" => "Database Migration Service",
            "DeviceFarm" => "Device Farm",
            "DirectConnect" => "Direct Connect",
            "DirectoryService" => "Directory Service",
            "DynamoDBStreams" => "DynamoDB Streams",
            "ElasticBeanstalk" => "Elastic Beanstalk",
            "ElasticLoadBalancing" => "Elastic Load Balancing",
            "ElasticLoadBalancingV2" => "Elastic Load Balancing v2",
            "ElasticTranscoder" => "Elastic Transcoder",
            "ElasticsearchService" => "Elasticsearch Service",
            "IoTDataPlane" => "IoT Data Plane",
            "IoTJobsDataPlane" => "IoT Jobs Data Plane",
            "IoT1ClickDevicesService" => "IoT 1Click Devices Service",
            "IoT1ClickProjects" => "IoT 1Click Projects",
            "KinesisAnalytics" => "Kinesis Analytics",
            "KinesisVideo" => "Kinesis Video",
            "KinesisVideoArchivedMedia" => "Kinesis Video Archived Media",
            "KinesisVideoMedia" => "Kinesis Video Media",
            "LambdaPreview" => "Lambda",
            "Lex" => "Lex Runtime Service",
            "LexModelBuildingService" => "Lex Model Building Service",
            "Lightsail" => "Lightsail",
            "MQ" => "mq",
            "MachineLearning" => "Machine Learning",
            "MarketplaceCommerceAnalytics" => "Marketplace Commerce Analytics",
            "MarketplaceEntitlementService" => "Marketplace Entitlement Service",
            "MarketplaceMetering" => "Marketplace Metering",
            "MediaStoreData" => "MediaStore Data",
            "MigrationHub" => "Migration Hub",
            "ResourceGroups" => "Resource Groups",
            "ResourceGroupsTaggingAPI" => "Resource Groups Tagging API",
            "Route53" => "Route 53",
            "Route53Domains" => "Route 53 Domains",
            "SecretsManager" => "Secrets Manager",
            "SageMakerRuntime" => "SageMaker Runtime",
            "ServiceCatalog" => "Service Catalog",
            "ServiceDiscovery" => "ServiceDiscovery",
            "Signer" => "signer",
            "States" => "SFN",
            "StorageGateway" => "Storage Gateway",
            "TranscribeService" => "Transcribe Service",
            "WAFRegional" => "WAF Regional",
          }
          if exceptions[id]
            exceptions[id]
          else
            id
          end
        end
      end
    end
  end
end
require 'date'

module Aws
  module Plugins
    class ClientMetricsSendPlugin < Seahorse::Client::Plugin

      def add_handlers(handlers, config)
        if config.client_side_monitoring && config.client_side_monitoring_port
          # AttemptHandler comes just before we would retry an error.
          # Or before we would follow redirects.
          handlers.add(AttemptHandler, step: :sign, priority: 39)
          # LatencyHandler is as close to sending as possible.
          handlers.add(LatencyHandler, step: :sign, priority: 0)
        end
      end

      class LatencyHandler < Seahorse::Client::Handler
        def call(context)
          start_time = Aws::Util.monotonic_milliseconds
          resp = @handler.call(context)
          end_time = Aws::Util.monotonic_milliseconds
          latency = end_time - start_time
          context.metadata[:current_call_attempt].request_latency = latency
          resp
        end
      end

      class AttemptHandler < Seahorse::Client::Handler
        def call(context)
          request_metrics = context.metadata[:client_metrics]
          attempt_opts = {
            timestamp: DateTime.now.strftime('%Q').to_i,
            fqdn: context.http_request.endpoint.host,
            region: context.config.region,
            user_agent: context.http_request.headers["user-agent"],
          }
          # It will generally cause an error, but it is semantically valid for
          # credentials to not exist.
          if context.config.credentials
            attempt_opts[:access_key] =
              context.config.credentials.credentials.access_key_id
            attempt_opts[:session_token] =
              context.config.credentials.credentials.session_token
          end
          call_attempt = request_metrics.build_call_attempt(attempt_opts)
          context.metadata[:current_call_attempt] = call_attempt

          resp = @handler.call(context)
          if context.metadata[:redirect_region]
            call_attempt.region = context.metadata[:redirect_region]
          end
          headers = context.http_response.headers
          if headers.include?("x-amz-id-2")
            call_attempt.x_amz_id_2 = headers["x-amz-id-2"]
          end
          if headers.include?("x-amz-request-id")
            call_attempt.x_amz_request_id = headers["x-amz-request-id"]
          end
          if headers.include?("x-amzn-request-id")
            call_attempt.x_amzn_request_id = headers["x-amzn-request-id"]
          end
          call_attempt.http_status_code = context.http_response.status_code
          if e = resp.error
            e_name = _extract_error_name(e)
            e_msg = e.message
            call_attempt.aws_exception = "#{e_name}"
            call_attempt.aws_exception_msg = "#{e_msg}"
          end
          request_metrics.add_call_attempt(call_attempt)
          resp
        end

        private
        def _extract_error_name(error)
          if error.is_a?(Aws::Errors::ServiceError)
            error.class.code
          else
            error.class.name.to_s
          end
        end
      end
    end
  end
end
module Aws
  module Plugins

    # For Streaming Input Operations, when `requiresLength` is enabled
    # checking whether `Content-Length` header can be set,
    # for `v4-unsigned-body` operations, set `Transfer-Encoding` header
    class TransferEncoding < Seahorse::Client::Plugin

      # @api private
      class Handler < Seahorse::Client::Handler

        def call(context)
          if streaming?(context.operation.input)
            begin
              context.http_request.body.size
            rescue
              if requires_length?(context.operation.input)
                # if size of the IO is not available but required
                raise Aws::Errors::MissingContentLength.new
              elsif context.operation['authtype'] == "v4-unsigned-body"
                context.http_request.headers['Transfer-Encoding'] = 'chunked'
              end
            end
          end

          @handler.call(context)
        end

        private

        def streaming?(ref)
          if payload = ref[:payload_member]
            payload["streaming"] || # checking ref and shape
              payload.shape["streaming"]
          else
            false
          end
        end

        def requires_length?(ref)
          payload = ref[:payload_member]
          payload["requiresLength"] || # checking ref and shape
            payload.shape["requiresLength"]
        end

      end

      handler(Handler, step: :sign)

    end

  end
end

module Aws
  module Plugins
    # @api private
    class SignatureV4 < Seahorse::Client::Plugin

      option(:sigv4_signer) do |cfg|
        SignatureV4.build_signer(cfg)
      end

      option(:sigv4_name) do |cfg|
        cfg.api.metadata['signingName'] || cfg.api.metadata['endpointPrefix']
      end

      option(:sigv4_region) do |cfg|

        # The signature version 4 signing region is most
        # commonly the configured region. There are a few
        # notable exceptions:
        #
        # * Some services have a global endpoint to the entire
        #   partition. For example, when constructing a route53
        #   client for a region like "us-west-2", we will
        #   always use "route53.amazonaws.com". This endpoint
        #   is actually global to the entire partition,
        #   and must be signed as "us-east-1".
        #
        # * When the region is configured, but it is configured
        #   to a non region, such as "aws-global". This is similar
        #   to the previous case. We use the Aws::Partitions::EndpointProvider
        #   to resolve to the actual signing region.
        #
        prefix = cfg.api.metadata['endpointPrefix']
        if prefix && cfg.endpoint.to_s.match(/#{prefix}\.amazonaws\.com/)
          'us-east-1'
        elsif cfg.region
          Aws::Partitions::EndpointProvider.signing_region(cfg.region, cfg.sigv4_name)
        end
      end

      option(:unsigned_operations) do |cfg|
        cfg.api.operation_names.inject([]) do |unsigned, operation_name|
          if cfg.api.operation(operation_name)['authtype'] == 'none' ||
            cfg.api.operation(operation_name)['authtype'] == 'custom'
            # Unsign requests that has custom apigateway authorizer as well
            unsigned << operation_name
          else
            unsigned
          end
        end
      end

      def add_handlers(handlers, cfg)
        if cfg.unsigned_operations.empty?
          handlers.add(Handler, step: :sign)
        else
          operations = cfg.api.operation_names - cfg.unsigned_operations
          handlers.add(Handler, step: :sign, operations: operations)
        end
      end

      class Handler < Seahorse::Client::Handler
        def call(context)
          SignatureV4.apply_signature(context: context)
          @handler.call(context)
        end
      end

      class MissingCredentialsSigner
        def sign_request(*args)
          raise Errors::MissingCredentialsError
        end
      end

      class << self

        # @api private
        def build_signer(cfg)
          if cfg.credentials && cfg.sigv4_region
            Aws::Sigv4::Signer.new(
              service: cfg.sigv4_name,
              region: cfg.sigv4_region,
              credentials_provider: cfg.credentials,
              unsigned_headers: ['content-length', 'user-agent', 'x-amzn-trace-id']
            )
          elsif cfg.credentials
            raise Errors::MissingRegionError
          elsif cfg.sigv4_region
            # Instead of raising now, we return a signer that raises only
            # if you attempt to sign a request. Some services have unsigned
            # operations and it okay to initialize clients for these services
            # without credentials. Unsigned operations have an "authtype"
            # trait of "none".
            MissingCredentialsSigner.new
          end
        end

        # @api private
        def apply_signature(options = {})
          context = apply_authtype(options[:context])
          signer = options[:signer] || context.config.sigv4_signer
          req = context.http_request

          # in case this request is being re-signed
          req.headers.delete('Authorization')
          req.headers.delete('X-Amz-Security-Token')
          req.headers.delete('X-Amz-Date')

          # compute the signature
          begin
            signature = signer.sign_request(
              http_method: req.http_method,
              url: req.endpoint,
              headers: req.headers,
              body: req.body
            )
          rescue Aws::Sigv4::Errors::MissingCredentialsError
            raise Aws::Errors::MissingCredentialsError
          end

          # apply signature headers
          req.headers.update(signature.headers)

          # add request metadata with signature components for debugging
          context[:canonical_request] = signature.canonical_request
          context[:string_to_sign] = signature.string_to_sign
        end

        # @api private
        def apply_authtype(context)
          if context.operation['authtype'].eql?('v4-unsigned-body') &&
            context.http_request.endpoint.scheme.eql?('https')
            context.http_request.headers['X-Amz-Content-Sha256'] = 'UNSIGNED-PAYLOAD'
          end
          context
        end
      end
    end
  end
end
require 'base64'

module Aws
  module Query
    class EC2ParamBuilder

      include Seahorse::Model::Shapes

      def initialize(param_list)
        @params = param_list
      end

      attr_reader :params

      def apply(ref, params)
        structure(ref, params, '')
      end

      private

      def structure(ref, values, prefix)
        shape = ref.shape
        values.each_pair do |name, value|
          unless value.nil?
            member_ref = shape.member(name)
            format(member_ref, value, prefix + query_name(member_ref))
          end
        end
      end

      def list(ref, values, prefix)
        if values.empty?
          set(prefix, '')
        else
          member_ref = ref.shape.member
          values.each.with_index do |value, n|
            format(member_ref, value, "#{prefix}.#{n+1}")
          end
        end
      end

      def format(ref, value, prefix)
        case ref.shape
        when StructureShape then structure(ref, value, prefix + '.')
        when ListShape      then list(ref, value, prefix)
        when MapShape       then raise NotImplementedError
        when BlobShape      then set(prefix, blob(value))
        when TimestampShape then set(prefix, timestamp(ref, value))
        else
          set(prefix, value.to_s)
        end
      end

      def query_name(ref)
        ref['queryName'] || ucfirst(ref.location_name)
      end

      def set(name, value)
        params.set(name, value)
      end

      def ucfirst(str)
        str[0].upcase + str[1..-1]
      end

      def blob(value)
        value = value.read unless String === value
        Base64.strict_encode64(value)
      end

      def timestamp(ref, value)
        case ref['timestampFormat'] || ref.shape['timestampFormat']
        when 'unixTimestamp' then value.to_i
        when 'rfc822' then value.utc.httpdate
        else
          # ec2 defaults to iso8601
          value.utc.iso8601
        end
      end

    end
  end
end
module Aws
  # @api private
  module Query
    class Handler < Seahorse::Client::Handler

      include Seahorse::Model::Shapes

      CONTENT_TYPE = 'application/x-www-form-urlencoded; charset=utf-8'

      WRAPPER_STRUCT = ::Struct.new(:result, :response_metadata)

      METADATA_STRUCT = ::Struct.new(:request_id)

      METADATA_REF = begin
        request_id = ShapeRef.new(
          shape: StringShape.new,
          location_name: 'RequestId')
        response_metadata = StructureShape.new
        response_metadata.struct_class = METADATA_STRUCT
        response_metadata.add_member(:request_id, request_id)
        ShapeRef.new(shape: response_metadata, location_name: 'ResponseMetadata')
      end

      # @param [Seahorse::Client::RequestContext] context
      # @return [Seahorse::Client::Response]
      def call(context)
        build_request(context)
        @handler.call(context).on_success do |response|
          response.error = nil
          parsed = parse_xml(context)
          if parsed.nil? || parsed == EmptyStructure
            response.data = EmptyStructure.new
          else
            response.data = parsed
          end
        end
      end

      private

      def build_request(context)
        context.http_request.http_method = 'POST'
        context.http_request.headers['Content-Type'] = CONTENT_TYPE
        param_list = ParamList.new
        param_list.set('Version', context.config.api.version)
        param_list.set('Action', context.operation.name)
        if input_shape = context.operation.input
          apply_params(param_list, context.params, input_shape)
        end
        context.http_request.body = param_list.to_io
      end

      def apply_params(param_list, params, rules)
        ParamBuilder.new(param_list).apply(rules, params)
      end

      def parse_xml(context)
        data = Xml::Parser.new(rules(context)).parse(xml(context))
        remove_wrapper(data, context)
      end

      def xml(context)
        context.http_response.body_contents
      end

      def rules(context)
        shape = Seahorse::Model::Shapes::StructureShape.new
        if context.operation.output
          shape.add_member(:result, ShapeRef.new(
            shape: context.operation.output.shape,
            location_name: context.operation.name + 'Result'
          ))
        end
        shape.struct_class = WRAPPER_STRUCT
        shape.add_member(:response_metadata, METADATA_REF)
        ShapeRef.new(shape: shape)
      end

      def remove_wrapper(data, context)
        if context.operation.output
          if data.response_metadata
            context[:request_id] = data.response_metadata.request_id
          end
          data.result || Structure.new(*context.operation.output.shape.member_names)
        else
          data
        end
      end

    end
  end
end
module Aws
  module Query
    class Param

      # @param [String] name
      # @param [String, nil] value (nil)
      def initialize(name, value = nil)
        @name = name.to_s
        @value = value
      end

      # @return [String]
      attr_reader :name

      # @return [String, nil]
      attr_reader :value

      # @return [String]
      def to_s
        value ? "#{escape(name)}=#{escape(value)}" : "#{escape(name)}="
      end

      # @api private
      def ==(other)
        other.kind_of?(Param) &&
        other.name == name &&
        other.value == value
      end

      # @api private
      def <=> other
        name <=> other.name
      end

      private

      def escape(str)
        Seahorse::Util.uri_escape(str)
      end

    end
  end
end
require 'base64'

module Aws
  module Query
    class ParamBuilder

      include Seahorse::Model::Shapes

      def initialize(param_list)
        @params = param_list
      end

      attr_reader :params

      def apply(ref, params)
        structure(ref, params, '')
      end

      private

      def structure(ref, values, prefix)
        shape = ref.shape
        values.each_pair do |name, value|
          next if value.nil?
          member_ref = shape.member(name)
          format(member_ref, value, prefix + query_name(member_ref))
        end
      end

      def list(ref, values, prefix)
        member_ref = ref.shape.member
        if values.empty?
          set(prefix, '')
          return
        end
        if flat?(ref)
          if name = query_name(member_ref)
            parts = prefix.split('.')
            parts.pop
            parts.push(name)
            prefix = parts.join('.')
          end
        else
          prefix += '.' + (member_ref.location_name || 'member')
        end
        values.each.with_index do |value, n|
          format(member_ref, value, "#{prefix}.#{n+1}")
        end
      end

      def map(ref, values, prefix)
        key_ref = ref.shape.key
        value_ref = ref.shape.value
        prefix += '.entry' unless flat?(ref)
        key_name = "%s.%d.#{query_name(key_ref, 'key')}"
        value_name  = "%s.%d.#{query_name(value_ref, 'value')}"
        values.each.with_index do |(key, value), n|
          format(key_ref, key, key_name % [prefix, n + 1])
          format(value_ref, value, value_name % [prefix, n + 1])
        end
      end

      def format(ref, value, prefix)
        case ref.shape
        when StructureShape then structure(ref, value, prefix + '.')
        when ListShape      then list(ref, value, prefix)
        when MapShape       then map(ref, value, prefix)
        when BlobShape      then set(prefix, blob(value))
        when TimestampShape then set(prefix, timestamp(ref, value))
        else set(prefix, value.to_s)
        end
      end

      def query_name(ref, default = nil)
        ref.location_name || default
      end

      def set(name, value)
        params.set(name, value)
      end

      def flat?(ref)
        ref.shape.flattened
      end

      def timestamp(ref, value)
        case ref['timestampFormat'] || ref.shape['timestampFormat']
        when 'unixTimestamp' then value.to_i
        when 'rfc822' then value.utc.httpdate
        else
          # query defaults to iso8601
          value.utc.iso8601
        end
      end

      def blob(value)
        value = value.read unless String === value
        Base64.strict_encode64(value)
      end

    end
  end
end
require 'stringio'

module Aws
  module Query
    class ParamList

      include Enumerable

      # @api private
      def initialize
        @params = {}
      end

      # @param [String] param_name
      # @param [String, nil] param_value
      # @return [Param]
      def set(param_name, param_value = nil)
        param = Param.new(param_name, param_value)
        @params[param.name] = param
        param
      end
      alias []= set

      # @return [Param, nil]
      def [](param_name)
        @params[param_name.to_s]
      end

      # @param [String] param_name
      # @return [Param, nil]
      def delete(param_name)
        @params.delete(param_name)
      end

      # @return [Enumerable]
      def each(&block)
        to_a.each(&block)
      end

      # @return [Boolean]
      def empty?
        @params.empty?
      end

      # @return [Array<Param>] Returns an array of sorted {Param} objects.
      def to_a
        @params.values.sort
      end

      # @return [String]
      def to_s
        to_a.map(&:to_s).join('&')
      end

      # @return [#read, #rewind, #size]
      def to_io
        IoWrapper.new(self)
      end

      # @api private
      class IoWrapper

        # @param [ParamList] param_list
        def initialize(param_list)
          @param_list = param_list
          @io = StringIO.new(param_list.to_s)
        end

        # @return [ParamList]
        attr_reader :param_list

        # @return [Integer]
        def size
          @io.size
        end

        # @return [void]
        def rewind
          @io.rewind
        end

        # @return [String, nil]
        def read(bytes = nil, output_buffer = nil)
          @io.read(bytes, output_buffer)
        end

      end

    end
  end
end
# KG-dev::RubyPacker replaced for query/ec2_param_builder.rb
# KG-dev::RubyPacker replaced for query/handler.rb
# KG-dev::RubyPacker replaced for query/param.rb
# KG-dev::RubyPacker replaced for query/param_builder.rb
# KG-dev::RubyPacker replaced for query/param_list.rb
# KG-dev::RubyPacker replaced for ../../query.rb

module Aws
  module Plugins
    module Protocols
      class Query < Seahorse::Client::Plugin
        handler(Aws::Query::Handler)
        handler(Xml::ErrorHandler, step: :sign)
      end
    end
  end
end

# Cesium: Manually replaced aws-sdk-core/plugins/protocols/json_prc.rb
module Aws
  module Plugins
    module Protocols
      class JsonRpc < Seahorse::Client::Plugin

        option(:simple_json,
          default: false,
          doc_type: 'Boolean',
          docstring: <<-DOCS)
Disables request parameter conversion, validation, and formatting.
Also disable response data type conversions. This option is useful
when you want to ensure the highest level of performance by
avoiding overhead of walking request parameters and response data
structures.

When `:simple_json` is enabled, the request parameters hash must
be formatted exactly as the DynamoDB API expects.
          DOCS

        option(:validate_params) { |config| !config.simple_json }

        option(:convert_params) { |config| !config.simple_json }

        handler(Json::Handler)

        handler(Json::ErrorHandler, step: :sign)

      end
    end
  end
end

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/master/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

# KG-dev::RubyPacker replaced for seahorse/client/plugins/content_length.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/plugins/credentials_configuration.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/plugins/logging.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/plugins/param_converter.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/plugins/param_validator.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/plugins/user_agent.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/plugins/helpful_socket_errors.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/plugins/retry_errors.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/plugins/global_configuration.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/plugins/regional_endpoint.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/plugins/endpoint_discovery.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/plugins/endpoint_pattern.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/plugins/response_paging.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/plugins/stub_responses.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/plugins/idempotency_token.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/plugins/jsonvalue_converter.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/plugins/client_metrics_plugin.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/plugins/client_metrics_send_plugin.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/plugins/transfer_encoding.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/plugins/signature_v4.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/plugins/protocols/query.rb

Aws::Plugins::GlobalConfiguration.add_identifier(:sts)

module Aws::STS
  class Client < Seahorse::Client::Base

    include Aws::ClientStubs

    @identifier = :sts

    set_api(ClientApi::API)

    add_plugin(Seahorse::Client::Plugins::ContentLength)
    add_plugin(Aws::Plugins::CredentialsConfiguration)
    add_plugin(Aws::Plugins::Logging)
    add_plugin(Aws::Plugins::ParamConverter)
    add_plugin(Aws::Plugins::ParamValidator)
    add_plugin(Aws::Plugins::UserAgent)
    add_plugin(Aws::Plugins::HelpfulSocketErrors)
    add_plugin(Aws::Plugins::RetryErrors)
    add_plugin(Aws::Plugins::GlobalConfiguration)
    add_plugin(Aws::Plugins::RegionalEndpoint)
    add_plugin(Aws::Plugins::EndpointDiscovery)
    add_plugin(Aws::Plugins::EndpointPattern)
    add_plugin(Aws::Plugins::ResponsePaging)
    add_plugin(Aws::Plugins::StubResponses)
    add_plugin(Aws::Plugins::IdempotencyToken)
    add_plugin(Aws::Plugins::JsonvalueConverter)
    add_plugin(Aws::Plugins::ClientMetricsPlugin)
    add_plugin(Aws::Plugins::ClientMetricsSendPlugin)
    add_plugin(Aws::Plugins::TransferEncoding)
    add_plugin(Aws::Plugins::SignatureV4)
    add_plugin(Aws::Plugins::Protocols::Query)

    # @overload initialize(options)
    #   @param [Hash] options
    #   @option options [required, Aws::CredentialProvider] :credentials
    #     Your AWS credentials. This can be an instance of any one of the
    #     following classes:
    #
    #     * `Aws::Credentials` - Used for configuring static, non-refreshing
    #       credentials.
    #
    #     * `Aws::InstanceProfileCredentials` - Used for loading credentials
    #       from an EC2 IMDS on an EC2 instance.
    #
    #     * `Aws::SharedCredentials` - Used for loading credentials from a
    #       shared file, such as `~/.aws/config`.
    #
    #     * `Aws::AssumeRoleCredentials` - Used when you need to assume a role.
    #
    #     When `:credentials` are not configured directly, the following
    #     locations will be searched for credentials:
    #
    #     * `Aws.config[:credentials]`
    #     * The `:access_key_id`, `:secret_access_key`, and `:session_token` options.
    #     * ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY']
    #     * `~/.aws/credentials`
    #     * `~/.aws/config`
    #     * EC2 IMDS instance profile - When used by default, the timeouts are
    #       very aggressive. Construct and pass an instance of
    #       `Aws::InstanceProfileCredentails` to enable retries and extended
    #       timeouts.
    #
    #   @option options [required, String] :region
    #     The AWS region to connect to.  The configured `:region` is
    #     used to determine the service `:endpoint`. When not passed,
    #     a default `:region` is search for in the following locations:
    #
    #     * `Aws.config[:region]`
    #     * `ENV['AWS_REGION']`
    #     * `ENV['AMAZON_REGION']`
    #     * `ENV['AWS_DEFAULT_REGION']`
    #     * `~/.aws/credentials`
    #     * `~/.aws/config`
    #
    #   @option options [String] :access_key_id
    #
    #   @option options [Boolean] :active_endpoint_cache (false)
    #     When set to `true`, a thread polling for endpoints will be running in
    #     the background every 60 secs (default). Defaults to `false`.
    #
    #   @option options [Boolean] :client_side_monitoring (false)
    #     When `true`, client-side metrics will be collected for all API requests from
    #     this client.
    #
    #   @option options [String] :client_side_monitoring_client_id ("")
    #     Allows you to provide an identifier for this client which will be attached to
    #     all generated client side metrics. Defaults to an empty string.
    #
    #   @option options [Integer] :client_side_monitoring_port (31000)
    #     Required for publishing client metrics. The port that the client side monitoring
    #     agent is running on, where client metrics will be published via UDP.
    #
    #   @option options [Aws::ClientSideMonitoring::Publisher] :client_side_monitoring_publisher (Aws::ClientSideMonitoring::Publisher)
    #     Allows you to provide a custom client-side monitoring publisher class. By default,
    #     will use the Client Side Monitoring Agent Publisher.
    #
    #   @option options [Boolean] :convert_params (true)
    #     When `true`, an attempt is made to coerce request parameters into
    #     the required types.
    #
    #   @option options [Boolean] :disable_host_prefix_injection (false)
    #     Set to true to disable SDK automatically adding host prefix
    #     to default service endpoint when available.
    #
    #   @option options [String] :endpoint
    #     The client endpoint is normally constructed from the `:region`
    #     option. You should only configure an `:endpoint` when connecting
    #     to test endpoints. This should be avalid HTTP(S) URI.
    #
    #   @option options [Integer] :endpoint_cache_max_entries (1000)
    #     Used for the maximum size limit of the LRU cache storing endpoints data
    #     for endpoint discovery enabled operations. Defaults to 1000.
    #
    #   @option options [Integer] :endpoint_cache_max_threads (10)
    #     Used for the maximum threads in use for polling endpoints to be cached, defaults to 10.
    #
    #   @option options [Integer] :endpoint_cache_poll_interval (60)
    #     When :endpoint_discovery and :active_endpoint_cache is enabled,
    #     Use this option to config the time interval in seconds for making
    #     requests fetching endpoints information. Defaults to 60 sec.
    #
    #   @option options [Boolean] :endpoint_discovery (false)
    #     When set to `true`, endpoint discovery will be enabled for operations when available. Defaults to `false`.
    #
    #   @option options [Aws::Log::Formatter] :log_formatter (Aws::Log::Formatter.default)
    #     The log formatter.
    #
    #   @option options [Symbol] :log_level (:info)
    #     The log level to send messages to the `:logger` at.
    #
    #   @option options [Logger] :logger
    #     The Logger instance to send log messages to.  If this option
    #     is not set, logging will be disabled.
    #
    #   @option options [String] :profile ("default")
    #     Used when loading credentials from the shared credentials file
    #     at HOME/.aws/credentials.  When not specified, 'default' is used.
    #
    #   @option options [Float] :retry_base_delay (0.3)
    #     The base delay in seconds used by the default backoff function.
    #
    #   @option options [Symbol] :retry_jitter (:none)
    #     A delay randomiser function used by the default backoff function. Some predefined functions can be referenced by name - :none, :equal, :full, otherwise a Proc that takes and returns a number.
    #
    #     @see https://www.awsarchitectureblog.com/2015/03/backoff.html
    #
    #   @option options [Integer] :retry_limit (3)
    #     The maximum number of times to retry failed requests.  Only
    #     ~ 500 level server errors and certain ~ 400 level client errors
    #     are retried.  Generally, these are throttling errors, data
    #     checksum errors, networking errors, timeout errors and auth
    #     errors from expired credentials.
    #
    #   @option options [Integer] :retry_max_delay (0)
    #     The maximum number of seconds to delay between retries (0 for no limit) used by the default backoff function.
    #
    #   @option options [String] :secret_access_key
    #
    #   @option options [String] :session_token
    #
    #   @option options [Boolean] :stub_responses (false)
    #     Causes the client to return stubbed responses. By default
    #     fake responses are generated and returned. You can specify
    #     the response data to return or errors to raise by calling
    #     {ClientStubs#stub_responses}. See {ClientStubs} for more information.
    #
    #     ** Please note ** When response stubbing is enabled, no HTTP
    #     requests are made, and retries are disabled.
    #
    #   @option options [Boolean] :validate_params (true)
    #     When `true`, request parameters are validated before
    #     sending the request.
    #
    #   @option options [URI::HTTP,String] :http_proxy A proxy to send
    #     requests through.  Formatted like 'http://proxy.com:123'.
    #
    #   @option options [Float] :http_open_timeout (15) The number of
    #     seconds to wait when opening a HTTP session before rasing a
    #     `Timeout::Error`.
    #
    #   @option options [Integer] :http_read_timeout (60) The default
    #     number of seconds to wait for response data.  This value can
    #     safely be set
    #     per-request on the session yeidled by {#session_for}.
    #
    #   @option options [Float] :http_idle_timeout (5) The number of
    #     seconds a connection is allowed to sit idble before it is
    #     considered stale.  Stale connections are closed and removed
    #     from the pool before making a request.
    #
    #   @option options [Float] :http_continue_timeout (1) The number of
    #     seconds to wait for a 100-continue response before sending the
    #     request body.  This option has no effect unless the request has
    #     "Expect" header set to "100-continue".  Defaults to `nil` which
    #     disables this behaviour.  This value can safely be set per
    #     request on the session yeidled by {#session_for}.
    #
    #   @option options [Boolean] :http_wire_trace (false) When `true`,
    #     HTTP debug output will be sent to the `:logger`.
    #
    #   @option options [Boolean] :ssl_verify_peer (true) When `true`,
    #     SSL peer certificates are verified when establishing a
    #     connection.
    #
    #   @option options [String] :ssl_ca_bundle Full path to the SSL
    #     certificate authority bundle file that should be used when
    #     verifying peer certificates.  If you do not pass
    #     `:ssl_ca_bundle` or `:ssl_ca_directory` the the system default
    #     will be used if available.
    #
    #   @option options [String] :ssl_ca_directory Full path of the
    #     directory that contains the unbundled SSL certificate
    #     authority files for verifying peer certificates.  If you do
    #     not pass `:ssl_ca_bundle` or `:ssl_ca_directory` the the
    #     system default will be used if available.
    #
    def initialize(*args)
      super
    end

    # @!group API Operations

    # Returns a set of temporary security credentials that you can use to
    # access AWS resources that you might not normally have access to. These
    # temporary credentials consist of an access key ID, a secret access
    # key, and a security token. Typically, you use `AssumeRole` within your
    # account or for cross-account access. For a comparison of `AssumeRole`
    # with other API operations that produce temporary credentials, see
    # [Requesting Temporary Security Credentials][1] and [Comparing the AWS
    # STS API operations][2] in the *IAM User Guide*.
    #
    # You cannot use AWS account root user credentials to call `AssumeRole`.
    # You must use credentials for an IAM user or an IAM role to call
    # `AssumeRole`.
    #
    # For cross-account access, imagine that you own multiple accounts and
    # need to access resources in each account. You could create long-term
    # credentials in each account to access those resources. However,
    # managing all those credentials and remembering which one can access
    # which account can be time consuming. Instead, you can create one set
    # of long-term credentials in one account. Then use temporary security
    # credentials to access all the other accounts by assuming roles in
    # those accounts. For more information about roles, see [IAM Roles][3]
    # in the *IAM User Guide*.
    #
    # By default, the temporary security credentials created by `AssumeRole`
    # last for one hour. However, you can use the optional `DurationSeconds`
    # parameter to specify the duration of your session. You can provide a
    # value from 900 seconds (15 minutes) up to the maximum session duration
    # setting for the role. This setting can have a value from 1 hour to 12
    # hours. To learn how to view the maximum value for your role, see [View
    # the Maximum Session Duration Setting for a Role][4] in the *IAM User
    # Guide*. The maximum session duration limit applies when you use the
    # `AssumeRole*` API operations or the `assume-role*` CLI commands.
    # However the limit does not apply when you use those operations to
    # create a console URL. For more information, see [Using IAM Roles][5]
    # in the *IAM User Guide*.
    #
    # The temporary security credentials created by `AssumeRole` can be used
    # to make API calls to any AWS service with the following exception: You
    # cannot call the AWS STS `GetFederationToken` or `GetSessionToken` API
    # operations.
    #
    # (Optional) You can pass inline or managed [session policies][6] to
    # this operation. You can pass a single JSON policy document to use as
    # an inline session policy. You can also specify up to 10 managed
    # policies to use as managed session policies. The plain text that you
    # use for both inline and managed session policies shouldn't exceed
    # 2048 characters. Passing policies to this operation returns new
    # temporary credentials. The resulting session's permissions are the
    # intersection of the role's identity-based policy and the session
    # policies. You can use the role's temporary credentials in subsequent
    # AWS API calls to access resources in the account that owns the role.
    # You cannot use session policies to grant more permissions than those
    # allowed by the identity-based policy of the role that is being
    # assumed. For more information, see [Session Policies][7] in the *IAM
    # User Guide*.
    #
    # To assume a role from a different account, your AWS account must be
    # trusted by the role. The trust relationship is defined in the role's
    # trust policy when the role is created. That trust policy states which
    # accounts are allowed to delegate that access to users in the account.
    #
    # A user who wants to access a role in a different account must also
    # have permissions that are delegated from the user account
    # administrator. The administrator must attach a policy that allows the
    # user to call `AssumeRole` for the ARN of the role in the other
    # account. If the user is in the same account as the role, then you can
    # do either of the following:
    #
    # * Attach a policy to the user (identical to the previous user in a
    #   different account).
    #
    # * Add the user as a principal directly in the role's trust policy.
    #
    # In this case, the trust policy acts as an IAM resource-based policy.
    # Users in the same account as the role do not need explicit permission
    # to assume the role. For more information about trust policies and
    # resource-based policies, see [IAM Policies][8] in the *IAM User
    # Guide*.
    #
    # **Using MFA with AssumeRole**
    #
    # (Optional) You can include multi-factor authentication (MFA)
    # information when you call `AssumeRole`. This is useful for
    # cross-account scenarios to ensure that the user that assumes the role
    # has been authenticated with an AWS MFA device. In that scenario, the
    # trust policy of the role being assumed includes a condition that tests
    # for MFA authentication. If the caller does not include valid MFA
    # information, the request to assume the role is denied. The condition
    # in a trust policy that tests for MFA authentication might look like
    # the following example.
    #
    # `"Condition": \{"Bool": \{"aws:MultiFactorAuthPresent": true\}\}`
    #
    # For more information, see [Configuring MFA-Protected API Access][9] in
    # the *IAM User Guide* guide.
    #
    # To use MFA with `AssumeRole`, you pass values for the `SerialNumber`
    # and `TokenCode` parameters. The `SerialNumber` value identifies the
    # user's hardware or virtual MFA device. The `TokenCode` is the
    # time-based one-time password (TOTP) that the MFA device produces.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html
    # [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison
    # [3]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html
    # [4]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session
    # [5]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html
    # [6]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session
    # [7]: https://docs.aws.amazon.com/IAM/latest/UserGuide/IAM/latest/UserGuide/access_policies.html#policies_session
    # [8]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html
    # [9]: https://docs.aws.amazon.com/IAM/latest/UserGuide/MFAProtectedAPI.html
    #
    # @option params [required, String] :role_arn
    #   The Amazon Resource Name (ARN) of the role to assume.
    #
    # @option params [required, String] :role_session_name
    #   An identifier for the assumed role session.
    #
    #   Use the role session name to uniquely identify a session when the same
    #   role is assumed by different principals or for different reasons. In
    #   cross-account scenarios, the role session name is visible to, and can
    #   be logged by the account that owns the role. The role session name is
    #   also used in the ARN of the assumed role principal. This means that
    #   subsequent cross-account API requests that use the temporary security
    #   credentials will expose the role session name to the external account
    #   in their AWS CloudTrail logs.
    #
    #   The regex used to validate this parameter is a string of characters
    #   consisting of upper- and lower-case alphanumeric characters with no
    #   spaces. You can also include underscores or any of the following
    #   characters: =,.@-
    #
    # @option params [Array<Types::PolicyDescriptorType>] :policy_arns
    #   The Amazon Resource Names (ARNs) of the IAM managed policies that you
    #   want to use as managed session policies. The policies must exist in
    #   the same account as the role.
    #
    #   This parameter is optional. You can provide up to 10 managed policy
    #   ARNs. However, the plain text that you use for both inline and managed
    #   session policies shouldn't exceed 2048 characters. For more
    #   information about ARNs, see [Amazon Resource Names (ARNs) and AWS
    #   Service Namespaces](general/latest/gr/aws-arns-and-namespaces.html) in
    #   the AWS General Reference.
    #
    #   <note markdown="1"> The characters in this parameter count towards the 2048 character
    #   session policy guideline. However, an AWS conversion compresses the
    #   session policies into a packed binary format that has a separate
    #   limit. This is the enforced limit. The `PackedPolicySize` response
    #   element indicates by percentage how close the policy is to the upper
    #   size limit.
    #
    #    </note>
    #
    #   Passing policies to this operation returns new temporary credentials.
    #   The resulting session's permissions are the intersection of the
    #   role's identity-based policy and the session policies. You can use
    #   the role's temporary credentials in subsequent AWS API calls to
    #   access resources in the account that owns the role. You cannot use
    #   session policies to grant more permissions than those allowed by the
    #   identity-based policy of the role that is being assumed. For more
    #   information, see [Session Policies][1] in the *IAM User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/IAM/latest/UserGuide/access_policies.html#policies_session
    #
    # @option params [String] :policy
    #   An IAM policy in JSON format that you want to use as an inline session
    #   policy.
    #
    #   This parameter is optional. Passing policies to this operation returns
    #   new temporary credentials. The resulting session's permissions are
    #   the intersection of the role's identity-based policy and the session
    #   policies. You can use the role's temporary credentials in subsequent
    #   AWS API calls to access resources in the account that owns the role.
    #   You cannot use session policies to grant more permissions than those
    #   allowed by the identity-based policy of the role that is being
    #   assumed. For more information, see [Session Policies][1] in the *IAM
    #   User Guide*.
    #
    #   The plain text that you use for both inline and managed session
    #   policies shouldn't exceed 2048 characters. The JSON policy characters
    #   can be any ASCII character from the space character to the end of the
    #   valid character list (\\u0020 through \\u00FF). It can also include
    #   the tab (\\u0009), linefeed (\\u000A), and carriage return (\\u000D)
    #   characters.
    #
    #   <note markdown="1"> The characters in this parameter count towards the 2048 character
    #   session policy guideline. However, an AWS conversion compresses the
    #   session policies into a packed binary format that has a separate
    #   limit. This is the enforced limit. The `PackedPolicySize` response
    #   element indicates by percentage how close the policy is to the upper
    #   size limit.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/IAM/latest/UserGuide/access_policies.html#policies_session
    #
    # @option params [Integer] :duration_seconds
    #   The duration, in seconds, of the role session. The value can range
    #   from 900 seconds (15 minutes) up to the maximum session duration
    #   setting for the role. This setting can have a value from 1 hour to 12
    #   hours. If you specify a value higher than this setting, the operation
    #   fails. For example, if you specify a session duration of 12 hours, but
    #   your administrator set the maximum session duration to 6 hours, your
    #   operation fails. To learn how to view the maximum value for your role,
    #   see [View the Maximum Session Duration Setting for a Role][1] in the
    #   *IAM User Guide*.
    #
    #   By default, the value is set to `3600` seconds.
    #
    #   <note markdown="1"> The `DurationSeconds` parameter is separate from the duration of a
    #   console session that you might request using the returned credentials.
    #   The request to the federation endpoint for a console sign-in token
    #   takes a `SessionDuration` parameter that specifies the maximum length
    #   of the console session. For more information, see [Creating a URL that
    #   Enables Federated Users to Access the AWS Management Console][2] in
    #   the *IAM User Guide*.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html
    #
    # @option params [String] :external_id
    #   A unique identifier that might be required when you assume a role in
    #   another account. If the administrator of the account to which the role
    #   belongs provided you with an external ID, then provide that value in
    #   the `ExternalId` parameter. This value can be any string, such as a
    #   passphrase or account number. A cross-account role is usually set up
    #   to trust everyone in an account. Therefore, the administrator of the
    #   trusting account might send an external ID to the administrator of the
    #   trusted account. That way, only someone with the ID can assume the
    #   role, rather than everyone in the account. For more information about
    #   the external ID, see [How to Use an External ID When Granting Access
    #   to Your AWS Resources to a Third Party][1] in the *IAM User Guide*.
    #
    #   The regex used to validate this parameter is a string of characters
    #   consisting of upper- and lower-case alphanumeric characters with no
    #   spaces. You can also include underscores or any of the following
    #   characters: =,.@:/-
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user_externalid.html
    #
    # @option params [String] :serial_number
    #   The identification number of the MFA device that is associated with
    #   the user who is making the `AssumeRole` call. Specify this value if
    #   the trust policy of the role being assumed includes a condition that
    #   requires MFA authentication. The value is either the serial number for
    #   a hardware device (such as `GAHT12345678`) or an Amazon Resource Name
    #   (ARN) for a virtual device (such as
    #   `arn:aws:iam::123456789012:mfa/user`).
    #
    #   The regex used to validate this parameter is a string of characters
    #   consisting of upper- and lower-case alphanumeric characters with no
    #   spaces. You can also include underscores or any of the following
    #   characters: =,.@-
    #
    # @option params [String] :token_code
    #   The value provided by the MFA device, if the trust policy of the role
    #   being assumed requires MFA (that is, if the policy includes a
    #   condition that tests for MFA). If the role being assumed requires MFA
    #   and if the `TokenCode` value is missing or expired, the `AssumeRole`
    #   call returns an "access denied" error.
    #
    #   The format for this parameter, as described by its regex pattern, is a
    #   sequence of six numeric digits.
    #
    # @return [Types::AssumeRoleResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::AssumeRoleResponse#credentials #credentials} => Types::Credentials
    #   * {Types::AssumeRoleResponse#assumed_role_user #assumed_role_user} => Types::AssumedRoleUser
    #   * {Types::AssumeRoleResponse#packed_policy_size #packed_policy_size} => Integer
    #
    #
    # @example Example: To assume a role
    #
    #   resp = client.assume_role({
    #     duration_seconds: 3600, 
    #     external_id: "123ABC", 
    #     policy: "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"Stmt1\",\"Effect\":\"Allow\",\"Action\":\"s3:ListAllMyBuckets\",\"Resource\":\"*\"}]}", 
    #     role_arn: "arn:aws:iam::123456789012:role/demo", 
    #     role_session_name: "Bob", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     assumed_role_user: {
    #       arn: "arn:aws:sts::123456789012:assumed-role/demo/Bob", 
    #       assumed_role_id: "ARO123EXAMPLE123:Bob", 
    #     }, 
    #     credentials: {
    #       access_key_id: "AKIAIOSFODNN7EXAMPLE", 
    #       expiration: Time.parse("2011-07-15T23:28:33.359Z"), 
    #       secret_access_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYzEXAMPLEKEY", 
    #       session_token: "AQoDYXdzEPT//////////wEXAMPLEtc764bNrC9SAPBSM22wDOk4x4HIZ8j4FZTwdQWLWsKWHGBuFqwAeMicRXmxfpSPfIeoIYRqTflfKD8YUuwthAx7mSEI/qkPpKPi/kMcGdQrmGdeehM4IC1NtBmUpp2wUE8phUZampKsburEDy0KPkyQDYwT7WZ0wq5VSXDvp75YU9HFvlRd8Tx6q6fE8YQcHNVXAkiY9q6d+xo0rKwT38xVqr7ZD0u0iPPkUL64lIZbqBAz+scqKmlzm8FDrypNC9Yjc8fPOLn9FX9KSYvKTr4rvx3iSIlTJabIQwj2ICCR/oLxBA==", 
    #     }, 
    #     packed_policy_size: 6, 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.assume_role({
    #     role_arn: "arnType", # required
    #     role_session_name: "roleSessionNameType", # required
    #     policy_arns: [
    #       {
    #         arn: "arnType",
    #       },
    #     ],
    #     policy: "sessionPolicyDocumentType",
    #     duration_seconds: 1,
    #     external_id: "externalIdType",
    #     serial_number: "serialNumberType",
    #     token_code: "tokenCodeType",
    #   })
    #
    # @example Response structure
    #
    #   resp.credentials.access_key_id #=> String
    #   resp.credentials.secret_access_key #=> String
    #   resp.credentials.session_token #=> String
    #   resp.credentials.expiration #=> Time
    #   resp.assumed_role_user.assumed_role_id #=> String
    #   resp.assumed_role_user.arn #=> String
    #   resp.packed_policy_size #=> Integer
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/AssumeRole AWS API Documentation
    #
    # @overload assume_role(params = {})
    # @param [Hash] params ({})
    def assume_role(params = {}, options = {})
      req = build_request(:assume_role, params)
      req.send_request(options)
    end

    # Returns a set of temporary security credentials for users who have
    # been authenticated via a SAML authentication response. This operation
    # provides a mechanism for tying an enterprise identity store or
    # directory to role-based AWS access without user-specific credentials
    # or configuration. For a comparison of `AssumeRoleWithSAML` with the
    # other API operations that produce temporary credentials, see
    # [Requesting Temporary Security Credentials][1] and [Comparing the AWS
    # STS API operations][2] in the *IAM User Guide*.
    #
    # The temporary security credentials returned by this operation consist
    # of an access key ID, a secret access key, and a security token.
    # Applications can use these temporary security credentials to sign
    # calls to AWS services.
    #
    # By default, the temporary security credentials created by
    # `AssumeRoleWithSAML` last for one hour. However, you can use the
    # optional `DurationSeconds` parameter to specify the duration of your
    # session. Your role session lasts for the duration that you specify, or
    # until the time specified in the SAML authentication response's
    # `SessionNotOnOrAfter` value, whichever is shorter. You can provide a
    # `DurationSeconds` value from 900 seconds (15 minutes) up to the
    # maximum session duration setting for the role. This setting can have a
    # value from 1 hour to 12 hours. To learn how to view the maximum value
    # for your role, see [View the Maximum Session Duration Setting for a
    # Role][3] in the *IAM User Guide*. The maximum session duration limit
    # applies when you use the `AssumeRole*` API operations or the
    # `assume-role*` CLI commands. However the limit does not apply when you
    # use those operations to create a console URL. For more information,
    # see [Using IAM Roles][4] in the *IAM User Guide*.
    #
    # The temporary security credentials created by `AssumeRoleWithSAML` can
    # be used to make API calls to any AWS service with the following
    # exception: you cannot call the STS `GetFederationToken` or
    # `GetSessionToken` API operations.
    #
    # (Optional) You can pass inline or managed [session policies][5] to
    # this operation. You can pass a single JSON policy document to use as
    # an inline session policy. You can also specify up to 10 managed
    # policies to use as managed session policies. The plain text that you
    # use for both inline and managed session policies shouldn't exceed
    # 2048 characters. Passing policies to this operation returns new
    # temporary credentials. The resulting session's permissions are the
    # intersection of the role's identity-based policy and the session
    # policies. You can use the role's temporary credentials in subsequent
    # AWS API calls to access resources in the account that owns the role.
    # You cannot use session policies to grant more permissions than those
    # allowed by the identity-based policy of the role that is being
    # assumed. For more information, see [Session Policies][6] in the *IAM
    # User Guide*.
    #
    # Before your application can call `AssumeRoleWithSAML`, you must
    # configure your SAML identity provider (IdP) to issue the claims
    # required by AWS. Additionally, you must use AWS Identity and Access
    # Management (IAM) to create a SAML provider entity in your AWS account
    # that represents your identity provider. You must also create an IAM
    # role that specifies this SAML provider in its trust policy.
    #
    # Calling `AssumeRoleWithSAML` does not require the use of AWS security
    # credentials. The identity of the caller is validated by using keys in
    # the metadata document that is uploaded for the SAML provider entity
    # for your identity provider.
    #
    # Calling `AssumeRoleWithSAML` can result in an entry in your AWS
    # CloudTrail logs. The entry includes the value in the `NameID` element
    # of the SAML assertion. We recommend that you use a `NameIDType` that
    # is not associated with any personally identifiable information (PII).
    # For example, you could instead use the Persistent Identifier
    # (`urn:oasis:names:tc:SAML:2.0:nameid-format:persistent`).
    #
    # For more information, see the following resources:
    #
    # * [About SAML 2.0-based Federation][7] in the *IAM User Guide*.
    #
    # * [Creating SAML Identity Providers][8] in the *IAM User Guide*.
    #
    # * [Configuring a Relying Party and Claims][9] in the *IAM User Guide*.
    #
    # * [Creating a Role for SAML 2.0 Federation][10] in the *IAM User
    #   Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html
    # [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison
    # [3]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session
    # [4]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html
    # [5]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session
    # [6]: https://docs.aws.amazon.com/IAM/latest/UserGuide/IAM/latest/UserGuide/access_policies.html#policies_session
    # [7]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_saml.html
    # [8]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml.html
    # [9]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml_relying-party.html
    # [10]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_saml.html
    #
    # @option params [required, String] :role_arn
    #   The Amazon Resource Name (ARN) of the role that the caller is
    #   assuming.
    #
    # @option params [required, String] :principal_arn
    #   The Amazon Resource Name (ARN) of the SAML provider in IAM that
    #   describes the IdP.
    #
    # @option params [required, String] :saml_assertion
    #   The base-64 encoded SAML authentication response provided by the IdP.
    #
    #   For more information, see [Configuring a Relying Party and Adding
    #   Claims][1] in the *IAM User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/create-role-saml-IdP-tasks.html
    #
    # @option params [Array<Types::PolicyDescriptorType>] :policy_arns
    #   The Amazon Resource Names (ARNs) of the IAM managed policies that you
    #   want to use as managed session policies. The policies must exist in
    #   the same account as the role.
    #
    #   This parameter is optional. You can provide up to 10 managed policy
    #   ARNs. However, the plain text that you use for both inline and managed
    #   session policies shouldn't exceed 2048 characters. For more
    #   information about ARNs, see [Amazon Resource Names (ARNs) and AWS
    #   Service Namespaces](general/latest/gr/aws-arns-and-namespaces.html) in
    #   the AWS General Reference.
    #
    #   <note markdown="1"> The characters in this parameter count towards the 2048 character
    #   session policy guideline. However, an AWS conversion compresses the
    #   session policies into a packed binary format that has a separate
    #   limit. This is the enforced limit. The `PackedPolicySize` response
    #   element indicates by percentage how close the policy is to the upper
    #   size limit.
    #
    #    </note>
    #
    #   Passing policies to this operation returns new temporary credentials.
    #   The resulting session's permissions are the intersection of the
    #   role's identity-based policy and the session policies. You can use
    #   the role's temporary credentials in subsequent AWS API calls to
    #   access resources in the account that owns the role. You cannot use
    #   session policies to grant more permissions than those allowed by the
    #   identity-based policy of the role that is being assumed. For more
    #   information, see [Session Policies][1] in the *IAM User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/IAM/latest/UserGuide/access_policies.html#policies_session
    #
    # @option params [String] :policy
    #   An IAM policy in JSON format that you want to use as an inline session
    #   policy.
    #
    #   This parameter is optional. Passing policies to this operation returns
    #   new temporary credentials. The resulting session's permissions are
    #   the intersection of the role's identity-based policy and the session
    #   policies. You can use the role's temporary credentials in subsequent
    #   AWS API calls to access resources in the account that owns the role.
    #   You cannot use session policies to grant more permissions than those
    #   allowed by the identity-based policy of the role that is being
    #   assumed. For more information, see [Session Policies][1] in the *IAM
    #   User Guide*.
    #
    #   The plain text that you use for both inline and managed session
    #   policies shouldn't exceed 2048 characters. The JSON policy characters
    #   can be any ASCII character from the space character to the end of the
    #   valid character list (\\u0020 through \\u00FF). It can also include
    #   the tab (\\u0009), linefeed (\\u000A), and carriage return (\\u000D)
    #   characters.
    #
    #   <note markdown="1"> The characters in this parameter count towards the 2048 character
    #   session policy guideline. However, an AWS conversion compresses the
    #   session policies into a packed binary format that has a separate
    #   limit. This is the enforced limit. The `PackedPolicySize` response
    #   element indicates by percentage how close the policy is to the upper
    #   size limit.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/IAM/latest/UserGuide/access_policies.html#policies_session
    #
    # @option params [Integer] :duration_seconds
    #   The duration, in seconds, of the role session. Your role session lasts
    #   for the duration that you specify for the `DurationSeconds` parameter,
    #   or until the time specified in the SAML authentication response's
    #   `SessionNotOnOrAfter` value, whichever is shorter. You can provide a
    #   `DurationSeconds` value from 900 seconds (15 minutes) up to the
    #   maximum session duration setting for the role. This setting can have a
    #   value from 1 hour to 12 hours. If you specify a value higher than this
    #   setting, the operation fails. For example, if you specify a session
    #   duration of 12 hours, but your administrator set the maximum session
    #   duration to 6 hours, your operation fails. To learn how to view the
    #   maximum value for your role, see [View the Maximum Session Duration
    #   Setting for a Role][1] in the *IAM User Guide*.
    #
    #   By default, the value is set to `3600` seconds.
    #
    #   <note markdown="1"> The `DurationSeconds` parameter is separate from the duration of a
    #   console session that you might request using the returned credentials.
    #   The request to the federation endpoint for a console sign-in token
    #   takes a `SessionDuration` parameter that specifies the maximum length
    #   of the console session. For more information, see [Creating a URL that
    #   Enables Federated Users to Access the AWS Management Console][2] in
    #   the *IAM User Guide*.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html
    #
    # @return [Types::AssumeRoleWithSAMLResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::AssumeRoleWithSAMLResponse#credentials #credentials} => Types::Credentials
    #   * {Types::AssumeRoleWithSAMLResponse#assumed_role_user #assumed_role_user} => Types::AssumedRoleUser
    #   * {Types::AssumeRoleWithSAMLResponse#packed_policy_size #packed_policy_size} => Integer
    #   * {Types::AssumeRoleWithSAMLResponse#subject #subject} => String
    #   * {Types::AssumeRoleWithSAMLResponse#subject_type #subject_type} => String
    #   * {Types::AssumeRoleWithSAMLResponse#issuer #issuer} => String
    #   * {Types::AssumeRoleWithSAMLResponse#audience #audience} => String
    #   * {Types::AssumeRoleWithSAMLResponse#name_qualifier #name_qualifier} => String
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.assume_role_with_saml({
    #     role_arn: "arnType", # required
    #     principal_arn: "arnType", # required
    #     saml_assertion: "SAMLAssertionType", # required
    #     policy_arns: [
    #       {
    #         arn: "arnType",
    #       },
    #     ],
    #     policy: "sessionPolicyDocumentType",
    #     duration_seconds: 1,
    #   })
    #
    # @example Response structure
    #
    #   resp.credentials.access_key_id #=> String
    #   resp.credentials.secret_access_key #=> String
    #   resp.credentials.session_token #=> String
    #   resp.credentials.expiration #=> Time
    #   resp.assumed_role_user.assumed_role_id #=> String
    #   resp.assumed_role_user.arn #=> String
    #   resp.packed_policy_size #=> Integer
    #   resp.subject #=> String
    #   resp.subject_type #=> String
    #   resp.issuer #=> String
    #   resp.audience #=> String
    #   resp.name_qualifier #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/AssumeRoleWithSAML AWS API Documentation
    #
    # @overload assume_role_with_saml(params = {})
    # @param [Hash] params ({})
    def assume_role_with_saml(params = {}, options = {})
      req = build_request(:assume_role_with_saml, params)
      req.send_request(options)
    end

    # Returns a set of temporary security credentials for users who have
    # been authenticated in a mobile or web application with a web identity
    # provider. Example providers include Amazon Cognito, Login with Amazon,
    # Facebook, Google, or any OpenID Connect-compatible identity provider.
    #
    # <note markdown="1"> For mobile applications, we recommend that you use Amazon Cognito. You
    # can use Amazon Cognito with the [AWS SDK for iOS Developer Guide][1]
    # and the [AWS SDK for Android Developer Guide][2] to uniquely identify
    # a user. You can also supply the user with a consistent identity
    # throughout the lifetime of an application.
    #
    #  To learn more about Amazon Cognito, see [Amazon Cognito Overview][3]
    # in *AWS SDK for Android Developer Guide* and [Amazon Cognito
    # Overview][4] in the *AWS SDK for iOS Developer Guide*.
    #
    #  </note>
    #
    # Calling `AssumeRoleWithWebIdentity` does not require the use of AWS
    # security credentials. Therefore, you can distribute an application
    # (for example, on mobile devices) that requests temporary security
    # credentials without including long-term AWS credentials in the
    # application. You also don't need to deploy server-based proxy
    # services that use long-term AWS credentials. Instead, the identity of
    # the caller is validated by using a token from the web identity
    # provider. For a comparison of `AssumeRoleWithWebIdentity` with the
    # other API operations that produce temporary credentials, see
    # [Requesting Temporary Security Credentials][5] and [Comparing the AWS
    # STS API operations][6] in the *IAM User Guide*.
    #
    # The temporary security credentials returned by this API consist of an
    # access key ID, a secret access key, and a security token. Applications
    # can use these temporary security credentials to sign calls to AWS
    # service API operations.
    #
    # By default, the temporary security credentials created by
    # `AssumeRoleWithWebIdentity` last for one hour. However, you can use
    # the optional `DurationSeconds` parameter to specify the duration of
    # your session. You can provide a value from 900 seconds (15 minutes) up
    # to the maximum session duration setting for the role. This setting can
    # have a value from 1 hour to 12 hours. To learn how to view the maximum
    # value for your role, see [View the Maximum Session Duration Setting
    # for a Role][7] in the *IAM User Guide*. The maximum session duration
    # limit applies when you use the `AssumeRole*` API operations or the
    # `assume-role*` CLI commands. However the limit does not apply when you
    # use those operations to create a console URL. For more information,
    # see [Using IAM Roles][8] in the *IAM User Guide*.
    #
    # The temporary security credentials created by
    # `AssumeRoleWithWebIdentity` can be used to make API calls to any AWS
    # service with the following exception: you cannot call the STS
    # `GetFederationToken` or `GetSessionToken` API operations.
    #
    # (Optional) You can pass inline or managed [session policies][9] to
    # this operation. You can pass a single JSON policy document to use as
    # an inline session policy. You can also specify up to 10 managed
    # policies to use as managed session policies. The plain text that you
    # use for both inline and managed session policies shouldn't exceed
    # 2048 characters. Passing policies to this operation returns new
    # temporary credentials. The resulting session's permissions are the
    # intersection of the role's identity-based policy and the session
    # policies. You can use the role's temporary credentials in subsequent
    # AWS API calls to access resources in the account that owns the role.
    # You cannot use session policies to grant more permissions than those
    # allowed by the identity-based policy of the role that is being
    # assumed. For more information, see [Session Policies][10] in the *IAM
    # User Guide*.
    #
    # Before your application can call `AssumeRoleWithWebIdentity`, you must
    # have an identity token from a supported identity provider and create a
    # role that the application can assume. The role that your application
    # assumes must trust the identity provider that is associated with the
    # identity token. In other words, the identity provider must be
    # specified in the role's trust policy.
    #
    # Calling `AssumeRoleWithWebIdentity` can result in an entry in your AWS
    # CloudTrail logs. The entry includes the [Subject][11] of the provided
    # Web Identity Token. We recommend that you avoid using any personally
    # identifiable information (PII) in this field. For example, you could
    # instead use a GUID or a pairwise identifier, as [suggested in the OIDC
    # specification][12].
    #
    # For more information about how to use web identity federation and the
    # `AssumeRoleWithWebIdentity` API, see the following resources:
    #
    # * [Using Web Identity Federation API Operations for Mobile Apps][13]
    #   and [Federation Through a Web-based Identity Provider][14].
    #
    # * [ Web Identity Federation Playground][15]. Walk through the process
    #   of authenticating through Login with Amazon, Facebook, or Google,
    #   getting temporary security credentials, and then using those
    #   credentials to make a request to AWS.
    #
    # * [AWS SDK for iOS Developer Guide][1] and [AWS SDK for Android
    #   Developer Guide][2]. These toolkits contain sample apps that show
    #   how to invoke the identity providers, and then how to use the
    #   information from these providers to get and use temporary security
    #   credentials.
    #
    # * [Web Identity Federation with Mobile Applications][16]. This article
    #   discusses web identity federation and shows an example of how to use
    #   web identity federation to get access to content in Amazon S3.
    #
    #
    #
    # [1]: http://aws.amazon.com/sdkforios/
    # [2]: http://aws.amazon.com/sdkforandroid/
    # [3]: https://docs.aws.amazon.com/mobile/sdkforandroid/developerguide/cognito-auth.html#d0e840
    # [4]: https://docs.aws.amazon.com/mobile/sdkforios/developerguide/cognito-auth.html#d0e664
    # [5]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html
    # [6]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison
    # [7]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session
    # [8]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html
    # [9]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session
    # [10]: https://docs.aws.amazon.com/IAM/latest/UserGuide/IAM/latest/UserGuide/access_policies.html#policies_session
    # [11]: http://openid.net/specs/openid-connect-core-1_0.html#Claims
    # [12]: http://openid.net/specs/openid-connect-core-1_0.html#SubjectIDTypes
    # [13]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_oidc_manual.html
    # [14]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity
    # [15]: https://web-identity-federation-playground.s3.amazonaws.com/index.html
    # [16]: http://aws.amazon.com/articles/web-identity-federation-with-mobile-applications
    #
    # @option params [required, String] :role_arn
    #   The Amazon Resource Name (ARN) of the role that the caller is
    #   assuming.
    #
    # @option params [required, String] :role_session_name
    #   An identifier for the assumed role session. Typically, you pass the
    #   name or identifier that is associated with the user who is using your
    #   application. That way, the temporary security credentials that your
    #   application will use are associated with that user. This session name
    #   is included as part of the ARN and assumed role ID in the
    #   `AssumedRoleUser` response element.
    #
    #   The regex used to validate this parameter is a string of characters
    #   consisting of upper- and lower-case alphanumeric characters with no
    #   spaces. You can also include underscores or any of the following
    #   characters: =,.@-
    #
    # @option params [required, String] :web_identity_token
    #   The OAuth 2.0 access token or OpenID Connect ID token that is provided
    #   by the identity provider. Your application must get this token by
    #   authenticating the user who is using your application with a web
    #   identity provider before the application makes an
    #   `AssumeRoleWithWebIdentity` call.
    #
    # @option params [String] :provider_id
    #   The fully qualified host component of the domain name of the identity
    #   provider.
    #
    #   Specify this value only for OAuth 2.0 access tokens. Currently
    #   `www.amazon.com` and `graph.facebook.com` are the only supported
    #   identity providers for OAuth 2.0 access tokens. Do not include URL
    #   schemes and port numbers.
    #
    #   Do not specify this value for OpenID Connect ID tokens.
    #
    # @option params [Array<Types::PolicyDescriptorType>] :policy_arns
    #   The Amazon Resource Names (ARNs) of the IAM managed policies that you
    #   want to use as managed session policies. The policies must exist in
    #   the same account as the role.
    #
    #   This parameter is optional. You can provide up to 10 managed policy
    #   ARNs. However, the plain text that you use for both inline and managed
    #   session policies shouldn't exceed 2048 characters. For more
    #   information about ARNs, see [Amazon Resource Names (ARNs) and AWS
    #   Service Namespaces](general/latest/gr/aws-arns-and-namespaces.html) in
    #   the AWS General Reference.
    #
    #   <note markdown="1"> The characters in this parameter count towards the 2048 character
    #   session policy guideline. However, an AWS conversion compresses the
    #   session policies into a packed binary format that has a separate
    #   limit. This is the enforced limit. The `PackedPolicySize` response
    #   element indicates by percentage how close the policy is to the upper
    #   size limit.
    #
    #    </note>
    #
    #   Passing policies to this operation returns new temporary credentials.
    #   The resulting session's permissions are the intersection of the
    #   role's identity-based policy and the session policies. You can use
    #   the role's temporary credentials in subsequent AWS API calls to
    #   access resources in the account that owns the role. You cannot use
    #   session policies to grant more permissions than those allowed by the
    #   identity-based policy of the role that is being assumed. For more
    #   information, see [Session Policies][1] in the *IAM User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/IAM/latest/UserGuide/access_policies.html#policies_session
    #
    # @option params [String] :policy
    #   An IAM policy in JSON format that you want to use as an inline session
    #   policy.
    #
    #   This parameter is optional. Passing policies to this operation returns
    #   new temporary credentials. The resulting session's permissions are
    #   the intersection of the role's identity-based policy and the session
    #   policies. You can use the role's temporary credentials in subsequent
    #   AWS API calls to access resources in the account that owns the role.
    #   You cannot use session policies to grant more permissions than those
    #   allowed by the identity-based policy of the role that is being
    #   assumed. For more information, see [Session Policies][1] in the *IAM
    #   User Guide*.
    #
    #   The plain text that you use for both inline and managed session
    #   policies shouldn't exceed 2048 characters. The JSON policy characters
    #   can be any ASCII character from the space character to the end of the
    #   valid character list (\\u0020 through \\u00FF). It can also include
    #   the tab (\\u0009), linefeed (\\u000A), and carriage return (\\u000D)
    #   characters.
    #
    #   <note markdown="1"> The characters in this parameter count towards the 2048 character
    #   session policy guideline. However, an AWS conversion compresses the
    #   session policies into a packed binary format that has a separate
    #   limit. This is the enforced limit. The `PackedPolicySize` response
    #   element indicates by percentage how close the policy is to the upper
    #   size limit.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/IAM/latest/UserGuide/access_policies.html#policies_session
    #
    # @option params [Integer] :duration_seconds
    #   The duration, in seconds, of the role session. The value can range
    #   from 900 seconds (15 minutes) up to the maximum session duration
    #   setting for the role. This setting can have a value from 1 hour to 12
    #   hours. If you specify a value higher than this setting, the operation
    #   fails. For example, if you specify a session duration of 12 hours, but
    #   your administrator set the maximum session duration to 6 hours, your
    #   operation fails. To learn how to view the maximum value for your role,
    #   see [View the Maximum Session Duration Setting for a Role][1] in the
    #   *IAM User Guide*.
    #
    #   By default, the value is set to `3600` seconds.
    #
    #   <note markdown="1"> The `DurationSeconds` parameter is separate from the duration of a
    #   console session that you might request using the returned credentials.
    #   The request to the federation endpoint for a console sign-in token
    #   takes a `SessionDuration` parameter that specifies the maximum length
    #   of the console session. For more information, see [Creating a URL that
    #   Enables Federated Users to Access the AWS Management Console][2] in
    #   the *IAM User Guide*.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html
    #
    # @return [Types::AssumeRoleWithWebIdentityResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::AssumeRoleWithWebIdentityResponse#credentials #credentials} => Types::Credentials
    #   * {Types::AssumeRoleWithWebIdentityResponse#subject_from_web_identity_token #subject_from_web_identity_token} => String
    #   * {Types::AssumeRoleWithWebIdentityResponse#assumed_role_user #assumed_role_user} => Types::AssumedRoleUser
    #   * {Types::AssumeRoleWithWebIdentityResponse#packed_policy_size #packed_policy_size} => Integer
    #   * {Types::AssumeRoleWithWebIdentityResponse#provider #provider} => String
    #   * {Types::AssumeRoleWithWebIdentityResponse#audience #audience} => String
    #
    #
    # @example Example: To assume a role as an OpenID Connect-federated user
    #
    #   resp = client.assume_role_with_web_identity({
    #     duration_seconds: 3600, 
    #     policy: "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"Stmt1\",\"Effect\":\"Allow\",\"Action\":\"s3:ListAllMyBuckets\",\"Resource\":\"*\"}]}", 
    #     provider_id: "www.amazon.com", 
    #     role_arn: "arn:aws:iam::123456789012:role/FederatedWebIdentityRole", 
    #     role_session_name: "app1", 
    #     web_identity_token: "Atza%7CIQEBLjAsAhRFiXuWpUXuRvQ9PZL3GMFcYevydwIUFAHZwXZXXXXXXXXJnrulxKDHwy87oGKPznh0D6bEQZTSCzyoCtL_8S07pLpr0zMbn6w1lfVZKNTBdDansFBmtGnIsIapjI6xKR02Yc_2bQ8LZbUXSGm6Ry6_BG7PrtLZtj_dfCTj92xNGed-CrKqjG7nPBjNIL016GGvuS5gSvPRUxWES3VYfm1wl7WTI7jn-Pcb6M-buCgHhFOzTQxod27L9CqnOLio7N3gZAGpsp6n1-AJBOCJckcyXe2c6uD0srOJeZlKUm2eTDVMf8IehDVI0r1QOnTV6KzzAI3OY87Vd_cVMQ", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     assumed_role_user: {
    #       arn: "arn:aws:sts::123456789012:assumed-role/FederatedWebIdentityRole/app1", 
    #       assumed_role_id: "AROACLKWSDQRAOEXAMPLE:app1", 
    #     }, 
    #     audience: "client.5498841531868486423.1548@apps.example.com", 
    #     credentials: {
    #       access_key_id: "AKIAIOSFODNN7EXAMPLE", 
    #       expiration: Time.parse("2014-10-24T23:00:23Z"), 
    #       secret_access_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYzEXAMPLEKEY", 
    #       session_token: "AQoDYXdzEE0a8ANXXXXXXXXNO1ewxE5TijQyp+IEXAMPLE", 
    #     }, 
    #     packed_policy_size: 123, 
    #     provider: "www.amazon.com", 
    #     subject_from_web_identity_token: "amzn1.account.AF6RHO7KZU5XRVQJGXK6HEXAMPLE", 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.assume_role_with_web_identity({
    #     role_arn: "arnType", # required
    #     role_session_name: "roleSessionNameType", # required
    #     web_identity_token: "clientTokenType", # required
    #     provider_id: "urlType",
    #     policy_arns: [
    #       {
    #         arn: "arnType",
    #       },
    #     ],
    #     policy: "sessionPolicyDocumentType",
    #     duration_seconds: 1,
    #   })
    #
    # @example Response structure
    #
    #   resp.credentials.access_key_id #=> String
    #   resp.credentials.secret_access_key #=> String
    #   resp.credentials.session_token #=> String
    #   resp.credentials.expiration #=> Time
    #   resp.subject_from_web_identity_token #=> String
    #   resp.assumed_role_user.assumed_role_id #=> String
    #   resp.assumed_role_user.arn #=> String
    #   resp.packed_policy_size #=> Integer
    #   resp.provider #=> String
    #   resp.audience #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/AssumeRoleWithWebIdentity AWS API Documentation
    #
    # @overload assume_role_with_web_identity(params = {})
    # @param [Hash] params ({})
    def assume_role_with_web_identity(params = {}, options = {})
      req = build_request(:assume_role_with_web_identity, params)
      req.send_request(options)
    end

    # Decodes additional information about the authorization status of a
    # request from an encoded message returned in response to an AWS
    # request.
    #
    # For example, if a user is not authorized to perform an operation that
    # he or she has requested, the request returns a
    # `Client.UnauthorizedOperation` response (an HTTP 403 response). Some
    # AWS operations additionally return an encoded message that can provide
    # details about this authorization failure.
    #
    # <note markdown="1"> Only certain AWS operations return an encoded authorization message.
    # The documentation for an individual operation indicates whether that
    # operation returns an encoded message in addition to returning an HTTP
    # code.
    #
    #  </note>
    #
    # The message is encoded because the details of the authorization status
    # can constitute privileged information that the user who requested the
    # operation should not see. To decode an authorization status message, a
    # user must be granted permissions via an IAM policy to request the
    # `DecodeAuthorizationMessage` (`sts:DecodeAuthorizationMessage`)
    # action.
    #
    # The decoded message includes the following type of information:
    #
    # * Whether the request was denied due to an explicit deny or due to the
    #   absence of an explicit allow. For more information, see [Determining
    #   Whether a Request is Allowed or Denied][1] in the *IAM User Guide*.
    #
    # * The principal who made the request.
    #
    # * The requested action.
    #
    # * The requested resource.
    #
    # * The values of condition keys in the context of the user's request.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html#policy-eval-denyallow
    #
    # @option params [required, String] :encoded_message
    #   The encoded message that was returned with the response.
    #
    # @return [Types::DecodeAuthorizationMessageResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::DecodeAuthorizationMessageResponse#decoded_message #decoded_message} => String
    #
    #
    # @example Example: To decode information about an authorization status of a request
    #
    #   resp = client.decode_authorization_message({
    #     encoded_message: "<encoded-message>", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     decoded_message: "{\"allowed\": \"false\",\"explicitDeny\": \"false\",\"matchedStatements\": \"\",\"failures\": \"\",\"context\": {\"principal\": {\"id\": \"AIDACKCEVSQ6C2EXAMPLE\",\"name\": \"Bob\",\"arn\": \"arn:aws:iam::123456789012:user/Bob\"},\"action\": \"ec2:StopInstances\",\"resource\": \"arn:aws:ec2:us-east-1:123456789012:instance/i-dd01c9bd\",\"conditions\": [{\"item\": {\"key\": \"ec2:Tenancy\",\"values\": [\"default\"]},{\"item\": {\"key\": \"ec2:ResourceTag/elasticbeanstalk:environment-name\",\"values\": [\"Default-Environment\"]}},(Additional items ...)]}}", 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.decode_authorization_message({
    #     encoded_message: "encodedMessageType", # required
    #   })
    #
    # @example Response structure
    #
    #   resp.decoded_message #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/DecodeAuthorizationMessage AWS API Documentation
    #
    # @overload decode_authorization_message(params = {})
    # @param [Hash] params ({})
    def decode_authorization_message(params = {}, options = {})
      req = build_request(:decode_authorization_message, params)
      req.send_request(options)
    end

    # Returns details about the IAM identity whose credentials are used to
    # call the API.
    #
    # @return [Types::GetCallerIdentityResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetCallerIdentityResponse#user_id #user_id} => String
    #   * {Types::GetCallerIdentityResponse#account #account} => String
    #   * {Types::GetCallerIdentityResponse#arn #arn} => String
    #
    #
    # @example Example: To get details about a calling IAM user
    #
    #   # This example shows a request and response made with the credentials for a user named Alice in the AWS account
    #   # 123456789012.
    #
    #   resp = client.get_caller_identity({
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     account: "123456789012", 
    #     arn: "arn:aws:iam::123456789012:user/Alice", 
    #     user_id: "AKIAI44QH8DHBEXAMPLE", 
    #   }
    #
    # @example Example: To get details about a calling user federated with AssumeRole
    #
    #   # This example shows a request and response made with temporary credentials created by AssumeRole. The name of the assumed
    #   # role is my-role-name, and the RoleSessionName is set to my-role-session-name.
    #
    #   resp = client.get_caller_identity({
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     account: "123456789012", 
    #     arn: "arn:aws:sts::123456789012:assumed-role/my-role-name/my-role-session-name", 
    #     user_id: "AKIAI44QH8DHBEXAMPLE:my-role-session-name", 
    #   }
    #
    # @example Example: To get details about a calling user federated with GetFederationToken
    #
    #   # This example shows a request and response made with temporary credentials created by using GetFederationToken. The Name
    #   # parameter is set to my-federated-user-name.
    #
    #   resp = client.get_caller_identity({
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     account: "123456789012", 
    #     arn: "arn:aws:sts::123456789012:federated-user/my-federated-user-name", 
    #     user_id: "123456789012:my-federated-user-name", 
    #   }
    #
    # @example Response structure
    #
    #   resp.user_id #=> String
    #   resp.account #=> String
    #   resp.arn #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/GetCallerIdentity AWS API Documentation
    #
    # @overload get_caller_identity(params = {})
    # @param [Hash] params ({})
    def get_caller_identity(params = {}, options = {})
      req = build_request(:get_caller_identity, params)
      req.send_request(options)
    end

    # Returns a set of temporary security credentials (consisting of an
    # access key ID, a secret access key, and a security token) for a
    # federated user. A typical use is in a proxy application that gets
    # temporary security credentials on behalf of distributed applications
    # inside a corporate network. You must call the `GetFederationToken`
    # operation using the long-term security credentials of an IAM user. As
    # a result, this call is appropriate in contexts where those credentials
    # can be safely stored, usually in a server-based application. For a
    # comparison of `GetFederationToken` with the other API operations that
    # produce temporary credentials, see [Requesting Temporary Security
    # Credentials][1] and [Comparing the AWS STS API operations][2] in the
    # *IAM User Guide*.
    #
    # <note markdown="1"> You can create a mobile-based or browser-based app that can
    # authenticate users using a web identity provider like Login with
    # Amazon, Facebook, Google, or an OpenID Connect-compatible identity
    # provider. In this case, we recommend that you use [Amazon Cognito][3]
    # or `AssumeRoleWithWebIdentity`. For more information, see [Federation
    # Through a Web-based Identity Provider][4].
    #
    #  </note>
    #
    # You can also call `GetFederationToken` using the security credentials
    # of an AWS account root user, but we do not recommend it. Instead, we
    # recommend that you create an IAM user for the purpose of the proxy
    # application. Then attach a policy to the IAM user that limits
    # federated users to only the actions and resources that they need to
    # access. For more information, see [IAM Best Practices][5] in the *IAM
    # User Guide*.
    #
    # The temporary credentials are valid for the specified duration, from
    # 900 seconds (15 minutes) up to a maximum of 129,600 seconds (36
    # hours). The default is 43,200 seconds (12 hours). Temporary
    # credentials that are obtained by using AWS account root user
    # credentials have a maximum duration of 3,600 seconds (1 hour).
    #
    # The temporary security credentials created by `GetFederationToken` can
    # be used to make API calls to any AWS service with the following
    # exceptions:
    #
    # * You cannot use these credentials to call any IAM API operations.
    #
    # * You cannot call any STS API operations except `GetCallerIdentity`.
    #
    # **Permissions**
    #
    # You must pass an inline or managed [session policy][6] to this
    # operation. You can pass a single JSON policy document to use as an
    # inline session policy. You can also specify up to 10 managed policies
    # to use as managed session policies. The plain text that you use for
    # both inline and managed session policies shouldn't exceed 2048
    # characters.
    #
    # Though the session policy parameters are optional, if you do not pass
    # a policy, then the resulting federated user session has no
    # permissions. The only exception is when the credentials are used to
    # access a resource that has a resource-based policy that specifically
    # references the federated user session in the `Principal` element of
    # the policy. When you pass session policies, the session permissions
    # are the intersection of the IAM user policies and the session policies
    # that you pass. This gives you a way to further restrict the
    # permissions for a federated user. You cannot use session policies to
    # grant more permissions than those that are defined in the permissions
    # policy of the IAM user. For more information, see [Session
    # Policies][7] in the *IAM User Guide*. For information about using
    # `GetFederationToken` to create temporary security credentials, see
    # [GetFederationToken—Federation Through a Custom Identity Broker][8].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html
    # [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison
    # [3]: http://aws.amazon.com/cognito/
    # [4]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity
    # [5]: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
    # [6]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session
    # [7]: https://docs.aws.amazon.com/IAM/latest/UserGuide/IAM/latest/UserGuide/access_policies.html#policies_session
    # [8]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getfederationtoken
    #
    # @option params [required, String] :name
    #   The name of the federated user. The name is used as an identifier for
    #   the temporary security credentials (such as `Bob`). For example, you
    #   can reference the federated user name in a resource-based policy, such
    #   as in an Amazon S3 bucket policy.
    #
    #   The regex used to validate this parameter is a string of characters
    #   consisting of upper- and lower-case alphanumeric characters with no
    #   spaces. You can also include underscores or any of the following
    #   characters: =,.@-
    #
    # @option params [String] :policy
    #   An IAM policy in JSON format that you want to use as an inline session
    #   policy.
    #
    #   You must pass an inline or managed [session policy][1] to this
    #   operation. You can pass a single JSON policy document to use as an
    #   inline session policy. You can also specify up to 10 managed policies
    #   to use as managed session policies.
    #
    #   This parameter is optional. However, if you do not pass any session
    #   policies, then the resulting federated user session has no
    #   permissions. The only exception is when the credentials are used to
    #   access a resource that has a resource-based policy that specifically
    #   references the federated user session in the `Principal` element of
    #   the policy.
    #
    #   When you pass session policies, the session permissions are the
    #   intersection of the IAM user policies and the session policies that
    #   you pass. This gives you a way to further restrict the permissions for
    #   a federated user. You cannot use session policies to grant more
    #   permissions than those that are defined in the permissions policy of
    #   the IAM user. For more information, see [Session Policies][2] in the
    #   *IAM User Guide*.
    #
    #   The plain text that you use for both inline and managed session
    #   policies shouldn't exceed 2048 characters. The JSON policy characters
    #   can be any ASCII character from the space character to the end of the
    #   valid character list (\\u0020 through \\u00FF). It can also include
    #   the tab (\\u0009), linefeed (\\u000A), and carriage return (\\u000D)
    #   characters.
    #
    #   <note markdown="1"> The characters in this parameter count towards the 2048 character
    #   session policy guideline. However, an AWS conversion compresses the
    #   session policies into a packed binary format that has a separate
    #   limit. This is the enforced limit. The `PackedPolicySize` response
    #   element indicates by percentage how close the policy is to the upper
    #   size limit.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/IAM/latest/UserGuide/access_policies.html#policies_session
    #
    # @option params [Array<Types::PolicyDescriptorType>] :policy_arns
    #   The Amazon Resource Names (ARNs) of the IAM managed policies that you
    #   want to use as a managed session policy. The policies must exist in
    #   the same account as the IAM user that is requesting federated access.
    #
    #   You must pass an inline or managed [session policy][1] to this
    #   operation. You can pass a single JSON policy document to use as an
    #   inline session policy. You can also specify up to 10 managed policies
    #   to use as managed session policies. The plain text that you use for
    #   both inline and managed session policies shouldn't exceed 2048
    #   characters. You can provide up to 10 managed policy ARNs. For more
    #   information about ARNs, see [Amazon Resource Names (ARNs) and AWS
    #   Service Namespaces](general/latest/gr/aws-arns-and-namespaces.html) in
    #   the AWS General Reference.
    #
    #   This parameter is optional. However, if you do not pass any session
    #   policies, then the resulting federated user session has no
    #   permissions. The only exception is when the credentials are used to
    #   access a resource that has a resource-based policy that specifically
    #   references the federated user session in the `Principal` element of
    #   the policy.
    #
    #   When you pass session policies, the session permissions are the
    #   intersection of the IAM user policies and the session policies that
    #   you pass. This gives you a way to further restrict the permissions for
    #   a federated user. You cannot use session policies to grant more
    #   permissions than those that are defined in the permissions policy of
    #   the IAM user. For more information, see [Session Policies][2] in the
    #   *IAM User Guide*.
    #
    #   <note markdown="1"> The characters in this parameter count towards the 2048 character
    #   session policy guideline. However, an AWS conversion compresses the
    #   session policies into a packed binary format that has a separate
    #   limit. This is the enforced limit. The `PackedPolicySize` response
    #   element indicates by percentage how close the policy is to the upper
    #   size limit.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/IAM/latest/UserGuide/access_policies.html#policies_session
    #
    # @option params [Integer] :duration_seconds
    #   The duration, in seconds, that the session should last. Acceptable
    #   durations for federation sessions range from 900 seconds (15 minutes)
    #   to 129,600 seconds (36 hours), with 43,200 seconds (12 hours) as the
    #   default. Sessions obtained using AWS account root user credentials are
    #   restricted to a maximum of 3,600 seconds (one hour). If the specified
    #   duration is longer than one hour, the session obtained by using root
    #   user credentials defaults to one hour.
    #
    # @return [Types::GetFederationTokenResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetFederationTokenResponse#credentials #credentials} => Types::Credentials
    #   * {Types::GetFederationTokenResponse#federated_user #federated_user} => Types::FederatedUser
    #   * {Types::GetFederationTokenResponse#packed_policy_size #packed_policy_size} => Integer
    #
    #
    # @example Example: To get temporary credentials for a role by using GetFederationToken
    #
    #   resp = client.get_federation_token({
    #     duration_seconds: 3600, 
    #     name: "Bob", 
    #     policy: "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"Stmt1\",\"Effect\":\"Allow\",\"Action\":\"s3:ListAllMyBuckets\",\"Resource\":\"*\"}]}", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     credentials: {
    #       access_key_id: "AKIAIOSFODNN7EXAMPLE", 
    #       expiration: Time.parse("2011-07-15T23:28:33.359Z"), 
    #       secret_access_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYzEXAMPLEKEY", 
    #       session_token: "AQoDYXdzEPT//////////wEXAMPLEtc764bNrC9SAPBSM22wDOk4x4HIZ8j4FZTwdQWLWsKWHGBuFqwAeMicRXmxfpSPfIeoIYRqTflfKD8YUuwthAx7mSEI/qkPpKPi/kMcGdQrmGdeehM4IC1NtBmUpp2wUE8phUZampKsburEDy0KPkyQDYwT7WZ0wq5VSXDvp75YU9HFvlRd8Tx6q6fE8YQcHNVXAkiY9q6d+xo0rKwT38xVqr7ZD0u0iPPkUL64lIZbqBAz+scqKmlzm8FDrypNC9Yjc8fPOLn9FX9KSYvKTr4rvx3iSIlTJabIQwj2ICCR/oLxBA==", 
    #     }, 
    #     federated_user: {
    #       arn: "arn:aws:sts::123456789012:federated-user/Bob", 
    #       federated_user_id: "123456789012:Bob", 
    #     }, 
    #     packed_policy_size: 6, 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_federation_token({
    #     name: "userNameType", # required
    #     policy: "sessionPolicyDocumentType",
    #     policy_arns: [
    #       {
    #         arn: "arnType",
    #       },
    #     ],
    #     duration_seconds: 1,
    #   })
    #
    # @example Response structure
    #
    #   resp.credentials.access_key_id #=> String
    #   resp.credentials.secret_access_key #=> String
    #   resp.credentials.session_token #=> String
    #   resp.credentials.expiration #=> Time
    #   resp.federated_user.federated_user_id #=> String
    #   resp.federated_user.arn #=> String
    #   resp.packed_policy_size #=> Integer
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/GetFederationToken AWS API Documentation
    #
    # @overload get_federation_token(params = {})
    # @param [Hash] params ({})
    def get_federation_token(params = {}, options = {})
      req = build_request(:get_federation_token, params)
      req.send_request(options)
    end

    # Returns a set of temporary credentials for an AWS account or IAM user.
    # The credentials consist of an access key ID, a secret access key, and
    # a security token. Typically, you use `GetSessionToken` if you want to
    # use MFA to protect programmatic calls to specific AWS API operations
    # like Amazon EC2 `StopInstances`. MFA-enabled IAM users would need to
    # call `GetSessionToken` and submit an MFA code that is associated with
    # their MFA device. Using the temporary security credentials that are
    # returned from the call, IAM users can then make programmatic calls to
    # API operations that require MFA authentication. If you do not supply a
    # correct MFA code, then the API returns an access denied error. For a
    # comparison of `GetSessionToken` with the other API operations that
    # produce temporary credentials, see [Requesting Temporary Security
    # Credentials][1] and [Comparing the AWS STS API operations][2] in the
    # *IAM User Guide*.
    #
    # The `GetSessionToken` operation must be called by using the long-term
    # AWS security credentials of the AWS account root user or an IAM user.
    # Credentials that are created by IAM users are valid for the duration
    # that you specify. This duration can range from 900 seconds (15
    # minutes) up to a maximum of 129,600 seconds (36 hours), with a default
    # of 43,200 seconds (12 hours). Credentials based on account credentials
    # can range from 900 seconds (15 minutes) up to 3,600 seconds (1 hour),
    # with a default of 1 hour.
    #
    # The temporary security credentials created by `GetSessionToken` can be
    # used to make API calls to any AWS service with the following
    # exceptions:
    #
    # * You cannot call any IAM API operations unless MFA authentication
    #   information is included in the request.
    #
    # * You cannot call any STS API *except* `AssumeRole` or
    #   `GetCallerIdentity`.
    #
    # <note markdown="1"> We recommend that you do not call `GetSessionToken` with AWS account
    # root user credentials. Instead, follow our [best practices][3] by
    # creating one or more IAM users, giving them the necessary permissions,
    # and using IAM users for everyday interaction with AWS.
    #
    #  </note>
    #
    # The credentials that are returned by `GetSessionToken` are based on
    # permissions associated with the user whose credentials were used to
    # call the operation. If `GetSessionToken` is called using AWS account
    # root user credentials, the temporary credentials have root user
    # permissions. Similarly, if `GetSessionToken` is called using the
    # credentials of an IAM user, the temporary credentials have the same
    # permissions as the IAM user.
    #
    # For more information about using `GetSessionToken` to create temporary
    # credentials, go to [Temporary Credentials for Users in Untrusted
    # Environments][4] in the *IAM User Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html
    # [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison
    # [3]: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#create-iam-users
    # [4]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getsessiontoken
    #
    # @option params [Integer] :duration_seconds
    #   The duration, in seconds, that the credentials should remain valid.
    #   Acceptable durations for IAM user sessions range from 900 seconds (15
    #   minutes) to 129,600 seconds (36 hours), with 43,200 seconds (12 hours)
    #   as the default. Sessions for AWS account owners are restricted to a
    #   maximum of 3,600 seconds (one hour). If the duration is longer than
    #   one hour, the session for AWS account owners defaults to one hour.
    #
    # @option params [String] :serial_number
    #   The identification number of the MFA device that is associated with
    #   the IAM user who is making the `GetSessionToken` call. Specify this
    #   value if the IAM user has a policy that requires MFA authentication.
    #   The value is either the serial number for a hardware device (such as
    #   `GAHT12345678`) or an Amazon Resource Name (ARN) for a virtual device
    #   (such as `arn:aws:iam::123456789012:mfa/user`). You can find the
    #   device for an IAM user by going to the AWS Management Console and
    #   viewing the user's security credentials.
    #
    #   The regex used to validate this parameter is a string of characters
    #   consisting of upper- and lower-case alphanumeric characters with no
    #   spaces. You can also include underscores or any of the following
    #   characters: =,.@:/-
    #
    # @option params [String] :token_code
    #   The value provided by the MFA device, if MFA is required. If any
    #   policy requires the IAM user to submit an MFA code, specify this
    #   value. If MFA authentication is required, the user must provide a code
    #   when requesting a set of temporary security credentials. A user who
    #   fails to provide the code receives an "access denied" response when
    #   requesting resources that require MFA authentication.
    #
    #   The format for this parameter, as described by its regex pattern, is a
    #   sequence of six numeric digits.
    #
    # @return [Types::GetSessionTokenResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetSessionTokenResponse#credentials #credentials} => Types::Credentials
    #
    #
    # @example Example: To get temporary credentials for an IAM user or an AWS account
    #
    #   resp = client.get_session_token({
    #     duration_seconds: 3600, 
    #     serial_number: "YourMFASerialNumber", 
    #     token_code: "123456", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     credentials: {
    #       access_key_id: "AKIAIOSFODNN7EXAMPLE", 
    #       expiration: Time.parse("2011-07-11T19:55:29.611Z"), 
    #       secret_access_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYzEXAMPLEKEY", 
    #       session_token: "AQoEXAMPLEH4aoAH0gNCAPyJxz4BlCFFxWNE1OPTgk5TthT+FvwqnKwRcOIfrRh3c/LTo6UDdyJwOOvEVPvLXCrrrUtdnniCEXAMPLE/IvU1dYUg2RVAJBanLiHb4IgRmpRV3zrkuWJOgQs8IZZaIv2BXIa2R4OlgkBN9bkUDNCJiBeb/AXlzBBko7b15fjrBs2+cTQtpZ3CYWFXG8C5zqx37wnOE49mRl/+OtkIKGO7fAE", 
    #     }, 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_session_token({
    #     duration_seconds: 1,
    #     serial_number: "serialNumberType",
    #     token_code: "tokenCodeType",
    #   })
    #
    # @example Response structure
    #
    #   resp.credentials.access_key_id #=> String
    #   resp.credentials.secret_access_key #=> String
    #   resp.credentials.session_token #=> String
    #   resp.credentials.expiration #=> Time
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/GetSessionToken AWS API Documentation
    #
    # @overload get_session_token(params = {})
    # @param [Hash] params ({})
    def get_session_token(params = {}, options = {})
      req = build_request(:get_session_token, params)
      req.send_request(options)
    end

    # @!endgroup

    # @param params ({})
    # @api private
    def build_request(operation_name, params = {})
      handlers = @handlers.for(operation_name)
      context = Seahorse::Client::RequestContext.new(
        operation_name: operation_name,
        operation: config.api.operation(operation_name),
        client: self,
        params: params,
        config: config)
      context[:gem_name] = 'aws-sdk-core'
      context[:gem_version] = '3.53.1'
      Seahorse::Client::Request.new(handlers, context)
    end

    # @api private
    # @deprecated
    def waiter_names
      []
    end

    class << self

      # @api private
      attr_reader :identifier

      # @api private
      def errors_module
        Errors
      end

    end
  end
end
# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/master/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::STS
  module Errors

    extend Aws::Errors::DynamicErrors

    class ExpiredTokenException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::STS::Types::ExpiredTokenException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class IDPCommunicationErrorException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::STS::Types::IDPCommunicationErrorException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class IDPRejectedClaimException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::STS::Types::IDPRejectedClaimException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class InvalidAuthorizationMessageException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::STS::Types::InvalidAuthorizationMessageException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class InvalidIdentityTokenException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::STS::Types::InvalidIdentityTokenException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class MalformedPolicyDocumentException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::STS::Types::MalformedPolicyDocumentException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class PackedPolicyTooLargeException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::STS::Types::PackedPolicyTooLargeException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

    class RegionDisabledException < ServiceError

      # @param [Seahorse::Client::RequestContext] context
      # @param [String] message
      # @param [Aws::STS::Types::RegionDisabledException] data
      def initialize(context, message, data = Aws::EmptyStructure.new)
        super(context, message, data)
      end

      # @return [String]
      def message
        @message || @data[:message]
      end

    end

  end
end
# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/master/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::STS
  class Resource

    # @param options ({})
    # @option options [Client] :client
    def initialize(options = {})
      @client = options[:client] || Client.new(options)
    end

    # @return [Client]
    def client
      @client
    end

  end
end
# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/master/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE


# KG-dev::RubyPacker replaced for aws-sdk-sts/types.rb
# KG-dev::RubyPacker replaced for aws-sdk-sts/client_api.rb
# KG-dev::RubyPacker replaced for aws-sdk-sts/client.rb
# KG-dev::RubyPacker replaced for aws-sdk-sts/errors.rb
# KG-dev::RubyPacker replaced for aws-sdk-sts/resource.rb
# KG-dev::RubyPacker replaced for aws-sdk-sts/customizations.rb

# This module provides support for AWS Security Token Service. This module is available in the
# `aws-sdk-core` gem.
#
# # Client
#
# The {Client} class provides one method for each API operation. Operation
# methods each accept a hash of request parameters and return a response
# structure.
#
# See {Client} for more information.
#
# # Errors
#
# Errors returned from AWS Security Token Service all
# extend {Errors::ServiceError}.
#
#     begin
#       # do stuff
#     rescue Aws::STS::Errors::ServiceError
#       # rescues all service API errors
#     end
#
# See {Errors} for more information.
#
# @service
module Aws::STS

  GEM_VERSION = '3.53.1'

end

# KG-dev::RubyPacker replaced for seahorse.rb

# KG-dev::RubyPacker replaced for aws-sdk-core/deprecations.rb

# credential providers

# KG-dev::RubyPacker replaced for aws-sdk-core/credential_provider.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/refreshing_credentials.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/assume_role_credentials.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/credentials.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/credential_provider_chain.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/ecs_credentials.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/instance_profile_credentials.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/shared_credentials.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/process_credentials.rb

# client modules

# KG-dev::RubyPacker replaced for aws-sdk-core/client_stubs.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/async_client_stubs.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/eager_loader.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/errors.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/pageable_response.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/pager.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/param_converter.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/param_validator.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/shared_config.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/structure.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/type_builder.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/util.rb

# resource classes

# KG-dev::RubyPacker replaced for aws-sdk-core/resources/collection.rb

# logging

# KG-dev::RubyPacker replaced for aws-sdk-core/log/formatter.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/log/param_filter.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/log/param_formatter.rb

# stubbing

# KG-dev::RubyPacker replaced for aws-sdk-core/stubbing/empty_stub.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/stubbing/data_applicator.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/stubbing/stub_data.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/stubbing/xml_error.rb

# stubbing protocols

# KG-dev::RubyPacker replaced for aws-sdk-core/stubbing/protocols/ec2.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/stubbing/protocols/json.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/stubbing/protocols/query.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/stubbing/protocols/rest.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/stubbing/protocols/rest_json.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/stubbing/protocols/rest_xml.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/stubbing/protocols/api_gateway.rb

# protocols

# KG-dev::RubyPacker replaced for aws-sdk-core/rest.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/xml.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/json.rb

# event stream

# KG-dev::RubyPacker replaced for aws-sdk-core/binary.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/event_emitter.rb

# endpoint discovery

# KG-dev::RubyPacker replaced for aws-sdk-core/endpoint_cache.rb

# client metrics

# KG-dev::RubyPacker replaced for aws-sdk-core/client_side_monitoring/request_metrics.rb
# KG-dev::RubyPacker replaced for aws-sdk-core/client_side_monitoring/publisher.rb

# aws-sdk-sts is vendored to support Aws::AssumeRoleCredentials

# KG-dev::RubyPacker replaced for aws-sdk-sts.rb

module Aws

  CORE_GEM_VERSION = File.read(File.expand_path('../../VERSION', __FILE__)).strip

  @config = {}

  class << self

    # @api private
    def shared_config
      enabled = ENV["AWS_SDK_CONFIG_OPT_OUT"] ? false : true
      @shared_config ||= SharedConfig.new(config_enabled: enabled)
    end

    # @return [Hash] Returns a hash of default configuration options shared
    #   by all constructed clients.
    attr_reader :config

    # @param [Hash] config
    def config=(config)
      if Hash === config
        @config = config
      else
        raise ArgumentError, 'configuration object must be a hash'
      end
    end

    # @see (Aws::Partitions.partition)
    def partition(partition_name)
      Aws::Partitions.partition(partition_name)
    end

    # @see (Aws::Partitions.partitions)
    def partitions
      Aws::Partitions.partitions
    end

    # The SDK ships with a ca certificate bundle to use when verifying SSL
    # peer certificates. By default, this cert bundle is *NOT* used. The
    # SDK will rely on the default cert available to OpenSSL. This ensures
    # the cert provided by your OS is used.
    #
    # For cases where the default cert is unavailable, e.g. Windows, you
    # can call this method.
    #
    #     Aws.use_bundled_cert!
    #
    # @return [String] Returns the path to the bundled cert.
    def use_bundled_cert!
      config.delete(:ssl_ca_directory)
      config.delete(:ssl_ca_store)
      config[:ssl_ca_bundle] = File.expand_path(File.join(
        File.dirname(__FILE__),
        '..',
        'ca-bundle.crt'
      ))
    end

    # Close any long-lived connections maintained by the SDK's internal
    # connection pool.
    #
    # Applications that rely heavily on the `fork()` system call on POSIX systems
    # should call this method in the child process directly after fork to ensure
    # there are no race conditions between the parent
    # process and its children
    # for the pooled TCP connections.
    #
    # Child processes that make multi-threaded calls to the SDK should block on
    # this call before beginning work.
    #
    # @return [nil]
    def empty_connection_pools!
      Seahorse::Client::NetHttp::ConnectionPool.pools.each do |pool|
        pool.empty!
      end
    end

    # @api private
    def eager_autoload!(*args)
      msg = 'Aws.eager_autoload is no longer needed, usage of '
      msg << 'autoload has been replaced with require statements'
      warn(msg)
    end

  end
end

end # Cesium::IonExporter
