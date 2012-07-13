require 'spec_helper'

describe Attachment do
  it { should belong_to(:post) }
  it { should validate_presence_of(:attachment) }

  describe '.filename' do
    it 'should return a filaname from a path' do
      image = build_stubbed(:attachment)
      image.filename.should == 'img.png'
    end
  end
end
