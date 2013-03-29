class ContextDelegator
  def initialize(context_manager)
    @_context = context_manager
    @_args = []
    @_blocks = []
  end

  def _args(index)
    @_args[index].call
  end

  def _block(index)
    @_blocks[index].call
  end

  def method_missing(method, *args, &block)
    args_params = []
    args.each do |argument|
      args_index = @_args.length
      @_args << argument
      args_params << "capybara._args(#{args_index})"
    end
    block_param = ""
    if block_given?
      block_index = @_blocks.length
      @_blocks << block
      block_param = ", " unless args.empty?
      block_param << "&capybara._block(#{block_index})"
    end
    params = "#{args_params.join ", "}#{block_param}"
    call = method.to_s
    call << "(#{params})" unless params.empty?
    val = @_context.raw_eval call
    @_args.pop args.length
    @_blocks.pop if block_given?
    val
  end
end