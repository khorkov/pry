require 'helper'

describe "Pry::DefaultCommands::Documentation" do
  describe "show-doc" do
    it 'should output a method\'s documentation' do
      redirect_pry_io(InputTester.new("show-doc sample_method", "exit-all"), str_output=StringIO.new) do
        pry
      end

      str_output.string.should =~ /sample doc/
    end

    it 'should output a method\'s documentation with line numbers' do
      redirect_pry_io(InputTester.new("show-doc sample_method -l", "exit-all"), str_output=StringIO.new) do
        pry
      end

      str_output.string.should =~ /\d: sample doc/
    end

    it 'should output a method\'s documentation with line numbers (base one)' do
      redirect_pry_io(InputTester.new("show-doc sample_method -b", "exit-all"), str_output=StringIO.new) do
        pry
      end

      str_output.string.should =~ /1: sample doc/
    end

    it 'should output a method\'s documentation if inside method without needing to use method name' do
      o = Object.new

      # sample comment
      def o.sample
        redirect_pry_io(InputTester.new("show-doc", "exit-all"), $out=StringIO.new) do
          binding.pry
       end
      end
      o.sample
      $out.string.should =~ /sample comment/
      $out = nil
    end

    it "should be able to find super methods" do

      c = Class.new{
        # classy initialize!
        def initialize(*args); end
      }

      d = Class.new(c){
        # grungy initialize??
        def initialize(*args, &block); end
      }

      o = d.new

      # instancey initialize!
      def o.initialize; end

      mock_pry(binding, "show-doc o.initialize").should =~ /instancey initialize/
      mock_pry(binding, "show-doc --super o.initialize").should =~ /grungy initialize/
      mock_pry(binding, "show-doc o.initialize -ss").should =~ /classy initialize/
      mock_pry(binding, "show-doc --super o.initialize -ss").should == mock_pry("show-doc Object#initialize")
    end
  end

  describe "on modules" do
    before do
      # god this is boring1
      class ShowSourceTestClass
        def alpha
        end
      end

      # god this is boring2
      module ShowSourceTestModule
        def alpha
        end
      end

      # god this is boring3
      ShowSourceTestClassWeirdSyntax = Class.new do
        def beta
        end
      end

      # god this is boring4
      ShowSourceTestModuleWeirdSyntax = Module.new do
        def beta
        end
      end
    end

    after do
      Object.remove_const :ShowSourceTestClass
      Object.remove_const :ShowSourceTestClassWeirdSyntax
      Object.remove_const :ShowSourceTestModule
      Object.remove_const :ShowSourceTestModuleWeirdSyntax
    end

    describe "basic functionality, should show docs for top-level module definitions" do
      it 'should show docs for a class' do
        mock_pry("show-doc ShowSourceTestClass").should =~ /god this is boring1/
      end

      it 'should show docs for a module' do
        mock_pry("show-doc ShowSourceTestModule").should =~ /god this is boring2/
      end

      it 'should show docs for a class when Const = Class.new syntax is used' do
        mock_pry("show-doc ShowSourceTestClassWeirdSyntax").should =~ /god this is boring3/
      end

      it 'should show docs for a module when Const = Module.new syntax is used' do
        mock_pry("show-doc ShowSourceTestModuleWeirdSyntax").should =~ /god this is boring4/
      end
    end

    describe "in REPL" do
      it 'should find class defined in repl' do
        mock_pry("# hello tobina", "class TobinaMyDog", "def woof", "end", "end", "show-doc TobinaMyDog").should =~ /hello tobina/
        Object.remove_const :TobinaMyDog
      end
    end

    it 'should lookup module name with respect to current context' do
      constant_scope(:AlphaClass, :BetaClass) do

        # top-level beta
        class BetaClass
          def alpha
          end
        end

        class AlphaClass

          # nested beta
          class BetaClass
            def beta
            end
          end
        end

        redirect_pry_io(InputTester.new("show-doc BetaClass", "exit-all"), out=StringIO.new) do
          AlphaClass.pry
        end

        out.string.should =~ /nested beta/
      end
    end

    it 'should lookup nested modules' do
      constant_scope(:AlphaClass) do
        class AlphaClass

          # nested beta
          class BetaClass
            def beta
            end
          end
        end

        mock_pry("show-doc AlphaClass::BetaClass").should =~ /nested beta/
      end
    end

    describe "show-doc -a" do
      it 'should show the docs for all monkeypatches defined in different files' do

        # local monkeypatch
        class TestClassForShowSource
          def beta
          end
        end

        mock_pry("show-doc TestClassForShowSource -a").should =~ /used by.*?local monkeypatch/m
      end
    end

  end
end
