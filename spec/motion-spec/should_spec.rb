motion_require '../spec_helper'

describe "#should shortcut for #it('should')" do

  should "be called" do
    @called = true
    @called.should.eq true
  end

  should "save some characters by typing should" do
    lambda { should.satisfy { 1 == 1 } }.should.not.raise
  end

  should "save characters even on failure" do
    lambda { should.satisfy { 1 == 2 } }.should.raise Motion::Spec::Error
  end

  should "work nested" do
    should.satisfy { 1 == 1 }
  end

  count = Motion::Spec::Counter[:specifications]
  should "add new specifications" do
    # XXX this should +=1 but it's +=2
    # What?
    (count+2).should.eq Motion::Spec::Counter[:specifications]
  end

  should "have been called" do
    @called.should.eq true
  end

end
