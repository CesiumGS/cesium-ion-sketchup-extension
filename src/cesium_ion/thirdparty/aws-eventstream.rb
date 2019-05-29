require 'stringio'
require 'tempfile'
require 'zlib'

module Cesium::IonExporter

module Aws
  module EventStream 

    # This class provides method for decoding binary inputs into
    # single or multiple messages (Aws::EventStream::Message).
    #
    # * {#decode} - decodes messages from an IO like object responds
    #   to #read that containing binary data, returning decoded
    #   Aws::EventStream::Message along the way or wrapped in an enumerator
    #
    # ## Examples
    #
    #   decoder = Aws::EventStream::Decoder.new
    #
    #   # decoding from IO
    #   decoder.decode(io) do |message|
    #     message.headers
    #     # => { ... }
    #     message.payload
    #     # => StringIO / Tempfile
    #   end
    #
    #   # alternatively
    #   message_pool = decoder.decode(io)
    #   message_pool.next
    #   # => Aws::EventStream::Message
    #   
    # * {#decode_chunk} - decodes a single message from a chunk of data,
    #   returning message object followed by boolean(indicating eof status
    #   of data) in an array object
    #
    # ## Examples
    #
    #   # chunk containing exactly one message data
    #   message, chunk_eof = decoder.decode_chunk(chunk_str)
    #   message
    #   # => Aws::EventStream::Message
    #   chunk_eof
    #   # => true
    #
    #   # chunk containing a partial message
    #   message, chunk_eof = decoder.decode_chunk(chunk_str)
    #   message
    #   # => nil
    #   chunk_eof
    #   # => true
    #   # chunk data is saved at decoder's message_buffer
    #
    #   # chunk containing more that one data message
    #   message, chunk_eof = decoder.decode_chunk(chunk_str)
    #   message
    #   # => Aws::EventStream::Message
    #   chunk_eof
    #   # => false
    #   # extra chunk data is saved at message_buffer of the decoder
    #
    class Decoder

      include Enumerable

      ONE_MEGABYTE = 1024 * 1024

      # bytes of prelude part, including 4 bytes of
      # total message length, headers length and crc checksum of prelude
      PRELUDE_LENGTH = 12

      # bytes of total overhead in a message, including prelude
      # and 4 bytes total message crc checksum
      OVERHEAD_LENGTH = 16

      # @options options [Boolean] format (true) When `false`
      #   disable user-friendly formatting for message header values
      #   including timestamp and uuid etc.
      #
      def initialize(options = {})
        @format = options.fetch(:format, true)
        @message_buffer = BytesBuffer.new('')
      end

      # @returns [BytesBuffer]
      attr_reader :message_buffer

      # Decodes messages from a binary stream
      #
      # @param [IO#read] io An IO-like object
      #   that responds to `#read`
      #
      # @yieldparam [Message] message
      # @return [Enumerable<Message>, nil] Returns a new Enumerable
      #   containing decoded messages if no block is given
      def decode(io, &block)
        io = BytesBuffer.new(io.read)
        return decode_io(io) unless block_given?
        until io.eof?
          # fetch message only
          yield(decode_message(io).first)
        end
      end

      # Decodes a single message from a chunk of string
      #
      # @param [String] chunk A chunk of string to be decoded,
      #   chunk can contain partial event message to multiple event messages
      #   When not provided, decode data from #message_buffer
      #
      # @return [Array<Message|nil, Boolean>] Returns single decoded message
      #   and boolean pair, the boolean flag indicates whether this chunk
      #   has been fully consumed, unused data is tracked at #message_buffer
      def decode_chunk(chunk = nil)
        @message_buffer.write(chunk) if chunk
        @message_buffer.rewind
        decode_message(@message_buffer)
      end

      private

      def decode_io(io)
        ::Enumerator.new {|e| e << decode_message(io) unless io.eof? }
      end

      def decode_message(io)
        # incomplete message prelude received, leave it in the buffer
        return [nil, true] if io.bytesize < PRELUDE_LENGTH

        # decode prelude
        total_len, headers_len, prelude_buffer = prelude(io)

        # incomplete message received, leave it in the buffer
        return [nil, true] if io.bytesize < total_len

        # decode headers and payload
        headers, payload = context(io, total_len, headers_len, prelude_buffer)

        # track extra message data in the buffer if exists
        # for #decode_chunk, io is @message_buffer
        if eof = io.eof?
          @message_buffer.clear!
        else
          @message_buffer = BytesBuffer.new(@message_buffer.read)
        end

        [Message.new(headers: headers, payload: payload), eof]
      end

      def prelude(io)
        # buffer prelude into bytes buffer
        # prelude contains length of message and headers,
        # followed with CRC checksum of itself
        buffer = BytesBuffer.new(io.read(PRELUDE_LENGTH))

        # prelude checksum takes last 4 bytes
        checksum = Zlib.crc32(buffer.read(PRELUDE_LENGTH - 4))
        unless checksum == unpack_uint32(buffer)
          raise Errors::PreludeChecksumError
        end

        buffer.rewind
        total_len, headers_len, _ = buffer.read.unpack('N*')
        [total_len, headers_len, buffer]
      end

      def context(io, total_len, headers_len, prelude_buffer)
        # buffer rest of the message except prelude length
        # including context and total message checksum
        buffer = BytesBuffer.new(io.read(total_len - PRELUDE_LENGTH))
        context_len = total_len - OVERHEAD_LENGTH

        prelude_buffer.rewind
        checksum = Zlib.crc32(prelude_buffer.read << buffer.read(context_len))
        unless checksum == unpack_uint32(buffer)
          raise Errors::MessageChecksumError
        end

        buffer.rewind
        [
          extract_headers(BytesBuffer.new(buffer.read(headers_len))),
          extract_payload(BytesBuffer.new(buffer.read(context_len - headers_len)))
        ]
      end

      def extract_headers(buffer)
        headers = {}
        until buffer.eof?
          # header key
          key_len = unpack_uint8(buffer)
          key = buffer.read(key_len)

          # header value
          value_type = Types.types[unpack_uint8(buffer)]
          unpack_pattern, value_len, _ = Types.pattern[value_type]
          if !!unpack_pattern == unpack_pattern
            # boolean types won't have value specified
            value = unpack_pattern
          else
            value_len = unpack_uint16(buffer) unless value_len
            value = unpack_pattern ?
              buffer.read(value_len).unpack(unpack_pattern)[0] :
              buffer.read(value_len)
          end

          headers[key] = HeaderValue.new(
            format: @format,
            value: value,
            type: value_type
          )
        end
        headers
      end

      def extract_payload(buffer)
        buffer.bytesize <= ONE_MEGABYTE ?
          payload_stringio(buffer) :
          payload_tempfile(buffer)
      end

      def payload_stringio(buffer)
        StringIO.new(buffer.read)
      end

      def payload_tempfile(buffer)
        payload = Tempfile.new
        payload.binmode
        until buffer.eof?
          payload.write(buffer.read(ONE_MEGABYTE))
        end
        payload.rewind
        payload
      end

      # overhead decode helpers

      def unpack_uint32(buffer)
        buffer.read(4).unpack('N')[0]
      end

      def unpack_uint16(buffer)
        buffer.read(2).unpack('S>')[0]
      end

      def unpack_uint8(buffer)
        buffer.readbyte.unpack('C')[0]
      end
    end

  end
end

module Aws
  module EventStream 

    # This class provides #encode method for encoding
    # Aws::EventStream::Message into binary.
    #
    # * {#encode} - encode Aws::EventStream::Message into binary
    #   when output IO-like object is provided, binary string
    #   would be written to IO. If not, the encoded binary string
    #   would be returned directly
    #
    # ## Examples
    #
    #   message = Aws::EventStream::Message.new(
    #     headers: {
    #       "foo" => Aws::EventStream::HeaderValue.new(
    #         value: "bar", type: "string"
    #        )
    #     },
    #     payload: "payload"
    #   )
    #   encoder = Aws::EventsStream::Encoder.new
    #   file = Tempfile.new
    #
    #   # encode into IO ouput
    #   encoder.encode(message, file)
    #
    #   # get encoded binary string
    #   encoded_message = encoder.encode(message)
    #
    #   file.read == encoded_message
    #   # => true
    #
    class Encoder

      # bytes of total overhead in a message, including prelude
      # and 4 bytes total message crc checksum
      OVERHEAD_LENGTH = 16

      # Maximum header length allowed (after encode) 128kb
      MAX_HEADERS_LENGTH = 131072

      # Maximum payload length allowed (after encode) 16mb
      MAX_PAYLOAD_LENGTH = 16777216

      # Encodes Aws::EventStream::Message to output IO when
      #   provided, else return the encoded binary string
      #
      # @param [Aws::EventStream::Message] message
      #
      # @param [IO#write, nil] io An IO-like object that
      #   responds to `#write`, encoded message will be
      #   written to this IO when provided
      #
      # @return [nil, String] when output IO is provided,
      #   encoded message will be written to that IO, nil
      #   will be returned. Else, encoded binary string is
      #   returned.
      def encode(message, io = nil)
        encoded = encode_message(message).read
        if io
          io.write(encoded)
          io.close
        else
          encoded
        end
      end

      # Encodes an Aws::EventStream::Message
      #   into Aws::EventStream::BytesBuffer
      #
      # @param [Aws::EventStream::Message] msg
      #
      # @return [Aws::EventStream::BytesBuffer]
      def encode_message(message)
        # create context buffer with encode headers
        ctx_buffer = encode_headers(message)
        headers_len = ctx_buffer.bytesize
        # encode payload
        if message.payload.length > MAX_PAYLOAD_LENGTH
          raise Aws::EventStream::Errors::EventPayloadLengthExceedError.new
        end
        ctx_buffer << message.payload.read
        total_len = ctx_buffer.bytesize + OVERHEAD_LENGTH

        # create message buffer with prelude section
        buffer = prelude(total_len, headers_len)

        # append message context (headers, payload)
        buffer << ctx_buffer.read
        # append message checksum
        buffer << pack_uint32(Zlib.crc32(buffer.read))

        # write buffered message to io
        buffer.rewind
        buffer
      end

      # Encodes headers part of an Aws::EventStream::Message
      #   into Aws::EventStream::BytesBuffer
      #
      # @param [Aws::EventStream::Message] msg
      #
      # @return [Aws::EventStream::BytesBuffer]
      def encode_headers(msg)
        buffer = BytesBuffer.new('')
        msg.headers.each do |k, v|
          # header key
          buffer << pack_uint8(k.bytesize)
          buffer << k

          # header value
          pattern, val_len, idx = Types.pattern[v.type]
          buffer << pack_uint8(idx)
          # boolean types doesn't need to specify value
          next if !!pattern == pattern
          buffer << pack_uint16(v.value.bytesize) unless val_len
          pattern ? buffer << [v.value].pack(pattern) :
            buffer << v.value
        end
        if buffer.bytesize > MAX_HEADERS_LENGTH
          raise Aws::EventStream::Errors::EventHeadersLengthExceedError.new
        end
        buffer
      end

      private

      def prelude(total_len, headers_len)
        BytesBuffer.new(pack_uint32([
          total_len,
          headers_len,
          Zlib.crc32(pack_uint32([total_len, headers_len]))
        ]))
      end

      # overhead encode helpers

      def pack_uint8(val)
        [val].pack('C')
      end

      def pack_uint16(val)
        [val].pack('S>')
      end

      def pack_uint32(val)
        if val.respond_to?(:each)
          val.pack('N*')
        else
          [val].pack('N')
        end
      end

    end

  end
end
module Aws
  module EventStream 

    # @api private
    class BytesBuffer

      # This Util class is for Decoder/Encoder usage only
      # Not for public common bytes buffer usage
      def initialize(data)
        @data = data
        @pos = 0
      end

      def read(len = nil, offset = 0)
        return '' if len == 0 || bytesize == 0
        unless eof?
          start_byte = @pos + offset
          end_byte = len ?
            start_byte + len - 1 :
            bytesize - 1

          error = Errors::ReadBytesExceedLengthError.new(end_byte, bytesize)
          raise error if end_byte >= bytesize

          @pos = end_byte + 1
          @data[start_byte..end_byte]
        end
      end

      def readbyte
        unless eof?
          @pos += 1
          @data[@pos - 1]
        end
      end

      def write(bytes)
        @data <<= bytes
        bytes.bytesize
      end
      alias_method :<<, :write

      def rewind
        @pos = 0
      end

      def eof?
        @pos == bytesize
      end

      def bytesize
        @data.bytesize
      end

      def tell
        @pos
      end

      def clear!
        @data = ''
        @pos = 0
      end
    end

  end
end
module Aws
  module EventStream
    class Message

      def initialize(options)
        @headers = options[:headers] || {}
        @payload = options[:payload] || StringIO.new
      end

      # @return [Hash] headers of a message
      attr_reader :headers

      # @return [IO] payload of a message, size not exceed 16MB.
      #   StringIO is returned for <= 1MB payload
      #   Tempfile is returned for > 1MB payload
      attr_reader :payload

    end
  end
end
module Aws
  module EventStream

    class HeaderValue

      def initialize(options)
        @type = options.fetch(:type)
        @value = options[:format] ?
          format_value(options.fetch(:value)) :
          options.fetch(:value)
      end

      attr_reader :value

      # @return [String] type of the header value
      #   complete type list see Aws::EventStream::Types
      attr_reader :type

      private

      def format_value(value)
        case @type
        when 'timestamp' then format_timestamp(value)
        when 'uuid' then format_uuid(value)
        else
          value
        end
      end

      def format_uuid(value)
        bytes = value.bytes
        # For user-friendly uuid representation,
        # format binary bytes into uuid string format
        uuid_pattern = [ [ 3, 2, 1, 0 ], [ 5, 4 ], [ 7, 6 ], [ 8, 9 ], 10..15 ]
        uuid_pattern.map {|p| p.map {|n| "%02x" % bytes.to_a[n] }.join }.join('-')
      end

      def format_timestamp(value)
        # millis_since_epoch to sec_since_epoch
        Time.at(value / 1000.0)
      end

    end

  end
end
module Aws
  module EventStream

    # Message Header Value Types
    module Types

      def self.types
        [
          'bool_true',
          'bool_false',
          'byte',
          'short',
          'integer',
          'long',
          'bytes',
          'string',
          'timestamp',
          'uuid'
        ]
      end

      # pack/unpack pattern, byte size, type idx
      def self.pattern
        {
          'bool_true' => [true, 0, 0],
          'bool_false' => [false, 0, 1],
          'byte' => ["c", 1, 2],
          'short' => ["s>", 2, 3],
          'integer' => ["l>", 4, 4],
          'long' => ["q>", 8, 5],
          'bytes' => [nil, nil, 6],
          'string' => [nil, nil, 7],
          'timestamp' => ["q>", 8, 8],
          'uuid' => [nil, 16, 9]
        }
      end

    end
  end
end
module Aws
  module EventStream
    module Errors

      # Raised when reading bytes exceed buffer total bytes
      class ReadBytesExceedLengthError < RuntimeError
        def initialize(target_byte, total_len)
          msg = "Attempting reading bytes to offset #{target_byte} exceeds"\
            " buffer length of #{total_len}"
          super(msg)
        end
      end

      # Raise when insufficient bytes of a message is received
      class IncompleteMessageError < RuntimeError
        def initialize(*args)
          super('Not enough bytes for event message')
        end
      end

      class PreludeChecksumError < RuntimeError
        def initialize(*args)
          super('Prelude checksum mismatch')
        end
      end

      class MessageChecksumError < RuntimeError
        def initialize(*args)
          super('Message checksum mismatch')
        end
      end

      class EventPayloadLengthExceedError < RuntimeError
        def initialize(*args)
          super("Payload length of a message should be under 16mb.")
        end
      end

      class EventHeadersLengthExceedError < RuntimeError
        def initialize(*args)
          super("Encoded headers length of a message should be under 128kb.")
        end
      end

    end
  end
end
# KG-dev::RubyPacker replaced for aws-eventstream/decoder.rb
# KG-dev::RubyPacker replaced for aws-eventstream/encoder.rb

# KG-dev::RubyPacker replaced for aws-eventstream/bytes_buffer.rb
# KG-dev::RubyPacker replaced for aws-eventstream/message.rb
# KG-dev::RubyPacker replaced for aws-eventstream/header_value.rb
# KG-dev::RubyPacker replaced for aws-eventstream/types.rb
# KG-dev::RubyPacker replaced for aws-eventstream/errors.rb

end # Cesium::IonExporter