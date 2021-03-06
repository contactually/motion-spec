# -*- encoding : utf-8 -*-

class MockObservable
  attr_accessor :an_attribute
end

describe 'NSRunloop aware Bacon' do
  describe "concerning `wait' with a fixed time" do
    it 'allows the user to postpone execution of a block for n seconds, which will halt any further execution of specs' do
      started_at_1 = started_at_2 = started_at_3 = Time.now
      # number_of_specs_before = MotionSpec::Counter[:specifications]

      wait(0.5) { (Time.now - started_at_1).should.be.close(0.5, 0.5) }

      wait 1 do
        (Time.now - started_at_2).should.be.close(1.5, 0.5)
        wait 1.5 do
          (Time.now - started_at_3).should.be.close(3, 0.5)
          # MotionSpec::Counter[:specifications].should.eq number_of_specs_before
        end
      end
    end
  end

  describe "concerning `wait' without a fixed time" do
    def delegateCallbackMethod
      @delegateCallbackCalled = true
      resume
    end

    def delegateCallbackTookTooLongMethod
      fail 'Oh noes, I must never be called!'
    end

    it 'allows the user to postpone execution of a block until Context#resume is called, from for instance a delegate callback' do
      performSelector('delegateCallbackMethod', withObject: nil, afterDelay: 0.1)
      @delegateCallbackCalled.should.eq nil
      wait { @delegateCallbackCalled.should.eq true }
    end

    ## This spec adds a failure to the ErrorLog!
    # it "has a default timeout of 1 second after which the spec will fail and further scheduled calls to the Context are cancelled" do
    #   expect_spec_to_fail!
    #   performSelector('delegateCallbackTookTooLongMethod', withObject:nil, afterDelay:1.2)
    #   wait do
    #     # we must never arrive here, because the default timeout of 1 second will have passed
    #     raise "Oh noes, we shouldn't have arrived in this postponed block!"
    #   end
    # end

    ## This spec adds a failure to the ErrorLog!
    # it "takes an explicit timeout" do
    #   expect_spec_to_fail!
    #   performSelector('delegateCallbackTookTooLongMethod', withObject:nil, afterDelay:0.8)
    #   wait_max 0.3 do
    #     # we must never arrive here, because the default timeout of 1 second will have passed
    #     raise "Oh noes, we shouldn't have arrived in this postponed block!"
    #   end
    # end
  end

  describe "concerning `wait_for_change'" do
    before { @observable = MockObservable.new }

    def triggerChange
      @observable.an_attribute = 'changed'
    end

    it 'resumes the postponed block once an observed value changes' do
      value = nil
      performSelector('triggerChange', withObject: nil, afterDelay: 0)
      wait_for_change @observable, 'an_attribute' do
        @observable.an_attribute.should.eq 'changed'
      end
    end

    ## This spec adds a failure to the ErrorLog!
    # it "has a default timeout of 1 second" do
    #   expect_spec_to_fail!
    #   wait_for_change(@observable, 'an_attribute') do
    #     raise "Oh noes, I must never be called!"
    #   end
    #   performSelector('triggerChange', withObject:nil, afterDelay:1.1)
    #   wait 1.2 do
    #     # we must never arrive here, because the default timeout of 1 second will have passed
    #     raise "Oh noes, we shouldn't have arrived in this postponed block!"
    #   end
    # end

    ## This spec adds a failure to the ErrorLog!
    # it "takes an explicit timeout" do
    #   expect_spec_to_fail!
    #   wait_for_change(@observable, 'an_attribute', 0.3) do
    #     raise "Oh noes, I must never be called!"
    #   end
    #   performSelector('triggerChange', withObject:nil, afterDelay:0.8)
    #   wait 0.9 do
    #     # we must never arrive here, because the default timeout of 1 second will have passed
    #     raise "Oh noes, we shouldn't have arrived in this postponed block!"
    #   end
    # end
  end

  describe 'postponing blocks should work from before/after filters as well' do
    shared 'waiting in before/after filters' do
      it 'starts later because of postponed blocks in the before filter' do
        (Time.now - @started_at).should.be.close(1, 0.5)
      end

      # TODO: this will never pass when run in concurrent mode, because it gets
      # executed around the same time as the above spec and take one second as
      # well.
      #
      # it "starts even later because of the postponed blocks in the after filter" do
      # (Time.now - @started_at).should.be.close(3, 0.5)
      # end
    end

    describe "with `wait'" do
      describe 'and an explicit time' do
        before do
          @started_at ||= Time.now
          wait 0.5 do
            wait 0.5 do
            end
          end
        end

        after do
          wait 0.5 do
            wait 0.5 do
              @time ||= 0
              @time += 2
              (Time.now - @started_at).should.be.close(@time, 0.2)
            end
          end
        end

        include_examples 'waiting in before/after filters'
      end

      describe 'and without explicit time' do
        before do
          @started_at ||= Time.now
          performSelector('resume', withObject: nil, afterDelay: 0.5)
          wait do
            performSelector('resume', withObject: nil, afterDelay: 0.5)
            wait do
            end
          end
        end

        after do
          performSelector('resume', withObject: nil, afterDelay: 0.5)
          wait do
            performSelector('resume', withObject: nil, afterDelay: 0.5)
            wait do
              @time ||= 0
              @time += 2
              (Time.now - @started_at).should.be.close(@time, 0.2)
            end
          end
        end

        include_examples 'waiting in before/after filters'
      end
    end

    describe "with `wait_for_change'" do
      before do
        @observable = MockObservable.new
        @started_at ||= Time.now
        performSelector('triggerChange', withObject: nil, afterDelay: 0.5)
        wait_for_change @observable, 'an_attribute' do
          performSelector('triggerChange', withObject: nil, afterDelay: 0.5)
          wait_for_change @observable, 'an_attribute' do
          end
        end
      end

      after do
        performSelector('triggerChange', withObject: nil, afterDelay: 0.5)
        wait_for_change @observable, 'an_attribute' do
          performSelector('triggerChange', withObject: nil, afterDelay: 0.5)
          wait_for_change @observable, 'an_attribute' do
            @time ||= 0
            @time += 2
            (Time.now - @started_at).should.be.close(@time, 1)
          end
        end
      end

      def triggerChange
        @observable.an_attribute = 'changed'
      end

      include_examples 'waiting in before/after filters'
    end
  end
end

# We make no promises about NIBs for the moment
#
# class WindowController < NSWindowController
#   attr_accessor :arrayController
#   attr_accessor :tableView
#   attr_accessor :textField
# end
#
# describe "Nib helper" do
#   self.run_on_main_thread = true
#
#   after do
#     @controller.close
#   end
#
#   def verify_outlets!
#     @controller.arrayController.should.be.instance_of NSArrayController
#     @controller.tableView.should.be.instance_of NSTableView
#     @controller.textField.should.be.instance_of NSTextField
#   end
#
#   it "takes a NIB path and instantiates the NIB with the given `owner' object" do
#     nib_path = File.expand_path("../fixtures/Window.nib", __FILE__)
#     @controller = WindowController.new
#     load_nib(nib_path, @controller)
#     verify_outlets!
#   end
#
#   it "also returns an array or other top level objects" do
#     nib_path = File.expand_path("../fixtures/Window.nib", __FILE__)
#     @controller = WindowController.new
#     top_level_objects = load_nib(nib_path, @controller).sort_by { |o| o.class.name }
#     top_level_objects[0].should.be.instance_of NSApplication
#     top_level_objects[1].should.be.instance_of NSArrayController
#     top_level_objects[2].should.be.instance_of NSWindow
#   end
#
#   it "converts a XIB to a tmp NIB before loading it and caches it" do
#     xib_path = File.expand_path("../fixtures/Window.xib", __FILE__)
#     @controller = WindowController.new
#     load_nib(xib_path, @controller)
#     verify_outlets!
#     @controller.close
#
#     def self.system(cmd)
#       raise "Oh noes! Tried to convert again!"
#     end
#
#     @controller = WindowController.new
#     load_nib(xib_path, @controller)
#     verify_outlets!
#   end
# end
