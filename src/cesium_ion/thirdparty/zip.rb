module Zip
  class DOSTime < Time #:nodoc:all
    # MS-DOS File Date and Time format as used in Interrupt 21H Function 57H:

    # Register CX, the Time:
    # Bits 0-4  2 second increments (0-29)
    # Bits 5-10 minutes (0-59)
    # bits 11-15 hours (0-24)

    # Register DX, the Date:
    # Bits 0-4 day (1-31)
    # bits 5-8 month (1-12)
    # bits 9-15 year (four digit year minus 1980)

    def to_binary_dos_time
      (sec / 2) +
        (min << 5) +
        (hour << 11)
    end

    def to_binary_dos_date
      day +
        (month << 5) +
        ((year - 1980) << 9)
    end

    # Dos time is only stored with two seconds accuracy
    def dos_equals(other)
      to_i / 2 == other.to_i / 2
    end

    def self.parse_binary_dos_format(binaryDosDate, binaryDosTime)
      second = 2 * (0b11111 & binaryDosTime)
      minute = (0b11111100000 & binaryDosTime) >> 5
      hour   = (0b1111100000000000 & binaryDosTime) >> 11
      day    = (0b11111 & binaryDosDate)
      month  = (0b111100000 & binaryDosDate) >> 5
      year   = ((0b1111111000000000 & binaryDosDate) >> 9) + 1980
      begin
        local(year, month, day, hour, minute, second)
      end
    end
  end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
module Zip
  module IOExtras #:nodoc:
    CHUNK_SIZE = 131_072

    RANGE_ALL = 0..-1

    class << self
      def copy_stream(ostream, istream)
        ostream.write(istream.read(CHUNK_SIZE, '')) until istream.eof?
      end

      def copy_stream_n(ostream, istream, nbytes)
        toread = nbytes
        while toread > 0 && !istream.eof?
          tr = toread > CHUNK_SIZE ? CHUNK_SIZE : toread
          ostream.write(istream.read(tr, ''))
          toread -= tr
        end
      end
    end

    # Implements kind_of? in order to pretend to be an IO object
    module FakeIO
      def kind_of?(object)
        object == IO || super
      end
    end
  end # IOExtras namespace module
end

# KG-dev::RubyPacker replaced for zip/ioextras/abstract_input_stream.rb
# KG-dev::RubyPacker replaced for zip/ioextras/abstract_output_stream.rb

# Copyright (C) 2002-2004 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
module Zip
  module IOExtras
    # Implements many of the convenience methods of IO
    # such as gets, getc, readline and readlines
    # depends on: input_finished?, produce_input and read
    module AbstractInputStream
      include Enumerable
      include FakeIO

      def initialize
        super
        @lineno        = 0
        @pos           = 0
        @output_buffer = ''
      end

      attr_accessor :lineno
      attr_reader :pos

      def read(number_of_bytes = nil, buf = '')
        tbuf = if @output_buffer.bytesize > 0
                 if number_of_bytes <= @output_buffer.bytesize
                   @output_buffer.slice!(0, number_of_bytes)
                 else
                   number_of_bytes -= @output_buffer.bytesize if number_of_bytes
                   rbuf = sysread(number_of_bytes, buf)
                   out  = @output_buffer
                   out << rbuf if rbuf
                   @output_buffer = ''
                   out
                 end
               else
                 sysread(number_of_bytes, buf)
               end

        if tbuf.nil? || tbuf.empty?
          return nil if number_of_bytes
          return ''
        end

        @pos += tbuf.length

        if buf
          buf.replace(tbuf)
        else
          buf = tbuf
        end
        buf
      end

      def readlines(a_sep_string = $/)
        ret_val = []
        each_line(a_sep_string) { |line| ret_val << line }
        ret_val
      end

      def gets(a_sep_string = $/, number_of_bytes = nil)
        @lineno = @lineno.next

        if number_of_bytes.respond_to?(:to_int)
          number_of_bytes = number_of_bytes.to_int
          a_sep_string = a_sep_string.to_str if a_sep_string
        elsif a_sep_string.respond_to?(:to_int)
          number_of_bytes = a_sep_string.to_int
          a_sep_string    = $/
        else
          number_of_bytes = nil
          a_sep_string = a_sep_string.to_str if a_sep_string
        end

        return read(number_of_bytes) if a_sep_string.nil?
        a_sep_string = "#{$/}#{$/}" if a_sep_string.empty?

        buffer_index = 0
        over_limit   = (number_of_bytes && @output_buffer.bytesize >= number_of_bytes)
        while (match_index = @output_buffer.index(a_sep_string, buffer_index)).nil? && !over_limit
          buffer_index = [buffer_index, @output_buffer.bytesize - a_sep_string.bytesize].max
          return @output_buffer.empty? ? nil : flush if input_finished?
          @output_buffer << produce_input
          over_limit = (number_of_bytes && @output_buffer.bytesize >= number_of_bytes)
        end
        sep_index = [match_index + a_sep_string.bytesize, number_of_bytes || @output_buffer.bytesize].min
        @pos += sep_index
        @output_buffer.slice!(0...sep_index)
      end

      def ungetc(byte)
        @output_buffer = byte.chr + @output_buffer
      end

      def flush
        ret_val        = @output_buffer
        @output_buffer = ''
        ret_val
      end

      def readline(a_sep_string = $/)
        ret_val = gets(a_sep_string)
        raise EOFError unless ret_val
        ret_val
      end

      def each_line(a_sep_string = $/)
        yield readline(a_sep_string) while true
      rescue EOFError
      end

      alias_method :each, :each_line
    end
  end
end
module Zip
  module IOExtras
    # Implements many of the output convenience methods of IO.
    # relies on <<
    module AbstractOutputStream
      include FakeIO

      def write(data)
        self << data
        data.to_s.bytesize
      end

      def print(*params)
        self << params.join($,) << $\.to_s
      end

      def printf(a_format_string, *params)
        self << format(a_format_string, *params)
      end

      def putc(an_object)
        self << case an_object
                when Integer
                  an_object.chr
                when String
                  an_object
                else
                  raise TypeError, 'putc: Only Integer and String supported'
                end
        an_object
      end

      def puts(*params)
        params << "\n" if params.empty?
        params.flatten.each do |element|
          val = element.to_s
          self << val
          self << "\n" unless val[-1, 1] == "\n"
        end
      end
    end
  end
end
require 'pathname'
module Zip
  class Entry
    STORED   = 0
    DEFLATED = 8
    # Language encoding flag (EFS) bit
    EFS = 0b100000000000

    attr_accessor :comment, :compressed_size, :crc, :extra, :compression_method,
                  :name, :size, :local_header_offset, :zipfile, :fstype, :external_file_attributes,
                  :internal_file_attributes,
                  :gp_flags, :header_signature, :follow_symlinks,
                  :restore_times, :restore_permissions, :restore_ownership,
                  :unix_uid, :unix_gid, :unix_perms,
                  :dirty
    attr_reader :ftype, :filepath # :nodoc:

    def set_default_vars_values
      @local_header_offset      = 0
      @local_header_size        = nil # not known until local entry is created or read
      @internal_file_attributes = 1
      @external_file_attributes = 0
      @header_signature         = ::Zip::CENTRAL_DIRECTORY_ENTRY_SIGNATURE

      @version_needed_to_extract = VERSION_NEEDED_TO_EXTRACT
      @version                   = VERSION_MADE_BY

      @ftype           = nil          # unspecified or unknown
      @filepath        = nil
      @gp_flags        = 0
      if ::Zip.unicode_names
        @gp_flags |= EFS
        @version = 63
      end
      @follow_symlinks = false

      @restore_times       = true
      @restore_permissions = false
      @restore_ownership   = false
      # BUG: need an extra field to support uid/gid's
      @unix_uid            = nil
      @unix_gid            = nil
      @unix_perms          = nil
      # @posix_acl = nil
      # @ntfs_acl = nil
      @dirty               = false
    end

    def check_name(name)
      return unless name.start_with?('/')
      raise ::Zip::EntryNameError, "Illegal ZipEntry name '#{name}', name must not start with /"
    end

    def initialize(*args)
      name = args[1] || ''
      check_name(name)

      set_default_vars_values
      @fstype = ::Zip::RUNNING_ON_WINDOWS ? ::Zip::FSTYPE_FAT : ::Zip::FSTYPE_UNIX

      @zipfile            = args[0] || ''
      @name               = name
      @comment            = args[2] || ''
      @extra              = args[3] || ''
      @compressed_size    = args[4] || 0
      @crc                = args[5] || 0
      @compression_method = args[6] || ::Zip::Entry::DEFLATED
      @size               = args[7] || 0
      @time               = args[8] || ::Zip::DOSTime.now

      @ftype = name_is_directory? ? :directory : :file
      @extra = ::Zip::ExtraField.new(@extra.to_s) unless @extra.is_a?(::Zip::ExtraField)
    end

    def time
      if @extra['UniversalTime']
        @extra['UniversalTime'].mtime
      elsif @extra['NTFS']
        @extra['NTFS'].mtime
      else
        # Standard time field in central directory has local time
        # under archive creator. Then, we can't get timezone.
        @time
      end
    end

    alias mtime time

    def time=(value)
      unless @extra.member?('UniversalTime') || @extra.member?('NTFS')
        @extra.create('UniversalTime')
      end
      (@extra['UniversalTime'] || @extra['NTFS']).mtime = value
      @time                         = value
    end

    def file_type_is?(type)
      raise InternalError, "current filetype is unknown: #{inspect}" unless @ftype
      @ftype == type
    end

    # Dynamic checkers
    %w[directory file symlink].each do |k|
      define_method "#{k}?" do
        file_type_is?(k.to_sym)
      end
    end

    def name_is_directory? #:nodoc:all
      @name.end_with?('/')
    end

    # Is the name a relative path, free of `..` patterns that could lead to
    # path traversal attacks? This does NOT handle symlinks; if the path
    # contains symlinks, this check is NOT enough to guarantee safety.
    def name_safe?
      cleanpath = Pathname.new(@name).cleanpath
      return false unless cleanpath.relative?
      root = ::File::SEPARATOR
      naive_expanded_path = ::File.join(root, cleanpath.to_s)
      ::File.absolute_path(cleanpath.to_s, root) == naive_expanded_path
    end

    def local_entry_offset #:nodoc:all
      local_header_offset + @local_header_size
    end

    def name_size
      @name ? @name.bytesize : 0
    end

    def extra_size
      @extra ? @extra.local_size : 0
    end

    def comment_size
      @comment ? @comment.bytesize : 0
    end

    def calculate_local_header_size #:nodoc:all
      LOCAL_ENTRY_STATIC_HEADER_LENGTH + name_size + extra_size
    end

    # check before rewriting an entry (after file sizes are known)
    # that we didn't change the header size (and thus clobber file data or something)
    def verify_local_header_size!
      return if @local_header_size.nil?
      new_size = calculate_local_header_size
      raise Error, "local header size changed (#{@local_header_size} -> #{new_size})" if @local_header_size != new_size
    end

    def cdir_header_size #:nodoc:all
      CDIR_ENTRY_STATIC_HEADER_LENGTH + name_size +
        (@extra ? @extra.c_dir_size : 0) + comment_size
    end

    def next_header_offset #:nodoc:all
      local_entry_offset + compressed_size + data_descriptor_size
    end

    # Extracts entry to file dest_path (defaults to @name).
    # NB: The caller is responsible for making sure dest_path is safe, if it
    # is passed.
    def extract(dest_path = nil, &block)
      if dest_path.nil? && !name_safe?
        puts "WARNING: skipped #{@name} as unsafe"
        return self
      end

      dest_path ||= @name
      block ||= proc { ::Zip.on_exists_proc }

      if directory? || file? || symlink?
        __send__("create_#{@ftype}", dest_path, &block)
      else
        raise "unknown file type #{inspect}"
      end

      self
    end

    def to_s
      @name
    end

    class << self
      def read_zip_short(io) # :nodoc:
        io.read(2).unpack('v')[0]
      end

      def read_zip_long(io) # :nodoc:
        io.read(4).unpack('V')[0]
      end

      def read_zip_64_long(io) # :nodoc:
        io.read(8).unpack('Q<')[0]
      end

      def read_c_dir_entry(io) #:nodoc:all
        path = if io.respond_to?(:path)
                 io.path
               else
                 io
               end
        entry = new(path)
        entry.read_c_dir_entry(io)
        entry
      rescue Error
        nil
      end

      def read_local_entry(io)
        entry = new(io)
        entry.read_local_entry(io)
        entry
      rescue Error
        nil
      end
    end

    public

    def unpack_local_entry(buf)
      @header_signature,
        @version,
        @fstype,
        @gp_flags,
        @compression_method,
        @last_mod_time,
        @last_mod_date,
        @crc,
        @compressed_size,
        @size,
        @name_length,
        @extra_length = buf.unpack('VCCvvvvVVVvv')
    end

    def read_local_entry(io) #:nodoc:all
      @local_header_offset = io.tell

      static_sized_fields_buf = io.read(::Zip::LOCAL_ENTRY_STATIC_HEADER_LENGTH) || ''

      unless static_sized_fields_buf.bytesize == ::Zip::LOCAL_ENTRY_STATIC_HEADER_LENGTH
        raise Error, 'Premature end of file. Not enough data for zip entry local header'
      end

      unpack_local_entry(static_sized_fields_buf)

      unless @header_signature == ::Zip::LOCAL_ENTRY_SIGNATURE
        raise ::Zip::Error, "Zip local header magic not found at location '#{local_header_offset}'"
      end
      set_time(@last_mod_date, @last_mod_time)

      @name = io.read(@name_length)
      extra = io.read(@extra_length)

      @name.tr!('\\', '/')
      if ::Zip.force_entry_names_encoding
        @name.force_encoding(::Zip.force_entry_names_encoding)
      end

      if extra && extra.bytesize != @extra_length
        raise ::Zip::Error, 'Truncated local zip entry header'
      else
        if @extra.is_a?(::Zip::ExtraField)
          @extra.merge(extra) if extra
        else
          @extra = ::Zip::ExtraField.new(extra)
        end
      end
      parse_zip64_extra(true)
      @local_header_size = calculate_local_header_size
    end

    def pack_local_entry
      zip64 = @extra['Zip64']
      [::Zip::LOCAL_ENTRY_SIGNATURE,
       @version_needed_to_extract, # version needed to extract
       @gp_flags, # @gp_flags
       @compression_method,
       @time.to_binary_dos_time, # @last_mod_time
       @time.to_binary_dos_date, # @last_mod_date
       @crc,
       zip64 && zip64.compressed_size ? 0xFFFFFFFF : @compressed_size,
       zip64 && zip64.original_size ? 0xFFFFFFFF : @size,
       name_size,
       @extra ? @extra.local_size : 0].pack('VvvvvvVVVvv')
    end

    def write_local_entry(io, rewrite = false) #:nodoc:all
      prep_zip64_extra(true)
      verify_local_header_size! if rewrite
      @local_header_offset = io.tell

      io << pack_local_entry

      io << @name
      io << @extra.to_local_bin if @extra
      @local_header_size = io.tell - @local_header_offset
    end

    def unpack_c_dir_entry(buf)
      @header_signature,
        @version, # version of encoding software
        @fstype, # filesystem type
        @version_needed_to_extract,
        @gp_flags,
        @compression_method,
        @last_mod_time,
        @last_mod_date,
        @crc,
        @compressed_size,
        @size,
        @name_length,
        @extra_length,
        @comment_length,
        _, # diskNumberStart
        @internal_file_attributes,
        @external_file_attributes,
        @local_header_offset,
        @name,
        @extra,
        @comment = buf.unpack('VCCvvvvvVVVvvvvvVV')
    end

    def set_ftype_from_c_dir_entry
      @ftype = case @fstype
               when ::Zip::FSTYPE_UNIX
                 @unix_perms = (@external_file_attributes >> 16) & 0o7777
                 case (@external_file_attributes >> 28)
                 when ::Zip::FILE_TYPE_DIR
                   :directory
                 when ::Zip::FILE_TYPE_FILE
                   :file
                 when ::Zip::FILE_TYPE_SYMLINK
                   :symlink
                 else
                   # best case guess for whether it is a file or not
                   # Otherwise this would be set to unknown and that entry would never be able to extracted
                   if name_is_directory?
                     :directory
                   else
                     :file
                   end
                 end
               else
                 if name_is_directory?
                   :directory
                 else
                   :file
                 end
               end
    end

    def check_c_dir_entry_static_header_length(buf)
      return if buf.bytesize == ::Zip::CDIR_ENTRY_STATIC_HEADER_LENGTH
      raise Error, 'Premature end of file. Not enough data for zip cdir entry header'
    end

    def check_c_dir_entry_signature
      return if header_signature == ::Zip::CENTRAL_DIRECTORY_ENTRY_SIGNATURE
      raise Error, "Zip local header magic not found at location '#{local_header_offset}'"
    end

    def check_c_dir_entry_comment_size
      return if @comment && @comment.bytesize == @comment_length
      raise ::Zip::Error, 'Truncated cdir zip entry header'
    end

    def read_c_dir_extra_field(io)
      if @extra.is_a?(::Zip::ExtraField)
        @extra.merge(io.read(@extra_length))
      else
        @extra = ::Zip::ExtraField.new(io.read(@extra_length))
      end
    end

    def read_c_dir_entry(io) #:nodoc:all
      static_sized_fields_buf = io.read(::Zip::CDIR_ENTRY_STATIC_HEADER_LENGTH)
      check_c_dir_entry_static_header_length(static_sized_fields_buf)
      unpack_c_dir_entry(static_sized_fields_buf)
      check_c_dir_entry_signature
      set_time(@last_mod_date, @last_mod_time)
      @name = io.read(@name_length)
      if ::Zip.force_entry_names_encoding
        @name.force_encoding(::Zip.force_entry_names_encoding)
      end
      read_c_dir_extra_field(io)
      @comment = io.read(@comment_length)
      check_c_dir_entry_comment_size
      set_ftype_from_c_dir_entry
      parse_zip64_extra(false)
    end

    def file_stat(path) # :nodoc:
      if @follow_symlinks
        ::File.stat(path)
      else
        ::File.lstat(path)
      end
    end

    def get_extra_attributes_from_path(path) # :nodoc:
      return if Zip::RUNNING_ON_WINDOWS
      stat        = file_stat(path)
      @unix_uid   = stat.uid
      @unix_gid   = stat.gid
      @unix_perms = stat.mode & 0o7777
    end

    def set_unix_permissions_on_path(dest_path)
      # BUG: does not update timestamps into account
      # ignore setuid/setgid bits by default.  honor if @restore_ownership
      unix_perms_mask = 0o1777
      unix_perms_mask = 0o7777 if @restore_ownership
      ::FileUtils.chmod(@unix_perms & unix_perms_mask, dest_path) if @restore_permissions && @unix_perms
      ::FileUtils.chown(@unix_uid, @unix_gid, dest_path) if @restore_ownership && @unix_uid && @unix_gid && ::Process.egid == 0
      # File::utimes()
    end

    def set_extra_attributes_on_path(dest_path) # :nodoc:
      return unless file? || directory?

      case @fstype
      when ::Zip::FSTYPE_UNIX
        set_unix_permissions_on_path(dest_path)
      end
    end

    def pack_c_dir_entry
      zip64 = @extra['Zip64']
      [
        @header_signature,
        @version, # version of encoding software
        @fstype, # filesystem type
        @version_needed_to_extract, # @versionNeededToExtract
        @gp_flags, # @gp_flags
        @compression_method,
        @time.to_binary_dos_time, # @last_mod_time
        @time.to_binary_dos_date, # @last_mod_date
        @crc,
        zip64 && zip64.compressed_size ? 0xFFFFFFFF : @compressed_size,
        zip64 && zip64.original_size ? 0xFFFFFFFF : @size,
        name_size,
        @extra ? @extra.c_dir_size : 0,
        comment_size,
        zip64 && zip64.disk_start_number ? 0xFFFF : 0, # disk number start
        @internal_file_attributes, # file type (binary=0, text=1)
        @external_file_attributes, # native filesystem attributes
        zip64 && zip64.relative_header_offset ? 0xFFFFFFFF : @local_header_offset,
        @name,
        @extra,
        @comment
      ].pack('VCCvvvvvVVVvvvvvVV')
    end

    def write_c_dir_entry(io) #:nodoc:all
      prep_zip64_extra(false)
      case @fstype
      when ::Zip::FSTYPE_UNIX
        ft = case @ftype
             when :file
               @unix_perms ||= 0o644
               ::Zip::FILE_TYPE_FILE
             when :directory
               @unix_perms ||= 0o755
               ::Zip::FILE_TYPE_DIR
             when :symlink
               @unix_perms ||= 0o755
               ::Zip::FILE_TYPE_SYMLINK
             end

        unless ft.nil?
          @external_file_attributes = (ft << 12 | (@unix_perms & 0o7777)) << 16
        end
      end

      io << pack_c_dir_entry

      io << @name
      io << (@extra ? @extra.to_c_dir_bin : '')
      io << @comment
    end

    def ==(other)
      return false unless other.class == self.class
      # Compares contents of local entry and exposed fields
      keys_equal = %w[compression_method crc compressed_size size name extra filepath].all? do |k|
        other.__send__(k.to_sym) == __send__(k.to_sym)
      end
      keys_equal && time.dos_equals(other.time)
    end

    def <=>(other)
      to_s <=> other.to_s
    end

    # Returns an IO like object for the given ZipEntry.
    # Warning: may behave weird with symlinks.
    def get_input_stream(&block)
      if @ftype == :directory
        yield ::Zip::NullInputStream if block_given?
        ::Zip::NullInputStream
      elsif @filepath
        case @ftype
        when :file
          ::File.open(@filepath, 'rb', &block)
        when :symlink
          linkpath = ::File.readlink(@filepath)
          stringio = ::StringIO.new(linkpath)
          yield(stringio) if block_given?
          stringio
        else
          raise "unknown @file_type #{@ftype}"
        end
      else
        zis = ::Zip::InputStream.new(@zipfile, local_header_offset)
        zis.instance_variable_set(:@complete_entry, self)
        zis.get_next_entry
        if block_given?
          begin
            yield(zis)
          ensure
            zis.close
          end
        else
          zis
        end
      end
    end

    def gather_fileinfo_from_srcpath(src_path) # :nodoc:
      stat   = file_stat(src_path)
      @ftype = case stat.ftype
               when 'file'
                 if name_is_directory?
                   raise ArgumentError,
                         "entry name '#{newEntry}' indicates directory entry, but " \
                             "'#{src_path}' is not a directory"
                 end
                 :file
               when 'directory'
                 @name += '/' unless name_is_directory?
                 :directory
               when 'link'
                 if name_is_directory?
                   raise ArgumentError,
                         "entry name '#{newEntry}' indicates directory entry, but " \
                             "'#{src_path}' is not a directory"
                 end
                 :symlink
               else
                 raise "unknown file type: #{src_path.inspect} #{stat.inspect}"
               end

      @filepath = src_path
      get_extra_attributes_from_path(@filepath)
    end

    def write_to_zip_output_stream(zip_output_stream) #:nodoc:all
      if @ftype == :directory
        zip_output_stream.put_next_entry(self, nil, nil, ::Zip::Entry::STORED)
      elsif @filepath
        zip_output_stream.put_next_entry(self, nil, nil, compression_method || ::Zip::Entry::DEFLATED)
        get_input_stream { |is| ::Zip::IOExtras.copy_stream(zip_output_stream, is) }
      else
        zip_output_stream.copy_raw_entry(self)
      end
    end

    def parent_as_string
      entry_name  = name.chomp('/')
      slash_index = entry_name.rindex('/')
      slash_index ? entry_name.slice(0, slash_index + 1) : nil
    end

    def get_raw_input_stream(&block)
      if @zipfile.respond_to?(:seek) && @zipfile.respond_to?(:read)
        yield @zipfile
      else
        ::File.open(@zipfile, 'rb', &block)
      end
    end

    def clean_up
      # By default, do nothing
    end

    private

    def set_time(binary_dos_date, binary_dos_time)
      @time = ::Zip::DOSTime.parse_binary_dos_format(binary_dos_date, binary_dos_time)
    rescue ArgumentError
      warn 'Invalid date/time in zip entry' if ::Zip.warn_invalid_date
    end

    def create_file(dest_path, _continue_on_exists_proc = proc { Zip.continue_on_exists_proc })
      if ::File.exist?(dest_path) && !yield(self, dest_path)
        raise ::Zip::DestinationFileExistsError,
              "Destination '#{dest_path}' already exists"
      end
      ::File.open(dest_path, 'wb') do |os|
        get_input_stream do |is|
          set_extra_attributes_on_path(dest_path)

          buf = ''.dup
          while (buf = is.sysread(::Zip::Decompressor::CHUNK_SIZE, buf))
            os << buf
          end
        end
      end
    end

    def create_directory(dest_path)
      return if ::File.directory?(dest_path)
      if ::File.exist?(dest_path)
        if block_given? && yield(self, dest_path)
          ::FileUtils.rm_f dest_path
        else
          raise ::Zip::DestinationFileExistsError,
                "Cannot create directory '#{dest_path}'. " \
                    'A file already exists with that name'
        end
      end
      ::FileUtils.mkdir_p(dest_path)
      set_extra_attributes_on_path(dest_path)
    end

    # BUG: create_symlink() does not use &block
    def create_symlink(dest_path)
      # TODO: Symlinks pose security challenges. Symlink support temporarily
      # removed in view of https://github.com/rubyzip/rubyzip/issues/369 .
      puts "WARNING: skipped symlink #{dest_path}"
    end

    # apply missing data from the zip64 extra information field, if present
    # (required when file sizes exceed 2**32, but can be used for all files)
    def parse_zip64_extra(for_local_header) #:nodoc:all
      return if @extra['Zip64'].nil?
      if for_local_header
        @size, @compressed_size = @extra['Zip64'].parse(@size, @compressed_size)
      else
        @size, @compressed_size, @local_header_offset = @extra['Zip64'].parse(@size, @compressed_size, @local_header_offset)
      end
    end

    def data_descriptor_size
      (@gp_flags & 0x0008) > 0 ? 16 : 0
    end

    # create a zip64 extra information field if we need one
    def prep_zip64_extra(for_local_header) #:nodoc:all
      return unless ::Zip.write_zip64_support
      need_zip64 = @size >= 0xFFFFFFFF || @compressed_size >= 0xFFFFFFFF
      need_zip64 ||= @local_header_offset >= 0xFFFFFFFF unless for_local_header
      if need_zip64
        @version_needed_to_extract = VERSION_NEEDED_TO_EXTRACT_ZIP64
        @extra.delete('Zip64Placeholder')
        zip64 = @extra.create('Zip64')
        if for_local_header
          # local header always includes size and compressed size
          zip64.original_size = @size
          zip64.compressed_size = @compressed_size
        else
          # central directory entry entries include whichever fields are necessary
          zip64.original_size = @size if @size >= 0xFFFFFFFF
          zip64.compressed_size = @compressed_size if @compressed_size >= 0xFFFFFFFF
          zip64.relative_header_offset = @local_header_offset if @local_header_offset >= 0xFFFFFFFF
        end
      else
        @extra.delete('Zip64')

        # if this is a local header entry, create a placeholder
        # so we have room to write a zip64 extra field afterward
        # (we won't know if it's needed until the file data is written)
        if for_local_header
          @extra.create('Zip64Placeholder')
        else
          @extra.delete('Zip64Placeholder')
        end
      end
    end
  end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
module Zip
  class ExtraField < Hash
    ID_MAP = {}

    def initialize(binstr = nil)
      merge(binstr) if binstr
    end

    def extra_field_type_exist(binstr, id, len, i)
      field_name = ID_MAP[id].name
      if member?(field_name)
        self[field_name].merge(binstr[i, len + 4])
      else
        field_obj        = ID_MAP[id].new(binstr[i, len + 4])
        self[field_name] = field_obj
      end
    end

    def extra_field_type_unknown(binstr, len, i)
      create_unknown_item unless self['Unknown']
      if !len || len + 4 > binstr[i..-1].bytesize
        self['Unknown'] << binstr[i..-1]
        return
      end
      self['Unknown'] << binstr[i, len + 4]
    end

    def create_unknown_item
      s = ''.dup
      class << s
        alias_method :to_c_dir_bin, :to_s
        alias_method :to_local_bin, :to_s
      end
      self['Unknown'] = s
    end

    def merge(binstr)
      return if binstr.empty?
      i = 0
      while i < binstr.bytesize
        id  = binstr[i, 2]
        len = binstr[i + 2, 2].to_s.unpack('v').first
        if id && ID_MAP.member?(id)
          extra_field_type_exist(binstr, id, len, i)
        elsif id
          create_unknown_item unless self['Unknown']
          break unless extra_field_type_unknown(binstr, len, i)
        end
        i += len + 4
      end
    end

    def create(name)
      unless (field_class = ID_MAP.values.find { |k| k.name == name })
        raise Error, "Unknown extra field '#{name}'"
      end
      self[name] = field_class.new
    end

    # place Unknown last, so "extra" data that is missing the proper signature/size
    # does not prevent known fields from being read back in
    def ordered_values
      result = []
      each { |k, v| k == 'Unknown' ? result.push(v) : result.unshift(v) }
      result
    end

    def to_local_bin
      ordered_values.map! { |v| v.to_local_bin.force_encoding('BINARY') }.join
    end

    alias to_s to_local_bin

    def to_c_dir_bin
      ordered_values.map! { |v| v.to_c_dir_bin.force_encoding('BINARY') }.join
    end

    def c_dir_size
      to_c_dir_bin.bytesize
    end

    def local_size
      to_local_bin.bytesize
    end

    alias length local_size
    alias size local_size
  end
end

# KG-dev::RubyPacker replaced for zip/extra_field/generic.rb
# KG-dev::RubyPacker replaced for zip/extra_field/universal_time.rb
# KG-dev::RubyPacker replaced for zip/extra_field/old_unix.rb
# KG-dev::RubyPacker replaced for zip/extra_field/unix.rb
# KG-dev::RubyPacker replaced for zip/extra_field/zip64.rb
# KG-dev::RubyPacker replaced for zip/extra_field/zip64_placeholder.rb
# KG-dev::RubyPacker replaced for zip/extra_field/ntfs.rb

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
module Zip
  class ExtraField::Generic
    def self.register_map
      if const_defined?(:HEADER_ID)
        ::Zip::ExtraField::ID_MAP[const_get(:HEADER_ID)] = self
      end
    end

    def self.name
      @name ||= to_s.split('::')[-1]
    end

    # return field [size, content] or false
    def initial_parse(binstr)
      if !binstr
        # If nil, start with empty.
        return false
      elsif binstr[0, 2] != self.class.const_get(:HEADER_ID)
        $stderr.puts 'Warning: weired extra feild header ID. skip parsing'
        return false
      end
      [binstr[2, 2].unpack('v')[0], binstr[4..-1]]
    end

    def ==(other)
      return false if self.class != other.class
      each do |k, v|
        return false if v != other[k]
      end
      true
    end

    def to_local_bin
      s = pack_for_local
      self.class.const_get(:HEADER_ID) + [s.bytesize].pack('v') << s
    end

    def to_c_dir_bin
      s = pack_for_c_dir
      self.class.const_get(:HEADER_ID) + [s.bytesize].pack('v') << s
    end
  end
end
module Zip
  # Info-ZIP Additional timestamp field
  class ExtraField::UniversalTime < ExtraField::Generic
    HEADER_ID = 'UT'
    register_map

    def initialize(binstr = nil)
      @ctime = nil
      @mtime = nil
      @atime = nil
      @flag  = nil
      binstr && merge(binstr)
    end

    attr_accessor :atime, :ctime, :mtime, :flag

    def merge(binstr)
      return if binstr.empty?
      size, content = initial_parse(binstr)
      size || return
      @flag, mtime, atime, ctime = content.unpack('CVVV')
      mtime && @mtime ||= ::Zip::DOSTime.at(mtime)
      atime && @atime ||= ::Zip::DOSTime.at(atime)
      ctime && @ctime ||= ::Zip::DOSTime.at(ctime)
    end

    def ==(other)
      @mtime == other.mtime &&
        @atime == other.atime &&
        @ctime == other.ctime
    end

    def pack_for_local
      s = [@flag].pack('C')
      @flag & 1 != 0 && s << [@mtime.to_i].pack('V')
      @flag & 2 != 0 && s << [@atime.to_i].pack('V')
      @flag & 4 != 0 && s << [@ctime.to_i].pack('V')
      s
    end

    def pack_for_c_dir
      s = [@flag].pack('C')
      @flag & 1 == 1 && s << [@mtime.to_i].pack('V')
      s
    end
  end
end
module Zip
  # Olf Info-ZIP Extra for UNIX uid/gid and file timestampes
  class ExtraField::OldUnix < ExtraField::Generic
    HEADER_ID = 'UX'
    register_map

    def initialize(binstr = nil)
      @uid = 0
      @gid = 0
      @atime = nil
      @mtime = nil
      binstr && merge(binstr)
    end

    attr_accessor :uid, :gid, :atime, :mtime

    def merge(binstr)
      return if binstr.empty?
      size, content = initial_parse(binstr)
      # size: 0 for central directory. 4 for local header
      return if !size || size == 0
      atime, mtime, uid, gid = content.unpack('VVvv')
      @uid ||= uid
      @gid ||= gid
      @atime ||= atime
      @mtime ||= mtime
    end

    def ==(other)
      @uid == other.uid &&
        @gid == other.gid &&
        @atime == other.atime &&
        @mtime == other.mtime
    end

    def pack_for_local
      [@atime, @mtime, @uid, @gid].pack('VVvv')
    end

    def pack_for_c_dir
      [@atime, @mtime].pack('VV')
    end
  end
end
module Zip
  # Info-ZIP Extra for UNIX uid/gid
  class ExtraField::IUnix < ExtraField::Generic
    HEADER_ID = 'Ux'
    register_map

    def initialize(binstr = nil)
      @uid = 0
      @gid = 0
      binstr && merge(binstr)
    end

    attr_accessor :uid, :gid

    def merge(binstr)
      return if binstr.empty?
      size, content = initial_parse(binstr)
      # size: 0 for central directory. 4 for local header
      return if !size || size == 0
      uid, gid = content.unpack('vv')
      @uid ||= uid
      @gid ||= gid
    end

    def ==(other)
      @uid == other.uid && @gid == other.gid
    end

    def pack_for_local
      [@uid, @gid].pack('vv')
    end

    def pack_for_c_dir
      ''
    end
  end
end
module Zip
  # Info-ZIP Extra for Zip64 size
  class ExtraField::Zip64 < ExtraField::Generic
    attr_accessor :original_size, :compressed_size, :relative_header_offset, :disk_start_number
    HEADER_ID = ['0100'].pack('H*')
    register_map

    def initialize(binstr = nil)
      # unparsed binary; we don't actually know what this contains
      # without looking for FFs in the associated file header
      # call parse after initializing with a binary string
      @content = nil
      @original_size          = nil
      @compressed_size        = nil
      @relative_header_offset = nil
      @disk_start_number      = nil
      binstr && merge(binstr)
    end

    def ==(other)
      other.original_size == @original_size &&
        other.compressed_size == @compressed_size &&
        other.relative_header_offset == @relative_header_offset &&
        other.disk_start_number == @disk_start_number
    end

    def merge(binstr)
      return if binstr.empty?
      _, @content = initial_parse(binstr)
    end

    # pass the values from the base entry (if applicable)
    # wider values are only present in the extra field for base values set to all FFs
    # returns the final values for the four attributes (from the base or zip64 extra record)
    def parse(original_size, compressed_size, relative_header_offset = nil, disk_start_number = nil)
      @original_size = extract(8, 'Q<') if original_size == 0xFFFFFFFF
      @compressed_size = extract(8, 'Q<') if compressed_size == 0xFFFFFFFF
      @relative_header_offset = extract(8, 'Q<') if relative_header_offset && relative_header_offset == 0xFFFFFFFF
      @disk_start_number = extract(4, 'V') if disk_start_number && disk_start_number == 0xFFFF
      @content = nil
      [@original_size || original_size,
       @compressed_size || compressed_size,
       @relative_header_offset || relative_header_offset,
       @disk_start_number || disk_start_number]
    end

    def extract(size, format)
      @content.slice!(0, size).unpack(format)[0]
    end
    private :extract

    def pack_for_local
      # local header entries must contain original size and compressed size; other fields do not apply
      return '' unless @original_size && @compressed_size
      [@original_size, @compressed_size].pack('Q<Q<')
    end

    def pack_for_c_dir
      # central directory entries contain only fields that didn't fit in the main entry part
      packed = ''.force_encoding('BINARY')
      packed << [@original_size].pack('Q<') if @original_size
      packed << [@compressed_size].pack('Q<') if @compressed_size
      packed << [@relative_header_offset].pack('Q<') if @relative_header_offset
      packed << [@disk_start_number].pack('V') if @disk_start_number
      packed
    end
  end
end
module Zip
  # placeholder to reserve space for a Zip64 extra information record, for the
  # local file header only, that we won't know if we'll need until after
  # we write the file data
  class ExtraField::Zip64Placeholder < ExtraField::Generic
    HEADER_ID = ['9999'].pack('H*') # this ID is used by other libraries such as .NET's Ionic.zip
    register_map

    def initialize(_binstr = nil); end

    def pack_for_local
      "\x00" * 16
    end
  end
end
module Zip
  # PKWARE NTFS Extra Field (0x000a)
  # Only Tag 0x0001 is supported
  class ExtraField::NTFS < ExtraField::Generic
    HEADER_ID = [0x000A].pack('v')
    register_map

    WINDOWS_TICK = 10_000_000.0
    SEC_TO_UNIX_EPOCH = 11_644_473_600

    def initialize(binstr = nil)
      @ctime = nil
      @mtime = nil
      @atime = nil
      binstr && merge(binstr)
    end

    attr_accessor :atime, :ctime, :mtime

    def merge(binstr)
      return if binstr.empty?
      size, content = initial_parse(binstr)
      (size && content) || return

      content = content[4..-1]
      tags = parse_tags(content)

      tag1 = tags[1]
      return unless tag1
      ntfs_mtime, ntfs_atime, ntfs_ctime = tag1.unpack('Q<Q<Q<')
      ntfs_mtime && @mtime ||= from_ntfs_time(ntfs_mtime)
      ntfs_atime && @atime ||= from_ntfs_time(ntfs_atime)
      ntfs_ctime && @ctime ||= from_ntfs_time(ntfs_ctime)
    end

    def ==(other)
      @mtime == other.mtime &&
        @atime == other.atime &&
        @ctime == other.ctime
    end

    # Info-ZIP note states this extra field is stored at local header
    def pack_for_local
      pack_for_c_dir
    end

    # But 7-zip for Windows only stores at central dir
    def pack_for_c_dir
      # reserved 0 and tag 1
      s = [0, 1].pack('Vv')

      tag1 = ''.force_encoding(Encoding::BINARY)
      if @mtime
        tag1 << [to_ntfs_time(@mtime)].pack('Q<')
        if @atime
          tag1 << [to_ntfs_time(@atime)].pack('Q<')
          tag1 << [to_ntfs_time(@ctime)].pack('Q<') if @ctime
        end
      end
      s << [tag1.bytesize].pack('v') << tag1
      s
    end

    private

    def parse_tags(content)
      return {} if content.nil?
      tags = {}
      i = 0
      while i < content.bytesize
        tag, size = content[i, 4].unpack('vv')
        i += 4
        break unless tag && size
        value = content[i, size]
        i += size
        tags[tag] = value
      end

      tags
    end

    def from_ntfs_time(ntfs_time)
      ::Zip::DOSTime.at(ntfs_time / WINDOWS_TICK - SEC_TO_UNIX_EPOCH)
    end

    def to_ntfs_time(time)
      ((time.to_f + SEC_TO_UNIX_EPOCH) * WINDOWS_TICK).to_i
    end
  end
end
module Zip
  class EntrySet #:nodoc:all
    include Enumerable
    attr_accessor :entry_set, :entry_order

    def initialize(an_enumerable = [])
      super()
      @entry_set = {}
      an_enumerable.each { |o| push(o) }
    end

    def include?(entry)
      @entry_set.include?(to_key(entry))
    end

    def find_entry(entry)
      @entry_set[to_key(entry)]
    end

    def <<(entry)
      @entry_set[to_key(entry)] = entry if entry
    end

    alias push <<

    def size
      @entry_set.size
    end

    alias length size

    def delete(entry)
      entry if @entry_set.delete(to_key(entry))
    end

    def each
      @entry_set = sorted_entries.dup.each do |_, value|
        yield(value)
      end
    end

    def entries
      sorted_entries.values
    end

    # deep clone
    def dup
      EntrySet.new(@entry_set.values.map(&:dup))
    end

    def ==(other)
      return false unless other.kind_of?(EntrySet)
      @entry_set.values == other.entry_set.values
    end

    def parent(entry)
      @entry_set[to_key(entry.parent_as_string)]
    end

    def glob(pattern, flags = ::File::FNM_PATHNAME | ::File::FNM_DOTMATCH | ::File::FNM_EXTGLOB)
      entries.map do |entry|
        next nil unless ::File.fnmatch(pattern, entry.name.chomp('/'), flags)
        yield(entry) if block_given?
        entry
      end.compact
    end

    protected

    def sorted_entries
      ::Zip.sort_entries ? Hash[@entry_set.sort] : @entry_set
    end

    private

    def to_key(entry)
      k = entry.to_s.chomp('/')
      k.downcase! if ::Zip.case_insensitive_match
      k
    end
  end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
module Zip
  class CentralDirectory
    include Enumerable

    END_OF_CDS             = 0x06054b50
    ZIP64_END_OF_CDS       = 0x06064b50
    ZIP64_EOCD_LOCATOR     = 0x07064b50
    MAX_END_OF_CDS_SIZE    = 65_536 + 18
    STATIC_EOCD_SIZE       = 22

    attr_reader :comment

    # Returns an Enumerable containing the entries.
    def entries
      @entry_set.entries
    end

    def initialize(entries = EntrySet.new, comment = '') #:nodoc:
      super()
      @entry_set = entries.kind_of?(EntrySet) ? entries : EntrySet.new(entries)
      @comment   = comment
    end

    def write_to_stream(io) #:nodoc:
      cdir_offset = io.tell
      @entry_set.each { |entry| entry.write_c_dir_entry(io) }
      eocd_offset = io.tell
      cdir_size = eocd_offset - cdir_offset
      if ::Zip.write_zip64_support
        need_zip64_eocd = cdir_offset > 0xFFFFFFFF || cdir_size > 0xFFFFFFFF || @entry_set.size > 0xFFFF
        need_zip64_eocd ||= @entry_set.any? { |entry| entry.extra['Zip64'] }
        if need_zip64_eocd
          write_64_e_o_c_d(io, cdir_offset, cdir_size)
          write_64_eocd_locator(io, eocd_offset)
        end
      end
      write_e_o_c_d(io, cdir_offset, cdir_size)
    end

    def write_e_o_c_d(io, offset, cdir_size) #:nodoc:
      tmp = [
        END_OF_CDS,
        0, # @numberOfThisDisk
        0, # @numberOfDiskWithStartOfCDir
        @entry_set ? [@entry_set.size, 0xFFFF].min : 0,
        @entry_set ? [@entry_set.size, 0xFFFF].min : 0,
        [cdir_size, 0xFFFFFFFF].min,
        [offset, 0xFFFFFFFF].min,
        @comment ? @comment.bytesize : 0
      ]
      io << tmp.pack('VvvvvVVv')
      io << @comment
    end

    private :write_e_o_c_d

    def write_64_e_o_c_d(io, offset, cdir_size) #:nodoc:
      tmp = [
        ZIP64_END_OF_CDS,
        44, # size of zip64 end of central directory record (excludes signature and field itself)
        VERSION_MADE_BY,
        VERSION_NEEDED_TO_EXTRACT_ZIP64,
        0, # @numberOfThisDisk
        0, # @numberOfDiskWithStartOfCDir
        @entry_set ? @entry_set.size : 0, # number of entries on this disk
        @entry_set ? @entry_set.size : 0, # number of entries total
        cdir_size, # size of central directory
        offset, # offset of start of central directory in its disk
      ]
      io << tmp.pack('VQ<vvVVQ<Q<Q<Q<')
    end

    private :write_64_e_o_c_d

    def write_64_eocd_locator(io, zip64_eocd_offset)
      tmp = [
        ZIP64_EOCD_LOCATOR,
        0, # number of disk containing the start of zip64 eocd record
        zip64_eocd_offset, # offset of the start of zip64 eocd record in its disk
        1 # total number of disks
      ]
      io << tmp.pack('VVQ<V')
    end

    private :write_64_eocd_locator

    def read_64_e_o_c_d(buf) #:nodoc:
      buf                                           = get_64_e_o_c_d(buf)
      @size_of_zip64_e_o_c_d                        = Entry.read_zip_64_long(buf)
      @version_made_by                              = Entry.read_zip_short(buf)
      @version_needed_for_extract                   = Entry.read_zip_short(buf)
      @number_of_this_disk                          = Entry.read_zip_long(buf)
      @number_of_disk_with_start_of_cdir            = Entry.read_zip_long(buf)
      @total_number_of_entries_in_cdir_on_this_disk = Entry.read_zip_64_long(buf)
      @size                                         = Entry.read_zip_64_long(buf)
      @size_in_bytes                                = Entry.read_zip_64_long(buf)
      @cdir_offset                                  = Entry.read_zip_64_long(buf)
      @zip_64_extensible                            = buf.slice!(0, buf.bytesize)
      raise Error, 'Zip consistency problem while reading eocd structure' unless buf.empty?
    end

    def read_e_o_c_d(buf) #:nodoc:
      buf                                           = get_e_o_c_d(buf)
      @number_of_this_disk                          = Entry.read_zip_short(buf)
      @number_of_disk_with_start_of_cdir            = Entry.read_zip_short(buf)
      @total_number_of_entries_in_cdir_on_this_disk = Entry.read_zip_short(buf)
      @size                                         = Entry.read_zip_short(buf)
      @size_in_bytes                                = Entry.read_zip_long(buf)
      @cdir_offset                                  = Entry.read_zip_long(buf)
      comment_length                                = Entry.read_zip_short(buf)
      @comment                                      = if comment_length.to_i <= 0
                                                        buf.slice!(0, buf.size)
                                                      else
                                                        buf.read(comment_length)
                                                      end
      raise Error, 'Zip consistency problem while reading eocd structure' unless buf.empty?
    end

    def read_central_directory_entries(io) #:nodoc:
      begin
        io.seek(@cdir_offset, IO::SEEK_SET)
      rescue Errno::EINVAL
        raise Error, 'Zip consistency problem while reading central directory entry'
      end
      @entry_set = EntrySet.new
      @size.times do
        @entry_set << Entry.read_c_dir_entry(io)
      end
    end

    def read_from_stream(io) #:nodoc:
      buf = start_buf(io)
      if zip64_file?(buf)
        read_64_e_o_c_d(buf)
      else
        read_e_o_c_d(buf)
      end
      read_central_directory_entries(io)
    end

    def get_e_o_c_d(buf) #:nodoc:
      sig_index = buf.rindex([END_OF_CDS].pack('V'))
      raise Error, 'Zip end of central directory signature not found' unless sig_index
      buf = buf.slice!((sig_index + 4)..(buf.bytesize))

      def buf.read(count)
        slice!(0, count)
      end

      buf
    end

    def zip64_file?(buf)
      buf.rindex([ZIP64_END_OF_CDS].pack('V')) && buf.rindex([ZIP64_EOCD_LOCATOR].pack('V'))
    end

    def start_buf(io)
      begin
        io.seek(-MAX_END_OF_CDS_SIZE, IO::SEEK_END)
      rescue Errno::EINVAL
        io.seek(0, IO::SEEK_SET)
      end
      io.read
    end

    def get_64_e_o_c_d(buf) #:nodoc:
      zip_64_start = buf.rindex([ZIP64_END_OF_CDS].pack('V'))
      raise Error, 'Zip64 end of central directory signature not found' unless zip_64_start
      zip_64_locator = buf.rindex([ZIP64_EOCD_LOCATOR].pack('V'))
      raise Error, 'Zip64 end of central directory signature locator not found' unless zip_64_locator
      buf = buf.slice!((zip_64_start + 4)..zip_64_locator)

      def buf.read(count)
        slice!(0, count)
      end

      buf
    end

    # For iterating over the entries.
    def each(&proc)
      @entry_set.each(&proc)
    end

    # Returns the number of entries in the central directory (and
    # consequently in the zip archive).
    def size
      @entry_set.size
    end

    def self.read_from_stream(io) #:nodoc:
      cdir = new
      cdir.read_from_stream(io)
      return cdir
    rescue Error
      return nil
    end

    def ==(other) #:nodoc:
      return false unless other.kind_of?(CentralDirectory)
      @entry_set.entries.sort == other.entries.sort && comment == other.comment
    end
  end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
module Zip
  # ZipFile is modeled after java.util.zip.ZipFile from the Java SDK.
  # The most important methods are those inherited from
  # ZipCentralDirectory for accessing information about the entries in
  # the archive and methods such as get_input_stream and
  # get_output_stream for reading from and writing entries to the
  # archive. The class includes a few convenience methods such as
  # #extract for extracting entries to the filesystem, and #remove,
  # #replace, #rename and #mkdir for making simple modifications to
  # the archive.
  #
  # Modifications to a zip archive are not committed until #commit or
  # #close is called. The method #open accepts a block following
  # the pattern from File.open offering a simple way to
  # automatically close the archive when the block returns.
  #
  # The following example opens zip archive <code>my.zip</code>
  # (creating it if it doesn't exist) and adds an entry
  # <code>first.txt</code> and a directory entry <code>a_dir</code>
  # to it.
  #
  #   require 'zip'
  #
  #   Zip::File.open("my.zip", Zip::File::CREATE) {
  #    |zipfile|
  #     zipfile.get_output_stream("first.txt") { |f| f.puts "Hello from ZipFile" }
  #     zipfile.mkdir("a_dir")
  #   }
  #
  # The next example reopens <code>my.zip</code> writes the contents of
  # <code>first.txt</code> to standard out and deletes the entry from
  # the archive.
  #
  #   require 'zip'
  #
  #   Zip::File.open("my.zip", Zip::File::CREATE) {
  #     |zipfile|
  #     puts zipfile.read("first.txt")
  #     zipfile.remove("first.txt")
  #   }
  #
  # ZipFileSystem offers an alternative API that emulates ruby's
  # interface for accessing the filesystem, ie. the File and Dir classes.

  class File < CentralDirectory
    CREATE               = true
    SPLIT_SIGNATURE      = 0x08074b50
    ZIP64_EOCD_SIGNATURE = 0x06064b50
    MAX_SEGMENT_SIZE     = 3_221_225_472
    MIN_SEGMENT_SIZE     = 65_536
    DATA_BUFFER_SIZE     = 8192
    IO_METHODS           = [:tell, :seek, :read, :close]

    attr_reader :name

    # default -> false
    attr_accessor :restore_ownership
    # default -> false
    attr_accessor :restore_permissions
    # default -> true
    attr_accessor :restore_times
    # Returns the zip files comment, if it has one
    attr_accessor :comment

    # Opens a zip archive. Pass true as the second parameter to create
    # a new archive if it doesn't exist already.
    def initialize(file_name, create = false, buffer = false, options = {})
      super()
      @name    = file_name
      @comment = ''
      @create  = create ? true : false # allow any truthy value to mean true
      if !buffer && ::File.size?(file_name)
        @create = false
        @file_permissions = ::File.stat(file_name).mode
        ::File.open(name, 'rb') do |f|
          read_from_stream(f)
        end
      elsif @create
        @entry_set = EntrySet.new
      elsif ::File.zero?(file_name)
        raise Error, "File #{file_name} has zero size. Did you mean to pass the create flag?"
      else
        raise Error, "File #{file_name} not found"
      end
      @stored_entries      = @entry_set.dup
      @stored_comment      = @comment
      @restore_ownership   = options[:restore_ownership]    || false
      @restore_permissions = options[:restore_permissions]  || true
      @restore_times       = options[:restore_times]        || true
    end

    class << self
      # Same as #new. If a block is passed the ZipFile object is passed
      # to the block and is automatically closed afterwards just as with
      # ruby's builtin File.open method.
      def open(file_name, create = false)
        zf = ::Zip::File.new(file_name, create)
        return zf unless block_given?
        begin
          yield zf
        ensure
          zf.close
        end
      end

      # Same as #open. But outputs data to a buffer instead of a file
      def add_buffer
        io = ::StringIO.new('')
        zf = ::Zip::File.new(io, true, true)
        yield zf
        zf.write_buffer(io)
      end

      # Like #open, but reads zip archive contents from a String or open IO
      # stream, and outputs data to a buffer.
      # (This can be used to extract data from a
      # downloaded zip archive without first saving it to disk.)
      def open_buffer(io, options = {})
        unless IO_METHODS.map { |method| io.respond_to?(method) }.all? || io.is_a?(String)
          raise "Zip::File.open_buffer expects a String or IO-like argument (responds to #{IO_METHODS.join(', ')}). Found: #{io.class}"
        end
        if io.is_a?(::String)
          require 'stringio'
          io = ::StringIO.new(io)
        elsif io.respond_to?(:binmode)
          # https://github.com/rubyzip/rubyzip/issues/119
          io.binmode
        end
        zf = ::Zip::File.new(io, true, true, options)
        zf.read_from_stream(io)
        return zf unless block_given?
        yield zf
        begin
          zf.write_buffer(io)
        rescue IOError => e
          raise unless e.message == 'not opened for writing'
        end
      end

      # Iterates over the contents of the ZipFile. This is more efficient
      # than using a ZipInputStream since this methods simply iterates
      # through the entries in the central directory structure in the archive
      # whereas ZipInputStream jumps through the entire archive accessing the
      # local entry headers (which contain the same information as the
      # central directory).
      def foreach(aZipFileName, &block)
        open(aZipFileName) do |zipFile|
          zipFile.each(&block)
        end
      end

      def get_segment_size_for_split(segment_size)
        if MIN_SEGMENT_SIZE > segment_size
          MIN_SEGMENT_SIZE
        elsif MAX_SEGMENT_SIZE < segment_size
          MAX_SEGMENT_SIZE
        else
          segment_size
        end
      end

      def get_partial_zip_file_name(zip_file_name, partial_zip_file_name)
        unless partial_zip_file_name.nil?
          partial_zip_file_name = zip_file_name.sub(/#{::File.basename(zip_file_name)}\z/,
                                                    partial_zip_file_name + ::File.extname(zip_file_name))
        end
        partial_zip_file_name ||= zip_file_name
        partial_zip_file_name
      end

      def get_segment_count_for_split(zip_file_size, segment_size)
        (zip_file_size / segment_size).to_i + (zip_file_size % segment_size == 0 ? 0 : 1)
      end

      def put_split_signature(szip_file, segment_size)
        signature_packed = [SPLIT_SIGNATURE].pack('V')
        szip_file << signature_packed
        segment_size - signature_packed.size
      end

      #
      # TODO: Make the code more understandable
      #
      def save_splited_part(zip_file, partial_zip_file_name, zip_file_size, szip_file_index, segment_size, segment_count)
        ssegment_size  = zip_file_size - zip_file.pos
        ssegment_size  = segment_size if ssegment_size > segment_size
        szip_file_name = "#{partial_zip_file_name}.#{format('%03d', szip_file_index)}"
        ::File.open(szip_file_name, 'wb') do |szip_file|
          if szip_file_index == 1
            ssegment_size = put_split_signature(szip_file, segment_size)
          end
          chunk_bytes = 0
          until ssegment_size == chunk_bytes || zip_file.eof?
            segment_bytes_left = ssegment_size - chunk_bytes
            buffer_size        = segment_bytes_left < DATA_BUFFER_SIZE ? segment_bytes_left : DATA_BUFFER_SIZE
            chunk              = zip_file.read(buffer_size)
            chunk_bytes += buffer_size
            szip_file << chunk
            # Info for track splitting
            yield segment_count, szip_file_index, chunk_bytes, ssegment_size if block_given?
          end
        end
      end

      # Splits an archive into parts with segment size
      def split(zip_file_name, segment_size = MAX_SEGMENT_SIZE, delete_zip_file = true, partial_zip_file_name = nil)
        raise Error, "File #{zip_file_name} not found" unless ::File.exist?(zip_file_name)
        raise Errno::ENOENT, zip_file_name unless ::File.readable?(zip_file_name)
        zip_file_size = ::File.size(zip_file_name)
        segment_size  = get_segment_size_for_split(segment_size)
        return if zip_file_size <= segment_size
        segment_count = get_segment_count_for_split(zip_file_size, segment_size)
        # Checking for correct zip structure
        open(zip_file_name) {}
        partial_zip_file_name = get_partial_zip_file_name(zip_file_name, partial_zip_file_name)
        szip_file_index       = 0
        ::File.open(zip_file_name, 'rb') do |zip_file|
          until zip_file.eof?
            szip_file_index += 1
            save_splited_part(zip_file, partial_zip_file_name, zip_file_size, szip_file_index, segment_size, segment_count)
          end
        end
        ::File.delete(zip_file_name) if delete_zip_file
        szip_file_index
      end
    end

    # Returns an input stream to the specified entry. If a block is passed
    # the stream object is passed to the block and the stream is automatically
    # closed afterwards just as with ruby's builtin File.open method.
    def get_input_stream(entry, &aProc)
      get_entry(entry).get_input_stream(&aProc)
    end

    # Returns an output stream to the specified entry. If entry is not an instance
    # of Zip::Entry, a new Zip::Entry will be initialized using the arguments
    # specified. If a block is passed the stream object is passed to the block and
    # the stream is automatically closed afterwards just as with ruby's builtin
    # File.open method.
    def get_output_stream(entry, permission_int = nil, comment = nil, extra = nil, compressed_size = nil, crc = nil, compression_method = nil, size = nil, time = nil, &aProc)
      new_entry =
        if entry.kind_of?(Entry)
          entry
        else
          Entry.new(@name, entry.to_s, comment, extra, compressed_size, crc, compression_method, size, time)
        end
      if new_entry.directory?
        raise ArgumentError,
              "cannot open stream to directory entry - '#{new_entry}'"
      end
      new_entry.unix_perms = permission_int
      zip_streamable_entry = StreamableStream.new(new_entry)
      @entry_set << zip_streamable_entry
      zip_streamable_entry.get_output_stream(&aProc)
    end

    # Returns the name of the zip archive
    def to_s
      @name
    end

    # Returns a string containing the contents of the specified entry
    def read(entry)
      get_input_stream(entry) { |is| is.read }
    end

    # Convenience method for adding the contents of a file to the archive
    def add(entry, src_path, &continue_on_exists_proc)
      continue_on_exists_proc ||= proc { ::Zip.continue_on_exists_proc }
      check_entry_exists(entry, continue_on_exists_proc, 'add')
      new_entry = entry.kind_of?(::Zip::Entry) ? entry : ::Zip::Entry.new(@name, entry.to_s)
      new_entry.gather_fileinfo_from_srcpath(src_path)
      new_entry.dirty = true
      @entry_set << new_entry
    end

    # Removes the specified entry.
    def remove(entry)
      @entry_set.delete(get_entry(entry))
    end

    # Renames the specified entry.
    def rename(entry, new_name, &continue_on_exists_proc)
      foundEntry = get_entry(entry)
      check_entry_exists(new_name, continue_on_exists_proc, 'rename')
      @entry_set.delete(foundEntry)
      foundEntry.name = new_name
      @entry_set << foundEntry
    end

    # Replaces the specified entry with the contents of srcPath (from
    # the file system).
    def replace(entry, srcPath)
      check_file(srcPath)
      remove(entry)
      add(entry, srcPath)
    end

    # Extracts entry to file dest_path.
    def extract(entry, dest_path, &block)
      block ||= proc { ::Zip.on_exists_proc }
      found_entry = get_entry(entry)
      found_entry.extract(dest_path, &block)
    end

    # Commits changes that has been made since the previous commit to
    # the zip archive.
    def commit
      return if name.is_a?(StringIO) || !commit_required?
      on_success_replace do |tmp_file|
        ::Zip::OutputStream.open(tmp_file) do |zos|
          @entry_set.each do |e|
            e.write_to_zip_output_stream(zos)
            e.dirty = false
            e.clean_up
          end
          zos.comment = comment
        end
        true
      end
      initialize(name)
    end

    # Write buffer write changes to buffer and return
    def write_buffer(io = ::StringIO.new(''))
      ::Zip::OutputStream.write_buffer(io) do |zos|
        @entry_set.each { |e| e.write_to_zip_output_stream(zos) }
        zos.comment = comment
      end
    end

    # Closes the zip file committing any changes that has been made.
    def close
      commit
    end

    # Returns true if any changes has been made to this archive since
    # the previous commit
    def commit_required?
      @entry_set.each do |e|
        return true if e.dirty
      end
      @comment != @stored_comment || @entry_set != @stored_entries || @create
    end

    # Searches for entry with the specified name. Returns nil if
    # no entry is found. See also get_entry
    def find_entry(entry_name)
      @entry_set.find_entry(entry_name)
    end

    # Searches for entries given a glob
    def glob(*args, &block)
      @entry_set.glob(*args, &block)
    end

    # Searches for an entry just as find_entry, but throws Errno::ENOENT
    # if no entry is found.
    def get_entry(entry)
      selected_entry = find_entry(entry)
      raise Errno::ENOENT, entry unless selected_entry
      selected_entry.restore_ownership   = @restore_ownership
      selected_entry.restore_permissions = @restore_permissions
      selected_entry.restore_times       = @restore_times
      selected_entry
    end

    # Creates a directory
    def mkdir(entryName, permissionInt = 0o755)
      raise Errno::EEXIST, "File exists - #{entryName}" if find_entry(entryName)
      entryName = entryName.dup.to_s
      entryName << '/' unless entryName.end_with?('/')
      @entry_set << ::Zip::StreamableDirectory.new(@name, entryName, nil, permissionInt)
    end

    private

    def directory?(newEntry, srcPath)
      srcPathIsDirectory = ::File.directory?(srcPath)
      if newEntry.directory? && !srcPathIsDirectory
        raise ArgumentError,
              "entry name '#{newEntry}' indicates directory entry, but " \
                  "'#{srcPath}' is not a directory"
      elsif !newEntry.directory? && srcPathIsDirectory
        newEntry.name += '/'
      end
      newEntry.directory? && srcPathIsDirectory
    end

    def check_entry_exists(entryName, continue_on_exists_proc, procedureName)
      continue_on_exists_proc ||= proc { Zip.continue_on_exists_proc }
      return unless @entry_set.include?(entryName)
      if continue_on_exists_proc.call
        remove get_entry(entryName)
      else
        raise ::Zip::EntryExistsError,
              procedureName + " failed. Entry #{entryName} already exists"
      end
    end

    def check_file(path)
      raise Errno::ENOENT, path unless ::File.readable?(path)
    end

    def on_success_replace
      dirname, basename = ::File.split(name)
      ::Dir::Tmpname.create(basename, dirname) do |tmp_filename|
        begin
          if yield tmp_filename
            ::File.rename(tmp_filename, name)
            ::File.chmod(@file_permissions, name) unless @create
          end
        ensure
          ::File.unlink(tmp_filename) if ::File.exist?(tmp_filename)
        end
      end
    end
  end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
module Zip
  # InputStream is the basic class for reading zip entries in a
  # zip file. It is possible to create a InputStream object directly,
  # passing the zip file name to the constructor, but more often than not
  # the InputStream will be obtained from a File (perhaps using the
  # ZipFileSystem interface) object for a particular entry in the zip
  # archive.
  #
  # A InputStream inherits IOExtras::AbstractInputStream in order
  # to provide an IO-like interface for reading from a single zip
  # entry. Beyond methods for mimicking an IO-object it contains
  # the method get_next_entry for iterating through the entries of
  # an archive. get_next_entry returns a Entry object that describes
  # the zip entry the InputStream is currently reading from.
  #
  # Example that creates a zip archive with ZipOutputStream and reads it
  # back again with a InputStream.
  #
  #   require 'zip'
  #
  #   Zip::OutputStream.open("my.zip") do |io|
  #
  #     io.put_next_entry("first_entry.txt")
  #     io.write "Hello world!"
  #
  #     io.put_next_entry("adir/first_entry.txt")
  #     io.write "Hello again!"
  #   end
  #
  #
  #   Zip::InputStream.open("my.zip") do |io|
  #
  #     while (entry = io.get_next_entry)
  #       puts "Contents of #{entry.name}: '#{io.read}'"
  #     end
  #   end
  #
  # java.util.zip.ZipInputStream is the original inspiration for this
  # class.

  class InputStream
    include ::Zip::IOExtras::AbstractInputStream

    # Opens the indicated zip file. An exception is thrown
    # if the specified offset in the specified filename is
    # not a local zip entry header.
    #
    # @param context [String||IO||StringIO] file path or IO/StringIO object
    # @param offset [Integer] offset in the IO/StringIO
    def initialize(context, offset = 0, decrypter = nil)
      super()
      @archive_io = get_io(context, offset)
      @decompressor  = ::Zip::NullDecompressor
      @decrypter     = decrypter || ::Zip::NullDecrypter.new
      @current_entry = nil
    end

    def close
      @archive_io.close
    end

    # Returns a Entry object. It is necessary to call this
    # method on a newly created InputStream before reading from
    # the first entry in the archive. Returns nil when there are
    # no more entries.
    def get_next_entry
      @archive_io.seek(@current_entry.next_header_offset, IO::SEEK_SET) if @current_entry
      open_entry
    end

    # Rewinds the stream to the beginning of the current entry
    def rewind
      return if @current_entry.nil?
      @lineno = 0
      @pos    = 0
      @archive_io.seek(@current_entry.local_header_offset, IO::SEEK_SET)
      open_entry
    end

    # Modeled after IO.sysread
    def sysread(number_of_bytes = nil, buf = nil)
      @decompressor.sysread(number_of_bytes, buf)
    end

    def eof
      @output_buffer.empty? && @decompressor.eof
    end

    alias :eof? eof

    class << self
      # Same as #initialize but if a block is passed the opened
      # stream is passed to the block and closed when the block
      # returns.
      def open(filename_or_io, offset = 0, decrypter = nil)
        zio = new(filename_or_io, offset, decrypter)
        return zio unless block_given?
        begin
          yield zio
        ensure
          zio.close if zio
        end
      end

      def open_buffer(filename_or_io, offset = 0)
        puts 'open_buffer is deprecated!!! Use open instead!'
        open(filename_or_io, offset)
      end
    end

    protected

    def get_io(io_or_file, offset = 0)
      if io_or_file.respond_to?(:seek)
        io = io_or_file.dup
        io.seek(offset, ::IO::SEEK_SET)
        io
      else
        file = ::File.open(io_or_file, 'rb')
        file.seek(offset, ::IO::SEEK_SET)
        file
      end
    end

    def open_entry
      @current_entry = ::Zip::Entry.read_local_entry(@archive_io)
      if @current_entry && @current_entry.gp_flags & 1 == 1 && @decrypter.is_a?(NullEncrypter)
        raise Error, 'password required to decode zip file'
      end
      if @current_entry && @current_entry.gp_flags & 8 == 8 && @current_entry.crc == 0 \
        && @current_entry.compressed_size == 0 \
        && @current_entry.size == 0 && !@complete_entry
        raise GPFBit3Error,
              'General purpose flag Bit 3 is set so not possible to get proper info from local header.' \
              'Please use ::Zip::File instead of ::Zip::InputStream'
      end
      @decompressor = get_decompressor
      flush
      @current_entry
    end

    def get_decompressor
      if @current_entry.nil?
        ::Zip::NullDecompressor
      elsif @current_entry.compression_method == ::Zip::Entry::STORED
        if @current_entry.gp_flags & 8 == 8 && @current_entry.crc == 0 && @current_entry.size == 0 && @complete_entry
          ::Zip::PassThruDecompressor.new(@archive_io, @complete_entry.size)
        else
          ::Zip::PassThruDecompressor.new(@archive_io, @current_entry.size)
        end
      elsif @current_entry.compression_method == ::Zip::Entry::DEFLATED
        header = @archive_io.read(@decrypter.header_bytesize)
        @decrypter.reset!(header)
        ::Zip::Inflater.new(@archive_io, @decrypter)
      else
        raise ::Zip::CompressionMethodError,
              "Unsupported compression method #{@current_entry.compression_method}"
      end
    end

    def produce_input
      @decompressor.produce_input
    end

    def input_finished?
      @decompressor.input_finished?
    end
  end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
module Zip
  # ZipOutputStream is the basic class for writing zip files. It is
  # possible to create a ZipOutputStream object directly, passing
  # the zip file name to the constructor, but more often than not
  # the ZipOutputStream will be obtained from a ZipFile (perhaps using the
  # ZipFileSystem interface) object for a particular entry in the zip
  # archive.
  #
  # A ZipOutputStream inherits IOExtras::AbstractOutputStream in order
  # to provide an IO-like interface for writing to a single zip
  # entry. Beyond methods for mimicking an IO-object it contains
  # the method put_next_entry that closes the current entry
  # and creates a new.
  #
  # Please refer to ZipInputStream for example code.
  #
  # java.util.zip.ZipOutputStream is the original inspiration for this
  # class.

  class OutputStream
    include ::Zip::IOExtras::AbstractOutputStream

    attr_accessor :comment

    # Opens the indicated zip file. If a file with that name already
    # exists it will be overwritten.
    def initialize(file_name, stream = false, encrypter = nil)
      super()
      @file_name = file_name
      @output_stream = if stream
                         iostream = @file_name.dup
                         iostream.reopen(@file_name)
                         iostream.rewind
                         iostream
                       else
                         ::File.new(@file_name, 'wb')
                       end
      @entry_set = ::Zip::EntrySet.new
      @compressor = ::Zip::NullCompressor.instance
      @encrypter = encrypter || ::Zip::NullEncrypter.new
      @closed = false
      @current_entry = nil
      @comment = nil
    end

    # Same as #initialize but if a block is passed the opened
    # stream is passed to the block and closed when the block
    # returns.
    class << self
      def open(file_name, encrypter = nil)
        return new(file_name) unless block_given?
        zos = new(file_name, false, encrypter)
        yield zos
      ensure
        zos.close if zos
      end

      # Same as #open but writes to a filestream instead
      def write_buffer(io = ::StringIO.new(''), encrypter = nil)
        zos = new(io, true, encrypter)
        yield zos
        zos.close_buffer
      end
    end

    # Closes the stream and writes the central directory to the zip file
    def close
      return if @closed
      finalize_current_entry
      update_local_headers
      write_central_directory
      @output_stream.close
      @closed = true
    end

    # Closes the stream and writes the central directory to the zip file
    def close_buffer
      return @output_stream if @closed
      finalize_current_entry
      update_local_headers
      write_central_directory
      @closed = true
      @output_stream
    end

    # Closes the current entry and opens a new for writing.
    # +entry+ can be a ZipEntry object or a string.
    def put_next_entry(entry_name, comment = nil, extra = nil, compression_method = Entry::DEFLATED, level = Zip.default_compression)
      raise Error, 'zip stream is closed' if @closed
      new_entry = if entry_name.kind_of?(Entry)
                    entry_name
                  else
                    Entry.new(@file_name, entry_name.to_s)
                  end
      new_entry.comment = comment unless comment.nil?
      unless extra.nil?
        new_entry.extra = extra.is_a?(ExtraField) ? extra : ExtraField.new(extra.to_s)
      end
      new_entry.compression_method = compression_method unless compression_method.nil?
      init_next_entry(new_entry, level)
      @current_entry = new_entry
    end

    def copy_raw_entry(entry)
      entry = entry.dup
      raise Error, 'zip stream is closed' if @closed
      raise Error, 'entry is not a ZipEntry' unless entry.is_a?(Entry)
      finalize_current_entry
      @entry_set << entry
      src_pos = entry.local_header_offset
      entry.write_local_entry(@output_stream)
      @compressor = NullCompressor.instance
      entry.get_raw_input_stream do |is|
        is.seek(src_pos, IO::SEEK_SET)
        ::Zip::Entry.read_local_entry(is)
        IOExtras.copy_stream_n(@output_stream, is, entry.compressed_size)
      end
      @compressor = NullCompressor.instance
      @current_entry = nil
    end

    private

    def finalize_current_entry
      return unless @current_entry
      finish
      @current_entry.compressed_size = @output_stream.tell - @current_entry.local_header_offset - @current_entry.calculate_local_header_size
      @current_entry.size = @compressor.size
      @current_entry.crc = @compressor.crc
      @output_stream << @encrypter.data_descriptor(@current_entry.crc, @current_entry.compressed_size, @current_entry.size)
      @current_entry.gp_flags |= @encrypter.gp_flags
      @current_entry = nil
      @compressor = ::Zip::NullCompressor.instance
    end

    def init_next_entry(entry, level = Zip.default_compression)
      finalize_current_entry
      @entry_set << entry
      entry.write_local_entry(@output_stream)
      @encrypter.reset!
      @output_stream << @encrypter.header(entry.mtime)
      @compressor = get_compressor(entry, level)
    end

    def get_compressor(entry, level)
      case entry.compression_method
      when Entry::DEFLATED then
        ::Zip::Deflater.new(@output_stream, level, @encrypter)
      when Entry::STORED then
        ::Zip::PassThruCompressor.new(@output_stream)
      else
        raise ::Zip::CompressionMethodError,
              "Invalid compression method: '#{entry.compression_method}'"
      end
    end

    def update_local_headers
      pos = @output_stream.pos
      @entry_set.each do |entry|
        @output_stream.pos = entry.local_header_offset
        entry.write_local_entry(@output_stream, true)
      end
      @output_stream.pos = pos
    end

    def write_central_directory
      cdir = CentralDirectory.new(@entry_set, @comment)
      cdir.write_to_stream(@output_stream)
    end

    protected

    def finish
      @compressor.finish
    end

    public

    # Modeled after IO.<<
    def <<(data)
      @compressor << data
      self
    end
  end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
module Zip
  class Decompressor #:nodoc:all
    CHUNK_SIZE = 32_768
    def initialize(input_stream)
      super()
      @input_stream = input_stream
    end
  end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
module Zip
  class Compressor #:nodoc:all
    def finish; end
  end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
module Zip
  module NullDecompressor #:nodoc:all
    module_function

    def sysread(_numberOfBytes = nil, _buf = nil)
      nil
    end

    def produce_input
      nil
    end

    def input_finished?
      true
    end

    def eof
      true
    end

    alias eof? eof
  end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
module Zip
  class NullCompressor < Compressor #:nodoc:all
    include Singleton

    def <<(_data)
      raise IOError, 'closed stream'
    end

    attr_reader :size, :compressed_size
  end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
module Zip
  module NullInputStream #:nodoc:all
    include ::Zip::NullDecompressor
    include ::Zip::IOExtras::AbstractInputStream
  end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
module Zip
  class PassThruCompressor < Compressor #:nodoc:all
    def initialize(outputStream)
      super()
      @output_stream = outputStream
      @crc = Zlib.crc32
      @size = 0
    end

    def <<(data)
      val = data.to_s
      @crc = Zlib.crc32(val, @crc)
      @size += val.bytesize
      @output_stream << val
    end

    attr_reader :size, :crc
  end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
module Zip
  class PassThruDecompressor < Decompressor #:nodoc:all
    def initialize(input_stream, chars_to_read)
      super(input_stream)
      @chars_to_read = chars_to_read
      @read_so_far = 0
      @has_returned_empty_string = false
    end

    def sysread(number_of_bytes = nil, buf = '')
      if input_finished?
        has_returned_empty_string_val = @has_returned_empty_string
        @has_returned_empty_string = true
        return '' unless has_returned_empty_string_val
        return
      end

      if number_of_bytes.nil? || @read_so_far + number_of_bytes > @chars_to_read
        number_of_bytes = @chars_to_read - @read_so_far
      end
      @read_so_far += number_of_bytes
      @input_stream.read(number_of_bytes, buf)
    end

    def produce_input
      sysread(::Zip::Decompressor::CHUNK_SIZE)
    end

    def input_finished?
      @read_so_far >= @chars_to_read
    end

    alias eof input_finished?
    alias eof? input_finished?
  end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
module Zip
  class Encrypter #:nodoc:all
  end

  class Decrypter
  end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
module Zip
  module NullEncryption
    def header_bytesize
      0
    end

    def gp_flags
      0
    end
  end

  class NullEncrypter < Encrypter
    include NullEncryption

    def header(_mtime)
      ''
    end

    def encrypt(data)
      data
    end

    def data_descriptor(_crc32, _compressed_size, _uncomprssed_size)
      ''
    end

    def reset!; end
  end

  class NullDecrypter < Decrypter
    include NullEncryption

    def decrypt(data)
      data
    end

    def reset!(_header); end
  end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
module Zip
  module TraditionalEncryption
    def initialize(password)
      @password = password
      reset_keys!
    end

    def header_bytesize
      12
    end

    def gp_flags
      0x0001 | 0x0008
    end

    protected

    def reset_keys!
      @key0 = 0x12345678
      @key1 = 0x23456789
      @key2 = 0x34567890
      @password.each_byte do |byte|
        update_keys(byte.chr)
      end
    end

    def update_keys(n)
      @key0 = ~Zlib.crc32(n, ~@key0)
      @key1 = ((@key1 + (@key0 & 0xff)) * 134_775_813 + 1) & 0xffffffff
      @key2 = ~Zlib.crc32((@key1 >> 24).chr, ~@key2)
    end

    def decrypt_byte
      temp = (@key2 & 0xffff) | 2
      ((temp * (temp ^ 1)) >> 8) & 0xff
    end
  end

  class TraditionalEncrypter < Encrypter
    include TraditionalEncryption

    def header(mtime)
      [].tap do |header|
        (header_bytesize - 2).times do
          header << Random.rand(0..255)
        end
        header << (mtime.to_binary_dos_time & 0xff)
        header << (mtime.to_binary_dos_time >> 8)
      end.map { |x| encode x }.pack('C*')
    end

    def encrypt(data)
      data.unpack('C*').map { |x| encode x }.pack('C*')
    end

    def data_descriptor(crc32, compressed_size, uncomprssed_size)
      [0x08074b50, crc32, compressed_size, uncomprssed_size].pack('VVVV')
    end

    def reset!
      reset_keys!
    end

    private

    def encode(n)
      t = decrypt_byte
      update_keys(n.chr)
      t ^ n
    end
  end

  class TraditionalDecrypter < Decrypter
    include TraditionalEncryption

    def decrypt(data)
      data.unpack('C*').map { |x| decode x }.pack('C*')
    end

    def reset!(header)
      reset_keys!
      header.each_byte do |x|
        decode x
      end
    end

    private

    def decode(n)
      n ^= decrypt_byte
      update_keys(n.chr)
      n
    end
  end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
module Zip
  class Inflater < Decompressor #:nodoc:all
    def initialize(input_stream, decrypter = NullDecrypter.new)
      super(input_stream)
      @zlib_inflater           = ::Zlib::Inflate.new(-Zlib::MAX_WBITS)
      @output_buffer           = ''.dup
      @has_returned_empty_string = false
      @decrypter = decrypter
    end

    def sysread(number_of_bytes = nil, buf = '')
      readEverything = number_of_bytes.nil?
      while readEverything || @output_buffer.bytesize < number_of_bytes
        break if internal_input_finished?
        @output_buffer << internal_produce_input(buf)
      end
      return value_when_finished if @output_buffer.bytesize == 0 && input_finished?
      end_index = number_of_bytes.nil? ? @output_buffer.bytesize : number_of_bytes
      @output_buffer.slice!(0...end_index)
    end

    def produce_input
      if @output_buffer.empty?
        internal_produce_input
      else
        @output_buffer.slice!(0...(@output_buffer.length))
      end
    end

    # to be used with produce_input, not read (as read may still have more data cached)
    # is data cached anywhere other than @outputBuffer?  the comment above may be wrong
    def input_finished?
      @output_buffer.empty? && internal_input_finished?
    end

    alias :eof input_finished?
    alias :eof? input_finished?

    private

    def internal_produce_input(buf = '')
      retried = 0
      begin
        @zlib_inflater.inflate(@decrypter.decrypt(@input_stream.read(Decompressor::CHUNK_SIZE, buf)))
      rescue Zlib::BufError
        raise if retried >= 5 # how many times should we retry?
        retried += 1
        retry
      end
    end

    def internal_input_finished?
      @zlib_inflater.finished?
    end

    def value_when_finished # mimic behaviour of ruby File object.
      return if @has_returned_empty_string
      @has_returned_empty_string = true
      ''
    end
  end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
module Zip
  class Deflater < Compressor #:nodoc:all
    def initialize(output_stream, level = Zip.default_compression, encrypter = NullEncrypter.new)
      super()
      @output_stream = output_stream
      @zlib_deflater = ::Zlib::Deflate.new(level, -::Zlib::MAX_WBITS)
      @size          = 0
      @crc           = ::Zlib.crc32
      @encrypter     = encrypter
    end

    def <<(data)
      val   = data.to_s
      @crc  = Zlib.crc32(val, @crc)
      @size += val.bytesize
      buffer = @zlib_deflater.deflate(data)
      if buffer.empty?
        @output_stream
      else
        @output_stream << @encrypter.encrypt(buffer)
      end
    end

    def finish
      @output_stream << @encrypter.encrypt(@zlib_deflater.finish) until @zlib_deflater.finished?
    end

    attr_reader :size, :crc
  end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
module Zip
  class StreamableStream < DelegateClass(Entry) # nodoc:all
    def initialize(entry)
      super(entry)
      dirname = if zipfile.is_a?(::String)
                  ::File.dirname(zipfile)
                else
                  nil
                end
      @temp_file = Tempfile.new(::File.basename(name), dirname)
      @temp_file.binmode
    end

    def get_output_stream
      if block_given?
        begin
          yield(@temp_file)
        ensure
          @temp_file.close
        end
      else
        @temp_file
      end
    end

    def get_input_stream
      unless @temp_file.closed?
        raise StandardError, "cannot open entry for reading while its open for writing - #{name}"
      end
      @temp_file.open # reopens tempfile from top
      @temp_file.binmode
      if block_given?
        begin
          yield(@temp_file)
        ensure
          @temp_file.close
        end
      else
        @temp_file
      end
    end

    def write_to_zip_output_stream(aZipOutputStream)
      aZipOutputStream.put_next_entry(self)
      get_input_stream { |is| ::Zip::IOExtras.copy_stream(aZipOutputStream, is) }
    end

    def clean_up
      @temp_file.unlink
    end
  end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
module Zip
  class StreamableDirectory < Entry
    def initialize(zipfile, entry, srcPath = nil, permissionInt = nil)
      super(zipfile, entry)

      @ftype = :directory
      entry.get_extra_attributes_from_path(srcPath) if srcPath
      @unix_perms = permissionInt if permissionInt
    end
  end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
module Zip
  RUNNING_ON_WINDOWS = RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/i

  CENTRAL_DIRECTORY_ENTRY_SIGNATURE = 0x02014b50
  CDIR_ENTRY_STATIC_HEADER_LENGTH   = 46

  LOCAL_ENTRY_SIGNATURE                  = 0x04034b50
  LOCAL_ENTRY_STATIC_HEADER_LENGTH       = 30
  LOCAL_ENTRY_TRAILING_DESCRIPTOR_LENGTH = 4 + 4 + 4
  VERSION_MADE_BY                        = 52 # this library's version
  VERSION_NEEDED_TO_EXTRACT              = 20
  VERSION_NEEDED_TO_EXTRACT_ZIP64        = 45

  FILE_TYPE_FILE    = 0o10
  FILE_TYPE_DIR     = 0o04
  FILE_TYPE_SYMLINK = 0o12

  FSTYPE_FAT      = 0
  FSTYPE_AMIGA    = 1
  FSTYPE_VMS      = 2
  FSTYPE_UNIX     = 3
  FSTYPE_VM_CMS   = 4
  FSTYPE_ATARI    = 5
  FSTYPE_HPFS     = 6
  FSTYPE_MAC      = 7
  FSTYPE_Z_SYSTEM = 8
  FSTYPE_CPM      = 9
  FSTYPE_TOPS20   = 10
  FSTYPE_NTFS     = 11
  FSTYPE_QDOS     = 12
  FSTYPE_ACORN    = 13
  FSTYPE_VFAT     = 14
  FSTYPE_MVS      = 15
  FSTYPE_BEOS     = 16
  FSTYPE_TANDEM   = 17
  FSTYPE_THEOS    = 18
  FSTYPE_MAC_OSX  = 19
  FSTYPE_ATHEOS   = 30

  FSTYPES = {
    FSTYPE_FAT      => 'FAT'.freeze,
    FSTYPE_AMIGA    => 'Amiga'.freeze,
    FSTYPE_VMS      => 'VMS (Vax or Alpha AXP)'.freeze,
    FSTYPE_UNIX     => 'Unix'.freeze,
    FSTYPE_VM_CMS   => 'VM/CMS'.freeze,
    FSTYPE_ATARI    => 'Atari ST'.freeze,
    FSTYPE_HPFS     => 'OS/2 or NT HPFS'.freeze,
    FSTYPE_MAC      => 'Macintosh'.freeze,
    FSTYPE_Z_SYSTEM => 'Z-System'.freeze,
    FSTYPE_CPM      => 'CP/M'.freeze,
    FSTYPE_TOPS20   => 'TOPS-20'.freeze,
    FSTYPE_NTFS     => 'NTFS'.freeze,
    FSTYPE_QDOS     => 'SMS/QDOS'.freeze,
    FSTYPE_ACORN    => 'Acorn RISC OS'.freeze,
    FSTYPE_VFAT     => 'Win32 VFAT'.freeze,
    FSTYPE_MVS      => 'MVS'.freeze,
    FSTYPE_BEOS     => 'BeOS'.freeze,
    FSTYPE_TANDEM   => 'Tandem NSK'.freeze,
    FSTYPE_THEOS    => 'Theos'.freeze,
    FSTYPE_MAC_OSX  => 'Mac OS/X (Darwin)'.freeze,
    FSTYPE_ATHEOS   => 'AtheOS'.freeze
  }.freeze
end
module Zip
  class Error < StandardError; end
  class EntryExistsError < Error; end
  class DestinationFileExistsError < Error; end
  class CompressionMethodError < Error; end
  class EntryNameError < Error; end
  class InternalError < Error; end
  class GPFBit3Error < Error; end

  # Backwards compatibility with v1 (delete in v2)
  ZipError = Error
  ZipEntryExistsError = EntryExistsError
  ZipDestinationFileExistsError = DestinationFileExistsError
  ZipCompressionMethodError = CompressionMethodError
  ZipEntryNameError = EntryNameError
  ZipInternalError = InternalError
end
require 'delegate'
require 'singleton'
require 'tempfile'
require 'tmpdir'
require 'fileutils'
require 'stringio'
require 'zlib'
# KG-dev::RubyPacker replaced for zip/dos_time.rb
# KG-dev::RubyPacker replaced for zip/ioextras.rb
require 'rbconfig'
# KG-dev::RubyPacker replaced for zip/entry.rb
# KG-dev::RubyPacker replaced for zip/extra_field.rb
# KG-dev::RubyPacker replaced for zip/entry_set.rb
# KG-dev::RubyPacker replaced for zip/central_directory.rb
# KG-dev::RubyPacker replaced for zip/file.rb
# KG-dev::RubyPacker replaced for zip/input_stream.rb
# KG-dev::RubyPacker replaced for zip/output_stream.rb
# KG-dev::RubyPacker replaced for zip/decompressor.rb
# KG-dev::RubyPacker replaced for zip/compressor.rb
# KG-dev::RubyPacker replaced for zip/null_decompressor.rb
# KG-dev::RubyPacker replaced for zip/null_compressor.rb
# KG-dev::RubyPacker replaced for zip/null_input_stream.rb
# KG-dev::RubyPacker replaced for zip/pass_thru_compressor.rb
# KG-dev::RubyPacker replaced for zip/pass_thru_decompressor.rb
# KG-dev::RubyPacker replaced for zip/crypto/encryption.rb
# KG-dev::RubyPacker replaced for zip/crypto/null_encryption.rb
# KG-dev::RubyPacker replaced for zip/crypto/traditional_encryption.rb
# KG-dev::RubyPacker replaced for zip/inflater.rb
# KG-dev::RubyPacker replaced for zip/deflater.rb
# KG-dev::RubyPacker replaced for zip/streamable_stream.rb
# KG-dev::RubyPacker replaced for zip/streamable_directory.rb
# KG-dev::RubyPacker replaced for zip/constants.rb
# KG-dev::RubyPacker replaced for zip/errors.rb

module Zip
  extend self
  attr_accessor :unicode_names,
                :on_exists_proc,
                :continue_on_exists_proc,
                :sort_entries,
                :default_compression,
                :write_zip64_support,
                :warn_invalid_date,
                :case_insensitive_match,
                :force_entry_names_encoding

  def reset!
    @_ran_once = false
    @unicode_names = false
    @on_exists_proc = false
    @continue_on_exists_proc = false
    @sort_entries = false
    @default_compression = ::Zlib::DEFAULT_COMPRESSION
    @write_zip64_support = false
    @warn_invalid_date = true
    @case_insensitive_match = false
  end

  def setup
    yield self unless @_ran_once
    @_ran_once = true
  end

  reset!
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
