![Exspec](logo.png)
======
With Exspec you can write specs while testing your Ruby code interactively in IRB.

Installation
-------
Exspec is available on RubyGems.org: [https://rubygems.org/gems/Exspec](https://rubygems.org/gems/Exspec)
You can install it by calling

`gem install Exspec`

Now you should have the `exspec` command available in your terminal.  
Please make sure that your gem's bin folder is included in your PATH variable.

How to Use
-------

In order to run Exspec just call

`exspec`

in your project directory. If it is a Rails project, Exspec will detect that automatically and start your Rails console. Otherwise you have to load your code manually by calling `load code.rb` on the exspec IRB console or by creating an `exspec.rb` file in your project folder and configuring it as shown under *Extensions* (see below).

Now you can test your code interactively as you are used to do with IRB.

# Commands

After testing a part of your code and getting a value back from an instruction, you can use the Exspec commands to specify whether or not you expect this returned value. There are also commands for managing your specs and mocking/stubbing purposes.

## Assertions

Exspec provides three ways to specify the expected value of a statement: `!expect`, `!expect_inspect`, `!assert`.

### !expect

Calling `!expect statement` executes the given statement and compares the return value with the value returned by your last executed instruction (or with an exception thrown by your last instruction).

#### Example:

<pre>
irb(main):001:0> myStringUtils.concat "Hello", "world!"
=> "Hello world!"
irb(main):002:0> !expect ["Hello", "world!"].join(" ") !# concatenates the params with a space
Successful: concatenates the params with a space
=> "Hello world!"
</pre>

As you can see, the returned value of the `!expect` command is the returned value of the given statement. This applies even if the test fails. Therefore, you can continue working with your expected value whether or not you actually got the expected value before, which can be helpful for working with Exspec in TDD (see below, *Test-driven Development*).

`!# comment` is optional and can be used after each of the three assertion instructions to describe what you expect. You can also use it stand-alone to add a comment to your spec.

### !expect_inspect

Instead of comparing the actual value, `!expect_inspect value` compares the inspect-value of your last instruction (i.e. the output in IRB or the string returned by calling `value.inspect` in Ruby) with the given value (which will be treated as a string). Alternatively, you can just call `!expect` without an argument, which opens a new prompt where you can enter the expected value. By pressing arrow-up on this prompt you automatically get the inspect-value of your last instruction on your input and can change it.

`!expect_inspect` compares fuzzy. This allows you to omit certain data that can be different when you run the spec next time, for instance time values.

#### Example:

<pre>
irb(main):003:0> User.create :name => "test"
=> #&lt;User id: 7, name: "test", created_at: "2013-03-06 04:28:35", updated_at: "2013-03-06 04:28:35", deleted_at: nil>
irb(main):004:0> !expect_inspect #&lt;User id:, name: "test", created_at: "", updated_at: "", deleted_at: nil>
Successful (fuzzy): inspecting last value has yielded "#&lt;User id: 7, name: "test", created_at: "2013-03-06 04:28:35", updated_at: "2013-03-06 04:28:35", deleted_at: nil>"
=> #&lt;User id: 7, name: "test", created_at: "2013-03-06 04:28:35", updated_at: "2013-03-06 04:28:35", deleted_at: nil>
</pre>

### !assert

`!assert statement` allows you to write any assertions you can express with your code. It executes the statement and passes if the result evaluates to true.

#### Example:

<pre>
irb(main):005:0> list = MyList.new
irb(main):006:0> list.add "value"
irb(main):007:0> !assert list.length == 1
Successful: list.length == 1
irb(main):008:0> !assert list.include? "value"
Successful: list.include? "value"
</pre>

## Managing Specs

Your spec gets recorded in your spec history. You can see your current history with

`!history`

In order to remove an entry from your history you can either use `!erase` to erase your last instruction or `!erase# index`, where `index` is the index of the instruction you want to remove. When you remove the last one, Exspecs also sets your current value (`_`) back to the return value of your new last instruction. This ensures that you have a consistent spec flow at any point.

If you are done testing a feature, you can save the spec by calling

`!save a short description !# more detailled explanation`

The `!# comment` is optional. The above command saves the spec in your spec folder as a\_short\_description.rb. If you have not specified a test directory (as shown under *Extensions*, see below), your specs will be saved under test/exspec in your project folder. Now your history is empty again and ready for writing your next spec based on the previous one. If you save the next spec, it will be saved in a folder called a\_short\_description under your test folder. And so on...

In case your spec is independent from the one before (i.e. it does not need any values from the one before) call `!independent` or `!up` and Exspec will load the spec preceding your last saved spec.

To load a spec you can call `!load spec name`. This searches for the given spec under your currently loaded spec. Preceding the spec name with a dot causes Exspec to search for the given spec in the root of your test directory. You can also load successive specs by joining their names with dots:

`!load . first spec . second spec`

Calling `!specs` gives you a list of the specs under your current spec or under the spec specified (`!specs .` for specs in your test dir root). You can load one of these by using `!load# index`, where index is the index of a spec in the menu returned by `!specs`. In the same way works `!stack` which gives you your currently loaded spec stack from the first spec to the spec you are currently working on.

Similarly, you can use `!run name` / `!run# index` or `!include name` / `!include# index` to run another spec within your current spec. While `!run` actually runs the other spec and by that copies its history, `!include` only includes a pointer to the other spec into your history.

In addition to showing the menus, commands like `!history` and `!specs` return the corresponding objects, i.e. an array of spec objects in case of `!specs`. To keep your history clean this gets returned into another context though, called Exspec context. This will be indicated by a `!_: ...` output besides your regular IRB `=> ...` output after calling a menu command. You can access these objects and work on the Exspec context by prefix your instructions with an exclamation mark. So you can run arbitrary Ruby code without dirtying your spec. Thus you can also load a spec by calling `! _[0].load` after invoking `!specs`.

## Mocking

Exspec provides a very ease to use yet powerful way for writing mocks / stubs.
Calling `!mock` or `!stub` (which are synonyms in Exspec) gives you an Exspec Mock object or assigns it to a variable when you specify one by calling `!mock var_name`. A mock keeps track of all method calls on it and returns a new mock for each non-defined methods. Also, it saves values that get defined to an attribute of the mock and returns it on accessing the same attribute method later.

For stubbing particular methods you can define those on your mock as follows:

<pre>
irb(main):009:0> !mock myMock
irb(main):010:0> myMock._def(:add_three) { |param| param + 3 }
irb(main):011:0> myMock.add_three 10
=> 13
</pre>

The list of params passed to the block is the list of params the method gets called with. When a block is given to the method call, the block is going the be the last parameter.

There are multiple ways for writing an assertion on a mock. The following listing shows some examples:

* `!assert myMock._have_been_called? :add_three` 
* `!assert myMock._times_called(:add_three) == 1`
* `!assert myMock._first_call(:add_three)[:args][0] == 10`

A mock also provides methods to access its child mocks returned by calling an undefined method (`_child(:method_name)`), to access all method calls on that object (`_method_calls`) and to get the values assigned to its attributes (`_attribute[:attr_name]`).

## Test-driven development

Besides testing existing code Exspec is also well-suited for test-driven development. Just write your spec as normal (see above) until one of your assertions fails. Now you can use the `!retry` command to rerun your spec to this point. If you have set up Exspec to load your code automatically in the `setup_context` callback as shown below (see *Extensions*), Exspec will reload your code by calling `!rety`. So it is possible to change your code and rerun your spec over and over again until your assertion passes. Then proceed writing your spec until you reach the next failed assertion.

# Running specs

To run your specs call `exspec` from the terminal with the name of your spec, the directory you want to run or just a dot in order to run all your specs:

`exspec .`

# Extensions

For extending Exspec or configuring it for your project you can write an Exspec etension and save it as exspec.rb under your project folder. An Exspec extension is a Ruby Module which extends `Exspec::Extension`. This provides several callbacks / extension points in order to customize Exspec for you project.
Please let me know if you need another extension point and I am going to add it if appropriate.

#### Example:

<pre>
require "exspec"

module MyAppExspecExtension
  extend Exspec::Extension

  @@dir = File.dirname(__FILE__)

  config do |config|
    config[:test_dir] = File.expand_path("my_specs/exspec", @@dir)
  end

  setup_context do
    Dir[File.expand_path("myCodeDir/*.rb", @@dir)].each { |file| load file }
  end
 
  execute_command do |command, param_string, options|
    case command # custom commands
      when "hello" # call it with `!hello world`
        execute(command, parameters(param_string), options) do |params|
          "hello #{params[0]}!"
        end
    end
  end
end
</pre>